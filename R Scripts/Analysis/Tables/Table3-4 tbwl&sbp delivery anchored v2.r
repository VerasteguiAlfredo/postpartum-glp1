# =============================================================================
# postpartum-glp1: Table 3 & Table 4 — Cox PH Survival Analyses
#                  *** DELIVERY-ANCHORED (PI revision, Dr. Adedinsewo) ***
#                  *** Reference group = LATE initiators (>= 6 months) ***
# -----------------------------------------------------------------------------
# Time origin = DELIVERY (day 0) for EVERY patient, on the same clock as the
# Figure 2-3 Kaplan-Meier curves.
#
# Reference group (per Dr. Adedinsewo): Late (>= 6 mo) initiators. HR therefore
# describes Early vs Late; HR > 1 = Early initiators reach the event faster.
#
# Covariate adjustment (per Dr. Adedinsewo, includes T2DM, obesity, OSA):
#   Weight outcomes: age, obesity (BMI >= 30), parity, delivery mode, T2DM,
#                    GDM, OSA, GLP-1 agent.
#   BP outcomes    : age, preeclampsia spectrum, T2DM, GDM, obesity, OSA,
#                    GLP-1 agent, baseline antihypertensive use.
#   Obesity is binary (BMI >= 30) rather than 4-level class to avoid separation.
#
# Six outcomes:
#   A1 >=10% weight loss (full cohort)   B1 >=5 mmHg SBP decline (HDP)
#   A2 >=20% weight loss (full cohort)   B2 >=10 mmHg SBP decline (HDP)
#   A3 return to pre-preg weight         B3 >=5 mmHg DBP decline (HDP)
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(survival)
  library(gt)
})

# =============================================================================
# PATHS (cross-platform)
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

cat("Loaded analysis_df:", nrow(analysis_df), "rows x", ncol(analysis_df), "cols\n")
cat("Loaded vitals_long:", nrow(vitals_long), "rows\n\n")

if (!"glp1_timing_2cat" %in% names(analysis_df))
  stop("glp1_timing_2cat not found. Re-run the build script first.")
if (!"obesity_bmi_baseline" %in% names(analysis_df))
  stop("obesity_bmi_baseline not found. Re-run the v4 build script first.")

# =============================================================================
# 1. PARAMETERS & DERIVED VARIABLES
# =============================================================================
DAYS_PER_MONTH     <- 30.44
FOLLOWUP_CAP       <- round(12 * DAYS_PER_MONTH)  # 365 d
BP_BASELINE_WINDOW <- 2
BP_EVENT_START_DAY <- 14

analysis_df <- analysis_df %>%
  mutate(pre_preg_weight_kg = PREGRAVID_BMI * (height_cm / 100)^2)

analysis_df <- analysis_df %>%
  mutate(
    bp_baseline_stage2 = (!is.na(sbp_baseline_combined) & sbp_baseline_combined >= 140) |
                         (!is.na(dbp_baseline_combined) & dbp_baseline_combined >= 90),
    hdp_cohort = (preg_htn_any == TRUE) | bp_baseline_stage2
  )

full_ids <- analysis_df$CURR_CLINIC
hdp_ids  <- analysis_df %>% filter(hdp_cohort) %>% pull(CURR_CLINIC)

cat("Full cohort:", length(full_ids), "| HDP subgroup:", length(hdp_ids), "\n")
cat("Pre-pregnancy weight available:", sum(!is.na(analysis_df$pre_preg_weight_kg)), "\n\n")

# =============================================================================
# 2. DELIVERY-ANCHORED BASELINES
# =============================================================================
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

# =============================================================================
# 3. CORE TTE BUILDER — DELIVERY-ANCHORED
# =============================================================================
build_tte_delivery <- function(vital_name, baseline_df, event_fn, cohort_ids,
                               cap = FOLLOWUP_CAP, event_start_day = 0) {
  vitals_long %>%
    filter(vital == vital_name,
           days_from_delivery >= event_start_day,
           days_from_delivery <= cap,
           !is.na(value),
           CURR_CLINIC %in% cohort_ids) %>%
    inner_join(baseline_df, by = "CURR_CLINIC") %>%
    mutate(is_event = event_fn(value, baseline)) %>%
    group_by(CURR_CLINIC) %>%
    summarise(
      last_day        = max(days_from_delivery),
      first_event_day = if (any(is_event)) min(days_from_delivery[is_event]) else NA_real_,
      .groups = "drop"
    ) %>%
    mutate(
      event    = as.integer(!is.na(first_event_day)),
      tte_days = pmin(ifelse(event == 1, first_event_day, last_day), cap),
      tte_days = ifelse(tte_days <= 0, 0.5, tte_days),
      tte      = tte_days / DAYS_PER_MONTH
    ) %>%
    select(CURR_CLINIC, tte, event)
}

