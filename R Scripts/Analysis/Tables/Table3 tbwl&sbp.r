# =============================================================================
# postpartum-glp1: Table 3 (revised) & Table 4 — Cox PH / KM Survival Analyses
# -----------------------------------------------------------------------------
# Per PI Dr. Adedinsewo restructure (see analysis plan markdown).
#
# *** PRIMARY DESIGN: GLP-1-ANCHORED (drug start = time 0) ***
# Time origin = each patient's GLP-1 initiation date.
# Follow-up = days on drug, capped at 540 days (18 months on drug).
# No left-truncation needed: every patient enters at their own day 0, so there
# is no immortal-time window to remove. Standard Surv(time, event) form.
# (Delivery-anchored + left-truncation retained as a SUPPLEMENTARY script.)
#
# Six outcomes, all using glp1_timing_2cat as primary predictor:
#   A1: time to >=10% weight loss from baseline (full cohort)
#   A2: time to >=20% weight loss from baseline (full cohort)
#   A3: time to pre-pregnancy weight (subgroup with PREGRAVID_BMI documented)
#   B1: time to >=5 mmHg SBP decline (HDP subgroup)
#   B2: time to >=10 mmHg SBP decline (HDP subgroup)
#   B3: time to >=5 mmHg DBP decline (HDP subgroup)
#
# Baseline weight/BP: *_baseline_combined (postpartum-stable; primary).
# Censoring: ITT-like — follow-up continues regardless of GLP-1 stop.
#
# Outputs:
#   table3_cox_weight.md/html — Table 3 (revised, weight)
#   table4_cox_bp.md/html     — Table 4 (BP, HDP subgroup)
#   tte_datasets.rds          — for downstream KM / forest-plot figures
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(survival)
  library(gt)
})

