# =============================================================================
# Audit: Why does the >6mo GLP-1 group show such small TBWL%?
# -----------------------------------------------------------------------------
# Hypotheses to test:
#   H1 (window artifact): >6mo starters have very little time on drug before the
#       12mo postpartum window closes — so they haven't lost weight yet
#   H2 (selection bias): the patients with 12mo follow-up may be non-responders
#       (they kept coming back because the drug wasn't working)
#   H3 (true biology): they have less metabolic disease so less to lose
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

if (!exists("analysis_df")) {
  proj_root <- "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
  analysis_df <- readRDS(file.path(proj_root, "data_processed", "analysis_df.rds"))
  vitals_long <- readRDS(file.path(proj_root, "data_processed", "vitals_long.rds"))
}

cat("================================================================\n")
cat(" AUDIT: >6mo GLP-1 stratum — why is TBWL% so small?\n")
cat("================================================================\n\n")

# ----------------------------------------------------------------------------
# H1 TEST: How much time on drug do these patients have at the 12mo pp window?
# ----------------------------------------------------------------------------
cat("--- H1: TIME ON DRUG AT EACH FOLLOW-UP WINDOW ---\n\n")

late_starters <- analysis_df %>%
  filter(glp1_timing_cat == "> 6mo")

cat("Late starters (> 6mo): n =", nrow(late_starters), "\n")
cat("Days from delivery to GLP-1 start:\n")
print(summary(late_starters$days_pp_to_glp1))
cat("\n")

# For each follow-up window, compute days-on-drug
# 12mo pp window = 365d after delivery
# Days on drug at that point = 365 - days_pp_to_glp1
cat("Days on GLP-1 at each postpartum measurement window:\n")
cat("(approximate, assuming follow-up exactly at the window center)\n\n")

window_summary <- late_starters %>%
  mutate(
    days_on_drug_at_3mo  = 90  - days_pp_to_glp1,
    days_on_drug_at_6mo  = 180 - days_pp_to_glp1,
    days_on_drug_at_12mo = 365 - days_pp_to_glp1
  ) %>%
  summarise(
    median_3mo  = median(days_on_drug_at_3mo,  na.rm = TRUE),
    median_6mo  = median(days_on_drug_at_6mo,  na.rm = TRUE),
    median_12mo = median(days_on_drug_at_12mo, na.rm = TRUE),
    q25_12mo    = quantile(days_on_drug_at_12mo, 0.25, na.rm = TRUE),
    q75_12mo    = quantile(days_on_drug_at_12mo, 0.75, na.rm = TRUE),
    pct_neg_at_3mo  = mean(days_on_drug_at_3mo  < 0, na.rm = TRUE) * 100,
    pct_neg_at_6mo  = mean(days_on_drug_at_6mo  < 0, na.rm = TRUE) * 100,
    n_neg_at_3mo    = sum(days_on_drug_at_3mo   < 0, na.rm = TRUE),
    n_neg_at_6mo    = sum(days_on_drug_at_6mo   < 0, na.rm = TRUE)
  )
print(window_summary)
cat("\n")

cat("Bottom line for H1:\n")
cat("  At the 12mo PP window, median time on drug =", round(window_summary$median_12mo), "days\n")
cat("  IQR =", round(window_summary$q25_12mo), "to", round(window_summary$q75_12mo), "days\n")
cat("  (For comparison: STEP trial showed 17% weight loss at 68 weeks ~ 476 days)\n\n")

# ----------------------------------------------------------------------------
# H1 TEST (additional): TBWL% PER DAY ON DRUG (the fair comparison)
# ----------------------------------------------------------------------------
cat("--- H1 (fair comparison): Time-adjusted TBWL% ---\n\n")
cat("If we measure TBWL% per month ON drug (not per month postpartum), do\n")
cat("strata still differ? This isolates drug effect from window artifact.\n\n")

# Compute TBWL% per month on drug for each patient at 12mo pp
adj_df <- analysis_df %>%
  filter(!is.na(weight_kg_baseline_combined),
         !is.na(weight_kg_m12_pp),
         !is.na(days_pp_to_glp1)) %>%
  mutate(
    tbwl_12m_pp = (weight_kg_baseline_combined - weight_kg_m12_pp) /
                  weight_kg_baseline_combined * 100,
    days_on_drug_at_12m = 365 - days_pp_to_glp1,
    months_on_drug = days_on_drug_at_12m / 30,
    tbwl_per_month_on_drug = tbwl_12m_pp / months_on_drug
  ) %>%
  filter(months_on_drug > 0)   # exclude patients who hadn't yet started

cat("TBWL% per month ON DRUG, by timing stratum (12mo pp window):\n")
print(
  adj_df %>%
    group_by(glp1_timing_cat) %>%
    summarise(
      n                  = n(),
      median_months_drug = round(median(months_on_drug), 1),
      median_tbwl_12mo   = round(median(tbwl_12m_pp), 2),
      median_tbwl_per_mo = round(median(tbwl_per_month_on_drug), 2),
      q25_tbwl_per_mo    = round(quantile(tbwl_per_month_on_drug, 0.25), 2),
      q75_tbwl_per_mo    = round(quantile(tbwl_per_month_on_drug, 0.75), 2),
      .groups = "drop"
    )
)
cat("\n")
cat("If TBWL%/month is SIMILAR across strata, H1 (window artifact) is supported.\n")
cat("If still much smaller in >6mo, H2 or H3 also contribute.\n\n")

