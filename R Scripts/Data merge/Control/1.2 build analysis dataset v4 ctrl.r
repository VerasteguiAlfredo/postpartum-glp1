# =============================================================================
# postpartum-glp1: Build Analysis-Ready Dataset (v4 — CONTROLS)
# -----------------------------------------------------------------------------
# Purpose : Build patient-level analysis dataset for the CONTROL group, parallel
#           to the treatment-group v3 script, so the two can be row-bound and
#           fed into propensity score matching (PSM) with an identical schema.
#
# INPUTS  : the *_controls tibbles already loaded in .GlobalEnv by the loader:
#           cohort_controls, demo_controls, ob_controls, bp_controls,
#           bmi_controls, hr_controls, height_controls, dx_controls,
#           labs_controls, alc_ppi_controls, alc_social_controls, echo_ef_controls
#
# OUTPUTS : analysis_df_controls  — wide, one row per patient
#           vitals_long_controls  — long-format BP/weight (delivery-anchored)
#           labs_long_controls    — long-format key labs (delivery-anchored)
#           events_df_controls    — provisional time-to-event table
#
# -----------------------------------------------------------------------------
# CONTROL-SPECIFIC DECISIONS (review with Dr. Demi before PSM):
#   (1) No GLP-1 exposure. Section 3 is replaced by a control stub:
#       treatment_group = "Control", index_date = delv_date, and all glp1_*
#       columns are set to NA / FALSE so the schema aligns with treatment.
#   (2) Baselines are DELIVERY-ANCHORED (there is no drug-start date):
#         primary  = closest measurement 42–132 d postpartum
#         pp       = closest measurement 0–90 d postpartum (fallback)
#         combined = primary -> pp fallback (used for staging, BMI, deltas)
#       Follow-up windows (m3/m6/m12) are delivery-anchored, same as treatment.
#   (3) events_df TTE uses a PROVISIONAL delivery clock. The real per-control
#       pseudo-index should be assigned AFTER PSM from the matched treated
#       patient's days_pp_to_glp1. Treat control TTE here as provisional.
#   (4) Tables not extracted for controls (ecg, ord_meds) produce all-NA/FALSE
#       columns. They CANNOT be PSM matching variables unless sourced later.
#
# STRUCTURAL DIFFERENCES vs treatment v3:
#   - weight: no weight_controls file. Derive weight_kg from BMI x height^2
#             (or use raw weight rows if bmi_controls happens to carry them).
#   - smoking: no smoking_controls file. Attempt recovery from
#              alc_social_controls social-history codes; else set to Unknown.
#   - keyword matching (dx, labs) runs on UNIQUE description strings, then maps
#     back to patients — the key speedup for 8.85M dx / 6.5M lab rows.
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
  library(tibble)
})

# --- Path setup (matches project convention) ---------------------------------
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
  if (!is.null(min_days_from_ref) && !is.null(ref_date)) {
    days_from_ref <- as.numeric(d - as.Date(ref_date))
    keep <- keep & days_from_ref >= min_days_from_ref
  }
  if (!any(keep)) return(NA_real_)
  v <- v[keep]; diff <- diff[keep]
  v[which.min(abs(diff))]
}

consolidate_race <- function(primary, secondary1, secondary2) {
  all_race <- paste(coalesce(primary, ""),
                    coalesce(secondary1, ""),
                    coalesce(secondary2, ""), sep = "|")
  r <- toupper(all_race)
  case_when(
    str_detect(r, "BLACK|AFRICAN|CARIBBEAN")                                    ~ "Black or African American",
    str_detect(r, "ASIAN|FILIPINO|CAMBODIAN|LAOTIAN|CHINESE|VIETNAMESE|HMONG")  ~ "Asian",
    str_detect(r, "AMERICAN INDIAN|ALASKAN NATIVE|NATIVE AMERICAN")             ~ "American Indian/Alaska Native",
    str_detect(r, "HAWAIIAN|PACIFIC ISLANDER")                                  ~ "Native Hawaiian/Pacific Islander",
    str_detect(r, "WHITE|CAUCASIAN")                                            ~ "White",
    str_detect(r, "OTHER")                                                      ~ "Other",
    str_detect(r, "CHOOSE NOT|UNKNOWN|DECLINE")                                 ~ "Unknown/Declined",
    TRUE                                                                        ~ NA_character_
  )
}

# --- Fast keyword flag over UNIQUE description strings, then map to patients --
# desc_lookup : data.table with columns (CURR_CLINIC, desc)  [desc already lower]
# unique_desc : character vector of unique desc values
# Returns tibble(CURR_CLINIC, <label> = TRUE) for matched patients only.
kw_flag_fast <- function(desc_lookup, unique_desc, patterns, label,
                         word_boundary_terms = NULL) {
  base_terms <- setdiff(patterns, word_boundary_terms)
  base_re <- if (length(base_terms))          paste(base_terms, collapse = "|") else NA_character_
  wb_re   <- if (length(word_boundary_terms)) paste(paste0("\\b", word_boundary_terms, "\\b"), collapse = "|") else NA_character_
  full_re <- paste(stats::na.omit(c(base_re, wb_re)), collapse = "|")
  hit_desc <- unique_desc[str_detect(unique_desc, regex(full_re, ignore_case = TRUE))]
  if (!length(hit_desc)) {
    return(tibble(CURR_CLINIC = numeric(0)) %>% mutate(!!label := logical(0)))
  }
  pts <- unique(desc_lookup[desc %chin% hit_desc, CURR_CLINIC])
  tibble(CURR_CLINIC = pts) %>% mutate(!!label := TRUE)
}

# =============================================================================
# 1. VERIFY / MAP LOADED CONTROL TABLES
# =============================================================================
required_controls <- c("cohort_controls", "demo_controls", "ob_controls",
                       "bp_controls", "bmi_controls", "hr_controls",
                       "height_controls", "dx_controls", "labs_controls",
                       "alc_ppi_controls", "alc_social_controls",
                       "echo_ef_controls")
missing_req <- required_controls[!sapply(required_controls, exists)]
if (length(missing_req) > 0) {
  stop("Missing required control datasets — run the loader first:\n  ",
       paste(missing_req, collapse = ", "))
}
cat("All required control datasets found.\n")

# Map _controls names to the generic names used in the v3 body (keeps the
# analysis logic identical and reduces transcription error).
cohort   <- cohort_controls
demo     <- demo_controls
ob       <- ob_controls
bp_flow  <- bp_controls
bmi_flow <- bmi_controls
hr_flow  <- hr_controls
height_flow <- height_controls
dx       <- dx_controls
labs     <- labs_controls
alc_ppi  <- alc_ppi_controls
alc_social <- alc_social_controls
echo_ef  <- echo_ef_controls

# Optional tables (may not exist for controls) — detect gracefully
have_smoking  <- exists("smoking_controls")
have_ecg      <- exists("ecg_controls")
have_ord_meds <- exists("ord_meds_controls")
cat(sprintf("Optional tables — smoking:%s  ecg:%s  ord_meds:%s\n",
            have_smoking, have_ecg, have_ord_meds))

# =============================================================================
# 1b. STRUCTURE PROBES (auto-detect weight & smoking sources; PRINT findings)
# =============================================================================
cat("\n=== PROBE: bmi_controls content (BMI vs raw weight rows) ===\n")
bmi_probe <- bmi_flow %>%
  mutate(u = tolower(trimws(Result_Units))) %>%
  count(Assessment_Name, Result_Units, sort = TRUE) %>%
  head(15)
