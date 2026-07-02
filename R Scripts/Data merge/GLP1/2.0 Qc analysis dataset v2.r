# =============================================================================
# postpartum-glp1: QC v2 — Delivery-Anchored Dataset
# -----------------------------------------------------------------------------
# Source after build_analysis_dataset_v2.R (or load .rds files from disk).
#
# Sections:
#   1.  Structure / dimensions
#   2.  GLP-1 timing strata (per Dr. Demi)
#   3.  Demographics + race consolidation check
#   4.  Comorbidity prevalence
#   5.  Vitals capture (primary vs sensitivity baseline)
#   6.  BP staging subgroup sizes
#   7.  Pre/post direction — overall + by GLP-1 timing stratum
#   8.  Pre/post direction — BP subgroup (Stage 1+ HTN only)
#   9.  Lab signal preview: HbA1c, total chol, LDL, triglycerides
#   10. Event rates by timing stratum
#   11. Trajectory plots (delivery-anchored)
#   12. Verdict
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(stringr)
  library(ggplot2)
})

sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1"
}
out_dir <- file.path(proj_root, "data_processed")

if (!exists("analysis_df")) analysis_df <- readRDS(file.path(out_dir, "analysis_df.rds"))
if (!exists("vitals_long")) vitals_long <- readRDS(file.path(out_dir, "vitals_long.rds"))
if (!exists("labs_long"))   labs_long   <- readRDS(file.path(out_dir, "labs_long.rds"))
if (!exists("events_df"))   events_df   <- readRDS(file.path(out_dir, "events_df.rds"))

cat("================================================================\n")
cat(" QC v2 REPORT: postpartum-glp1 (delivery-anchored)\n")
cat("================================================================\n\n")

# =============================================================================
# 1. STRUCTURE
# =============================================================================
cat("--- 1. Structure ---\n")
cat("analysis_df:", nrow(analysis_df), "rows ×", ncol(analysis_df), "cols\n")
cat("vitals_long:", nrow(vitals_long), "rows\n")
cat("labs_long:  ", nrow(labs_long),   "rows\n")
cat("events_df:  ", nrow(events_df),   "rows\n\n")

# =============================================================================
# 2. GLP-1 TIMING STRATA
# =============================================================================
cat("--- 2. GLP-1 Timing Strata (per Dr. Demi) ---\n")
print(analysis_df %>%
        count(glp1_timing_cat) %>%
        mutate(pct = round(100 * n / sum(n), 1)))
cat("\n")

cat("Drug distribution within each timing stratum:\n")
print(analysis_df %>%
        count(glp1_timing_cat, glp1_first_drug) %>%
        pivot_wider(names_from = glp1_first_drug, values_from = n, values_fill = 0))
cat("\n")

# =============================================================================
# 3. DEMOGRAPHICS + RACE CHECK
# =============================================================================
cat("--- 3. Demographics ---\n")
cat("Age at delivery:\n");   print(summary(analysis_df$current_age))
cat("\nRace (consolidated):\n")
print(analysis_df %>% count(race_consolidated, sort = TRUE))
cat("\nEthnicity (consolidated):\n")
print(analysis_df %>% count(ethnicity_consolidated, sort = TRUE))
cat("\n")

# =============================================================================
# 4. COMORBIDITY PREVALENCE
# =============================================================================
cat("--- 4a. CKM Condition Prevalence (lifetime, pre-delivery) ---\n")
ckm_cols <- grep("^ckm_", names(analysis_df), value = TRUE)
ckm_cols <- ckm_cols[!str_detect(ckm_cols, "count|any")]  # exclude composites
print(
  analysis_df %>%
    summarise(across(all_of(ckm_cols), ~ sum(., na.rm = TRUE))) %>%
    pivot_longer(everything(), names_to = "condition", values_to = "n") %>%
    mutate(pct = round(100 * n / nrow(analysis_df), 1)) %>%
    arrange(desc(n)),
  n = Inf
)
cat("\n--- 4b. Pregnancy Complication Prevalence (index pregnancy) ---\n")
preg_cols <- grep("^preg_", names(analysis_df), value = TRUE)
preg_cols <- preg_cols[!str_detect(preg_cols, "count")]
print(
  analysis_df %>%
    summarise(across(all_of(preg_cols), ~ sum(., na.rm = TRUE))) %>%
    pivot_longer(everything(), names_to = "complication", values_to = "n") %>%
    mutate(pct = round(100 * n / nrow(analysis_df), 1)) %>%
    arrange(desc(n)),
  n = Inf
)
cat("\n")

