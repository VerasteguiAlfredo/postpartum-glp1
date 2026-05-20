# =============================================================================
# Audit: Why is the < 6 weeks GLP-1 stratum missing baseline vitals?
# -----------------------------------------------------------------------------
# Hypothesis to test:
#   These 24 patients started GLP-1 too soon postpartum (<42 days) to satisfy
#   the PRIMARY baseline rule. But they may still have vitals captured at:
#     (a) the delivery encounter,
#     (b) immediate postpartum hospital stay,
#     (c) 1-6 week postpartum visit (before GLP-1 start).
#
# Goal: Quantify what's available for these patients so we can decide whether
# to relax the baseline rule for the <6 weeks group or to leave NAs.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
})

if (!exists("analysis_df")) {
  proj_root <- "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
  analysis_df <- readRDS(file.path(proj_root, "data_processed", "analysis_df.rds"))
  vitals_long <- readRDS(file.path(proj_root, "data_processed", "vitals_long.rds"))
}

# Subset to the 24 early-starters
early_ids <- analysis_df %>%
  filter(glp1_timing_cat == "< 6 weeks") %>%
  pull(CURR_CLINIC)

cat("================================================================\n")
cat(" AUDIT: < 6 weeks GLP-1 stratum (N =", length(early_ids), " patients)\n")
cat("================================================================\n\n")

# What's their GLP-1 start timing?
cat("--- 1. Days from delivery to GLP-1 start ---\n")
early_timing <- analysis_df %>%
  filter(CURR_CLINIC %in% early_ids) %>%
  select(CURR_CLINIC, delv_date, glp1_index_date, days_pp_to_glp1)
print(summary(early_timing$days_pp_to_glp1))
cat("\nDistribution:\n")
print(table(cut(early_timing$days_pp_to_glp1,
                breaks = c(-1, 0, 7, 14, 21, 28, 35, 42),
                labels = c("delivery day", "1-7d", "8-14d", "15-21d",
                           "22-28d", "29-35d", "36-41d"))))
cat("\n")

# What vitals do they have, anywhere in the window we looked at?
cat("--- 2. ANY vitals captured around delivery (delivery-90d to delivery+365d) ---\n")
vitals_early <- vitals_long %>%
  filter(CURR_CLINIC %in% early_ids)

cat("Total vital measurements for these 24 patients:", nrow(vitals_early), "\n")
cat("Unique patients with ANY vital captured:", n_distinct(vitals_early$CURR_CLINIC), "\n\n")

cat("Measurements by vital type:\n")
print(vitals_early %>% count(vital))
cat("\n")

# Stratify by timing relative to delivery AND GLP-1 start
cat("--- 3. Where (in time) do their vitals fall? ---\n\n")

# Time-window flags for each measurement
vitals_early_flagged <- vitals_early %>%
  mutate(
    days_window = case_when(
      days_from_delivery <  0                          ~ "pre-delivery (90d before)",
      days_from_delivery == 0                          ~ "delivery day",
      days_from_delivery >= 1   & days_from_delivery <= 7   ~ "1-7d postpartum (hospital stay)",
      days_from_delivery >= 8   & days_from_delivery <= 14  ~ "8-14d postpartum",
      days_from_delivery >= 15  & days_from_delivery <= 28  ~ "15-28d postpartum",
      days_from_delivery >= 29  & days_from_delivery <= 41  ~ "29-41d postpartum (pre-6wk)",
      days_from_delivery >= 42  & days_from_delivery <= 90  ~ "42-90d postpartum (6wk-3mo)",
      days_from_delivery >= 91  & days_from_delivery <= 180 ~ "3-6mo postpartum",
      days_from_delivery >= 181 & days_from_delivery <= 365 ~ "6-12mo postpartum"
    ),
    relative_to_glp1 = case_when(
      days_from_glp1 <  0  ~ "pre-GLP1",
      days_from_glp1 == 0  ~ "GLP1 start day",
      days_from_glp1 >  0  ~ "post-GLP1"
    )
  )

cat("Counts of measurements by window and pre/post GLP-1 status:\n")
print(
  vitals_early_flagged %>%
    count(vital, days_window, relative_to_glp1) %>%
    pivot_wider(names_from = relative_to_glp1, values_from = n, values_fill = 0) %>%
    arrange(vital, days_window)
)
cat("\n")