# =============================================================================
# 4. BUILD 6 TTE DATASETS  (event_start_day passed BY NAME — do not pass positionally)
# =============================================================================
cat("--- Building delivery-anchored TTE datasets ---\n")

A1 <- build_tte_delivery("weight_kg", wt_base,      function(v, b) v <= b * 0.90, full_ids, event_start_day = 0)
A2 <- build_tte_delivery("weight_kg", wt_base,      function(v, b) v <= b * 0.80, full_ids, event_start_day = 0)
A3 <- build_tte_delivery("weight_kg", prepreg_base, function(v, b) v <= b,        full_ids, event_start_day = 0)
B1 <- build_tte_delivery("sbp", sbp_base, function(v, b) (b - v) >= 5,  hdp_ids, event_start_day = BP_EVENT_START_DAY)
B2 <- build_tte_delivery("sbp", sbp_base, function(v, b) (b - v) >= 10, hdp_ids, event_start_day = BP_EVENT_START_DAY)
B3 <- build_tte_delivery("dbp", dbp_base, function(v, b) (b - v) >= 5,  hdp_ids, event_start_day = BP_EVENT_START_DAY)

for (nm in c("A1","A2","A3","B1","B2","B3")) {
  d <- get(nm)
  cat(sprintf("  %s: n = %d, events = %d\n", nm, nrow(d), sum(d$event)))
}
cat("\n")

# =============================================================================
# 5. COVARIATES  (binary obesity + OSA included; Late = reference)
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
  select(CURR_CLINIC, glp1_timing_2cat, current_age, obesity_bmi_baseline,
         parity_cat, delivery_mode_simple, ckm_t2dm, preg_gdm, ckm_osa,
         glp1_agent_simple, preg_preec_any_spectrum, bp_med_any)

attach_covs <- function(tte_df) {
  tte_df %>%
    inner_join(covariates, by = "CURR_CLINIC") %>%
    mutate(glp1_timing_2cat = relevel(factor(
      glp1_timing_2cat,
      levels = c("Early (< 6 months)", "Late (>= 6 months)")),
      ref = "Late (>= 6 months)"))
}

A1c <- attach_covs(A1); A2c <- attach_covs(A2); A3c <- attach_covs(A3)
B1c <- attach_covs(B1); B2c <- attach_covs(B2); B3c <- attach_covs(B3)

cat("After covariate attach:\n")
for (nm in c("A1c","A2c","A3c","B1c","B2c","B3c")) {
  d <- get(nm)
  cat(sprintf("  %s: n = %d, events = %d\n", nm, nrow(d), sum(d$event)))
}
cat("\n")

