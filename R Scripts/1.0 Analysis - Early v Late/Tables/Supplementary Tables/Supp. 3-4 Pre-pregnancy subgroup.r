# =============================================================================
# postpartum-glp1: Table 1 — Baseline Demographics and Clinical Characteristics
# -----------------------------------------------------------------------------
# Produces:
#   - Overall column (full cohort)
#   - 4 stratified columns by GLP-1 timing (<6wk / 6wk-3mo / 3-6mo / >6mo)
#   - Between-group p-values (Kruskal-Wallis for continuous, Fisher's exact for
#     categorical — handles small cells without spurious warnings)
#   - Missing data flags
#
# Outputs:
#   /Results/Analysis/Tables/MD Files/    table1_*.md   (printed to console too)
#   /Results/Analysis/Tables/HTML Files/  table1_*.html (NEJM/JAMA minimalist style)
#
# Source AFTER build_analysis_dataset_v2.R (uses analysis_df from memory or rds)
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
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}

data_dir <- file.path(proj_root, "data_processed")
md_dir   <- file.path(proj_root, "Results", "Analysis", "Tables", "MD Files")
html_dir <- file.path(proj_root, "Results", "Analysis", "Tables", "HTML Files")
for (d in c(md_dir, html_dir)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# --- Load data if not in memory ---
if (!exists("analysis_df")) {
  analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
}

cat("Loaded analysis_df:", nrow(analysis_df), "rows ×", ncol(analysis_df), "cols\n\n")

# =============================================================================
# 1. PREPARE TABLE 1 VARIABLES
# =============================================================================
table1_df <- analysis_df %>%
  mutate(
    # BMI category (uses COMBINED baseline = primary -> pp fallback)
    bmi_cat = case_when(
      is.na(bmi_baseline_combined)        ~ NA_character_,
      bmi_baseline_combined <  25         ~ "Normal/Underweight (<25)",
      bmi_baseline_combined >= 25 & bmi_baseline_combined < 30 ~ "Overweight (25-29.9)",
      bmi_baseline_combined >= 30 & bmi_baseline_combined < 35 ~ "Obesity Class I (30-34.9)",
      bmi_baseline_combined >= 35 & bmi_baseline_combined < 40 ~ "Obesity Class II (35-39.9)",
      bmi_baseline_combined >= 40         ~ "Obesity Class III (>=40)",
      TRUE                                ~ NA_character_
    ),
    bmi_cat = factor(bmi_cat,
                     levels = c("Normal/Underweight (<25)",
                                "Overweight (25-29.9)",
                                "Obesity Class I (30-34.9)",
                                "Obesity Class II (35-39.9)",
                                "Obesity Class III (>=40)")),
    parity_cat = case_when(
      is.na(PARITY)                ~ NA_character_,
      as.numeric(PARITY) == 1      ~ "Primiparous (1)",
      as.numeric(PARITY) >= 2      ~ "Multiparous (>=2)",
      TRUE                         ~ NA_character_
    ),
    gravidity_cat = case_when(
      is.na(GRAVIDITY)             ~ NA_character_,
      as.numeric(GRAVIDITY) == 1   ~ "Primigravida (1)",
      as.numeric(GRAVIDITY) >= 2   ~ "Multigravida (>=2)",
      TRUE                         ~ NA_character_
    ),
    delivery_mode_simple = case_when(
      str_detect(DELIVERY_MODALITY, regex("c-section|cesarean", ignore_case = TRUE)) ~ "Cesarean",
      str_detect(DELIVERY_MODALITY, regex("vaginal", ignore_case = TRUE))             ~ "Vaginal",
      TRUE                                                                             ~ "Other/Unknown"
    )
  )

# =============================================================================
# 2. LABEL DICTIONARY
# =============================================================================
label_map <- list(
  # Demographics
  current_age            = "Age at delivery, years",
  race_consolidated      = "Race",
  ethnicity_consolidated = "Ethnicity",

  # Anthropometrics
  height_cm                   = "Height, cm",
  weight_kg_baseline_combined = "Baseline weight, kg",
  bmi_baseline_combined       = "Baseline BMI, kg/m^2",
  bmi_cat                     = "BMI category",
  PREGRAVID_BMI               = "Pre-pregnancy BMI, kg/m^2",

  # Hemodynamics
  sbp_baseline_combined = "Baseline SBP, mmHg",
  dbp_baseline_combined = "Baseline DBP, mmHg",
  bp_stage              = "BP stage (ACC/AHA 2017)",

  # Pregnancy / OB
  gravidity_cat            = "Gravidity",
  parity_cat               = "Parity",
  GESTATIONAL_AGE_IN_WEEKS = "Gestational age at delivery, weeks",
  delivery_mode_simple     = "Delivery mode",

  # GLP-1 exposure
  glp1_first_drug      = "First postpartum GLP-1 drug",
  glp1_persistence_cat = "GLP-1 persistence",
  days_pp_to_glp1      = "Days from delivery to GLP-1 start",

  # Sociobehavioral
  smoking_status = "Smoking status (pre-pregnancy preferred)",
  alc_use_status = "Alcohol use (pre-pregnancy preferred)",

  # CKM comorbidities
  ckm_obesity        = "Obesity (Dx)",
  ckm_t2dm           = "Type 2 diabetes",
  ckm_t1dm           = "Type 1 diabetes",
  ckm_prediabetes    = "Prediabetes",
  ckm_htn            = "Essential hypertension",
  ckm_dyslipidemia   = "Dyslipidemia",
  ckm_ckd_3plus      = "CKD Stage 3A+",
  ckm_osa            = "Obstructive sleep apnea",
  ckm_cad            = "Coronary artery disease",
  ckm_any_hf         = "Heart failure (any)",
  ckm_any_arrhythmia = "Arrhythmia (AF/SVT/VT)",
  ckm_stroke_tia_hx  = "Stroke / TIA history",

  # Pregnancy complications
  preg_htn_any            = "Hypertension during pregnancy",
  preg_htn_gestational    = "Gestational hypertension",
  preg_preec_any_spectrum = "Preeclampsia spectrum (any)",
  preg_gdm                = "Gestational diabetes",
  preg_iugr               = "IUGR",
  preg_sga                = "Small for gestational age",
  preg_abruption          = "Placental abruption",

  # Concomitant medications
  med_metformin   = "Metformin",
  med_insulin     = "Insulin",
  med_acei        = "ACE inhibitor",
  med_arb         = "ARB",
  med_betablocker = "Beta-blocker",
  med_ccb         = "Calcium channel blocker",
  med_diuretic    = "Diuretic",
  med_statin      = "Statin",

  # Labs (baseline = closest pre-GLP-1)
  lab_hba1c_baseline   = "HbA1c, %",
  lab_glucose_baseline = "Glucose, mg/dL",
  lab_creat_baseline   = "Creatinine, mg/dL",
  lab_egfr_baseline    = "eGFR, mL/min/1.73m^2",
  lab_ldl_baseline     = "LDL cholesterol, mg/dL",
  lab_hdl_baseline     = "HDL cholesterol, mg/dL",
  lab_tc_baseline      = "Total cholesterol, mg/dL",
  lab_trig_baseline    = "Triglycerides, mg/dL",
  lab_alt_baseline     = "ALT, U/L",
  lab_ast_baseline     = "AST, U/L",

  # ECG / Echo
  echo_ef          = "Echo LVEF, %",
  echo_bsa         = "BSA, m^2",
  ecg_hr           = "ECG heart rate, bpm",
  ecg_qtc          = "ECG QTc, ms",
  ecg_qrs_duration = "ECG QRS duration, ms"
)

table1_vars <- names(label_map)

# =============================================================================
# 3. BUILD TABLE 1 — STRATIFIED BY GLP-1 TIMING
# =============================================================================
cat("Building Table 1 (stratified by GLP-1 timing)...\n")

# Use Fisher's exact for categorical (handles small cells; no warnings)
# Use Kruskal-Wallis for continuous
# Identify variables with all-zero or single-level values that would break Fisher's test
# These get included in the table but their p-value is suppressed
zero_variance_vars <- table1_df %>%
  select(all_of(table1_vars)) %>%
  summarise(across(everything(), ~ length(unique(na.omit(.))))) %>%
  pivot_longer(everything(), names_to = "var", values_to = "n_levels") %>%
  filter(n_levels <= 1) %>%
  pull(var)

if (length(zero_variance_vars) > 0) {
  cat("Skipping p-value for zero-variance variables:", paste(zero_variance_vars, collapse = ", "), "\n")
}

table1_by_timing <- table1_df %>%
  select(all_of(table1_vars), glp1_timing_2cat) %>%
  tbl_summary(
    by      = glp1_timing_2cat,
    label   = label_map,
    type    = list(
      all_continuous() ~ "continuous",
      starts_with("ckm_")  ~ "dichotomous",
      starts_with("preg_") ~ "dichotomous",
      starts_with("med_")  ~ "dichotomous"
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
    # Skip the zero-variance vars from p-value calculation
    include  = -any_of(zero_variance_vars),
    test     = list(
      all_continuous()  ~ "wilcox.test",
      all_categorical() ~ function(data, variable, by, ...) {
        tab <- table(data[[variable]], data[[by]])
        pv <- fisher.test(tab, simulate.p.value = TRUE, B = 10000)$p.value
        dplyr::tibble(p.value = pv, method = "Fisher (MC sim)")
      }
    ),
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  modify_header(
    label = "**Baseline Characteristic**",
    all_stat_cols() ~ "**{level}**, N = {n}"
  ) %>%
  modify_caption("**Table 1.** Baseline demographics and clinical characteristics, overall and by GLP-1 initiation timing (early vs late)") %>%
  modify_footnote(
    all_stat_cols() ~ paste(
      "Continuous variables: median (Q1, Q3); categorical: n (%).",
      "P-values: Wilcoxon rank-sum for continuous, Fisher exact for categorical.",
      "Early = GLP-1 initiated <6 months postpartum; Late = GLP-1 initiated >=6 months postpartum.",
      "Baseline = closest pre-GLP-1 measurement, postpartum window. Primary tier requires >=42 days postpartum;",
      "for early starters (<6 weeks GLP-1) the postpartum-only fallback tier is used (any day >=0 postpartum, before GLP-1, within 90 days).",
      sep = " "
    )
  )

# =============================================================================
# 4. BUILD TABLE 1 — OVERALL
# =============================================================================
cat("Building Table 1 (overall only)...\n")

table1_overall <- table1_df %>%
  select(all_of(table1_vars)) %>%
  tbl_summary(
    label   = label_map,
    type    = list(
      all_continuous() ~ "continuous",
      starts_with("ckm_")  ~ "dichotomous",
      starts_with("preg_") ~ "dichotomous",
      starts_with("med_")  ~ "dichotomous"
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
    label = "**Baseline Characteristic**",
    stat_0 = "**N = {N}**"
  ) %>%
  modify_caption("**Table 1.** Baseline demographics and clinical characteristics (overall cohort)")

# =============================================================================
# 5. RENDER MD OUTPUT
# =============================================================================
# tbl_summary -> as_tibble -> kable for clean markdown

tbl_to_md <- function(tbl, caption) {
  df <- as_tibble(tbl)
  md <- knitr::kable(df, format = "pipe", caption = caption)
  paste(md, collapse = "\n")
}

md_by_timing <- tbl_to_md(
  table1_by_timing,
  "Table 1. Baseline demographics and clinical characteristics, overall and by GLP-1 initiation timing (early vs late)"
)

md_overall <- tbl_to_md(
  table1_overall,
  "Table 1. Baseline demographics and clinical characteristics (overall cohort)"
)

# Save MD files
writeLines(md_by_timing, file.path(md_dir, "table1_by_timing_2cat.md"))
writeLines(md_overall,   file.path(md_dir, "table1_overall.md"))

# =============================================================================
# 6. RENDER HTML — minimalist NEJM/JAMA style
# =============================================================================
# Style:
#   - Black text, white background
#   - Border at top of header row
#   - Border below header row
#   - Border above the last data row (or above totals if present)
#   - Border at the bottom of the table
#   - No vertical lines, no internal horizontal lines
#   - Serif font (academic feel), tight padding

# Build minimalist gt theme function
nejm_style <- function(gt_tbl) {
  n_rows <- nrow(gt_tbl[["_data"]])

  gt_tbl %>%
    tab_options(
      table.font.names                = "Georgia, 'Times New Roman', serif",
      table.font.size                 = px(13),
      table.font.color                = "#000000",
      table.background.color          = "#FFFFFF",
      heading.title.font.size         = px(15),
      heading.title.font.weight       = "bold",
      heading.align                   = "left",
      data_row.padding                = px(5),
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

html_by_timing <- table1_by_timing %>%
  as_gt() %>%
  nejm_style()

html_overall <- table1_overall %>%
  as_gt() %>%
  nejm_style()

gt::gtsave(html_by_timing, file.path(html_dir, "table1_by_timing_2cat.html"))
gt::gtsave(html_overall,   file.path(html_dir, "table1_overall.html"))

# =============================================================================
# 7. PRINT MD TO CONSOLE
# =============================================================================
cat("\n================================================================\n")
cat(" TABLE 1 — STRATIFIED BY GLP-1 TIMING, EARLY vs LATE (MARKDOWN)\n")
cat("================================================================\n\n")
cat(md_by_timing, "\n\n")

cat("================================================================\n")
cat(" TABLE 1 — OVERALL (MARKDOWN)\n")
cat("================================================================\n\n")
cat(md_overall, "\n\n")

cat("================================================================\n")
cat(" FILES CREATED\n")
cat("================================================================\n")
cat("MD Files:\n")
cat("  ", file.path(md_dir, "table1_by_timing_2cat.md"), "\n")
cat("  ", file.path(md_dir, "table1_overall.md"), "\n")
cat("HTML Files:\n")
cat("  ", file.path(html_dir, "table1_by_timing_2cat.html"), "\n")
cat("  ", file.path(html_dir, "table1_overall.html"), "\n")