# =============================================================================
# 5. VITALS CAPTURE
# =============================================================================
cat("--- 5. Vitals Capture (primary vs sensitivity baseline) ---\n")

capture_tbl <- tibble(
  variable = c("SBP", "DBP", "Weight (kg)"),
  baseline_primary = c(sum(!is.na(analysis_df$sbp_baseline_primary)),
                       sum(!is.na(analysis_df$dbp_baseline_primary)),
                       sum(!is.na(analysis_df$weight_kg_baseline_primary))),
  baseline_sens    = c(sum(!is.na(analysis_df$sbp_baseline_sens)),
                       sum(!is.na(analysis_df$dbp_baseline_sens)),
                       sum(!is.na(analysis_df$weight_kg_baseline_sens))),
  m3_pp            = c(sum(!is.na(analysis_df$sbp_m3_pp)),
                       sum(!is.na(analysis_df$dbp_m3_pp)),
                       sum(!is.na(analysis_df$weight_kg_m3_pp))),
  m6_pp            = c(sum(!is.na(analysis_df$sbp_m6_pp)),
                       sum(!is.na(analysis_df$dbp_m6_pp)),
                       sum(!is.na(analysis_df$weight_kg_m6_pp))),
  m12_pp           = c(sum(!is.na(analysis_df$sbp_m12_pp)),
                       sum(!is.na(analysis_df$dbp_m12_pp)),
                       sum(!is.na(analysis_df$weight_kg_m12_pp))),
  N_total          = nrow(analysis_df)
)
print(capture_tbl)
cat("\n")

cat("Paired N (baseline_primary + follow-up):\n")
paired_tbl <- tibble(
  pair = c("SBP base + m6pp", "SBP base + m12pp",
           "DBP base + m6pp", "DBP base + m12pp",
           "Weight base + m6pp", "Weight base + m12pp"),
  n_paired = c(
    sum(!is.na(analysis_df$sbp_baseline_primary) & !is.na(analysis_df$sbp_m6_pp)),
    sum(!is.na(analysis_df$sbp_baseline_primary) & !is.na(analysis_df$sbp_m12_pp)),
    sum(!is.na(analysis_df$dbp_baseline_primary) & !is.na(analysis_df$dbp_m6_pp)),
    sum(!is.na(analysis_df$dbp_baseline_primary) & !is.na(analysis_df$dbp_m12_pp)),
    sum(!is.na(analysis_df$weight_kg_baseline_primary) & !is.na(analysis_df$weight_kg_m6_pp)),
    sum(!is.na(analysis_df$weight_kg_baseline_primary) & !is.na(analysis_df$weight_kg_m12_pp))
  )
)
print(paired_tbl)
cat("\n")

# =============================================================================
# 6. BP STAGING SUBGROUP SIZES
# =============================================================================
cat("--- 6. BP Staging at Baseline (per ACC/AHA 2017) ---\n")
print(analysis_df %>%
        filter(!is.na(bp_stage)) %>%
        count(bp_stage) %>%
        mutate(pct = round(100 * n / sum(n), 1)))
cat("\n")

cat("Stage 1+ HTN by GLP-1 timing stratum:\n")
print(analysis_df %>%
        filter(!is.na(bp_stage)) %>%
        count(glp1_timing_cat, elevated_bp_any) %>%
        pivot_wider(names_from = elevated_bp_any, values_from = n,
                    names_prefix = "elevated_", values_fill = 0))
cat("\n")

