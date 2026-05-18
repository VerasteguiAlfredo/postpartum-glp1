# `data_processed/` — Dataset and Figure Inventory

This folder contains the merged analysis-ready datasets and QC plots produced by the build and QC pipelines.

**Last updated:** After v2 build (delivery-anchored, post-comorbidity refinement)
**Source scripts:** `build_analysis_dataset_v2.R`, `qc_analysis_dataset_v2.R`

---

## Datasets

All datasets are exported in two formats: `.rds` (R-native, preserves factor levels and types) and `.csv` (universal, no factor metadata). **Use the `.rds` versions when working in R** to avoid losing factor levels and date types.

### `analysis_df` (one row per patient, wide format)

**Dimensions:** 704 rows × 228 columns
**Primary use:** Table 1, baseline characteristics, cross-sectional models, time-to-event analyses

The master patient-level table. Each row is one patient, with all baseline characteristics, GLP-1 exposure details, vitals at each follow-up window, comorbidity flags, labs, and outcome variables.

**Variable categories (228 total):**

| Category | n vars | Examples |
|---|---|---|
| Demographics / cohort | 13 | `CURR_CLINIC`, `current_age`, `race_consolidated`, `ethnicity_consolidated`, `Gender` |
| OB / pregnancy | 18 | `DELIVERY_DTM`, `GESTATIONAL_AGE_IN_WEEKS`, `DELIVERY_MODALITY`, `PREGRAVID_BMI`, `PARITY` |
| GLP-1 exposure | 17 | `glp1_index_date`, `glp1_timing_cat`, `glp1_first_drug`, `glp1_duration_days`, `glp1_persistence_cat`, `glp1_active_at_6m_pp` |
| Vitals (BP/weight) | 43 | `sbp_baseline_primary`, `sbp_baseline_sens`, `sbp_m6_pp`, `weight_kg_m12_pp`, `delta_wt_pp6m`, `pct_wt_loss_pp12m`, `bp_stage` |
| Time-to-event | 9 | `sbp_event`, `sbp_tte`, `wt_event`, `wt_tte`, `wt_fu` |
| CKM comorbidities | 24 | `ckm_obesity`, `ckm_t2dm`, `ckm_htn`, `ckm_hfref`, `ckm_count_conditions`, `ckm_any_dm` |
| Pregnancy complications | 12 | `preg_htn_any`, `preg_preeclampsia`, `preg_postpartum_preec`, `preg_preec_any_spectrum`, `preg_gdm` |
| Labs | 52 | `lab_hba1c_baseline`, `lab_hba1c_post_6m`, `lab_ldl_post_12m`, `delta_hba1c_6m`, `lab_creat_baseline` |
| Smoking | 8 | `smoking_status` (primary), `smoking_status_pre_preg`, `smoking_status_pre_delv`, `smoking_ever` |
| Alcohol | 18 | `alc_use_status` (primary), `alc_current_use`, `audit_c_score`, `audit_c_at_risk` |
| Echo | 3 | `echo_ef`, `echo_bsa`, `echo_date` |
| ECG | 7 | `ecg_hr`, `ecg_pr_interval`, `ecg_qrs_duration`, `ecg_qtc`, `ecg_qtf` |
| Concomitant meds | 9 | `med_metformin`, `med_insulin`, `med_acei`, `med_betablocker`, `med_statin` |

