# =============================================================================
# postpartum-glp1: Build Analysis-Ready Dataset
# -----------------------------------------------------------------------------
# Purpose : Merge all loaded xlsx tables (in `data_list`) into a single
#           patient-level analysis dataset for evaluating postpartum GLP-1
#           effects on BP and weight within 12 months postpartum.
#
# Inputs  : `data_list` (already in memory) with named tibbles:
#           alc_flow, alc_ppi, alc_sdoh, alc_social,
#           bmi_flow, bp_flow, hr_flow, height_flow, weight_flow,
#           cohort, demo, dx, labs, ob, smoking,
#           ecg, echo_ef, echo_dict,
#           glp1_meds, ord_meds
#
# Outputs : `analysis_df`  — one row per patient, wide format
#           `vitals_long`  — long-format longitudinal BP/weight (for plots / mixed models)
#           `events_df`    — time-to-event table (SBP/DBP/weight thresholds)
#
# Author  : Alf (built with Claude)
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(stringr)
  library(purrr)
  library(data.table)
  library(readr)
})

# Cross-platform path detection (matches existing project convention)
sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "~/Documents/postpartum-glp1"                                          # Mac (personal)
} else {
  "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1"            # Windows (work)
}
out_dir <- file.path(proj_root, "data_processed")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# 0. HELPERS
# =============================================================================

# Safe numeric coercion — handles "<5", ">100", "Negative", etc.
to_num <- function(x) suppressWarnings(as.numeric(x))

# Parse "SBP/DBP" string from bp_flow$Result
parse_bp <- function(bp_string) {
  parts <- str_split_fixed(bp_string, "/", 2)
  list(
    sbp = to_num(parts[, 1]),
    dbp = to_num(parts[, 2])
  )
}

# Normalize weight to kg given Result_Units
weight_to_kg <- function(value, units) {
  v <- to_num(value)
  u <- tolower(trimws(units))
  dplyr::case_when(
    u %in% c("kg", "kilogram", "kilograms") ~ v,
    u %in% c("lb", "lbs", "pound", "pounds") ~ v * 0.45359237,
    u %in% c("oz", "ounce", "ounces") ~ v * 0.028349523125,
    u %in% c("g", "gram", "grams") ~ v / 1000,
    TRUE ~ NA_real_
  )
}

# Normalize height to cm
height_to_cm <- function(value, units) {
  v <- to_num(value)
  u <- tolower(trimws(units))
  dplyr::case_when(
    u %in% c("cm", "centimeter", "centimeters") ~ v,
    u %in% c("m", "meter", "meters") ~ v * 100,
    u %in% c("in", "inch", "inches") ~ v * 2.54,
    TRUE ~ NA_real_
  )
}

# Pick closest measurement to a target date, within a window
# (used for baseline & per-window post values)
closest_within <- function(dates, values, target, window_days = NULL, side = c("any", "before", "after")) {
  side <- match.arg(side)
  ok <- !is.na(dates) & !is.na(values) & !is.na(target)
  if (!any(ok)) return(NA_real_)
  d <- as.Date(dates[ok]); v <- values[ok]; t <- as.Date(target)
  diff <- as.numeric(d - t)
  keep <- switch(side,
                 any    = rep(TRUE, length(diff)),
                 before = diff <= 0,
                 after  = diff >= 0)
  if (!is.null(window_days)) keep <- keep & abs(diff) <= window_days
  if (!any(keep)) return(NA_real_)
  v <- v[keep]; diff <- diff[keep]
  v[which.min(abs(diff))]
}

# =============================================================================
# 1. PULL FROM data_list (lives in your global env)
# =============================================================================
stopifnot(exists("data_list"))
list2env(data_list, envir = environment())

# =============================================================================
# 2. COHORT BACKBONE — one row per patient
# =============================================================================
# Cohort has 729 patients (all female delivery cohort). We start here.
# Exclude patients with privacy/auth issues per standard practice.

