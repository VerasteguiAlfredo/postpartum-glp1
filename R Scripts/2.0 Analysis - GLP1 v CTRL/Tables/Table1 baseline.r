# =============================================================================
# postpartum-glp1: Table 1 — Baseline Characteristics (GLP-1 vs Control)
# -----------------------------------------------------------------------------
# Row-binds analysis_df (GLP-1 exposed) + analysis_df_controls (Control) into
# a single frame, then builds a Table 1 comparing baseline covariates that
# will feed the propensity-score matching (PSM) model.
#
# NOTE ON P-VALUES:
#   This is a PRE-PSM Table 1. Because N_control (~36k) >> N_treatment (~700),
#   p-values will be extremely small on nearly every row — that is the intended
#   signal: it quantifies the imbalance that motivates PSM. After matching, a
#   companion script will rebuild this table on the matched cohort using
#   standardized mean differences (SMDs) instead of p-values, which is the
#   preferred balance diagnostic for reviewers.
#
# Outputs:
#   /Results/Analysis/Tables/MD Files/
#       table1_baseline_glp1_vs_control.md
#   /Results/Analysis/Tables/HTML Files/
#       table1_baseline_glp1_vs_control.html
#
# Source AFTER both build scripts have produced their .rds files.
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

# .rds inputs now live in the split subfolder
data_dir <- file.path(proj_root, "data_processed", "rds_processed")
# Fallback: some .rds may still be at the old data_processed root
data_dir_legacy <- file.path(proj_root, "data_processed")