**Key design decisions encoded:**
- **Two baselines per vital:** `*_baseline_primary` (≥42d postpartum, before GLP-1) and `*_baseline_sens` (any pre-GLP-1)
- **Two anchors for sociobehavioral variables:** `*_pre_preg` (preferred PMH) and `*_pre_delv` (legacy)
- **Pregnancy complications are mutually exclusive** by design (preeclampsia, postpartum preeclampsia, and eclampsia don't overlap); `preg_preec_any_spectrum` is the composite

### `vitals_long`

**Dimensions:** 186,489 rows
**Primary use:** Linear mixed-effects models, trajectory plots, repeated-measures analyses

Long-format longitudinal vitals: one row per (patient, measurement date, vital type).

| Column | Description |
|---|---|
| `CURR_CLINIC` | Patient ID |
| `meas_date` | Date of measurement |
| `vital` | One of `sbp`, `dbp`, `weight_kg` |
| `value` | Numeric measurement (mmHg or kg) |
| `delv_date` | Delivery date (joined from cohort) |
| `index_date` | Delivery date (= delv_date in v2) |
| `glp1_index_date` | First postpartum GLP-1 order date |
| `days_from_delivery` | Days from delivery to measurement |
| `days_from_glp1` | Days from GLP-1 start to measurement |
| `period_glp1` | `pre` / `post` flag relative to GLP-1 start |
| `glp1_postpartum_exposed` | Always TRUE in this cohort |
| `days_pp_to_glp1` | Days from delivery to GLP-1 start |
| `glp1_timing_cat` | Timing stratum factor |

**Date range:** 90 days before delivery to 365 days after delivery.

### `labs_long`

**Dimensions:** 32,466 rows
**Primary use:** Lab trajectories, mixed-effects models for lab outcomes

Long-format lab results, restricted to the 15 cardiometabolic lab domains of interest (HbA1c, glucose, creatinine, eGFR, ALT, AST, albumin, bilirubin, albumin/creatinine ratio, LDL, HDL, total cholesterol, triglycerides, non-HDL, CRP).

| Column | Description |
|---|---|
| `CURR_CLINIC` | Patient ID |
| `Lab_Date` | Date of lab draw |
| `lab_domain` | Domain label (e.g., `hba1c`, `ldl`, `creat`) |
| `TestDesc` | Original lab test description (for traceability) |
| `Resultn` | Numeric result |
| `Resultc` | Categorical fallback (for non-numeric labs) |
| `Units` | Unit string from source |
| `Encounter_Nbr` | Encounter identifier |
| `delv_date` | Delivery date |
| `glp1_index_date` | GLP-1 start date |
| `days_from_delivery`, `days_from_glp1` | Timing variables |

### `events_df`

**Dimensions:** 704 rows
**Primary use:** Kaplan-Meier curves, Cox proportional hazards models

Time-to-event table, one row per patient, for the three clinical thresholds.

| Column | Description |
|---|---|
| `CURR_CLINIC` | Patient ID |
| `glp1_postpartum_exposed` | TRUE in this cohort |
| `glp1_index_date` | GLP-1 start date |
| `days_pp_to_glp1` | Days delivery → GLP-1 |
| `glp1_timing_cat` | Timing stratum |
| `sbp_event` / `sbp_tte` / `sbp_fu` | SBP ≥10 mmHg drop event flag, time-to-event, last follow-up |
| `dbp_event` / `dbp_tte` / `dbp_fu` | DBP ≥5 mmHg drop event flag, time-to-event, last follow-up |
| `wt_event` / `wt_tte` / `wt_fu` | >10% weight loss event flag, time-to-event, last follow-up |

**Note:** All time-to-event variables are measured in **days from GLP-1 start** (not days from delivery), since the events conceptually anchor to drug initiation.

---

## QC Plots (`qc_plots_v2/`)

All plots are PNG, 8×5 inches, 300 DPI, ready for paste-in to slides or supplementary materials.

### Headline plots (use these in the manuscript / PI updates)

#### `v2_tbwl_pct_by_timing.png` ⭐
**Total body weight loss % trajectory by GLP-1 timing stratum (full cohort)**

Each patient's weight expressed as % change from their primary baseline, plotted against days from delivery, with LOESS curves and 95% CI bands colored by timing stratum. Reference lines at 5%, 10%, 15% TBWL thresholds.

This is the headline weight figure — shows the timing gradient cleanly.

#### `v2_sbp_pct_subgroup.png` ⭐
**SBP % change trajectory in Stage 1+ HTN subgroup, by GLP-1 timing**

Same approach as TBWL but for SBP, **restricted to patients with baseline BP ≥130/80** (n=324). Reference lines at −5%, −10% change.

This is the BP figure that answers Dr. Demi's subgroup question. Shows where the signal actually lives.

#### `v2_hba1c_by_dm_status.png` ⭐
**HbA1c trajectory around GLP-1 start, stratified by diabetes status**

Three trajectories: No DM/Pre-DM, Prediabetes, T2DM. Reference lines at 5.7% (pre-DM) and 6.5% (DM thresholds). Y-axis capped at 4.5–11% to keep the clinically meaningful range visible.

Most informative HbA1c view — biological signal expected only in T2DM/prediabetes patients.

### Supplementary / supporting plots

#### `v2_sbp_pct_by_timing.png`
SBP % change trajectory by timing stratum, **full cohort** (not subgroup-restricted). Companion to the subgroup plot — useful for showing that the signal washes out in normotensives.

#### `v2_weight_kg_by_timing.png`
Absolute weight (kg) trajectory by timing stratum. Less interpretable than TBWL% because baseline weights differ across patients; included for transparency.

#### `v2_sbp_kg_by_timing.png`
Absolute SBP trajectory by timing stratum, full cohort. Includes Stage 1 (130) and Stage 2 (140) reference lines.

#### `v2_sbp_subgroup.png`
Absolute SBP trajectory in Stage 1+ HTN subgroup, single curve (not stratified by timing). Useful as a simple "does BP fall in hypertensives?" view.

#### `v2_hba1c_trajectory.png`
HbA1c trajectory overall (not stratified). Companion to the by-DM-status plot.

---

## File Cleanup Recommendations

The following files were left over from earlier versions and **can be safely deleted**:

| File | Reason |
|---|---|
| `qc_plots/qc_dbp_trajectory.png` | v1 GLP-1-anchored, superseded by v2 |
| `qc_plots/qc_sbp_trajectory.png` | v1 GLP-1-anchored, superseded by v2 |
| `qc_plots/qc_timing_histogram.png` | v1, was useful to demonstrate the time-window problem but now obsolete |
| `qc_plots/qc_weight_trajectory.png` | v1 GLP-1-anchored, superseded by v2 |
| `qc_plots_v2/v2_sbp_by_timing.png` | Duplicate of `v2_sbp_kg_by_timing.png` (mid-development rename leftover) |
| `qc_plots_v2/v2_weight_by_timing.png` | Duplicate of `v2_weight_kg_by_timing.png` (mid-development rename leftover) |

After cleanup, the entire v1 `qc_plots/` folder can be removed.

---

## Quick Reference: Loading the Data

```r
library(dplyr)
library(ggplot2)

data_dir <- "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1/data_processed"

# Master patient-level table
analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))

# Long-format vitals (for trajectory plots, LMM)
vitals_long <- readRDS(file.path(data_dir, "vitals_long.rds"))

# Long-format labs
labs_long <- readRDS(file.path(data_dir, "labs_long.rds"))

# Time-to-event
events_df <- readRDS(file.path(data_dir, "events_df.rds"))
```

---

## Provenance

| Artifact | Generated by |
|---|---|
| `analysis_df.rds` / `.csv` | `1.0 Build analysis dataset v2.R` |
| `vitals_long.rds` / `.csv` | `1.0 Build analysis dataset v2.R` |
| `labs_long.rds` / `.csv` | `1.0 Build analysis dataset v2.R` |
| `events_df.rds` / `.csv` | `1.0 Build analysis dataset v2.R` |
| `qc_plots_v2/*.png` | `2.0 Qc analysis dataset v2.R` |