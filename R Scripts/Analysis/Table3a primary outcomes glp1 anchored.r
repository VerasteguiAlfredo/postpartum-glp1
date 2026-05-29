# =============================================================================
# postpartum-glp1: Table 3a — Primary Outcomes (GLP-1-anchored sensitivity)
# -----------------------------------------------------------------------------
# Purpose: Sensitivity analysis to Table 3. Same outcomes but measured at
#          3 / 6 / 12 months POST-GLP-1 START instead of post-delivery.
#          This removes the postpartum-window artifact that penalizes late
#          starters (who don't have enough time on drug within the 12mo PP
#          window in the delivery-anchored analysis).
#
# Outputs:
#   /Results/Analysis/Tables/MD Files/    table3a_*.md   (printed to console)
#   /Results/Analysis/Tables/HTML Files/  table3a_*.html (NEJM/JAMA minimalist)
#
# Source AFTER build_analysis_dataset_v3.R
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(stringr)
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

if (!exists("analysis_df")) {
  analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
}
if (!exists("vitals_long")) {
  vitals_long <- readRDS(file.path(data_dir, "vitals_long.rds"))
}

cat("Loaded analysis_df:", nrow(analysis_df), "rows x", ncol(analysis_df), "cols\n")
cat("Loaded vitals_long:", nrow(vitals_long), "rows\n\n")

