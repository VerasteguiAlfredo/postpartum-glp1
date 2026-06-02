# =============================================================================
# postpartum-glp1: Build Analysis-Ready Dataset (v3 — DELIVERY-ANCHORED)
# -----------------------------------------------------------------------------
# Purpose : Build patient-level analysis dataset anchored to DELIVERY DATE,
#           per Dr. Demi's guidance:
#           - GLP-1 timing as categorical exposure (6wk-3mo / 3-6mo / >6mo)
#           - BP analysis restricted to elevated-BP patients (Stage 1 / 2)
#           - Baseline weight ≥ 42 days postpartum (with sensitivity flag)
#           - Lab extraction via keyword matching on TestDesc
#
# v3 CHANGES vs v2:
#   - NEW baseline tier: *_baseline_pp (postpartum-only, no 42-day floor).
#     Recovers the <6 weeks GLP-1 stratum (24 patients) whose primary baseline
#     was impossible by definition.
#   - NEW combined baseline: *_baseline_combined falls back from primary →
#     postpartum-only. Used for bp_stage, BMI, deltas, and Table 1.
#   - NEW _source variable indicates which tier was used per patient.
#   - Sensitivity baseline retained as tier 3 for audit/sensitivity analyses.
#
# Inputs  : `data_list` (loaded in memory)
#
# Outputs : analysis_df    — wide, one row per patient
#           vitals_long    — long-format BP/weight (delivery-anchored)
#           labs_long      — long-format key labs (delivery-anchored)
#           events_df      — time-to-event table
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

# --- Path setup ---
sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}
out_dir <- file.path(proj_root, "data_processed")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# 0. HELPERS
# =============================================================================
to_num <- function(x) suppressWarnings(as.numeric(x))
first_or_na <- function(x) if (length(x) == 0) NA_real_ else x[1]

weight_to_kg <- function(value, units) {
  v <- to_num(value); u <- tolower(trimws(units))
  dplyr::case_when(
    u %in% c("kg", "kilogram", "kilograms") ~ v,
    u %in% c("lb", "lbs", "pound", "pounds") ~ v * 0.45359237,
    u %in% c("oz", "ounce", "ounces") ~ v * 0.028349523125,
    u %in% c("g", "gram", "grams") ~ v / 1000,
    TRUE ~ NA_real_
  )
}

height_to_cm <- function(value, units) {
  v <- to_num(value); u <- tolower(trimws(units))
  dplyr::case_when(
    u %in% c("cm", "centimeter", "centimeters") ~ v,
    u %in% c("m", "meter", "meters") ~ v * 100,
    u %in% c("in", "inch", "inches") ~ v * 2.54,
    TRUE ~ NA_real_
  )
}

# Pick value closest to target date within a window
closest_within <- function(dates, values, target,
                           window_days = NULL,
                           side = c("any", "before", "after"),
                           min_days_from_ref = NULL, ref_date = NULL) {
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
  # Optional: enforce a minimum number of days from a reference date (e.g., delivery)
  if (!is.null(min_days_from_ref) && !is.null(ref_date)) {
    days_from_ref <- as.numeric(d - as.Date(ref_date))
    keep <- keep & days_from_ref >= min_days_from_ref
  }
  if (!any(keep)) return(NA_real_)
  v <- v[keep]; diff <- diff[keep]
  v[which.min(abs(diff))]
}

# Race consolidation — collapses 16 categories to clinically useful groups
consolidate_race <- function(primary, secondary1, secondary2) {
  # Build any-mention flag — if any field mentions Black/African/etc, count it
  all_race <- paste(coalesce(primary, ""),
                    coalesce(secondary1, ""),
                    coalesce(secondary2, ""), sep = "|")
  r <- toupper(all_race)
  case_when(
    str_detect(r, "BLACK|AFRICAN|CARIBBEAN")                              ~ "Black or African American",
    str_detect(r, "ASIAN|FILIPINO|CAMBODIAN|LAOTIAN|CHINESE|VIETNAMESE|HMONG") ~ "Asian",
    str_detect(r, "AMERICAN INDIAN|ALASKAN NATIVE|NATIVE AMERICAN")        ~ "American Indian/Alaska Native",
    str_detect(r, "HAWAIIAN|PACIFIC ISLANDER")                             ~ "Native Hawaiian/Pacific Islander",
    str_detect(r, "WHITE|CAUCASIAN")                                       ~ "White",
    str_detect(r, "OTHER")                                                 ~ "Other",
    str_detect(r, "CHOOSE NOT|UNKNOWN|DECLINE")                            ~ "Unknown/Declined",
    TRUE                                                                   ~ NA_character_
  )
}

# =============================================================================
# 1. VERIFY DATA IS LOADED
# =============================================================================
required_tables <- c("cohort", "demo", "ob", "bp_flow", "weight_flow",
                     "height_flow", "dx", "labs", "smoking", "alc_ppi",
                     "alc_social", "ecg", "echo_ef", "glp1_meds", "ord_meds")

missing <- required_tables[!sapply(required_tables, exists)]
if (length(missing) > 0) {
  stop("Missing datasets — please run the loader script first:\n  ",
       paste(missing, collapse = ", "))
}
cat("All required datasets found in environment.\n")

# =============================================================================
# 2. COHORT BACKBONE
# =============================================================================
cohort_clean <- cohort %>%
  filter(auth == "Y", Privacy != "Y", Test_Patient != "Y", Legal != "Y") %>%
  mutate(delv_date = as.Date(delv_date),
         Birth_Dt  = as.Date(Birth_Dt),
         Death_Dt  = as.Date(Death_Dt)) %>%
  select(CURR_CLINIC, delv_date, Birth_Dt, current_age, Gender,
         Deceased, Death_Dt, Hospice, Dismissed) %>%
  group_by(CURR_CLINIC) %>%
  arrange(delv_date, .by_group = TRUE) %>%
  slice(1) %>%
  ungroup()

cat("Cohort after auth/privacy filter:", nrow(cohort_clean), "patients\n")

# Demographics with race consolidation
demo_clean <- demo %>%
  distinct(CURR_CLINIC, .keep_all = TRUE) %>%
  mutate(race_consolidated = consolidate_race(race_primary,
                                              race_secondary_race1,
                                              race_secondary_race2),
         ethnicity_consolidated = case_when(
           str_detect(Ethnicity_Name, regex("hispanic|latino|mexican|puerto rican|south american|central american|spanish", ignore_case = TRUE)) &
             !str_detect(Ethnicity_Name, regex("not hispanic", ignore_case = TRUE)) ~ "Hispanic or Latino",
           str_detect(Ethnicity_Name, regex("not hispanic", ignore_case = TRUE))    ~ "Not Hispanic or Latino",
           TRUE                                                                      ~ "Unknown/Declined"
         )) %>%
  select(CURR_CLINIC, race_consolidated, ethnicity_consolidated,
         race_primary_raw = race_primary, ethnicity_raw = Ethnicity_Name)

# OB
ob_clean <- ob %>%
  mutate(DELIVERY_DTM = as.Date(DELIVERY_DTM)) %>%
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
         GESTATIONAL_AGE_IN_WEEKS, DELIVERY_MODALITY, DELIVERY_COMPLICATIONS,
         GRAVIDITY, PARITY, MULTIPLE_BIRTHS,
         PREGRAVID_BMI, LAST_MATERNAL_BMI,
         pregravid_weight_kg, last_maternal_weight_kg, birth_weight_kg,
         NUMBER_OF_PRENATAL_VISITS, INFERTILITY_TREATMENT,
         PRIOR_CESAREAN_YN, LABOR_ATTEMPT_YN, APGAR_1, APGAR_5)