# =============================================================================
# 7. PRE/POST DIRECTION — OVERALL + BY TIMING STRATUM
# =============================================================================
cat("--- 7. Pre/Post Direction Check (PRIMARY baseline) ---\n\n")

quiet_wilcox <- function(x, y, label) {
  ok <- !is.na(x) & !is.na(y)
  if (sum(ok) < 10) {
    cat(sprintf("  %-40s n=%-4d  (too few pairs)\n", label, sum(ok)))
    return(invisible(NULL))
  }
  w <- suppressWarnings(wilcox.test(x[ok], y[ok], paired = TRUE))
  cat(sprintf("  %-40s n=%-4d  median Δ=%+.2f   p=%.4g\n",
              label, sum(ok), median(x[ok] - y[ok]), w$p.value))
}

cat("Overall (all GLP-1 patients):\n")
with(analysis_df, {
  quiet_wilcox(sbp_baseline_primary, sbp_m6_pp,        "SBP base → 6mo postpartum")
  quiet_wilcox(sbp_baseline_primary, sbp_m12_pp,       "SBP base → 12mo postpartum")
  quiet_wilcox(dbp_baseline_primary, dbp_m6_pp,        "DBP base → 6mo postpartum")
  quiet_wilcox(dbp_baseline_primary, dbp_m12_pp,       "DBP base → 12mo postpartum")
  quiet_wilcox(weight_kg_baseline_primary, weight_kg_m6_pp,  "Weight base → 6mo postpartum")
  quiet_wilcox(weight_kg_baseline_primary, weight_kg_m12_pp, "Weight base → 12mo postpartum")
})
cat("\n")

cat("Weight change by GLP-1 timing stratum (TBWL% at 6mo pp, primary baseline):\n")
weight_by_timing <- analysis_df %>%
  filter(!is.na(glp1_timing_cat),
         !is.na(weight_kg_baseline_primary), !is.na(weight_kg_m6_pp)) %>%
  group_by(glp1_timing_cat) %>%
  summarise(
    n               = n(),
    median_kg_delta = median(weight_kg_baseline_primary - weight_kg_m6_pp, na.rm = TRUE),
    median_tbwl_pct = round(median(pct_wt_loss_pp6m, na.rm = TRUE), 2),
    q25_tbwl_pct    = round(quantile(pct_wt_loss_pp6m, 0.25, na.rm = TRUE), 2),
    q75_tbwl_pct    = round(quantile(pct_wt_loss_pp6m, 0.75, na.rm = TRUE), 2),
    pct_ge_5tbwl    = round(mean(pct_wt_loss_pp6m >= 5,  na.rm = TRUE) * 100, 1),
    pct_ge_10tbwl   = round(mean(pct_wt_loss_pp6m >= 10, na.rm = TRUE) * 100, 1),
    .groups = "drop"
  )
print(weight_by_timing)
cat("\n")

# Same table at 12mo
cat("Weight change by GLP-1 timing stratum (TBWL% at 12mo pp):\n")
weight_by_timing_12m <- analysis_df %>%
  filter(!is.na(glp1_timing_cat),
         !is.na(weight_kg_baseline_primary), !is.na(weight_kg_m12_pp)) %>%
  group_by(glp1_timing_cat) %>%
  summarise(
    n               = n(),
    median_tbwl_pct = round(median(pct_wt_loss_pp12m, na.rm = TRUE), 2),
    q25_tbwl_pct    = round(quantile(pct_wt_loss_pp12m, 0.25, na.rm = TRUE), 2),
    q75_tbwl_pct    = round(quantile(pct_wt_loss_pp12m, 0.75, na.rm = TRUE), 2),
    pct_ge_5tbwl    = round(mean(pct_wt_loss_pp12m >= 5,  na.rm = TRUE) * 100, 1),
    pct_ge_10tbwl   = round(mean(pct_wt_loss_pp12m >= 10, na.rm = TRUE) * 100, 1),
    .groups = "drop"
  )
print(weight_by_timing_12m)
cat("\n")

