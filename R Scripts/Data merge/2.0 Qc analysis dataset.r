# =============================================================================
# postpartum-glp1: QC / Sanity Checks on Merged Dataset
# -----------------------------------------------------------------------------
# Purpose: Validate the output of build_analysis_dataset.R before any modeling.
#
# Run this AFTER build_analysis_dataset.R has been sourced (objects in memory)
# OR standalone by loading the .rds files from data_processed/.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(stringr)
  library(ggplot2)
})

# --- Path setup (matches build script) ---
sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "~/Documents/postpartum-glp1"
} else {
  "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1"
}
out_dir <- file.path(proj_root, "data_processed")

# --- Load if not already in memory ---
if (!exists("analysis_df")) analysis_df <- readRDS(file.path(out_dir, "analysis_df.rds"))
if (!exists("vitals_long")) vitals_long <- readRDS(file.path(out_dir, "vitals_long.rds"))
if (!exists("events_df"))   events_df   <- readRDS(file.path(out_dir, "events_df.rds"))

cat("================================================================\n")
cat(" QC REPORT: postpartum-glp1 analysis dataset\n")
cat("================================================================\n\n")

# =============================================================================
# 1. STRUCTURE & DIMENSIONS
# =============================================================================
cat("--- 1. Structure ---\n")
cat("analysis_df: ", nrow(analysis_df), "rows ×", ncol(analysis_df), "cols\n")
cat("vitals_long: ", nrow(vitals_long), "rows\n")
cat("events_df:   ", nrow(events_df), "rows\n\n")

# Unique patient counts should match
stopifnot(n_distinct(analysis_df$CURR_CLINIC) == nrow(analysis_df))
cat("✓ analysis_df has one row per CURR_CLINIC\n\n")

# =============================================================================
# 2. EXPOSURE TIMING DISTRIBUTION
# =============================================================================
cat("--- 2. GLP-1 Exposure Timing ---\n")
timing <- analysis_df %>%
  filter(glp1_postpartum_exposed) %>%
  summarise(
    n               = n(),
    median_days     = median(days_pp_to_glp1, na.rm = TRUE),
    q25_days        = quantile(days_pp_to_glp1, 0.25, na.rm = TRUE),
    q75_days        = quantile(days_pp_to_glp1, 0.75, na.rm = TRUE),
    min_days        = min(days_pp_to_glp1, na.rm = TRUE),
    max_days        = max(days_pp_to_glp1, na.rm = TRUE),
    early_pp_lt_30  = sum(days_pp_to_glp1 < 30,  na.rm = TRUE),
    early_pp_lt_90  = sum(days_pp_to_glp1 < 90,  na.rm = TRUE),
    late_pp_gt_180  = sum(days_pp_to_glp1 > 180, na.rm = TRUE)
  )
print(timing)
cat("\n")

cat("Distribution of postpartum GLP-1 start (days from delivery):\n")
print(quantile(analysis_df$days_pp_to_glp1, probs = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
               na.rm = TRUE))
cat("\n")

# Breakdown by drug
cat("First postpartum GLP-1 drug:\n")
print(analysis_df %>% count(glp1_first_drug, sort = TRUE))
cat("\n")

cat("Weight-loss-branded as first drug:\n")
print(analysis_df %>% count(glp1_first_brand_wl))
cat("\n")

# =============================================================================
# 3. BASELINE DEMOGRAPHICS
# =============================================================================
cat("--- 3. Baseline Demographics ---\n")
cat("Age at delivery (current_age proxy):\n")
print(summary(analysis_df$current_age))
cat("\n")

cat("Race (primary):\n")
print(analysis_df %>% count(race_primary, sort = TRUE))
cat("\n")

cat("Ethnicity:\n")
print(analysis_df %>% count(Ethnicity_Name, sort = TRUE))
cat("\n")

# =============================================================================
# 4. DATA CAPTURE COMPLETENESS
# =============================================================================
cat("--- 4. Data Capture (baseline + each follow-up window) ---\n")

