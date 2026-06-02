# =============================================================================
# postpartum-glp1: Supplementary Table 1 — Primary Outcomes (Change in Weight, SBP, DBP)
# -----------------------------------------------------------------------------
# Produces:
#   - Overall + by GLP-1 timing stratum
#   - Continuous outcomes: median delta (Q1, Q3) with paired Wilcoxon p-value
#     (within stratum) and Kruskal-Wallis (between strata)
#   - Threshold outcomes: n (%) achieving event with Fisher's exact p-value
#   - All outcomes evaluated at 3, 6, and 12 months postpartum
#
# Outputs:
#   /Results/Analysis/Tables/MD Files/    supplementary_table1_*.md   (printed to console too)
#   /Results/Analysis/Tables/HTML Files/  supplementary_table1_*.html (NEJM/JAMA minimalist)
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
md_dir   <- file.path(proj_root, "Results", "Analysis", "Supplementary Material", "MD Files")
html_dir <- file.path(proj_root, "Results", "Analysis", "Supplementary Material", "HTML Files")
for (d in c(md_dir, html_dir)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

if (!exists("analysis_df")) {
  analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
}

cat("Loaded analysis_df:", nrow(analysis_df), "rows ×", ncol(analysis_df), "cols\n\n")

# =============================================================================
# 1. HELPER FUNCTIONS
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

# Within-stratum paired Wilcoxon (baseline -> follow-up)
paired_wilcox_p <- function(baseline, followup) {
  ok <- !is.na(baseline) & !is.na(followup)
  if (sum(ok) < 5) return(NA_real_)
  suppressWarnings(
    wilcox.test(baseline[ok], followup[ok], paired = TRUE)$p.value
  )
}

# Between-strata Kruskal-Wallis on the delta
kruskal_p <- function(delta, group) {
  ok <- !is.na(delta) & !is.na(group)
  if (sum(ok) < 5 || length(unique(group[ok])) < 2) return(NA_real_)
  suppressWarnings(
    kruskal.test(delta[ok], group[ok])$p.value
  )
}

# Between-strata Fisher's exact for proportions
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
# 2. PREPARE OUTCOME DATA
# =============================================================================
# Compute deltas and event flags at each timepoint using COMBINED baseline.
# Convention: positive delta = improvement (BP down, weight down).

outcome_df <- analysis_df %>%
  mutate(
    # SBP changes (positive = SBP drop = improvement)
    sbp_delta_3m  = sbp_baseline_combined - sbp_m3_pp,
    sbp_delta_6m  = sbp_baseline_combined - sbp_m6_pp,
    sbp_delta_12m = sbp_baseline_combined - sbp_m12_pp,

    # DBP changes
    dbp_delta_3m  = dbp_baseline_combined - dbp_m3_pp,
    dbp_delta_6m  = dbp_baseline_combined - dbp_m6_pp,
    dbp_delta_12m = dbp_baseline_combined - dbp_m12_pp,

    # Weight changes (kg)
    wt_delta_3m  = weight_kg_baseline_combined - weight_kg_m3_pp,
    wt_delta_6m  = weight_kg_baseline_combined - weight_kg_m6_pp,
    wt_delta_12m = weight_kg_baseline_combined - weight_kg_m12_pp,

    # TBWL% (positive = weight loss = improvement)
    tbwl_3m  = (weight_kg_baseline_combined - weight_kg_m3_pp)  / weight_kg_baseline_combined * 100,
    tbwl_6m  = (weight_kg_baseline_combined - weight_kg_m6_pp)  / weight_kg_baseline_combined * 100,
    tbwl_12m = (weight_kg_baseline_combined - weight_kg_m12_pp) / weight_kg_baseline_combined * 100,

    # Threshold events at each timepoint (computed only for patients with both
    # baseline and follow-up measurement at that timepoint)
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
# 3. BUILD ONE ROW OF THE TABLE (per outcome, per timepoint)
# =============================================================================

# Continuous outcomes — show median delta (Q1, Q3) + paired p-value per stratum,
# Kruskal-Wallis between strata
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
    outcome   = outcome_label,
    Overall   = stratum_cells["Overall"],
    `< 6 weeks` = stratum_cells["< 6 weeks"],
    `6wk-3mo` = stratum_cells["6wk-3mo"],
    `3-6mo`   = stratum_cells["3-6mo"],
    `> 6mo`   = stratum_cells["> 6mo"],
    `p (between)` = fmt_p(p_between)
  )
}