# =============================================================================
# 8. BP SUBGROUP ANALYSIS (Stage 1+ HTN at baseline)
# =============================================================================
cat("--- 8. BP Subgroup Analysis (Stage 1+ HTN only, per Dr. Demi) ---\n")

bp_subgroup <- analysis_df %>% filter(elevated_bp_any == TRUE)
cat("Subgroup size:", nrow(bp_subgroup), "\n\n")

cat("SBP and DBP changes in elevated-BP subgroup:\n")
with(bp_subgroup, {
  quiet_wilcox(sbp_baseline_primary, sbp_m6_pp,  "SBP base → 6mo (Stage 1+)")
  quiet_wilcox(sbp_baseline_primary, sbp_m12_pp, "SBP base → 12mo (Stage 1+)")
  quiet_wilcox(dbp_baseline_primary, dbp_m6_pp,  "DBP base → 6mo (Stage 1+)")
  quiet_wilcox(dbp_baseline_primary, dbp_m12_pp, "DBP base → 12mo (Stage 1+)")
})
cat("\n")

# Stage 2 only (sensitivity)
bp_stage2 <- analysis_df %>% filter(stage2_htn == TRUE)
cat("Stage 2 only (n =", nrow(bp_stage2), "):\n")
with(bp_stage2, {
  quiet_wilcox(sbp_baseline_primary, sbp_m6_pp,  "SBP base → 6mo (Stage 2)")
  quiet_wilcox(dbp_baseline_primary, dbp_m6_pp,  "DBP base → 6mo (Stage 2)")
})
cat("\n")

# =============================================================================
# 9. LAB SIGNAL PREVIEW (per Dr. Demi's PS — A1C and cholesterol)
# =============================================================================
cat("--- 9. Lab Signal Preview (post-GLP-1 changes) ---\n\n")

lab_paired_wilcox <- function(label, baseline_col, post_col) {
  x <- analysis_df[[baseline_col]]
  y <- analysis_df[[post_col]]
  ok <- !is.na(x) & !is.na(y)
  if (sum(ok) < 10) {
    cat(sprintf("  %-40s n=%-4d  (too few pairs)\n", label, sum(ok)))
    return(invisible(NULL))
  }
  w <- suppressWarnings(wilcox.test(x[ok], y[ok], paired = TRUE))
  cat(sprintf("  %-40s n=%-4d  median Δ=%+.2f   p=%.4g\n",
              label, sum(ok), median(x[ok] - y[ok]), w$p.value))
}

cat("HbA1c:\n")
lab_paired_wilcox("HbA1c baseline → 6mo post-GLP-1",  "lab_hba1c_baseline", "lab_hba1c_post_6m")
lab_paired_wilcox("HbA1c baseline → 12mo post-GLP-1", "lab_hba1c_baseline", "lab_hba1c_post_12m")
cat("\nIn T2DM subgroup only (n =", sum(analysis_df$ckm_t2dm), "):\n")
t2dm_df <- analysis_df %>% filter(ckm_t2dm == TRUE)
with(t2dm_df, {
  ok <- !is.na(lab_hba1c_baseline) & !is.na(lab_hba1c_post_6m)
  if (sum(ok) >= 10) {
    w <- suppressWarnings(wilcox.test(lab_hba1c_baseline[ok], lab_hba1c_post_6m[ok], paired = TRUE))
    cat(sprintf("  HbA1c base → 6m (T2DM)              n=%-4d  median Δ=%+.2f   p=%.4g\n",
                sum(ok), median(lab_hba1c_baseline[ok] - lab_hba1c_post_6m[ok]), w$p.value))
  } else {
    cat(sprintf("  HbA1c base → 6m (T2DM)              n=%-4d  (too few pairs)\n", sum(ok)))
  }
})
cat("\nTotal Cholesterol:\n")
lab_paired_wilcox("TC baseline → 6mo post-GLP-1",  "lab_tc_baseline", "lab_tc_post_6m")
lab_paired_wilcox("TC baseline → 12mo post-GLP-1", "lab_tc_baseline", "lab_tc_post_12m")
cat("\nLDL Cholesterol:\n")
lab_paired_wilcox("LDL baseline → 6mo post-GLP-1", "lab_ldl_baseline", "lab_ldl_post_6m")
cat("\nHDL Cholesterol:\n")
lab_paired_wilcox("HDL baseline → 6mo post-GLP-1", "lab_hdl_baseline", "lab_hdl_post_6m")
cat("\nTriglycerides:\n")
lab_paired_wilcox("Trig baseline → 6mo post-GLP-1", "lab_trig_baseline", "lab_trig_post_6m")
cat("\n")

