# =============================================================================
# postpartum-glp1: CONTROLS — recon of 4 newly added datasets
# -----------------------------------------------------------------------------
# Assumes datasets are already loaded into the global environment:
#   - ord_meds_controls
#   - patient_list_controls
#   - smoking_controls
#   - weight_controls
#   - cohort_controls
# Output tee'd to controls_recon_v2.txt
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(tibble)
})

sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}

recon_file <- file.path(proj_root, "controls_recon_v2.txt")

# ---- Recon output tee'd to file --------------------------------------------
sink(recon_file, split = TRUE)

new_tables <- c(
  "ord_meds_controls",
  "patient_list_controls",
  "smoking_controls",
  "weight_controls"
)

# 1. Inventory
cat("=== 1. INVENTORY ===\n")
inventory <- purrr::map_dfr(new_tables, function(nm) {
  if (!exists(nm) || is.null(get(nm))) {
    return(tibble(
      dataset = nm,
      n_rows = NA,
      n_cols = NA,
      mem_mb = NA,
      key_candidate = "NOT LOADED"
    ))
  }

  x <- get(nm, envir = .GlobalEnv)

  key_candidates <- intersect(
    names(x),
    c("CURR_CLINIC", "curr_clinic", "Clinic_Number", "clinic_number", "CLINIC_NBR")
  )

  tibble(
    dataset = nm,
    n_rows = nrow(x),
    n_cols = ncol(x),
    mem_mb = round(as.numeric(object.size(x)) / 1024^2, 1),
    key_candidate = paste(key_candidates, collapse = "|")
  )
})

print(inventory)

cat(
  "\nTotal memory:",
  round(sum(inventory$mem_mb, na.rm = TRUE) / 1024, 2),
  "GB\n\n"
)

# 2. Column names
cat("=== 2. COLUMN NAMES ===\n")

for (nm in new_tables) {
  if (!exists(nm) || is.null(get(nm))) next

  cat("\n--- ", nm, " (", ncol(get(nm)), " cols) ---\n", sep = "")
  print(names(get(nm, envir = .GlobalEnv)))
}

# 3. Head(3)
cat("\n=== 3. HEAD(3) ===\n")

for (nm in new_tables) {
  if (!exists(nm) || is.null(get(nm))) next

  x <- get(nm, envir = .GlobalEnv)

  cat("\n--- ", nm, " ---\n", sep = "")
  print(head(x[, seq_len(min(12, ncol(x)))], 3))
}

# 4. Domain-specific probes
cat("\n=== 4. DOMAIN PROBES ===\n")

# weight_controls
if (exists("weight_controls") && !is.null(weight_controls)) {

  cat("\n--- weight_controls: units distribution ---\n")

  if ("Result_Units" %in% names(weight_controls)) {
    print(
      head(
        sort(
          table(tolower(trimws(weight_controls$Result_Units))),
          decreasing = TRUE
        ),
        10
      )
    )
  }

  cat("Has Assessment_Date:", "Assessment_Date" %in% names(weight_controls), "\n")
  cat("Has Result:         ", "Result" %in% names(weight_controls), "\n")
}

# smoking_controls
if (exists("smoking_controls") && !is.null(smoking_controls)) {

  cat("\n--- smoking_controls: tob_name distribution (top 15) ---\n")

  tob_name_col <- intersect(
    names(smoking_controls),
    c("tob_name", "Tob_Name", "TOB_NAME", "tobacco_name")
  )[1]

  if (!is.na(tob_name_col)) {

    print(
      head(
        sort(
          table(smoking_controls[[tob_name_col]]),
          decreasing = TRUE
        ),
        15
      )
    )

  } else {

    cat("(no tob_name-like column — showing all names)\n")
    print(names(smoking_controls))

  }
}

# ord_meds_controls
if (exists("ord_meds_controls") && !is.null(ord_meds_controls)) {

  cat("\n--- ord_meds_controls: key medication columns ---\n")

  med_cols <- intersect(
    names(ord_meds_controls),
    c(
      "Order_Name",
      "Med_Generic",
      "Order_Start_Date",
      "Order_Stop_Date"
    )
  )

  cat("Expected med columns present:\n")
  print(setNames(med_cols %in% names(ord_meds_controls), med_cols))

  cat("Missing expected columns:\n")

  print(
    setdiff(
      c(
        "Order_Name",
        "Med_Generic",
        "Order_Start_Date",
        "Order_Stop_Date"
      ),
      names(ord_meds_controls)
    )
  )
}

# patient_list_controls
if (exists("patient_list_controls") &&
    !is.null(patient_list_controls) &&
    exists("cohort_controls")) {

  cat("\n--- patient_list_controls: overlap with cohort_controls ---\n")

  pl_ids <- unique(patient_list_controls$CURR_CLINIC)
  ch_ids <- unique(cohort_controls$CURR_CLINIC)

  cat("N unique CURR_CLINIC in patient_list:", length(pl_ids), "\n")
  cat("N unique CURR_CLINIC in cohort:     ", length(ch_ids), "\n")
  cat("In patient_list only: ", length(setdiff(pl_ids, ch_ids)), "\n")
  cat("In cohort only:       ", length(setdiff(ch_ids, pl_ids)), "\n")
  cat("Common:               ", length(intersect(pl_ids, ch_ids)), "\n")
}

# 5. Cohort-ID filter preview
if (exists("cohort_controls")) {

  cat("\n=== 5. POST-FILTER SHRINKAGE ===\n")

  cohort_ids <- unique(cohort_controls$CURR_CLINIC)

  cat("Cohort N:", length(cohort_ids), "\n\n")

  for (nm in new_tables) {

    if (!exists(nm) || is.null(get(nm))) next

    x <- get(nm, envir = .GlobalEnv)

    key_col <- intersect(
      names(x),
      c("CURR_CLINIC", "curr_clinic", "Clinic_Number")
    )[1]

    if (is.na(key_col)) {
      cat(sprintf("%-24s  (no key)\n", nm))
      next
    }

    n_before <- nrow(x)
    n_after  <- sum(x[[key_col]] %in% cohort_ids)

    cat(
      sprintf(
        "%-24s  before: %10s  after: %10s  (%.2f%% retained)\n",
        nm,
        format(n_before, big.mark = ","),
        format(n_after, big.mark = ","),
        100 * n_after / n_before
      )
    )
  }
}

sink()

cat("\nRecon written to:\n  ", recon_file, "\n")