print(bmi_probe)

# Does bmi_controls carry raw weight rows (kg/lb/oz units) or only BMI?
bmi_units <- tolower(trimws(unique(bmi_flow$Result_Units)))
has_raw_weight_rows <- any(bmi_units %in%
  c("kg","kilogram","kilograms","lb","lbs","pound","pounds","oz","ounce","ounces","g","gram","grams"))
cat("Raw weight-unit rows present in bmi_controls:", has_raw_weight_rows, "\n")

cat("\n=== PROBE: alc_social_controls social-history codes (smoking hunt) ===\n")
soc_codes <- alc_social %>%
  count(Social_Hx_Name_Abbr, Social_Hx_NAME, sort = TRUE) %>%
  head(25)
print(soc_codes)
smoking_abbr <- alc_social %>%
  filter(str_detect(Social_Hx_Name_Abbr, regex("smok|tobac|cigar", ignore_case = TRUE)) |
         str_detect(Social_Hx_NAME,      regex("smok|tobac|cigar", ignore_case = TRUE))) %>%
  distinct(Social_Hx_Name_Abbr) %>% pull(Social_Hx_Name_Abbr)
cat("Smoking-like social-hx abbrs found:",
    if (length(smoking_abbr)) paste(smoking_abbr, collapse=", ") else "(none)", "\n")

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
  slice(1) %>%                       # earliest delivery per patient (== v3)
  ungroup()

cat("\nCohort after auth/privacy filter:", nrow(cohort_clean), "patients\n")

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
# 3. CONTROL EXPOSURE STUB  (replaces treatment GLP-1 section)
# =============================================================================
# Controls have no GLP-1. We build an exposure_df with the SAME columns the
# rest of the pipeline references, so downstream code (and later row-binding
# with the treatment analysis_df) sees an identical schema.
exposure_df <- cohort_clean %>%
  select(CURR_CLINIC, delv_date) %>%
  mutate(
    treatment_group          = "Control",
    glp1_postpartum_exposed  = FALSE,
    glp1_predelivery_any     = FALSE,
    glp1_index_date          = as.Date(NA),
    glp1_first_drug          = NA_character_,
    glp1_first_brand_wl      = NA,
    glp1_n_orders_pp         = 0L,
    glp1_n_distinct_drugs    = 0L,
    glp1_drugs_all           = NA_character_,
    days_pp_to_glp1          = NA_real_,
    glp1_last_date           = as.Date(NA),
    glp1_has_stop_date       = NA,
    glp1_duration_days       = NA_real_,
    glp1_timing_cat          = factor(NA, levels = c("< 6 weeks","6wk-3mo","3-6mo","> 6mo")),
    glp1_timing_2cat         = factor(NA, levels = c("Early (< 6 months)","Late (>= 6 months)")),
    glp1_persistence_cat     = factor(NA, levels = c("< 1 month","1-3 months","3-6 months",
                                                     "6-12 months","≥ 12 months","Unknown")),
    # index_date = delivery date (delivery-anchored, same convention as v3)
    index_date               = delv_date,
    glp1_active_at_6m_pp     = FALSE,
    glp1_active_at_12m_pp    = FALSE
  )

# =============================================================================
# 4. VITALS — DELIVERY-ANCHORED LONGITUDINAL
# =============================================================================

# ---- Blood pressure (bp_controls: Result = "SBP/DBP" string) ----
bp_long <- bp_flow %>%
  filter(!is.na(Result), str_detect(Result, "^\\s*\\d+\\s*/\\s*\\d+")) %>%
  mutate(Assessment_Date = as.Date(Assessment_Date),
         sbp = to_num(str_extract(Result, "^\\s*\\d+")),
         dbp = to_num(str_extract(Result, "(?<=/)\\s*\\d+"))) %>%
  filter(!is.na(sbp), !is.na(dbp), sbp > 50, sbp < 260, dbp > 30, dbp < 180) %>%
  select(CURR_CLINIC, meas_date = Assessment_Date, sbp, dbp,
         Encounter_Nbr, Site, Site_State)

# ---- Height (needed to derive weight from BMI) ----
ht_long <- height_flow %>%
  filter(!is.na(Result), !is.na(Result_Units)) %>%
  mutate(Assessment_Date = as.Date(Assessment_Date),
         height_cm = height_to_cm(Result, Result_Units)) %>%
  filter(!is.na(height_cm), height_cm > 120, height_cm < 220)

height_summary <- ht_long %>%
  group_by(CURR_CLINIC) %>%
  summarise(height_cm = median(height_cm, na.rm = TRUE), .groups = "drop")

# ---- Weight (controls have no weight file) ----
# Path A: if bmi_controls carries raw weight rows, use them directly.
# Path B: otherwise derive weight_kg = BMI * (height_m)^2, per measurement date,
#         using the patient's median height.
if (has_raw_weight_rows) {
  cat("\nWeight source: raw weight rows found in bmi_controls (Path A)\n")
  wt_long <- bmi_flow %>%
    filter(!is.na(Result), !is.na(Result_Units),
           tolower(trimws(Result_Units)) %in%
             c("kg","kilogram","kilograms","lb","lbs","pound","pounds",
               "oz","ounce","ounces","g","gram","grams")) %>%
    mutate(Assessment_Date = as.Date(Assessment_Date),
           weight_kg = weight_to_kg(Result, Result_Units)) %>%
    filter(!is.na(weight_kg), weight_kg > 30, weight_kg < 350) %>%
    select(CURR_CLINIC, meas_date = Assessment_Date, weight_kg,
           Encounter_Nbr, Site, Site_State)
} else {
  cat("\nWeight source: derived from BMI x height^2 (Path B)\n")
  bmi_meas <- bmi_flow %>%
    filter(!is.na(Result)) %>%
    mutate(Assessment_Date = as.Date(Assessment_Date),
           bmi_val = to_num(Result)) %>%
    filter(!is.na(bmi_val), bmi_val > 10, bmi_val < 90) %>%
    select(CURR_CLINIC, meas_date = Assessment_Date, bmi_val,
           Encounter_Nbr, Site, Site_State)
  wt_long <- bmi_meas %>%
    left_join(height_summary, by = "CURR_CLINIC") %>%
    mutate(weight_kg = bmi_val * (height_cm / 100)^2) %>%
    filter(!is.na(weight_kg), weight_kg > 30, weight_kg < 350) %>%
    select(CURR_CLINIC, meas_date, weight_kg, Encounter_Nbr, Site, Site_State)
}
cat("Weight measurements assembled:", nrow(wt_long), "rows\n")

# ---- Long-format vitals around delivery ----
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
  filter(meas_date >= delv_date - 90,
         meas_date <= delv_date + 365) %>%
  mutate(days_from_delivery = as.numeric(meas_date - delv_date),
         # controls: index = delivery, so days_from_glp1 == days_from_delivery
         days_from_glp1     = as.numeric(meas_date - delv_date),
         # period relative to delivery (index) — "post" = on/after delivery
         period_glp1 = case_when(
           meas_date <  delv_date ~ "pre",
           meas_date >= delv_date ~ "post"
         ))