# =============================================================================
# 10. EVENT RATES BY TIMING STRATUM
# =============================================================================
cat("--- 10. Event Rates by GLP-1 Timing Stratum ---\n")
event_by_timing <- analysis_df %>%
  filter(!is.na(glp1_timing_cat)) %>%
  group_by(glp1_timing_cat) %>%
  summarise(
    n           = n(),
    sbp_drop_n  = sum(sbp_event, na.rm = TRUE),
    sbp_drop_pct= round(mean(sbp_event, na.rm = TRUE) * 100, 1),
    dbp_drop_n  = sum(dbp_event, na.rm = TRUE),
    dbp_drop_pct= round(mean(dbp_event, na.rm = TRUE) * 100, 1),
    wt_loss_n   = sum(wt_event, na.rm = TRUE),
    wt_loss_pct = round(mean(wt_event, na.rm = TRUE) * 100, 1),
    .groups = "drop"
  )
print(event_by_timing)
cat("\n")

# =============================================================================
# 11. TRAJECTORY PLOTS (DELIVERY-ANCHORED, STRATIFIED BY GLP-1 TIMING)
# =============================================================================
cat("--- 11. Generating trajectory plots ---\n")

plot_dir <- file.path(out_dir, "qc_plots_v2")
if (!dir.exists(plot_dir)) dir.create(plot_dir, recursive = TRUE)

# --- Build TBWL% trajectory dataset ---
# For each patient: compute % change from their PRIMARY baseline at each measurement
weight_traj <- vitals_long %>%
  filter(vital == "weight_kg", !is.na(glp1_timing_cat)) %>%
  inner_join(
    analysis_df %>% select(CURR_CLINIC, weight_kg_baseline_primary),
    by = "CURR_CLINIC"
  ) %>%
  filter(!is.na(weight_kg_baseline_primary)) %>%
  mutate(tbwl_pct = (weight_kg_baseline_primary - value) / weight_kg_baseline_primary * 100)

# TBWL% trajectory by GLP-1 timing stratum
p_tbwl_by_timing <- weight_traj %>%
  ggplot(aes(x = days_from_delivery, y = tbwl_pct,
             color = glp1_timing_cat, fill = glp1_timing_cat)) +
  geom_point(alpha = 0.12, size = 0.5) +
  geom_smooth(method = "loess", se = TRUE, span = 0.5, alpha = 0.15) +
  geom_vline(xintercept = 0,  linetype = "dashed", color = "gray30") +
  geom_vline(xintercept = 42, linetype = "dotted", color = "gray60") +
  geom_hline(yintercept = 0,  linetype = "solid",  color = "black", linewidth = 0.3) +
  geom_hline(yintercept = c(5, 10, 15), linetype = "dotted", color = "darkgreen", alpha = 0.6) +
  annotate("text", x = 365, y = 5,  label = "5% TBWL",  hjust = 1, vjust = -0.3, size = 3, color = "darkgreen") +
  annotate("text", x = 365, y = 10, label = "10% TBWL", hjust = 1, vjust = -0.3, size = 3, color = "darkgreen") +
  annotate("text", x = 365, y = 15, label = "15% TBWL", hjust = 1, vjust = -0.3, size = 3, color = "darkgreen") +
  labs(title = "Weight loss (TBWL%) by GLP-1 timing stratum",
       subtitle = "Day 0 = delivery; baseline = each patient's primary postpartum weight (≥42d pp, pre-GLP-1)",
       x = "Days from delivery", y = "Total body weight loss (%)",
       color = "GLP-1 timing", fill = "GLP-1 timing") +
  scale_y_continuous(breaks = seq(-10, 30, 5)) +
  theme_minimal(base_size = 11)

