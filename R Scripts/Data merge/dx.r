# ============================================================
# FILTER DIAGNOSES OF INTEREST USING KEYWORD MATCHING
# ============================================================

library(dplyr)
library(stringr)

# Make sure Dx_Desc is clean (optional but recommended)
dx <- dx %>%
  mutate(Dx_Desc_clean = str_to_lower(Dx_Desc))

# ------------------------------------------------------------
# Define keyword groups (expandable, case-insensitive matching)
# ------------------------------------------------------------

ckm_keywords <- c(
  "atrial fibrillation", "atrial flutter",
  "supraventricular tachycardia",
  "heart failure", "hfpef", "hfref",
  "hypertension", "htn",
  "coronary artery disease", "cad",
  "chronic kidney disease", "ckd",
  "diabetes mellitus type 1", "type i diabetes",
  "diabetes mellitus type 2", "type 2 diabetes",
  "dyslipidemia", "hyperlipidemia",
  "prediabetes",
  "cabg", "coronary artery bypass",
  "stent", "angioplasty",
  "stroke", "tia",
  "obesity", "bmi",
  "peripheral arterial disease", "pad",
  "pacemaker", "defibrillator",
  "ventricular tachycardia",
  "obstructive sleep apnea", "osa"
)

pregnancy_keywords <- c(
  "gestational hypertension",
  "preeclampsia", "eclampsia",
  "gestational diabetes",
  "small for gestational age", "sga",
  "intrauterine growth restriction", "iugr",
  "placental abruption",
  "peripartum cardiomyopathy",
  "postpartum preeclampsia"
)

# ------------------------------------------------------------
# Helper function: detect any keyword match
# ------------------------------------------------------------
match_any_keyword <- function(text, keywords) {
  str_detect(text, str_c(keywords, collapse = "|"))
}

# ------------------------------------------------------------
# Flag conditions in dataset
# ------------------------------------------------------------
dx_filtered <- dx %>%
  mutate(
    ckm_condition = match_any_keyword(Dx_Desc_clean, ckm_keywords),
    pregnancy_condition = match_any_keyword(Dx_Desc_clean, pregnancy_keywords)
  ) %>%
  filter(ckm_condition | pregnancy_condition)

# ------------------------------------------------------------
# Quick summary checks
# ------------------------------------------------------------
dx_filtered %>%
  count(ckm_condition, pregnancy_condition)

# View top matched diagnoses
dx_filtered %>%
  count(Dx_Desc, sort = TRUE) %>%
  print(n = 50)