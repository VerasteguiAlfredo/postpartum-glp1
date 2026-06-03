## Fig 2
### Median time-to-event by outcome and stratum

### Median time-to-event by outcome and stratum

|        |Outcome                  |   N| Events|Overall (months) |Early (months) |Late (months) |
|:-------|:------------------------|---:|------:|:----------------|:--------------|:-------------|
|median  |A1: >=10% weight loss    | 611|     98|7.8              |8.3            |5.2           |
|median1 |A2: >=20% weight loss    | 611|     22|NR               |NR             |NR            |
|median2 |A3: Pre-pregnancy weight | 577|    250|3.9              |4.4            |3.2           |


### Cumulative incidence at landmark timepoints (overall)

|Outcome                  | Month| At risk| Events|Cum. incidence (%) |95% CI    |
|:------------------------|-----:|-------:|------:|:------------------|:---------|
|A1: >=10% weight loss    |     3|     259|     21|6.3                |3.6-8.9   |
|                         |     6|      86|     61|38.5               |31.0-45.1 |
|A2: >=20% weight loss    |     3|     272|      1|0.3                |0.0-0.8   |
|                         |     6|     113|      7|4.6                |1.3-7.7   |
|A3: Pre-pregnancy weight |     3|     175|    179|39.7               |34.7-44.4 |
|                         |     6|      51|     59|65.0               |58.6-70.4 |


### Log-rank test (Early vs Late)

|Outcome                  | Log-rank chi-sq| df|p-value |
|:------------------------|---------------:|--:|:-------|
|A1: >=10% weight loss    |            2.98|  1|0.084   |
|A2: >=20% weight loss    |            0.00|  1|0.968   |
|A3: Pre-pregnancy weight |            2.73|  1|0.099   |

## Fig 3
### Median time-to-event by outcome and stratum (HDP subgroup)

### Median time-to-event by outcome and stratum (HDP subgroup)

|        |Outcome                   |   N| Events|Overall (months) |Early (months) |Late (months) |
|:-------|:-------------------------|---:|------:|:----------------|:--------------|:-------------|
|median  |B1: >=5 mmHg SBP decline  | 366|    172|2.9              |3.2            |2.5           |
|median1 |B2: >=10 mmHg SBP decline | 366|    138|4.3              |4.6            |3.3           |
|median2 |B3: >=5 mmHg DBP decline  | 366|    157|3.3              |3.9            |2.5           |


### Cumulative incidence at landmark timepoints (HDP subgroup, overall)

|Outcome                   | Month| At risk| Events|Cum. incidence (%) |95% CI    |
|:-------------------------|-----:|-------:|------:|:------------------|:---------|
|B1: >=5 mmHg SBP decline  |     3|      95|    129|50.6               |43.9-56.6 |
|                          |     6|      25|     35|73.6               |65.8-79.6 |
|B2: >=10 mmHg SBP decline |     3|     113|     99|39.3               |32.8-45.1 |
|                          |     6|      35|     30|60.5               |52.0-67.4 |
|B3: >=5 mmHg DBP decline  |     3|      99|    115|46.3               |39.5-52.3 |
|                          |     6|      28|     33|69.9               |61.6-76.5 |


## Log-rank test, Early vs Late (HDP subgroup)

|Outcome                   | Log-rank chi-sq| df|p-value |
|:-------------------------|---------------:|--:|:-------|
|B1: >=5 mmHg SBP decline  |            3.69|  1|0.055   |
|B2: >=10 mmHg SBP decline |            2.09|  1|0.148   |
|B3: >=5 mmHg DBP decline  |            7.06|  1|0.008   |

## Fig 4
--- Extracted hazard ratios (Late vs Early) ---
               Outcome events   n    un_hr        un_p    ad_hr       ad_p
     >=10% weight loss     98 611 1.609889 0.085703943 1.599864 0.11167912
     >=20% weight loss     22 611 1.047770 0.967926494 1.226231 0.86468696
  Pre-pregnancy weight    250 577 1.230647 0.130406751 1.224962 0.15632318
  >=5 mmHg SBP decline    172 366 1.372996 0.055637688 1.374850 0.06517067
 >=10 mmHg SBP decline    138 366 1.309681 0.150157092 1.348318 0.12232809
  >=5 mmHg DBP decline    157 366 1.591313 0.008417128 1.585895 0.01130976


## Fig 5
 FIGURE 5 SAVED (600 dpi) — outcome: A1 ( >=10% weight loss )
================================================================
  Figure5A_swimmer_delivery_A1.png / .pdf
  Figure5B_swimmer_drug_A1.png / .pdf
To swap outcomes, change OUTCOME at top (A1/A2/A3/B1/B2/B3) and re-run.
Location: /Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1/Results/Analysis/Figures 


## Sample composition — A1 ( >=10% weight loss )

|Stratum                       | Plotted (n)| Events| Censored|    Event rate (%)|
|:-----------------------------|-----------:|------:|--------:|-----------------:|
|Early (< 6 months)            |          97|     77|       20|              79.4|
|Late (>= 6 months)            |          41|     21|       20|              51.2|
|Total (plotted / full cohort) |         138|     98|       40| 71.0 (full: 16.0)|

Full cohort: 611 patients (98 events). Plotted: 138 patients.


## Timeline summary by stratum — median (IQR), months

|Stratum            |  n|Delivery to GLP-1 (months) |Time-to-event (months) |Total PP follow-up (months) |
|:------------------|--:|:--------------------------|:----------------------|:---------------------------|
|Early (< 6 months) | 97|3.6 (2.5-4.6)              |4.6 (3.1-6.0)          |8.6 (6.4-10.0)              |
|Late (>= 6 months) | 41|7.5 (6.9-8.8)              |2.8 (1.0-3.8)          |10.7 (9.4-11.4)             |


## Event vs censored — timeline comparison (months)

|Status   |  n|Delivery to GLP-1 (months) |Time on drug to endpoint (months) |
|:--------|--:|:--------------------------|:---------------------------------|
|Censored | 40|6.0 (3.1-8.5)              |1.9 (0.0-4.1)                     |
|Event    | 98|4.3 (2.6-5.6)              |4.4 (3.2-5.9)                     |
