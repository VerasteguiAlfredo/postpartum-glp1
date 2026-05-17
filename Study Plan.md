# Postpartum GLP-1 Receptor Agonist Therapy: Analysis Plan

**Version 2.0** | Updated after dataset construction and exploratory QC | Built on Dr. Demi's original analysis plan

---

## 1. Study Design

Retrospective single-arm pre–post cohort study evaluating cardiometabolic outcomes before and after exposure to glucagon-like peptide-1 receptor agonists (GLP-1 RA) in the postpartum period. **Each participant serves as her own control**, with outcomes compared between baseline (pre-GLP-1 initiation) and follow-up measurements obtained within 12 months following the index delivery.

### Cohort Summary (post data prep)

| Item | Value |
|---|---|
| Patients | 704 (all GLP-1 exposed postpartum) |
| Median age at delivery | 33 years (IQR 29–36) |
| Obesity (any) | 81.1% |
| T2DM | 16.2% |
| Pre-existing essential HTN | 20.2% |
| Any preeclampsia spectrum | 28.6% |
| Median days delivery → GLP-1 start | 207 (IQR 123–282) |
| Pre-pregnancy GLP-1 exposure | 0 (excluded by design) |

---

## 2. Primary Outcomes

### Continuous Outcomes
- **Change in maternal weight (kg)** from baseline to follow-up within 12 months postpartum
- **Total Body Weight Loss percentage (TBWL%)** at 3, 6, and 12 months postpartum *(primary effectiveness metric, gold-standard in GLP-1 trials)*
- **Change in SBP and DBP (mmHg)** from baseline to follow-up

### Binary Threshold Outcomes
- **≥5% TBWL** achieved by 12 months *(FDA threshold for weight-loss drug approval)*
- **≥10% TBWL** achieved by 12 months *(threshold for HTN/DM remission)*
- **≥15% TBWL** achieved by 12 months *(threshold for CV event reduction, SURMOUNT-MMO)*
- **Difference between pre-pregnancy and last postpartum weight <4 kg** *(weight retention threshold)*
- **SBP reduction ≥10 mmHg** at any post-baseline visit
- **DBP reduction ≥5 mmHg** at any post-baseline visit

---

## 3. Secondary Outcomes

- Change in HbA1c (overall and in T2DM subgroup)
- Change in total cholesterol, LDL, HDL, triglycerides
- Change in eGFR
- Time to clinically meaningful improvement (see Survival Analysis section)

---

## 4. Time Zero and Baseline Definitions

### Two Time Anchors (Per Methodological Discussion with Dr. Demi)

**Delivery-anchored** (primary frame for descriptive analyses and follow-up windowing):
- Index date = delivery date
- Follow-up windows at 3, 6, and 12 months postpartum
- All measurements anchored to delivery for uniform cohort timeline

**GLP-1-anchored** (for time-to-event analyses):
- Time zero = first postpartum GLP-1 order date
- Outcomes measured from days post-GLP-1 start
- Censored at 12 months postpartum or last available follow-up

### Baseline Definitions

**Primary baseline** *(rigorous, used for primary analyses)*:
- Most recent BP/weight measurement that is:
  - Within 90 days before GLP-1 start, AND
  - ≥42 days postpartum (clinically meaningful 6-week checkpoint, avoids hospital discharge fluid status)
- N=613 patients have primary SBP baseline; N=622 have primary weight baseline

**Sensitivity baseline** *(inclusive, used for robustness checks)*:
- Most recent measurement before GLP-1, no 42-day floor
- N=644 SBP; N=654 weight

### Sociobehavioral Variables

Pre-pregnancy anchor preferred to avoid pregnancy-period reporting bias:
- Smoking, alcohol use, AUDIT-C captured ≥280 days before delivery when available
- Falls back to pre-delivery if no pre-pregnancy record exists
- Sensitivity analysis available comparing both anchors

---

## 5. GLP-1 Exposure Variables

### Timing Strata (Per Dr. Demi's spec)

| Stratum | Days delivery → GLP-1 | N | % |
|---|---|---|---|
| < 6 weeks | < 42 | 24 | 3.4% |
| 6wk – 3mo | 42–89 | 84 | 11.9% |
| 3 – 6mo | 90–179 | 189 | 26.8% |
| > 6mo | ≥180 | 407 | 57.8% |

### Drug Distribution

| Drug | N | % |
|---|---|---|
| Semaglutide | 325 | 46.2% |
| Tirzepatide | 299 | 42.5% |
| Liraglutide | 56 | 8.0% |
| Dulaglutide | 21 | 3.0% |
| Exenatide | 2 | 0.3% |
| Other | 1 | 0.1% |

### Persistence Tracking
- Duration on therapy (`glp1_duration_days`)
- Active-at-window flags (6mo, 12mo postpartum)
- Drug switches (`glp1_n_distinct_drugs`)
- Persistence categorical: <1mo, 1-3mo, 3-6mo, 6-12mo, ≥12mo

> ⚠️ **Important confounder identified**: Early starters persist longer (96% of <6wk starters reach ≥12 months on therapy vs 41% of >6mo starters). Duration must be considered when interpreting timing-stratified effects.

