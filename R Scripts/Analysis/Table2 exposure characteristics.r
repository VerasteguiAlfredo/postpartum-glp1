# =============================================================================
# postpartum-glp1: Table 2 — GLP-1 Exposure Characteristics
# -----------------------------------------------------------------------------
# Produces:
#   - Overall column (full cohort)
#   - Stratified by BP subgroup (Normal/Elevated vs Stage 1+ HTN) for the
#     subgroup analysis support
#
# Outputs:
#   /Results/Analysis/Tables/MD Files/    table2_*.md   (printed to console too)
#   /Results/Analysis/Tables/HTML Files/  table2_*.html (NEJM/JAMA minimalist)
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

# --- Paths ---
sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1"
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

cat("Loaded analysis_df:", nrow(analysis_df), "rows ×", ncol(analysis_df), "cols\n\n")

# =============================================================================
# 1. PREPARE TABLE 2 VARIABLES
# =============================================================================
# Some derived variables for clearer reporting

table2_df <- analysis_df %>%
  mutate(
    # Drug class — friendly labels (capitalize, group rare ones)
    glp1_first_drug_friendly = case_when(
      glp1_first_drug == "semaglutide" ~ "Semaglutide (Ozempic, Wegovy, Rybelsus)",
      glp1_first_drug == "tirzepatide" ~ "Tirzepatide (Mounjaro, Zepbound)",
      glp1_first_drug == "liraglutide" ~ "Liraglutide (Victoza, Saxenda)",
      glp1_first_drug == "dulaglutide" ~ "Dulaglutide (Trulicity)",
      glp1_first_drug == "exenatide"   ~ "Exenatide (Byetta, Bydureon)",
      glp1_first_drug == "lixisenatide"~ "Lixisenatide (Adlyxin)",
      TRUE                             ~ "Other / Unspecified"
    ),
    glp1_first_drug_friendly = factor(
      glp1_first_drug_friendly,
      levels = c("Semaglutide (Ozempic, Wegovy, Rybelsus)",
                 "Tirzepatide (Mounjaro, Zepbound)",
                 "Liraglutide (Victoza, Saxenda)",
                 "Dulaglutide (Trulicity)",
                 "Exenatide (Byetta, Bydureon)",
                 "Lixisenatide (Adlyxin)",
                 "Other / Unspecified")
    ),

    # Indication proxy — weight-loss-branded vs T2DM-branded
    glp1_indication_proxy = case_when(
      is.na(glp1_first_brand_wl)        ~ NA_character_,
      glp1_first_brand_wl == TRUE       ~ "Weight-loss-branded",
      glp1_first_brand_wl == FALSE      ~ "T2DM-branded"
    ),
    glp1_indication_proxy = factor(
      glp1_indication_proxy,
      levels = c("Weight-loss-branded", "T2DM-branded")
    ),

    # Drug switches — group 1 vs >=2
    glp1_n_drugs_cat = case_when(
      is.na(glp1_n_distinct_drugs)        ~ NA_character_,
      glp1_n_distinct_drugs == 1          ~ "Single agent",
      glp1_n_distinct_drugs >= 2          ~ "Switched (>=2 agents)"
    ),
    glp1_n_drugs_cat = factor(
      glp1_n_drugs_cat,
      levels = c("Single agent", "Switched (>=2 agents)")
    ),

    # BP subgroup label (for stratification)
    bp_subgroup = case_when(
      is.na(elevated_bp_any)        ~ NA_character_,
      elevated_bp_any == TRUE       ~ "Stage 1+ HTN (>=130/80)",
      elevated_bp_any == FALSE      ~ "Normal/Elevated BP"
    ),
    bp_subgroup = factor(
      bp_subgroup,
      levels = c("Normal/Elevated BP", "Stage 1+ HTN (>=130/80)")
    )
  )

# =============================================================================
# 2. LABEL DICTIONARY (display order)
# =============================================================================
label_map <- list(
  # Timing
  days_pp_to_glp1     = "Days from delivery to GLP-1 initiation",
  glp1_timing_cat     = "GLP-1 initiation timing",

  # Drug class
  glp1_first_drug_friendly = "First postpartum GLP-1 agent",
  glp1_indication_proxy    = "Branded indication (proxy)",

  # Exposure intensity / persistence
  glp1_n_orders_pp        = "Number of GLP-1 orders postpartum",
  glp1_n_distinct_drugs   = "Number of distinct GLP-1 agents",
  glp1_n_drugs_cat        = "Single agent vs switched",
  glp1_duration_days      = "GLP-1 prescription duration, days",
  glp1_persistence_cat    = "GLP-1 persistence category",
  glp1_active_at_6m_pp    = "Active GLP-1 at 6 months postpartum",
  glp1_active_at_12m_pp   = "Active GLP-1 at 12 months postpartum"
)

table2_vars <- names(label_map)

# =============================================================================
# 3. BUILD TABLE 2 — OVERALL ONLY
# =============================================================================
cat("Building Table 2 (overall)...\n")

