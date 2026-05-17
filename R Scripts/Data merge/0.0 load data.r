# =============================================================================
# Load all xlsx files into data_list (run BEFORE sourcing build script)
# =============================================================================
library(readxl)
library(dplyr)

# Set Mac path
folder_path <- "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1/Perinatal Outcomes_files/Datasets"

# Safe loader (in case load_excel_safe() isn't defined in this session)
load_excel_safe <- function(filename) {
  full_path <- file.path(folder_path, filename)
  if (!file.exists(full_path)) {
    warning("File not found: ", full_path)
    return(NULL)
  }
  cat("Loading:", filename, "...\n")
  readxl::read_excel(full_path)
}

data_list <- list(
  # Alcohol / SDoH
  alc_flow    = load_excel_safe("alcohol_flowsheet.xlsx"),
  alc_ppi     = load_excel_safe("alcohol_ppi.xlsx"),
  alc_sdoh    = load_excel_safe("alcohol_sdoh.xlsx"),
  alc_social  = load_excel_safe("alcohol_social_history.xlsx"),
  
  # Vitals
  bmi_flow    = load_excel_safe("bmi_flowsheet.xlsx"),
  bp_flow     = load_excel_safe("bp_flowsheet.xlsx"),
  hr_flow     = load_excel_safe("heartrate_flowsheet.xlsx"),
  height_flow = load_excel_safe("height_flowsheet.xlsx"),
  weight_flow = load_excel_safe("weight_flowsheet.xlsx"),
  
  # Cohort & demographics
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

# Verify
cat("\nLoaded", length(data_list), "datasets\n")
cat("Datasets:", paste(names(data_list), collapse = ", "), "\n")