---

## 6. Comorbidity Variables

### Cardio-Kidney-Metabolic (CKM) Conditions at Baseline (19 conditions)
Lifetime history flags from ICD descriptions, captured before delivery:
- Atrial fibrillation/flutter, supraventricular tachycardia, ventricular tachycardia
- HFpEF, HFrEF
- Essential hypertension, coronary artery disease
- CKD Stage 3A+, T1DM, T2DM, dyslipidemia, prediabetes
- CABG history, PCI/stent history, stroke/TIA history
- Obesity (any BMI ≥30), peripheral arterial disease
- Implantable cardiac device, obstructive sleep apnea

### Pregnancy-Related Complications (11 variables)
Captured during index pregnancy window (delivery − 280d to delivery + 90d):
- Hypertension (any, gestational)
- Preeclampsia (mutually exclusive: pregnancy-period, postpartum, eclampsia)
- `preg_preec_any_spectrum` composite
- Gestational diabetes
- SGA, IUGR, placental abruption
- Peripartum cardiomyopathy

---

## 7. Descriptive Statistics (Table 1)

Baseline characteristics will be summarized using:
- **Continuous variables**: median (Q1, Q3)
- **Categorical variables**: n (%)
- **Missing data**: reported explicitly per variable

### Stratification
Table 1 will be presented in two ways:
1. **Overall** (full cohort, n=704)
2. **Stratified by GLP-1 timing** (<6wk / 6wk-3mo / 3-6mo / >6mo) with between-group p-values

### Variables for Table 1
- Demographics: age, race (consolidated 7 categories), ethnicity (3 categories)
- Anthropometrics at baseline: weight, height, BMI, BSA
- Hemodynamics at baseline: SBP, DBP, BP stage (Normal / Stage 1 / Stage 2 per ACC/AHA 2017)
- Pre-pregnancy lifestyle: smoking status, alcohol use, AUDIT-C
- Obstetric history: gravidity, parity, gestational age at delivery, delivery modality
- CKM comorbidities (all 19)
- Pregnancy complications (all 10 + composite spectrum)
- Concomitant medications: ACEi, ARB, BB, CCB, diuretic, statin, metformin, insulin, SGLT2
- Baseline labs: HbA1c, glucose, creatinine, eGFR, LDL, HDL, TC, triglycerides, ALT, AST
- Cardiac assessment (subset): echo EF, BSA; ECG HR, PR, QRS, QTc

### Variables for Table 2 (GLP-1 Exposure)
- Time to initiation after delivery (median, IQR)
- Drug class distribution
- Persistence categorical
- Drug switches
- Active-at-6mo and active-at-12mo flags

---

## 8. Modeling Continuous Outcomes

### Linear Mixed-Effects Models (LMM)

Preferred over repeated-measures ANOVA to accommodate unequal follow-up times and missing data.

**Model structure** (illustrative, weight as outcome):
```
weight_kg ~ time + (1 | patient_id)
```
With extensions for:
- **Random intercept and slope** per patient
- **Time as continuous** (days from GLP-1 start) with restricted cubic splines if non-linear
- **Stratification by GLP-1 timing**: `weight_kg ~ time * glp1_timing_cat + (1 + time | patient_id)`
- **Adjustment** for baseline value, age, race, baseline BMI, comorbidity burden

**Reporting**: estimated marginal means with 95% CIs, at 3/6/12 months from GLP-1 start.

Example interpretation: *"Postpartum women receiving GLP-1 RA showed a mean SBP reduction of X mmHg (95% CI X–Y) at 6 months in the elevated-BP subgroup."*

### Paired Wilcoxon Signed-Rank Tests
For binary pre/post comparisons at fixed timepoints, used descriptively alongside LMM.

---

## 9. Subgroup Analyses

### BP Subgroup (per Dr. Demi)
**Restriction: baseline BP ≥130/80 (Stage 1+ HTN, ACC/AHA 2017)**
- N=324 patients (46% of cohort)
- Rationale: GLP-1 has minimal BP effect in normotensives. QC showed BP signal only emerged in this subgroup (SBP Δ at 12mo: p<0.001).
- Sensitivity: Stage 2 HTN only (n=68) where signal is even stronger

### Diabetes Subgroup (HbA1c outcome)
- T2DM subgroup (n=114) for HbA1c effect
- Includes prediabetes subgroup (n=144) as exploratory

### GLP-1 Timing Strata
- Primary stratification per Dr. Demi: <6wk / 6wk-3mo / 3-6mo / >6mo
- Secondary dichotomy: early (<6mo) vs late (≥6mo)

---

## 10. Time-to-Event Analyses

### Event Definitions
- **SBP event**: First visit with SBP ≥10 mmHg lower than baseline
- **DBP event**: First visit with DBP ≥5 mmHg lower than baseline
- **Weight events**: First visit achieving ≥5%, ≥10%, or ≥15% TBWL

### Time Origin
GLP-1 initiation date (clock starts when drug is started)

### Censoring
At the earlier of:
- Last available follow-up measurement
- 12 months postpartum