capture_tbl <- tibble(
  variable = c("SBP", "DBP", "Weight (kg)"),
  baseline = c(sum(!is.na(analysis_df$sbp_baseline)),
               sum(!is.na(analysis_df$dbp_baseline)),
               sum(!is.na(analysis_df$weight_kg_baseline))),
  m1       = c(sum(!is.na(analysis_df$sbp_m1)),
               sum(!is.na(analysis_df$dbp_m1)),
               sum(!is.na(analysis_df$weight_kg_m1))),
  m3       = c(sum(!is.na(analysis_df$sbp_m3)),
               sum(!is.na(analysis_df$dbp_m3)),
               sum(!is.na(analysis_df$weight_kg_m3))),
  m6       = c(sum(!is.na(analysis_df$sbp_m6)),
               sum(!is.na(analysis_df$dbp_m6)),
               sum(!is.na(analysis_df$weight_kg_m6))),
  m12      = c(sum(!is.na(analysis_df$sbp_m12)),
               sum(!is.na(analysis_df$dbp_m12)),
               sum(!is.na(analysis_df$weight_kg_m12))),
  N_total  = nrow(analysis_df)
)
print(capture_tbl)
cat("\n")

# Paired data availability (have both baseline AND m6 / m12)
cat("Paired analysis N (have both baseline AND follow-up):\n")
paired_tbl <- tibble(
  pair = c("SBP baseline + m6",
           "SBP baseline + m12",
           "DBP baseline + m6",
           "DBP baseline + m12",
           "Weight baseline + m6",
           "Weight baseline + m12"),
  n_paired = c(
    sum(!is.na(analysis_df$sbp_baseline)       & !is.na(analysis_df$sbp_m6)),
    sum(!is.na(analysis_df$sbp_baseline)       & !is.na(analysis_df$sbp_m12)),
    sum(!is.na(analysis_df$dbp_baseline)       & !is.na(analysis_df$dbp_m6)),
    sum(!is.na(analysis_df$dbp_baseline)       & !is.na(analysis_df$dbp_m12)),
    sum(!is.na(analysis_df$weight_kg_baseline) & !is.na(analysis_df$weight_kg_m6)),
    sum(!is.na(analysis_df$weight_kg_baseline) & !is.na(analysis_df$weight_kg_m12))
  )
)
print(paired_tbl)
cat("\n")

# =============================================================================
# 5. PHYSIOLOGIC SANITY OF VITALS
# =============================================================================
cat("--- 5. Vitals: Plausibility ---\n")

cat("Baseline SBP:\n");    print(summary(analysis_df$sbp_baseline))
cat("\nBaseline DBP:\n");  print(summary(analysis_df$dbp_baseline))
cat("\nBaseline Weight (kg):\n"); print(summary(analysis_df$weight_kg_baseline))
cat("\nBaseline BMI (calc):\n"); print(summary(analysis_df$bmi_baseline))
cat("\n")

# Flag implausible values
implausible <- analysis_df %>%
  summarise(
    sbp_lt_80     = sum(sbp_baseline < 80,  na.rm = TRUE),
    sbp_gt_200    = sum(sbp_baseline > 200, na.rm = TRUE),
    dbp_lt_40     = sum(dbp_baseline < 40,  na.rm = TRUE),
    dbp_gt_130    = sum(dbp_baseline > 130, na.rm = TRUE),
    weight_lt_45  = sum(weight_kg_baseline < 45,  na.rm = TRUE),
    weight_gt_200 = sum(weight_kg_baseline > 200, na.rm = TRUE),
    bmi_lt_18     = sum(bmi_baseline < 18,  na.rm = TRUE),
    bmi_gt_70     = sum(bmi_baseline > 70,  na.rm = TRUE)
  )
cat("Implausible-value counts:\n"); print(implausible); cat("\n")

# =============================================================================
# 6. PAIRED PRE/POST PEEK — IS THE DIRECTION SENSIBLE?
# =============================================================================
cat("--- 6. Pre/Post Direction Check (descriptive only) ---\n")

paired_summary <- analysis_df %>%
  summarise(
    sbp_baseline_med  = median(sbp_baseline,  na.rm = TRUE),
    sbp_m6_med        = median(sbp_m6,        na.rm = TRUE),
    sbp_m12_med       = median(sbp_m12,       na.rm = TRUE),
    dbp_baseline_med  = median(dbp_baseline,  na.rm = TRUE),
    dbp_m6_med        = median(dbp_m6,        na.rm = TRUE),
    dbp_m12_med       = median(dbp_m12,       na.rm = TRUE),
    wt_baseline_med   = median(weight_kg_baseline, na.rm = TRUE),
    wt_m6_med         = median(weight_kg_m6,       na.rm = TRUE),
    wt_m12_med        = median(weight_kg_m12,      na.rm = TRUE)
  )