# =============================================================================
# 5. PER-PATIENT BASELINE & POST-INDEX VITAL SUMMARIES (DELIVERY-ANCHORED)
# =============================================================================
# Control baseline tiers (delivery-anchored — see header decision #2):
#   PRIMARY  : closest measurement 42–132 d postpartum (target = delv+42,
#              side="after", window 90, min 42 d pp)
#   PP       : closest measurement 0–90 d postpartum (target = delv, side="after",
#              window 90, min 0 d pp)   [fallback]
#   SENS     : closest measurement within 90 d either side of delivery
#   COMBINED : PRIMARY -> PP fallback
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
      baseline_primary = {
        ref_delv <- safe_first(delv_date)
        if (length(ref_delv) == 0 || is.na(ref_delv)) NA_real_ else
          closest_within(meas_date, value, target = ref_delv + 42,
                         window_days = 90, side = "after",
                         min_days_from_ref = 42, ref_date = ref_delv)
      },
      baseline_pp = {
        ref_delv <- safe_first(delv_date)
        if (length(ref_delv) == 0 || is.na(ref_delv)) NA_real_ else
          closest_within(meas_date, value, target = ref_delv,
                         window_days = 90, side = "after",
                         min_days_from_ref = 0, ref_date = ref_delv)
      },
      baseline_sens = {
        ref_delv <- safe_first(delv_date)
        if (length(ref_delv) == 0 || is.na(ref_delv)) NA_real_ else
          closest_within(meas_date, value, target = ref_delv,
                         window_days = 90, side = "any")
      },
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
# 6. BP HYPERTENSION STAGING (ACC/AHA 2017, on COMBINED baseline)
# =============================================================================
bp_staging <- sbp_summary %>%
  select(CURR_CLINIC, sbp_baseline_combined) %>%
  left_join(dbp_summary %>% select(CURR_CLINIC, dbp_baseline_combined),
            by = "CURR_CLINIC") %>%
  mutate(
    bp_stage = case_when(
      is.na(sbp_baseline_combined) & is.na(dbp_baseline_combined) ~ NA_character_,
      sbp_baseline_combined >= 140 | dbp_baseline_combined >= 90  ~ "Stage 2",
      sbp_baseline_combined >= 130 | dbp_baseline_combined >= 80  ~ "Stage 1",
      TRUE                                                        ~ "Normal/Elevated"
    ),
    bp_stage = factor(bp_stage, levels = c("Normal/Elevated", "Stage 1", "Stage 2")),
    elevated_bp_any = bp_stage %in% c("Stage 1", "Stage 2"),
    stage2_htn      = bp_stage == "Stage 2"
  )

# =============================================================================
# 7. TIME-TO-EVENT (PROVISIONAL — delivery clock; see header decision #3)
# =============================================================================
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
      event_occurred = any(event, na.rm = TRUE),
      time_to_event  = if (any(event, na.rm = TRUE))
                         min(days_from_glp1[event], na.rm = TRUE) else NA_real_,
      last_followup  = max(days_from_glp1, na.rm = TRUE),
      .groups = "drop"
    )
}

sbp_event <- compute_events(vitals_long, "sbp", sbp_summary, "sbp_baseline_combined",
                            function(v, b) (b - v) >= 10) %>%
  rename(sbp_event = event_occurred, sbp_tte = time_to_event, sbp_fu = last_followup)
dbp_event <- compute_events(vitals_long, "dbp", dbp_summary, "dbp_baseline_combined",
                            function(v, b) (b - v) >= 5) %>%
  rename(dbp_event = event_occurred, dbp_tte = time_to_event, dbp_fu = last_followup)
wt_event  <- compute_events(vitals_long, "weight_kg", weight_summary, "weight_kg_baseline_combined",
                            function(v, b) ((b - v) / b) > 0.10) %>%
  rename(wt_event = event_occurred, wt_tte = time_to_event, wt_fu = last_followup)

events_df <- exposure_df %>%
  select(CURR_CLINIC, glp1_postpartum_exposed, glp1_index_date,
         days_pp_to_glp1, glp1_timing_cat, glp1_timing_2cat) %>%
  left_join(sbp_event, by = "CURR_CLINIC") %>%
  left_join(dbp_event, by = "CURR_CLINIC") %>%
  left_join(wt_event,  by = "CURR_CLINIC")

# =============================================================================
# 8. COMORBIDITIES — keyword-based (UNIQUE-STRING optimized for scale)
# =============================================================================
# Build a lean data.table lookup (CURR_CLINIC + lowered Dx_Desc), sliced by
# window, then match all patterns against the UNIQUE desc strings.
dx_dt <- as.data.table(dx)[, .(CURR_CLINIC,
                               Dx_Date = as.Date(Dx_Date),
                               desc    = str_to_lower(Dx_Desc))]
# attach the (deduped) delivery date
dx_dt <- merge(dx_dt,
               as.data.table(cohort_clean)[, .(CURR_CLINIC, delv_date)],
               by = "CURR_CLINIC", all.x = FALSE)
dx_dt <- dx_dt[!is.na(Dx_Date)]

dx_life  <- dx_dt[Dx_Date <= delv_date]
dx_preg  <- dx_dt[Dx_Date >= (delv_date - 280) & Dx_Date <= (delv_date + 90)]
uniq_life <- unique(dx_life$desc)
uniq_preg <- unique(dx_preg$desc)
cat("\nUnique dx descriptions — lifetime:", length(uniq_life),
    " index-preg:", length(uniq_preg), "\n")

# ---- (A) CKM conditions at baseline (dx_life) ----
ckm_afib_flutter <- kw_flag_fast(dx_life, uniq_life,
  c("atrial fibrillation","atrial flutter"), "ckm_afib_flutter")
ckm_svt <- kw_flag_fast(dx_life, uniq_life,
  c("supraventricular tachycardia","paroxysmal supraventricular tachycardia"),
  "ckm_svt", word_boundary_terms = c("svt","psvt"))
ckm_hfpef <- kw_flag_fast(dx_life, uniq_life,
  c("heart failure with preserved ejection fraction","preserved ejection fraction heart failure",
    "diastolic.*heart failure","diastolic .*congestive.*heart failure",
    "diastolic congestive heart failure","diastolic heart failure"),
  "ckm_hfpef", word_boundary_terms = c("hfpef"))
ckm_hfref <- kw_flag_fast(dx_life, uniq_life,
  c("heart failure with reduced ejection fraction","reduced ejection fraction heart failure",
    "systolic.*heart failure","systolic .*congestive.*heart failure",
    "systolic congestive heart failure","dilated cardiomyopathy"),
  "ckm_hfref", word_boundary_terms = c("hfref","hfmref"))
ckm_htn <- kw_flag_fast(dx_life, uniq_life,
  c("essential hypertension","hypertension essential","pre-existing essential hypertension",
    "pre-existing hypertension","pregnancy preexisting hypertension",
    "hypertensive heart disease","secondary hypertension"), "ckm_htn")
ckm_cad <- kw_flag_fast(dx_life, uniq_life,
  c("coronary artery disease","ischemic heart disease","atherosclerotic heart disease",
    "myocardial infarction","angina pectoris"), "ckm_cad", word_boundary_terms = c("cad"))
