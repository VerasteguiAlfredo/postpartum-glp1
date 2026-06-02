# postpartum-glp1 — Revised Analysis Plan
### In response to PI feedback (Adedinsewo DA) on Tables 3 / 3a
---

## Overview of Changes

The PI has fundamentally restructured the primary analysis from a
cross-sectional snapshot approach (median delta at fixed timepoints) to a
**time-to-event (survival) framework**. This is the right call for a
high-impact journal — KM curves with Cox PH are far more compelling and
interpretable than a table of medians across 4 timing subgroups.

Tables 3 and 3a in their current form are **retired as primary tables**.
They may survive as supplementary material.

---

## What We Are Keeping

| Item | Status | Notes |
|---|---|---|
| Table 1 (demographics) | ✅ Keep as-is | Finalized |
| Table 2 (GLP-1 exposure) | ✅ Keep as-is | Finalized with dual BP threshold |
| Table 3 (snapshot outcomes) | ⬇️ Demote to Supplement | Too many subgroups for main text |
| Table 3a (GLP-1-anchored) | ⬇️ Demote to Supplement | Useful sensitivity, not primary |

---

## Predictor Restructuring

**Old:** 4-level timing (`< 6wk / 6wk-3mo / 3-6mo / > 6mo`)  
**New:** 2-level timing (`< 6 months postpartum` vs `>= 6 months postpartum`)

This collapses your existing `glp1_timing_cat` into a new binary variable
`glp1_timing_2cat` (may already exist in `analysis_df` — confirm).
All survival models use this as the primary predictor.

---

## Follow-up Window

- Extend to **18 months postpartum** if ≥ ~50% of patients have vitals
  data at that window (check n before committing).
- If sparse at 18 months, censor at 12 months for all — do not use
  inconsistent censoring across patients.
- **Action item before coding:** run a quick attrition check:
```r
  analysis_df %>%
    summarise(
      n_any_vital_18m = sum(!is.na(sbp_m18_pp) | !is.na(weight_kg_m18_pp)),
      pct = mean(!is.na(sbp_m18_pp) | !is.na(weight_kg_m18_pp)) * 100
    )
```
  If n < 200 or pct < 30%, keep 12 months.

---

## Primary Analysis A — Weight (Full Cohort, N = 704)

**Anchor:** Weight recorded at or closest to delivery date (baseline).  
**Outcome:** Time (days from delivery) to threshold weight loss event.  
**Predictor:** GLP-1 start time (< 6mo vs >= 6mo postpartum).

| Analysis | Event Definition | Cohort |
|---|---|---|
| A1 | Time to ≥10% decline from delivery weight | All N = 704 |
| A2 | Time to ≥20% decline from delivery weight | All N = 704 |
| A3 | Time to reach pre-pregnancy weight | Subgroup with pre-pregnancy weight documented |

### For each of A1–A3, produce:

1. **KM curve (overall)** — single curve with median time-to-event + 95% CI
2. **KM curve (stratified)** — early vs late initiators, log-rank p-value
3. **Cox PH model (unadjusted)** — HR (95% CI) for GLP-1 timing
4. **Cox PH model (adjusted)** — adjust for: age, baseline BMI, parity,
   delivery mode, T2DM, GDM, GLP-1 agent (semaglutide vs other),
   GLP-1 persistence

### New Table: Table 3 (revised) — Cox PH Results, Weight Outcomes

| Outcome | n events / N at risk | Median time to event (95% CI) | Log-rank p | HR unadj (95% CI) | HR adj (95% CI) |
|---|---|---|---|---|---|
| ≥10% weight loss | | | | | |
| — Early (< 6mo) | | | | | |
| — Late (>= 6mo) | | | | | |
| ≥20% weight loss | | | | | |
| — Early (< 6mo) | | | | | |
| — Late (>= 6mo) | | | | | |
| Pre-preg weight | | | | | |
| — Early (< 6mo) | | | | | |
| — Late (>= 6mo) | | | | | |

---

## Primary Analysis B — Blood Pressure (HDP Subgroup)

**Subgroup:** Patients with HDP OR SBP ≥ 140 / DBP ≥ 90 at delivery  
**Expected N:** ~430 (61% of 704 flagged as HDP — confirm overlap with
BP ≥ 140/90 at delivery to get exact denominator).  
**Anchor:** First postpartum BP measurement (or delivery BP if available).  
**Predictor:** GLP-1 start time (< 6mo vs >= 6mo postpartum).  
**Key covariate:** Antihypertensive therapy — treat as time-varying covariate
if start/stop dates are available (preferred), or as baseline binary if not.

| Analysis | Event Definition | Cohort |
|---|---|---|
| B1 | Time to ≥5 mmHg decline in SBP | HDP subgroup |
| B2 | Time to ≥10 mmHg decline in SBP | HDP subgroup |
| B3 | Time to ≥5 mmHg decline in DBP | HDP subgroup |

### For each of B1–B3, produce:

1. **KM curve (overall)** — single curve with median time-to-event + 95% CI
2. **KM curve (stratified)** — early vs late initiators, log-rank p-value
3. **Cox PH model (unadjusted)** — HR (95% CI) for GLP-1 timing
4. **Cox PH model (adjusted)** — adjust for: age, baseline BMI, type of HDP
   (gestational HTN vs preeclampsia), T2DM, GDM, GLP-1 agent,
   antihypertensive use (time-varying or baseline binary)

### New Table: Table 4 (new) — Cox PH Results, BP Outcomes (HDP Subgroup)

| Outcome | n events / N at risk | Median time to event (95% CI) | Log-rank p | HR unadj (95% CI) | HR adj (95% CI) |
|---|---|---|---|---|---|
| SBP ≥5 mmHg drop | | | | | |
| — Early (< 6mo) | | | | | |
| — Late (>= 6mo) | | | | | |
| SBP ≥10 mmHg drop | | | | | |
| — Early (< 6mo) | | | | | |
| — Late (>= 6mo) | | | | | |
| DBP ≥5 mmHg drop | | | | | |
| — Early (< 6mo) | | | | | |
| — Late (>= 6mo) | | | | | |

---

## Recommended Figure Set (High-Impact Journal)

### Figure 1 — Study Flow / Cohort Diagram
- CONSORT-style attrition diagram
- Start: all postpartum patients in DataMart → GLP-1 users → met
  inclusion criteria → final analytic cohort (N = 704)
- Annotate HDP subgroup (N ≈ 430) as a box branching from the main cohort
- **Format:** SVG or high-res PNG, single panel

### Figure 2 — KM Curves: Weight Outcomes (3-panel)
- Panel A: Time to ≥10% weight loss (overall + stratified)
- Panel B: Time to ≥20% weight loss (overall + stratified)
- Panel C: Time to pre-pregnancy weight (subgroup, overall + stratified)
- Each panel: KM curves for early vs late, shaded 95% CI, number-at-risk
  table below x-axis, log-rank p in upper right
- **Format:** 3-panel figure, publication width (~180mm), color-blind safe
  palette (e.g., `#E69F00` / `#0072B2`)

### Figure 3 — KM Curves: BP Outcomes in HDP Subgroup (3-panel)
- Panel A: Time to SBP ≥5 mmHg drop
- Panel B: Time to SBP ≥10 mmHg drop
- Panel C: Time to DBP ≥5 mmHg drop
- Same formatting as Figure 2
- Add subtitle noting HDP subgroup definition

### Figure 4 — Forest Plot: Cox PH Hazard Ratios
- All 6 outcomes (A1, A2, A3, B1, B2, B3) in one forest plot
- Rows = outcomes, columns = unadjusted HR / adjusted HR
- Reference line at HR = 1.0
- Early initiators (< 6mo) as reference group
- This is the single most important figure for the abstract / central message
- **Format:** single panel, ~90mm wide (half-page column)

### Optional Figure 5 — Timeline Swimmer Plot (N = 50–100 random sample)
- One horizontal bar per patient
- Mark: delivery, GLP-1 start, weight/BP event (if achieved), censoring
- Stratified by early vs late, sorted by time-to-event
- Good for visual intuition; some journals love these for clinical papers

---

## Recommended Final Table Structure for Submission

| # | Table | Primary or Supplementary |
|---|---|---|
| Table 1 | Baseline demographics (overall + by GLP-1 timing 2-cat) | Primary |
| Table 2 | GLP-1 exposure characteristics (overall + dual BP threshold) | Primary |
| Table 3 | Cox PH results — weight outcomes (A1–A3) | Primary |
| Table 4 | Cox PH results — BP outcomes, HDP subgroup (B1–B3) | Primary |
| Supp Table 1 | Old Table 3 — snapshot outcomes at 3/6/12mo | Supplementary |
| Supp Table 2 | Old Table 3a — GLP-1-anchored sensitivity | Supplementary |
| Supp Table 3 | A3 pre-pregnancy weight subgroup characteristics | Supplementary |

---

## Coding Order / Next Steps
Step 1 — Data check
[ ] Confirm glp1_timing_2cat exists or derive it
[ ] Attrition check at 18 months → decide censoring window
[ ] Confirm pre-pregnancy weight availability (denominator for A3)
[ ] Confirm HDP subgroup N and overlap with BP ≥140/90 at delivery
[ ] Confirm antihypertensive start/stop dates available for time-varying covariate
Step 2 — Survival dataset construction
[ ] Build event/time variables for A1, A2, A3 (weight)
[ ] Build event/time variables for B1, B2, B3 (BP, HDP subgroup only)
[ ] Handle left-truncation if GLP-1 started > day 0
Step 3 — Tables 3 and 4 (Cox PH)
[ ] Unadjusted models
[ ] Adjusted models (confirm covariate list with PI)
[ ] Check PH assumption (Schoenfeld residuals, log-log plots)
Step 4 — Figures
[ ] Figure 1: consort flow (can do now)
[ ] Figure 2: KM weight (after Step 2)
[ ] Figure 3: KM BP (after Step 2)
[ ] Figure 4: forest plot (after Step 3)
[ ] Figure 5: swimmer plot (optional, last)