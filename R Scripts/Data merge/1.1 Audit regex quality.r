# =============================================================================
# Audit regex quality v2 — updated for pre-pregnancy / pre-delivery anchors
# Run AFTER build_analysis_dataset_v2.R
# =============================================================================
suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tidyr)
})

# -----------------------------------------------------------------------------
# Reconstruct dx_indexpreg slice (same as build script)
# -----------------------------------------------------------------------------
dx_indexpreg <- dx %>%
  mutate(Dx_Date       = as.Date(Dx_Date),
         Dx_Desc_lower = str_to_lower(Dx_Desc)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(cohort_clean %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(!is.na(Dx_Date),
         Dx_Date >= (delv_date - 280),
         Dx_Date <= (delv_date + 90))

dx_lifetime_check <- dx %>%
  mutate(Dx_Date       = as.Date(Dx_Date),
         Dx_Desc_lower = str_to_lower(Dx_Desc)) %>%
  select(-any_of("delv_date")) %>%
  inner_join(cohort_clean %>% select(CURR_CLINIC, delv_date),
             by = "CURR_CLINIC",
             relationship = "many-to-one") %>%
  filter(!is.na(Dx_Date), Dx_Date <= delv_date)

# =============================================================================
# AUDIT 1: Verify eclampsia false-positive fix worked
# =============================================================================
cat("================================================================\n")
cat(" AUDIT 1: eclampsia regex (post-fix)\n")
cat("================================================================\n\n")

cat("Patients flagged as preg_eclampsia (true eclampsia only):\n")
print(sum(analysis_df$preg_eclampsia, na.rm = TRUE))

cat("\nDx descriptions matched by current preg_eclampsia regex ((?<!pre)eclampsia):\n")
dx_indexpreg %>%
  filter(str_detect(Dx_Desc_lower, regex("(?<!pre)(?<!pre-)(?<!pre )eclampsia", ignore_case = TRUE))) %>%
  count(Dx_Desc, sort = TRUE) %>%
  print(n = 10)

# =============================================================================
# AUDIT 2: Verify postpartum preeclampsia + IUGR/SGA captured
# =============================================================================
cat("\n================================================================\n")
cat(" AUDIT 2: postpartum preeclampsia / IUGR / SGA captures\n")
cat("================================================================\n\n")

cat("Patients flagged as preg_postpartum_preec:", sum(analysis_df$preg_postpartum_preec, na.rm = TRUE), "\n")
cat("Patients flagged as preg_iugr:           ", sum(analysis_df$preg_iugr,            na.rm = TRUE), "\n")
cat("Patients flagged as preg_sga:            ", sum(analysis_df$preg_sga,             na.rm = TRUE), "\n\n")

cat("Top dx descriptions captured by preg_postpartum_preec:\n")
dx_indexpreg %>%
  filter(str_detect(Dx_Desc_lower,
    regex("(preeclampsia|pre-eclampsia|pre eclampsia).*(postpartum|puerperium)|(postpartum|puerperium).*(preeclampsia|pre-eclampsia|pre eclampsia)|postpartum eclampsia|post-partum eclampsia",
          ignore_case = TRUE))) %>%
  count(Dx_Desc, sort = TRUE) %>%
  print(n = 10)

cat("\nTop dx descriptions captured by preg_iugr:\n")
dx_indexpreg %>%
  filter(str_detect(Dx_Desc_lower,
    regex("intrauterine growth restriction|intrauterine growth retardation|fetal growth restriction|fetal growth retardation|retardation fetal growth|poor fetal growth|slow intrauterine growth|slow fetal growth|\\biugr\\b",
          ignore_case = TRUE))) %>%
  count(Dx_Desc, sort = TRUE) %>%
  print(n = 10)

# =============================================================================
# AUDIT 3: Confirm CKM zero-counts are genuine (not regex misses)
# =============================================================================
cat("\n================================================================\n")
cat(" AUDIT 3: zero-count CKM conditions — true zero or missed?\n")
cat("================================================================\n\n")

cat("ckm_hfref captures:", sum(analysis_df$ckm_hfref, na.rm = TRUE), "\n")
cat("ckm_hfpef captures:", sum(analysis_df$ckm_hfpef, na.rm = TRUE), "\n")
cat("ckm_cabg_hx captures:", sum(analysis_df$ckm_cabg_hx, na.rm = TRUE), "\n")
cat("ckm_pci_stent_hx captures:", sum(analysis_df$ckm_pci_stent_hx, na.rm = TRUE), "\n")
cat("ckm_pad captures:", sum(analysis_df$ckm_pad, na.rm = TRUE), "\n\n")

cat("--- All heart failure / cardiomyopathy descriptions in cohort ---\n")
dx_lifetime_check %>%
  filter(str_detect(Dx_Desc_lower, "heart failure|ejection fraction|cardiomyopathy")) %>%
  count(Dx_Desc, sort = TRUE) %>%
  print(n = 15)

cat("\n--- All bypass / CABG descriptions (gastric bypass should now be excluded) ---\n")
dx_lifetime_check %>%
  filter(str_detect(Dx_Desc_lower, "bypass|\\bcabg\\b")) %>%
  count(Dx_Desc, sort = TRUE) %>%
  print(n = 10)

# =============================================================================
# AUDIT 4: Smoking + alcohol (PRE-PREGNANCY anchor)
# =============================================================================
cat("\n================================================================\n")
cat(" AUDIT 4: smoking + alcohol — pre-pregnancy vs pre-delivery\n")
cat("================================================================\n\n")

cat("--- Smoking status: pre-pregnancy anchor ---\n")
print(analysis_df %>% count(smoking_status_pre_preg))

cat("\n--- Smoking status: pre-delivery anchor (legacy) ---\n")
print(analysis_df %>% count(smoking_status_pre_delv))

cat("\n--- PRIMARY smoking_status (pre-pregnancy preferred, falls back to pre-delivery) ---\n")
print(analysis_df %>% count(smoking_status))

cat("\n--- Patients where pre-pregnancy and pre-delivery answers disagree ---\n")
disagree_smk <- analysis_df %>%
  filter(!is.na(smoking_status_pre_preg),
         !is.na(smoking_status_pre_delv),
         as.character(smoking_status_pre_preg) != as.character(smoking_status_pre_delv)) %>%
  count(smoking_status_pre_preg, smoking_status_pre_delv)
print(disagree_smk)
cat("Total disagreements:", sum(disagree_smk$n, na.rm = TRUE), "\n")

cat("\n--- Raw pre-pregnancy smoking values ---\n")
print(analysis_df %>% count(smoking_status_pre_preg_raw, sort = TRUE) %>% head(10))

cat("\n--- Raw pre-delivery smoking values ---\n")
print(analysis_df %>% count(smoking_status_pre_delv_raw, sort = TRUE) %>% head(10))

cat("\n--- Alcohol status: pre-pregnancy anchor ---\n")
print(analysis_df %>% count(alc_use_status_pre_preg))

cat("\n--- Alcohol status: pre-delivery anchor (legacy) ---\n")
print(analysis_df %>% count(alc_use_status_pre_delv))

cat("\n--- PRIMARY alc_use_status (pre-pregnancy preferred) ---\n")
print(analysis_df %>% count(alc_use_status))

cat("\n--- Patients where pre-pregnancy and pre-delivery alcohol answers disagree ---\n")
disagree_alc <- analysis_df %>%
  filter(!is.na(alc_use_status_pre_preg),
         !is.na(alc_use_status_pre_delv),
         as.character(alc_use_status_pre_preg) != as.character(alc_use_status_pre_delv)) %>%
  count(alc_use_status_pre_preg, alc_use_status_pre_delv)
print(disagree_alc)
cat("Total disagreements:", sum(disagree_alc$n, na.rm = TRUE), "\n")

cat("\n--- AUDIT-C score (PRIMARY, pre-pregnancy preferred) ---\n")
print(summary(analysis_df$audit_c_score))

cat("\n--- AUDIT-C at-risk drinking (score ≥ 3, primary) ---\n")
print(analysis_df %>% count(audit_c_at_risk))

# =============================================================================
# AUDIT 5: ECG + Echo capture
# =============================================================================
cat("\n================================================================\n")
cat(" AUDIT 5: ECG + Echo capture\n")
cat("================================================================\n\n")

cat("ECG parameter capture (non-missing counts):\n")
ecg_capture <- analysis_df %>%
  summarise(
    has_hr   = sum(!is.na(ecg_hr)),
    has_pr   = sum(!is.na(ecg_pr_interval)),
    has_qrs  = sum(!is.na(ecg_qrs_duration)),
    has_qt   = sum(!is.na(ecg_qt_interval)),
    has_qtc  = sum(!is.na(ecg_qtc)),
    has_qtf  = sum(!is.na(ecg_qtf))
  )
print(ecg_capture)

cat("\nECG parameter ranges:\n")
analysis_df %>%
  select(starts_with("ecg_") & where(is.numeric)) %>%
  summary() %>% print()

cat("\nEcho EF capture:\n")
cat("  Patients with echo_ef:", sum(!is.na(analysis_df$echo_ef)), "\n")
cat("  EF summary:\n")
print(summary(analysis_df$echo_ef))
cat("\nLow EF patients (<50%):", sum(analysis_df$echo_ef < 50, na.rm = TRUE), "\n")

cat("\nEcho BSA capture:\n")
cat("  Patients with echo_bsa:", sum(!is.na(analysis_df$echo_bsa)), "\n")
print(summary(analysis_df$echo_bsa))

# =============================================================================
# AUDIT 6 (NEW): Cross-check pregnancy complication overlap
# =============================================================================
cat("\n================================================================\n")
cat(" AUDIT 6: pregnancy complication overlaps / sanity\n")
cat("================================================================\n\n")

cat("--- Hypertension hierarchy ---\n")
cat("preg_htn_any        :", sum(analysis_df$preg_htn_any,         na.rm = TRUE), "\n")
cat("preg_htn_gestational:", sum(analysis_df$preg_htn_gestational, na.rm = TRUE), "\n")
cat("preg_preeclampsia   :", sum(analysis_df$preg_preeclampsia,    na.rm = TRUE), "\n")
cat("preg_postpartum_preec:", sum(analysis_df$preg_postpartum_preec, na.rm = TRUE), "\n")
cat("preg_eclampsia      :", sum(analysis_df$preg_eclampsia,       na.rm = TRUE), "\n")

cat("\n--- Patients with severe spectrum (preeclampsia / eclampsia / postpartum) ---\n")
cat("Any preeclampsia spectrum:",
    sum(analysis_df$preg_preeclampsia |
        analysis_df$preg_eclampsia |
        analysis_df$preg_postpartum_preec, na.rm = TRUE), "\n")

# =============================================================================
# AUDIT 7 (NEW): GLP-1 timing × persistence cross-tab
# =============================================================================
cat("\n================================================================\n")
cat(" AUDIT 7: GLP-1 timing × persistence cross-tab\n")
cat("================================================================\n\n")

cat("Timing × Persistence:\n")
print(table(analysis_df$glp1_timing_cat, analysis_df$glp1_persistence_cat, useNA = "ifany"))

cat("\nActive at 6m × Timing:\n")
print(table(analysis_df$glp1_timing_cat, analysis_df$glp1_active_at_6m_pp, useNA = "ifany"))

cat("\nActive at 12m × Timing:\n")
print(table(analysis_df$glp1_timing_cat, analysis_df$glp1_active_at_12m_pp, useNA = "ifany"))

# =============================================================================
# AUDIT 8 (NEW): Final variable inventory
# =============================================================================
cat("\n================================================================\n")
cat(" AUDIT 8: Variable inventory by category\n")
cat("================================================================\n\n")

vars <- names(analysis_df)
cat("Total variables:", length(vars), "\n\n")
cat("By category:\n")
cat("  Demographics/cohort   :", sum(vars %in% c("CURR_CLINIC","delv_date","Birth_Dt","current_age",
                                                  "Gender","Deceased","Death_Dt","Hospice","Dismissed",
                                                  "race_consolidated","ethnicity_consolidated",
                                                  "race_primary_raw","ethnicity_raw")), "\n")
cat("  OB / pregnancy        :", length(grep("^(GESTATIONAL|DELIVERY|PARITY|GRAVIDITY|MULTIPLE|PREGRAVID|LAST_MATERNAL|birth_weight|NUMBER_OF|INFERTILITY|PRIOR_CESAREAN|LABOR_ATTEMPT|APGAR|pregravid)",
                                              vars, ignore.case = TRUE)), "\n")
cat("  GLP-1 exposure        :", length(grep("^glp1_|^days_pp_to_glp1$", vars)), "\n")
cat("  Vitals (BP/weight)    :", length(grep("^(sbp_|dbp_|weight_kg_|bmi_|height_|bp_|elevated|stage|delta_|pct_)", vars)), "\n")
cat("  Events (TTE)          :", length(grep("^(sbp_event|dbp_event|wt_event|sbp_tte|dbp_tte|wt_tte|sbp_fu|dbp_fu|wt_fu)$", vars)), "\n")
cat("  CKM comorbidities     :", length(grep("^ckm_", vars)), "\n")
cat("  Pregnancy complications:", length(grep("^preg_", vars)), "\n")
cat("  Labs                  :", length(grep("^lab_", vars)), "\n")
cat("  Smoking               :", length(grep("^smoking_", vars)), "\n")
cat("  Alcohol               :", length(grep("^(alc_|audit_)", vars)), "\n")
cat("  Echo                  :", length(grep("^echo_", vars)), "\n")
cat("  ECG                   :", length(grep("^ecg_", vars)), "\n")
cat("  Concomitant meds      :", length(grep("^med_", vars)), "\n")

cat("\n================================================================\n")
cat(" AUDIT v2 COMPLETE — ready for Table 1 and analysis\n")
cat("================================================================\n")