# --- Paths ---
sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}
data_dir <- file.path(proj_root, "data_processed")
md_dir   <- file.path(proj_root, "Results", "Analysis", "Tables", "MD Files")
html_dir <- file.path(proj_root, "Results", "Analysis", "Tables", "HTML Files")
for (d in c(md_dir, html_dir)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

if (!exists("analysis_df")) analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
if (!exists("vitals_long")) vitals_long <- readRDS(file.path(data_dir, "vitals_long.rds"))

cat("Loaded analysis_df:", nrow(analysis_df), "rows x", ncol(analysis_df), "cols\n")
cat("Loaded vitals_long:", nrow(vitals_long), "rows\n\n")

if (!"glp1_timing_2cat" %in% names(analysis_df)) {
  stop("glp1_timing_2cat not found. Re-run build_analysis_dataset_v3.R first.")
}

# =============================================================================
# 1. PARAMETERS & DERIVED VARIABLES
# =============================================================================
FOLLOWUP_CAP <- 540   # 18 months on drug, in days

# Pre-pregnancy weight from PREGRAVID_BMI x height^2 (for A3)
analysis_df <- analysis_df %>%
  mutate(pre_preg_weight_kg = PREGRAVID_BMI * (height_cm / 100)^2)

# HDP subgroup: pregnancy HTN OR baseline BP >= 140/90
analysis_df <- analysis_df %>%
  mutate(
    bp_baseline_stage2 = (!is.na(sbp_baseline_combined) & sbp_baseline_combined >= 140) |
                        (!is.na(dbp_baseline_combined) & dbp_baseline_combined >= 90),
    hdp_cohort = (preg_htn_any == TRUE) | bp_baseline_stage2
  )

cat("HDP subgroup size:", sum(analysis_df$hdp_cohort, na.rm = TRUE), "\n")
cat("Pre-pregnancy weight available:",
    sum(!is.na(analysis_df$pre_preg_weight_kg)), "\n\n")

# =============================================================================
# 2. CORE TTE BUILDER — DRUG-ANCHORED
# -----------------------------------------------------------------------------
# Uses days_from_glp1 as the time axis. Only post-initiation measurements
# (days_from_glp1 >= 0) count. First measurement satisfying event_fn marks the
# event; otherwise censored at last on-drug measurement. Cap at 540 days.
# Returns standard (tte, event) — NO entry time, NO left-truncation.
# =============================================================================
build_tte_drug <- function(vital_name, baseline_var, event_fn,
                           cohort_df = analysis_df, cap = FOLLOWUP_CAP) {
  vl <- vitals_long %>%
    filter(vital == vital_name,
           !is.na(days_from_glp1),
           days_from_glp1 >= 0,
           days_from_glp1 <= cap)

  vl <- vl %>%
    inner_join(cohort_df %>% select(CURR_CLINIC, all_of(baseline_var)),
               by = "CURR_CLINIC") %>%
    rename(baseline = all_of(baseline_var)) %>%
    filter(!is.na(baseline)) %>%
    mutate(is_event = event_fn(value, baseline))

  per_pt <- vl %>%
    arrange(CURR_CLINIC, days_from_glp1) %>%
    group_by(CURR_CLINIC) %>%
    summarise(
      last_meas_day   = max(days_from_glp1, na.rm = TRUE),
      first_event_day = ifelse(any(is_event, na.rm = TRUE),
                               min(days_from_glp1[is_event], na.rm = TRUE),
                               NA_real_),
      .groups = "drop"
    ) %>%
    mutate(
      event = as.integer(!is.na(first_event_day)),
      tte   = ifelse(event == 1, first_event_day, last_meas_day),
      tte   = pmin(tte, cap),
      # Guard: a patient whose only on-drug measurement is at day 0 has tte=0;
      # bump to 0.5 day so Surv() accepts positive time.
      tte   = ifelse(tte <= 0, 0.5, tte)
    )

  cohort_df %>%
    select(CURR_CLINIC) %>%
    inner_join(per_pt, by = "CURR_CLINIC")
}

# =============================================================================
# 3. BUILD 6 TTE DATASETS
# =============================================================================
cat("--- Building drug-anchored TTE datasets ---\n")

A1 <- build_tte_drug("weight_kg", "weight_kg_baseline_combined",
                     function(v, b) v <= b * 0.90)
cat("A1 (>=10% weight loss): n =", nrow(A1), ", events =", sum(A1$event), "\n")

A2 <- build_tte_drug("weight_kg", "weight_kg_baseline_combined",
                     function(v, b) v <= b * 0.80)
cat("A2 (>=20% weight loss): n =", nrow(A2), ", events =", sum(A2$event), "\n")

A3 <- build_tte_drug("weight_kg", "pre_preg_weight_kg",
                     function(v, b) v <= b)
cat("A3 (reach pre-preg weight): n =", nrow(A3), ", events =", sum(A3$event), "\n")

hdp_df <- analysis_df %>% filter(hdp_cohort)

B1 <- build_tte_drug("sbp", "sbp_baseline_combined",
                     function(v, b) (b - v) >= 5, cohort_df = hdp_df)
cat("B1 (>=5 mmHg SBP drop, HDP): n =", nrow(B1), ", events =", sum(B1$event), "\n")

B2 <- build_tte_drug("sbp", "sbp_baseline_combined",
                     function(v, b) (b - v) >= 10, cohort_df = hdp_df)
cat("B2 (>=10 mmHg SBP drop, HDP): n =", nrow(B2), ", events =", sum(B2$event), "\n")

B3 <- build_tte_drug("dbp", "dbp_baseline_combined",
                     function(v, b) (b - v) >= 5, cohort_df = hdp_df)
cat("B3 (>=5 mmHg DBP drop, HDP): n =", nrow(B3), ", events =", sum(B3$event), "\n\n")

# =============================================================================
# 4. COVARIATES
# =============================================================================
covariates <- analysis_df %>%
  mutate(
    parity_cat = case_when(
      as.numeric(PARITY) == 1 ~ "Primiparous",
      as.numeric(PARITY) >= 2 ~ "Multiparous",
      TRUE ~ NA_character_
    ),
    delivery_mode_simple = case_when(
      str_detect(DELIVERY_MODALITY, regex("c-section|cesarean", ignore_case = TRUE)) ~ "Cesarean",
      str_detect(DELIVERY_MODALITY, regex("vaginal", ignore_case = TRUE)) ~ "Vaginal",
      TRUE ~ "Other"
    ),
    glp1_agent_simple = if_else(glp1_first_drug == "semaglutide", "semaglutide", "other"),
    bp_med_any = med_acei | med_arb | med_betablocker | med_ccb | med_diuretic
  ) %>%
  select(CURR_CLINIC, glp1_timing_2cat, days_pp_to_glp1,
         current_age, bmi_baseline_combined,
         parity_cat, delivery_mode_simple,
         ckm_t2dm, preg_gdm, glp1_agent_simple,
         preg_preec_any_spectrum, bp_med_any)

# Attach covariates. No left-truncation filter needed under drug-anchoring.
attach_covs <- function(tte_df) {
  tte_df %>%
    inner_join(covariates, by = "CURR_CLINIC") %>%
    mutate(glp1_timing_2cat = factor(glp1_timing_2cat,
                                     levels = c("Early (< 6 months)",
                                                "Late (>= 6 months)")))
}

A1c <- attach_covs(A1); A2c <- attach_covs(A2); A3c <- attach_covs(A3)
B1c <- attach_covs(B1); B2c <- attach_covs(B2); B3c <- attach_covs(B3)

cat("After covariate attach (no truncation filter):\n")
for (nm in c("A1c","A2c","A3c","B1c","B2c","B3c")) {
  d <- get(nm)
  cat(sprintf("  %s: n = %d, events = %d\n", nm, nrow(d), sum(d$event)))
}
cat("\n")

# =============================================================================
# 5. ANALYSIS FUNCTIONS (standard Surv — drug-anchored)
# =============================================================================
surv_obj <- function(df) Surv(time = df$tte, event = df$event)

median_tte <- function(df) {
  fit <- survfit(Surv(tte, event) ~ 1, data = df)
  sm <- summary(fit)$table
  med <- sm["median"]; lcl <- sm["0.95LCL"]; ucl <- sm["0.95UCL"]
  if (is.na(med)) return("NR")
  sprintf("%.0f (%.0f-%.0f)", med,
          ifelse(is.na(lcl), NA, lcl), ifelse(is.na(ucl), NA, ucl))
}

median_tte_strata <- function(df, level) {
  sub <- df %>% filter(glp1_timing_2cat == level)
  if (nrow(sub) < 5) return("--")
  median_tte(sub)
}

# Log-rank (standard Surv works now)
logrank_p <- function(df) {
  if (length(unique(df$glp1_timing_2cat)) < 2) return(NA_real_)
  lr <- survdiff(Surv(tte, event) ~ glp1_timing_2cat, data = df)
  1 - pchisq(lr$chisq, df = length(lr$n) - 1)
}

cox_unadj <- function(df) {
  fit <- coxph(Surv(tte, event) ~ glp1_timing_2cat, data = df)
  ci <- exp(confint(fit)); hr <- exp(coef(fit))[1]
  p  <- summary(fit)$coefficients[1, "Pr(>|z|)"]
  list(hr = hr, lcl = ci[1,1], ucl = ci[1,2], p = p, fit = fit)
}

cox_adj <- function(df, covar_rhs) {
  f <- as.formula(paste("Surv(tte, event) ~ glp1_timing_2cat +", covar_rhs))
  fit <- tryCatch(coxph(f, data = df), error = function(e) NULL)
  if (is.null(fit)) return(list(hr = NA, lcl = NA, ucl = NA, p = NA, fit = NULL))
  cf <- "glp1_timing_2catLate (>= 6 months)"
  ci <- exp(confint(fit))
  list(hr = exp(coef(fit))[cf], lcl = ci[cf,1], ucl = ci[cf,2],
       p = summary(fit)$coefficients[cf, "Pr(>|z|)"], fit = fit)
}

fmt_hr <- function(hr, lcl, ucl, p = NULL) {
  if (is.na(hr)) return("--")
  base <- sprintf("%.2f (%.2f-%.2f)", hr, lcl, ucl)
  if (!is.null(p) && !is.na(p))
    base <- sprintf("%s, p=%s", base, ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
  base
}
fmt_p <- function(p) ifelse(is.na(p), "--", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))

cov_weight <- "current_age + bmi_baseline_combined + parity_cat + delivery_mode_simple + ckm_t2dm + preg_gdm + glp1_agent_simple"
cov_bp     <- "current_age + bmi_baseline_combined + preg_preec_any_spectrum + ckm_t2dm + preg_gdm + glp1_agent_simple + bp_med_any"

# =============================================================================
# 6. BUILD OUTCOME BLOCKS
# =============================================================================
build_outcome_block <- function(label, df, cov_rhs) {
  early <- df %>% filter(glp1_timing_2cat == "Early (< 6 months)")
  late  <- df %>% filter(glp1_timing_2cat == "Late (>= 6 months)")

  med_overall <- median_tte(df)
  med_early   <- median_tte_strata(df, "Early (< 6 months)")
  med_late    <- median_tte_strata(df, "Late (>= 6 months)")
  lr_p <- logrank_p(df)
  un   <- cox_unadj(df)
  ad   <- cox_adj(df, cov_rhs)

  tibble(
    Outcome = c(label, "  Early (< 6 mo)", "  Late (>= 6 mo)"),
    `n events / N at risk` = c(
      sprintf("%d / %d", sum(df$event), nrow(df)),
      sprintf("%d / %d", sum(early$event), nrow(early)),
      sprintf("%d / %d", sum(late$event),  nrow(late))
    ),
    `Median TTE, days (95% CI)` = c(med_overall, med_early, med_late),
    `Log-rank p` = c(fmt_p(lr_p), "", ""),
    `HR unadj (95% CI)` = c("", "1.00 (ref)", fmt_hr(un$hr, un$lcl, un$ucl, un$p)),
    `HR adj (95% CI)`   = c("", "1.00 (ref)", fmt_hr(ad$hr, ad$lcl, ad$ucl, ad$p))
  )
}

cat("--- Fitting Cox models (drug-anchored) ---\n")
A1_block <- build_outcome_block(">=10% weight loss",   A1c, cov_weight)
A2_block <- build_outcome_block(">=20% weight loss",   A2c, cov_weight)
A3_block <- build_outcome_block("Pre-pregnancy weight", A3c, cov_weight)
B1_block <- build_outcome_block(">=5 mmHg SBP drop",   B1c, cov_bp)
B2_block <- build_outcome_block(">=10 mmHg SBP drop",  B2c, cov_bp)
B3_block <- build_outcome_block(">=5 mmHg DBP drop",   B3c, cov_bp)

table3 <- bind_rows(A1_block, A2_block, A3_block)
table4 <- bind_rows(B1_block, B2_block, B3_block)

# =============================================================================
# 7. RENDER (MD + HTML)
# =============================================================================
cap3 <- paste("Table 3 (revised). Cox proportional hazards results for weight outcomes,",
              "anchored to GLP-1 initiation (time 0 = drug start), follow-up capped at 18 months on drug.",
              "Reference group: Early initiators (< 6 months postpartum).")
cap4 <- paste("Table 4. Cox proportional hazards results for blood-pressure outcomes",
              "in the HDP subgroup, anchored to GLP-1 initiation, follow-up capped at 18 months on drug.",
              "Reference group: Early initiators (< 6 months postpartum).")

md_table3 <- knitr::kable(table3, format = "pipe", caption = cap3) %>% paste(collapse = "\n")
md_table4 <- knitr::kable(table4, format = "pipe", caption = cap4) %>% paste(collapse = "\n")
writeLines(md_table3, file.path(md_dir, "table3_cox_weight.md"))
writeLines(md_table4, file.path(md_dir, "table4_cox_bp.md"))

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
      source_notes.border.bottom.style = "none"
    ) %>%
    tab_style(cell_borders(sides = "all", color = "#FFFFFF", weight = px(0)),
              list(cells_body(), cells_column_labels(), cells_title(), cells_source_notes())) %>%
    tab_style(cell_borders(sides = "top", color = "#000000", weight = px(2)),
              cells_column_labels()) %>%
    tab_style(cell_borders(sides = "bottom", color = "#000000", weight = px(1)),
              cells_column_labels()) %>%
    tab_style(cell_borders(sides = "bottom", color = "#000000", weight = px(2)),
              cells_body(rows = n_rows))
}

