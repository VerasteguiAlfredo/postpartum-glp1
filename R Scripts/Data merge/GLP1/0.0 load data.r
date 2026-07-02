# =============================================================================
# Load all xlsx files into global environment (run BEFORE sourcing build script)
# =============================================================================
library(readxl)
library(dplyr)

# Detect OS and set folder path
sys_name <- Sys.info()[["sysname"]]
folder_path <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1/Perinatal Outcomes_files/Datasets"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1/Perinatal Outcomes_files/Datasets"
}

# Safe loader — reads one xlsx and assigns it directly to .GlobalEnv
load_excel_safe <- function(filename, varname) {
  full_path <- file.path(folder_path, filename)
  if (!file.exists(full_path)) {
    warning("File not found: ", full_path)
    assign(varname, NULL, envir = .GlobalEnv)
    return(invisible(NULL))
  }
  cat("Loading:", filename, "...\n")
  df <- readxl::read_excel(full_path)
  assign(varname, df, envir = .GlobalEnv)
  invisible(df)
}

# Load each file directly into the global environment
# Alcohol / SDoH
load_excel_safe("alcohol_flowsheet.xlsx",       "alc_flow")
load_excel_safe("alcohol_ppi.xlsx",             "alc_ppi")
load_excel_safe("alcohol_sdoh.xlsx",            "alc_sdoh")
load_excel_safe("alcohol_social_history.xlsx",  "alc_social")

# Vitals
load_excel_safe("bmi_flowsheet.xlsx",           "bmi_flow")
load_excel_safe("bp_flowsheet.xlsx",            "bp_flow")
load_excel_safe("heartrate_flowsheet.xlsx",     "hr_flow")
load_excel_safe("height_flowsheet.xlsx",        "height_flow")
load_excel_safe("weight_flowsheet.xlsx",        "weight_flow")

# Cohort & demographics
load_excel_safe("cohort.xlsx",                  "cohort")
load_excel_safe("demo.xlsx",                    "demo")

# Clinical
load_excel_safe("dx.xlsx",                      "dx")
load_excel_safe("labs.xlsx",                    "labs")
load_excel_safe("ob_data.xlsx",                 "ob")
load_excel_safe("smoking.xlsx",                 "smoking")

# Cardiac
load_excel_safe("ecg.xlsx",                     "ecg")
load_excel_safe("echo_ef_data.xlsx",            "echo_ef")
load_excel_safe("echo_data_dictionary.xlsx",    "echo_dict")

# Medications
load_excel_safe("glp1_orderedmed_data.xlsx",    "glp1_meds")
load_excel_safe("ordered_meds.xlsx",            "ord_meds")

# Also keep data_list for any code that still references it
data_list <- mget(c("alc_flow","alc_ppi","alc_sdoh","alc_social",
                    "bmi_flow","bp_flow","hr_flow","height_flow","weight_flow",
                    "cohort","demo","dx","labs","ob","smoking",
                    "ecg","echo_ef","echo_dict","glp1_meds","ord_meds"),
                  envir = .GlobalEnv)

# Verify
loaded   <- sum(!sapply(data_list, is.null))
n_rows   <- sapply(data_list, function(x) if (is.null(x)) "MISSING" else nrow(x))
cat("\n--- Load summary ---\n")
cat("Successfully loaded:", loaded, "of", length(data_list), "datasets\n\n")
print(data_row <- data.frame(dataset = names(n_rows), rows = unname(n_rows)))