# =============================================================================
# postpartum-glp1: CONTROLS — slim recon (echo skipped, output to file)
# -----------------------------------------------------------------------------
# Writes results to a .txt file so nothing is lost to console overflow.
# =============================================================================

library(dplyr)
library(purrr)
library(tibble)

# Output file: place next to project folder
sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}
recon_file <- file.path(proj_root, "controls_recon.txt")
sink(recon_file, split = TRUE)   # tee output to file AND console

# ---- Datasets to inspect. Echo skipped (already understood). ---------------
controls_env <- c(
  "alc_flow_controls", "alc_ppi_controls", "alc_sdoh_controls",
  "alc_social_controls", "bmi_controls", "bp_controls", "hr_controls",
  "height_controls", "cohort_controls", "demo_controls", "dx_controls",
  "labs_controls", "ob_controls"
)

# ----- 1. Inventory ---------------------------------------------------------
cat("=== 1. INVENTORY ===\n")
inventory <- purrr::map_dfr(controls_env, function(nm) {
  x <- get(nm, envir = .GlobalEnv)
  key_candidates <- intersect(names(x),
    c("CURR_CLINIC", "curr_clinic", "Clinic_Number", "clinic_number", "CLINIC_NBR"))
  tibble(
    dataset       = nm,
    n_rows        = nrow(x),
    n_cols        = ncol(x),
    mem_mb        = round(as.numeric(object.size(x)) / 1024^2, 1),
    key_candidate = paste(key_candidates, collapse = "|")
  )
})
print(inventory)
cat("\nTotal memory:", round(sum(inventory$mem_mb) / 1024, 2), "GB\n\n")

# Echo separately (just confirm the 4 fields we need are present)
cat("--- echo_ef_controls (spot check of used fields only) ---\n")
echo_needed <- c("curr_clinic", "procedure_date", "ef", "bsa")
cat("Rows:", nrow(echo_ef_controls),
    " | Cols:", ncol(echo_ef_controls), "\n")
cat("Needed fields present:\n")
print(setNames(echo_needed %in% names(echo_ef_controls), echo_needed))
cat("\n")

# ----- 2. Column names per dataset (one at a time, no scroll pileup) -------
cat("=== 2. COLUMN NAMES ===\n")
for (nm in controls_env) {
  cat("\n--- ", nm, " (", ncol(get(nm)), " cols) ---\n", sep = "")
  print(names(get(nm, envir = .GlobalEnv)))
}

# ----- 3. Head(3) for each (skip if too wide to be readable) ---------------
cat("\n=== 3. HEAD(3) ===\n")
for (nm in controls_env) {
  x <- get(nm, envir = .GlobalEnv)
  cat("\n--- ", nm, " ---\n", sep = "")
  # Show first 12 columns only to keep it readable
  print(head(x[, seq_len(min(12, ncol(x)))], 3))
}

# ----- 4. Cohort delivery-date sanity --------------------------------------
cat("\n=== 4. COHORT DELIVERY DATE ===\n")
if ("delv_date" %in% names(cohort_controls)) {
  d <- as.Date(cohort_controls$delv_date)
  cat("delv_date range:", format(range(d, na.rm = TRUE)), "\n")
  cat("Missing delv_date:", sum(is.na(d)), "\n")
  cat("Unique CURR_CLINIC:", dplyr::n_distinct(cohort_controls$CURR_CLINIC), "\n")
  cat("Rows in cohort_controls:", nrow(cohort_controls), "\n")
} else {
  cat("WARNING: no delv_date column found — actual names:\n")
  print(names(cohort_controls))
}

# ----- 5. Post-filter shrinkage preview (KEY for memory strategy) ----------
cat("\n=== 5. POST-FILTER SHRINKAGE (cohort-ID early filter) ===\n")
cohort_ids <- unique(cohort_controls$CURR_CLINIC)
cat("Cohort N:", length(cohort_ids), "\n\n")

big_tables <- c("dx_controls", "labs_controls", "bp_controls",
                "bmi_controls", "hr_controls", "height_controls",
                "alc_social_controls", "alc_flow_controls",
                "alc_ppi_controls", "alc_sdoh_controls")

for (nm in big_tables) {
  x <- get(nm, envir = .GlobalEnv)
  key_col <- intersect(names(x),
              c("CURR_CLINIC", "curr_clinic", "Clinic_Number"))[1]
  if (is.na(key_col)) {
    cat(sprintf("%-22s  (no CURR_CLINIC-like key found)\n", nm)); next
  }
  n_before <- nrow(x)
  n_after  <- sum(x[[key_col]] %in% cohort_ids)
  cat(sprintf("%-22s  before: %11s  after: %10s  (%.2f%% retained)\n",
              nm,
              format(n_before, big.mark = ","),
              format(n_after,  big.mark = ","),
              100 * n_after / n_before))
}

sink()
cat("\nRecon written to:\n  ", recon_file, "\n")