# Keep the absolute weight trajectory as a supplementary plot
p_wt_by_timing <- vitals_long %>%
  filter(vital == "weight_kg", !is.na(glp1_timing_cat)) %>%
  ggplot(aes(x = days_from_delivery, y = value,
             color = glp1_timing_cat, fill = glp1_timing_cat)) +
  geom_point(alpha = 0.1, size = 0.5) +
  geom_smooth(method = "loess", se = TRUE, span = 0.5, alpha = 0.15) +
  geom_vline(xintercept = 0,  linetype = "dashed", color = "gray30") +
  geom_vline(xintercept = 42, linetype = "dotted", color = "gray60") +
  labs(title = "Absolute weight trajectory by GLP-1 timing stratum",
       subtitle = "Supplementary view — primary metric is TBWL%",
       x = "Days from delivery", y = "Weight (kg)",
       color = "GLP-1 timing", fill = "GLP-1 timing") +
  theme_minimal(base_size = 11)

# --- SBP % change trajectory (analogous to TBWL%) ---
sbp_traj <- vitals_long %>%
  filter(vital == "sbp", !is.na(glp1_timing_cat)) %>%
  inner_join(
    analysis_df %>% select(CURR_CLINIC, sbp_baseline_primary, elevated_bp_any),
    by = "CURR_CLINIC"
  ) %>%
  filter(!is.na(sbp_baseline_primary)) %>%
  mutate(sbp_pct_change = (value - sbp_baseline_primary) / sbp_baseline_primary * 100)

# SBP % change by GLP-1 timing — full cohort
p_sbp_pct_by_timing <- sbp_traj %>%
  ggplot(aes(x = days_from_delivery, y = sbp_pct_change,
             color = glp1_timing_cat, fill = glp1_timing_cat)) +
  geom_point(alpha = 0.1, size = 0.5) +
  geom_smooth(method = "loess", se = TRUE, span = 0.5, alpha = 0.15) +
  geom_vline(xintercept = 0,  linetype = "dashed", color = "gray30") +
  geom_vline(xintercept = 42, linetype = "dotted", color = "gray60") +
  geom_hline(yintercept = 0,  linetype = "solid",  color = "black", linewidth = 0.3) +
  geom_hline(yintercept = c(-5, -10), linetype = "dotted", color = "firebrick", alpha = 0.6) +
  annotate("text", x = 365, y = -5,  label = "5% drop",  hjust = 1, vjust = -0.3, size = 3, color = "firebrick") +
  annotate("text", x = 365, y = -10, label = "10% drop", hjust = 1, vjust = -0.3, size = 3, color = "firebrick") +
  labs(title = "SBP % change by GLP-1 timing stratum (full cohort)",
       subtitle = "Day 0 = delivery; baseline = each patient's primary postpartum SBP",
       x = "Days from delivery", y = "SBP change from baseline (%)",
       color = "GLP-1 timing", fill = "GLP-1 timing") +
  theme_minimal(base_size = 11)

