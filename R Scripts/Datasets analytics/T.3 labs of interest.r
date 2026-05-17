# Load library
library(readxl)

# Read Excel file
labs_data <- read_excel(
  "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1/Perinatal Outcomes_files/Datasets/labs.xlsx"
)

head(labs_data)

library(dplyr)

cv_terms <- c(
  "A1C",
  "GLUCOSE",
  "CREATININE",
  "EGFR",
  "CHOLESTEROL",
  "LDL",
  "HDL",
  "TRIGLYCERIDE",
  "CRP",
  "TROPONIN",
  "BNP",
  "INSULIN",
  "AST",
  "ALT",
  "ALBUMIN",
  "PROTEIN"
)

cv_lookup <- labs_data %>%
  filter(
    grepl(
      paste(cv_terms, collapse = "|"),
      TestDesc,
      ignore.case = TRUE
    )
  ) %>%
  distinct(
    Test_Code,
    TestDesc,
    Units,
    Lab_type,
    Lab_Panel_Desc
  ) %>%
  arrange(TestDesc)

print(cv_lookup, n = 100)

cv_lookup %>%
  filter(grepl("A1C", TestDesc, ignore.case = TRUE))

cv_lookup %>%
  filter(grepl("CREATININE", TestDesc, ignore.case = TRUE))

labs_data %>%
  filter(grepl("CREATININE", TestDesc, ignore.case = TRUE)) %>%
  count(TestDesc, Units, sort = TRUE)