# Threshold/event outcomes — show n/N (%) per stratum + Fisher's exact between strata
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
    outcome   = outcome_label,
    Overall   = stratum_cells["Overall"],
    `< 6 weeks` = stratum_cells["< 6 weeks"],
    `6wk-3mo` = stratum_cells["6wk-3mo"],
    `3-6mo`   = stratum_cells["3-6mo"],
    `> 6mo`   = stratum_cells["> 6mo"],
    `p (between)` = fmt_p(p_between)
  )
}

# =============================================================================
# 4. ASSEMBLE SUPPLEMENTARY TABLE 1
# =============================================================================

table3 <- bind_rows(
  # --- SBP block ---
  tibble(outcome = "Systolic blood pressure",
         Overall = "", `< 6 weeks` = "", `6wk-3mo` = "",
         `3-6mo` = "", `> 6mo` = "", `p (between)` = ""),
  build_continuous_row(outcome_df, "  Change at 3 months, mmHg",
                       "sbp_baseline_combined", "sbp_m3_pp",  "sbp_delta_3m"),
  build_continuous_row(outcome_df, "  Change at 6 months, mmHg",
                       "sbp_baseline_combined", "sbp_m6_pp",  "sbp_delta_6m"),
  build_continuous_row(outcome_df, "  Change at 12 months, mmHg",
                       "sbp_baseline_combined", "sbp_m12_pp", "sbp_delta_12m"),
  build_event_row(outcome_df, "  >=10 mmHg drop by 3 months",  "sbp_drop10_3m"),
  build_event_row(outcome_df, "  >=10 mmHg drop by 6 months",  "sbp_drop10_6m"),
  build_event_row(outcome_df, "  >=10 mmHg drop by 12 months", "sbp_drop10_12m"),

  # --- DBP block ---
  tibble(outcome = "Diastolic blood pressure",
         Overall = "", `< 6 weeks` = "", `6wk-3mo` = "",
         `3-6mo` = "", `> 6mo` = "", `p (between)` = ""),
  build_continuous_row(outcome_df, "  Change at 3 months, mmHg",
                       "dbp_baseline_combined", "dbp_m3_pp",  "dbp_delta_3m"),
  build_continuous_row(outcome_df, "  Change at 6 months, mmHg",
                       "dbp_baseline_combined", "dbp_m6_pp",  "dbp_delta_6m"),
  build_continuous_row(outcome_df, "  Change at 12 months, mmHg",
                       "dbp_baseline_combined", "dbp_m12_pp", "dbp_delta_12m"),
  build_event_row(outcome_df, "  >=5 mmHg drop by 3 months",  "dbp_drop5_3m"),
  build_event_row(outcome_df, "  >=5 mmHg drop by 6 months",  "dbp_drop5_6m"),
  build_event_row(outcome_df, "  >=5 mmHg drop by 12 months", "dbp_drop5_12m"),

  # --- Weight block (TBWL% is the primary metric — accounts for baseline weight) ---
  tibble(outcome = "Weight (TBWL%)",
         Overall = "", `< 6 weeks` = "", `6wk-3mo` = "",
         `3-6mo` = "", `> 6mo` = "", `p (between)` = ""),
  build_continuous_row(outcome_df, "  TBWL% at 3 months",
                       "weight_kg_baseline_combined", "weight_kg_m3_pp",  "tbwl_3m",
                       digits = 1),
  build_continuous_row(outcome_df, "  TBWL% at 6 months",
                       "weight_kg_baseline_combined", "weight_kg_m6_pp",  "tbwl_6m",
                       digits = 1),
  build_continuous_row(outcome_df, "  TBWL% at 12 months",
                       "weight_kg_baseline_combined", "weight_kg_m12_pp", "tbwl_12m",
                       digits = 1),
  build_event_row(outcome_df, "  >=5% TBWL by 3 months",   "ge5_tbwl_3m"),
  build_event_row(outcome_df, "  >=5% TBWL by 6 months",   "ge5_tbwl_6m"),
  build_event_row(outcome_df, "  >=5% TBWL by 12 months",  "ge5_tbwl_12m"),
  build_event_row(outcome_df, "  >=10% TBWL by 3 months",  "ge10_tbwl_3m"),
  build_event_row(outcome_df, "  >=10% TBWL by 6 months",  "ge10_tbwl_6m"),
  build_event_row(outcome_df, "  >=10% TBWL by 12 months", "ge10_tbwl_12m")
)

