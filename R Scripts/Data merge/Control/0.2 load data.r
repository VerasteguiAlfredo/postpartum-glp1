# =============================================================================
# Load all SAS files into global environment  (corruption-tolerant)
# =============================================================================
library(haven)
library(dplyr)
library(data.table)

# Detect OS and set folder path
sys_name <- Sys.info()[["sysname"]]

folder_path <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1/Perinatal Outcomes_files/Datasets/Controls"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1/Perinatal Outcomes_files/Datasets/Controls"
}

# -----------------------------------------------------------------------------
# Safe loader — never halts the pipeline; a failed read becomes NULL + warning
# -----------------------------------------------------------------------------
load_sas_safe <- function(filename, varname) {
  full_path <- file.path(folder_path, filename)

  if (!file.exists(full_path)) {
    warning("File not found: ", full_path)
    assign(varname, NULL, envir = .GlobalEnv)
    return(invisible(NULL))
  }

  cat("Loading:", filename, "...\n")
  df <- tryCatch(
    haven::read_sas(full_path),
    error = function(e) {
      warning("FAILED to read ", filename, ": ", conditionMessage(e))
      NULL
    }
  )
  assign(varname, df, envir = .GlobalEnv)
  invisible(df)
}

# -----------------------------------------------------------------------------
# Chunked salvage reader — for large/corrupt files.
#   stop_before : stop reading at this row (exclusive). Set just under the
#                 known corrupt row so we never touch the bad page.
#   chunk_size  : rows per read; keeps memory bounded.
#   row_filter  : optional function(df) -> df applied per chunk (e.g. keep
#                 only cohort IDs / relevant lab tests) to shrink the result.
# -----------------------------------------------------------------------------
read_sas_salvage <- function(path,
                             stop_before = Inf,
                             chunk_size  = 1e6,
                             row_filter  = NULL) {
  parts <- list()
  skip  <- 0

  repeat {
    n_this <- min(chunk_size, stop_before - skip)
    if (n_this <= 0) break

    chunk <- tryCatch(
      haven::read_sas(path, skip = skip, n_max = n_this),
      error = function(e) {
        message("  chunk at row ", skip + 1, " failed: ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(chunk)) break            # hit corruption
    got <- nrow(chunk)
    if (got == 0) break                  # clean EOF

    if (!is.null(row_filter)) chunk <- row_filter(chunk)
    parts[[length(parts) + 1L]] <- chunk
    cat("  rows", skip + 1, "-", skip + got, "| kept", nrow(chunk), "\n")

    if (got < n_this) break              # short read = clean EOF
    skip <- skip + got
  }

  if (!length(parts)) return(NULL)
  data.table::rbindlist(parts, use.names = TRUE, fill = TRUE)
}

# -----------------------------------------------------------------------------
# Load each file directly into the global environment
# -----------------------------------------------------------------------------

# Alcohol / SDoH
load_sas_safe("alcohol_flowsheet_controls (1).sas7bdat", "alc_flow_controls")
load_sas_safe("alcohol_ppi_controls.sas7bdat",           "alc_ppi_controls")
load_sas_safe("alcohol_sdoh_controls.sas7bdat",          "alc_sdoh_controls")
load_sas_safe("alcohol_social_hx_controls.sas7bdat",     "alc_social_controls")

# Vitals
load_sas_safe("bmi_controls.sas7bdat",                   "bmi_controls")
load_sas_safe("bp_controls.sas7bdat",                    "bp_controls")
load_sas_safe("heartrate_controls.sas7bdat",             "hr_controls")
load_sas_safe("height_controls.sas7bdat",                "height_controls")

# Cohort & demographics
load_sas_safe("cohort_controls.sas7bdat",                "cohort_controls")
load_sas_safe("demo_controls.sas7bdat",                  "demo_controls")

# Clinical (dx + ob normal; labs is the big/corrupt one → chunked salvage)
load_sas_safe("dx_controls.sas7bdat",                    "dx_controls")
load_sas_safe("ob_data_controls.sas7bdat",               "ob_controls")

cat("Loading: labs_controls.sas7bdat (chunked salvage) ...\n")
labs_controls <- read_sas_salvage(
  file.path(folder_path, "labs_controls.sas7bdat"),
  stop_before = 6505314,   # corrupt row is 6505315; if it still errors, lower this
  chunk_size  = 1e6,
  row_filter  = NULL       # see note below to filter to cohort IDs and save RAM
)

# Cardiac
load_sas_safe("echo_ef_data_controls.sas7bdat",          "echo_ef_controls")

# -----------------------------------------------------------------------------
# Keep data_list + summary
# -----------------------------------------------------------------------------
data_list_controls <- mget(
  c("alc_flow_controls", "alc_ppi_controls", "alc_sdoh_controls",
    "alc_social_controls", "bmi_controls", "bp_controls", "hr_controls",
    "height_controls", "cohort_controls", "demo_controls", "dx_controls",
    "labs_controls", "ob_controls", "echo_ef_controls"),
  envir = .GlobalEnv
)

loaded <- sum(!sapply(data_list_controls, is.null))
n_rows <- sapply(data_list_controls, function(x) if (is.null(x)) "MISSING" else nrow(x))

cat("\n--- Controls load summary ---\n")
cat("Successfully loaded:", loaded, "of", length(data_list_controls), "datasets\n\n")

print(data.frame(dataset = names(n_rows), rows = unname(n_rows), row.names = NULL))