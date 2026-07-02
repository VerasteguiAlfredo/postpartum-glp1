# =============================================================================
# postpartum-glp1: Full covariate Cox models — DELIVERY-ANCHORED
#                  *** Reference = LATE (>= 6 months); binary obesity ***
# -----------------------------------------------------------------------------
# Companion to table3_4_cox_delivery_anchored_v2.R. For each of 6 outcomes:
#   (1) UNIVARIATE table  — every candidate covariate fit alone (-> supplementary)
#   (2) MULTIVARIABLE table — final adjusted model, HR/95% CI/p per term (-> main)
#
# Multivariable selection:
#   * Exposure (GLP-1 timing) always included.
#   * Pre-specified, forced in per Dr. Adedinsewo: T2DM, obesity (BMI>=30), OSA.
#   * Any remaining candidate with univariate p < 0.10 added.
#
# Reference (per Dr. Adedinsewo): Late (>= 6 mo). HR > 1 = Early reach event faster.
#
# NOTE: event_start_day is ALWAYS passed by name. The 5th positional argument of
#       build_tte_delivery is `cap`; passing 0 there collapses the window to a
#       single day and yields 0 events. Do not pass it positionally.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(survival)
  library(knitr)
  library(gt)
})

# =============================================================================
# PATHS
# =============================================================================
sys_name  <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}
data_dir <- file.path(proj_root, "data_processed")
md_dir   <- file.path(proj_root, "Results", "Analysis", "Tables", "MD Files")
html_dir <- file.path(proj_root, "Results", "Analysis", "Tables", "HTML Files")
for (d in c(md_dir, html_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

if (!exists("analysis_df")) analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
if (!exists("vitals_long")) vitals_long <- readRDS(file.path(data_dir, "vitals_long.rds"))

if (!"obesity_bmi_baseline" %in% names(analysis_df))
  stop("obesity_bmi_baseline not found — re-run the v4 build script first.")

# =============================================================================
# PARAMETERS & TTE CONSTRUCTION
# =============================================================================
DAYS_PER_MONTH     <- 30.44
FOLLOWUP_CAP       <- round(12 * DAYS_PER_MONTH)
BP_BASELINE_WINDOW <- 2
BP_EVENT_START_DAY <- 14
P_SCREEN           <- 0.10

analysis_df <- analysis_df %>%
  mutate(
    pre_preg_weight_kg = PREGRAVID_BMI * (height_cm / 100)^2,
    bp_baseline_stage2 = (!is.na(sbp_baseline_combined) & sbp_baseline_combined >= 140) |
                         (!is.na(dbp_baseline_combined) & dbp_baseline_combined >= 90),
    hdp_cohort = (preg_htn_any == TRUE) | bp_baseline_stage2
  )

full_ids <- analysis_df$CURR_CLINIC
hdp_ids  <- analysis_df %>% filter(hdp_cohort) %>% pull(CURR_CLINIC)

earliest_pp_baseline <- function(vital_name) {
  vitals_long %>%
    filter(vital == vital_name, days_from_delivery >= 0, !is.na(value)) %>%
    group_by(CURR_CLINIC) %>% slice_min(days_from_delivery, n = 1, with_ties = FALSE) %>%
    ungroup() %>% transmute(CURR_CLINIC, baseline = value)
}
delivery_date_bp_baseline <- function(vital_name) {
  vitals_long %>%
    filter(vital == vital_name, !is.na(value), abs(days_from_delivery) <= BP_BASELINE_WINDOW) %>%
    group_by(CURR_CLINIC) %>% slice_min(abs(days_from_delivery), n = 1, with_ties = FALSE) %>%
    ungroup() %>% transmute(CURR_CLINIC, baseline = value)
}
wt_base      <- earliest_pp_baseline("weight_kg")
sbp_base     <- delivery_date_bp_baseline("sbp")
dbp_base     <- delivery_date_bp_baseline("dbp")
prepreg_base <- analysis_df %>% transmute(CURR_CLINIC, baseline = pre_preg_weight_kg) %>%
  filter(!is.na(baseline))

build_tte_delivery <- function(vital_name, baseline_df, event_fn, cohort_ids,
                               cap = FOLLOWUP_CAP, event_start_day = 0) {
  vitals_long %>%
    filter(vital == vital_name, days_from_delivery >= event_start_day,
           days_from_delivery <= cap, !is.na(value), CURR_CLINIC %in% cohort_ids) %>%
    inner_join(baseline_df, by = "CURR_CLINIC") %>%
    mutate(is_event = event_fn(value, baseline)) %>%
    group_by(CURR_CLINIC) %>%
    summarise(last_day = max(days_from_delivery),
              first_event_day = if (any(is_event)) min(days_from_delivery[is_event]) else NA_real_,
              .groups = "drop") %>%
    mutate(event = as.integer(!is.na(first_event_day)),
           tte_days = pmin(ifelse(event == 1, first_event_day, last_day), cap),
           tte_days = ifelse(tte_days <= 0, 0.5, tte_days),
           tte = tte_days / DAYS_PER_MONTH) %>%
    select(CURR_CLINIC, tte, event)
}

# event_start_day BY NAME (do not pass positionally)
A1 <- build_tte_delivery("weight_kg", wt_base,      function(v, b) v <= b * 0.90, full_ids, event_start_day = 0)
A2 <- build_tte_delivery("weight_kg", wt_base,      function(v, b) v <= b * 0.80, full_ids, event_start_day = 0)
A3 <- build_tte_delivery("weight_kg", prepreg_base, function(v, b) v <= b,        full_ids, event_start_day = 0)
B1 <- build_tte_delivery("sbp", sbp_base, function(v, b) (b - v) >= 5,  hdp_ids, event_start_day = BP_EVENT_START_DAY)
B2 <- build_tte_delivery("sbp", sbp_base, function(v, b) (b - v) >= 10, hdp_ids, event_start_day = BP_EVENT_START_DAY)
B3 <- build_tte_delivery("dbp", dbp_base, function(v, b) (b - v) >= 5,  hdp_ids, event_start_day = BP_EVENT_START_DAY)

cat("--- TTE event counts ---\n")
for (nm in c("A1","A2","A3","B1","B2","B3")) {
  d <- get(nm); cat(sprintf("  %s: n = %d, events = %d\n", nm, nrow(d), sum(d$event)))
}
cat("\n")

# =============================================================================
# COVARIATES — factors w/ explicit refs; Late = ref; binary obesity
# =============================================================================
covariates <- analysis_df %>%
  mutate(
    glp1_timing_2cat = relevel(
      factor(glp1_timing_2cat, levels = c("Early (< 6 months)", "Late (>= 6 months)")),
      ref = "Late (>= 6 months)"),
    parity_cat = factor(case_when(
      as.numeric(PARITY) == 1 ~ "Primiparous",
      as.numeric(PARITY) >= 2 ~ "Multiparous",
      TRUE ~ NA_character_), levels = c("Primiparous", "Multiparous")),
    delivery_mode_simple = factor(case_when(
      str_detect(DELIVERY_MODALITY, regex("c-section|cesarean", ignore_case = TRUE)) ~ "Cesarean",
      str_detect(DELIVERY_MODALITY, regex("vaginal", ignore_case = TRUE)) ~ "Vaginal",
      TRUE ~ "Other"), levels = c("Vaginal", "Cesarean", "Other")),
    glp1_agent_simple = factor(if_else(glp1_first_drug == "semaglutide", "semaglutide", "other"),
                               levels = c("semaglutide", "other")),
    bp_med_any = med_acei | med_arb | med_betablocker | med_ccb | med_diuretic
  ) %>%
  select(CURR_CLINIC, glp1_timing_2cat, current_age, parity_cat, delivery_mode_simple,
         ckm_t2dm, preg_gdm, obesity_bmi_baseline, ckm_osa,
         glp1_agent_simple, preg_preec_any_spectrum, bp_med_any)

attach_covs <- function(tte_df) {
  tte_df %>%
    inner_join(covariates, by = "CURR_CLINIC") %>%
    mutate(across(where(is.factor), droplevels))
}
A1c <- attach_covs(A1); A2c <- attach_covs(A2); A3c <- attach_covs(A3)
B1c <- attach_covs(B1); B2c <- attach_covs(B2); B3c <- attach_covs(B3)

# =============================================================================
# HELPERS
# =============================================================================
tidy_cox <- function(fit) {
  s  <- summary(fit); cf <- s$coefficients; ci <- s$conf.int
  tibble(term = rownames(cf),
         hr  = cf[, "exp(coef)"],
         lcl = ci[, "lower .95"],
         ucl = ci[, "upper .95"],
         p   = cf[, "Pr(>|z|)"])
}

var_labels <- c(
  glp1_timing_2cat        = "GLP-1 timing",
  current_age             = "Age (years)",
  parity_cat              = "Parity",
  delivery_mode_simple    = "Delivery mode",
  ckm_t2dm                = "Type 2 diabetes",
  preg_gdm                = "Gestational diabetes",
  obesity_bmi_baseline    = "Obesity (BMI \u2265 30)",
  ckm_osa                 = "Obstructive sleep apnea",
  glp1_agent_simple       = "GLP-1 agent",
  preg_preec_any_spectrum = "Preeclampsia spectrum",
  bp_med_any              = "Baseline antihypertensive use"
)
.lab_order <- names(var_labels)[order(nchar(names(var_labels)), decreasing = TRUE)]

pretty_term <- function(term) {
  for (v in .lab_order) {
    if (startsWith(term, v)) {
      lvl <- sub(paste0("^", v), "", term)
      if (lvl == "" || lvl == "TRUE") return(unname(var_labels[[v]]))
      return(paste0(var_labels[[v]], ": ", lvl))
    }
  }
  term
}

fmt_p  <- function(p) ifelse(is.na(p), "--", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
fmt_model_table <- function(tt) {
  tt %>%
    mutate(Variable = vapply(term, pretty_term, character(1)),
           `HR (95% CI)` = sprintf("%.2f (%.2f-%.2f)", hr, lcl, ucl),
           `p-value` = fmt_p(p)) %>%
    select(Variable, `HR (95% CI)`, `p-value`)
}

# =============================================================================
# CORE: univariate screen + multivariable model
# =============================================================================
run_outcome_models <- function(df, candidates, forced, exposure = "glp1_timing_2cat") {
  uni_terms <- c(exposure, candidates)
  uni_tab <- bind_rows(lapply(uni_terms, function(v) {
    fit <- tryCatch(coxph(as.formula(paste("Surv(tte, event) ~", v)), data = df),
                    error = function(e) NULL)
    if (is.null(fit)) return(NULL)
    tt <- tidy_cox(fit); tt$variable <- v
    tt$screen_p <- unname(summary(fit)$logtest["pvalue"])
    tt
  }))
  passed <- candidates[vapply(candidates, function(v) {
    sp <- unique(uni_tab$screen_p[uni_tab$variable == v])
    length(sp) == 1 && !is.na(sp) && sp < P_SCREEN
  }, logical(1))]
  selected <- c(exposure, intersect(candidates, union(passed, forced)))
  fit_multi <- tryCatch(
    coxph(as.formula(paste("Surv(tte, event) ~", paste(selected, collapse = " + "))), data = df),
    error = function(e) NULL)
  multi_tab <- if (is.null(fit_multi)) NULL else tidy_cox(fit_multi)
  list(uni = uni_tab, multi = multi_tab, fit_multi = fit_multi,
       passed = passed, forced = forced, selected = selected)
}

weight_cands <- c("current_age", "parity_cat", "delivery_mode_simple",
                  "ckm_t2dm", "preg_gdm", "obesity_bmi_baseline",
                  "ckm_osa", "glp1_agent_simple")
bp_cands     <- c("current_age", "preg_preec_any_spectrum", "ckm_t2dm",
                  "preg_gdm", "obesity_bmi_baseline", "ckm_osa",
                  "glp1_agent_simple", "bp_med_any")
forced       <- c("ckm_t2dm", "obesity_bmi_baseline", "ckm_osa")

outcomes <- list(
  A1 = list(df = A1c, label = "A1: >=10% weight loss",              cand = weight_cands),
  A2 = list(df = A2c, label = "A2: >=20% weight loss",              cand = weight_cands),
  A3 = list(df = A3c, label = "A3: Return to pre-pregnancy weight", cand = weight_cands),
  B1 = list(df = B1c, label = "B1: >=5 mmHg SBP decline (HDP)",     cand = bp_cands),
  B2 = list(df = B2c, label = "B2: >=10 mmHg SBP decline (HDP)",    cand = bp_cands),
  B3 = list(df = B3c, label = "B3: >=5 mmHg DBP decline (HDP)",     cand = bp_cands)
)

nejm_style <- function(gt_tbl) {
  n_rows <- nrow(gt_tbl[["_data"]])
  gt_tbl %>%
    tab_options(
      table.font.names = "Georgia, 'Times New Roman', serif",
      table.font.size = px(12), table.font.color = "#000000",
      table.background.color = "#FFFFFF",
      heading.title.font.size = px(14), heading.title.font.weight = "bold",
      heading.align = "left", data_row.padding = px(4),
      column_labels.padding = px(8), column_labels.font.weight = "bold",
      table.border.top.style = "none", table.border.bottom.style = "none",
      heading.border.bottom.style = "none",
      column_labels.border.top.style = "none", column_labels.border.bottom.style = "none",
      table_body.border.top.style = "none", table_body.border.bottom.style = "none",
      table_body.hlines.style = "none", table_body.vlines.style = "none",
      source_notes.border.bottom.style = "none") %>%
    tab_style(cell_borders(sides = "all", color = "#FFFFFF", weight = px(0)),
              list(cells_body(), cells_column_labels(), cells_title(), cells_source_notes())) %>%
    tab_style(cell_borders(sides = "top", color = "#000000", weight = px(2)), cells_column_labels()) %>%
    tab_style(cell_borders(sides = "bottom", color = "#000000", weight = px(1)), cells_column_labels()) %>%
    tab_style(cell_borders(sides = "bottom", color = "#000000", weight = px(2)), cells_body(rows = n_rows))
}

# =============================================================================
# RUN + ASSEMBLE
# =============================================================================
uni_md  <- c("# Supplementary Table. Univariate Cox associations (delivery-anchored)",
             "", "_Reference: Late (>= 6 mo) initiators. Each covariate in a separate",
             "unadjusted Cox model. Screening threshold for the multivariable model:",
             "univariate p < 0.10._", "")
main_md <- c("# Multivariable Cox models (delivery-anchored)",
             "", "_Reference: Late (>= 6 mo) initiators. HR > 1 = Early initiators reach",
             "the outcome faster than Late._", "")

cat("================ COVARIATE SELECTION SUMMARY ================\n")
for (nm in names(outcomes)) {
  oc  <- outcomes[[nm]]
  res <- run_outcome_models(oc$df, oc$cand, forced)
  screened_in <- setdiff(res$passed, forced)

  cat(sprintf("\n%s (events = %d / %d)\n", oc$label, sum(oc$df$event), nrow(oc$df)))
  cat("  Forced:      ", paste(forced, collapse = ", "), "\n")
  cat("  Screened-in: ", if (length(screened_in)) paste(screened_in, collapse = ", ") else "(none)", "\n")
  cat("  Final model: ", paste(res$selected, collapse = " + "), "\n")

  uni_md <- c(uni_md, paste0("## ", oc$label), "",
              kable(fmt_model_table(res$uni), format = "pipe", align = "lrr"), "")

  if (!is.null(res$multi)) {
    note <- paste0("_Model: GLP-1 timing + pre-specified (T2DM, obesity, OSA)",
                   if (length(screened_in)) paste0(" + univariate p<0.10 (",
                                                   paste(screened_in, collapse = ", "), ")") else "",
                   ". Events = ", sum(oc$df$event), " / ", nrow(oc$df), "._")
    main_md <- c(main_md, paste0("## ", oc$label), "",
                 kable(fmt_model_table(res$multi), format = "pipe", align = "lrr"),
                 "", note, "")

    gt_mv <- fmt_model_table(res$multi) %>% gt() %>%
      tab_header(title = md(paste0("**Multivariable Cox — ", oc$label, "**"))) %>%
      tab_source_note(md(gsub("_", "", note))) %>% nejm_style()
    gt::gtsave(gt_mv, file.path(html_dir, paste0("mv_cox_", nm, "_delivery.html")))

    gt_uni <- fmt_model_table(res$uni) %>% gt() %>%
      tab_header(title = md(paste0("**Univariate Cox — ", oc$label, "**"))) %>% nejm_style()
    gt::gtsave(gt_uni, file.path(html_dir, paste0("uni_cox_", nm, "_delivery.html")))
  } else {
    main_md <- c(main_md, paste0("## ", oc$label), "",
                 "_Multivariable model did not converge._", "")
  }
}
cat("\n============================================================\n")

writeLines(uni_md,  file.path(md_dir, "suppl_univariate_cox_delivery.md"))
writeLines(main_md, file.path(md_dir, "main_multivariable_cox_delivery.md"))

cat("\nWritten:\n")
cat("  MD  :", file.path(md_dir, "suppl_univariate_cox_delivery.md"), "\n")
cat("  MD  :", file.path(md_dir, "main_multivariable_cox_delivery.md"), "\n")
cat("  HTML: mv_cox_<A1..B3>_delivery.html and uni_cox_<A1..B3>_delivery.html (12 files)\n")