table2_overall <- table2_df %>%
  select(all_of(table2_vars)) %>%
  tbl_summary(
    label   = label_map,
    type    = list(
      all_continuous() ~ "continuous",
      c("glp1_active_at_6m_pp", "glp1_active_at_12m_pp") ~ "dichotomous"
    ),
    statistic = list(
      all_continuous()  ~ "{median} ({p25}, {p75})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits    = list(all_continuous() ~ 1),
    missing      = "ifany",
    missing_text = "Missing"
  ) %>%
  modify_header(
    label = "**GLP-1 Exposure Characteristic**",
    stat_0 = "**N = {N}**"
  ) %>%
  modify_caption("**Table 2.** GLP-1 exposure characteristics (overall cohort)") %>%
  bold_labels()

# =============================================================================
# 4. BUILD TABLE 2 — STRATIFIED BY BP SUBGROUP
# =============================================================================
cat("Building Table 2 (stratified by BP subgroup)...\n")

table2_by_bp <- table2_df %>%
  filter(!is.na(bp_subgroup)) %>%   # drop patients without baseline BP staging
  select(all_of(table2_vars), bp_subgroup) %>%
  tbl_summary(
    by      = bp_subgroup,
    label   = label_map,
    type    = list(
      all_continuous() ~ "continuous",
      c("glp1_active_at_6m_pp", "glp1_active_at_12m_pp") ~ "dichotomous"
    ),
    statistic = list(
      all_continuous()  ~ "{median} ({p25}, {p75})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits    = list(all_continuous() ~ 1),
    missing      = "ifany",
    missing_text = "Missing"
  ) %>%
  add_overall(col_label = "**Overall**, N = {N}") %>%
  add_p(
    test     = list(
      all_continuous()  ~ "wilcox.test",
      all_categorical() ~ "fisher.test"
    ),
    test.args  = all_categorical() ~ list(simulate.p.value = TRUE, B = 10000),
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  modify_header(
    label = "**GLP-1 Exposure Characteristic**",
    all_stat_cols() ~ "**{level}**, N = {n}"
  ) %>%
  modify_caption("**Table 2.** GLP-1 exposure characteristics, overall and by BP subgroup") %>%
  bold_labels()

# =============================================================================
# 5. RENDER MD OUTPUTS
# =============================================================================
tbl_to_md <- function(tbl, caption) {
  df <- as_tibble(tbl)
  md <- knitr::kable(df, format = "pipe", caption = caption)
  paste(md, collapse = "\n")
}

md_overall <- tbl_to_md(
  table2_overall,
  "Table 2. GLP-1 exposure characteristics (overall cohort)"
)

md_by_bp <- tbl_to_md(
  table2_by_bp,
  "Table 2. GLP-1 exposure characteristics, overall and by BP subgroup"
)

writeLines(md_overall, file.path(md_dir, "table2_overall.md"))
writeLines(md_by_bp,   file.path(md_dir, "table2_by_bp_subgroup.md"))

# =============================================================================
# 6. RENDER HTML — NEJM/JAMA minimalist style
# =============================================================================
nejm_style <- function(gt_tbl) {
  gt_tbl %>%
    tab_options(
      table.border.top.style          = "hidden",
      table.border.bottom.style       = "hidden",
      heading.border.bottom.style     = "hidden",
      column_labels.border.top.style  = "hidden",
      column_labels.border.bottom.style = "hidden",
      table_body.border.top.style     = "hidden",
      table_body.border.bottom.style  = "hidden",
      row_group.border.top.style      = "hidden",
      row_group.border.bottom.style   = "hidden",
      stub.border.style               = "hidden",
      table.font.names                = "Georgia, 'Times New Roman', serif",
      table.font.size                 = px(13),
      table.font.color                = "#000000",
      table.background.color          = "#FFFFFF",
      heading.title.font.size         = px(15),
      heading.title.font.weight       = "bold",
      heading.align                   = "left",
      data_row.padding                = px(5),
      column_labels.padding           = px(8),
      column_labels.font.weight       = "bold"
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
      locations = cells_body(rows = nrow(gt_tbl[["_data"]]))
    )
}

html_overall <- table2_overall %>%
  as_gt() %>%
  nejm_style()

html_by_bp <- table2_by_bp %>%
  as_gt() %>%
  nejm_style()

gt::gtsave(html_overall, file.path(html_dir, "table2_overall.html"))
gt::gtsave(html_by_bp,   file.path(html_dir, "table2_by_bp_subgroup.html"))

# =============================================================================
# 7. PRINT MD TO CONSOLE
# =============================================================================
cat("\n================================================================\n")
cat(" TABLE 2 — OVERALL (MARKDOWN)\n")
cat("================================================================\n\n")
cat(md_overall, "\n\n")

cat("================================================================\n")
cat(" TABLE 2 — STRATIFIED BY BP SUBGROUP (MARKDOWN)\n")
cat("================================================================\n\n")
cat(md_by_bp, "\n\n")

cat("================================================================\n")
cat(" FILES CREATED\n")
cat("================================================================\n")
cat("MD Files:\n")
cat("  ", file.path(md_dir, "table2_overall.md"), "\n")
cat("  ", file.path(md_dir, "table2_by_bp_subgroup.md"), "\n")
cat("HTML Files:\n")
cat("  ", file.path(html_dir, "table2_overall.html"), "\n")
cat("  ", file.path(html_dir, "table2_by_bp_subgroup.html"), "\n")