cohort_clean <- cohort %>%
  filter(auth == "Y",
         Privacy != "Y",
         Test_Patient != "Y",
         Legal != "Y") %>%
  mutate(delv_date = as.Date(delv_date),
         Birth_Dt  = as.Date(Birth_Dt),
         Death_Dt  = as.Date(Death_Dt)) %>%
  select(CURR_CLINIC, delv_date, Birth_Dt, current_age, Gender,
         Deceased, Death_Dt, Hospice, Dismissed) %>%
  # One row per patient — keep earliest delivery if duplicates exist
  group_by(CURR_CLINIC) %>%
  arrange(delv_date, .by_group = TRUE) %>%
  slice(1) %>%
  ungroup()

cat("Cohort after auth/privacy filter:", nrow(cohort_clean), "patients\n")

# Demographics
demo_clean <- demo %>%
  select(CURR_CLINIC, Ethnicity_Name, race_primary,
         race_secondary_race1, race_secondary_race2) %>%
  distinct(CURR_CLINIC, .keep_all = TRUE)

# OB data — keep delivery-relevant fields; one row per delivery, prefer index delivery
ob_clean <- ob %>%
  mutate(DELIVERY_DTM = as.Date(DELIVERY_DTM)) %>%
  # If multiple deliveries per patient, keep the one matching cohort delv_date
  group_by(CURR_CLINIC) %>%
  arrange(desc(DELIVERY_DTM), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  mutate(
    pregravid_weight_kg     = PREGRAVID_WEIGHT_IN_OUNCES * 0.028349523125,
    last_maternal_weight_kg = LAST_MATERNAL_WEIGHT_IN_OUNCES * 0.028349523125,
    birth_weight_kg         = BIRTH_WEIGHT_IN_OUNCES * 0.028349523125
  ) %>%
  select(CURR_CLINIC, DELIVERY_DTM,
         GESTATIONAL_AGE_IN_WEEKS, GESTATIONAL_AGE_IN_DAYS,
         DELIVERY_MODALITY, DELIVERY_COMPLICATIONS,
         GRAVIDITY, PARITY, MULTIPLE_BIRTHS,
         PREGRAVID_BMI, LAST_MATERNAL_BMI,
         pregravid_weight_kg, last_maternal_weight_kg, birth_weight_kg,
         NUMBER_OF_PRENATAL_VISITS, INFERTILITY_TREATMENT,
         PRIOR_CESAREAN_YN, LABOR_ATTEMPT_YN,
         APGAR_1, APGAR_5)

# =============================================================================
# 3. GLP-1 EXPOSURE — index date and exposure class
# =============================================================================
# Identify postpartum GLP-1 start (first order on or after delv_date)

glp1_clean <- glp1_meds %>%
  mutate(Order_Start_Date = as.Date(Order_Start_Date),
         Order_Date       = as.Date(Order_Date)) %>%
  # Prefer Order_Start_Date; fall back to Order_Date
  mutate(glp1_start = coalesce(Order_Start_Date, Order_Date)) %>%
  # Drop glp1_meds' own delv_date to avoid name collision with cohort_clean
  select(-any_of("delv_date")) %>%
  inner_join(cohort_clean %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(!is.na(delv_date), !is.na(glp1_start))

# Classify drug from Order_Name (handles weight-loss-branded variants)
glp1_clean <- glp1_clean %>%
  mutate(
    drug_name = case_when(
      str_detect(Order_Name, regex("semaglutide", ignore_case = TRUE)) ~ "semaglutide",
      str_detect(Order_Name, regex("liraglutide", ignore_case = TRUE)) ~ "liraglutide",
      str_detect(Order_Name, regex("tirzepatide", ignore_case = TRUE)) ~ "tirzepatide",
      str_detect(Order_Name, regex("dulaglutide", ignore_case = TRUE)) ~ "dulaglutide",
      str_detect(Order_Name, regex("exenatide",   ignore_case = TRUE)) ~ "exenatide",
      str_detect(Order_Name, regex("lixisenatide",ignore_case = TRUE)) ~ "lixisenatide",
      TRUE ~ "other_glp1"
    ),
    is_weightloss_brand = str_detect(Order_Name,
      regex("weight loss|wegovy|saxenda|zepbound", ignore_case = TRUE))
  )

# Postpartum GLP-1: order start ≥ delv_date
glp1_postpartum <- glp1_clean %>%
  filter(glp1_start >= delv_date) %>%
  group_by(CURR_CLINIC) %>%
  arrange(glp1_start, .by_group = TRUE) %>%
  summarise(
    glp1_index_date     = first(glp1_start),
    glp1_first_drug     = first(drug_name),
    glp1_first_brand_wl = first(is_weightloss_brand),
    glp1_n_orders_pp    = n(),
    glp1_drugs_all      = paste(sort(unique(drug_name)), collapse = "|"),
    days_pp_to_glp1     = as.numeric(first(glp1_start) - first(delv_date)),
    .groups = "drop"
  )

# Pre-pregnancy / pre-delivery GLP-1 exposure (for sensitivity / exclusion)
glp1_predelivery <- glp1_clean %>%
  filter(glp1_start < delv_date) %>%
  group_by(CURR_CLINIC) %>%
  summarise(glp1_predelivery_any = TRUE,
            glp1_predelivery_first = suppressWarnings(min(glp1_start, na.rm = TRUE)),
            .groups = "drop") %>%
  mutate(glp1_predelivery_first = as.Date(ifelse(is.infinite(glp1_predelivery_first),
                                                  NA, glp1_predelivery_first),
                                          origin = "1970-01-01"))

# Build exposure flag on full cohort
exposure_df <- cohort_clean %>%
  select(CURR_CLINIC, delv_date) %>%
  left_join(glp1_postpartum,   by = "CURR_CLINIC") %>%
  left_join(glp1_predelivery,  by = "CURR_CLINIC") %>%
  mutate(
    glp1_postpartum_exposed = !is.na(glp1_index_date),
    glp1_predelivery_any    = coalesce(glp1_predelivery_any, FALSE),
    # For unexposed: use delv_date as pseudo-index for symmetric windowing
    index_date = coalesce(glp1_index_date, delv_date),
    index_source = if_else(glp1_postpartum_exposed, "glp1_start", "delivery_date")
  )

cat("Postpartum GLP-1 exposed:", sum(exposure_df$glp1_postpartum_exposed), "\n")
cat("Pre-delivery GLP-1 exposed:", sum(exposure_df$glp1_predelivery_any), "\n")

# =============================================================================
# 4. VITALS — BP and Weight longitudinal
# =============================================================================

# --- Blood pressure ---
bp_parsed <- bp_flow %>%
  filter(!is.na(Result), str_detect(Result, "^\\s*\\d+\\s*/\\s*\\d+")) %>%
  mutate(Assessment_Date = as.Date(Assessment_Date),
         sbp = to_num(str_extract(Result, "^\\s*\\d+")),
         dbp = to_num(str_extract(Result, "(?<=/)\\s*\\d+")))

bp_long <- bp_parsed %>%
  filter(!is.na(sbp), !is.na(dbp),
         sbp > 50, sbp < 260,
         dbp > 30, dbp < 180) %>%
  select(CURR_CLINIC, meas_date = Assessment_Date, sbp, dbp,
         Encounter_Nbr, Site, Site_State)

# --- Weight ---
wt_long <- weight_flow %>%
  filter(!is.na(Result), !is.na(Result_Units)) %>%
  mutate(Assessment_Date = as.Date(Assessment_Date),
         weight_kg = weight_to_kg(Result, Result_Units)) %>%
  filter(!is.na(weight_kg), weight_kg > 30, weight_kg < 350) %>%
  select(CURR_CLINIC, meas_date = Assessment_Date, weight_kg,
         Encounter_Nbr, Site, Site_State)

# --- Height (one per patient, latest pre-index) ---
ht_long <- height_flow %>%
  filter(!is.na(Result), !is.na(Result_Units)) %>%
  mutate(Assessment_Date = as.Date(Assessment_Date),
         height_cm = height_to_cm(Result, Result_Units)) %>%
  filter(!is.na(height_cm), height_cm > 120, height_cm < 220) %>%
  select(CURR_CLINIC, meas_date = Assessment_Date, height_cm)

height_summary <- ht_long %>%
  group_by(CURR_CLINIC) %>%
  summarise(height_cm = median(height_cm, na.rm = TRUE), .groups = "drop")

# Restrict vitals to **postpartum window** for analysis: delv_date to delv_date + 365
vitals_long <- bind_rows(
  bp_long %>% mutate(measure = "bp") %>%
    pivot_longer(c(sbp, dbp), names_to = "vital", values_to = "value") %>%
    select(CURR_CLINIC, meas_date, vital, value),
  wt_long %>% select(CURR_CLINIC, meas_date, value = weight_kg) %>%
    mutate(vital = "weight_kg") %>%
    select(CURR_CLINIC, meas_date, vital, value)
) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date, index_date,
                                    glp1_postpartum_exposed, index_source),
             by = "CURR_CLINIC") %>%
  filter(meas_date >= delv_date,
         meas_date <= delv_date + 365) %>%
  mutate(days_from_index   = as.numeric(meas_date - index_date),
         days_from_delivery = as.numeric(meas_date - delv_date))

