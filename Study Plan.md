# Analysis Plan

## Study Design and Comparison

This is a retrospective pre–post cohort study evaluating changes in cardiometabolic outcomes before and after exposure to glucagon-like peptide-1 receptor agonists (GLP-1 RA) in the postpartum period. Each participant serves as her own control, with outcomes compared between baseline (pre-GLP-1 initiation) and follow-up measurements obtained within 12 months following delivery.

---

## Outcomes

### Primary Outcomes

- Change in maternal weight (kg) from baseline to follow-up within 12 months postpartum [numeric]
- >10% change in maternal weight from baseline to follow-up within 12 months postpartum [categorical; yes/no]
- Difference between pregnancy and last postpartum weight (postpartum − pre-pregnancy weight; pre-pregnancy defined as weight prior to 20 weeks gestation) <4 kg [categorical; yes/no]
- Change in systolic blood pressure (SBP) from baseline to follow-up [numeric]
- Reduction in SBP >10 mmHg [categorical; yes/no]
- Change in diastolic blood pressure (DBP) from baseline to follow-up [numeric]
- Reduction in DBP >5 mmHg [categorical; yes/no]

### Secondary Outcomes

- Change in total cholesterol [numeric]  
- Change in LDL cholesterol [numeric]  
- Change in HDL cholesterol [numeric]  
- Change in triglycerides [numeric]  
- Change in HbA1c [numeric]  
- Change in estimated glomerular filtration rate (eGFR) [numeric]  

---

## Descriptive Statistics

Baseline demographic and clinical characteristics will be summarized using descriptive statistics. Continuous variables will be reported as medians with interquartile ranges (IQR), and categorical variables as counts and percentages.

---

## Analytical Considerations

### Overall Objective

To evaluate how postpartum GLP-1 therapy influences maternal blood pressure and weight within 12 months postpartum by:

- Quantifying continuous changes in SBP, DBP, and weight before vs. after GLP-1 initiation  
- Measuring time to clinically meaningful improvements:
  - ≥10 mmHg reduction in SBP  
  - ≥5 mmHg reduction in DBP  
  - >10% weight loss from baseline  

---

## Time Zero Definition

GLP-1 initiation will serve as time zero for outcome analyses. This anchors each patient’s follow-up to the start of therapy.

- Observation begins at GLP-1 initiation date (e.g., semaglutide start)
- Follow-up is restricted to the postpartum period (≤12 months after delivery)
- Outcomes are censored at 12 months postpartum

---

## Baseline Definition

Baseline values for weight and blood pressure are defined as the last available measurement prior to or at GLP-1 initiation.

- If GLP-1 is started at 5 months postpartum, baseline values are taken from that visit or the most recent prior visit within a clinically reasonable window (up to 6 months pre-initiation, but still within postpartum period)
- All changes are calculated relative to this baseline

---

## Postpartum Follow-up Window

Follow-up is restricted to 12 months postpartum to focus on short-term postpartum effects.

- Patients starting GLP-1 late in the postpartum period will have truncated follow-up
- Patients without post-initiation follow-up measurements within the postpartum window will be excluded from longitudinal analyses or contribute only baseline data

---

## Modeling Continuous Outcomes

Continuous outcomes (SBP, DBP, weight) will be analyzed using linear mixed-effects models (LMMs) to account for:

- Unequal follow-up times  
- Repeated measurements  
- Missing data  

Results will be reported as mean/median change over time with 95% confidence intervals.

---

## Time-to-Event Analyses

We will perform survival analyses for clinically meaningful improvements:

- ≥10 mmHg reduction in SBP  
- ≥5 mmHg reduction in DBP  
- >10% weight loss from baseline  

### Event Definitions

- **SBP event:** First visit with SBP ≥10 mmHg lower than baseline  
- **DBP event:** First visit with DBP ≥5 mmHg lower than baseline  
- **Weight event:** First visit with >10% reduction from baseline weight  

### Censoring

Patients will be censored at:
- Last available follow-up within 12 months postpartum, or  
- 12 months postpartum (whichever occurs first)

---

## Survival Analysis

### Kaplan–Meier Analysis

- Estimate cumulative incidence of:
  - ≥10% weight loss  
  - SBP and DBP improvements over time  

- Time origin: GLP-1 initiation  

Stratified analyses will include:
- Early initiation (<6 months postpartum) vs late initiation (≥6 months)  
- Age group (<35 vs ≥35 years)  
- Gravidity (1 vs ≥2)  
- Parity (1 vs ≥2)  

### Reported Outcomes

- Median time to ≥10% weight loss  
- Proportion achieving outcomes at 12 months  
- Example: “By 3 months post-GLP-1, 20% achieved ≥10 mmHg SBP reduction; by 12 months, 60% did.”

### Cox Proportional Hazards Models

- Assess predictors of achieving weight and BP improvement
- Report hazard ratios for:
  - Timing of GLP-1 initiation  
  - Baseline BMI  
  - Reproductive history variables