print(paired_summary %>% pivot_longer(everything()))
cat("\n")

# Quick paired Wilcoxon at 6m and 12m (descriptive — not your final test)
cat("Paired Wilcoxon signed-rank (baseline vs m6, m12):\n")
quiet_wilcox <- function(x, y, label) {
  ok <- !is.na(x) & !is.na(y)
  if (sum(ok) < 10) {
    cat(sprintf("  %-30s n=%-4d  (too few pairs)\n", label, sum(ok)))
    return(invisible(NULL))
  }
  w <- suppressWarnings(wilcox.test(x[ok], y[ok], paired = TRUE))
  cat(sprintf("  %-30s n=%-4d  median Δ=%+.2f   p=%.4g\n",
              label, sum(ok), median(x[ok] - y[ok]), w$p.value))
}
with(analysis_df, {
  quiet_wilcox(sbp_baseline, sbp_m6,        "SBP baseline → m6")
  quiet_wilcox(sbp_baseline, sbp_m12,       "SBP baseline → m12")
  quiet_wilcox(dbp_baseline, dbp_m6,        "DBP baseline → m6")
  quiet_wilcox(dbp_baseline, dbp_m12,       "DBP baseline → m12")
  quiet_wilcox(weight_kg_baseline, weight_kg_m6,  "Weight baseline → m6")
  quiet_wilcox(weight_kg_baseline, weight_kg_m12, "Weight baseline → m12")
})
cat("\n")

# =============================================================================
# 7. EVENT RATES (time-to-event endpoints)
# =============================================================================
cat("--- 7. Event Rates ---\n")
event_rates <- analysis_df %>%
  summarise(
    n              = n(),
    sbp_drop_10_n  = sum(sbp_event, na.rm = TRUE),
    sbp_drop_10_pct= mean(sbp_event, na.rm = TRUE) * 100,
    dbp_drop_5_n   = sum(dbp_event, na.rm = TRUE),
    dbp_drop_5_pct = mean(dbp_event, na.rm = TRUE) * 100,
    wt_loss_10_n   = sum(wt_event,  na.rm = TRUE),
    wt_loss_10_pct = mean(wt_event,  na.rm = TRUE) * 100
  )
print(event_rates)
cat("\n")

cat("Time-to-event among those who had it (median days):\n")
tte_summary <- analysis_df %>%
  summarise(
    sbp_tte_med = median(sbp_tte, na.rm = TRUE),
    dbp_tte_med = median(dbp_tte, na.rm = TRUE),
    wt_tte_med  = median(wt_tte,  na.rm = TRUE)
  )
print(tte_summary)
cat("\n")

