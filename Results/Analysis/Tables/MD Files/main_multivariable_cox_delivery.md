# Multivariable Cox models (delivery-anchored)

_Reference: Late (>= 6 mo) initiators. HR > 1 = Early initiators reach
the outcome faster than Late._

## A1: >=10% weight loss

|Variable                         |      HR (95% CI)| p-value|
|:--------------------------------|----------------:|-------:|
|GLP-1 timing: Early (< 6 months) | 2.64 (2.00-3.47)|  <0.001|
|Age (years)                      | 1.01 (0.99-1.04)|   0.277|
|Delivery mode: Cesarean          | 1.27 (0.96-1.67)|   0.088|
|Delivery mode: Other             | 0.30 (0.07-1.24)|   0.096|
|Type 2 diabetes                  | 1.03 (0.72-1.49)|   0.857|
|Obesity (BMI ≥ 30)               | 0.44 (0.26-0.74)|   0.002|
|Obstructive sleep apnea          | 0.89 (0.53-1.50)|   0.668|

_Model: GLP-1 timing + pre-specified (T2DM, obesity, OSA) + univariate p<0.10 (current_age, delivery_mode_simple). Events = 236 / 698._

## A2: >=20% weight loss

|Variable                         |       HR (95% CI)| p-value|
|:--------------------------------|-----------------:|-------:|
|GLP-1 timing: Early (< 6 months) | 6.36 (3.41-11.88)|  <0.001|
|Age (years)                      |  1.04 (0.99-1.10)|   0.111|
|Delivery mode: Cesarean          |  1.37 (0.77-2.42)|   0.283|
|Delivery mode: Other             |   0.00 (0.00-Inf)|   0.996|
|Type 2 diabetes                  |  0.88 (0.42-1.84)|   0.727|
|Obesity (BMI ≥ 30)               |  0.23 (0.10-0.51)|  <0.001|
|Obstructive sleep apnea          |  0.70 (0.24-2.08)|   0.522|

_Model: GLP-1 timing + pre-specified (T2DM, obesity, OSA) + univariate p<0.10 (current_age, delivery_mode_simple). Events = 56 / 698._

## A3: Return to pre-pregnancy weight

|Variable                         |      HR (95% CI)| p-value|
|:--------------------------------|----------------:|-------:|
|GLP-1 timing: Early (< 6 months) | 1.23 (0.99-1.54)|   0.063|
|Parity: Multiparous              | 1.50 (1.16-1.95)|   0.002|
|Delivery mode: Cesarean          | 0.84 (0.67-1.05)|   0.125|
|Delivery mode: Other             | 0.45 (0.17-1.23)|   0.120|
|Type 2 diabetes                  | 1.19 (0.88-1.62)|   0.256|
|Obesity (BMI ≥ 30)               | 0.98 (0.58-1.65)|   0.937|
|Obstructive sleep apnea          | 0.98 (0.63-1.51)|   0.918|

_Model: GLP-1 timing + pre-specified (T2DM, obesity, OSA) + univariate p<0.10 (parity_cat, delivery_mode_simple). Events = 355 / 628._

## B1: >=5 mmHg SBP decline (HDP)

|Variable                         |      HR (95% CI)| p-value|
|:--------------------------------|----------------:|-------:|
|GLP-1 timing: Early (< 6 months) | 1.20 (0.97-1.49)|   0.093|
|Type 2 diabetes                  | 1.07 (0.82-1.41)|   0.612|
|Obesity (BMI ≥ 30)               | 0.88 (0.52-1.50)|   0.642|
|Obstructive sleep apnea          | 1.03 (0.71-1.51)|   0.871|
|Baseline antihypertensive use    | 1.24 (0.99-1.56)|   0.059|

_Model: GLP-1 timing + pre-specified (T2DM, obesity, OSA) + univariate p<0.10 (bp_med_any). Events = 368 / 430._

## B2: >=10 mmHg SBP decline (HDP)

|Variable                         |      HR (95% CI)| p-value|
|:--------------------------------|----------------:|-------:|
|GLP-1 timing: Early (< 6 months) | 1.19 (0.95-1.49)|   0.130|
|Type 2 diabetes                  | 1.04 (0.79-1.38)|   0.772|
|Obesity (BMI ≥ 30)               | 0.72 (0.42-1.22)|   0.219|
|Obstructive sleep apnea          | 1.09 (0.74-1.60)|   0.677|
|Baseline antihypertensive use    | 1.30 (1.02-1.64)|   0.031|

_Model: GLP-1 timing + pre-specified (T2DM, obesity, OSA) + univariate p<0.10 (bp_med_any). Events = 339 / 430._

## B3: >=5 mmHg DBP decline (HDP)

|Variable                         |      HR (95% CI)| p-value|
|:--------------------------------|----------------:|-------:|
|GLP-1 timing: Early (< 6 months) | 1.14 (0.88-1.46)|   0.323|
|Type 2 diabetes                  | 1.07 (0.79-1.46)|   0.669|
|Obesity (BMI ≥ 30)               | 0.48 (0.28-0.83)|   0.008|
|Obstructive sleep apnea          | 1.50 (0.99-2.28)|   0.057|

_Model: GLP-1 timing + pre-specified (T2DM, obesity, OSA). Events = 273 / 430._

