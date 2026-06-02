# =============================================================================
# postpartum-glp1: Table 2 — GLP-1 Exposure Characteristics
# -----------------------------------------------------------------------------
# Produces:
#   - Overall column (full cohort)
#   - Stratified by BP subgroup:
#       (a) ACC/AHA 2017 threshold: Stage 1+ HTN (>=130/80 mmHg)
#       (b) Traditional obstetric threshold: HTN (>=140/90 mmHg)
#       (c) Combined dual-threshold comparison (tbl_merge)
#
# Per PI feedback (Adedinsewo DA): added 140/90 threshold alongside 130/80
# to reflect traditional obstetric HTN definition; p-values retained to
# demonstrate no significant differences between BP subgroups in GLP-1
# exposure characteristics.
#
# Outputs:
#   /Results/Analysis/Tables/MD Files/
#       table2_overall.md
#       table2_by_bp_130_80.md
#       table2_by_bp_140_90.md
#       table2_by_bp_combined.md
#   /Results/Analysis/Tables/HTML Files/
#       table2_overall.html
#       table2_by_bp_130_80.html
#       table2_by_bp_140_90.html
#       table2_by_bp_combined.html
#
# Source AFTER build_analysis_dataset_v2.R
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(gtsummary)
  library(gt)
})

# =============================================================================
# 0. PATHS
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