# =============================================================================
# 3. GLP-1 EXPOSURE — TIMING AS CATEGORICAL VARIABLE
# =============================================================================
glp1_clean <- glp1_meds %>%
  mutate(Order_Start_Date = as.Date(Order_Start_Date),
         Order_Date       = as.Date(Order_Date),
         glp1_start       = coalesce(Order_Start_Date, Order_Date)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(cohort_clean %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(!is.na(delv_date), !is.na(glp1_start)) %>%
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

# Postpartum GLP-1 (start ≥ delivery date)
# Cap absurd stop dates (e.g., 9999-12-31 placeholders or data entry errors)
# at start + 5 years (1825 days). Anything beyond that is treated as missing,
# which then triggers the "no stop date recorded" path below.
glp1_postpartum_raw <- glp1_clean %>%
  filter(glp1_start >= delv_date) %>%
  mutate(Order_Stop_Date_raw = as.Date(Order_Stop_Date),
         # Sanity-cap implausible stop dates
         Order_Stop_Date     = if_else(
           !is.na(Order_Stop_Date_raw) &
             (Order_Stop_Date_raw > (glp1_start + 1825) |
              Order_Stop_Date_raw > as.Date("2030-01-01")),
           NA_Date_,
           Order_Stop_Date_raw
         ),
         # If no stop date, use the order start (treated as a point exposure)
         glp1_end_effective = coalesce(Order_Stop_Date, glp1_start))

# Diagnostic: how many orders had implausible stop dates capped?
n_capped <- sum(!is.na(glp1_postpartum_raw$Order_Stop_Date_raw) &
                is.na(glp1_postpartum_raw$Order_Stop_Date))
if (n_capped > 0) {
  cat("Note:", n_capped, "GLP-1 orders had implausible stop dates capped",
      "(>5y after start or post-2030 — likely placeholder values).\n")
}

glp1_postpartum <- glp1_postpartum_raw %>%
  group_by(CURR_CLINIC) %>%
  arrange(glp1_start, .by_group = TRUE) %>%
  summarise(
    glp1_index_date         = first(glp1_start),
    glp1_first_drug         = first(drug_name),
    glp1_first_brand_wl     = first(is_weightloss_brand),
    glp1_n_orders_pp        = n(),
    glp1_n_distinct_drugs   = n_distinct(drug_name),
    glp1_drugs_all          = paste(sort(unique(drug_name)), collapse = "|"),
    days_pp_to_glp1         = as.numeric(first(glp1_start) - first(delv_date)),
    # Last exposure date = latest stop OR latest start if no stops recorded
    glp1_last_date          = suppressWarnings(max(glp1_end_effective, na.rm = TRUE)),
    # Has any explicit stop date?
    glp1_has_stop_date      = any(!is.na(Order_Stop_Date)),
    .groups = "drop"
  ) %>%
  mutate(
    glp1_last_date    = as.Date(ifelse(is.infinite(glp1_last_date),
                                       NA, glp1_last_date), origin = "1970-01-01"),
    # Duration from first start to last end (in days)
    glp1_duration_days = as.numeric(glp1_last_date - glp1_index_date),
    # If no stop dates ever recorded, mark duration as uncertain (could be ongoing)
    glp1_duration_days = ifelse(glp1_duration_days < 0, NA, glp1_duration_days)
  ) %>%
  # GLP-1 timing categorical per Dr. Demi (42 / 90 / 180 day cuts)
  mutate(glp1_timing_cat = case_when(
    days_pp_to_glp1 <  42                              ~ "< 6 weeks",
    days_pp_to_glp1 >= 42  & days_pp_to_glp1 < 90      ~ "6wk-3mo",
    days_pp_to_glp1 >= 90  & days_pp_to_glp1 < 180     ~ "3-6mo",
    days_pp_to_glp1 >= 180                             ~ "> 6mo",
    TRUE                                               ~ NA_character_
  ),
  glp1_timing_cat = factor(glp1_timing_cat,
                           levels = c("< 6 weeks", "6wk-3mo", "3-6mo", "> 6mo")),
  # GLP-1 timing 2-level (per Dr. Hurtado): collapses to early / late at 6 months
  # for primary analyses where small-cell stability is a concern. The 4-level
  # version remains available for sensitivity analyses.
  glp1_timing_2cat = case_when(
    days_pp_to_glp1 <  180                             ~ "Early (< 6 months)",
    days_pp_to_glp1 >= 180                             ~ "Late (>= 6 months)",
    TRUE                                               ~ NA_character_
  ),
  glp1_timing_2cat = factor(glp1_timing_2cat,
                            levels = c("Early (< 6 months)", "Late (>= 6 months)")),
  # Persistence categorical (proxy for treatment duration)
  glp1_persistence_cat = case_when(
    is.na(glp1_duration_days)             ~ "Unknown",
    glp1_duration_days <  30              ~ "< 1 month",
    glp1_duration_days >= 30  & glp1_duration_days < 90  ~ "1-3 months",
    glp1_duration_days >= 90  & glp1_duration_days < 180 ~ "3-6 months",
    glp1_duration_days >= 180 & glp1_duration_days < 365 ~ "6-12 months",
    glp1_duration_days >= 365                            ~ "≥ 12 months",
    TRUE ~ NA_character_
  ),
  glp1_persistence_cat = factor(glp1_persistence_cat,
                                levels = c("< 1 month", "1-3 months", "3-6 months",
                                           "6-12 months", "≥ 12 months", "Unknown")))

# Pre-delivery GLP-1 (for exclusion / sensitivity)
glp1_predelivery <- glp1_clean %>%
  filter(glp1_start < delv_date) %>%
  group_by(CURR_CLINIC) %>%
  summarise(glp1_predelivery_any = TRUE,
            glp1_predelivery_first = suppressWarnings(min(glp1_start, na.rm = TRUE)),
            .groups = "drop") %>%
  mutate(glp1_predelivery_first = as.Date(ifelse(is.infinite(glp1_predelivery_first),
                                                  NA, glp1_predelivery_first),
                                          origin = "1970-01-01"))

# Build exposure table — anchored to DELIVERY DATE
exposure_df <- cohort_clean %>%
  select(CURR_CLINIC, delv_date) %>%
  left_join(glp1_postpartum,  by = "CURR_CLINIC") %>%
  left_join(glp1_predelivery, by = "CURR_CLINIC") %>%
  mutate(
    glp1_postpartum_exposed = !is.na(glp1_index_date),
    glp1_predelivery_any    = coalesce(glp1_predelivery_any, FALSE),
    # *** KEY CHANGE: index_date = delv_date (delivery-anchored) ***
    index_date              = delv_date,
    # Active-at-window flags: was the patient on GLP-1 at 6mo / 12mo postpartum?
    glp1_active_at_6m_pp  = glp1_index_date <= (delv_date + 180) &
                            glp1_last_date  >= (delv_date + 180),
    glp1_active_at_12m_pp = glp1_index_date <= (delv_date + 365) &
                            glp1_last_date  >= (delv_date + 365),
    glp1_active_at_6m_pp  = coalesce(glp1_active_at_6m_pp, FALSE),
    glp1_active_at_12m_pp = coalesce(glp1_active_at_12m_pp, FALSE)
  )

# =============================================================================
# 4. VITALS — DELIVERY-ANCHORED LONGITUDINAL
# =============================================================================

# Blood pressure
bp_long <- bp_flow %>%
  filter(!is.na(Result), str_detect(Result, "^\\s*\\d+\\s*/\\s*\\d+")) %>%
  mutate(Assessment_Date = as.Date(Assessment_Date),
         sbp = to_num(str_extract(Result, "^\\s*\\d+")),
         dbp = to_num(str_extract(Result, "(?<=/)\\s*\\d+"))) %>%
  filter(!is.na(sbp), !is.na(dbp), sbp > 50, sbp < 260, dbp > 30, dbp < 180) %>%
  select(CURR_CLINIC, meas_date = Assessment_Date, sbp, dbp,
         Encounter_Nbr, Site, Site_State)

# Weight
wt_long <- weight_flow %>%
  filter(!is.na(Result), !is.na(Result_Units)) %>%
  mutate(Assessment_Date = as.Date(Assessment_Date),
         weight_kg = weight_to_kg(Result, Result_Units)) %>%
  filter(!is.na(weight_kg), weight_kg > 30, weight_kg < 350) %>%
  select(CURR_CLINIC, meas_date = Assessment_Date, weight_kg,
         Encounter_Nbr, Site, Site_State)

# Height
ht_long <- height_flow %>%
  filter(!is.na(Result), !is.na(Result_Units)) %>%
  mutate(Assessment_Date = as.Date(Assessment_Date),
         height_cm = height_to_cm(Result, Result_Units)) %>%
  filter(!is.na(height_cm), height_cm > 120, height_cm < 220)

height_summary <- ht_long %>%
  group_by(CURR_CLINIC) %>%
  summarise(height_cm = median(height_cm, na.rm = TRUE), .groups = "drop")

# Long-format vitals around delivery (delivery-anchored)
vitals_long <- bind_rows(
  bp_long %>%
    pivot_longer(c(sbp, dbp), names_to = "vital", values_to = "value") %>%
    select(CURR_CLINIC, meas_date, vital, value),
  wt_long %>%
    transmute(CURR_CLINIC, meas_date, vital = "weight_kg", value = weight_kg)
) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date, index_date,
                                    glp1_postpartum_exposed, glp1_index_date,
                                    days_pp_to_glp1, glp1_timing_cat, glp1_timing_2cat),
             by = "CURR_CLINIC") %>%
  # Keep measurements from 90d before delivery to 12mo after
  filter(meas_date >= delv_date - 90,
         meas_date <= delv_date + 365) %>%
  mutate(days_from_delivery = as.numeric(meas_date - delv_date),
         days_from_glp1     = as.numeric(meas_date - glp1_index_date),
         # Flag relative to GLP-1: pre vs post
         period_glp1 = case_when(
           is.na(glp1_index_date)     ~ NA_character_,
           meas_date <  glp1_index_date ~ "pre",
           meas_date >= glp1_index_date ~ "post"
         ))

# =============================================================================
# 5. PER-PATIENT BASELINE & POST-INDEX VITAL SUMMARIES (DELIVERY-ANCHORED)
# =============================================================================
# Per Dr. Demi:
#   - Baseline weight: ≥ 42 days postpartum, BEFORE GLP-1 start
#     (sensitivity: include all baselines, no 42-day floor)
#   - Post values at 3, 6, 12 months from DELIVERY date

# v3 baseline strategy (3 tiers + 1 combined):
#   PRIMARY  (tier 1): closest measurement that is
#                      (a) ≥42 days postpartum
#                      AND (b) before GLP-1 start
#                      AND (c) within 90 days before GLP-1
#   PP-ONLY  (tier 2): closest postpartum measurement (≥0 days pp), before GLP-1,
#                      within 90 days before GLP-1.
#                      Recovers <6 weeks GLP-1 starters with honest postpartum
#                      data (caveat: day 1-7 pp weights are fluid-inflated).
#   SENS     (tier 3): closest measurement before GLP-1 within 90 days (no
#                      postpartum-period requirement). May include pre-pregnancy.
#                      Kept for audit/sensitivity analyses only.
#   COMBINED (used for primary analyses): PRIMARY → fallback to PP-ONLY.