ckm_ckd_3plus <- kw_flag_fast(dx_life, uniq_life,
  c("chronic kidney disease, stage 3","chronic kidney disease, stage 4","chronic kidney disease, stage 5",
    "chronic kidney disease stage 3","chronic kidney disease stage 4","chronic kidney disease stage 5",
    "ckd stage 3","ckd stage 4","ckd stage 5","end stage renal disease","end-stage renal disease",
    "kidney failure"), "ckm_ckd_3plus", word_boundary_terms = c("esrd"))
ckm_t1dm <- kw_flag_fast(dx_life, uniq_life,
  c("type 1 diabetes","diabetes mellitus type 1","type i diabetes","diabetes mellitus type i"),
  "ckm_t1dm")
ckm_t2dm <- kw_flag_fast(dx_life, uniq_life,
  c("type 2 diabetes","diabetes mellitus type 2","type ii diabetes","diabetes mellitus type ii",
    "pre-existing type 2 diabetes","pre existing type 2 diabetes",
    "pre-existing diabetes mellitus type 2","pre existing diabetes mellitus type 2"), "ckm_t2dm")
ckm_dyslipidemia <- kw_flag_fast(dx_life, uniq_life,
  c("hyperlipidemia","dyslipidemia","mixed hyperlipidemia","hypercholesterolemia",
    "hypertriglyceridemia"), "ckm_dyslipidemia")
ckm_prediabetes <- kw_flag_fast(dx_life, uniq_life,
  c("prediabetes","pre-diabetes","pre diabetes","impaired fasting glucose",
    "impaired glucose tolerance","abnormal glucose"), "ckm_prediabetes")
ckm_cabg_hx <- kw_flag_fast(dx_life, uniq_life,
  c("coronary artery bypass","coronary bypass","history of coronary artery bypass",
    "personal history of coronary artery bypass"), "ckm_cabg_hx", word_boundary_terms = c("cabg"))
ckm_pci_stent_hx <- kw_flag_fast(dx_life, uniq_life,
  c("coronary stent","percutaneous coronary intervention","coronary angioplasty",
    "history of stent","presence of coronary stent","presence of coronary angioplasty implant"),
  "ckm_pci_stent_hx", word_boundary_terms = c("pci"))
ckm_stroke_tia_hx <- kw_flag_fast(dx_life, uniq_life,
  c("stroke","cerebral infarction","cerebrovascular accident","transient ischemic attack",
    "history of stroke","history of transient ischemic attack"),
  "ckm_stroke_tia_hx", word_boundary_terms = c("tia","cva"))
ckm_obesity <- kw_flag_fast(dx_life, uniq_life,
  c("obesity","morbid \\(severe\\) obesity",
    "body mass index 30","body mass index 35","body mass index 40","body mass index 45",
    "body mass index 50","body mass index 55","body mass index 60",
    "bmi 30","bmi 35","bmi 40","bmi 45","bmi 50","bmi 55","bmi 60",
    "bmi >= 30","bmi >= 35","bmi >= 40"), "ckm_obesity")
ckm_pad <- kw_flag_fast(dx_life, uniq_life,
  c("peripheral arterial disease","peripheral vascular disease","peripheral artery disease"),
  "ckm_pad", word_boundary_terms = c("pad","pvd"))
ckm_cardiac_device <- kw_flag_fast(dx_life, uniq_life,
  c("pacemaker","implantable cardioverter defibrillator","implantable defibrillator",
    "cardiac resynchronization","biventricular pacing","presence of cardiac pacemaker",
    "presence of automatic.*defibrillator"),
  "ckm_cardiac_device", word_boundary_terms = c("icd","crt","crt-d","crt-p"))
ckm_vt_sustained <- kw_flag_fast(dx_life, uniq_life,
  c("ventricular tachycardia","sustained ventricular tachycardia"), "ckm_vt_sustained")
ckm_osa <- kw_flag_fast(dx_life, uniq_life,
  c("obstructive sleep apnea","sleep apnea, obstructive"), "ckm_osa",
  word_boundary_terms = c("osa"))

# ---- (B) Pregnancy-related complications (dx_preg) ----
preg_htn_any <- kw_flag_fast(dx_preg, uniq_preg, c("hypertension"), "preg_htn_any")
preg_htn_gestational <- kw_flag_fast(dx_preg, uniq_preg,
  c("gestational hypertension","pregnancy-induced hypertension","hypertension gestational"),
  "preg_htn_gestational")
# preeclampsia: exclude postpartum/puerperium (captured separately)
preg_preec_desc <- uniq_preg[
  str_detect(uniq_preg, regex("preeclampsia|pre-eclampsia|pre eclampsia", ignore_case = TRUE)) &
  !str_detect(uniq_preg, regex("postpartum|puerperium|post-partum", ignore_case = TRUE))]
preg_preeclampsia <- tibble(
  CURR_CLINIC = unique(dx_preg[desc %chin% preg_preec_desc, CURR_CLINIC])) %>%
  mutate(preg_preeclampsia = TRUE)
preg_eclampsia <- kw_flag_fast(dx_preg, uniq_preg,
  c("(?<!pre)(?<!pre-)(?<!pre )eclampsia"), "preg_eclampsia")
preg_postpartum_preec <- kw_flag_fast(dx_preg, uniq_preg,
  c("preeclampsia.*postpartum","preeclampsia.*puerperium","pre-eclampsia.*postpartum",
    "pre-eclampsia.*puerperium","pre eclampsia.*postpartum","pre eclampsia.*puerperium",
    "postpartum.*preeclampsia","postpartum.*pre-eclampsia","postpartum preeclampsia",
    "post-partum preeclampsia","postpartum eclampsia","post-partum eclampsia"),
  "preg_postpartum_preec")
preg_gdm <- kw_flag_fast(dx_preg, uniq_preg, c("gestational diabetes"), "preg_gdm",
  word_boundary_terms = c("gdm"))
preg_sga <- kw_flag_fast(dx_preg, uniq_preg,
  c("small for gestational age","small-for-gestational-age",
    "newborn affected by slow intrauterine growth"), "preg_sga",
  word_boundary_terms = c("sga"))
preg_iugr <- kw_flag_fast(dx_preg, uniq_preg,
  c("intrauterine growth restriction","intrauterine growth retardation",
    "fetal growth restriction","fetal growth retardation","retardation fetal growth",
    "poor fetal growth","slow intrauterine growth","slow fetal growth"),
  "preg_iugr", word_boundary_terms = c("iugr"))
preg_abruption <- kw_flag_fast(dx_preg, uniq_preg,
  c("placental abruption","abruptio placentae","premature separation of placenta"),
  "preg_abruption")
preg_peripartum_cm <- kw_flag_fast(dx_preg, uniq_preg,
  c("peripartum cardiomyopathy","postpartum cardiomyopathy"), "preg_peripartum_cm")

# ---- Combine flags ----
ckm_flags <- list(
  ckm_afib_flutter, ckm_svt, ckm_hfpef, ckm_hfref, ckm_htn, ckm_cad,
  ckm_ckd_3plus, ckm_t1dm, ckm_t2dm, ckm_dyslipidemia, ckm_prediabetes,
  ckm_cabg_hx, ckm_pci_stent_hx, ckm_stroke_tia_hx, ckm_obesity, ckm_pad,
  ckm_cardiac_device, ckm_vt_sustained, ckm_osa
) %>% reduce(full_join, by = "CURR_CLINIC")