bold_rows_3 <- which(!startsWith(table3$Outcome, "  "))
bold_rows_4 <- which(!startsWith(table4$Outcome, "  "))

gt_table3 <- table3 %>% gt() %>%
  tab_header(title = md("**Table 3 (revised).** Cox PH results — weight outcomes (full cohort, drug-anchored)")) %>%
  tab_style(cell_text(weight = "bold"), cells_body(rows = bold_rows_3)) %>%
  tab_source_note(md(paste(
    "*Time 0 = GLP-1 initiation; administrative censoring at 18 months on drug.",
    "Adjusted Cox: age, baseline BMI, parity, delivery mode, T2DM, GDM, GLP-1 agent (semaglutide vs other).",
    "Reference: Early initiators (< 6 months postpartum). HR > 1 = Late group reaches event faster.*"))) %>%
  nejm_style()

gt_table4 <- table4 %>% gt() %>%
  tab_header(title = md("**Table 4.** Cox PH results — BP outcomes, HDP subgroup (drug-anchored)")) %>%
  tab_style(cell_text(weight = "bold"), cells_body(rows = bold_rows_4)) %>%
  tab_source_note(md(paste(
    "*HDP subgroup = pregnancy hypertension (any) OR baseline BP >=140/90.",
    "Time 0 = GLP-1 initiation; administrative censoring at 18 months on drug.",
    "Adjusted Cox: age, baseline BMI, preeclampsia spectrum, T2DM, GDM, GLP-1 agent, baseline antihypertensive use.",
    "Reference: Early initiators (< 6 months postpartum).*"))) %>%
  nejm_style()