# =============================================================================
# 5. PER-PATIENT BASELINE & POST-INDEX VITAL SUMMARIES
# =============================================================================

# For each patient: baseline (closest pre-index within 90d) and
# post values at 1m, 3m, 6m, 12m (closest within ±30d of target).
windows_post <- list(
  m1  = 30,
  m3  = 90,
  m6  = 180,
  m12 = 365
)

summarise_vital <- function(df, vital_name) {
  df %>%
    filter(vital == vital_name) %>%
    group_by(CURR_CLINIC) %>%
    summarise(
      baseline = closest_within(meas_date, value, first(index_date),
                                window_days = 90, side = "before"),
      m1  = closest_within(meas_date, value, first(index_date) + 30,
                           window_days = 21, side = "any"),
      m3  = closest_within(meas_date, value, first(index_date) + 90,
                           window_days = 30, side = "any"),
      m6  = closest_within(meas_date, value, first(index_date) + 180,
                           window_days = 45, side = "any"),
      m12 = closest_within(meas_date, value, first(index_date) + 365,
                           window_days = 60, side = "any"),
      n_meas_pp = n(),
      .groups = "drop"
    ) %>%
    rename_with(~ paste0(vital_name, "_", .x), -CURR_CLINIC)
}

sbp_summary    <- summarise_vital(vitals_long, "sbp")
dbp_summary    <- summarise_vital(vitals_long, "dbp")
weight_summary <- summarise_vital(vitals_long, "weight_kg")