# =============================================================================
# 1. HELPER FUNCTIONS (same as Table 3)
# =============================================================================
fmt_iqr <- function(x, digits = 1) {
  ok <- !is.na(x)
  if (sum(ok) == 0) return("--")
  q <- quantile(x[ok], probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
  sprintf(paste0("%+.", digits, "f (%+.", digits, "f, %+.", digits, "f)"),
          q[2], q[1], q[3])
}

fmt_pct <- function(n_event, n_total) {
  if (n_total == 0) return("--")
  sprintf("%d/%d (%.0f%%)", n_event, n_total, 100 * n_event / n_total)
}

fmt_p <- function(p) {
  if (is.na(p)) return("--")
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

paired_wilcox_p <- function(baseline, followup) {
  ok <- !is.na(baseline) & !is.na(followup)
  if (sum(ok) < 5) return(NA_real_)
  suppressWarnings(
    wilcox.test(baseline[ok], followup[ok], paired = TRUE)$p.value
  )
}

kruskal_p <- function(delta, group) {
  ok <- !is.na(delta) & !is.na(group)
  if (sum(ok) < 5 || length(unique(group[ok])) < 2) return(NA_real_)
  suppressWarnings(
    kruskal.test(delta[ok], group[ok])$p.value
  )
}

fisher_p <- function(event, group) {
  ok <- !is.na(event) & !is.na(group)
  if (sum(ok) < 5) return(NA_real_)
  tab <- table(event[ok], group[ok])
  if (nrow(tab) < 2 || ncol(tab) < 2) return(NA_real_)
  suppressWarnings(
    fisher.test(tab, simulate.p.value = TRUE, B = 10000)$p.value
  )
}

# =============================================================================
# 2. BUILD GLP-1-ANCHORED FOLLOW-UP MEASUREMENTS FROM vitals_long
# =============================================================================
# For each patient: find the closest measurement to each post-drug landmark.
# Windows: 3mo +/- 30d, 6mo +/- 45d, 12mo +/- 60d (same widths as Table 3).
# Target dates relative to glp1_index_date.

# Helper: closest value to target days_from_glp1 within window
closest_post_glp1 <- function(df, target_day, window_days) {
  df %>%
    filter(!is.na(days_from_glp1),
           days_from_glp1 >= target_day - window_days,
           days_from_glp1 <= target_day + window_days,
           days_from_glp1 >= 0) %>%   # post-drug only
    group_by(CURR_CLINIC) %>%
    arrange(abs(days_from_glp1 - target_day), .by_group = TRUE) %>%
    slice(1) %>%
    ungroup() %>%
    select(CURR_CLINIC, value)
}

# Build per-vital, per-window summary
build_followup_wide <- function(vital_name) {
  sub <- vitals_long %>% filter(vital == vital_name)
  m3  <- closest_post_glp1(sub, 90,  30) %>% rename("{vital_name}_m3_glp1"  := value)
  m6  <- closest_post_glp1(sub, 180, 45) %>% rename("{vital_name}_m6_glp1"  := value)
  m12 <- closest_post_glp1(sub, 365, 60) %>% rename("{vital_name}_m12_glp1" := value)
  m3 %>% full_join(m6, by = "CURR_CLINIC") %>% full_join(m12, by = "CURR_CLINIC")
}

sbp_fu_glp1    <- build_followup_wide("sbp")
dbp_fu_glp1    <- build_followup_wide("dbp")
weight_fu_glp1 <- build_followup_wide("weight_kg")

# =============================================================================
# 3. MERGE ONTO analysis_df AND COMPUTE DELTAS
# =============================================================================
# Same baseline (combined) as Table 3, but follow-up is GLP-1-anchored.

outcome_df <- analysis_df %>%
  left_join(sbp_fu_glp1,    by = "CURR_CLINIC") %>%
  left_join(dbp_fu_glp1,    by = "CURR_CLINIC") %>%
  left_join(weight_fu_glp1, by = "CURR_CLINIC") %>%
  mutate(
    # SBP changes (positive = drop = improvement)
    sbp_delta_3m  = sbp_baseline_combined - sbp_m3_glp1,
    sbp_delta_6m  = sbp_baseline_combined - sbp_m6_glp1,
    sbp_delta_12m = sbp_baseline_combined - sbp_m12_glp1,

    # DBP
    dbp_delta_3m  = dbp_baseline_combined - dbp_m3_glp1,
    dbp_delta_6m  = dbp_baseline_combined - dbp_m6_glp1,
    dbp_delta_12m = dbp_baseline_combined - dbp_m12_glp1,

    # TBWL%
    tbwl_3m  = (weight_kg_baseline_combined - weight_kg_m3_glp1)  / weight_kg_baseline_combined * 100,
    tbwl_6m  = (weight_kg_baseline_combined - weight_kg_m6_glp1)  / weight_kg_baseline_combined * 100,
    tbwl_12m = (weight_kg_baseline_combined - weight_kg_m12_glp1) / weight_kg_baseline_combined * 100,

    # Threshold events
    ge5_tbwl_3m   = if_else(!is.na(tbwl_3m),  tbwl_3m  >= 5,  NA),
    ge5_tbwl_6m   = if_else(!is.na(tbwl_6m),  tbwl_6m  >= 5,  NA),
    ge5_tbwl_12m  = if_else(!is.na(tbwl_12m), tbwl_12m >= 5,  NA),
    ge10_tbwl_3m  = if_else(!is.na(tbwl_3m),  tbwl_3m  >= 10, NA),
    ge10_tbwl_6m  = if_else(!is.na(tbwl_6m),  tbwl_6m  >= 10, NA),
    ge10_tbwl_12m = if_else(!is.na(tbwl_12m), tbwl_12m >= 10, NA),

    sbp_drop10_3m  = if_else(!is.na(sbp_delta_3m),  sbp_delta_3m  >= 10, NA),
    sbp_drop10_6m  = if_else(!is.na(sbp_delta_6m),  sbp_delta_6m  >= 10, NA),
    sbp_drop10_12m = if_else(!is.na(sbp_delta_12m), sbp_delta_12m >= 10, NA),

    dbp_drop5_3m   = if_else(!is.na(dbp_delta_3m),  dbp_delta_3m  >= 5, NA),
    dbp_drop5_6m   = if_else(!is.na(dbp_delta_6m),  dbp_delta_6m  >= 5, NA),
    dbp_drop5_12m  = if_else(!is.na(dbp_delta_12m), dbp_delta_12m >= 5, NA)
  )

# =============================================================================
# 4. ROW BUILDERS (same logic as Table 3)
# =============================================================================
build_continuous_row <- function(df, outcome_label, baseline_col, followup_col, delta_col,
                                  digits = 1) {
  groups <- levels(df$glp1_timing_cat)

  stratum_cells <- sapply(c("Overall", groups), function(g) {
    sub <- if (g == "Overall") df else df %>% filter(glp1_timing_cat == g)
    delta_vals <- sub[[delta_col]]
    n_paired   <- sum(!is.na(delta_vals))
    if (n_paired == 0) {
      "--"
    } else {
      iqr_str <- fmt_iqr(delta_vals, digits = digits)
      p_within <- paired_wilcox_p(sub[[baseline_col]], sub[[followup_col]])
      sprintf("%s [n=%d, p=%s]", iqr_str, n_paired, fmt_p(p_within))
    }
  })

  p_between <- kruskal_p(df[[delta_col]], df$glp1_timing_cat)

  tibble(
    outcome     = outcome_label,
    Overall     = stratum_cells["Overall"],
    `< 6 weeks` = stratum_cells["< 6 weeks"],
    `6wk-3mo`   = stratum_cells["6wk-3mo"],
    `3-6mo`     = stratum_cells["3-6mo"],
    `> 6mo`     = stratum_cells["> 6mo"],
    `p (between)` = fmt_p(p_between)
  )
}

build_event_row <- function(df, outcome_label, event_col) {
  groups <- levels(df$glp1_timing_cat)

  stratum_cells <- sapply(c("Overall", groups), function(g) {
    sub <- if (g == "Overall") df else df %>% filter(glp1_timing_cat == g)
    ev  <- sub[[event_col]]
    n_total <- sum(!is.na(ev))
    n_event <- sum(ev, na.rm = TRUE)
    fmt_pct(n_event, n_total)
  })

  p_between <- fisher_p(df[[event_col]], df$glp1_timing_cat)

  tibble(
    outcome     = outcome_label,
    Overall     = stratum_cells["Overall"],
    `< 6 weeks` = stratum_cells["< 6 weeks"],
    `6wk-3mo`   = stratum_cells["6wk-3mo"],
    `3-6mo`     = stratum_cells["3-6mo"],
    `> 6mo`     = stratum_cells["> 6mo"],
    `p (between)` = fmt_p(p_between)
  )
}

# =============================================================================
# 5. ASSEMBLE TABLE 3a
# =============================================================================

table3a <- bind_rows(
  # --- SBP block ---
  tibble(outcome = "Systolic blood pressure",
         Overall = "", `< 6 weeks` = "", `6wk-3mo` = "",
         `3-6mo` = "", `> 6mo` = "", `p (between)` = ""),
  build_continuous_row(outcome_df, "  Change at 3 months on drug, mmHg",
                       "sbp_baseline_combined", "sbp_m3_glp1",  "sbp_delta_3m"),
  build_continuous_row(outcome_df, "  Change at 6 months on drug, mmHg",
                       "sbp_baseline_combined", "sbp_m6_glp1",  "sbp_delta_6m"),
  build_continuous_row(outcome_df, "  Change at 12 months on drug, mmHg",
                       "sbp_baseline_combined", "sbp_m12_glp1", "sbp_delta_12m"),
  build_event_row(outcome_df, "  >=10 mmHg drop by 3 months on drug",  "sbp_drop10_3m"),
  build_event_row(outcome_df, "  >=10 mmHg drop by 6 months on drug",  "sbp_drop10_6m"),
  build_event_row(outcome_df, "  >=10 mmHg drop by 12 months on drug", "sbp_drop10_12m"),

  # --- DBP block ---
  tibble(outcome = "Diastolic blood pressure",
         Overall = "", `< 6 weeks` = "", `6wk-3mo` = "",
         `3-6mo` = "", `> 6mo` = "", `p (between)` = ""),
  build_continuous_row(outcome_df, "  Change at 3 months on drug, mmHg",
                       "dbp_baseline_combined", "dbp_m3_glp1",  "dbp_delta_3m"),
  build_continuous_row(outcome_df, "  Change at 6 months on drug, mmHg",
                       "dbp_baseline_combined", "dbp_m6_glp1",  "dbp_delta_6m"),
  build_continuous_row(outcome_df, "  Change at 12 months on drug, mmHg",
                       "dbp_baseline_combined", "dbp_m12_glp1", "dbp_delta_12m"),
  build_event_row(outcome_df, "  >=5 mmHg drop by 3 months on drug",  "dbp_drop5_3m"),
  build_event_row(outcome_df, "  >=5 mmHg drop by 6 months on drug",  "dbp_drop5_6m"),
  build_event_row(outcome_df, "  >=5 mmHg drop by 12 months on drug", "dbp_drop5_12m"),

  # --- Weight block (TBWL%) ---
  tibble(outcome = "Weight (TBWL%)",
         Overall = "", `< 6 weeks` = "", `6wk-3mo` = "",
         `3-6mo` = "", `> 6mo` = "", `p (between)` = ""),
  build_continuous_row(outcome_df, "  TBWL% at 3 months on drug",
                       "weight_kg_baseline_combined", "weight_kg_m3_glp1",  "tbwl_3m",
                       digits = 1),
  build_continuous_row(outcome_df, "  TBWL% at 6 months on drug",
                       "weight_kg_baseline_combined", "weight_kg_m6_glp1",  "tbwl_6m",
                       digits = 1),
  build_continuous_row(outcome_df, "  TBWL% at 12 months on drug",
                       "weight_kg_baseline_combined", "weight_kg_m12_glp1", "tbwl_12m",
                       digits = 1),
  build_event_row(outcome_df, "  >=5% TBWL by 3 months on drug",   "ge5_tbwl_3m"),
  build_event_row(outcome_df, "  >=5% TBWL by 6 months on drug",   "ge5_tbwl_6m"),
  build_event_row(outcome_df, "  >=5% TBWL by 12 months on drug",  "ge5_tbwl_12m"),
  build_event_row(outcome_df, "  >=10% TBWL by 3 months on drug",  "ge10_tbwl_3m"),
  build_event_row(outcome_df, "  >=10% TBWL by 6 months on drug",  "ge10_tbwl_6m"),
  build_event_row(outcome_df, "  >=10% TBWL by 12 months on drug", "ge10_tbwl_12m")
)

table3a <- table3a %>% rename(`Outcome` = outcome)

# =============================================================================
# 6. RENDER MD
# =============================================================================
md_caption <- "Table 3a. Primary outcomes — GLP-1-anchored sensitivity analysis at 3, 6, and 12 months on drug"

md_table3a <- knitr::kable(table3a, format = "pipe", caption = md_caption) %>%
  paste(collapse = "\n")

writeLines(md_table3a, file.path(md_dir, "table3a_primary_outcomes_glp1_anchored.md"))

# =============================================================================
# 7. RENDER HTML — NEJM/JAMA minimalist
# =============================================================================
nejm_style <- function(gt_tbl) {
  n_rows <- nrow(gt_tbl[["_data"]])
  gt_tbl %>%
    tab_options(
      table.font.names                = "Georgia, 'Times New Roman', serif",
      table.font.size                 = px(12),
      table.font.color                = "#000000",
      table.background.color          = "#FFFFFF",
      heading.title.font.size         = px(15),
      heading.title.font.weight       = "bold",
      heading.align                   = "left",
      data_row.padding                = px(4),
      column_labels.padding           = px(8),
      column_labels.font.weight       = "bold",
      table.border.top.style          = "none",
      table.border.bottom.style       = "none",
      heading.border.bottom.style     = "none",
      heading.border.lr.style         = "none",
      column_labels.border.top.style  = "none",
      column_labels.border.bottom.style = "none",
      column_labels.border.lr.style   = "none",
      table_body.border.top.style     = "none",
      table_body.border.bottom.style  = "none",
      table_body.hlines.style         = "none",
      table_body.vlines.style         = "none",
      row_group.border.top.style      = "none",
      row_group.border.bottom.style   = "none",
      row_group.border.left.style     = "none",
      row_group.border.right.style    = "none",
      stub.border.style               = "none",
      stub.border.width               = px(0),
      footnotes.border.bottom.style   = "none",
      source_notes.border.bottom.style = "none"
    ) %>%
    tab_style(
      style = cell_borders(sides = "all", color = "#FFFFFF", weight = px(0)),
      locations = list(
        cells_body(),
        cells_column_labels(),
        cells_title(),
        cells_footnotes(),
        cells_source_notes()
      )
    ) %>%
    tab_style(
      style = cell_borders(sides = "top", color = "#000000", weight = px(2)),
      locations = cells_column_labels()
    ) %>%
    tab_style(
      style = cell_borders(sides = "bottom", color = "#000000", weight = px(1)),
      locations = cells_column_labels()
    ) %>%
    tab_style(
      style = cell_borders(sides = "bottom", color = "#000000", weight = px(2)),
      locations = cells_body(rows = n_rows)
    )
}

header_row_indices <- which(table3a$Outcome %in%
                              c("Systolic blood pressure",
                                "Diastolic blood pressure",
                                "Weight (TBWL%)"))

html_table3a <- table3a %>%
  gt() %>%
  tab_header(title = md("**Table 3a.** Primary outcomes — GLP-1-anchored sensitivity analysis at 3, 6, and 12 months on drug")) %>%
  cols_label(
    Outcome     = "Outcome",
    Overall     = "Overall",
    `< 6 weeks` = "< 6 weeks",
    `6wk-3mo`   = "6wk-3mo",
    `3-6mo`     = "3-6mo",
    `> 6mo`     = "> 6mo",
    `p (between)` = "p (between)"
  ) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_body(rows = header_row_indices)
  ) %>%
  tab_source_note(source_note = md(paste(
    "*Sensitivity analysis: same outcomes as Table 3 but anchored to GLP-1 initiation, not delivery date.",
    "Follow-up measurements taken at 3, 6, and 12 months POST-DRUG-START (closest measurement within +/-30/45/60-day window).",
    "This isolates drug effect from postpartum window constraints. Continuous outcomes: median delta (Q1, Q3) [n paired, paired Wilcoxon p].",
    "Threshold outcomes: n/N (%). Positive delta = improvement.",
    "Between-stratum p: Kruskal-Wallis (continuous) / Fisher exact Monte Carlo (binary).*",
    sep = " "
  ))) %>%
  tab_source_note(source_note = md(paste(
    "*Compared with Table 3 (delivery-anchored), this analysis allows late starters to reach full drug exposure.",
    "Differences between strata that persist here likely reflect true biological/persistence variation, not window artifacts.*",
    sep = " "
  ))) %>%
  nejm_style()

gt::gtsave(html_table3a, file.path(html_dir, "table3a_primary_outcomes_glp1_anchored.html"))

# =============================================================================
# 8. PRINT TO CONSOLE
# =============================================================================
cat("\n================================================================\n")
cat(" TABLE 3a — GLP-1 ANCHORED OUTCOMES (MARKDOWN)\n")
cat("================================================================\n\n")
cat(md_table3a, "\n\n")

cat("================================================================\n")
cat(" FILES CREATED\n")
cat("================================================================\n")
cat("MD Files:\n")
cat("  ", file.path(md_dir, "table3a_primary_outcomes_glp1_anchored.md"), "\n")
cat("HTML Files:\n")
cat("  ", file.path(html_dir, "table3a_primary_outcomes_glp1_anchored.html"), "\n")