# =============================================================================
# 8. COMORBIDITY PREVALENCE
# =============================================================================
cat("--- 8. Comorbidity Prevalence (pre-index) ---\n")
cm_cols <- grep("^cm_", names(analysis_df), value = TRUE)
cm_prev <- analysis_df %>%
  summarise(across(all_of(cm_cols), ~ sum(., na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "comorbidity", values_to = "n") %>%
  mutate(pct = round(100 * n / nrow(analysis_df), 1)) %>%
  arrange(desc(n))
print(cm_prev)
cat("\n")

# =============================================================================
# 9. CONCOMITANT MEDICATIONS
# =============================================================================
cat("--- 9. Concomitant Meds (active near index) ---\n")
med_cols <- grep("^med_", names(analysis_df), value = TRUE)
med_prev <- analysis_df %>%
  summarise(across(all_of(med_cols), ~ sum(., na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "medication", values_to = "n") %>%
  mutate(pct = round(100 * n / nrow(analysis_df), 1)) %>%
  arrange(desc(n))
print(med_prev)
cat("\n")

# =============================================================================
# 10. LAB CAPTURE
# =============================================================================
cat("--- 10. Lab Capture (pre-index) ---\n")
lab_cols <- grep("^lab_.*_value$", names(analysis_df), value = TRUE)
lab_capture <- analysis_df %>%
  summarise(across(all_of(lab_cols), ~ sum(!is.na(.)))) %>%
  pivot_longer(everything(), names_to = "lab", values_to = "n_with_value") %>%
  mutate(pct = round(100 * n_with_value / nrow(analysis_df), 1)) %>%
  arrange(desc(n_with_value))
print(lab_capture)
cat("\n")

# =============================================================================
# 11. QUICK VISUAL — vitals trajectory around index
# =============================================================================
cat("--- 11. Generating trajectory plots ---\n")

plot_dir <- file.path(out_dir, "qc_plots")
if (!dir.exists(plot_dir)) dir.create(plot_dir, recursive = TRUE)

p_sbp <- vitals_long %>%
  filter(vital == "sbp", days_from_index >= -90, days_from_index <= 365) %>%
  ggplot(aes(x = days_from_index, y = value)) +
  geom_point(alpha = 0.15, size = 0.6) +
  geom_smooth(method = "loess", se = TRUE, color = "steelblue", span = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "SBP trajectory around GLP-1 start (day 0)",
       x = "Days from GLP-1 start",
       y = "SBP (mmHg)") +
  theme_minimal(base_size = 11)

p_dbp <- vitals_long %>%
  filter(vital == "dbp", days_from_index >= -90, days_from_index <= 365) %>%
  ggplot(aes(x = days_from_index, y = value)) +
  geom_point(alpha = 0.15, size = 0.6) +
  geom_smooth(method = "loess", se = TRUE, color = "darkorange", span = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "DBP trajectory around GLP-1 start (day 0)",
       x = "Days from GLP-1 start",
       y = "DBP (mmHg)") +
  theme_minimal(base_size = 11)

p_wt <- vitals_long %>%
  filter(vital == "weight_kg", days_from_index >= -90, days_from_index <= 365) %>%
  ggplot(aes(x = days_from_index, y = value)) +
  geom_point(alpha = 0.15, size = 0.6) +
  geom_smooth(method = "loess", se = TRUE, color = "forestgreen", span = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Weight trajectory around GLP-1 start (day 0)",
       x = "Days from GLP-1 start",
       y = "Weight (kg)") +
  theme_minimal(base_size = 11)

# Distribution of days from delivery to GLP-1 start
p_timing <- analysis_df %>%
  filter(!is.na(days_pp_to_glp1)) %>%
  ggplot(aes(x = days_pp_to_glp1)) +
  geom_histogram(binwidth = 14, fill = "steelblue", color = "white") +
  geom_vline(xintercept = c(42, 90, 180),
             linetype = "dashed", color = "darkred") +
  annotate("text", x = 42,  y = Inf, label = "6 wk",  vjust = 1.5, hjust = -0.1, size = 3) +
  annotate("text", x = 90,  y = Inf, label = "3 mo",  vjust = 1.5, hjust = -0.1, size = 3) +
  annotate("text", x = 180, y = Inf, label = "6 mo",  vjust = 1.5, hjust = -0.1, size = 3) +
  labs(title = "Days from delivery to first postpartum GLP-1 order",
       x = "Days postpartum",
       y = "Patient count") +
  theme_minimal(base_size = 11)

ggsave(file.path(plot_dir, "qc_sbp_trajectory.png"),    p_sbp,    width = 7, height = 4.5, dpi = 300)
ggsave(file.path(plot_dir, "qc_dbp_trajectory.png"),    p_dbp,    width = 7, height = 4.5, dpi = 300)
ggsave(file.path(plot_dir, "qc_weight_trajectory.png"), p_wt,     width = 7, height = 4.5, dpi = 300)
ggsave(file.path(plot_dir, "qc_timing_histogram.png"),  p_timing, width = 7, height = 4.5, dpi = 300)

cat("Plots saved to:", plot_dir, "\n\n")

# =============================================================================
# 12. SUMMARY VERDICT
# =============================================================================
cat("================================================================\n")
cat(" QC COMPLETE — review the report above before modeling.\n")
cat(" Key things to confirm:\n")
cat("   1. Is single-arm (exposed-only) design expected?\n")
cat("   2. Are baseline/m6/m12 paired N's adequate for your primary endpoint?\n")
cat("   3. Do paired Wilcoxon directions match clinical expectation?\n")
cat("      (Expect SBP/DBP/weight to all decrease post-GLP-1)\n")
cat("   4. Any implausible vitals values to investigate?\n")
cat("================================================================\n")