# =============================================================================
# 6. TIME-TO-EVENT (clinically meaningful improvements)
# =============================================================================
# Events (post-index, post-delivery only):
#   - SBP drop ≥ 10 mmHg vs baseline
#   - DBP drop ≥ 5  mmHg vs baseline
#   - Weight loss > 10% vs baseline

compute_events <- function(vitals_long, vital_name, baseline_df, baseline_col, threshold_fn) {
  baselines <- baseline_df %>% select(CURR_CLINIC, baseline = all_of(baseline_col))
  vitals_long %>%
    filter(vital == vital_name, days_from_index >= 0) %>%
    inner_join(baselines, by = "CURR_CLINIC") %>%
    filter(!is.na(baseline)) %>%
    mutate(event = threshold_fn(value, baseline)) %>%
    group_by(CURR_CLINIC) %>%
    arrange(meas_date, .by_group = TRUE) %>%
    summarise(
      event_occurred = any(event, na.rm = TRUE),
      time_to_event  = if (any(event, na.rm = TRUE))
                         min(days_from_index[event], na.rm = TRUE) else NA_real_,
      last_followup  = max(days_from_index, na.rm = TRUE),
      .groups = "drop"
    )
}

sbp_event <- compute_events(
  vitals_long, "sbp", sbp_summary, "sbp_baseline",
  function(v, b) (b - v) >= 10
) %>% rename(sbp_event = event_occurred, sbp_tte = time_to_event, sbp_fu = last_followup)