# SBP % change in Stage 1+ HTN subgroup only (Dr. Demi's question)
p_sbp_pct_subgroup <- sbp_traj %>%
  filter(elevated_bp_any == TRUE) %>%
  ggplot(aes(x = days_from_delivery, y = sbp_pct_change,
             color = glp1_timing_cat, fill = glp1_timing_cat)) +
  geom_point(alpha = 0.15, size = 0.6) +
  geom_smooth(method = "loess", se = TRUE, span = 0.5, alpha = 0.15) +
  geom_vline(xintercept = 0,  linetype = "dashed", color = "gray30") +
  geom_hline(yintercept = 0,  linetype = "solid",  color = "black", linewidth = 0.3) +
  geom_hline(yintercept = c(-5, -10), linetype = "dotted", color = "firebrick", alpha = 0.6) +
  annotate("text", x = 365, y = -5,  label = "5% drop",  hjust = 1, vjust = -0.3, size = 3, color = "firebrick") +
  annotate("text", x = 365, y = -10, label = "10% drop", hjust = 1, vjust = -0.3, size = 3, color = "firebrick") +
  labs(title = "SBP % change — Stage 1+ HTN subgroup",
       subtitle = paste0("N = ", sum(analysis_df$elevated_bp_any, na.rm = TRUE),
                         " patients with baseline BP ≥130/80"),
       x = "Days from delivery", y = "SBP change from baseline (%)",
       color = "GLP-1 timing", fill = "GLP-1 timing") +
  theme_minimal(base_size = 11)

# Keep existing absolute-SBP plots for reference
p_sbp_by_timing <- vitals_long %>%
  filter(vital == "sbp", !is.na(glp1_timing_cat)) %>%
  ggplot(aes(x = days_from_delivery, y = value,
             color = glp1_timing_cat, fill = glp1_timing_cat)) +
  geom_point(alpha = 0.1, size = 0.5) +
  geom_smooth(method = "loess", se = TRUE, span = 0.5, alpha = 0.15) +
  geom_vline(xintercept = 0,  linetype = "dashed", color = "gray30") +
  geom_hline(yintercept = c(130, 140), linetype = "dotted", color = "red") +
  labs(title = "SBP (absolute) by GLP-1 timing stratum",
       subtitle = "Supplementary view — primary metric is SBP % change",
       x = "Days from delivery", y = "SBP (mmHg)",
       color = "GLP-1 timing", fill = "GLP-1 timing") +
  theme_minimal(base_size = 11)