preg_flags <- list(
  preg_htn_any, preg_htn_gestational, preg_preeclampsia, preg_eclampsia,
  preg_postpartum_preec, preg_gdm, preg_sga, preg_iugr, preg_abruption,
  preg_peripartum_cm
) %>% reduce(full_join, by = "CURR_CLINIC")

comorbidities <- ckm_flags %>%
  full_join(preg_flags, by = "CURR_CLINIC") %>%
  mutate(across(c(starts_with("ckm_"), starts_with("preg_")), ~ coalesce(., FALSE))) %>%
  mutate(
    ckm_any_dm         = ckm_t1dm | ckm_t2dm,
    ckm_any_hf         = ckm_hfpef | ckm_hfref,
    ckm_any_revasc_hx  = ckm_cabg_hx | ckm_pci_stent_hx,
    ckm_any_arrhythmia = ckm_afib_flutter | ckm_svt | ckm_vt_sustained,
    ckm_count_conditions = ckm_afib_flutter + ckm_svt + ckm_hfpef + ckm_hfref +
      ckm_htn + ckm_cad + ckm_ckd_3plus + ckm_t1dm + ckm_t2dm + ckm_dyslipidemia +
      ckm_prediabetes + ckm_cabg_hx + ckm_pci_stent_hx + ckm_stroke_tia_hx +
      ckm_obesity + ckm_pad + ckm_cardiac_device + ckm_vt_sustained + ckm_osa,
    preg_preec_any_spectrum = preg_preeclampsia | preg_postpartum_preec | preg_eclampsia,
    preg_count_complications = preg_htn_any + preg_htn_gestational + preg_preeclampsia +
      preg_eclampsia + preg_postpartum_preec + preg_gdm + preg_sga + preg_iugr +
      preg_abruption + preg_peripartum_cm
  )

cat("\n--- CKM Condition Prevalence (lifetime, pre-delivery) ---\n")
print(comorbidities %>%
  summarise(across(starts_with("ckm_"), ~ sum(., na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "condition", values_to = "n") %>%
  mutate(pct = round(100 * n / nrow(cohort_clean), 1)) %>%
  filter(!str_detect(condition, "count|any")) %>% arrange(desc(n)), n = Inf)

cat("\n--- Pregnancy Complication Prevalence (index pregnancy) ---\n")
print(comorbidities %>%
  summarise(across(starts_with("preg_"), ~ sum(., na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "complication", values_to = "n") %>%
  mutate(pct = round(100 * n / nrow(cohort_clean), 1)) %>%
  filter(!str_detect(complication, "count")) %>% arrange(desc(n)), n = Inf)

rm(dx_dt, dx_life, dx_preg); gc()

# =============================================================================
# 9. LABS — keyword extraction (UNIQUE-STRING optimized)
# =============================================================================
lab_keymap <- list(
  hba1c    = "A1C|HEMOGLOBIN A1C|GLYCATED HEMOGLOBIN|GLYCATED HGB",
  glucose  = "\\bGLUCOSE\\b|FASTING GLUCOSE|2 HR GLUCOSE|OGTT|GLUCOSE TOLERANCE",
  creat    = "CREATININE",
  egfr     = "EGFR|ESTIMATED GFR|GFR",
  alb_creat= "ALBUMIN/CREATININE|MICROALBUMIN|URINE ALBUMIN|PROTEIN/CREATININE",
  alt      = "\\bALT\\b|ALANINE AMINOTRANSFERASE",
  ast      = "\\bAST\\b|ASPARTATE AMINOTRANSFERASE",
  albumin  = "\\bALBUMIN\\b(?!.*CREATININE)",
  bilirubin= "BILIRUBIN",
  ldl      = "\\bLDL\\b|LDL CHOLESTEROL|LDL-C|LDL, CALC",
  hdl      = "\\bHDL\\b|HDL CHOLESTEROL|HDL-C",
  tc       = "CHOLESTEROL, TOTAL|TOTAL CHOLESTEROL|CHOLESTEROL TOTAL",
  trig     = "TRIGLYCERIDE",
  non_hdl  = "NON-HDL|NON HDL",
  crp      = "C-REACTIVE PROTEIN|\\bCRP\\b|HIGH SENSITIVITY CRP|HS-CRP"
)
domain_order <- c("hba1c","glucose","creat","egfr","alb_creat_ratio","alt","ast",
                  "albumin","bilirubin","ldl","hdl","tc","trig","non_hdl","crp")
keymap_by_domain <- setNames(lab_keymap, c(
  "hba1c","glucose","creat","egfr","alb_creat_ratio","alt","ast","albumin",
  "bilirubin","ldl","hdl","tc","trig","non_hdl","crp"))

# Build UNIQUE (TestDesc, Panel, Subtype) combos and classify once.
labs_dt <- as.data.table(labs)[, .(
  CURR_CLINIC,
  Lab_Date = as.Date(Lab_Date),
  Resultn  = to_num(Resultn),
  Resultc, Units, Encounter_Nbr,
  td = toupper(trimws(TestDesc)),
  pd = toupper(trimws(Lab_Panel_Desc)),
  sd = toupper(trimws(Lab_Subtype)),
  TestDesc
)]
combo <- unique(labs_dt[, .(td, pd, sd)])
classify_combo <- function(td, pd, sd) {
  hit <- function(pat) {
    str_detect(td, regex(pat, ignore_case = TRUE)) |
    str_detect(pd, regex(pat, ignore_case = TRUE)) |
    str_detect(sd, regex(pat, ignore_case = TRUE))
  }
  out <- rep(NA_character_, length(td))
  for (dom in names(keymap_by_domain)) {
    idx <- is.na(out) & hit(keymap_by_domain[[dom]])
    out[idx] <- dom
  }
  out
}
combo[, lab_domain := classify_combo(td, pd, sd)]
labs_dt <- merge(labs_dt, combo, by = c("td","pd","sd"), all.x = TRUE)
labs_long_all <- as_tibble(labs_dt[!is.na(lab_domain),
  .(CURR_CLINIC, Lab_Date, lab_domain, TestDesc, Resultn, Resultc, Units, Encounter_Nbr)])

cat("\nLab matches by domain:\n")
print(labs_long_all %>% count(lab_domain, sort = TRUE))
rm(labs_dt, combo); gc()

# Attach delivery date; controls have no glp1_index_date (baseline = pre-delivery)
labs_long <- labs_long_all %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date, glp1_index_date),
             by = "CURR_CLINIC", relationship = "many-to-one") %>%
  filter(!is.na(Resultn)) %>%
  mutate(days_from_delivery = as.numeric(Lab_Date - delv_date),
         days_from_glp1     = as.numeric(Lab_Date - delv_date))  # index = delivery

# Per-patient lab summary (baseline = closest pre-delivery; post windows from delivery)
summarise_lab <- function(df, dom) {
  safe_first <- function(x) if (length(x) == 0) NA else x[1]
  sub <- df %>% filter(lab_domain == dom)
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
        ref <- safe_first(delv_date)
        if (length(ref) == 0 || is.na(ref)) NA_real_ else
          closest_within(Lab_Date, Resultn, target = ref, window_days = 365, side = "before")
      },
      post_3m = {
        ref <- safe_first(delv_date)
        if (length(ref) == 0 || is.na(ref)) NA_real_ else
          closest_within(Lab_Date, Resultn, target = ref + 90, window_days = 45, side = "any")
      },
      post_6m = {
        ref <- safe_first(delv_date)
        if (length(ref) == 0 || is.na(ref)) NA_real_ else
          closest_within(Lab_Date, Resultn, target = ref + 180, window_days = 60, side = "any")
      },
      post_12m = {
        ref <- safe_first(delv_date)
        if (length(ref) == 0 || is.na(ref)) NA_real_ else
          closest_within(Lab_Date, Resultn, target = ref + 365, window_days = 90, side = "any")
      },
      .groups = "drop"
    ) %>%
    rename_with(~ paste0("lab_", dom, "_", .x), -CURR_CLINIC)
}