# =============================================================================
# 6. ANALYSIS FUNCTIONS
# =============================================================================
median_tte <- function(df) {
  fit <- survfit(Surv(tte, event) ~ 1, data = df)
  sm  <- summary(fit)$table
  med <- sm["median"]; lcl <- sm["0.95LCL"]; ucl <- sm["0.95UCL"]
  if (is.na(med)) return("NR")
  sprintf("%.1f (%.1f-%.1f)", med,
          ifelse(is.na(lcl), NA, lcl), ifelse(is.na(ucl), NA, ucl))
}
median_tte_strata <- function(df, level) {
  sub <- df %>% filter(glp1_timing_2cat == level)
  if (nrow(sub) < 5) return("--")
  median_tte(sub)
}
logrank_p <- function(df) {
  if (length(unique(df$glp1_timing_2cat)) < 2) return(NA_real_)
  lr <- survdiff(Surv(tte, event) ~ glp1_timing_2cat, data = df)
  pchisq(lr$chisq, df = length(lr$n) - 1, lower.tail = FALSE)
}
cox_unadj <- function(df) {
  fit <- coxph(Surv(tte, event) ~ glp1_timing_2cat, data = df)
  ci  <- exp(confint(fit)); hr <- exp(coef(fit))[1]
  p   <- summary(fit)$coefficients[1, "Pr(>|z|)"]
  list(hr = hr, lcl = ci[1,1], ucl = ci[1,2], p = p, fit = fit)
}
cox_adj <- function(df, covar_rhs) {
  f   <- as.formula(paste("Surv(tte, event) ~ glp1_timing_2cat +", covar_rhs))
  fit <- tryCatch(coxph(f, data = df), error = function(e) NULL)
  if (is.null(fit)) return(list(hr = NA, lcl = NA, ucl = NA, p = NA, fit = NULL))
  cf <- "glp1_timing_2catEarly (< 6 months)"   # Late = reference => Early is the contrast
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

cov_weight <- paste("current_age + parity_cat + delivery_mode_simple +",
                    "ckm_t2dm + preg_gdm + obesity_bmi_baseline + ckm_osa + glp1_agent_simple")
cov_bp     <- paste("current_age + preg_preec_any_spectrum + ckm_t2dm +",
                    "preg_gdm + obesity_bmi_baseline + ckm_osa + glp1_agent_simple + bp_med_any")

# =============================================================================
# 7. BUILD OUTCOME BLOCKS  (Late listed first as the reference row)
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
    Outcome = c(label, "  Late (>= 6 mo, ref)", "  Early (< 6 mo)"),
    `n events / N at risk` = c(
      sprintf("%d / %d", sum(df$event), nrow(df)),
      sprintf("%d / %d", sum(late$event),  nrow(late)),
      sprintf("%d / %d", sum(early$event), nrow(early))
    ),
    `Median TTE, months (95% CI)` = c(med_overall, med_late, med_early),
    `Log-rank p` = c(fmt_p(lr_p), "", ""),
    `HR unadj (95% CI)` = c("", "1.00 (ref)", fmt_hr(un$hr, un$lcl, un$ucl, un$p)),
    `HR adj (95% CI)`   = c("", "1.00 (ref)", fmt_hr(ad$hr, ad$lcl, ad$ucl, ad$p))
  )
}

cat("--- Fitting Cox models (delivery-anchored, Late = ref) ---\n")
A1_block <- build_outcome_block(">=10% weight loss",    A1c, cov_weight)
A2_block <- build_outcome_block(">=20% weight loss",    A2c, cov_weight)
A3_block <- build_outcome_block("Pre-pregnancy weight", A3c, cov_weight)
B1_block <- build_outcome_block(">=5 mmHg SBP decline",  B1c, cov_bp)
B2_block <- build_outcome_block(">=10 mmHg SBP decline", B2c, cov_bp)
B3_block <- build_outcome_block(">=5 mmHg DBP decline",  B3c, cov_bp)

table3 <- bind_rows(A1_block, A2_block, A3_block)
table4 <- bind_rows(B1_block, B2_block, B3_block)

# =============================================================================
# 8. RENDER (MD + HTML)
# =============================================================================
cap3 <- paste("Table 3. Cox proportional hazards results for weight outcomes,",
              "anchored to delivery (time 0 = delivery), follow-up through 12 months postpartum.",
              "Reference group: Late initiators (>= 6 months postpartum).")
cap4 <- paste("Table 4. Cox proportional hazards results for blood-pressure outcomes",
              "in the HDP subgroup, anchored to delivery, follow-up through 12 months postpartum.",
              "Reference group: Late initiators (>= 6 months postpartum).")

md_table3 <- knitr::kable(table3, format = "pipe", caption = cap3) %>% paste(collapse = "\n")
md_table4 <- knitr::kable(table4, format = "pipe", caption = cap4) %>% paste(collapse = "\n")
writeLines(md_table3, file.path(md_dir, "table3_cox_weight_delivery.md"))
writeLines(md_table4, file.path(md_dir, "table4_cox_bp_delivery.md"))

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
    tab_style(cell_borders(sides = "top", color = "#000000", weight = px(2)), cells_column_labels()) %>%
    tab_style(cell_borders(sides = "bottom", color = "#000000", weight = px(1)), cells_column_labels()) %>%
    tab_style(cell_borders(sides = "bottom", color = "#000000", weight = px(2)), cells_body(rows = n_rows))
}

bold_rows_3 <- which(!startsWith(table3$Outcome, "  "))
bold_rows_4 <- which(!startsWith(table4$Outcome, "  "))