# BP subgroup only — does SBP fall in those who actually have HTN?
elevated_ids <- analysis_df %>% filter(elevated_bp_any == TRUE) %>% pull(CURR_CLINIC)
p_sbp_subgroup <- vitals_long %>%
  filter(vital == "sbp", CURR_CLINIC %in% elevated_ids) %>%
  ggplot(aes(x = days_from_delivery, y = value)) +
  geom_point(alpha = 0.15, size = 0.6) +
  geom_smooth(method = "loess", se = TRUE, color = "firebrick", span = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
  geom_hline(yintercept = c(130, 140), linetype = "dotted", color = "darkred") +
  labs(title = "SBP (absolute) — Stage 1+ HTN subgroup only",
       subtitle = paste0("N = ", length(elevated_ids), " patients with baseline BP ≥130/80"),
       x = "Days from delivery", y = "SBP (mmHg)") +
  theme_minimal(base_size = 11)

# Lab signal: HbA1c
# Filter outliers: HbA1c outside 4-15% is almost always a unit error or lab artifact
hba1c_long <- labs_long %>%
  filter(lab_domain == "hba1c", !is.na(Resultn),
         Resultn >= 4, Resultn <= 15,
         days_from_glp1 >= -180, days_from_glp1 <= 365)

p_hba1c <- hba1c_long %>%
  ggplot(aes(x = days_from_glp1, y = Resultn)) +
  geom_point(alpha = 0.3, size = 0.7) +
  geom_smooth(method = "loess", se = TRUE, color = "purple", span = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
  geom_hline(yintercept = c(5.7, 6.5), linetype = "dotted", color = "darkorange") +
  annotate("text", x = -180, y = 5.7, label = "Prediabetes (5.7%)",
           hjust = 0, vjust = -0.3, size = 3, color = "darkorange") +
  annotate("text", x = -180, y = 6.5, label = "Diabetes (6.5%)",
           hjust = 0, vjust = -0.3, size = 3, color = "darkorange") +
  coord_cartesian(ylim = c(4.5, 11)) +
  scale_y_continuous(breaks = seq(4, 12, 1)) +
  labs(title = "HbA1c trajectory around GLP-1 start",
       subtitle = paste0("Day 0 = GLP-1 start; ",
                         nrow(hba1c_long), " measurements from ",
                         n_distinct(hba1c_long$CURR_CLINIC), " patients"),
       x = "Days from GLP-1 start", y = "HbA1c (%)") +
  theme_minimal(base_size = 11)

# Additional plot: HbA1c stratified by T2DM status (biologically the expected signal)
hba1c_by_dm <- labs_long %>%
  filter(lab_domain == "hba1c", !is.na(Resultn),
         Resultn >= 4, Resultn <= 15,
         days_from_glp1 >= -180, days_from_glp1 <= 365) %>%
  inner_join(analysis_df %>% select(CURR_CLINIC, ckm_t2dm, ckm_prediabetes),
             by = "CURR_CLINIC") %>%
  mutate(dm_status = case_when(
    ckm_t2dm        ~ "T2DM",
    ckm_prediabetes ~ "Prediabetes",
    TRUE            ~ "No DM/Pre-DM"
  ),
  dm_status = factor(dm_status, levels = c("No DM/Pre-DM", "Prediabetes", "T2DM")))

p_hba1c_by_dm <- hba1c_by_dm %>%
  ggplot(aes(x = days_from_glp1, y = Resultn,
             color = dm_status, fill = dm_status)) +
  geom_point(alpha = 0.2, size = 0.6) +
  geom_smooth(method = "loess", se = TRUE, span = 0.5, alpha = 0.15) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
  geom_hline(yintercept = c(5.7, 6.5), linetype = "dotted", color = "darkorange") +
  coord_cartesian(ylim = c(4.5, 11)) +
  scale_y_continuous(breaks = seq(4, 12, 1)) +
  labs(title = "HbA1c trajectory by diabetes status",
       subtitle = "Day 0 = GLP-1 start; expected signal: T2DM patients show greater HbA1c drop",
       x = "Days from GLP-1 start", y = "HbA1c (%)",
       color = "Diabetes status", fill = "Diabetes status") +
  theme_minimal(base_size = 11)

ggsave(file.path(plot_dir, "v2_tbwl_pct_by_timing.png"),  p_tbwl_by_timing,
       width = 8, height = 5, dpi = 300, bg = "white")

ggsave(file.path(plot_dir, "v2_weight_kg_by_timing.png"), p_wt_by_timing,
       width = 8, height = 5, dpi = 300, bg = "white")

ggsave(file.path(plot_dir, "v2_sbp_pct_by_timing.png"),   p_sbp_pct_by_timing,
       width = 8, height = 5, dpi = 300, bg = "white")

ggsave(file.path(plot_dir, "v2_sbp_pct_subgroup.png"),    p_sbp_pct_subgroup,
       width = 8, height = 5, dpi = 300, bg = "white")

ggsave(file.path(plot_dir, "v2_sbp_kg_by_timing.png"),    p_sbp_by_timing,
       width = 8, height = 5, dpi = 300, bg = "white")

ggsave(file.path(plot_dir, "v2_sbp_subgroup.png"),        p_sbp_subgroup,
       width = 8, height = 5, dpi = 300, bg = "white")

ggsave(file.path(plot_dir, "v2_hba1c_trajectory.png"),    p_hba1c,
       width = 8, height = 5, dpi = 300, bg = "white")

ggsave(file.path(plot_dir, "v2_hba1c_by_dm_status.png"),  p_hba1c_by_dm,
       width = 8, height = 5, dpi = 300, bg = "white")

cat("Plots saved to:", plot_dir, "\n\n")

# =============================================================================
# 12. VERDICT
# =============================================================================
cat("================================================================\n")
cat(" QC v2 COMPLETE\n")
cat(" Things to verify before modeling:\n")
cat("   1. Weight loss visible across all GLP-1 timing strata\n")
cat("   2. BP signal emerges in Stage 1+ HTN subgroup (vs nothing overall)\n")
cat("   3. HbA1c signal in T2DM subgroup (per Dr. Demi's PS)\n")
cat("   4. Adequate N at 12mo paired (delivery-anchored should help)\n")
cat("================================================================\n")