# Most important question: do these patients have ANY pre-GLP-1 vital measurement
# (i.e., is the sensitivity baseline possible)?
cat("--- 4. Pre-GLP-1 measurement availability per patient ---\n\n")

pre_glp1_availability <- vitals_early_flagged %>%
  filter(relative_to_glp1 == "pre-GLP1") %>%
  group_by(CURR_CLINIC, vital) %>%
  summarise(
    n_measurements = n(),
    earliest_days_from_delivery = min(days_from_delivery, na.rm = TRUE),
    latest_days_from_delivery   = max(days_from_delivery, na.rm = TRUE),
    .groups = "drop"
  )

cat("Patients with ANY pre-GLP-1 vital measurement:\n")
print(
  pre_glp1_availability %>%
    count(vital, name = "n_patients_with_data") %>%
    mutate(pct_of_24 = round(100 * n_patients_with_data / 24, 1))
)
cat("\n")

# Specifically: how many patients could have a sensitivity baseline (≥0 days pp, before GLP-1)?
cat("--- 5. Sensitivity baseline coverage for the <6 weeks group ---\n\n")

cat("Per current build script, sensitivity baseline = closest pre-GLP-1 measurement\n")
cat("within 90 days before GLP-1 start (no 42-day floor).\n\n")

sens_coverage <- analysis_df %>%
  filter(CURR_CLINIC %in% early_ids) %>%
  summarise(
    has_sbp_sens     = sum(!is.na(sbp_baseline_sens)),
    has_dbp_sens     = sum(!is.na(dbp_baseline_sens)),
    has_weight_sens  = sum(!is.na(weight_kg_baseline_sens)),
    has_sbp_primary  = sum(!is.na(sbp_baseline_primary)),
    has_weight_primary = sum(!is.na(weight_kg_baseline_primary))
  )
print(sens_coverage)
cat("\n")

cat("--- 6. Sample-level snapshot: first 5 patients in the <6 weeks group ---\n\n")
sample_ids <- head(early_ids, 5)
for (pid in sample_ids) {
  cat("Patient", pid, ":\n")
  pt_info <- analysis_df %>%
    filter(CURR_CLINIC == pid) %>%
    select(delv_date, glp1_index_date, days_pp_to_glp1,
           sbp_baseline_primary, sbp_baseline_sens,
           weight_kg_baseline_primary, weight_kg_baseline_sens)
  cat("  delv:", as.character(pt_info$delv_date),
      " GLP-1 start:", as.character(pt_info$glp1_index_date),
      " (day", pt_info$days_pp_to_glp1, "pp)\n")
  cat("  Primary SBP baseline:", pt_info$sbp_baseline_primary,
      "| Sens SBP baseline:", pt_info$sbp_baseline_sens, "\n")
  cat("  Primary weight:     ", pt_info$weight_kg_baseline_primary,
      "| Sens weight:     ", pt_info$weight_kg_baseline_sens, "\n")

  # Show all their vitals around delivery
  pt_vitals <- vitals_early_flagged %>%
    filter(CURR_CLINIC == pid) %>%
    arrange(meas_date) %>%
    select(vital, meas_date, value, days_from_delivery, days_from_glp1)
  cat("  Available measurements (", nrow(pt_vitals), " total):\n", sep = "")
  if (nrow(pt_vitals) > 0) {
    print(pt_vitals %>% head(10))
  } else {
    cat("    (none captured in delivery±window)\n")
  }
  cat("\n")
}

cat("================================================================\n")
cat(" CONCLUSIONS\n")
cat("================================================================\n")
cat("Compare:\n")
cat("  primary baseline coverage (≥42d postpartum requirement)\n")
cat("  sensitivity baseline coverage (no 42d floor)\n")
cat("\n")
cat("If sensitivity baseline recovers most patients, we can use it for the\n")
cat("<6 weeks stratum and footnote the deviation.\n")
cat("If both are NA, those patients literally have no pre-GLP-1 measurement\n")
cat("captured in EHR — no methodological fix is possible.\n")