### Analysis Methods

**Kaplan-Meier curves** showing cumulative incidence over months since GLP-1 start, stratified by:
1. **GLP-1 timing**: <6wk / 6wk-3mo / 3-6mo / >6mo (primary)
2. **Age group**: <35 vs ≥35 years
3. **Gravidity**: 1 vs ≥2
4. **Parity**: 1 vs ≥2
5. **Baseline BMI**: 30–34 vs 35–39 vs ≥40
6. **T2DM status**: Yes vs No

**Cox proportional hazards models** for predictors of achieving each event:
- Univariate: each predictor alone
- Multivariate: timing + age + baseline BMI + T2DM + parity + race

### Reporting
- Median time to ≥10% weight loss (overall and by stratum)
- Proportion achieving event by 3, 6, 12 months
- Hazard ratios (95% CI) for timing strata using `> 6mo` as reference
- Log-rank tests for between-strata comparisons

Example: *"Median time to ≥10% TBWL was 7 months in 6wk-3mo starters versus not reached in >6mo starters (HR 2.4, 95% CI 1.6-3.5, p<0.001 for early vs late initiation)."*

---

## 11. Sensitivity Analyses

1. **Baseline window**: Re-run primary analyses using sensitivity baseline (no 42-day floor) — confirms results aren't driven by baseline-definition choice
2. **Pre-pregnancy vs pre-delivery sociobehavioral**: Re-run with pre-delivery anchors to confirm robustness
3. **Persistence subgroup**: Restrict to patients with ≥3 months active GLP-1 therapy (excludes early discontinuers)
4. **Drug class**: Stratify by semaglutide vs tirzepatide (the two dominant agents) for class-specific effects
5. **GLP-1-anchored vs delivery-anchored**: Compare time-to-event using both anchors

---

## 12. Important Caveats Discovered During Data Prep

### Postpartum Window Constraint Creates Apparent "No Effect" in Late Starters
Patients starting GLP-1 at ≥6 months postpartum have very limited follow-up within the 12-month-postpartum window. Their 12mo TBWL% appears near zero, but this reflects insufficient observation time, not lack of drug effect. **Timing-stratified analysis is essential to avoid misleading null findings.**

### BP Effect Is Subgroup-Specific
In the full cohort, median SBP change at 6mo is essentially zero. The signal only emerges when restricted to patients with elevated baseline BP (Stage 1+ HTN). This subgroup approach must be pre-specified, not post-hoc.

### Lipid Panel Sample Bias
N=27 patients with paired lipid panels at 6mo. These patients are likely selected for repeat testing due to abnormal baseline values, creating regression-to-the-mean bias. Lipid findings should be reported as exploratory with prominent caveats.

### Smoking/Alcohol Pregnancy-Period Bias
Pre-delivery smoking captured 35 current smokers (5%); pre-pregnancy anchor captured 72 current smokers (12%). The pregnancy-period anchor systematically undercounts true PMH. The primary variables use pre-pregnancy anchor where available; methods section should describe this approach.

### Right-Censoring of Persistence
Many patients with "Unknown" stop dates may actually still be on therapy. Persistence categories are prescription-based, not adherence-based. Discuss as limitation.

---

## 13. Tables and Figures (Final Manuscript)

### Tables
- **Table 1**: Baseline demographics and clinical characteristics, overall and by GLP-1 timing stratum
- **Table 2**: GLP-1 exposure characteristics (drug class, timing, persistence)
- **Table 3**: Primary outcomes — change in weight, SBP, DBP from baseline at 3, 6, 12 months postpartum (overall and by timing)
- **Table 4**: Time-to-event summary — proportion achieving each threshold, median time-to-event, hazard ratios
- **Table 5**: Secondary outcomes — lab changes (with N and caveats)

### Figures
- **Figure 1**: TBWL% trajectory by GLP-1 timing stratum *(headline figure)*
- **Figure 2**: SBP % change trajectory in Stage 1+ HTN subgroup, by timing
- **Figure 3**: Kaplan-Meier curve — time to ≥10% TBWL, stratified by GLP-1 timing
- **Figure 4**: Kaplan-Meier curve — time to ≥10 mmHg SBP reduction (Stage 1+ subgroup)
- **Figure 5**: Kaplan-Meier curve — time to ≥5 mmHg DBP reduction (Stage 1+ subgroup)
- **Figure 6** (supplementary): HbA1c trajectory by diabetes status

---

## 14. Statistical Software

All analyses in R (≥4.3). Key packages:
- `tidyverse` for data manipulation
- `lme4` and `lmerTest` for linear mixed-effects models
- `survival` and `survminer` for KM and Cox models
- `gtsummary` for publication-ready Table 1
- `ggplot2` for figures

---

## 15. Data Provenance and Reproducibility

- Build pipeline: `build_analysis_dataset_v2.R` (delivery-anchored)
- QC pipeline: `qc_analysis_dataset_v2.R`
- Regex audit: `audit_regex_quality_v2.R`
- Outputs versioned in `data_processed/` with `.rds` and `.csv` formats
- Code repository: GitHub (path TBD)