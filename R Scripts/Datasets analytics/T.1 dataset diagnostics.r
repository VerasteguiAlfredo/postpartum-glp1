# =============================================================================
# POSTPARTUM GLP-1 STUDY — DATASET DIAGNOSTICS
# =============================================================================
# Purpose : Profile all raw datasets before merging
# Output  : Console summary + markdown report (dataset_overview.md)
# Author  : [Your name]
# Updated : [Date]
# =============================================================================

# ── 0. SETUP ─────────────────────────────────────────────────────────────────

library(dplyr)
library(readxl)
library(skimr)
library(purrr)

# Paths
DATA_DIR   <- "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1/Perinatal Outcomes_files/Datasets"
SCRIPT_DIR <- "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1/R Scripts/Data merge"
OUT_FILE   <- file.path(SCRIPT_DIR, "dataset_overview.md")


# ── 1. LOAD DATASETS ─────────────────────────────────────────────────────────

# FIX 1 -- readxl type-guessing warnings
# By default read_excel() inspects only the first 1000 rows to guess column
# types. When a column is all-NA in those rows but has text later (e.g. "BPM",
# "Patient reported..."), it guesses "logical" and warns on every mismatch.
# Setting guess_max = Inf forces a full-file scan before guessing, eliminating
# those warnings. suppressWarnings() catches any residual edge cases.

load_excel_safe <- function(filename) {
  path <- file.path(DATA_DIR, filename)
  tryCatch(
    suppressWarnings(read_excel(path, guess_max = Inf)),
    error = function(e) {
      warning("Could not load: ", filename, " -- ", conditionMessage(e))
      NULL
    }
  )
}

data_list <- list(
  # Alcohol / SDoH
  alc_flow    = load_excel_safe("alcohol_flowsheet.xlsx"),
  alc_ppi     = load_excel_safe("alcohol_ppi.xlsx"),
  alc_sdoh    = load_excel_safe("alcohol_sdoh.xlsx"),
  alc_social  = load_excel_safe("alcohol_social_history.xlsx"),

  # Vitals (flowsheets)
  bmi_flow    = load_excel_safe("bmi_flowsheet.xlsx"),
  bp_flow     = load_excel_safe("bp_flowsheet.xlsx"),
  hr_flow     = load_excel_safe("heartrate_flowsheet.xlsx"),
  height_flow = load_excel_safe("height_flowsheet.xlsx"),
  weight_flow = load_excel_safe("weight_flowsheet.xlsx"),

  # Core cohort & demographics
  cohort      = load_excel_safe("cohort.xlsx"),
  demo        = load_excel_safe("demo.xlsx"),

  # Clinical
  dx          = load_excel_safe("dx.xlsx"),
  labs        = load_excel_safe("labs.xlsx"),
  ob          = load_excel_safe("ob_data.xlsx"),
  smoking     = load_excel_safe("smoking.xlsx"),

  # Cardiac
  ecg         = load_excel_safe("ecg.xlsx"),
  echo_ef     = load_excel_safe("echo_ef_data.xlsx"),
  echo_dict   = load_excel_safe("echo_data_dictionary.xlsx"),

  # Medications
  glp1_meds   = load_excel_safe("glp1_orderedmed_data.xlsx"),
  ord_meds    = load_excel_safe("ordered_meds.xlsx")
)

# Drop any datasets that failed to load
data_list <- purrr::compact(data_list)

n_loaded <- length(data_list)
n_failed <- 20 - n_loaded

cat("Loaded:", n_loaded, "datasets\n")
cat("Failed:", n_failed, "\n\n")

if (n_failed > 0) {
  cat("NOTE: Check file names and paths for any datasets that failed to load.\n\n")
}


# ── 2. HELPER: SINGLE-DATASET DIAGNOSTICS ────────────────────────────────────