gt::gtsave(gt_table3, file.path(html_dir, "table3_cox_weight.html"))
gt::gtsave(gt_table4, file.path(html_dir, "table4_cox_bp.html"))

# =============================================================================
# 8. PH ASSUMPTION CHECKS
# =============================================================================
cat("\n--- Proportional-hazards checks (Schoenfeld residuals) ---\n")
cat("(predictor p < 0.05 indicates PH violation)\n\n")
ph_check <- function(label, df, cov_rhs) {
  f <- as.formula(paste("Surv(tte, event) ~ glp1_timing_2cat +", cov_rhs))
  fit <- tryCatch(coxph(f, data = df), error = function(e) NULL)
  if (is.null(fit)) { cat(sprintf("%-25s : model failed\n", label)); return(invisible()) }
  zph <- tryCatch(cox.zph(fit), error = function(e) NULL)
  if (is.null(zph)) { cat(sprintf("%-25s : cox.zph failed\n", label)); return(invisible()) }
  gp <- zph$table["GLOBAL", "p"]; pp <- zph$table["glp1_timing_2cat", "p"]
  cat(sprintf("%-25s : GLOBAL p=%.3f, timing p=%.3f%s\n", label, gp, pp,
              ifelse(!is.na(pp) && pp < 0.05, " ** PH violation", "")))
}
ph_check("A1 (>=10% wt loss)",  A1c, cov_weight)
ph_check("A2 (>=20% wt loss)",  A2c, cov_weight)
ph_check("A3 (pre-preg weight)", A3c, cov_weight)
ph_check("B1 (>=5 mmHg SBP)",   B1c, cov_bp)
ph_check("B2 (>=10 mmHg SBP)",  B2c, cov_bp)
ph_check("B3 (>=5 mmHg DBP)",   B3c, cov_bp)

# =============================================================================
# 9. CONSOLE OUTPUT + SAVE
# =============================================================================
cat("\n================================================================\n")
cat(" TABLE 3 (revised) — WEIGHT OUTCOMES (drug-anchored)\n")
cat("================================================================\n\n")
cat(md_table3, "\n\n")
cat("================================================================\n")
cat(" TABLE 4 — BP OUTCOMES, HDP SUBGROUP (drug-anchored)\n")
cat("================================================================\n\n")
cat(md_table4, "\n\n")

cat("================================================================\n")
cat(" FILES CREATED\n")
cat("================================================================\n")
cat("MD:  ", file.path(md_dir, "table3_cox_weight.md"), "\n")
cat("     ", file.path(md_dir, "table4_cox_bp.md"), "\n")
cat("HTML:", file.path(html_dir, "table3_cox_weight.html"), "\n")
cat("     ", file.path(html_dir, "table4_cox_bp.html"), "\n")

saveRDS(list(A1 = A1c, A2 = A2c, A3 = A3c, B1 = B1c, B2 = B2c, B3 = B3c,
             anchor = "glp1"),
        file.path(data_dir, "tte_datasets.rds"))
cat("\nTTE datasets saved to:", file.path(data_dir, "tte_datasets.rds"), "\n")