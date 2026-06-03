# Notes on Weight-Loss Time-to-Event Analysis and Proportional Hazards Assessment

## Dataset Structure

The final analysis dataset (`analysis_df`) contains 704 patients and 248 variables. The dataset is structured with one row per patient, making it suitable for patient-level survival analyses.

Relevant variables for the weight-loss time-to-event analyses include:

* `wt_event`: Indicator for achieving the predefined weight-loss event (>10% weight loss).
* `wt_tte`: Time-to-event (days) among patients who achieved the event.
* `wt_fu`: Follow-up time (days) among patients who did not achieve the event (censored observations).
* `glp1_timing_cat`: Four-level postpartum GLP-1 initiation timing variable (<6 weeks, 6 weeks–3 months, 3–6 months, >6 months).
* `glp1_timing_2cat`: Primary analysis grouping:

  * Early initiation (<6 months postpartum)
  * Late initiation (≥6 months postpartum)

The dataset contains 704 unique patients with no duplicate patient identifiers.

## Event Availability

Among 704 patients:

* 98 patients achieved the weight-loss event.
* 513 patients were censored.
* 93 patients have missing weight-event information and are excluded from survival analyses.

The resulting survival analysis population contains 611 patients and 98 events.

## Preliminary Survival Analysis Findings

A preliminary Cox proportional hazards model was fit using:

Surv(wt_time, wt_event) ~ glp1_timing_2cat

where:

* Event time = `wt_tte` for patients with events.
* Follow-up time = `wt_fu` for censored patients.

Results:

* Hazard Ratio (Late vs Early): 1.61
* 95% CI: 0.94–2.77
* p = 0.086

## Proportional Hazards Assumption

One of the primary concerns raised by the PI was that early postpartum GLP-1 initiators may accumulate weight-loss events more rapidly simply because they have been exposed to therapy for a longer period of time.

This concern appears justified based on the current data.

Observed follow-up by exposure group:

| Group             | N   | Events | Event Rate | Median Follow-up |
| ----------------- | --- | ------ | ---------- | ---------------- |
| Early (<6 months) | 297 | 77     | 28.1%      | 166 days         |
| Late (≥6 months)  | 407 | 21     | 6.2%       | 38 days          |

The large difference in follow-up duration suggests that event accumulation may differ substantially over time between groups.

## Preliminary PH Testing

The proportional hazards assumption was evaluated using Schoenfeld residuals (`cox.zph`).

Results:

* Exposure variable p = 0.049
* Global test p = 0.049

These findings suggest borderline evidence of proportional hazards violation.

## Recommended Next Steps

The following analyses are recommended before finalizing the manuscript:

1. Generate log-log survival plots for visual assessment of proportional hazards.
2. Review Schoenfeld residual plots to determine the pattern and magnitude of PH violation.
3. Report the PH testing results in the Methods and/or Supplementary Material.
4. Perform a Restricted Mean Survival Time (RMST) analysis as a sensitivity analysis if PH violation persists.
5. Consider a time-stratified or time-varying Cox model if non-proportionality is substantial.
6. Consider landmark analyses (e.g., restricting to patients with adequate follow-up duration) to address the marked follow-up imbalance between early and late initiators.

## Additional Data Quality Checks

A small number of observations have weight-event times equal to 0 days and should be reviewed to confirm that these represent valid same-day measurements rather than data-processing artifacts.

Further exploration of the distribution of follow-up time by exposure group is also recommended.