# Rename outcome column for display
table3 <- table3 %>%
  rename(`Outcome` = outcome)

# =============================================================================
# 5. RENDER MD
# =============================================================================
md_caption <- "Supplementary Table 1. Primary outcomes — change in weight, SBP, DBP from baseline at 3, 6, and 12 months postpartum"

md_table3 <- knitr::kable(table3, format = "pipe", caption = md_caption) %>%
  paste(collapse = "\n")

writeLines(md_table3, file.path(md_dir, "supplementary_table1_primary_outcomes.md"))

# =============================================================================
# 6. RENDER HTML — NEJM/JAMA minimalist
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

# Identify header rows (SBP / DBP / Weight) and bold them
header_row_indices <- which(table3$Outcome %in%
                              c("Systolic blood pressure",
                                "Diastolic blood pressure",
                                "Weight (TBWL%)"))

html_table3 <- table3 %>%
  gt() %>%
  tab_header(title = md("**Supplementary Table 1.** Primary outcomes — change in weight, SBP, DBP from baseline at 3, 6, and 12 months postpartum")) %>%
  cols_label(
    Outcome     = "Outcome",
    Overall     = "Overall",
    `< 6 weeks` = "< 6 weeks",
    `6wk-3mo`   = "6wk-3mo",
    `3-6mo`     = "3-6mo",
    `> 6mo`     = "> 6mo",
    `p (between)` = "p (between)"
  ) %>%
  # Bold the section header rows
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_body(rows = header_row_indices)
  ) %>%
  tab_source_note(source_note = md(paste(
    "*Continuous outcomes shown as median delta (Q1, Q3) with [n paired, p-value from Wilcoxon signed-rank within stratum].",
    "Threshold outcomes shown as n/N (%). Positive delta indicates improvement (BP drop or weight loss).",
    "Between-stratum p-value: Kruskal-Wallis for continuous, Fisher exact (Monte Carlo, B=10,000) for binary.",
    "Baseline = combined primary (>=42d postpartum, before GLP-1) with postpartum-only fallback for early starters.*",
    sep = " "
  ))) %>%
  tab_source_note(source_note = md(paste(
    "*Note: Outcomes anchored to DELIVERY DATE. Late starters (> 6mo) have a median of only ~3 months on drug at the 12mo postpartum window,",
    "which substantially underestimates their true drug response. See Supplementary Table 1a for GLP-1-anchored sensitivity analysis at matched exposure times.*",
    sep = " "
  ))) %>%
  nejm_style()

gt::gtsave(html_table3, file.path(html_dir, "supplementary_table1_primary_outcomes.html"))

# =============================================================================
# 7. PRINT TO CONSOLE
# =============================================================================
cat("\n================================================================\n")
cat(" SUPPLEMENTARY TABLE 1 — PRIMARY OUTCOMES (MARKDOWN)\n")
cat("================================================================\n\n")
cat(md_table3, "\n\n")

cat("================================================================\n")
cat(" FILES CREATED\n")
cat("================================================================\n")
cat("MD Files:\n")
cat("  ", file.path(md_dir, "supplementary_table1_primary_outcomes.md"), "\n")
cat("HTML Files:\n")
cat("  ", file.path(html_dir, "supplementary_table1_primary_outcomes.html"), "\n")