dbp_event <- compute_events(
  vitals_long, "dbp", dbp_summary, "dbp_baseline",
  function(v, b) (b - v) >= 5
) %>% rename(dbp_event = event_occurred, dbp_tte = time_to_event, dbp_fu = last_followup)

wt_event <- compute_events(
  vitals_long, "weight_kg", weight_summary, "weight_kg_baseline",
  function(v, b) ((b - v) / b) > 0.10
) %>% rename(wt_event = event_occurred, wt_tte = time_to_event, wt_fu = last_followup)

events_df <- exposure_df %>%
  select(CURR_CLINIC, glp1_postpartum_exposed, index_date) %>%
  left_join(sbp_event, by = "CURR_CLINIC") %>%
  left_join(dbp_event, by = "CURR_CLINIC") %>%
  left_join(wt_event,  by = "CURR_CLINIC")

# =============================================================================
# 7. COMORBIDITIES — diagnosis-derived flags (pre-index)
# =============================================================================
# Use ICD-10 prefix matching on dx codes prior to index_date.

dx_clean <- dx %>%
  mutate(Dx_Date = as.Date(Dx_Date)) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, index_date), by = "CURR_CLINIC") %>%
  filter(!is.na(Dx_Date), Dx_Date <= index_date)

dx_flag <- function(df, regex_pat, label) {
  df %>%
    filter(str_detect(Dx_Code, regex_pat)) %>%
    distinct(CURR_CLINIC) %>%
    mutate(!!label := TRUE)
}

comorb_t2dm <- dx_flag(dx_clean, "^E11", "cm_t2dm")
comorb_t1dm <- dx_flag(dx_clean, "^E10", "cm_t1dm")
comorb_gdm  <- dx_flag(dx_clean, "^O24", "cm_gdm")
comorb_htn  <- dx_flag(dx_clean, "^I1[0-5]", "cm_htn")
comorb_pre  <- dx_flag(dx_clean, "^O1[3-6]|^O11", "cm_preeclampsia")
comorb_obesity <- dx_flag(dx_clean, "^E66", "cm_obesity")
comorb_dyslip  <- dx_flag(dx_clean, "^E78", "cm_dyslipidemia")
comorb_ckd     <- dx_flag(dx_clean, "^N18", "cm_ckd")
comorb_hf      <- dx_flag(dx_clean, "^I50", "cm_hf")
comorb_cad     <- dx_flag(dx_clean, "^I25", "cm_cad")
comorb_af      <- dx_flag(dx_clean, "^I48", "cm_afib")
comorb_pcos    <- dx_flag(dx_clean, "^E28\\.2", "cm_pcos")
comorb_thyroid <- dx_flag(dx_clean, "^E0[3-5]", "cm_thyroid")
comorb_depress <- dx_flag(dx_clean, "^F3[23]", "cm_depression")
comorb_anxiety <- dx_flag(dx_clean, "^F41", "cm_anxiety")

comorbidities <- list(comorb_t2dm, comorb_t1dm, comorb_gdm, comorb_htn,
                      comorb_pre, comorb_obesity, comorb_dyslip, comorb_ckd,
                      comorb_hf, comorb_cad, comorb_af, comorb_pcos,
                      comorb_thyroid, comorb_depress, comorb_anxiety) %>%
  reduce(full_join, by = "CURR_CLINIC") %>%
  mutate(across(starts_with("cm_"), ~ coalesce(., FALSE)))

# =============================================================================
# 8. LAB SUMMARIES — closest pre-index values for key labs
# =============================================================================
# Cardiometabolic labs of interest. Use TestDesc / Lab_Subtype to identify.

