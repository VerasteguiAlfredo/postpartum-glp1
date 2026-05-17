# =============================================================================
# POSTPARTUM GLP-1 STUDY — SIMPLE DATASET DIAGNOSTICS
# =============================================================================
# Purpose : Quick structure + column review before merging
# Output  : Markdown report (str + colnames only)
# =============================================================================

library(dplyr)
library(readxl)
library(purrr)

# ── PATHS ────────────────────────────────────────────────────────────────────

DATA_DIR   <- "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1/Perinatal Outcomes_files/Datasets"
SCRIPT_DIR <- "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1/R Scripts/Data merge"
OUT_FILE   <- file.path(SCRIPT_DIR, "dataset_structure_only.md")


# ── LOAD FUNCTION ────────────────────────────────────────────────────────────

load_excel_safe <- function(filename) {
  path <- file.path(DATA_DIR, filename)
  tryCatch(
    readxl::read_excel(path, guess_max = Inf),
    error = function(e) NULL
  )
}


# ── DATA LIST ────────────────────────────────────────────────────────────────

data_list <- list(
  alc_flow    = load_excel_safe("alcohol_flowsheet.xlsx"),
  alc_ppi     = load_excel_safe("alcohol_ppi.xlsx"),
  alc_sdoh    = load_excel_safe("alcohol_sdoh.xlsx"),
  alc_social  = load_excel_safe("alcohol_social_history.xlsx"),

  bmi_flow    = load_excel_safe("bmi_flowsheet.xlsx"),
  bp_flow     = load_excel_safe("bp_flowsheet.xlsx"),
  hr_flow     = load_excel_safe("heartrate_flowsheet.xlsx"),
  height_flow = load_excel_safe("height_flowsheet.xlsx"),
  weight_flow = load_excel_safe("weight_flowsheet.xlsx"),

  cohort      = load_excel_safe("cohort.xlsx"),
  demo        = load_excel_safe("demo.xlsx"),

  dx          = load_excel_safe("dx.xlsx"),
  labs        = load_excel_safe("labs.xlsx"),
  ob          = load_excel_safe("ob_data.xlsx"),
  smoking     = load_excel_safe("smoking.xlsx"),

  ecg         = load_excel_safe("ecg.xlsx"),
  echo_ef     = load_excel_safe("echo_ef_data.xlsx"),
  echo_dict   = load_excel_safe("echo_data_dictionary.xlsx"),

  glp1_meds   = load_excel_safe("glp1_orderedmed_data.xlsx"),
  ord_meds    = load_excel_safe("ordered_meds.xlsx")
)

data_list <- purrr::compact(data_list)


# ── WRITE MARKDOWN ───────────────────────────────────────────────────────────

sink(OUT_FILE)

cat("# Dataset Structure Report\n")
cat("\n**Generated:**", format(Sys.time()), "\n")
cat("\n**Content:** Column names + structure only (str)\n\n")

for (nm in names(data_list)) {

  df <- data_list[[nm]]

  cat("\n\n---\n")
  cat("\n# Dataset:", nm, "\n\n")

  # Dimensions
  cat("## Dimensions\n")
  cat("- Rows:", nrow(df), "\n")
  cat("- Columns:", ncol(df), "\n\n")

  # Column names
  cat("## Column Names\n")
  cat(paste(colnames(df), collapse = ", "), "\n\n")

  # Structure
  cat("## Structure (str)\n")
  capture.output(str(df)) |> cat(sep = "\n")
  cat("\n\n")
}

sink()

cat("\nSaved to:\n", OUT_FILE, "\n")