md_dir   <- file.path(proj_root, "Results", "Analysis", "Tables", "MD Files")
html_dir <- file.path(proj_root, "Results", "Analysis", "Tables", "HTML Files")
for (d in c(md_dir, html_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# Small helper: try the rds_processed folder first, then legacy
read_rds_smart <- function(fname) {
  p1 <- file.path(data_dir, fname)
  p2 <- file.path(data_dir_legacy, fname)
  if      (file.exists(p1)) readRDS(p1)
  else if (file.exists(p2)) readRDS(p2)
  else stop("Could not find ", fname, " in either:\n  ", p1, "\n  ", p2)
}

# =============================================================================
# 1. LOAD & ROW-BIND
# =============================================================================
tx   <- read_rds_smart("analysis_df.rds")
ctrl <- read_rds_smart("analysis_df_controls.rds")


### patch
# Legacy fix: treatment analysis_df.rds stored ecg_date as numeric
if ("ecg_date" %in% names(tx) && !inherits(tx$ecg_date, "Date")) {
  tx$ecg_date <- as.Date(tx$ecg_date, origin = "1970-01-01")
}


# Ensure treatment_group is set on both sides
if (!"treatment_group" %in% names(tx))   tx$treatment_group   <- "GLP-1"
if (!"treatment_group" %in% names(ctrl)) ctrl$treatment_group <- "Control"

# Schema parity: warn about columns present in one side only, then union-bind
only_tx   <- setdiff(names(tx),   names(ctrl))
only_ctrl <- setdiff(names(ctrl), names(tx))
if (length(only_tx))   cat("Columns in treatment only (", length(only_tx),   "):\n"); if (length(only_tx))   print(only_tx)
if (length(only_ctrl)) cat("Columns in controls only  (", length(only_ctrl), "):\n"); if (length(only_ctrl)) print(only_ctrl)

combined <- bind_rows(tx, ctrl) %>%
  mutate(
    treatment_group = factor(treatment_group, levels = c("Control", "GLP-1"))
  )

cat("\nCombined analysis_df:", nrow(combined), "rows (",
    sum(combined$treatment_group == "GLP-1"), "GLP-1 /",
    sum(combined$treatment_group == "Control"), "Control )\n\n")

# =============================================================================
# 2. PREPARE VARIABLES
# =============================================================================
# Derived helpers we want in Table 1
table1_df <- combined %>%
  mutate(
    # Pre-pregnancy obesity flag from PREGRAVID_BMI
    prepreg_obesity = case_when(
      is.na(PREGRAVID_BMI) ~ NA_character_,
      PREGRAVID_BMI >= 30  ~ "Yes",
      PREGRAVID_BMI <  30  ~ "No"
    ),
    prepreg_obesity = factor(prepreg_obesity, levels = c("No","Yes")),

    # Delivery modality: collapse to Cesarean vs Vaginal for a cleaner row
    delivery_mode_grouped = case_when(
      is.na(DELIVERY_MODALITY)                                                ~ NA_character_,
      str_detect(DELIVERY_MODALITY, regex("cesarean|c-section|c/s|csect",
                                          ignore_case = TRUE))                ~ "Cesarean",
      str_detect(DELIVERY_MODALITY, regex("vaginal|vbac|forceps|vacuum",
                                          ignore_case = TRUE))                ~ "Vaginal",
      TRUE                                                                     ~ "Other/Unknown"
    ),
    delivery_mode_grouped = factor(delivery_mode_grouped,
                                   levels = c("Vaginal","Cesarean","Other/Unknown")),

    # Multiple births -> yes/no factor
    multiple_births = case_when(
      is.na(MULTIPLE_BIRTHS)              ~ NA_character_,
      as.character(MULTIPLE_BIRTHS) %in% c("Y","Yes","1","TRUE","T") ~ "Yes",
      TRUE                                 ~ "No"
    ),
    multiple_births = factor(multiple_births, levels = c("No","Yes")),

    # BP subgroups (kept for descriptive purposes)
    bp_subgroup_140_90 = case_when(
      is.na(sbp_baseline_combined) | is.na(dbp_baseline_combined) ~ NA_character_,
      sbp_baseline_combined >= 140 | dbp_baseline_combined >= 90  ~ "HTN (>=140/90)",
      TRUE                                                          ~ "No HTN (<140/90)"
    ),
    bp_subgroup_140_90 = factor(bp_subgroup_140_90,
                                levels = c("No HTN (<140/90)","HTN (>=140/90)"))
  )

# =============================================================================
# 3. LABEL DICTIONARY  (matched to what actually populates in analysis_df)
# =============================================================================
label_map <- list(
  # --- Demographics ---
  current_age             = "Age at delivery, years",
  race_consolidated       = "Race",
  ethnicity_consolidated  = "Ethnicity",

  # --- OB history / index pregnancy ---
  GRAVIDITY                 = "Gravidity",
  PARITY                    = "Parity",
  GESTATIONAL_AGE_IN_WEEKS  = "Gestational age at delivery, weeks",
  delivery_mode_grouped     = "Delivery modality",
  multiple_births           = "Multiple gestation",
  NUMBER_OF_PRENATAL_VISITS = "Prenatal visits, n",
  PREGRAVID_BMI             = "Pre-pregnancy BMI, kg/m^2",
  prepreg_obesity           = "Pre-pregnancy obesity (BMI >=30)",
  LAST_MATERNAL_BMI         = "Last maternal BMI (peripartum), kg/m^2",

  # --- Baseline vitals (combined tier) ---
  sbp_baseline_combined       = "Baseline SBP, mmHg",
  dbp_baseline_combined       = "Baseline DBP, mmHg",
  weight_kg_baseline_combined = "Baseline weight, kg",
  bmi_baseline_combined       = "Baseline BMI, kg/m^2",
  height_cm                   = "Height, cm",
  bp_stage                    = "ACC/AHA BP stage",
  bp_subgroup_140_90          = "Obstetric HTN threshold (>=140/90)",

  # --- CKM comorbidities (lifetime pre-delivery) ---
  ckm_htn           = "Hypertension (pre-existing)",
  ckm_t2dm          = "Type 2 diabetes",
  ckm_t1dm          = "Type 1 diabetes",
  ckm_prediabetes   = "Prediabetes",
  ckm_dyslipidemia  = "Dyslipidemia",
  ckm_obesity       = "Obesity (Dx)",
  ckm_osa           = "Obstructive sleep apnea",
  ckm_any_hf        = "Any heart failure (HFpEF or HFrEF)",
  ckm_cad           = "Coronary artery disease",
  ckm_any_arrhythmia= "Any arrhythmia",
  ckm_ckd_3plus     = "CKD stage 3+",
  ckm_stroke_tia_hx = "Stroke / TIA history",
  ckm_count_conditions = "Number of CKM conditions",

  # --- Pregnancy complications (index pregnancy) ---
  preg_htn_gestational      = "Gestational hypertension",
  preg_preec_any_spectrum   = "Preeclampsia spectrum (any)",
  preg_gdm                  = "Gestational diabetes",
  preg_iugr                 = "IUGR / fetal growth restriction",
  preg_sga                  = "Small for gestational age",
  preg_abruption            = "Placental abruption",
  preg_peripartum_cm        = "Peripartum cardiomyopathy",

  # --- Labs (baseline closest pre-index) ---
  lab_hba1c_baseline   = "HbA1c, %",
  lab_glucose_baseline = "Fasting glucose, mg/dL",
  lab_creat_baseline   = "Creatinine, mg/dL",
  lab_egfr_baseline    = "eGFR, mL/min/1.73m^2",
  lab_alt_baseline     = "ALT, U/L",
  lab_ast_baseline     = "AST, U/L",
  lab_ldl_baseline     = "LDL cholesterol, mg/dL",
  lab_hdl_baseline     = "HDL cholesterol, mg/dL",
  lab_tc_baseline      = "Total cholesterol, mg/dL",
  lab_trig_baseline    = "Triglycerides, mg/dL",
  lab_crp_baseline     = "CRP, mg/L",

  # --- Social history (pre-pregnancy preferred) ---
  smoking_status = "Smoking status (pre-pregnancy pref.)",
  alc_use_status = "Alcohol use status (pre-pregnancy pref.)",

  # --- Echo (most recent pre-delivery) ---
  echo_ef = "LVEF at last echo, %",

  # --- Concomitant medications (active near delivery) ---
  med_metformin    = "Metformin",
  med_insulin      = "Insulin",
  med_sglt2        = "SGLT2 inhibitor",
  med_acei         = "ACE inhibitor",
  med_arb          = "ARB",
  med_betablocker  = "Beta-blocker",
  med_ccb          = "Calcium channel blocker",
  med_diuretic     = "Diuretic",
  med_statin       = "Statin"
)

# Keep only labels whose variable actually exists in the combined data
label_map <- label_map[names(label_map) %in% names(table1_df)]
table1_vars <- names(label_map)

cat("Variables included in Table 1:", length(table1_vars), "\n\n")

# =============================================================================
# 4. SHARED tbl_summary ARGS
# =============================================================================
# Force all ckm_*, preg_*, med_* logical/0-1 flags to dichotomous so they
# report a single "Yes (%)" row, not a two-level factor block.
dichotomous_vars <- table1_vars[
  grepl("^(ckm_|preg_|med_)", table1_vars) &
  !grepl("count", table1_vars)
]

shared_type <- list(
  all_continuous() ~ "continuous",
  all_of(dichotomous_vars) ~ "dichotomous"
)

shared_statistic <- list(
  all_continuous()  ~ "{median} ({p25}, {p75})",
  all_categorical() ~ "{n} ({p}%)"
)

# =============================================================================
# 5. BUILD TABLE 1
# =============================================================================
cat("Building Table 1 (GLP-1 vs Control)...\n")

table1_by_group <- table1_df %>%
  select(all_of(table1_vars), treatment_group) %>%
  tbl_summary(
    by        = treatment_group,
    label     = label_map,
    type      = shared_type,
    statistic = shared_statistic,
    digits    = list(all_continuous() ~ 1),
    missing      = "ifany",
    missing_text = "Missing"
  ) %>%
  add_overall(col_label = "**Overall**, N = {N}") %>%
  add_p(
    test = list(
      all_continuous()  ~ "wilcox.test",
      all_categorical() ~ "chisq.test"     # chi-square: fisher exact is too slow at N=36k+
    ),
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  modify_header(
    label           = "**Baseline Characteristic**",
    all_stat_cols() ~ "**{level}**, N = {n}"
  ) %>%
  modify_caption(
    "**Table 1.** Baseline characteristics by treatment group (pre-PSM)"
  ) %>%
  modify_footnote(
    all_stat_cols() ~ paste(
      "Continuous variables: median (Q1, Q3); categorical: n (%).",
      "P-values: Wilcoxon rank-sum for continuous, chi-square for categorical.",
      "Note: this is a pre-PSM comparison; the extreme N imbalance",
      "(N_control >> N_treatment) drives very small p-values regardless of",
      "clinical relevance. Post-PSM balance will be reported via SMDs.",
      sep = " "
    )
  ) %>%
  bold_labels()

# =============================================================================
# 6. NEJM/JAMA MINIMALIST HTML STYLE  (same as previous scripts)
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
    tab_style(
      style = cell_borders(sides = "all", color = "#FFFFFF", weight = px(0)),
      locations = list(cells_body(), cells_column_labels(), cells_title(),
                       cells_footnotes(), cells_source_notes())
    ) %>%
    tab_style(
      style     = cell_borders(sides = "top", color = "#000000", weight = px(2)),
      locations = cells_column_labels()
    ) %>%
    tab_style(
      style     = cell_borders(sides = "bottom", color = "#000000", weight = px(1)),
      locations = cells_column_labels()
    ) %>%
    tab_style(
      style     = cell_borders(sides = "bottom", color = "#000000", weight = px(2)),
      locations = cells_body(rows = n_rows)
    )
}

# =============================================================================
# 7. RENDER OUTPUTS
# =============================================================================
tbl_to_md <- function(tbl, caption) {
  df <- as_tibble(tbl)
  paste(knitr::kable(df, format = "pipe", caption = caption), collapse = "\n")
}

md_table1   <- tbl_to_md(table1_by_group,
                         "Table 1. Baseline characteristics by treatment group (pre-PSM)")
html_table1 <- table1_by_group %>% as_gt() %>% nejm_style()

writeLines(md_table1, file.path(md_dir, "table1_baseline_glp1_vs_control.md"))
gt::gtsave(html_table1, file.path(html_dir, "table1_baseline_glp1_vs_control.html"))

# =============================================================================
# 8. PRINT + CONFIRM
# =============================================================================
cat("\n================================================================\n")
cat(" TABLE 1 — BASELINE CHARACTERISTICS (GLP-1 vs CONTROL, pre-PSM)\n")
cat("================================================================\n\n")
cat(md_table1, "\n\n")

cat("================================================================\n")
cat(" FILES CREATED\n")
cat("================================================================\n")
cat("MD:   ", file.path(md_dir,   "table1_baseline_glp1_vs_control.md"),   "\n")
cat("HTML: ", file.path(html_dir, "table1_baseline_glp1_vs_control.html"), "\n")

invisible(list(table1 = table1_by_group, combined = combined))