gt_table3 <- table3 %>% gt() %>%
  tab_header(title = md("**Table 3.** Cox PH results — weight outcomes (full cohort, delivery-anchored)")) %>%
  tab_style(cell_text(weight = "bold"), cells_body(rows = bold_rows_3)) %>%
  tab_source_note(md(paste(
    "*Time 0 = delivery; administrative censoring at 12 months postpartum.",
    "Weight baseline = earliest postpartum measurement.",
    "Adjusted Cox: age, obesity (BMI >=30), parity, delivery mode, T2DM, GDM, OSA, GLP-1 agent (semaglutide vs other).",
    "Reference: Late initiators (>= 6 months postpartum). HR > 1 = Early group reaches the event faster.",
    "On the delivery clock the comparison is a natural-history association (Late untreated months 0-6),",
    "not a clean on-treatment effect.*"))) %>%
  nejm_style()

gt_table4 <- table4 %>% gt() %>%
  tab_header(title = md("**Table 4.** Cox PH results — BP outcomes, HDP subgroup (delivery-anchored)")) %>%
  tab_style(cell_text(weight = "bold"), cells_body(rows = bold_rows_4)) %>%
  tab_source_note(md(paste(
    "*HDP subgroup = pregnancy hypertension (any) OR baseline BP >=140/90.",
    "Time 0 = delivery; BP baseline = single value within +/-2 d of delivery;",
    "14-day blanking before event ascertainment; censoring at 12 months postpartum.",
    "Adjusted Cox: age, preeclampsia spectrum, T2DM, GDM, obesity (BMI >=30), OSA, GLP-1 agent, baseline antihypertensive use.",
    "Reference: Late initiators (>= 6 months postpartum). Interpret with the PH check below;",
    "BP curves converge early and may violate proportional hazards.*"))) %>%
  nejm_style()

gt::gtsave(gt_table3, file.path(html_dir, "table3_cox_weight_delivery.html"))
gt::gtsave(gt_table4, file.path(html_dir, "table4_cox_bp_delivery.html"))

# =============================================================================
# 9. PH ASSUMPTION CHECKS
# =============================================================================
cat("\n--- Proportional-hazards checks (Schoenfeld residuals) ---\n")
ph_check <- function(label, df, cov_rhs) {
  f   <- as.formula(paste("Surv(tte, event) ~ glp1_timing_2cat +", cov_rhs))
  fit <- tryCatch(coxph(f, data = df), error = function(e) NULL)
  if (is.null(fit)) { cat(sprintf("%-25s : model failed\n", label)); return(invisible()) }
  zph <- tryCatch(cox.zph(fit), error = function(e) NULL)
  if (is.null(zph)) { cat(sprintf("%-25s : cox.zph failed\n", label)); return(invisible()) }
  gp <- zph$table["GLOBAL", "p"]; pp <- zph$table["glp1_timing_2cat", "p"]
  cat(sprintf("%-25s : GLOBAL p=%.3f, timing p=%.3f%s\n", label, gp, pp,
              ifelse(!is.na(pp) && pp < 0.05, " ** PH violation", "")))
}
ph_check("A1 (>=10% wt loss)",   A1c, cov_weight)
ph_check("A2 (>=20% wt loss)",   A2c, cov_weight)
ph_check("A3 (pre-preg weight)", A3c, cov_weight)
ph_check("B1 (>=5 mmHg SBP)",    B1c, cov_bp)
ph_check("B2 (>=10 mmHg SBP)",   B2c, cov_bp)
ph_check("B3 (>=5 mmHg DBP)",    B3c, cov_bp)

# =============================================================================
# 10. CONSOLE OUTPUT + SAVE
# =============================================================================
cat("\n================================================================\n")
cat(" TABLE 3 — WEIGHT OUTCOMES (delivery-anchored, Late = ref)\n")
cat("================================================================\n\n")
cat(md_table3, "\n\n")
cat("================================================================\n")
cat(" TABLE 4 — BP OUTCOMES, HDP SUBGROUP (delivery-anchored, Late = ref)\n")
cat("================================================================\n\n")
cat(md_table4, "\n\n")

saveRDS(list(A1 = A1c, A2 = A2c, A3 = A3c, B1 = B1c, B2 = B2c, B3 = B3c,
             anchor = "delivery", reference = "Late (>= 6 months)"),
        file.path(data_dir, "tte_datasets_delivery.rds"))
cat("TTE datasets saved to:", file.path(data_dir, "tte_datasets_delivery.rds"), "\n")