lab_domains_of_interest <- c("hba1c","glucose","creat","egfr","alt","ast",
                             "albumin","ldl","hdl","tc","trig","non_hdl","crp")
labs_wide <- purrr::map(lab_domains_of_interest, ~ summarise_lab(labs_long, .x)) %>%
  reduce(full_join, by = "CURR_CLINIC")

# =============================================================================
# 10. SMOKING — recover from alc_social_controls if possible; else Unknown
# =============================================================================
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

if (length(smoking_abbr) > 0) {
  cat("\nSmoking source: recovered from alc_social_controls (",
      paste(smoking_abbr, collapse=", "), ")\n")
  smoke_src <- alc_social %>%
    mutate(dt = as.Date(Social_Hx_DTM)) %>%
    filter(Social_Hx_Name_Abbr %in% smoking_abbr, !is.na(Social_Hx_Answer)) %>%
    select(-any_of("delv_date")) %>%
    inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
               by = "CURR_CLINIC", relationship = "many-to-one")
  smoking_pre_preg <- smoke_src %>%
    filter(dt <= (delv_date - 280)) %>%
    group_by(CURR_CLINIC) %>% arrange(desc(dt), .by_group = TRUE) %>% slice(1) %>% ungroup() %>%
    transmute(CURR_CLINIC,
              smoking_status_pre_preg = factor(map_smoking(Social_Hx_Answer),
                                               levels = c("Never","Former","Current","Unknown")),
              smoking_status_pre_preg_raw = Social_Hx_Answer,
              smoking_status_pre_preg_date = dt)
  smoking_pre_delv <- smoke_src %>%
    filter(dt <= delv_date) %>%
    group_by(CURR_CLINIC) %>% arrange(desc(dt), .by_group = TRUE) %>% slice(1) %>% ungroup() %>%
    transmute(CURR_CLINIC,
              smoking_status_pre_delv = factor(map_smoking(Social_Hx_Answer),
                                               levels = c("Never","Former","Current","Unknown")),
              smoking_status_pre_delv_raw = Social_Hx_Answer,
              smoking_status_pre_delv_date = dt)
  smoking_clean <- smoking_pre_preg %>%
    full_join(smoking_pre_delv, by = "CURR_CLINIC") %>%
    mutate(smoking_status = coalesce(smoking_status_pre_preg, smoking_status_pre_delv),
           smoking_ever   = smoking_status %in% c("Former","Current"))
} else {
  cat("\nSmoking source: NONE found for controls — emitting Unknown/NA columns.\n")
  smoking_clean <- tibble(
    CURR_CLINIC = cohort_clean$CURR_CLINIC,
    smoking_status_pre_preg = factor(NA, levels = c("Never","Former","Current","Unknown")),
    smoking_status_pre_preg_raw = NA_character_,
    smoking_status_pre_preg_date = as.Date(NA),
    smoking_status_pre_delv = factor(NA, levels = c("Never","Former","Current","Unknown")),
    smoking_status_pre_delv_raw = NA_character_,
    smoking_status_pre_delv_date = as.Date(NA),
    smoking_status = factor(NA, levels = c("Never","Former","Current","Unknown")),
    smoking_ever = NA
  )
}

# =============================================================================
# 11. ALCOHOL — pre-pregnancy and pre-delivery anchors (same as treatment)
# =============================================================================
map_alcohol <- function(x) {
  case_when(
    str_detect(x, regex("^yes$|currently", ignore_case = TRUE))       ~ "Current",
    str_detect(x, regex("not currently|former|quit", ignore_case = TRUE)) ~ "Former",
    str_detect(x, regex("^no$|never", ignore_case = TRUE))            ~ "Never",
    TRUE                                                              ~ "Unknown"
  )
}