# Helper: per patient, compute baselines + post-delivery windows
summarise_vital_delivery_anchored <- function(df, vital_name) {
  safe_first <- function(x) if (length(x) == 0) NA else x[1]

  sub <- df %>% filter(vital == vital_name)
  if (nrow(sub) == 0) {
    return(tibble(CURR_CLINIC = numeric(0)) %>%
             mutate("{vital_name}_baseline_primary"  := numeric(0),
                    "{vital_name}_baseline_pp"       := numeric(0),
                    "{vital_name}_baseline_sens"     := numeric(0),
                    "{vital_name}_baseline_combined" := numeric(0),
                    "{vital_name}_baseline_source"   := character(0),
                    "{vital_name}_m3_pp"             := numeric(0),
                    "{vital_name}_m6_pp"             := numeric(0),
                    "{vital_name}_m12_pp"            := numeric(0),
                    "{vital_name}_n_meas_pp"         := integer(0)))
  }

  sub %>%
    group_by(CURR_CLINIC) %>%
    summarise(
      # ----- TIER 1: PRIMARY BASELINE (≥42 days postpartum, before GLP-1) -----
      baseline_primary = {
        ref_delv <- safe_first(delv_date)
        ref_glp1 <- safe_first(glp1_index_date)
        if (length(ref_glp1) == 0 || is.na(ref_glp1)) NA_real_ else
          closest_within(meas_date, value,
                         target = ref_glp1,
                         window_days = 90, side = "before",
                         min_days_from_ref = 42, ref_date = ref_delv)
      },
      # ----- TIER 2: POSTPARTUM-ONLY BASELINE (any day ≥0 pp, before GLP-1) -----
      baseline_pp = {
        ref_delv <- safe_first(delv_date)
        ref_glp1 <- safe_first(glp1_index_date)
        if (length(ref_glp1) == 0 || is.na(ref_glp1)) NA_real_ else
          closest_within(meas_date, value,
                         target = ref_glp1,
                         window_days = 90, side = "before",
                         min_days_from_ref = 0, ref_date = ref_delv)
      },
      # ----- TIER 3: SENSITIVITY BASELINE (any baseline before GLP-1) -----
      baseline_sens = {
        ref_glp1 <- safe_first(glp1_index_date)
        if (length(ref_glp1) == 0 || is.na(ref_glp1)) NA_real_ else
          closest_within(meas_date, value,
                         target = ref_glp1,
                         window_days = 90, side = "before")
      },
      # ----- FOLLOW-UP WINDOWS (anchored to DELIVERY) -----
      m3_pp  = {
        ref_delv <- safe_first(delv_date)
        if (length(ref_delv) == 0 || is.na(ref_delv)) NA_real_ else
          closest_within(meas_date, value, ref_delv + 90,
                         window_days = 30, side = "any")
      },
      m6_pp  = {
        ref_delv <- safe_first(delv_date)
        if (length(ref_delv) == 0 || is.na(ref_delv)) NA_real_ else
          closest_within(meas_date, value, ref_delv + 180,
                         window_days = 45, side = "any")
      },
      m12_pp = {
        ref_delv <- safe_first(delv_date)
        if (length(ref_delv) == 0 || is.na(ref_delv)) NA_real_ else
          closest_within(meas_date, value, ref_delv + 365,
                         window_days = 60, side = "any")
      },
      n_meas_pp = {
        ref_delv <- safe_first(delv_date)
        if (length(ref_delv) == 0 || is.na(ref_delv)) 0L else
          sum(meas_date >= ref_delv & meas_date <= ref_delv + 365)
      },
      .groups = "drop"
    ) %>%
    # ----- COMBINED BASELINE (primary → pp-only fallback) + SOURCE TAG -----
    mutate(
      baseline_combined = coalesce(baseline_primary, baseline_pp),
      baseline_source   = case_when(
        !is.na(baseline_primary) ~ "primary",
        !is.na(baseline_pp)      ~ "postpartum_fallback",
        TRUE                     ~ NA_character_
      )
    ) %>%
    rename_with(~ paste0(vital_name, "_", .x), -CURR_CLINIC)
}

sbp_summary    <- summarise_vital_delivery_anchored(vitals_long, "sbp")
dbp_summary    <- summarise_vital_delivery_anchored(vitals_long, "dbp")
weight_summary <- summarise_vital_delivery_anchored(vitals_long, "weight_kg")

# =============================================================================
# 6. BP HYPERTENSION STAGING (around delivery)
# =============================================================================
# Per ACC/AHA 2017 (which Dr. Demi referenced):
#   Stage 1: SBP 130-139 OR DBP 80-89
#   Stage 2: SBP ≥ 140 OR DBP ≥ 90
# Apply to baseline (COMBINED: primary → pp fallback) so all patients with
# any pre-GLP-1 postpartum BP measurement are stageable.

bp_staging <- sbp_summary %>%
  select(CURR_CLINIC, sbp_baseline_combined) %>%
  left_join(dbp_summary %>% select(CURR_CLINIC, dbp_baseline_combined),
            by = "CURR_CLINIC") %>%
  mutate(
    bp_stage = case_when(
      is.na(sbp_baseline_combined) & is.na(dbp_baseline_combined)            ~ NA_character_,
      sbp_baseline_combined >= 140 | dbp_baseline_combined >= 90              ~ "Stage 2",
      sbp_baseline_combined >= 130 | dbp_baseline_combined >= 80              ~ "Stage 1",
      TRUE                                                                    ~ "Normal/Elevated"
    ),
    bp_stage = factor(bp_stage,
                      levels = c("Normal/Elevated", "Stage 1", "Stage 2")),
    elevated_bp_any    = bp_stage %in% c("Stage 1", "Stage 2"),
    stage2_htn         = bp_stage == "Stage 2"
  )

# =============================================================================
# 7. TIME-TO-EVENT (anchored to delivery, looking at post-GLP-1 changes)
# =============================================================================
# Events (post GLP-1 start, vs COMBINED baseline = primary → pp fallback):
#   - SBP drop ≥ 10 mmHg
#   - DBP drop ≥ 5 mmHg
#   - Weight loss > 10%

compute_events <- function(vitals_long, vital_name, baseline_df, baseline_col, threshold_fn) {
  baselines <- baseline_df %>% select(CURR_CLINIC, baseline = all_of(baseline_col))
  vitals_long %>%
    filter(vital == vital_name, period_glp1 == "post") %>%
    inner_join(baselines, by = "CURR_CLINIC") %>%
    filter(!is.na(baseline)) %>%
    mutate(event = threshold_fn(value, baseline)) %>%
    group_by(CURR_CLINIC) %>%
    arrange(meas_date, .by_group = TRUE) %>%
    summarise(
      event_occurred  = any(event, na.rm = TRUE),
      time_to_event   = if (any(event, na.rm = TRUE))
                          min(days_from_glp1[event], na.rm = TRUE) else NA_real_,
      last_followup   = max(days_from_glp1, na.rm = TRUE),
      .groups = "drop"
    )
}

sbp_event <- compute_events(vitals_long, "sbp", sbp_summary, "sbp_baseline_combined",
                            function(v, b) (b - v) >= 10) %>%
  rename(sbp_event = event_occurred, sbp_tte = time_to_event, sbp_fu = last_followup)

dbp_event <- compute_events(vitals_long, "dbp", dbp_summary, "dbp_baseline_combined",
                            function(v, b) (b - v) >= 5) %>%
  rename(dbp_event = event_occurred, dbp_tte = time_to_event, dbp_fu = last_followup)

wt_event <- compute_events(vitals_long, "weight_kg", weight_summary, "weight_kg_baseline_combined",
                           function(v, b) ((b - v) / b) > 0.10) %>%
  rename(wt_event = event_occurred, wt_tte = time_to_event, wt_fu = last_followup)

events_df <- exposure_df %>%
  select(CURR_CLINIC, glp1_postpartum_exposed, glp1_index_date,
         days_pp_to_glp1, glp1_timing_cat, glp1_timing_2cat) %>%
  left_join(sbp_event, by = "CURR_CLINIC") %>%
  left_join(dbp_event, by = "CURR_CLINIC") %>%
  left_join(wt_event,  by = "CURR_CLINIC")

# =============================================================================
# 8. COMORBIDITIES — keyword-based, per Dr. Morales Lopez's spec
# =============================================================================
# Two groups:
#   (A) Co-morbid Cardio-Kidney-Metabolic (CKM) conditions at baseline
#       (pre-delivery, lifetime history)
#   (B) Pregnancy-related complications developed during the INDEX pregnancy
#       (window: delivery date − 280 days to delivery date + 90 days)
# -----------------------------------------------------------------------------