diagnose_dataset <- function(df, nm, to_console = TRUE, to_md = FALSE) {

  header <- paste0("\n", strrep("=", 60),
                   "\n  DATASET: ", nm,
                   "\n", strrep("=", 60))
  dims   <- paste0("Rows: ", nrow(df), "   |   Columns: ", ncol(df))
  cols   <- paste(colnames(df), collapse = ", ")

  # --- Missing values (only columns that have any NAs) ---------------------
  miss_raw <- sort(colSums(is.na(df)), decreasing = TRUE)
  miss_raw <- miss_raw[miss_raw > 0]
  if (length(miss_raw) == 0) {
    miss_str <- "  (none)"
  } else {
    miss_pct <- round(miss_raw / nrow(df) * 100, 1)
    miss_str <- paste0("  ", names(miss_raw), ": ", miss_raw,
                       " (", miss_pct, "%)", collapse = "\n")
  }

  # --- Column types summary ------------------------------------------------
  # FIX 2 -- multi-class columns crash table(sapply(..., class))
  # Columns like POSIXct have class c("POSIXct", "POSIXt"), so sapply()
  # returns a list instead of a character vector, breaking table().
  # vapply(..., character(1)) enforces extraction of only the FIRST class,
  # always returning a plain character vector that table() handles correctly.
  col_classes <- vapply(df, function(x) class(x)[1], character(1))
  type_tbl    <- table(col_classes)
  type_str    <- paste(names(type_tbl), as.integer(type_tbl),
                       sep = " x ", collapse = ",  ")

  # --- Date columns -- range check -----------------------------------------
  date_cols <- names(df)[sapply(df, inherits,
                                what = c("Date", "POSIXct", "POSIXlt"))]
  if (length(date_cols) > 0) {
    date_ranges <- sapply(date_cols, function(col) {
      vals <- df[[col]]
      paste0(format(min(vals, na.rm = TRUE)), " to ",
             format(max(vals, na.rm = TRUE)))
    })
    date_str <- paste0("  ", date_cols, ": ", date_ranges, collapse = "\n")
  } else {
    date_str <- "  (none)"
  }

  # --- Potential ID columns ------------------------------------------------
  id_cols <- grep("(id|pat|mrn|patient)", colnames(df),
                  ignore.case = TRUE, value = TRUE)
  if (length(id_cols) > 0) {
    id_n_unique <- sapply(id_cols,
                          function(col) n_distinct(df[[col]], na.rm = TRUE))
    id_str <- paste0("  ", id_cols, ": ", id_n_unique,
                     " unique values", collapse = "\n")
  } else {
    id_str <- "  (none detected)"
  }

  # --- Console output -------------------------------------------------------
  if (to_console) {
    cat(header, "\n")
    cat("\nDimensions  :", dims, "\n")
    cat("\nColumn types:", type_str, "\n")
    cat("\nColumns     :\n  ", cols, "\n")
    cat("\nID-like columns:\n", id_str, "\n")
    cat("\nDate columns and ranges:\n", date_str, "\n")
    cat("\nMissing values (columns with any NA):\n", miss_str, "\n")
    cat("\nSkim:\n")
    print(skim(df))
    cat("\n")
  }

  # --- Markdown output ------------------------------------------------------
  if (to_md) {
    lines <- c(
      "\n\n---\n",
      paste0("# Dataset: `", nm, "`\n"),
      "## Dimensions",
      paste0("- Rows: ", nrow(df)),
      paste0("- Columns: ", ncol(df), "\n"),
      "## Column Types",
      paste0(type_str, "\n"),
      "## Columns",
      paste0("`", cols, "`\n"),
      "## ID-like Columns",
      id_str, "\n",
      "## Date Columns and Ranges",
      date_str, "\n",
      "## Missing Values (columns with any NA)",
      miss_str, "\n",
      "## Skim Summary",
      paste(capture.output(print(skim(df))), collapse = "\n"),
      "\n"
    )
    return(invisible(lines))
  }
}


# ── 3. CONSOLE DIAGNOSTICS ───────────────────────────────────────────────────

for (nm in names(data_list)) {
  diagnose_dataset(data_list[[nm]], nm, to_console = TRUE, to_md = FALSE)
}


# ── 4. CROSS-DATASET SUMMARY TABLE ───────────────────────────────────────────

cat("\n", strrep("=", 60), "\n")
cat("  CROSS-DATASET SUMMARY\n")
cat(strrep("=", 60), "\n\n")

summary_tbl <- purrr::imap_dfr(data_list, function(df, nm) {
  id_cols   <- grep("(id|pat|mrn|patient)", colnames(df),
                    ignore.case = TRUE, value = TRUE)
  date_cols <- names(df)[sapply(df, inherits,
                                what = c("Date", "POSIXct", "POSIXlt"))]
  data.frame(
    Dataset     = nm,
    Rows        = nrow(df),
    Cols        = ncol(df),
    Pct_Missing = round(mean(is.na(df)) * 100, 1),
    ID_cols     = paste(id_cols,   collapse = ", "),
    Date_cols   = paste(date_cols, collapse = ", "),
    stringsAsFactors = FALSE
  )
})

print(summary_tbl, row.names = FALSE)


# ── 5. WRITE MARKDOWN REPORT ─────────────────────────────────────────────────

sink(OUT_FILE)

cat("# Dataset Diagnostic Overview\n")
cat("\n**Study:** Postpartum GLP-1 Receptor Agonist Cohort\n")
cat("\n**Generated:** ", format(Sys.time()), "\n")
cat("\n**Datasets loaded:** ", length(data_list), "\n")

# Cross-dataset summary table (markdown pipe table)
cat("\n\n---\n")
cat("# Summary Table\n\n")
cat("| Dataset | Rows | Cols | % Missing | ID Columns | Date Columns |\n")
cat("|---------|------|------|-----------|------------|--------------|\n")
for (i in seq_len(nrow(summary_tbl))) {
  r <- summary_tbl[i, ]
  cat("|", r$Dataset, "|", r$Rows, "|", r$Cols, "|",
      r$Pct_Missing, "|", r$ID_cols, "|", r$Date_cols, "|\n")
}

# Per-dataset detail sections
for (nm in names(data_list)) {
  lines <- diagnose_dataset(data_list[[nm]], nm,
                            to_console = FALSE, to_md = TRUE)
  cat(lines, sep = "\n")
}

sink()

cat("\nMarkdown report written to:\n ", OUT_FILE, "\n")