for (d in c(md_dir, html_dir)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# =============================================================================
# 1. LOAD DATA
# =============================================================================
if (!exists("analysis_df")) {
  analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
}

cat("Loaded analysis_df:", nrow(analysis_df), "rows x", ncol(analysis_df), "cols\n\n")

# =============================================================================
# 2. PREPARE VARIABLES
# =============================================================================
table2_df <- analysis_df %>%
  mutate(

    # --- GLP-1 agent — friendly labels ---
    glp1_first_drug_friendly = case_when(
      glp1_first_drug == "semaglutide"  ~ "Semaglutide (Ozempic, Wegovy, Rybelsus)",
      glp1_first_drug == "tirzepatide"  ~ "Tirzepatide (Mounjaro, Zepbound)",
      glp1_first_drug == "liraglutide"  ~ "Liraglutide (Victoza, Saxenda)",
      glp1_first_drug == "dulaglutide"  ~ "Dulaglutide (Trulicity)",
      glp1_first_drug == "exenatide"    ~ "Exenatide (Byetta, Bydureon)",
      glp1_first_drug == "lixisenatide" ~ "Lixisenatide (Adlyxin)",
      TRUE                              ~ "Other / Unspecified"
    ),
    glp1_first_drug_friendly = factor(
      glp1_first_drug_friendly,
      levels = c(
        "Semaglutide (Ozempic, Wegovy, Rybelsus)",
        "Tirzepatide (Mounjaro, Zepbound)",
        "Liraglutide (Victoza, Saxenda)",
        "Dulaglutide (Trulicity)",
        "Exenatide (Byetta, Bydureon)",
        "Lixisenatide (Adlyxin)",
        "Other / Unspecified"
      )
    ),

    # --- Branded indication proxy ---
    glp1_indication_proxy = case_when(
      is.na(glp1_first_brand_wl)  ~ NA_character_,
      glp1_first_brand_wl == TRUE ~ "Weight-loss-branded",
      TRUE                        ~ "T2DM-branded"
    ),
    glp1_indication_proxy = factor(
      glp1_indication_proxy,
      levels = c("Weight-loss-branded", "T2DM-branded")
    ),

    # --- Single agent vs switched ---
    glp1_n_drugs_cat = case_when(
      is.na(glp1_n_distinct_drugs)   ~ NA_character_,
      glp1_n_distinct_drugs == 1     ~ "Single agent",
      glp1_n_distinct_drugs >= 2     ~ "Switched (>=2 agents)"
    ),
    glp1_n_drugs_cat = factor(
      glp1_n_drugs_cat,
      levels = c("Single agent", "Switched (>=2 agents)")
    ),

    # --- BP subgroup: ACC/AHA 2017 (130/80) ---
    bp_subgroup_130_80 = case_when(
      is.na(elevated_bp_any)        ~ NA_character_,
      elevated_bp_any == TRUE       ~ "Stage 1+ HTN (>=130/80 mmHg)",
      TRUE                          ~ "Normal/Elevated BP (<130/80 mmHg)"
    ),
    bp_subgroup_130_80 = factor(
      bp_subgroup_130_80,
      levels = c("Normal/Elevated BP (<130/80 mmHg)", "Stage 1+ HTN (>=130/80 mmHg)")
    ),

    # --- BP subgroup: Traditional obstetric threshold (140/90) ---
    bp_subgroup_140_90 = case_when(
      is.na(sbp_baseline_combined) | is.na(dbp_baseline_combined) ~ NA_character_,
      sbp_baseline_combined >= 140 | dbp_baseline_combined >= 90  ~ "HTN (>=140/90 mmHg)",
      TRUE                                                          ~ "No HTN (<140/90 mmHg)"
    ),
    bp_subgroup_140_90 = factor(
      bp_subgroup_140_90,
      levels = c("No HTN (<140/90 mmHg)", "HTN (>=140/90 mmHg)")
    )
  )

# =============================================================================
# 3. LABEL DICTIONARY
# =============================================================================
label_map <- list(
  # Timing
  days_pp_to_glp1          = "Days from delivery to GLP-1 initiation",
  glp1_timing_cat          = "GLP-1 initiation timing",

  # Drug
  glp1_first_drug_friendly = "First postpartum GLP-1 agent",
  glp1_indication_proxy    = "Branded indication (proxy)",

  # Exposure intensity / persistence
  glp1_n_orders_pp         = "Number of GLP-1 orders postpartum",
  glp1_n_distinct_drugs    = "Number of distinct GLP-1 agents",
  glp1_n_drugs_cat         = "Single agent vs switched",
  glp1_duration_days       = "GLP-1 prescription duration, days",
  glp1_persistence_cat     = "GLP-1 persistence category",
  glp1_active_at_6m_pp     = "Active GLP-1 at 6 months postpartum",
  glp1_active_at_12m_pp    = "Active GLP-1 at 12 months postpartum"
)

table2_vars <- names(label_map)

# =============================================================================
# 4. SHARED tbl_summary ARGUMENTS (avoids repetition)
# =============================================================================
shared_type <- list(
  all_continuous()                                            ~ "continuous",
  c("glp1_active_at_6m_pp", "glp1_active_at_12m_pp")        ~ "dichotomous"
)

shared_statistic <- list(
  all_continuous()  ~ "{median} ({p25}, {p75})",
  all_categorical() ~ "{n} ({p}%)"
)

shared_add_p <- function(tbl) {
  tbl %>%
    add_p(
      test      = list(
        all_continuous()  ~ "wilcox.test",
        all_categorical() ~ "fisher.test"
      ),
      test.args  = all_categorical() ~ list(simulate.p.value = TRUE, B = 10000),
      pvalue_fun = ~ style_pvalue(.x, digits = 3)
    )
}

footnote_130_80 <- paste(
  "Continuous variables: median (Q1, Q3); categorical: n (%).",
  "P-values: Wilcoxon rank-sum for continuous, Fisher exact (simulated, B = 10,000) for categorical.",
  "ACC/AHA 2017 HTN threshold: SBP >=130 mmHg OR DBP >=80 mmHg.",
  sep = " "
)

footnote_140_90 <- paste(
  "Continuous variables: median (Q1, Q3); categorical: n (%).",
  "P-values: Wilcoxon rank-sum for continuous, Fisher exact (simulated, B = 10,000) for categorical.",
  "Traditional obstetric HTN threshold: SBP >=140 mmHg OR DBP >=90 mmHg.",
  sep = " "
)

# =============================================================================
# 5. BUILD TABLES
# =============================================================================

# --- 5a. Overall ---
cat("Building Table 2 (overall)...\n")

table2_overall <- table2_df %>%
  select(all_of(table2_vars)) %>%
  tbl_summary(
    label     = label_map,
    type      = shared_type,
    statistic = shared_statistic,
    digits    = list(all_continuous() ~ 1),
    missing      = "ifany",
    missing_text = "Missing"
  ) %>%
  modify_header(
    label  = "**GLP-1 Exposure Characteristic**",
    stat_0 = "**N = {N}**"
  ) %>%
  modify_caption("**Table 2.** GLP-1 exposure characteristics (overall cohort)") %>%
  bold_labels()

# --- 5b. Stratified by ACC/AHA 2017 (130/80) ---
cat("Building Table 2 (stratified by BP subgroup, 130/80 threshold)...\n")

table2_by_bp_130_80 <- table2_df %>%
  filter(!is.na(bp_subgroup_130_80)) %>%
  select(all_of(table2_vars), bp_subgroup_130_80) %>%
  tbl_summary(
    by        = bp_subgroup_130_80,
    label     = label_map,
    type      = shared_type,
    statistic = shared_statistic,
    digits    = list(all_continuous() ~ 1),
    missing      = "ifany",
    missing_text = "Missing"
  ) %>%
  add_overall(col_label = "**Overall**, N = {N}") %>%
  shared_add_p() %>%
  modify_header(
    label           = "**GLP-1 Exposure Characteristic**",
    all_stat_cols() ~ "**{level}**, N = {n}"
  ) %>%
  modify_caption(
    "**Table 2a.** GLP-1 exposure characteristics by BP subgroup (ACC/AHA 2017: >=130/80 mmHg)"
  ) %>%
  modify_footnote(all_stat_cols() ~ footnote_130_80) %>%
  bold_labels()

# --- 5c. Stratified by traditional obstetric threshold (140/90) ---
cat("Building Table 2 (stratified by BP subgroup, 140/90 threshold)...\n")

table2_by_bp_140_90 <- table2_df %>%
  filter(!is.na(bp_subgroup_140_90)) %>%
  select(all_of(table2_vars), bp_subgroup_140_90) %>%
  tbl_summary(
    by        = bp_subgroup_140_90,
    label     = label_map,
    type      = shared_type,
    statistic = shared_statistic,
    digits    = list(all_continuous() ~ 1),
    missing      = "ifany",
    missing_text = "Missing"
  ) %>%
  add_overall(col_label = "**Overall**, N = {N}") %>%
  shared_add_p() %>%
  modify_header(
    label           = "**GLP-1 Exposure Characteristic**",
    all_stat_cols() ~ "**{level}**, N = {n}"
  ) %>%
  modify_caption(
    "**Table 2b.** GLP-1 exposure characteristics by BP subgroup (traditional obstetric threshold: >=140/90 mmHg)"
  ) %>%
  modify_footnote(all_stat_cols() ~ footnote_140_90) %>%
  bold_labels()

# --- 5d. Combined dual-threshold comparison ---
cat("Building Table 2 (combined dual-threshold)...\n")

table2_bp_combined <- tbl_merge(
  tbls        = list(table2_by_bp_130_80, table2_by_bp_140_90),
  tab_spanner = c(
    "**ACC/AHA 2017 Threshold (>=130/80 mmHg)**",
    "**Traditional Obstetric Threshold (>=140/90 mmHg)**"
  )
) %>%
  modify_caption(
    "**Table 2c.** GLP-1 exposure characteristics by BP subgroup — dual threshold comparison (ACC/AHA 2017 vs traditional obstetric)"
  )

# =============================================================================
# 6. NEJM/JAMA MINIMALIST HTML STYLE
# =============================================================================
nejm_style <- function(gt_tbl) {
  n_rows <- nrow(gt_tbl[["_data"]])

  gt_tbl %>%
    tab_options(
      table.font.names                  = "Georgia, 'Times New Roman', serif",
      table.font.size                   = px(13),
      table.font.color                  = "#000000",
      table.background.color            = "#FFFFFF",
      heading.title.font.size           = px(15),
      heading.title.font.weight         = "bold",
      heading.align                     = "left",
      data_row.padding                  = px(5),
      column_labels.padding             = px(8),
      column_labels.font.weight         = "bold",
      table.border.top.style            = "none",
      table.border.bottom.style         = "none",
      heading.border.bottom.style       = "none",
      heading.border.lr.style           = "none",
      column_labels.border.top.style    = "none",
      column_labels.border.bottom.style = "none",
      column_labels.border.lr.style     = "none",
      table_body.border.top.style       = "none",
      table_body.border.bottom.style    = "none",
      table_body.hlines.style           = "none",
      table_body.vlines.style           = "none",
      row_group.border.top.style        = "none",
      row_group.border.bottom.style     = "none",
      row_group.border.left.style       = "none",
      row_group.border.right.style      = "none",
      stub.border.style                 = "none",
      stub.border.width                 = px(0),
      footnotes.border.bottom.style     = "none",
      source_notes.border.bottom.style  = "none"
    ) %>%
    # Strip all cell borders first
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
    # Top border above column headers
    tab_style(
      style     = cell_borders(sides = "top", color = "#000000", weight = px(2)),
      locations = cells_column_labels()
    ) %>%
    # Bottom border below column headers
    tab_style(
      style     = cell_borders(sides = "bottom", color = "#000000", weight = px(1)),
      locations = cells_column_labels()
    ) %>%
    # Bottom border below final data row
    tab_style(
      style     = cell_borders(sides = "bottom", color = "#000000", weight = px(2)),
      locations = cells_body(rows = n_rows)
    )
}

# =============================================================================
# 7. RENDER MD OUTPUTS
# =============================================================================
tbl_to_md <- function(tbl, caption) {
  df <- as_tibble(tbl)
  md <- knitr::kable(df, format = "pipe", caption = caption)
  paste(md, collapse = "\n")
}

md_overall      <- tbl_to_md(table2_overall,      "Table 2. GLP-1 exposure characteristics (overall cohort)")
md_by_130_80    <- tbl_to_md(table2_by_bp_130_80, "Table 2a. GLP-1 exposure by BP subgroup (ACC/AHA 2017: >=130/80 mmHg)")
md_by_140_90    <- tbl_to_md(table2_by_bp_140_90, "Table 2b. GLP-1 exposure by BP subgroup (traditional obstetric: >=140/90 mmHg)")
md_bp_combined  <- tbl_to_md(table2_bp_combined,  "Table 2c. GLP-1 exposure by BP subgroup — dual threshold comparison")

writeLines(md_overall,     file.path(md_dir, "table2_overall.md"))
writeLines(md_by_130_80,   file.path(md_dir, "table2_by_bp_130_80.md"))
writeLines(md_by_140_90,   file.path(md_dir, "table2_by_bp_140_90.md"))
writeLines(md_bp_combined, file.path(md_dir, "table2_by_bp_combined.md"))

# =============================================================================
# 8. RENDER HTML OUTPUTS
# =============================================================================
html_overall     <- table2_overall      %>% as_gt() %>% nejm_style()
html_by_130_80   <- table2_by_bp_130_80 %>% as_gt() %>% nejm_style()
html_by_140_90   <- table2_by_bp_140_90 %>% as_gt() %>% nejm_style()
html_bp_combined <- table2_bp_combined  %>% as_gt() %>% nejm_style()

gt::gtsave(html_overall,     file.path(html_dir, "table2_overall.html"))
gt::gtsave(html_by_130_80,   file.path(html_dir, "table2_by_bp_130_80.html"))
gt::gtsave(html_by_140_90,   file.path(html_dir, "table2_by_bp_140_90.html"))
gt::gtsave(html_bp_combined, file.path(html_dir, "table2_by_bp_combined.html"))

# =============================================================================
# 9. PRINT MD TO CONSOLE
# =============================================================================
cat("\n================================================================\n")
cat(" TABLE 2 — OVERALL\n")
cat("================================================================\n\n")
cat(md_overall, "\n\n")

cat("================================================================\n")
cat(" TABLE 2a — BY BP SUBGROUP (ACC/AHA 2017: >=130/80 mmHg)\n")
cat("================================================================\n\n")
cat(md_by_130_80, "\n\n")

cat("================================================================\n")
cat(" TABLE 2b — BY BP SUBGROUP (TRADITIONAL OBSTETRIC: >=140/90 mmHg)\n")
cat("================================================================\n\n")
cat(md_by_140_90, "\n\n")

cat("================================================================\n")
cat(" TABLE 2c — DUAL THRESHOLD COMPARISON\n")
cat("================================================================\n\n")
cat(md_bp_combined, "\n\n")

cat("================================================================\n")
cat(" FILES CREATED\n")
cat("================================================================\n")
cat("MD Files:\n")
cat("  ", file.path(md_dir, "table2_overall.md"),        "\n")
cat("  ", file.path(md_dir, "table2_by_bp_130_80.md"),   "\n")
cat("  ", file.path(md_dir, "table2_by_bp_140_90.md"),   "\n")
cat("  ", file.path(md_dir, "table2_by_bp_combined.md"), "\n")
cat("HTML Files:\n")
cat("  ", file.path(html_dir, "table2_overall.html"),        "\n")
cat("  ", file.path(html_dir, "table2_by_bp_130_80.html"),   "\n")
cat("  ", file.path(html_dir, "table2_by_bp_140_90.html"),   "\n")
cat("  ", file.path(html_dir, "table2_by_bp_combined.html"), "\n")