# Methods

## Study Design and Setting

This was a retrospective, single-center cohort study conducted at Mayo Clinic, using clinical and administrative data extracted from the Cardiovascular Data Mart (CV DataMart), a curated longitudinal repository within the Mayo Clinic Unified Data Platform that integrates electronic medical record data on demographics, encounters, laboratory results, vital signs, medications, diagnoses, and obstetric outcomes. The study was approved by the Mayo Clinic Institutional Review Board (IRB 25-012602) with a waiver of informed consent. Reporting follows the STROBE guidelines for observational cohort studies.

## Participants

We included women aged 18 years or older with at least one documented delivery date in the electronic medical record and a first-time prescription for a glucagon-like peptide-1 receptor agonist (GLP-1 RA) initiated within 12 months following the index delivery between June 2018 and December 31, 2025. Eligible agents included semaglutide (Ozempic, Wegovy, Rybelsus), tirzepatide (Mounjaro, Zepbound), liraglutide (Victoza, Saxenda), dulaglutide (Trulicity), exenatide (Byetta, Bydureon Bcise), lixisenatide (Adlyxin), and albiglutide (Tanzeum). Patients with documented pre-delivery GLP-1 RA exposure were excluded to restrict the analysis to postpartum-initiated therapy. After applying inclusion and exclusion criteria, 704 patients formed the final analytic cohort. Cohort derivation is detailed in Figure 1.

## Exposure

The primary exposure was timing of GLP-1 RA initiation relative to the index delivery, dichotomized a priori at 6 months postpartum: Early (<6 months; n=297) versus Late (≥6 months; n=407). This threshold was chosen to distinguish the early postpartum period, characterized by ongoing physiologic recovery and lactation, from the stabilized later interval. A four-category parameterization (<6 weeks, 6 weeks–3 months, 3–6 months, >6 months) was retained for descriptive analyses.

## Outcomes

Six time-to-event outcomes were pre-specified, with follow-up restricted to 540 days (18 months) following GLP-1 initiation:

Weight outcomes were evaluated in the full cohort: (A1) first measured weight ≤90% of baseline (≥10% reduction), (A2) first weight ≤80% of baseline (≥20% reduction), and (A3) first weight ≤ pre-pregnancy weight, evaluated in the subset with documented pre-pregnancy weight (n=633).

Blood pressure outcomes were evaluated in a hypertensive disorder of pregnancy (HDP) subgroup (n=440), defined as any documented gestational hypertension, preeclampsia, eclampsia, or chronic hypertension during the index pregnancy, or a baseline blood pressure ≥140/90 mmHg. The outcomes were (B1) first ≥5 mmHg decline in systolic blood pressure (SBP) from baseline, (B2) first ≥10 mmHg SBP decline, and (B3) first ≥5 mmHg decline in diastolic blood pressure (DBP).

## Variables and Data Sources

Baseline weight and blood pressure were derived using a two-tier hierarchical approach. The primary baseline preferred the measurement closest to GLP-1 initiation occurring at least 42 days postpartum (avoiding acute postpartum physiologic flux); a fallback used the closest measurement at any postpartum day when no qualifying primary measurement existed. All baseline measurements were constrained to a 90-day window before drug initiation. Pre-pregnancy weight was calculated from documented pre-gravid BMI and height. Comorbidities were ascertained from ICD-10 codes documented prior to the index delivery; pregnancy-related conditions were ascertained from obstetric data captured during the index pregnancy. Implausible vital sign measurements were excluded (weight <30 or >350 kg; SBP <50 or >260 mmHg; DBP <30 or >180 mmHg).

## Statistical Analysis

Baseline characteristics were summarized by GLP-1 timing stratum as medians with interquartile ranges for continuous variables and counts with percentages for categorical variables, with Wilcoxon rank-sum tests and Fisher's exact tests (with Monte Carlo simulation using 10,000 replicates) used for between-stratum comparisons, respectively.

Time-to-event analyses used a drug-anchored time origin (time zero = GLP-1 RA initiation date), with follow-up censored at 540 days or the last available measurement. This anchoring was selected to ensure equivalent on-drug observation across timing strata. Cumulative incidence was estimated via the Kaplan-Meier method, with log-rank tests for stratum comparisons. Cox proportional hazards regression yielded adjusted hazard ratios (HRs) and 95% confidence intervals (CIs) for Late versus Early initiation. The proportional hazards assumption was assessed by Schoenfeld residuals.

Weight outcome models adjusted for maternal age, baseline BMI, parity (primiparous vs. multiparous), delivery mode (cesarean vs. vaginal), pre-existing type 2 diabetes, gestational diabetes, and GLP-1 agent class (semaglutide vs. other). Blood pressure models adjusted for maternal age, baseline BMI, any baseline antihypertensive medication, history of preeclampsia (any spectrum), pre-existing type 2 diabetes, gestational diabetes, and GLP-1 agent class. GLP-1 persistence was deliberately omitted from adjustment as a post-baseline variable subject to collider bias.

Censoring followed an intent-to-treat-style framework, with outcome ascertainment continuing after any GLP-1 discontinuation to reflect the policy-relevant question of initiation timing.

## Sensitivity Analyses

Two pre-specified sensitivity analyses were conducted for each outcome: (i) a drug-anchored model using an expanded baseline definition that included near-delivery measurements obtained between 0 and 42 days postpartum, to test robustness to fluid-influenced early postpartum weights; and (ii) a delivery-anchored model with left-truncation at GLP-1 initiation, providing the postpartum-clock perspective.

## Missing Data and Software

Missing data were not imputed. Patients lacking the relevant baseline measurement were excluded from outcome-specific analyses (52 lacked a weight baseline; 60 lacked a blood pressure baseline; 71 lacked documented pre-pregnancy weight). All analyses were performed in R version 4.4 (R Foundation for Statistical Computing) using the *survival*, *survminer*, *gtsummary*, *gt*, and *forestploter* packages. Two-sided *p* values <0.05 were considered statistically significant.