lab_keys <- list(
  hba1c    = "(?i)hemoglobin a1c|hba1c|a1c",
  glucose  = "(?i)glucose",
  ldl      = "(?i)ldl cholesterol|ldl-c|ldl, calc",
  hdl      = "(?i)hdl cholesterol|hdl-c",
  trig     = "(?i)triglyceride",
  tc       = "(?i)cholesterol, total|total cholesterol",
  creat    = "(?i)creatinine",
  egfr     = "(?i)egfr|estimated gfr",
  alt      = "(?i)\\bALT\\b|alanine amino",
  ast      = "(?i)\\bAST\\b|aspartate amino",
  tsh      = "(?i)\\bTSH\\b|thyrotropin"
)

labs_clean <- labs %>%
  mutate(Lab_Date = as.Date(Lab_Date),
         Resultn  = to_num(Resultn)) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, index_date), by = "CURR_CLINIC") %>%
  filter(!is.na(Resultn), !is.na(Lab_Date))

get_closest_lab <- function(pattern, label) {
  labs_clean %>%
    filter(str_detect(TestDesc, pattern) |
           str_detect(Lab_Subtype, pattern) |
           str_detect(Lab_Panel_Desc, pattern)) %>%
    filter(Lab_Date <= index_date) %>%
    group_by(CURR_CLINIC) %>%
    arrange(desc(Lab_Date), .by_group = TRUE) %>%
    slice(1) %>%
    ungroup() %>%
    transmute(CURR_CLINIC,
              !!paste0("lab_", label, "_value") := Resultn,
              !!paste0("lab_", label, "_date")  := Lab_Date)
}

labs_wide <- imap(lab_keys, get_closest_lab) %>%
  reduce(full_join, by = "CURR_CLINIC")

