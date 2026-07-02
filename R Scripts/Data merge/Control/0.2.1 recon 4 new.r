# =============================================================================
# Recon: 4 newly found control datasets
# =============================================================================
library(dplyr); library(purrr); library(tibble); library(stringr)

sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}
recon_file <- file.path(proj_root, "controls_recon_v2.txt")
sink(recon_file, split = TRUE)

new_tables <- c("weight_controls", "smoking_controls",
                "ord_meds_controls", "patient_list_controls")

# 1. Inventory
cat("=== 1. INVENTORY ===\n")
print(purrr::map_dfr(new_tables, function(nm) {
  if (!exists(nm) || is.null(get(nm)))
    return(tibble(dataset = nm, n_rows = NA, n_cols = NA, mem_mb = NA, key = "FAILED"))
  x <- get(nm)
  tibble(dataset = nm, n_rows = nrow(x), n_cols = ncol(x),
         mem_mb = round(as.numeric(object.size(x))/1024^2, 1),
         key = paste(intersect(names(x), c("CURR_CLINIC","curr_clinic")), collapse="|"))
}))

# 2. Column names
cat("\n=== 2. COLUMN NAMES ===\n")
for (nm in new_tables) {
  if (!exists(nm) || is.null(get(nm))) next
  cat("\n--- ", nm, " (", ncol(get(nm)), " cols) ---\n", sep = "")
  print(names(get(nm)))
}

# 3. Head(3)
cat("\n=== 3. HEAD(3) ===\n")
for (nm in new_tables) {
  if (!exists(nm) || is.null(get(nm))) next
  cat("\n--- ", nm, " ---\n", sep = "")
  print(head(get(nm)[, seq_len(min(12, ncol(get(nm))))], 3))
}

# 4. Domain probes
cat("\n=== 4. DOMAIN PROBES ===\n")

# weight: confirm Result + Result_Units + Assessment_Date
if (exists("weight_controls") && !is.null(weight_controls)) {
  cat("\n--- weight_controls: units ---\n")
  if ("Result_Units" %in% names(weight_controls))
    print(head(sort(table(tolower(trimws(weight_controls$Result_Units))), decreasing=TRUE), 10))
  cat("Has Assessment_Date:", "Assessment_Date" %in% names(weight_controls), "\n")
  cat("Has Result:         ", "Result" %in% names(weight_controls), "\n")
}

# smoking: confirm tob_name / tob_value / tob_dt
if (exists("smoking_controls") && !is.null(smoking_controls)) {
  cat("\n--- smoking_controls: tob_name values ---\n")
  tob_col <- intersect(names(smoking_controls), c("tob_name","Tob_Name","TOB_NAME"))[1]
  if (!is.na(tob_col)) {
    print(head(sort(table(smoking_controls[[tob_col]]), decreasing=TRUE), 15))
  }
  tob_val <- intersect(names(smoking_controls), c("tob_value","Tob_Value","TOB_VALUE"))[1]
  if (!is.na(tob_val)) {
    cat("\n--- smoking_controls: tob_value values (top 15) ---\n")
    print(head(sort(table(smoking_controls[[tob_val]]), decreasing=TRUE), 15))
  }
}

# ord_meds: confirm Order_Name / Med_Generic / dates
if (exists("ord_meds_controls") && !is.null(ord_meds_controls)) {
  cat("\n--- ord_meds_controls: key columns ---\n")
  expected <- c("Order_Name","Med_Generic","Order_Start_Date","Order_Stop_Date")
  present  <- expected %in% names(ord_meds_controls)
  print(setNames(present, expected))
  missing  <- expected[!present]
  if (length(missing)) cat("MISSING:", paste(missing, collapse=", "), "\n")
}

# patient_list: overlap with cohort_controls
if (exists("patient_list_controls") && !is.null(patient_list_controls) && exists("cohort_controls")) {
  cat("\n--- patient_list_controls: overlap with cohort ---\n")
  pl <- unique(patient_list_controls$CURR_CLINIC)
  ch <- unique(cohort_controls$CURR_CLINIC)
  cat("patient_list N:", length(pl), "\n")
  cat("cohort N:      ", length(ch), "\n")
  cat("overlap:       ", length(intersect(pl, ch)), "\n")
  cat("pl only:       ", length(setdiff(pl, ch)), "\n")
  cat("cohort only:   ", length(setdiff(ch, pl)), "\n")
}

sink()
cat("\nRecon written to:\n  ", recon_file, "\n")