# ----------------------------------------------------------------------------
# H2 TEST: Are 12mo follow-up >6mo patients sicker / less responsive?
# ----------------------------------------------------------------------------
cat("--- H2: Selection bias check on patients with 12mo follow-up ---\n\n")
cat("Compare patients WITH vs WITHOUT a 12mo weight in the >6mo group:\n")

selection_check <- late_starters %>%
  mutate(has_12mo_weight = !is.na(weight_kg_m12_pp)) %>%
  group_by(has_12mo_weight) %>%
  summarise(
    n = n(),
    median_baseline_bmi = round(median(bmi_baseline_combined, na.rm = TRUE), 1),
    median_baseline_wt  = round(median(weight_kg_baseline_combined, na.rm = TRUE), 1),
    pct_t2dm  = round(mean(ckm_t2dm, na.rm = TRUE) * 100, 1),
    pct_htn   = round(mean(ckm_htn, na.rm = TRUE) * 100, 1),
    pct_obesity = round(mean(ckm_obesity, na.rm = TRUE) * 100, 1),
    median_days_on_drug_at_12mo = round(median(365 - days_pp_to_glp1, na.rm = TRUE)),
    .groups = "drop"
  )
print(selection_check)
cat("\n")
cat("If the two groups look similar, H2 is not strongly supported.\n\n")

# ----------------------------------------------------------------------------
# H3 TEST: Less metabolic disease = smaller absolute losses?
# ----------------------------------------------------------------------------
cat("--- H3: Comparing metabolic burden across strata ---\n\n")
cat("Already known from Table 1, but for reference:\n")
print(
  analysis_df %>%
    group_by(glp1_timing_cat) %>%
    summarise(
      n = n(),
      pct_t2dm  = round(mean(ckm_t2dm, na.rm = TRUE) * 100, 1),
      pct_htn   = round(mean(ckm_htn, na.rm = TRUE) * 100, 1),
      pct_obesity = round(mean(ckm_obesity, na.rm = TRUE) * 100, 1),
      median_bmi  = round(median(bmi_baseline_combined, na.rm = TRUE), 1),
      .groups = "drop"
    )
)
cat("\n")

# ----------------------------------------------------------------------------
# VISUAL: TBWL% as a function of days on drug (not days postpartum)
# ----------------------------------------------------------------------------
cat("--- Generating visualization: TBWL% vs days on drug ---\n\n")

plot_dir <- file.path(
  ifelse(Sys.info()[["sysname"]] == "Darwin",
         "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1",
         "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1"),
  "data_processed", "qc_plots_v2"
)

tbwl_by_drug_time <- vitals_long %>%
  filter(vital == "weight_kg", !is.na(glp1_timing_cat),
         days_from_glp1 >= 0, days_from_glp1 <= 730) %>%
  inner_join(
    analysis_df %>% select(CURR_CLINIC, weight_kg_baseline_combined),
    by = "CURR_CLINIC"
  ) %>%
  filter(!is.na(weight_kg_baseline_combined)) %>%
  mutate(tbwl_pct = (weight_kg_baseline_combined - value) /
                    weight_kg_baseline_combined * 100)

p_tbwl_drug_time <- tbwl_by_drug_time %>%
  ggplot(aes(x = days_from_glp1, y = tbwl_pct,
             color = glp1_timing_cat, fill = glp1_timing_cat)) +
  geom_point(alpha = 0.1, size = 0.5) +
  geom_smooth(method = "loess", se = TRUE, span = 0.5, alpha = 0.15) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.3) +
  geom_hline(yintercept = c(5, 10, 15), linetype = "dotted", color = "darkgreen", alpha = 0.6) +
  labs(title = "TBWL% by DAYS ON DRUG (vs days postpartum)",
       subtitle = "If all strata follow similar trajectories, the >6mo \"no effect\" is a window artifact",
       x = "Days since GLP-1 start", y = "Total body weight loss (%)",
       color = "GLP-1 timing", fill = "GLP-1 timing") +
  theme_minimal(base_size = 11)

ggsave(file.path(plot_dir, "v3_tbwl_by_days_on_drug.png"), p_tbwl_drug_time,
       width = 8, height = 5, dpi = 300, bg = "white")

cat("Plot saved:", file.path(plot_dir, "v3_tbwl_by_days_on_drug.png"), "\n\n")

# ----------------------------------------------------------------------------
# VERDICT GUIDE
# ----------------------------------------------------------------------------
cat("================================================================\n")
cat(" VERDICT GUIDE\n")
cat("================================================================\n\n")
cat("Look at the H1 results:\n")
cat("  - If most >6mo patients had <90 days on drug at the 12mo pp window,\n")
cat("    AND TBWL%/month is similar across strata,\n")
cat("    THEN the 'no effect' in >6mo is a WINDOW ARTIFACT, not biology.\n\n")
cat("Look at the new plot v3_tbwl_by_days_on_drug.png:\n")
cat("  - If all 4 stratum curves overlap when plotted against days-on-drug,\n")
cat("    that's strong evidence the drug works equally — we just measured\n")
cat("    the >6mo group too early.\n\n")
cat("If H1 is the answer, this is actually a STRONG paper finding:\n")
cat("  'Postpartum-window-restricted analyses systematically underestimate\n")
cat("  GLP-1 effects in late starters.'\n")