# Build dx_clean (pre-delivery diagnoses, lowercased Dx_Desc for matching)
dx_clean <- dx %>%
  mutate(Dx_Date       = as.Date(Dx_Date),
         Dx_Desc_lower = str_to_lower(Dx_Desc)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(!is.na(Dx_Date))

# Lifetime-history slice (anything before delivery)
dx_lifetime <- dx_clean %>% filter(Dx_Date <= delv_date)

# Index-pregnancy slice (10 months before to 3 months after delivery)
dx_indexpreg <- dx_clean %>%
  filter(Dx_Date >= (delv_date - 280),
         Dx_Date <= (delv_date + 90))

# -----------------------------------------------------------------------------
# Helper: flag patients whose Dx_Desc_lower matches ANY keyword.
# `word_boundary_terms` are wrapped with \b to prevent substring false positives.
# -----------------------------------------------------------------------------
kw_flag <- function(df, patterns, label, word_boundary_terms = NULL) {
  base_terms <- setdiff(patterns, word_boundary_terms)
  base_re   <- if (length(base_terms))           paste(base_terms, collapse = "|") else NA_character_
  wb_re     <- if (length(word_boundary_terms))  paste(paste0("\\b", word_boundary_terms, "\\b"), collapse = "|") else NA_character_
  full_re   <- paste(na.omit(c(base_re, wb_re)), collapse = "|")
  df %>%
    filter(str_detect(Dx_Desc_lower, regex(full_re, ignore_case = TRUE))) %>%
    distinct(CURR_CLINIC) %>%
    mutate(!!label := TRUE)
}

# =============================================================================
# (A) CKM CONDITIONS AT BASELINE  ←  search dx_lifetime
# =============================================================================

ckm_afib_flutter <- kw_flag(
  dx_lifetime,
  c("atrial fibrillation", "atrial flutter"),
  "ckm_afib_flutter"
)

ckm_svt <- kw_flag(
  dx_lifetime,
  c("supraventricular tachycardia",
    "paroxysmal supraventricular tachycardia"),
  "ckm_svt",
  word_boundary_terms = c("svt", "psvt")
)

ckm_hfpef <- kw_flag(
  dx_lifetime,
  c("heart failure with preserved ejection fraction",
    "preserved ejection fraction heart failure",
    # Mayo strings include parenthetical "(congestive)"
    "diastolic.*heart failure",
    "diastolic .*congestive.*heart failure",
    "diastolic congestive heart failure",
    "diastolic heart failure"),
  "ckm_hfpef",
  word_boundary_terms = c("hfpef")
)

ckm_hfref <- kw_flag(
  dx_lifetime,
  c("heart failure with reduced ejection fraction",
    "reduced ejection fraction heart failure",
    # Mayo strings: "Acute on chronic systolic (congestive) heart failure",
    # "Chronic Systolic (Congestive) Heart Failure"
    "systolic.*heart failure",
    "systolic .*congestive.*heart failure",
    "systolic congestive heart failure",
    "dilated cardiomyopathy"),
  "ckm_hfref",
  word_boundary_terms = c("hfref", "hfmref")
)

# Hypertension: lifetime (essential or pre-existing), excludes pure gestational
ckm_htn <- kw_flag(
  dx_lifetime,
  c("essential hypertension",
    "hypertension essential",
    "pre-existing essential hypertension",
    "pre-existing hypertension",
    "pregnancy preexisting hypertension",
    "hypertensive heart disease",
    "secondary hypertension"),
  "ckm_htn"
)

ckm_cad <- kw_flag(
  dx_lifetime,
  c("coronary artery disease",
    "ischemic heart disease",
    "atherosclerotic heart disease",
    "myocardial infarction",
    "angina pectoris"),
  "ckm_cad",
  word_boundary_terms = c("cad")
)

# CKD Stage 3A or higher (Stage 3, 3a, 3b, 4, 5, ESRD)
ckm_ckd_3plus <- kw_flag(
  dx_lifetime,
  c("chronic kidney disease, stage 3",
    "chronic kidney disease, stage 4",
    "chronic kidney disease, stage 5",
    "chronic kidney disease stage 3",
    "chronic kidney disease stage 4",
    "chronic kidney disease stage 5",
    "ckd stage 3", "ckd stage 4", "ckd stage 5",
    "end stage renal disease", "end-stage renal disease",
    "kidney failure"),
  "ckm_ckd_3plus",
  word_boundary_terms = c("esrd")
)

ckm_t1dm <- kw_flag(
  dx_lifetime,
  c("type 1 diabetes",
    "diabetes mellitus type 1",
    "type i diabetes",
    "diabetes mellitus type i"),
  "ckm_t1dm"
)

ckm_t2dm <- kw_flag(
  dx_lifetime,
  c("type 2 diabetes",
    "diabetes mellitus type 2",
    "type ii diabetes",
    "diabetes mellitus type ii",
    "pre-existing type 2 diabetes",
    "pre existing type 2 diabetes",
    "pre-existing diabetes mellitus type 2",
    "pre existing diabetes mellitus type 2"),
  "ckm_t2dm"
)

ckm_dyslipidemia <- kw_flag(
  dx_lifetime,
  c("hyperlipidemia", "dyslipidemia",
    "mixed hyperlipidemia",
    "hypercholesterolemia",
    "hypertriglyceridemia"),
  "ckm_dyslipidemia"
)

ckm_prediabetes <- kw_flag(
  dx_lifetime,
  c("prediabetes", "pre-diabetes", "pre diabetes",
    "impaired fasting glucose", "impaired glucose tolerance",
    "abnormal glucose"),
  "ckm_prediabetes"
)

ckm_cabg_hx <- kw_flag(
  dx_lifetime,
  # Match "bypass" preceded by "coronary" / "artery" / "cardiac", NOT "gastric"/"intestinal"
  c("coronary artery bypass",
    "coronary bypass",
    "history of coronary artery bypass",
    "personal history of coronary artery bypass"),
  "ckm_cabg_hx",
  word_boundary_terms = c("cabg")
)

ckm_pci_stent_hx <- kw_flag(
  dx_lifetime,
  c("coronary stent", "percutaneous coronary intervention",
    "coronary angioplasty",
    "history of stent", "presence of coronary stent",
    "presence of coronary angioplasty implant"),
  "ckm_pci_stent_hx",
  word_boundary_terms = c("pci")
)

ckm_stroke_tia_hx <- kw_flag(
  dx_lifetime,
  c("stroke",
    "cerebral infarction",
    "cerebrovascular accident",
    "transient ischemic attack",
    "history of stroke",
    "history of transient ischemic attack"),
  "ckm_stroke_tia_hx",
  word_boundary_terms = c("tia", "cva")
)

# Obesity ≥ BMI 30 — captures all obesity dx including morbid + BMI codes
ckm_obesity <- kw_flag(
  dx_lifetime,
  c("obesity",
    "morbid \\(severe\\) obesity",
    "body mass index 30",
    "body mass index 35",
    "body mass index 40",
    "body mass index 45",
    "body mass index 50",
    "body mass index 55",
    "body mass index 60",
    "bmi 30", "bmi 35", "bmi 40", "bmi 45", "bmi 50", "bmi 55", "bmi 60",
    "bmi >= 30", "bmi >= 35", "bmi >= 40"),
  "ckm_obesity"
)

ckm_pad <- kw_flag(
  dx_lifetime,
  c("peripheral arterial disease",
    "peripheral vascular disease",
    "peripheral artery disease"),
  "ckm_pad",
  word_boundary_terms = c("pad", "pvd")
)

ckm_cardiac_device <- kw_flag(
  dx_lifetime,
  c("pacemaker",
    "implantable cardioverter defibrillator",
    "implantable defibrillator",
    "cardiac resynchronization",
    "biventricular pacing",
    "presence of cardiac pacemaker",
    "presence of automatic.*defibrillator"),
  "ckm_cardiac_device",
  word_boundary_terms = c("icd", "crt", "crt-d", "crt-p")
)

ckm_vt_sustained <- kw_flag(
  dx_lifetime,
  c("ventricular tachycardia",
    "sustained ventricular tachycardia"),
  "ckm_vt_sustained"
)

ckm_osa <- kw_flag(
  dx_lifetime,
  c("obstructive sleep apnea",
    "sleep apnea, obstructive"),
  "ckm_osa",
  word_boundary_terms = c("osa")
)

# =============================================================================
# (B) PREGNANCY-RELATED COMPLICATIONS  ←  search dx_indexpreg
# =============================================================================

# Note: "Hypertension" here means any HTN diagnosed during the index pregnancy
# (essential or gestational). This mirrors Dr. Morales Lopez's "1. Hypertension"
# in the pregnancy complications list.
preg_htn_any <- kw_flag(
  dx_indexpreg,
  c("hypertension"),
  "preg_htn_any"
)

preg_htn_gestational <- kw_flag(
  dx_indexpreg,
  c("gestational hypertension",
    "pregnancy-induced hypertension",
    "hypertension gestational"),
  "preg_htn_gestational"
)

preg_preeclampsia <- dx_indexpreg %>%
  # Match (pre-)eclampsia diagnoses, but EXCLUDE those that are postpartum/puerperium
  # (those are captured by preg_postpartum_preec to avoid double-counting)
  filter(str_detect(Dx_Desc_lower,
                    regex("preeclampsia|pre-eclampsia|pre eclampsia", ignore_case = TRUE)),
         !str_detect(Dx_Desc_lower,
                    regex("postpartum|puerperium|post-partum", ignore_case = TRUE))) %>%
  distinct(CURR_CLINIC) %>%
  mutate(preg_preeclampsia = TRUE)

preg_eclampsia <- kw_flag(
  dx_indexpreg,
  # Match "eclampsia" but NOT preceded by "pre"/"pre-"/"pre " (i.e., true eclampsia only)
  c("(?<!pre)(?<!pre-)(?<!pre )eclampsia"),
  "preg_eclampsia"
)

preg_postpartum_preec <- kw_flag(
  dx_indexpreg,
  # Mayo strings: "pre-eclampsia complicating the puerperium",
  # "Preeclampsia Severe Postpartum", "Preeclampsia Postpartum (HCC)",
  # "pre-existing hypertension with pre-eclampsia, complicating the puerperium"
  c("preeclampsia.*postpartum",
    "preeclampsia.*puerperium",
    "pre-eclampsia.*postpartum",
    "pre-eclampsia.*puerperium",
    "pre eclampsia.*postpartum",
    "pre eclampsia.*puerperium",
    "postpartum.*preeclampsia",
    "postpartum.*pre-eclampsia",
    "postpartum preeclampsia",
    "post-partum preeclampsia",
    "postpartum eclampsia",
    "post-partum eclampsia"),
  "preg_postpartum_preec"
)

preg_gdm <- kw_flag(
  dx_indexpreg,
  c("gestational diabetes"),
  "preg_gdm",
  word_boundary_terms = c("gdm")
)

preg_sga <- kw_flag(
  dx_indexpreg,
  c("small for gestational age",
    "small-for-gestational-age",
    "newborn affected by slow intrauterine growth"),
  "preg_sga",
  word_boundary_terms = c("sga")
)

preg_iugr <- kw_flag(
  dx_indexpreg,
  # Mayo strings: "Retardation Fetal Growth", "Maternal care for ... poor fetal growth ...",
  # "intrauterine growth restriction/retardation", "fetal growth restriction/retardation",
  # "Personal History Intrauterine Growth Restriction"
  c("intrauterine growth restriction",
    "intrauterine growth retardation",
    "fetal growth restriction",
    "fetal growth retardation",
    "retardation fetal growth",
    "poor fetal growth",
    "slow intrauterine growth",
    "slow fetal growth"),
  "preg_iugr",
  word_boundary_terms = c("iugr")
)

preg_abruption <- kw_flag(
  dx_indexpreg,
  c("placental abruption",
    "abruptio placentae",
    "premature separation of placenta"),
  "preg_abruption"
)

preg_peripartum_cm <- kw_flag(
  dx_indexpreg,
  c("peripartum cardiomyopathy",
    "postpartum cardiomyopathy"),
  "preg_peripartum_cm"
)

# =============================================================================
# COMBINE ALL FLAGS
# =============================================================================
ckm_flags <- list(
  ckm_afib_flutter, ckm_svt,
  ckm_hfpef, ckm_hfref,
  ckm_htn, ckm_cad,
  ckm_ckd_3plus,
  ckm_t1dm, ckm_t2dm,
  ckm_dyslipidemia, ckm_prediabetes,
  ckm_cabg_hx, ckm_pci_stent_hx, ckm_stroke_tia_hx,
  ckm_obesity, ckm_pad,
  ckm_cardiac_device, ckm_vt_sustained,
  ckm_osa
) %>% reduce(full_join, by = "CURR_CLINIC")

preg_flags <- list(
  preg_htn_any, preg_htn_gestational,
  preg_preeclampsia, preg_eclampsia, preg_postpartum_preec,
  preg_gdm,
  preg_sga, preg_iugr,
  preg_abruption, preg_peripartum_cm
) %>% reduce(full_join, by = "CURR_CLINIC")

comorbidities <- ckm_flags %>%
  full_join(preg_flags, by = "CURR_CLINIC") %>%
  mutate(across(c(starts_with("ckm_"), starts_with("preg_")), ~ coalesce(., FALSE))) %>%
  # Composite / summary flags
  mutate(
    ckm_any_dm                = ckm_t1dm | ckm_t2dm,
    ckm_any_hf                = ckm_hfpef | ckm_hfref,
    ckm_any_revasc_hx         = ckm_cabg_hx | ckm_pci_stent_hx,
    ckm_any_arrhythmia        = ckm_afib_flutter | ckm_svt | ckm_vt_sustained,
    ckm_count_conditions      = ckm_afib_flutter + ckm_svt + ckm_hfpef + ckm_hfref +
                                 ckm_htn + ckm_cad + ckm_ckd_3plus + ckm_t1dm + ckm_t2dm +
                                 ckm_dyslipidemia + ckm_prediabetes + ckm_cabg_hx +
                                 ckm_pci_stent_hx + ckm_stroke_tia_hx + ckm_obesity +
                                 ckm_pad + ckm_cardiac_device + ckm_vt_sustained + ckm_osa,
    # Composite: any preeclampsia spectrum disorder (mutually exclusive children)
    preg_preec_any_spectrum   = preg_preeclampsia | preg_postpartum_preec | preg_eclampsia,
    preg_count_complications  = preg_htn_any + preg_htn_gestational + preg_preeclampsia +
                                 preg_eclampsia + preg_postpartum_preec + preg_gdm +
                                 preg_sga + preg_iugr + preg_abruption + preg_peripartum_cm
  )

# Print prevalence preview
cat("\n--- CKM Condition Prevalence (lifetime, pre-delivery) ---\n")
ckm_preview <- comorbidities %>%
  summarise(across(starts_with("ckm_"), ~ sum(., na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "condition", values_to = "n") %>%
  mutate(pct = round(100 * n / nrow(cohort_clean), 1)) %>%
  filter(!str_detect(condition, "count|any")) %>%
  arrange(desc(n))
print(ckm_preview, n = Inf)

cat("\n--- Pregnancy Complication Prevalence (index pregnancy) ---\n")
preg_preview <- comorbidities %>%
  summarise(across(starts_with("preg_"), ~ sum(., na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "complication", values_to = "n") %>%
  mutate(pct = round(100 * n / nrow(cohort_clean), 1)) %>%
  filter(!str_detect(complication, "count")) %>%
  arrange(desc(n))
print(preg_preview, n = Inf)
cat("\n")

# =============================================================================
# 9. LABS — keyword-based extraction per Alf's lab strategy
# =============================================================================
# Standardize TestDesc (uppercase, trimmed) and apply keyword matchers
# across the 6 domains: glycemic, renal, hepatic, lipid, inflammation, coag.

labs_std <- labs %>%
  mutate(
    Lab_Date         = as.Date(Lab_Date),
    Resultn          = to_num(Resultn),
    TestDesc_UP      = toupper(trimws(TestDesc)),
    Lab_Panel_Desc_UP= toupper(trimws(Lab_Panel_Desc)),
    Lab_Subtype_UP   = toupper(trimws(Lab_Subtype))
  )

# Keyword maps (matched against TestDesc, fallback to Panel/Subtype)
lab_keymap <- list(
  hba1c    = "A1C|HEMOGLOBIN A1C|GLYCATED HEMOGLOBIN|GLYCATED HGB",
  glucose  = "\\bGLUCOSE\\b|FASTING GLUCOSE|2 HR GLUCOSE|OGTT|GLUCOSE TOLERANCE",
  creat    = "CREATININE",
  egfr     = "EGFR|ESTIMATED GFR|GFR",
  alb_creat= "ALBUMIN/CREATININE|MICROALBUMIN|URINE ALBUMIN|PROTEIN/CREATININE",
  alt      = "\\bALT\\b|ALANINE AMINOTRANSFERASE",
  ast      = "\\bAST\\b|ASPARTATE AMINOTRANSFERASE",
  albumin  = "\\bALBUMIN\\b(?!.*CREATININE)",  # ALBUMIN but not urine ACR
  bilirubin= "BILIRUBIN",
  ldl      = "\\bLDL\\b|LDL CHOLESTEROL|LDL-C|LDL, CALC",
  hdl      = "\\bHDL\\b|HDL CHOLESTEROL|HDL-C",
  tc       = "CHOLESTEROL, TOTAL|TOTAL CHOLESTEROL|CHOLESTEROL TOTAL",
  trig     = "TRIGLYCERIDE",
  non_hdl  = "NON-HDL|NON HDL",
  crp      = "C-REACTIVE PROTEIN|\\bCRP\\b|HIGH SENSITIVITY CRP|HS-CRP"
)

# Match a lab using all three text fields, return logical
match_lab <- function(df, pattern) {
  str_detect(df$TestDesc_UP,       regex(pattern, ignore_case = TRUE)) |
  str_detect(df$Lab_Panel_Desc_UP, regex(pattern, ignore_case = TRUE)) |
  str_detect(df$Lab_Subtype_UP,    regex(pattern, ignore_case = TRUE))
}

# Build long-format lab dataset with all matched labs flagged
labs_long_all <- labs_std %>%
  mutate(across(everything(), ~ replace(., is.na(.), NA))) %>%   # ensure NA-safety
  mutate(
    lab_domain = case_when(
      match_lab(., lab_keymap$hba1c)     ~ "hba1c",
      match_lab(., lab_keymap$glucose)   ~ "glucose",
      match_lab(., lab_keymap$creat)     ~ "creat",
      match_lab(., lab_keymap$egfr)      ~ "egfr",
      match_lab(., lab_keymap$alb_creat) ~ "alb_creat_ratio",
      match_lab(., lab_keymap$alt)       ~ "alt",
      match_lab(., lab_keymap$ast)       ~ "ast",
      match_lab(., lab_keymap$albumin)   ~ "albumin",
      match_lab(., lab_keymap$bilirubin) ~ "bilirubin",
      match_lab(., lab_keymap$ldl)       ~ "ldl",
      match_lab(., lab_keymap$hdl)       ~ "hdl",
      match_lab(., lab_keymap$tc)        ~ "tc",
      match_lab(., lab_keymap$trig)      ~ "trig",
      match_lab(., lab_keymap$non_hdl)   ~ "non_hdl",
      match_lab(., lab_keymap$crp)       ~ "crp",
      TRUE                               ~ NA_character_
    )
  ) %>%
  filter(!is.na(lab_domain)) %>%
  select(CURR_CLINIC, Lab_Date, lab_domain, TestDesc, Resultn, Resultc, Units, Encounter_Nbr)

cat("Lab matches by domain:\n")
print(labs_long_all %>% count(lab_domain, sort = TRUE))

# Pivot: per patient, closest pre-delivery (baseline) and best post-delivery (within 6mo) value
labs_long <- labs_long_all %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date, glp1_index_date),
             by = "CURR_CLINIC",
             relationship = "many-to-many") %>%
  filter(!is.na(Resultn)) %>%
  mutate(days_from_delivery = as.numeric(Lab_Date - delv_date),
         days_from_glp1     = as.numeric(Lab_Date - glp1_index_date))

# Build per-patient lab summary: baseline (pre-GLP-1), post (post-GLP-1 within 12mo)
summarise_lab <- function(df, dom) {
  # Helper: safe first() that returns NA for zero-length input
  safe_first <- function(x) if (length(x) == 0) NA else x[1]
  # Helper: safe ref-check that handles zero-length inputs
  safe_ref_check <- function(ref) {
    length(ref) == 0 || is.na(ref)
  }

  sub <- df %>% filter(lab_domain == dom)
  # If no rows match this domain at all, return an empty stub with the right columns
  if (nrow(sub) == 0) {
    return(tibble(CURR_CLINIC = numeric(0)) %>%
             mutate("lab_{dom}_baseline" := numeric(0),
                    "lab_{dom}_post_3m"  := numeric(0),
                    "lab_{dom}_post_6m"  := numeric(0),
                    "lab_{dom}_post_12m" := numeric(0)))
  }

  sub %>%
    group_by(CURR_CLINIC) %>%
    summarise(
      baseline = {
        ref <- safe_first(glp1_index_date)
        if (safe_ref_check(ref)) NA_real_ else
          closest_within(Lab_Date, Resultn, target = ref,
                         window_days = 365, side = "before")
      },
      post_3m  = {
        ref <- safe_first(glp1_index_date)
        if (safe_ref_check(ref)) NA_real_ else
          closest_within(Lab_Date, Resultn, target = ref + 90,
                         window_days = 45, side = "any")
      },
      post_6m  = {
        ref <- safe_first(glp1_index_date)
        if (safe_ref_check(ref)) NA_real_ else
          closest_within(Lab_Date, Resultn, target = ref + 180,
                         window_days = 60, side = "any")
      },
      post_12m = {
        ref <- safe_first(glp1_index_date)
        if (safe_ref_check(ref)) NA_real_ else
          closest_within(Lab_Date, Resultn, target = ref + 365,
                         window_days = 90, side = "any")
      },
      .groups = "drop"
    ) %>%
    rename_with(~ paste0("lab_", dom, "_", .x), -CURR_CLINIC)
}

lab_domains_of_interest <- c("hba1c", "glucose", "creat", "egfr",
                             "alt", "ast", "albumin",
                             "ldl", "hdl", "tc", "trig", "non_hdl", "crp")

labs_wide <- purrr::map(lab_domains_of_interest, ~ summarise_lab(labs_long, .x)) %>%
  reduce(full_join, by = "CURR_CLINIC")

# =============================================================================
# 10. SMOKING — two anchors: pre-pregnancy (true PMH) and pre-delivery
# =============================================================================
# CLINICAL ISSUE: Patients typically quit/reduce smoking during pregnancy.
# A "current smoker" status taken just before delivery underestimates true PMH.
# Solution: capture the most recent status BEFORE pregnancy started
# (delv_date - 280 days), which reflects true habits before pregnancy
# motivated abstinence. Also keep the pre-delivery anchor for reference.

# Step 1: build the smoking table with one row per patient/date
smoking_long <- smoking %>%
  mutate(tob_dt = as.Date(tob_dt)) %>%
  filter(tob_name == "SMOKING_STATUS_SUMMARY", !is.na(tob_value)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one")

# Helper: map raw values to clean categories
map_smoking <- function(x) {
  case_when(
    str_detect(x, regex("never", ignore_case = TRUE))                            ~ "Never",
    str_detect(x, regex("former|quit|ex-?smoker", ignore_case = TRUE))           ~ "Former",
    str_detect(x, regex("current|every day|some days|daily|^yes$", ignore_case = TRUE)) ~ "Current",
    str_detect(x, regex("^no$", ignore_case = TRUE))                             ~ "Never",
    str_detect(x, regex("never assessed|unknown|declined", ignore_case = TRUE))  ~ "Unknown",
    TRUE                                                                          ~ "Unknown"
  )
}

# Pre-pregnancy anchor: most recent status BEFORE pregnancy started
smoking_pre_preg <- smoking_long %>%
  filter(tob_dt <= (delv_date - 280)) %>%
  group_by(CURR_CLINIC) %>%
  arrange(desc(tob_dt), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(CURR_CLINIC,
            smoking_status_pre_preg = factor(map_smoking(tob_value),
                                             levels = c("Never","Former","Current","Unknown")),
            smoking_status_pre_preg_raw  = tob_value,
            smoking_status_pre_preg_date = tob_dt)

# Pre-delivery anchor: most recent status before delivery (legacy variable name)
smoking_pre_delv <- smoking_long %>%
  filter(tob_dt <= delv_date) %>%
  group_by(CURR_CLINIC) %>%
  arrange(desc(tob_dt), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(CURR_CLINIC,
            smoking_status_pre_delv = factor(map_smoking(tob_value),
                                             levels = c("Never","Former","Current","Unknown")),
            smoking_status_pre_delv_raw  = tob_value,
            smoking_status_pre_delv_date = tob_dt)

# Combine, with preferred "smoking_status" = pre-pregnancy if available, else pre-delivery
smoking_clean <- smoking_pre_preg %>%
  full_join(smoking_pre_delv, by = "CURR_CLINIC") %>%
  mutate(
    # Primary smoking variable: prefer pre-pregnancy (true PMH)
    smoking_status = coalesce(smoking_status_pre_preg, smoking_status_pre_delv),
    smoking_ever   = smoking_status %in% c("Former", "Current")
  )

# =============================================================================
# 11. ALCOHOL — two anchors: pre-pregnancy (true PMH) and pre-delivery
# =============================================================================
# CLINICAL ISSUE: Patients typically stop alcohol during pregnancy. A status
# recorded just before delivery will under-capture PMH alcohol use.
# Solution: capture most recent status BEFORE pregnancy started (delv_date - 280
# days), reflecting baseline habits. Keep pre-delivery anchor for transparency.

# Helper: map raw alcohol social-hx value to clean categories
map_alcohol <- function(x) {
  case_when(
    str_detect(x, regex("^yes$|currently",       ignore_case = TRUE)) ~ "Current",
    str_detect(x, regex("not currently|former|quit", ignore_case = TRUE)) ~ "Former",
    str_detect(x, regex("^no$|never",            ignore_case = TRUE)) ~ "Never",
    TRUE                                                              ~ "Unknown"
  )
}

# ---- AUDIT-C (PPI questionnaire) ----
alc_ppi_long <- alc_ppi %>%
  mutate(Ans_Dt    = as.Date(Ans_Dt),
         Ans_Value = to_num(Ans_Value)) %>%
  # AUDIT-C items each score 0-4; anything outside that range is invalid
  mutate(Ans_Value = ifelse(Ans_Value < 0 | Ans_Value > 4, NA_real_, Ans_Value)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one")

summarise_auditc <- function(df) {
  df %>%
    group_by(CURR_CLINIC) %>%
    arrange(desc(Ans_Dt), .by_group = TRUE) %>%
    summarise(
      audit_frequency = first_or_na(Ans_Value[str_detect(Question_Text,
                          regex("how often do you have a drink", ignore_case = TRUE))]),
      audit_quantity  = first_or_na(Ans_Value[str_detect(Question_Text,
                          regex("how many drinks",               ignore_case = TRUE))]),
      audit_binge     = first_or_na(Ans_Value[str_detect(Question_Text,
                          regex("six or more",                   ignore_case = TRUE))]),
      .groups = "drop"
    ) %>%
    mutate(audit_c_score = ifelse(is.na(audit_frequency) & is.na(audit_quantity) & is.na(audit_binge),
                                  NA_real_,
                                  rowSums(across(c(audit_frequency, audit_quantity, audit_binge)),
                                          na.rm = TRUE)),
           audit_c_at_risk = ifelse(is.na(audit_c_score), NA, audit_c_score >= 3))
}

# Pre-pregnancy AUDIT-C
auditc_pre_preg <- alc_ppi_long %>%
  filter(Ans_Dt <= (delv_date - 280)) %>%
  summarise_auditc() %>%
  rename_with(~ paste0(.x, "_pre_preg"), -CURR_CLINIC)

# Pre-delivery AUDIT-C
auditc_pre_delv <- alc_ppi_long %>%
  filter(Ans_Dt <= delv_date) %>%
  summarise_auditc() %>%
  rename_with(~ paste0(.x, "_pre_delv"), -CURR_CLINIC)

# ---- Social-history alcohol-use status ----
alc_social_long <- alc_social %>%
  mutate(Social_Hx_DTM = as.Date(Social_Hx_DTM)) %>%
  filter(Social_Hx_Name_Abbr == "ALCOHOL_USE_C", !is.na(Social_Hx_Answer)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one")

# Pre-pregnancy alcohol use status
alc_status_pre_preg <- alc_social_long %>%
  filter(Social_Hx_DTM <= (delv_date - 280)) %>%
  group_by(CURR_CLINIC) %>%
  arrange(desc(Social_Hx_DTM), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(CURR_CLINIC,
            alc_use_status_pre_preg = factor(map_alcohol(Social_Hx_Answer),
                                             levels = c("Never","Former","Current","Unknown")),
            alc_social_pre_preg_raw = Social_Hx_Answer)

# Pre-delivery alcohol use status
alc_status_pre_delv <- alc_social_long %>%
  filter(Social_Hx_DTM <= delv_date) %>%
  group_by(CURR_CLINIC) %>%
  arrange(desc(Social_Hx_DTM), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(CURR_CLINIC,
            alc_use_status_pre_delv = factor(map_alcohol(Social_Hx_Answer),
                                             levels = c("Never","Former","Current","Unknown")),
            alc_social_pre_delv_raw = Social_Hx_Answer)

# ---- Combine: prefer pre-pregnancy values for primary PMH variables ----
alc_combined <- auditc_pre_preg %>%
  full_join(auditc_pre_delv,        by = "CURR_CLINIC") %>%
  full_join(alc_status_pre_preg,    by = "CURR_CLINIC") %>%
  full_join(alc_status_pre_delv,    by = "CURR_CLINIC") %>%
  mutate(
    # Primary alcohol use status: prefer pre-pregnancy (true PMH)
    alc_use_status = coalesce(alc_use_status_pre_preg, alc_use_status_pre_delv),
    # Primary AUDIT-C score: prefer pre-pregnancy
    audit_c_score   = coalesce(audit_c_score_pre_preg,   audit_c_score_pre_delv),
    audit_c_at_risk = coalesce(audit_c_at_risk_pre_preg, audit_c_at_risk_pre_delv),
    # Binary current-use (using primary status)
    alc_current_use = case_when(
      alc_use_status == "Current"                     ~ TRUE,
      alc_use_status %in% c("Never","Former")         ~ FALSE,
      !is.na(audit_c_score) & audit_c_score >= 1      ~ TRUE,
      !is.na(audit_c_score) & audit_c_score == 0      ~ FALSE,
      TRUE                                            ~ NA
    )
  )

# =============================================================================
# 12. ECHO / EF (most recent pre-delivery)
# =============================================================================
echo_clean <- echo_ef %>%
  rename(CURR_CLINIC = curr_clinic) %>%
  mutate(procedure_date = as.Date(procedure_date), ef = to_num(ef)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(procedure_date <= delv_date, !is.na(ef)) %>%
  group_by(CURR_CLINIC) %>%
  arrange(desc(procedure_date), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(CURR_CLINIC, echo_ef = ef, echo_date = procedure_date, echo_bsa = bsa)

# =============================================================================
# 12b. ECG QUANTITATIVE PARAMETERS (most recent pre-delivery)
# =============================================================================
# Extract HR, PR, QRS duration, QT, QTC, QTF from the most recent ECG before
# delivery. Use the row with non-missing numeric values per patient/ECG.

ecg_clean <- ecg %>%
  mutate(ECG_Date     = as.Date(ECG_Date),
         Heart_Rate   = to_num(Heart_Rate),
         PR_Interval  = to_num(PR_Interval),
         QRS_Duration = to_num(QRS_Duration),
         QT_Interval  = to_num(QT_Interval),
         QTC          = to_num(QTC),
         QTF          = to_num(QTF)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(!is.na(ECG_Date), ECG_Date <= delv_date) %>%
  # For each ECG_Date, collapse to a single row using the maximum non-NA value
  # per parameter (handles multiple sequence rows per ECG)
  group_by(CURR_CLINIC, ECG_Date) %>%
  summarise(
    ecg_hr           = suppressWarnings(max(Heart_Rate,   na.rm = TRUE)),
    ecg_pr_interval  = suppressWarnings(max(PR_Interval,  na.rm = TRUE)),
    ecg_qrs_duration = suppressWarnings(max(QRS_Duration, na.rm = TRUE)),
    ecg_qt_interval  = suppressWarnings(max(QT_Interval,  na.rm = TRUE)),
    ecg_qtc          = suppressWarnings(max(QTC,          na.rm = TRUE)),
    ecg_qtf          = suppressWarnings(max(QTF,          na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  # Replace -Inf (no non-NA values) with NA
  mutate(across(starts_with("ecg_"), ~ ifelse(is.infinite(.), NA_real_, .))) %>%
  # Keep most recent ECG per patient
  group_by(CURR_CLINIC) %>%
  arrange(desc(ECG_Date), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  rename(ecg_date = ECG_Date)

cat("ECG quantitative data captured for", nrow(ecg_clean), "patients\n")

# =============================================================================
# 13. CONCOMITANT MEDICATIONS (active near delivery)
# =============================================================================
ord_meds_clean <- ord_meds %>%
  mutate(Order_Start_Date = as.Date(Order_Start_Date),
         Order_Stop_Date  = as.Date(Order_Stop_Date)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(Order_Start_Date <= delv_date,
         is.na(Order_Stop_Date) | Order_Stop_Date >= (delv_date - 30))

med_class_flag <- function(df, pattern, label) {
  df %>%
    filter(str_detect(Order_Name, regex(pattern, ignore_case = TRUE)) |
           str_detect(Med_Generic, regex(pattern, ignore_case = TRUE))) %>%
    distinct(CURR_CLINIC) %>%
    mutate(!!label := TRUE)
}

meds_wide <- list(
  med_class_flag(ord_meds_clean, "metformin",                                       "med_metformin"),
  med_class_flag(ord_meds_clean, "insulin",                                         "med_insulin"),
  med_class_flag(ord_meds_clean, "empagliflozin|dapagliflozin|canagliflozin|ertugliflozin", "med_sglt2"),
  med_class_flag(ord_meds_clean, "lisinopril|enalapril|ramipril|captopril|benazepril",      "med_acei"),
  med_class_flag(ord_meds_clean, "losartan|valsartan|olmesartan|telmisartan|irbesartan|candesartan", "med_arb"),
  med_class_flag(ord_meds_clean, "metoprolol|atenolol|carvedilol|bisoprolol|propranolol|labetalol|nebivolol", "med_betablocker"),
  med_class_flag(ord_meds_clean, "amlodipine|nifedipine|diltiazem|verapamil|felodipine",                      "med_ccb"),
  med_class_flag(ord_meds_clean, "hydrochlorothiazide|hctz|furosemide|spironolactone|chlorthalidone|bumetanide", "med_diuretic"),
  med_class_flag(ord_meds_clean, "atorvastatin|simvastatin|rosuvastatin|pravastatin|lovastatin|pitavastatin", "med_statin")
) %>%
  reduce(full_join, by = "CURR_CLINIC") %>%
  mutate(across(starts_with("med_"), ~ coalesce(., FALSE)))

# =============================================================================
# 14. ASSEMBLE FINAL ANALYSIS DATA FRAME
# =============================================================================
cat("\n--- Pre-assembly diagnostics ---\n")
cat("Cohort patients:                ", nrow(cohort_clean), "\n")
cat("Postpartum GLP-1 exposed:       ", sum(exposure_df$glp1_postpartum_exposed), "\n")
cat("Pre-delivery GLP-1 exposed:     ", sum(exposure_df$glp1_predelivery_any), "\n\n")

cat("GLP-1 timing distribution:\n")
print(table(exposure_df$glp1_timing_cat, useNA = "ifany"))
cat("\n")
cat("GLP-1 timing 2-level (primary analysis grouping):\n")
print(table(exposure_df$glp1_timing_2cat, useNA = "ifany"))
cat("\n")

cat("GLP-1 persistence distribution:\n")
print(table(exposure_df$glp1_persistence_cat, useNA = "ifany"))
cat("\n")

cat("Active GLP-1 at follow-up windows:\n")
cat("  Active at 6m postpartum:  ", sum(exposure_df$glp1_active_at_6m_pp), "\n")
cat("  Active at 12m postpartum: ", sum(exposure_df$glp1_active_at_12m_pp), "\n\n")

cat("Drug switches (n_distinct_drugs):\n")
print(table(exposure_df$glp1_n_distinct_drugs, useNA = "ifany"))
cat("\n")

# Baseline tier coverage (v3) — quantify the recovery from new pp tier
cat("--- Baseline tier coverage (v3) ---\n")
baseline_coverage <- tibble(
  vital              = c("SBP", "DBP", "Weight"),
  has_primary        = c(sum(!is.na(sbp_summary$sbp_baseline_primary)),
                         sum(!is.na(dbp_summary$dbp_baseline_primary)),
                         sum(!is.na(weight_summary$weight_kg_baseline_primary))),
  has_pp_only        = c(sum(!is.na(sbp_summary$sbp_baseline_pp)),
                         sum(!is.na(dbp_summary$dbp_baseline_pp)),
                         sum(!is.na(weight_summary$weight_kg_baseline_pp))),
  has_combined       = c(sum(!is.na(sbp_summary$sbp_baseline_combined)),
                         sum(!is.na(dbp_summary$dbp_baseline_combined)),
                         sum(!is.na(weight_summary$weight_kg_baseline_combined))),
  has_sens           = c(sum(!is.na(sbp_summary$sbp_baseline_sens)),
                         sum(!is.na(dbp_summary$dbp_baseline_sens)),
                         sum(!is.na(weight_summary$weight_kg_baseline_sens)))
)
print(baseline_coverage)
cat("\n")

cat("Baseline source breakdown (combined = primary -> pp fallback):\n")
print(sbp_summary    %>% count(sbp_baseline_source,       name = "n_sbp"))
print(dbp_summary    %>% count(dbp_baseline_source,       name = "n_dbp"))
print(weight_summary %>% count(weight_kg_baseline_source, name = "n_weight"))
cat("\n")

# Source breakdown stratified by GLP-1 timing (shows which strata used fallback)
cat("Baseline source by GLP-1 timing stratum (weight):\n")
print(
  weight_summary %>%
    inner_join(exposure_df %>% select(CURR_CLINIC, glp1_timing_cat),
               by = "CURR_CLINIC") %>%
    count(glp1_timing_cat, weight_kg_baseline_source) %>%
    tidyr::pivot_wider(names_from = weight_kg_baseline_source,
                       values_from = n, values_fill = 0)
)
cat("\n")

# Compare pre-pregnancy vs pre-delivery smoking/alcohol (PMH integrity check)
cat("--- Smoking: pre-pregnancy vs pre-delivery anchor ---\n")
cat("Pre-pregnancy:\n")
print(table(smoking_clean$smoking_status_pre_preg, useNA = "ifany"))
cat("Pre-delivery (legacy):\n")
print(table(smoking_clean$smoking_status_pre_delv, useNA = "ifany"))
cat("Primary smoking_status (prefers pre-pregnancy):\n")
print(table(smoking_clean$smoking_status, useNA = "ifany"))

cat("\n--- Alcohol: pre-pregnancy vs pre-delivery anchor ---\n")
cat("Pre-pregnancy:\n")
print(table(alc_combined$alc_use_status_pre_preg, useNA = "ifany"))
cat("Pre-delivery (legacy):\n")
print(table(alc_combined$alc_use_status_pre_delv, useNA = "ifany"))
cat("Primary alc_use_status (prefers pre-pregnancy):\n")
print(table(alc_combined$alc_use_status, useNA = "ifany"))
cat("\n")

analysis_df <- cohort_clean %>%
  left_join(demo_clean,       by = "CURR_CLINIC") %>%
  left_join(ob_clean,         by = "CURR_CLINIC") %>%
  left_join(exposure_df %>% select(-delv_date),       by = "CURR_CLINIC") %>%
  left_join(height_summary,   by = "CURR_CLINIC") %>%
  left_join(sbp_summary,      by = "CURR_CLINIC") %>%
  left_join(dbp_summary,      by = "CURR_CLINIC") %>%
  left_join(weight_summary,   by = "CURR_CLINIC") %>%
  left_join(bp_staging %>% select(CURR_CLINIC, bp_stage, elevated_bp_any, stage2_htn),
                              by = "CURR_CLINIC") %>%
  left_join(events_df %>%
              select(-glp1_postpartum_exposed, -glp1_index_date,
                     -days_pp_to_glp1, -glp1_timing_cat, -glp1_timing_2cat),
                              by = "CURR_CLINIC") %>%
  left_join(comorbidities,    by = "CURR_CLINIC") %>%
  left_join(labs_wide,        by = "CURR_CLINIC") %>%
  left_join(smoking_clean,    by = "CURR_CLINIC") %>%
  left_join(alc_combined,     by = "CURR_CLINIC") %>%
  left_join(echo_clean,       by = "CURR_CLINIC") %>%
  left_join(ecg_clean,        by = "CURR_CLINIC") %>%
  left_join(meds_wide,        by = "CURR_CLINIC") %>%
  mutate(
    across(starts_with("ckm_"),  ~ if (is.logical(.)) coalesce(., FALSE) else .),
    across(starts_with("preg_"), ~ if (is.logical(.)) coalesce(., FALSE) else .),
    across(starts_with("med_"),  ~ coalesce(., FALSE)),
    glp1_postpartum_exposed = coalesce(glp1_postpartum_exposed, FALSE),
    glp1_predelivery_any    = coalesce(glp1_predelivery_any, FALSE),
    # Derived BMI from each baseline tier
    bmi_baseline_primary  = weight_kg_baseline_primary  / ((height_cm / 100) ^ 2),
    bmi_baseline_pp       = weight_kg_baseline_pp       / ((height_cm / 100) ^ 2),
    bmi_baseline_sens     = weight_kg_baseline_sens     / ((height_cm / 100) ^ 2),
    bmi_baseline_combined = weight_kg_baseline_combined / ((height_cm / 100) ^ 2),
    # Deltas using COMBINED baseline (primary → pp fallback). Used for
    # primary analyses and Table 1. Keep _primary versions for reference.
    delta_sbp_pp6m_primary   = sbp_baseline_primary        - sbp_m6_pp,
    delta_sbp_pp12m_primary  = sbp_baseline_primary        - sbp_m12_pp,
    delta_dbp_pp6m_primary   = dbp_baseline_primary        - dbp_m6_pp,
    delta_dbp_pp12m_primary  = dbp_baseline_primary        - dbp_m12_pp,
    delta_wt_pp6m_primary    = weight_kg_baseline_primary  - weight_kg_m6_pp,
    delta_wt_pp12m_primary   = weight_kg_baseline_primary  - weight_kg_m12_pp,
    pct_wt_loss_pp6m_primary  = (weight_kg_baseline_primary  - weight_kg_m6_pp)  / weight_kg_baseline_primary  * 100,
    pct_wt_loss_pp12m_primary = (weight_kg_baseline_primary  - weight_kg_m12_pp) / weight_kg_baseline_primary  * 100,
    # PRIMARY ANALYSIS deltas — use COMBINED baseline
    delta_sbp_pp6m   = sbp_baseline_combined       - sbp_m6_pp,
    delta_sbp_pp12m  = sbp_baseline_combined       - sbp_m12_pp,
    delta_dbp_pp6m   = dbp_baseline_combined       - dbp_m6_pp,
    delta_dbp_pp12m  = dbp_baseline_combined       - dbp_m12_pp,
    delta_wt_pp6m    = weight_kg_baseline_combined - weight_kg_m6_pp,
    delta_wt_pp12m   = weight_kg_baseline_combined - weight_kg_m12_pp,
    pct_wt_loss_pp6m  = (weight_kg_baseline_combined - weight_kg_m6_pp)  / weight_kg_baseline_combined * 100,
    pct_wt_loss_pp12m = (weight_kg_baseline_combined - weight_kg_m12_pp) / weight_kg_baseline_combined * 100,
    # Lab deltas (HbA1c, lipids)
    delta_hba1c_6m    = lab_hba1c_baseline   - lab_hba1c_post_6m,
    delta_hba1c_12m   = lab_hba1c_baseline   - lab_hba1c_post_12m,
    delta_tc_6m       = lab_tc_baseline      - lab_tc_post_6m,
    delta_ldl_6m      = lab_ldl_baseline     - lab_ldl_post_6m,
    delta_trig_6m     = lab_trig_baseline    - lab_trig_post_6m
  )

# =============================================================================
# 15. EXPORT
# =============================================================================
saveRDS(analysis_df, file.path(out_dir, "analysis_df.rds"))
saveRDS(vitals_long, file.path(out_dir, "vitals_long.rds"))
saveRDS(labs_long,   file.path(out_dir, "labs_long.rds"))
saveRDS(events_df,   file.path(out_dir, "events_df.rds"))

readr::write_csv(analysis_df, file.path(out_dir, "analysis_df.csv"))
readr::write_csv(vitals_long, file.path(out_dir, "vitals_long.csv"))
readr::write_csv(labs_long,   file.path(out_dir, "labs_long.csv"))
readr::write_csv(events_df,   file.path(out_dir, "events_df.csv"))

cat("\n========================================\n")
cat("FINAL ANALYSIS DATASET (v3 — delivery-anchored)\n")
cat("========================================\n")
cat("Patients (rows):           ", nrow(analysis_df), "\n")
cat("Variables (cols):          ", ncol(analysis_df), "\n")
cat("GLP-1 exposed:             ", sum(analysis_df$glp1_postpartum_exposed), "\n")
cat("\n")
cat("Baseline SBP coverage:\n")
cat("  primary (>=42d pp):      ", sum(!is.na(analysis_df$sbp_baseline_primary)), "\n")
cat("  pp-only (>=0d pp):       ", sum(!is.na(analysis_df$sbp_baseline_pp)), "\n")
cat("  combined (used for analysis):", sum(!is.na(analysis_df$sbp_baseline_combined)), "\n")
cat("  sensitivity (audit only):", sum(!is.na(analysis_df$sbp_baseline_sens)), "\n")
cat("\nBaseline Weight coverage:\n")
cat("  primary (>=42d pp):      ", sum(!is.na(analysis_df$weight_kg_baseline_primary)), "\n")
cat("  pp-only (>=0d pp):       ", sum(!is.na(analysis_df$weight_kg_baseline_pp)), "\n")
cat("  combined (used for analysis):", sum(!is.na(analysis_df$weight_kg_baseline_combined)), "\n")
cat("  sensitivity (audit only):", sum(!is.na(analysis_df$weight_kg_baseline_sens)), "\n")
cat("\n")
cat("Stage 1+ HTN at baseline:  ", sum(analysis_df$elevated_bp_any, na.rm = TRUE), "\n")
cat("Stage 2 HTN at baseline:   ", sum(analysis_df$stage2_htn,      na.rm = TRUE), "\n")
cat("Output dir:                ", out_dir, "\n")

invisible(list(
  analysis_df = analysis_df,
  vitals_long = vitals_long,
  labs_long   = labs_long,
  events_df   = events_df
))