alc_ppi_long <- alc_ppi %>%
  mutate(Ans_Dt = as.Date(Ans_Dt), Ans_Value = to_num(Ans_Value)) %>%
  mutate(Ans_Value = ifelse(Ans_Value < 0 | Ans_Value > 4, NA_real_, Ans_Value)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC", relationship = "many-to-one")

summarise_auditc <- function(df) {
  df %>%
    group_by(CURR_CLINIC) %>% arrange(desc(Ans_Dt), .by_group = TRUE) %>%
    summarise(
      audit_frequency = first_or_na(Ans_Value[str_detect(Question_Text, regex("how often do you have a drink", ignore_case = TRUE))]),
      audit_quantity  = first_or_na(Ans_Value[str_detect(Question_Text, regex("how many drinks", ignore_case = TRUE))]),
      audit_binge     = first_or_na(Ans_Value[str_detect(Question_Text, regex("six or more", ignore_case = TRUE))]),
      .groups = "drop") %>%
    mutate(audit_c_score = ifelse(is.na(audit_frequency) & is.na(audit_quantity) & is.na(audit_binge),
                                  NA_real_,
                                  rowSums(across(c(audit_frequency, audit_quantity, audit_binge)), na.rm = TRUE)),
           audit_c_at_risk = ifelse(is.na(audit_c_score), NA, audit_c_score >= 3))
}

auditc_pre_preg <- alc_ppi_long %>% filter(Ans_Dt <= (delv_date - 280)) %>%
  summarise_auditc() %>% rename_with(~ paste0(.x, "_pre_preg"), -CURR_CLINIC)
auditc_pre_delv <- alc_ppi_long %>% filter(Ans_Dt <= delv_date) %>%
  summarise_auditc() %>% rename_with(~ paste0(.x, "_pre_delv"), -CURR_CLINIC)

alc_social_long <- alc_social %>%
  mutate(Social_Hx_DTM = as.Date(Social_Hx_DTM)) %>%
  filter(Social_Hx_Name_Abbr == "ALCOHOL_USE_C", !is.na(Social_Hx_Answer)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC", relationship = "many-to-one")

alc_status_pre_preg <- alc_social_long %>% filter(Social_Hx_DTM <= (delv_date - 280)) %>%
  group_by(CURR_CLINIC) %>% arrange(desc(Social_Hx_DTM), .by_group = TRUE) %>% slice(1) %>% ungroup() %>%
  transmute(CURR_CLINIC,
            alc_use_status_pre_preg = factor(map_alcohol(Social_Hx_Answer),
                                             levels = c("Never","Former","Current","Unknown")),
            alc_social_pre_preg_raw = Social_Hx_Answer)
alc_status_pre_delv <- alc_social_long %>% filter(Social_Hx_DTM <= delv_date) %>%
  group_by(CURR_CLINIC) %>% arrange(desc(Social_Hx_DTM), .by_group = TRUE) %>% slice(1) %>% ungroup() %>%
  transmute(CURR_CLINIC,
            alc_use_status_pre_delv = factor(map_alcohol(Social_Hx_Answer),
                                             levels = c("Never","Former","Current","Unknown")),
            alc_social_pre_delv_raw = Social_Hx_Answer)

alc_combined <- auditc_pre_preg %>%
  full_join(auditc_pre_delv,     by = "CURR_CLINIC") %>%
  full_join(alc_status_pre_preg, by = "CURR_CLINIC") %>%
  full_join(alc_status_pre_delv, by = "CURR_CLINIC") %>%
  mutate(
    alc_use_status  = coalesce(alc_use_status_pre_preg, alc_use_status_pre_delv),
    audit_c_score   = coalesce(audit_c_score_pre_preg,   audit_c_score_pre_delv),
    audit_c_at_risk = coalesce(audit_c_at_risk_pre_preg, audit_c_at_risk_pre_delv),
    alc_current_use = case_when(
      alc_use_status == "Current"                 ~ TRUE,
      alc_use_status %in% c("Never","Former")     ~ FALSE,
      !is.na(audit_c_score) & audit_c_score >= 1  ~ TRUE,
      !is.na(audit_c_score) & audit_c_score == 0  ~ FALSE,
      TRUE                                        ~ NA
    )
  )

# =============================================================================
# 12. ECHO / EF (most recent pre-delivery) — 4 fields only
# =============================================================================
echo_clean <- echo_ef %>%
  rename(CURR_CLINIC = curr_clinic) %>%
  mutate(procedure_date = as.Date(procedure_date), ef = to_num(ef)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC", relationship = "many-to-one") %>%
  filter(procedure_date <= delv_date, !is.na(ef)) %>%
  group_by(CURR_CLINIC) %>% arrange(desc(procedure_date), .by_group = TRUE) %>%
  slice(1) %>% ungroup() %>%
  transmute(CURR_CLINIC, echo_ef = ef, echo_date = procedure_date, echo_bsa = bsa)

# =============================================================================
# 12b. ECG — not extracted for controls → emit empty stub (schema parity)
# =============================================================================
if (have_ecg) {
  ecg_clean <- ecg_controls %>%
    mutate(ECG_Date = as.Date(ECG_Date),
           Heart_Rate = to_num(Heart_Rate), PR_Interval = to_num(PR_Interval),
           QRS_Duration = to_num(QRS_Duration), QT_Interval = to_num(QT_Interval),
           QTC = to_num(QTC), QTF = to_num(QTF)) %>%
    select(-any_of("delv_date")) %>%
    inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
               by = "CURR_CLINIC", relationship = "many-to-one") %>%
    filter(!is.na(ECG_Date), ECG_Date <= delv_date) %>%
    group_by(CURR_CLINIC, ECG_Date) %>%
    summarise(ecg_hr = suppressWarnings(max(Heart_Rate, na.rm = TRUE)),
              ecg_pr_interval = suppressWarnings(max(PR_Interval, na.rm = TRUE)),
              ecg_qrs_duration = suppressWarnings(max(QRS_Duration, na.rm = TRUE)),
              ecg_qt_interval = suppressWarnings(max(QT_Interval, na.rm = TRUE)),
              ecg_qtc = suppressWarnings(max(QTC, na.rm = TRUE)),
              ecg_qtf = suppressWarnings(max(QTF, na.rm = TRUE)), .groups = "drop") %>%
    mutate(across(starts_with("ecg_"), ~ ifelse(is.infinite(.), NA_real_, .))) %>%
    group_by(CURR_CLINIC) %>% arrange(desc(ECG_Date), .by_group = TRUE) %>%
    slice(1) %>% ungroup() %>% rename(ecg_date = ECG_Date)
} else {
  cat("ECG: not available for controls — emitting NA columns.\n")
  ecg_clean <- tibble(CURR_CLINIC = numeric(0),
    ecg_date = as.Date(character(0)),
    ecg_hr = numeric(0), ecg_pr_interval = numeric(0), ecg_qrs_duration = numeric(0),
    ecg_qt_interval = numeric(0), ecg_qtc = numeric(0), ecg_qtf = numeric(0))
}

# =============================================================================
# 13. CONCOMITANT MEDS — not extracted for controls → all-FALSE stub
# =============================================================================
med_cols <- c("med_metformin","med_insulin","med_sglt2","med_acei","med_arb",
              "med_betablocker","med_ccb","med_diuretic","med_statin")
if (have_ord_meds) {
  ord_meds_clean <- ord_meds_controls %>%
    mutate(Order_Start_Date = as.Date(Order_Start_Date),
           Order_Stop_Date  = as.Date(Order_Stop_Date)) %>%
    select(-any_of("delv_date")) %>%
    inner_join(exposure_df %>% select(CURR_CLINIC, delv_date),
               by = "CURR_CLINIC", relationship = "many-to-one") %>%
    filter(Order_Start_Date <= delv_date,
           is.na(Order_Stop_Date) | Order_Stop_Date >= (delv_date - 30))
  med_class_flag <- function(df, pattern, label) {
    df %>% filter(str_detect(Order_Name, regex(pattern, ignore_case = TRUE)) |
                  str_detect(Med_Generic, regex(pattern, ignore_case = TRUE))) %>%
      distinct(CURR_CLINIC) %>% mutate(!!label := TRUE)
  }
  meds_wide <- list(
    med_class_flag(ord_meds_clean, "metformin", "med_metformin"),
    med_class_flag(ord_meds_clean, "insulin", "med_insulin"),
    med_class_flag(ord_meds_clean, "empagliflozin|dapagliflozin|canagliflozin|ertugliflozin", "med_sglt2"),
    med_class_flag(ord_meds_clean, "lisinopril|enalapril|ramipril|captopril|benazepril", "med_acei"),
    med_class_flag(ord_meds_clean, "losartan|valsartan|olmesartan|telmisartan|irbesartan|candesartan", "med_arb"),
    med_class_flag(ord_meds_clean, "metoprolol|atenolol|carvedilol|bisoprolol|propranolol|labetalol|nebivolol", "med_betablocker"),
    med_class_flag(ord_meds_clean, "amlodipine|nifedipine|diltiazem|verapamil|felodipine", "med_ccb"),
    med_class_flag(ord_meds_clean, "hydrochlorothiazide|hctz|furosemide|spironolactone|chlorthalidone|bumetanide", "med_diuretic"),
    med_class_flag(ord_meds_clean, "atorvastatin|simvastatin|rosuvastatin|pravastatin|lovastatin|pitavastatin", "med_statin")
  ) %>% reduce(full_join, by = "CURR_CLINIC") %>%
    mutate(across(starts_with("med_"), ~ coalesce(., FALSE)))
} else {
  cat("Ordered meds: not available for controls — emitting FALSE columns.\n")
  meds_wide <- tibble(CURR_CLINIC = cohort_clean$CURR_CLINIC)
  for (mc in med_cols) meds_wide[[mc]] <- FALSE
}

# =============================================================================
# 14. ASSEMBLE FINAL ANALYSIS DATA FRAME
# =============================================================================
cat("\n--- Pre-assembly diagnostics (controls) ---\n")
cat("Cohort patients:", nrow(cohort_clean), "\n")
cat("Baseline SBP combined coverage:", sum(!is.na(sbp_summary$sbp_baseline_combined)), "\n")
cat("Baseline weight combined coverage:", sum(!is.na(weight_summary$weight_kg_baseline_combined)), "\n\n")

cat("Baseline source breakdown (weight):\n")
print(weight_summary %>% count(weight_kg_baseline_source, name = "n"))

analysis_df <- cohort_clean %>%
  left_join(demo_clean,     by = "CURR_CLINIC") %>%
  left_join(ob_clean,       by = "CURR_CLINIC") %>%
  left_join(exposure_df %>% select(-delv_date), by = "CURR_CLINIC") %>%
  left_join(height_summary, by = "CURR_CLINIC") %>%
  left_join(sbp_summary,    by = "CURR_CLINIC") %>%
  left_join(dbp_summary,    by = "CURR_CLINIC") %>%
  left_join(weight_summary, by = "CURR_CLINIC") %>%
  left_join(bp_staging %>% select(CURR_CLINIC, bp_stage, elevated_bp_any, stage2_htn),
            by = "CURR_CLINIC") %>%
  left_join(events_df %>% select(-glp1_postpartum_exposed, -glp1_index_date,
                                 -days_pp_to_glp1, -glp1_timing_cat, -glp1_timing_2cat),
            by = "CURR_CLINIC") %>%
  left_join(comorbidities,  by = "CURR_CLINIC") %>%
  left_join(labs_wide,      by = "CURR_CLINIC") %>%
  left_join(smoking_clean,  by = "CURR_CLINIC") %>%
  left_join(alc_combined,   by = "CURR_CLINIC") %>%
  left_join(echo_clean,     by = "CURR_CLINIC") %>%
  left_join(ecg_clean,      by = "CURR_CLINIC") %>%
  left_join(meds_wide,      by = "CURR_CLINIC") %>%
  mutate(
    across(starts_with("ckm_"),  ~ if (is.logical(.)) coalesce(., FALSE) else .),
    across(starts_with("preg_"), ~ if (is.logical(.)) coalesce(., FALSE) else .),
    across(starts_with("med_"),  ~ coalesce(., FALSE)),
    glp1_postpartum_exposed = coalesce(glp1_postpartum_exposed, FALSE),
    glp1_predelivery_any    = coalesce(glp1_predelivery_any, FALSE),
    bmi_baseline_primary  = weight_kg_baseline_primary  / ((height_cm / 100)^2),
    bmi_baseline_pp       = weight_kg_baseline_pp       / ((height_cm / 100)^2),
    bmi_baseline_sens     = weight_kg_baseline_sens     / ((height_cm / 100)^2),
    bmi_baseline_combined = weight_kg_baseline_combined / ((height_cm / 100)^2),
    delta_sbp_pp6m_primary   = sbp_baseline_primary        - sbp_m6_pp,
    delta_sbp_pp12m_primary  = sbp_baseline_primary        - sbp_m12_pp,
    delta_dbp_pp6m_primary   = dbp_baseline_primary        - dbp_m6_pp,
    delta_dbp_pp12m_primary  = dbp_baseline_primary        - dbp_m12_pp,
    delta_wt_pp6m_primary    = weight_kg_baseline_primary  - weight_kg_m6_pp,
    delta_wt_pp12m_primary   = weight_kg_baseline_primary  - weight_kg_m12_pp,
    pct_wt_loss_pp6m_primary  = (weight_kg_baseline_primary - weight_kg_m6_pp)  / weight_kg_baseline_primary  * 100,
    pct_wt_loss_pp12m_primary = (weight_kg_baseline_primary - weight_kg_m12_pp) / weight_kg_baseline_primary  * 100,
    delta_sbp_pp6m   = sbp_baseline_combined       - sbp_m6_pp,
    delta_sbp_pp12m  = sbp_baseline_combined       - sbp_m12_pp,
    delta_dbp_pp6m   = dbp_baseline_combined       - dbp_m6_pp,
    delta_dbp_pp12m  = dbp_baseline_combined       - dbp_m12_pp,
    delta_wt_pp6m    = weight_kg_baseline_combined - weight_kg_m6_pp,
    delta_wt_pp12m   = weight_kg_baseline_combined - weight_kg_m12_pp,
    pct_wt_loss_pp6m  = (weight_kg_baseline_combined - weight_kg_m6_pp)  / weight_kg_baseline_combined * 100,
    pct_wt_loss_pp12m = (weight_kg_baseline_combined - weight_kg_m12_pp) / weight_kg_baseline_combined * 100,
    delta_hba1c_6m  = lab_hba1c_baseline - lab_hba1c_post_6m,
    delta_hba1c_12m = lab_hba1c_baseline - lab_hba1c_post_12m,
    delta_tc_6m     = lab_tc_baseline    - lab_tc_post_6m,
    delta_ldl_6m    = lab_ldl_baseline   - lab_ldl_post_6m,
    delta_trig_6m   = lab_trig_baseline  - lab_trig_post_6m
  ) %>%
  mutate(treatment_group = "Control")   # ensure present after joins

# =============================================================================
# 15. EXPORT  (note: _controls suffix so treatment outputs are not overwritten)
# =============================================================================
saveRDS(analysis_df,  file.path(out_dir, "analysis_df_controls.rds"))
saveRDS(vitals_long,  file.path(out_dir, "vitals_long_controls.rds"))
saveRDS(labs_long,    file.path(out_dir, "labs_long_controls.rds"))
saveRDS(events_df,    file.path(out_dir, "events_df_controls.rds"))

readr::write_csv(analysis_df, file.path(out_dir, "analysis_df_controls.csv"))
readr::write_csv(vitals_long, file.path(out_dir, "vitals_long_controls.csv"))
readr::write_csv(labs_long,   file.path(out_dir, "labs_long_controls.csv"))
readr::write_csv(events_df,   file.path(out_dir, "events_df_controls.csv"))

cat("\n========================================\n")
cat("FINAL CONTROL DATASET (v4 — delivery-anchored)\n")
cat("========================================\n")
cat("Patients (rows):     ", nrow(analysis_df), "\n")
cat("Variables (cols):    ", ncol(analysis_df), "\n")
cat("Baseline SBP combined:", sum(!is.na(analysis_df$sbp_baseline_combined)), "\n")
cat("Baseline Wt  combined:", sum(!is.na(analysis_df$weight_kg_baseline_combined)), "\n")
cat("Stage 1+ HTN:        ", sum(analysis_df$elevated_bp_any, na.rm = TRUE), "\n")
cat("Stage 2 HTN:         ", sum(analysis_df$stage2_htn,      na.rm = TRUE), "\n")
cat("Output dir:          ", out_dir, "\n")

# Column-parity check vs treatment analysis_df (if present) — helps before rbind
tx_path <- file.path(out_dir, "analysis_df.rds")
if (file.exists(tx_path)) {
  tx <- readRDS(tx_path)
  only_tx   <- setdiff(names(tx), names(analysis_df))
  only_ctrl <- setdiff(names(analysis_df), names(tx))
  cat("\n--- Schema parity vs treatment analysis_df ---\n")
  cat("In treatment only (", length(only_tx), "):\n", sep=""); print(only_tx)
  cat("In controls only  (", length(only_ctrl), "):\n", sep=""); print(only_ctrl)
}

invisible(list(
  analysis_df = analysis_df,
  vitals_long = vitals_long,
  labs_long   = labs_long,
  events_df   = events_df
))