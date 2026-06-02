# =============================================================================
# postpartum-glp1: 18-Month Follow-up Attrition Check
# =============================================================================

sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}

if (!exists("analysis_df")) {
  analysis_df <- readRDS(file.path(proj_root, "data_processed", "analysis_df.rds"))
}

required_cols <- c("sbp_m18_pp", "weight_kg_m18_pp")
missing_cols <- setdiff(required_cols, names(analysis_df))

if (length(missing_cols) > 0) {
  stop(
    "Missing required columns in analysis_df: ",
    paste(missing_cols, collapse = ", "),
    "\nAvailable columns are:\n",
    paste(names(analysis_df), collapse = ", ")
  )
}

# --- Overall attrition ---
attrition <- analysis_df %>%
  summarise(
    n_total         = n(),
    n_any_vital_18m = sum(!is.na(sbp_m18_pp) | !is.na(weight_kg_m18_pp)),
    pct             = mean(!is.na(sbp_m18_pp) | !is.na(weight_kg_m18_pp)) * 100
  )

# --- Breakdown by vital ---
attrition_detail <- analysis_df %>%
  summarise(
    n_sbp_18m   = sum(!is.na(sbp_m18_pp)),
    pct_sbp_18m = mean(!is.na(sbp_m18_pp)) * 100,
    n_wt_18m    = sum(!is.na(weight_kg_m18_pp)),
    pct_wt_18m  = mean(!is.na(weight_kg_m18_pp)) * 100
  )

# --- Decision ---
decision <- if (attrition$n_any_vital_18m >= 200 && attrition$pct >= 30) {
  "EXTEND to 18 months postpartum"
} else {
  "CENSOR at 12 months for all patients"
}

cat("================================================================\n")
cat(" 18-MONTH FOLLOW-UP ATTRITION CHECK\n")
cat("================================================================\n\n")
cat(sprintf("Total cohort (N):              %d\n", attrition$n_total))
cat(sprintf("Any vital at 18m (n):          %d\n", attrition$n_any_vital_18m))
cat(sprintf("Any vital at 18m (%%):          %.1f%%\n\n", attrition$pct))
cat(sprintf("  SBP at 18m:    n = %d (%.1f%%)\n", attrition_detail$n_sbp_18m, attrition_detail$pct_sbp_18m))
cat(sprintf("  Weight at 18m: n = %d (%.1f%%)\n\n", attrition_detail$n_wt_18m, attrition_detail$pct_wt_18m))
cat("Decision thresholds: n >= 200 AND pct >= 30%\n")
cat("----------------------------------------------------------------\n")
cat(sprintf("DECISION: %s\n", decision))
cat("================================================================\n")