# =============================================================================
# 9. SMOKING — most recent pre-index status
# =============================================================================
smoking_clean <- smoking %>%
  mutate(tob_dt = as.Date(tob_dt)) %>%
  filter(tob_name == "SMOKING_STATUS_SUMMARY", !is.na(tob_value)) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, index_date), by = "CURR_CLINIC") %>%
  filter(tob_dt <= index_date) %>%
  group_by(CURR_CLINIC) %>%
  arrange(desc(tob_dt), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(CURR_CLINIC, smoking_status = tob_value, smoking_status_date = tob_dt)

# =============================================================================
# 10. ALCOHOL — derive AUDIT-C summary from PPI / SDoH (most recent pre-index)
# =============================================================================

# Helper: returns first value if any exist, else NA_real_
first_or_na <- function(x) if (length(x) == 0) NA_real_ else x[1]

alc_ppi_clean <- alc_ppi %>%
  mutate(Ans_Dt = as.Date(Ans_Dt),
         Ans_Value = to_num(Ans_Value)) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, index_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(Ans_Dt <= index_date) %>%
  group_by(CURR_CLINIC) %>%
  arrange(desc(Ans_Dt), .by_group = TRUE) %>%
  summarise(
    audit_frequency = first_or_na(Ans_Value[str_detect(Question_Text,
                        regex("how often do you have a drink", ignore_case = TRUE))]),
    audit_quantity  = first_or_na(Ans_Value[str_detect(Question_Text,
                        regex("how many drinks",               ignore_case = TRUE))]),
    audit_binge     = first_or_na(Ans_Value[str_detect(Question_Text,
                        regex("six or more",                   ignore_case = TRUE))]),
    audit_date      = suppressWarnings(max(Ans_Dt, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  mutate(audit_date = as.Date(ifelse(is.infinite(audit_date), NA, audit_date),
                              origin = "1970-01-01"),
         audit_c_score = rowSums(across(c(audit_frequency, audit_quantity, audit_binge)),
                                  na.rm = TRUE),
         # If all three components are NA, set score to NA rather than 0
         audit_c_score = ifelse(is.na(audit_frequency) & is.na(audit_quantity) & is.na(audit_binge),
                                NA_real_, audit_c_score))

# =============================================================================
# 11. ECHO / EF — most recent pre-index EF
# =============================================================================
echo_clean <- echo_ef %>%
  rename(CURR_CLINIC = curr_clinic) %>%
  mutate(procedure_date = as.Date(procedure_date),
         ef = to_num(ef)) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, index_date),
             by = "CURR_CLINIC") %>%
  filter(procedure_date <= index_date, !is.na(ef)) %>%
  group_by(CURR_CLINIC) %>%
  arrange(desc(procedure_date), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(CURR_CLINIC,
            echo_ef = ef,
            echo_date = procedure_date,
            echo_bsa = bsa)

# =============================================================================
# 12. CONCOMITANT MEDICATIONS — flag classes active near index
# =============================================================================
# Active = order start ≤ index_date AND (stop missing OR stop ≥ index_date - 30d)
ord_meds_clean <- ord_meds %>%
  mutate(Order_Start_Date = as.Date(Order_Start_Date),
         Order_Stop_Date  = as.Date(Order_Stop_Date)) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, index_date), by = "CURR_CLINIC") %>%
  filter(Order_Start_Date <= index_date,
         is.na(Order_Stop_Date) | Order_Stop_Date >= (index_date - 30))

med_class_flag <- function(df, pattern, label) {
  df %>%
    filter(str_detect(Order_Name, regex(pattern, ignore_case = TRUE)) |
           str_detect(Med_Generic, regex(pattern, ignore_case = TRUE))) %>%
    distinct(CURR_CLINIC) %>%
    mutate(!!label := TRUE)
}

med_metformin <- med_class_flag(ord_meds_clean, "metformin", "med_metformin")
med_insulin   <- med_class_flag(ord_meds_clean, "insulin",   "med_insulin")
med_sglt2     <- med_class_flag(ord_meds_clean,
  "empagliflozin|dapagliflozin|canagliflozin|ertugliflozin", "med_sglt2")
med_acei      <- med_class_flag(ord_meds_clean,
  "lisinopril|enalapril|ramipril|captopril|benazepril", "med_acei")
med_arb       <- med_class_flag(ord_meds_clean,
  "losartan|valsartan|olmesartan|telmisartan|irbesartan|candesartan", "med_arb")
med_bb        <- med_class_flag(ord_meds_clean,
  "metoprolol|atenolol|carvedilol|bisoprolol|propranolol|labetalol|nebivolol", "med_betablocker")
med_ccb       <- med_class_flag(ord_meds_clean,
  "amlodipine|nifedipine|diltiazem|verapamil|felodipine", "med_ccb")
med_diuretic  <- med_class_flag(ord_meds_clean,
  "hydrochlorothiazide|hctz|furosemide|spironolactone|chlorthalidone|bumetanide", "med_diuretic")
med_statin    <- med_class_flag(ord_meds_clean,
  "atorvastatin|simvastatin|rosuvastatin|pravastatin|lovastatin|pitavastatin", "med_statin")

meds_wide <- list(med_metformin, med_insulin, med_sglt2, med_acei, med_arb,
                  med_bb, med_ccb, med_diuretic, med_statin) %>%
  reduce(full_join, by = "CURR_CLINIC") %>%
  mutate(across(starts_with("med_"), ~ coalesce(., FALSE)))

# =============================================================================
# 13. ASSEMBLE FINAL WIDE ANALYSIS DATAFRAME
# =============================================================================

# --- Diagnostic checks before assembly ---
cat("\n--- Pre-assembly diagnostics ---\n")
cat("Cohort patients:                ", nrow(cohort_clean), "\n")
cat("Patients with any GLP-1 order:  ", n_distinct(glp1_clean$CURR_CLINIC), "\n")
cat("Postpartum GLP-1 exposed:       ", sum(exposure_df$glp1_postpartum_exposed), "\n")
cat("Pre-delivery GLP-1 exposed:     ", sum(exposure_df$glp1_predelivery_any), "\n")
cat("Median days delivery→GLP-1:     ",
    suppressWarnings(median(exposure_df$days_pp_to_glp1, na.rm = TRUE)), "\n")
cat("Range days delivery→GLP-1:      ",
    suppressWarnings(paste(range(exposure_df$days_pp_to_glp1, na.rm = TRUE), collapse = " to ")), "\n\n")

analysis_df <- cohort_clean %>%
  left_join(demo_clean,       by = "CURR_CLINIC") %>%
  left_join(ob_clean,         by = "CURR_CLINIC") %>%
  left_join(exposure_df %>%
              select(-delv_date),                       by = "CURR_CLINIC") %>%
  left_join(height_summary,   by = "CURR_CLINIC") %>%
  left_join(sbp_summary,      by = "CURR_CLINIC") %>%
  left_join(dbp_summary,      by = "CURR_CLINIC") %>%
  left_join(weight_summary,   by = "CURR_CLINIC") %>%
  left_join(events_df %>%
              select(-glp1_postpartum_exposed, -index_date),
                              by = "CURR_CLINIC") %>%
  left_join(comorbidities,    by = "CURR_CLINIC") %>%
  left_join(labs_wide,        by = "CURR_CLINIC") %>%
  left_join(smoking_clean,    by = "CURR_CLINIC") %>%
  left_join(alc_ppi_clean,    by = "CURR_CLINIC") %>%
  left_join(echo_clean,       by = "CURR_CLINIC") %>%
  left_join(meds_wide,        by = "CURR_CLINIC") %>%
  mutate(across(starts_with("cm_"),  ~ coalesce(., FALSE)),
         across(starts_with("med_"), ~ coalesce(., FALSE)),
         glp1_postpartum_exposed = coalesce(glp1_postpartum_exposed, FALSE),
         glp1_predelivery_any    = coalesce(glp1_predelivery_any, FALSE)) %>%
  # Derived: BMI at index, weight delta at 6m and 12m, BP deltas
  mutate(
    bmi_baseline   = weight_kg_baseline / ((height_cm / 100) ^ 2),
    delta_sbp_6m   = sbp_baseline - sbp_m6,
    delta_sbp_12m  = sbp_baseline - sbp_m12,
    delta_dbp_6m   = dbp_baseline - dbp_m6,
    delta_dbp_12m  = dbp_baseline - dbp_m12,
    delta_wt_6m    = weight_kg_baseline - weight_kg_m6,
    delta_wt_12m   = weight_kg_baseline - weight_kg_m12,
    pct_wt_loss_6m  = (weight_kg_baseline - weight_kg_m6)  / weight_kg_baseline * 100,
    pct_wt_loss_12m = (weight_kg_baseline - weight_kg_m12) / weight_kg_baseline * 100
  )

# =============================================================================
# 14. EXPORT
# =============================================================================
saveRDS(analysis_df, file.path(out_dir, "analysis_df.rds"))
saveRDS(vitals_long, file.path(out_dir, "vitals_long.rds"))
saveRDS(events_df,   file.path(out_dir, "events_df.rds"))

readr::write_csv(analysis_df, file.path(out_dir, "analysis_df.csv"))
readr::write_csv(vitals_long, file.path(out_dir, "vitals_long.csv"))
readr::write_csv(events_df,   file.path(out_dir, "events_df.csv"))

# Quick sanity summary
cat("\n========================================\n")
cat("FINAL ANALYSIS DATASET\n")
cat("========================================\n")
cat("Patients (rows):", nrow(analysis_df), "\n")
cat("Variables (cols):", ncol(analysis_df), "\n")
cat("Postpartum GLP-1 exposed:", sum(analysis_df$glp1_postpartum_exposed), "\n")
cat("Unexposed:", sum(!analysis_df$glp1_postpartum_exposed), "\n")
cat("With baseline SBP:", sum(!is.na(analysis_df$sbp_baseline)), "\n")
cat("With baseline weight:", sum(!is.na(analysis_df$weight_kg_baseline)), "\n")
cat("Output dir:", out_dir, "\n")

# Return invisibly
invisible(list(
  analysis_df = analysis_df,
  vitals_long = vitals_long,
  events_df   = events_df
))