# Dataset Diagnostic Overview

**Study:** Postpartum GLP-1 Receptor Agonist Cohort

**Generated:**  2026-05-14 17:01:13 

**Datasets loaded:**  20 


---
# Summary Table

| Dataset | Rows | Cols | % Missing | ID Columns | Date Columns |
|---------|------|------|-----------|------------|--------------|
| alc_flow | 20956 | 24 | 18.6 | Assessment_ID, Fluid_Intake, Fluid_Output, Patient_Reported_Status | delv_date, Birth_Dt, Assessment_Date, Assessment_Time |
| alc_ppi | 15979 | 17 | 0.1 | Form_ID, Question_ID, Ans_Provided | delv_date, Birth_Dt, Ans_Dt |
| alc_sdoh | 5791 | 20 | 1 | PATIENT_FULL_NAME, SDOH_DATA_ID, SDOH_ENTRY_PROVIDER_DK, PROVIDER_LAST_NAME | delv_date, Birth_Dt, SDOH_CONTACT_DTM |
| alc_social | 146382 | 10 | 0 |  | delv_date, Birth_Dt, Social_Hx_DTM |
| bmi_flow | 107166 | 24 | 17.1 | Assessment_ID, Fluid_Intake, Fluid_Output, Patient_Reported_Status | delv_date, Birth_Dt, Assessment_Date, Assessment_Time |
| bp_flow | 139624 | 24 | 19.9 | Assessment_ID, Fluid_Intake, Fluid_Output, Patient_Reported_Status | delv_date, Birth_Dt, Assessment_Date, Assessment_Time |
| hr_flow | 106720 | 24 | 22.4 | Assessment_ID, Fluid_Intake, Fluid_Output, Patient_Reported_Status | delv_date, Birth_Dt, Assessment_Date, Assessment_Time |
| height_flow | 25484 | 24 | 16.8 | Assessment_ID, Fluid_Intake, Fluid_Output, Patient_Reported_Status | delv_date, Birth_Dt, Assessment_Date, Assessment_Time |
| weight_flow | 156133 | 24 | 16.9 | Assessment_ID, Fluid_Intake, Fluid_Output, Patient_Reported_Status | delv_date, Birth_Dt, Assessment_Date, Assessment_Time |
| cohort | 729 | 16 | 6.2 | Test_Patient | delv_date, Birth_Dt |
| demo | 729 | 8 | 24.7 |  | delv_date, Birth_Dt |
| dx | 314315 | 19 | 10.5 | Patient_Type, Dx_Servicing_Provider_Id | delv_date, Birth_Dt, Dx_Date |
| labs | 224910 | 31 | 5.9 |  | delv_date, Birth_Dt, Lab_Date, Lab_Time, Lab_Result_Date, Lab_Result_Time |
| ob | 1230 | 61 | 24.7 | PREGRAVID_BMI, PREGRAVID_WEIGHT_IN_OUNCES, GRAVIDITY | delv_date, Birth_Dt, INDUCTION_DTM, MEMBRANE_RUPTURE_DTM, DELIVERY_DTM, OB_DELIVERY_ADMIT_DTM, OB_DELIVERY_DISCHARGE_DTM, LAST_MATERNAL_BMI_DTM, LAST_MATERNAL_WEIGHT_DTM, LAST_MENSTRUAL_PERIOD_DTM, ULTRASOUND_DTM |
| smoking | 167209 | 11 | 9.1 |  | delv_date, Birth_Dt, tob_dt, tob_tm |
| ecg | 4783 | 29 | 11.7 |  | delv_date, Birth_Dt, ECG_Date, ECG_Time |
| echo_ef | 317 | 847 | 90 | procedure_id, visit_id, report_id, phase_id, RESEARCH_PROT_DEF_ID, STRESS_PROT_DEF_ID | birth_date, procedure_date, procedure_time |
| echo_dict | 26 | 2 | 0 |  |  |
| glp1_meds | 3834 | 40 | 13.1 | Order_ID, Ordering_Provider_Person_ID, Approving_Provider_Person_ID, Inpatient_Flag | delv_date, Birth_Dt, Order_Date, Order_Time, Order_Start_Date, Order_Start_Time, Order_Stop_Date, Order_Stop_Time |
| ord_meds | 132819 | 40 | 14.2 | Order_ID, Ordering_Provider_Person_ID, Approving_Provider_Person_ID, Inpatient_Flag | delv_date, Birth_Dt, Order_Date, Order_Time, Order_Start_Date, Order_Start_Time, Order_Stop_Date, Order_Stop_Time |


---

# Dataset: `alc_flow`

## Dimensions
- Rows: 20956
- Columns: 24

## Column Types
character x 14,  logical x 4,  numeric x 2,  POSIXct x 4

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Assessment_Date, Assessment_Time, Assessment_ID, Assessment_Name, Assessment_Type_Description, Fluid_Intake, Fluid_Output, Device_Type, Document_Source, Patient_Reported_Status, Service_Type, Assessment_Subtype_Desc, Assessment_Subtype_Code, Result, Result_Units, Encounter_Nbr, Source, Site, Site_Name, Site_State`

## ID-like Columns
  Assessment_ID: 78 unique values
  Fluid_Intake: 0 unique values
  Fluid_Output: 0 unique values
  Patient_Reported_Status: 2 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Assessment_Date: 2018-01-03 to 2026-03-07
  Assessment_Time: 1899-12-31 to 1899-12-31 23:58:01


## Missing Values (columns with any NA)
  Fluid_Intake: 20956 (100%)
  Fluid_Output: 20956 (100%)
  Device_Type: 20956 (100%)
  Result_Units: 20956 (100%)
  Patient_Reported_Status: 8601 (41%)
  Site_State: 675 (3.2%)
  Document_Source: 159 (0.8%)
  Site: 34 (0.2%)
  Site_Name: 34 (0.2%)
  Result: 11 (0.1%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             20956 
Number of columns          24    
_______________________          
Column type frequency:           
  character                14    
  logical                  4     
  numeric                  2     
  POSIXct                  4     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable               n_missing complete_rate min max empty n_unique
 1 Assessment_ID                       0         1       5  10     0       78
 2 Assessment_Name                     0         1       7 210     0       75
 3 Assessment_Type_Description         0         1       4  31     0        7
 4 Document_Source                   159         0.992   9  43     0       11
 5 Patient_Reported_Status          8601         0.590  37  41     0        2
 6 Service_Type                        0         1       6 192     0       76
 7 Assessment_Subtype_Desc             0         1       7 224     0       81
 8 Assessment_Subtype_Code             0         1       5  10     0       78
 9 Result                             11         0.999   1  29     0       43
10 Encounter_Nbr                       0         1       9  13     0     5814
11 Source                              0         1       4  24     0        2
12 Site                               34         0.998   3   5     0        4
13 Site_Name                          34         0.998   4  20     0        4
14 Site_State                        675         0.968   2   7     0        4
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate mean count
1 Fluid_Intake      20956             0  NaN ": " 
2 Fluid_Output      20956             0  NaN ": " 
3 Device_Type       20956             0  NaN ": " 
4 Result_Units      20956             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8368771.  2869439.   3502573 6089757
2 current_age           0             1      32.5       5.52      19      29
      p50     p75     p100 hist 
1 8480775 9715284 14840800 ▅▃▇▂▃
2      32      36       54 ▃▇▆▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable   n_missing complete_rate min                
1 delv_date               0             1 2018-06-24 00:00:00
2 Birth_Dt                0             1 1970-09-13 00:00:00
3 Assessment_Date         0             1 2018-01-03 00:00:00
4 Assessment_Time         0             1 1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-06-04 00:00:00      564
2 2006-01-28 00:00:00 1992-04-06 00:00:00      673
3 2026-03-07 00:00:00 2023-04-28 00:00:00     2091
4 1899-12-31 23:58:01 1899-12-31 12:37:44     1863




---

# Dataset: `alc_ppi`

## Dimensions
- Rows: 15979
- Columns: 17

## Column Types
character x 11,  numeric x 3,  POSIXct x 3

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Ans_Dt, Form_ID, Form_Name, Question_ID, Question_Text, Ans_Text, Ans_Value, Ans_Provided, Source, Site, Site_Name, Site_State, Location_Desc`

## ID-like Columns
  Form_ID: 48 unique values
  Question_ID: 129 unique values
  Ans_Provided: 2 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Ans_Dt: 2018-01-02 to 2026-03-06


## Missing Values (columns with any NA)
  Site_State: 154 (1%)
  Ans_Text: 17 (0.1%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             15979 
Number of columns          17    
_______________________          
Column type frequency:           
  character                11    
  numeric                  3     
  POSIXct                  3     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable n_missing complete_rate min max empty n_unique whitespace
 1 Form_ID               0         1       2  19     0       48          0
 2 Form_Name             0         1      13  98     0       48          0
 3 Question_ID           0         1       3  29     0      129          0
 4 Question_Text         0         1      12 265     0       88          0
 5 Ans_Text             17         0.999   1 217     0      246          0
 6 Ans_Provided          0         1       1   1     0        2          0
 7 Source                0         1       3   4     0        2          0
 8 Site                  0         1       3   5     0        5          0
 9 Site_Name             0         1       4  21     0        5          0
10 Site_State          154         0.990   2   2     0        4          0
11 Location_Desc         0         1      21  68     0      337          0

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8063688.  2807456.   3502573 5415380
2 current_age           0             1      33.0       5.55      19      29
3 Ans_Value             0             1    -105.     3260.    -99999       0
      p50     p75     p100 hist 
1 8192092 9458303 14840800 ▆▅▇▂▂
2      33      36       54 ▂▇▇▂▁
3       1       2      200 ▁▁▁▁▇

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate min                 max                
1 delv_date             0             1 2018-06-24 00:00:00 2025-12-23 00:00:00
2 Birth_Dt              0             1 1970-09-13 00:00:00 2006-01-28 00:00:00
3 Ans_Dt                0             1 2018-01-02 00:00:00 2026-03-06 00:00:00
  median              n_unique
1 2024-04-25 00:00:00      553
2 1991-08-24 00:00:00      658
3 2022-12-08 00:00:00     1845




---

# Dataset: `alc_sdoh`

## Dimensions
- Rows: 5791
- Columns: 20

## Column Types
character x 15,  numeric x 2,  POSIXct x 3

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, PATIENT_FULL_NAME, ENCOUNTER_NUMBER, SDOH_DATA_ID, SDOH_ENTRY_PROVIDER_DK, PROVIDER_LAST_NAME, SITE_NAME, SDOH_CONTACT_DTM, SDOH_DISPLAY_NAME, SDOH_DOMAIN_DK, SDOH_DOMAIN, SDOH_RULE_DK, SDOH_RULE_NAME, SDOH_ANSWER_VALUE, SDOH_ANSWER, SDOH_ENTRY_INTERPRETATION_EXTERN, SDOH_CONCERNS_PRESENT_YN`

## ID-like Columns
  PATIENT_FULL_NAME: 607 unique values
  SDOH_DATA_ID: 608 unique values
  SDOH_ENTRY_PROVIDER_DK: 107 unique values
  PROVIDER_LAST_NAME: 106 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-22
  Birth_Dt: 1970-09-13 to 2005-12-16
  SDOH_CONTACT_DTM: 2019-06-04 to 2023-05-25


## Missing Values (columns with any NA)
  SITE_NAME: 1205 (20.8%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             5791  
Number of columns          20    
_______________________          
Column type frequency:           
  character                15    
  numeric                  2     
  POSIXct                  3     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable                    n_missing complete_rate min max empty
 1 PATIENT_FULL_NAME                        0         1       8  34     0
 2 ENCOUNTER_NUMBER                         0         1       6  13     0
 3 SDOH_DATA_ID                             0         1       5   9     0
 4 SDOH_ENTRY_PROVIDER_DK                   0         1       6  13     0
 5 PROVIDER_LAST_NAME                       0         1       3  13     0
 6 SITE_NAME                             1205         0.792   4  20     0
 7 SDOH_DISPLAY_NAME                        0         1      11  11     0
 8 SDOH_DOMAIN_DK                           0         1       7   7     0
 9 SDOH_DOMAIN                              0         1      11  11     0
10 SDOH_RULE_DK                             0         1      11  11     0
11 SDOH_RULE_NAME                           0         1      36  42     0
12 SDOH_ANSWER_VALUE                        0         1       1   2     0
13 SDOH_ANSWER                              0         1       5  22     0
14 SDOH_ENTRY_INTERPRETATION_EXTERN         0         1       7  14     0
15 SDOH_CONCERNS_PRESENT_YN                 0         1       1   1     0
   n_unique whitespace
 1      607          0
 2     1861          0
 3      608          0
 4      107          0
 5      106          0
 6        4          0
 7        1          0
 8        1          0
 9        1          0
10        3          0
11        3          0
12        8          0
13       17          0
14        3          0
15        2          0

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8057164.  2583491.   3502573 6042092
2 current_age           0             1      33.1       5.26      19      29
      p50      p75     p100 hist 
1 8419660 9529590. 13960737 ▅▃▇▂▃
2      33      36        54 ▂▇▇▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable    n_missing complete_rate min                
1 delv_date                0             1 2018-06-24 00:00:00
2 Birth_Dt                 0             1 1970-09-13 00:00:00
3 SDOH_CONTACT_DTM         0             1 2019-06-04 00:00:00
  max                 median              n_unique
1 2025-12-22 00:00:00 2024-02-24 00:00:00      510
2 2005-12-16 00:00:00 1991-08-17 00:00:00      588
3 2023-05-25 00:00:00 2021-12-29 00:00:00      980




---

# Dataset: `alc_social`

## Dimensions
- Rows: 146382
- Columns: 10

## Column Types
character x 4,  numeric x 3,  POSIXct x 3

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Social_Hx_DTM, ENCOUNTER_NBR, Social_Hx_NAME, Social_Hx_Name_Abbr, Social_Hx_Answer, Source`

## ID-like Columns
  (none detected)


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Social_Hx_DTM: 2018-01-01 to 2026-03-08


## Missing Values (columns with any NA)
  (none)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             146382
Number of columns          10    
_______________________          
Column type frequency:           
  character                4     
  numeric                  3     
  POSIXct                  3     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
  skim_variable       n_missing complete_rate min max empty n_unique whitespace
1 Social_Hx_NAME              0             1  14  35     0       10          0
2 Social_Hx_Name_Abbr         0             1  13  24     0       10          0
3 Social_Hx_Answer            0             1   1 169     0      679          0
4 Source                      0             1   4   4     0        1          0

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate    mean           sd            p0
1 CURR_CLINIC           0             1 8.24e 6   2540829.         3502573
2 current_age           0             1 3.28e 1         5.45            19
3 ENCOUNTER_NBR         0             1 2.00e12 151146764.   2000098726804
            p25           p50           p75          p100 hist 
1       6342919       8480775       9538280      14840800 ▃▃▇▂▂
2            29            33            36            54 ▂▇▇▂▁
3 2000358371801 2000469757033 2000611859263 2000763127294 ▁▇▇▇▆

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate min                 max                
1 delv_date             0             1 2018-06-24 00:00:00 2025-12-23 00:00:00
2 Birth_Dt              0             1 1970-09-13 00:00:00 2006-01-28 00:00:00
3 Social_Hx_DTM         0             1 2018-01-01 00:00:00 2026-03-08 00:00:00
  median              n_unique
1 2024-04-04 00:00:00      565
2 1991-10-11 00:00:00      676
3 2022-04-13 00:00:00     2938




---

# Dataset: `bmi_flow`

## Dimensions
- Rows: 107166
- Columns: 24

## Column Types
character x 14,  logical x 4,  numeric x 2,  POSIXct x 4

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Assessment_Date, Assessment_Time, Assessment_ID, Assessment_Name, Assessment_Type_Description, Fluid_Intake, Fluid_Output, Device_Type, Document_Source, Patient_Reported_Status, Service_Type, Assessment_Subtype_Desc, Assessment_Subtype_Code, Result, Result_Units, Encounter_Nbr, Source, Site, Site_Name, Site_State`

## ID-like Columns
  Assessment_ID: 16 unique values
  Fluid_Intake: 0 unique values
  Fluid_Output: 0 unique values
  Patient_Reported_Status: 0 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Assessment_Date: 2018-01-01 to 2026-03-08
  Assessment_Time: 1899-12-31 to 1899-12-31 23:59:00


## Missing Values (columns with any NA)
  Fluid_Intake: 107166 (100%)
  Fluid_Output: 107166 (100%)
  Device_Type: 107166 (100%)
  Patient_Reported_Status: 107166 (100%)
  Result_Units: 10546 (9.8%)
  Document_Source: 1094 (1%)
  Result: 203 (0.2%)
  Site: 165 (0.2%)
  Site_Name: 165 (0.2%)
  Site_State: 39 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             107166
Number of columns          24    
_______________________          
Column type frequency:           
  character                14    
  logical                  4     
  numeric                  2     
  POSIXct                  4     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable               n_missing complete_rate min max empty n_unique
 1 Assessment_ID                       0         1       4  10     0       16
 2 Assessment_Name                     0         1       3  41     0        9
 3 Assessment_Type_Description         0         1      11  33     0       11
 4 Document_Source                  1094         0.990   9  37     0       12
 5 Service_Type                        0         1       5  62     0       15
 6 Assessment_Subtype_Desc             0         1       3  50     0        8
 7 Assessment_Subtype_Code             0         1       4  10     0       16
 8 Result                            203         0.998   1  38     0     3269
 9 Result_Units                    10546         0.902   5   5     0        4
10 Encounter_Nbr                       0         1       7  13     0    19310
11 Source                              0         1       4  24     0        3
12 Site                              165         0.998   3   5     0        5
13 Site_Name                         165         0.998   4  21     0        5
14 Site_State                         39         1.000   2   7     0        5
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable           n_missing complete_rate mean count
1 Fluid_Intake               107166             0  NaN ": " 
2 Fluid_Output               107166             0  NaN ": " 
3 Device_Type                107166             0  NaN ": " 
4 Patient_Reported_Status    107166             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8376416.  2692233.   3502573 6331633
2 current_age           0             1      32.5       5.58      19      29
      p50     p75     p100 hist 
1 8500729 9647570 14840800 ▃▃▇▂▂
2      33      36       54 ▃▇▆▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable   n_missing complete_rate min                
1 delv_date               0             1 2018-06-24 00:00:00
2 Birth_Dt                0             1 1970-09-13 00:00:00
3 Assessment_Date         0             1 2018-01-01 00:00:00
4 Assessment_Time         0             1 1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-04-06 00:00:00      565
2 2006-01-28 00:00:00 1992-02-22 00:00:00      676
3 2026-03-08 00:00:00 2023-06-21 00:00:00     2648
4 1899-12-31 23:59:00 1899-12-31 11:32:00     1601




---

# Dataset: `bp_flow`

## Dimensions
- Rows: 139624
- Columns: 24

## Column Types
character x 16,  logical x 2,  numeric x 2,  POSIXct x 4

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Assessment_Date, Assessment_Time, Assessment_ID, Assessment_Name, Assessment_Type_Description, Fluid_Intake, Fluid_Output, Device_Type, Document_Source, Patient_Reported_Status, Service_Type, Assessment_Subtype_Desc, Assessment_Subtype_Code, Result, Result_Units, Encounter_Nbr, Source, Site, Site_Name, Site_State`

## ID-like Columns
  Assessment_ID: 56 unique values
  Fluid_Intake: 0 unique values
  Fluid_Output: 0 unique values
  Patient_Reported_Status: 1 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Assessment_Date: 2017-07-19 to 2026-03-08
  Assessment_Time: 1899-12-31 to 1899-12-31 23:59:00


## Missing Values (columns with any NA)
  Fluid_Intake: 139624 (100%)
  Fluid_Output: 139624 (100%)
  Patient_Reported_Status: 138086 (98.9%)
  Device_Type: 114642 (82.1%)
  Result_Units: 68780 (49.3%)
  Document_Source: 63989 (45.8%)
  Site: 826 (0.6%)
  Site_Name: 826 (0.6%)
  Result: 603 (0.4%)
  Site_State: 560 (0.4%)
  Encounter_Nbr: 546 (0.4%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             139624
Number of columns          24    
_______________________          
Column type frequency:           
  character                16    
  logical                  2     
  numeric                  2     
  POSIXct                  4     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable               n_missing complete_rate min max empty n_unique
 1 Assessment_ID                       0        1        1  11     0       56
 2 Assessment_Name                     0        1        2 156     0       51
 3 Assessment_Type_Description         0        1       11  33     0        9
 4 Device_Type                    114642        0.179    8  50     0      126
 5 Document_Source                 63989        0.542    8  44     0       23
 6 Patient_Reported_Status        138086        0.0110  41  41     0        1
 7 Service_Type                        0        1        6 125     0       53
 8 Assessment_Subtype_Desc             0        1        2 156     0       51
 9 Assessment_Subtype_Code             0        1        1  11     0       56
10 Result                            603        0.996    1 119     0     6476
11 Result_Units                    68780        0.507    1   7     0        4
12 Encounter_Nbr                     546        0.996    9  13     0    20586
13 Source                              0        1        4  24     0        2
14 Site                              826        0.994    3   5     0        3
15 Site_Name                         826        0.994    4  20     0        3
16 Site_State                        560        0.996    2   7     0        3
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0
15          0
16          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate mean count
1 Fluid_Intake     139624             0  NaN ": " 
2 Fluid_Output     139624             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8567986.  2948346.   3502573 6288027
2 current_age           0             1      32.7       5.70      19      29
      p50     p75     p100 hist 
1 8581763 9944346 14840800 ▅▃▇▂▃
2      33      36       54 ▃▇▇▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable   n_missing complete_rate min                
1 delv_date               0             1 2018-06-24 00:00:00
2 Birth_Dt                0             1 1970-09-13 00:00:00
3 Assessment_Date         0             1 2017-07-19 00:00:00
4 Assessment_Time         0             1 1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-05-30 00:00:00      562
2 2006-01-28 00:00:00 1991-10-21 00:00:00      676
3 2026-03-08 00:00:00 2024-08-13 00:00:00     2374
4 1899-12-31 23:59:00 1899-12-31 12:02:00     2342




---

# Dataset: `hr_flow`

## Dimensions
- Rows: 106720
- Columns: 24

## Column Types
character x 16,  logical x 2,  numeric x 2,  POSIXct x 4

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Assessment_Date, Assessment_Time, Assessment_ID, Assessment_Name, Assessment_Type_Description, Fluid_Intake, Fluid_Output, Device_Type, Document_Source, Patient_Reported_Status, Service_Type, Assessment_Subtype_Desc, Assessment_Subtype_Code, Result, Result_Units, Encounter_Nbr, Source, Site, Site_Name, Site_State`

## ID-like Columns
  Assessment_ID: 21 unique values
  Fluid_Intake: 0 unique values
  Fluid_Output: 0 unique values
  Patient_Reported_Status: 1 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Assessment_Date: 2017-07-19 to 2026-03-08
  Assessment_Time: 1899-12-31 to 1899-12-31 23:59:32


## Missing Values (columns with any NA)
  Fluid_Intake: 106720 (100%)
  Fluid_Output: 106720 (100%)
  Patient_Reported_Status: 106697 (100%)
  Result_Units: 106582 (99.9%)
  Device_Type: 82207 (77%)
  Document_Source: 64493 (60.4%)
  Site: 194 (0.2%)
  Site_Name: 194 (0.2%)
  Result: 150 (0.1%)
  Encounter_Nbr: 23 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             106720
Number of columns          24    
_______________________          
Column type frequency:           
  character                16    
  logical                  2     
  numeric                  2     
  POSIXct                  4     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable               n_missing complete_rate min max empty n_unique
 1 Assessment_ID                       0      1          5  10     0       21
 2 Assessment_Name                     0      1         10 218     0       17
 3 Assessment_Type_Description         0      1         11  12     0        2
 4 Device_Type                     82207      0.230     10  50     0      127
 5 Document_Source                 64493      0.396      8  44     0       16
 6 Patient_Reported_Status        106697      0.000216  41  41     0        1
 7 Service_Type                        0      1         18  55     0       21
 8 Assessment_Subtype_Desc             0      1         10 218     0       17
 9 Assessment_Subtype_Code             0      1          5  10     0       21
10 Result                            150      0.999      1  15     0      178
11 Result_Units                   106582      0.00129    3   3     0        2
12 Encounter_Nbr                      23      1.000     13  13     0     3270
13 Source                              0      1          4   4     0        1
14 Site                              194      0.998      3   4     0        2
15 Site_Name                         194      0.998      4  20     0        2
16 Site_State                          0      1          2   7     0        3
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0
15          0
16          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate mean count
1 Fluid_Intake     106720             0  NaN ": " 
2 Fluid_Output     106720             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8554243.  2941443.   3502573 6309613
2 current_age           0             1      33.1       5.68      19      29
      p50     p75     p100 hist 
1 8511388 9944346 14840800 ▅▃▇▂▃
2      33      37       54 ▃▇▇▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable   n_missing complete_rate min                
1 delv_date               0             1 2018-06-24 00:00:00
2 Birth_Dt                0             1 1970-09-13 00:00:00
3 Assessment_Date         0             1 2017-07-19 00:00:00
4 Assessment_Time         0             1 1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-04-11 00:00:00      562
2 2006-01-28 00:00:00 1991-07-25 00:00:00      669
3 2026-03-08 00:00:00 2024-06-14 00:00:00     1580
4 1899-12-31 23:59:32 1899-12-31 11:55:00     1702




---

# Dataset: `height_flow`

## Dimensions
- Rows: 25484
- Columns: 24

## Column Types
character x 14,  logical x 4,  numeric x 2,  POSIXct x 4

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Assessment_Date, Assessment_Time, Assessment_ID, Assessment_Name, Assessment_Type_Description, Fluid_Intake, Fluid_Output, Device_Type, Document_Source, Patient_Reported_Status, Service_Type, Assessment_Subtype_Desc, Assessment_Subtype_Code, Result, Result_Units, Encounter_Nbr, Source, Site, Site_Name, Site_State`

## ID-like Columns
  Assessment_ID: 5 unique values
  Fluid_Intake: 0 unique values
  Fluid_Output: 0 unique values
  Patient_Reported_Status: 0 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Assessment_Date: 2018-01-01 to 2026-03-08
  Assessment_Time: 1899-12-31 to 1899-12-31 23:59:00


## Missing Values (columns with any NA)
  Fluid_Intake: 25484 (100%)
  Fluid_Output: 25484 (100%)
  Device_Type: 25484 (100%)
  Patient_Reported_Status: 25484 (100%)
  Document_Source: 418 (1.6%)
  Result: 116 (0.5%)
  Site: 42 (0.2%)
  Site_Name: 42 (0.2%)
  Result_Units: 13 (0.1%)
  Site_State: 9 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             25484 
Number of columns          24    
_______________________          
Column type frequency:           
  character                14    
  logical                  4     
  numeric                  2     
  POSIXct                  4     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable               n_missing complete_rate min max empty n_unique
 1 Assessment_ID                       0         1       2  10     0        5
 2 Assessment_Name                     0         1       6  11     0        2
 3 Assessment_Type_Description         0         1       6  33     0       11
 4 Document_Source                   418         0.984   9  37     0        9
 5 Service_Type                        0         1       6  28     0        6
 6 Assessment_Subtype_Desc             0         1       6  11     0        2
 7 Assessment_Subtype_Code             0         1       2  10     0        5
 8 Result                            116         0.995   2   6     0      990
 9 Result_Units                       13         0.999   2   2     0        3
10 Encounter_Nbr                       0         1       7  13     0    11983
11 Source                              0         1       4  24     0        3
12 Site                               42         0.998   3   5     0        5
13 Site_Name                          42         0.998   4  21     0        5
14 Site_State                          9         1.000   2   7     0        5
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable           n_missing complete_rate mean count
1 Fluid_Intake                25484             0  NaN ": " 
2 Fluid_Output                25484             0  NaN ": " 
3 Device_Type                 25484             0  NaN ": " 
4 Patient_Reported_Status     25484             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8264385.  2631739.   3502573 6288027
2 current_age           0             1      32.6       5.63      19      29
      p50     p75     p100 hist 
1 8472501 9602967 14840800 ▃▃▇▁▂
2      33      36       54 ▃▇▇▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable   n_missing complete_rate min                
1 delv_date               0             1 2018-06-24 00:00:00
2 Birth_Dt                0             1 1970-09-13 00:00:00
3 Assessment_Date         0             1 2018-01-01 00:00:00
4 Assessment_Time         0             1 1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-03-21 00:00:00      565
2 2006-01-28 00:00:00 1992-01-02 00:00:00      676
3 2026-03-08 00:00:00 2023-02-10 00:00:00     2521
4 1899-12-31 23:59:00 1899-12-31 11:45:00     1339




---

# Dataset: `weight_flow`

## Dimensions
- Rows: 156133
- Columns: 24

## Column Types
character x 15,  logical x 3,  numeric x 2,  POSIXct x 4

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Assessment_Date, Assessment_Time, Assessment_ID, Assessment_Name, Assessment_Type_Description, Fluid_Intake, Fluid_Output, Device_Type, Document_Source, Patient_Reported_Status, Service_Type, Assessment_Subtype_Desc, Assessment_Subtype_Code, Result, Result_Units, Encounter_Nbr, Source, Site, Site_Name, Site_State`

## ID-like Columns
  Assessment_ID: 25 unique values
  Fluid_Intake: 0 unique values
  Fluid_Output: 0 unique values
  Patient_Reported_Status: 1 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Assessment_Date: 2018-01-01 to 2026-03-08
  Assessment_Time: 1899-12-31 to 1899-12-31 23:59:00


## Missing Values (columns with any NA)
  Fluid_Intake: 156133 (100%)
  Fluid_Output: 156133 (100%)
  Device_Type: 156133 (100%)
  Patient_Reported_Status: 155973 (99.9%)
  Result_Units: 7870 (5%)
  Document_Source: 1589 (1%)
  Result: 603 (0.4%)
  Site: 242 (0.2%)
  Site_Name: 242 (0.2%)
  Encounter_Nbr: 100 (0.1%)
  Site_State: 70 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             156133
Number of columns          24    
_______________________          
Column type frequency:           
  character                15    
  logical                  3     
  numeric                  2     
  POSIXct                  4     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable               n_missing complete_rate min max empty n_unique
 1 Assessment_ID                       0       1         2  10     0       25
 2 Assessment_Name                     0       1         6  90     0       20
 3 Assessment_Type_Description         0       1         6  33     0       15
 4 Document_Source                  1589       0.990     9  44     0       16
 5 Patient_Reported_Status        155973       0.00102  41  41     0        1
 6 Service_Type                        0       1         6  32     0       23
 7 Assessment_Subtype_Desc             0       1         6  90     0       20
 8 Assessment_Subtype_Code             0       1         2  10     0       25
 9 Result                            603       0.996     1  22     0     3690
10 Result_Units                     7870       0.950     2   3     0        4
11 Encounter_Nbr                     100       0.999     7  13     0    35579
12 Source                              0       1         4  24     0        3
13 Site                              242       0.998     3   5     0        5
14 Site_Name                         242       0.998     4  21     0        5
15 Site_State                         70       1.000     2   7     0        5
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0
15          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate mean count
1 Fluid_Intake     156133             0  NaN ": " 
2 Fluid_Output     156133             0  NaN ": " 
3 Device_Type      156133             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8426206.  2652370.   3502573 6398313
2 current_age           0             1      32.4       5.59      19      28
      p50     p75     p100 hist 
1 8533077 9710780 14840800 ▃▃▇▂▂
2      33      36       54 ▃▇▆▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable   n_missing complete_rate min                
1 delv_date               0             1 2018-06-24 00:00:00
2 Birth_Dt                0             1 1970-09-13 00:00:00
3 Assessment_Date         0             1 2018-01-01 00:00:00
4 Assessment_Time         0             1 1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-04-24 00:00:00      565
2 2006-01-28 00:00:00 1992-02-22 00:00:00      676
3 2026-03-08 00:00:00 2023-03-31 00:00:00     2878
4 1899-12-31 23:59:00 1899-12-31 12:05:00     1799




---

# Dataset: `cohort`

## Dimensions
- Rows: 729
- Columns: 16

## Column Types
character x 11,  logical x 1,  numeric x 2,  POSIXct x 2

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Deceased, Death_Dt, Gender, auth, FMC, Legal, Privacy, Test_Patient, Hospice, Dismissed, No_Contact, Terminated`

## ID-like Columns
  Test_Patient: 1 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28


## Missing Values (columns with any NA)
  Death_Dt: 729 (100%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             729   
Number of columns          16    
_______________________          
Column type frequency:           
  character                11    
  logical                  1     
  numeric                  2     
  POSIXct                  2     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable n_missing complete_rate min max empty n_unique whitespace
 1 Deceased              0             1   1   1     0        1          0
 2 Gender                0             1   1   1     0        1          0
 3 auth                  0             1   1   1     0        1          0
 4 FMC                   0             1   1   1     0        1          0
 5 Legal                 0             1   1   1     0        1          0
 6 Privacy               0             1   1   1     0        1          0
 7 Test_Patient          0             1   1   1     0        1          0
 8 Hospice               0             1   1   1     0        1          0
 9 Dismissed             0             1   1   1     0        2          0
10 No_Contact            0             1   1   1     0        1          0
11 Terminated            0             1   1   1     0        1          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate mean count
1 Death_Dt            729             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8685191.  2921379.   3502573 6342919
2 current_age           0             1      32.5       5.48      19      29
      p50      p75     p100 hist 
1 8609485 10278367 14840800 ▅▃▇▂▃
2      33       36       54 ▃▇▆▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate min                 max                
1 delv_date             0             1 2018-06-24 00:00:00 2025-12-23 00:00:00
2 Birth_Dt              0             1 1970-09-13 00:00:00 2006-01-28 00:00:00
  median              n_unique
1 2024-05-08 00:00:00      565
2 1992-02-20 00:00:00      676




---

# Dataset: `demo`

## Dimensions
- Rows: 729
- Columns: 8

## Column Types
character x 4,  numeric x 2,  POSIXct x 2

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Ethnicity_Name, race_primary, race_secondary_race1, race_secondary_race2`

## ID-like Columns
  (none detected)


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28


## Missing Values (columns with any NA)
  race_secondary_race2: 726 (99.6%)
  race_secondary_race1: 714 (97.9%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             729   
Number of columns          8     
_______________________          
Column type frequency:           
  character                4     
  numeric                  2     
  POSIXct                  2     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
  skim_variable        n_missing complete_rate min max empty n_unique whitespace
1 Ethnicity_Name               0       1         7  50     0        8          0
2 race_primary                 0       1         5  31     0       16          0
3 race_secondary_race1       714       0.0206    5  31     0        7          0
4 race_secondary_race2       726       0.00412   5   5     0        2          0

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0             1 8685191.  2921379.   3502573 6342919
2 current_age           0             1      32.5       5.48      19      29
      p50      p75     p100 hist 
1 8609485 10278367 14840800 ▅▃▇▂▃
2      33       36       54 ▃▇▆▂▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate min                 max                
1 delv_date             0             1 2018-06-24 00:00:00 2025-12-23 00:00:00
2 Birth_Dt              0             1 1970-09-13 00:00:00 2006-01-28 00:00:00
  median              n_unique
1 2024-05-08 00:00:00      565
2 1992-02-20 00:00:00      676




---

# Dataset: `dx`

## Dimensions
- Rows: 314315
- Columns: 19

## Column Types
character x 13,  numeric x 3,  POSIXct x 3

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Dx_Date, Dx_Code, Dx_Desc, Dx_Type, Primary_Dx_Flag, Dx_POA_Flag, Encounter_Nbr, Visit_Nbr, Patient_Type, Dx_Source, Dx_Servicing_Provider_Id, Dx_Site, Dx_Site_Name, Dx_Site_State, Comments`

## ID-like Columns
  Patient_Type: 3 unique values
  Dx_Servicing_Provider_Id: 7175 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Dx_Date: 2017-07-07 to 2026-03-10


## Missing Values (columns with any NA)
  Comments: 313991 (99.9%)
  Dx_POA_Flag: 292645 (93.1%)
  Primary_Dx_Flag: 21717 (6.9%)
  Dx_Code: 404 (0.1%)
  Dx_Type: 404 (0.1%)
  Patient_Type: 48 (0%)
  Dx_Site_State: 11 (0%)
  Dx_Servicing_Provider_Id: 3 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             314315
Number of columns          19    
_______________________          
Column type frequency:           
  character                13    
  numeric                  3     
  POSIXct                  3     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable            n_missing complete_rate min max empty n_unique
 1 Dx_Code                        404       0.999     3  16     0     4043
 2 Dx_Desc                          0       1         4 163     0     7691
 3 Dx_Type                        404       0.999     5   9     0        3
 4 Primary_Dx_Flag              21717       0.931     1   1     0        2
 5 Dx_POA_Flag                 292645       0.0689    1   1     0        1
 6 Encounter_Nbr                    0       1         6  13     0    66748
 7 Patient_Type                    48       1.000     9  10     0        3
 8 Dx_Source                        0       1         2   5     0        4
 9 Dx_Servicing_Provider_Id         3       1.000     5  10     0     7175
10 Dx_Site                          0       1         3   5     0        5
11 Dx_Site_Name                     0       1         4  21     0        5
12 Dx_Site_State                   11       1.000     2   2     0        6
13 Comments                    313991       0.00103   1 434     0      250
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate        mean           sd      p0     p25
1 CURR_CLINIC           0             1   8604762.    2912237.   3502573 6362616
2 current_age           0             1        33.0         5.68      19      29
3 Visit_Nbr             0             1 499555319.  584261345.    -99999  -99999
      p50        p75       p100 hist 
1 8583051   10264701   14840800 ▅▃▇▂▃
2      33         37         54 ▂▇▇▂▁
3  -99999 1173480191 1274606796 ▇▁▁▁▆

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate min                 max                
1 delv_date             0             1 2018-06-24 00:00:00 2025-12-23 00:00:00
2 Birth_Dt              0             1 1970-09-13 00:00:00 2006-01-28 00:00:00
3 Dx_Date               0             1 2017-07-07 00:00:00 2026-03-10 00:00:00
  median              n_unique
1 2024-03-12 00:00:00      550
2 1991-09-16 00:00:00      676
3 2024-05-09 00:00:00     2621




---

# Dataset: `labs`

## Dimensions
- Rows: 224910
- Columns: 31

## Column Types
character x 22,  numeric x 3,  POSIXct x 6

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Lab_Date, Lab_Time, Lab_Result_Date, Lab_Result_Time, Test_Code, TestDesc, Lab_Panel_Code, Lab_Panel_Desc, Lab_Panel_Type, Sample_Type_Desc, Resultn, Resultc, Accession, Units, Ranges, Rang_Ind, Range_Ind_Description, Status, Lab_type, Lab_Subtype, Source, Site, Site_Name, Site_State, Facility, Encounter_Nbr, Comments`

## ID-like Columns
  (none detected)


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Lab_Date: 2017-07-19 to 2026-03-08
  Lab_Time: 1899-12-31 to 1899-12-31 23:59:00
  Lab_Result_Date: 2017-07-19 to 2026-03-08
  Lab_Result_Time: 1899-12-31 to 1899-12-31 23:59:00


## Missing Values (columns with any NA)
  Comments: 187187 (83.2%)
  Resultn: 85054 (37.8%)
  Units: 70587 (31.4%)
  Ranges: 49185 (21.9%)
  Site_State: 8385 (3.7%)
  Resultc: 5693 (2.5%)
  Site: 3455 (1.5%)
  Site_Name: 3455 (1.5%)
  Accession: 470 (0.2%)
  Rang_Ind: 8 (0%)
  Range_Ind_Description: 8 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             224910
Number of columns          31    
_______________________          
Column type frequency:           
  character                22    
  numeric                  3     
  POSIXct                  6     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable         n_missing complete_rate min  max empty n_unique
 1 Test_Code                     0         1       1   12     0     3466
 2 TestDesc                      0         1       2   75     0     3117
 3 Lab_Panel_Code                0         1       3   12     0      959
 4 Lab_Panel_Desc                0         1       5   94     0      953
 5 Lab_Panel_Type                0         1       3   35     0        6
 6 Sample_Type_Desc              0         1       4   30     0       30
 7 Resultc                    5693         0.975   1  239     0     8178
 8 Accession                   470         0.998   8   36     0    53826
 9 Units                     70587         0.686   1   16     0      149
10 Ranges                    49185         0.781   2   50     0      994
11 Rang_Ind                      8         1.000   1    3     0       12
12 Range_Ind_Description         8         1.000   3   13     0       12
13 Status                        0         1       1   21     0        3
14 Lab_type                      0         1       3   94     0     1031
15 Lab_Subtype                   0         1       2   67     0     2287
16 Source                        0         1       4   13     0        2
17 Site                       3455         0.985   3    5     0        5
18 Site_Name                  3455         0.985   4   21     0        5
19 Site_State                 8385         0.963   2    2     0        4
20 Facility                      0         1      21   68     0      387
21 Encounter_Nbr                 0         1       9   13     0    13902
22 Comments                 187187         0.168   4 5217     0     4095
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0
15          0
16          0
17          0
18          0
19          0
20          0
21          0
22          0

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0       p25
1 CURR_CLINIC           0         1     8594239.  2858536.   3502573 6378886  
2 current_age           0         1          32.7       5.82      19      28  
3 Resultn           85054         0.622     316.    32262.       -20       4.2
        p50       p75     p100 hist 
1 8546148   9944227   14840800 ▃▃▇▂▃
2      33        37         54 ▃▇▇▂▁
3      12.8      83.2  8312023 ▇▁▁▁▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable   n_missing complete_rate min                
1 delv_date               0             1 2018-06-24 00:00:00
2 Birth_Dt                0             1 1970-09-13 00:00:00
3 Lab_Date                0             1 2017-07-19 00:00:00
4 Lab_Time                0             1 1899-12-31 00:00:00
5 Lab_Result_Date         0             1 2017-07-19 00:00:00
6 Lab_Result_Time         0             1 1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-04-03 00:00:00      550
2 2006-01-28 00:00:00 1991-11-01 00:00:00      676
3 2026-03-08 00:00:00 2024-05-06 00:00:00     2195
4 1899-12-31 23:59:00 1899-12-31 12:14:00     1439
5 2026-03-08 00:00:00 2024-05-07 00:00:00     2352
6 1899-12-31 23:59:00 1899-12-31 13:08:00     1443




---

# Dataset: `ob`

## Dimensions
- Rows: 1230
- Columns: 61

## Column Types
character x 38,  numeric x 12,  POSIXct x 11

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, OB_DELIVERY_FPK, SITE, SITE_NAME, SOURCE, INDUCTION_DTM, MEMBRANE_RUPTURE_DTM, DELIVERY_DTM, OB_DELIVERY_ADMIT_DTM, OB_DELIVERY_DISCHARGE_DTM, BIRTH_WEIGHT_IN_OUNCES, GESTATIONAL_AGE_IN_DAYS, GESTATIONAL_AGE_IN_WEEKS, MATERNAL_ENCOUNTER_NUMBER, BABY_ENCOUNTER_NUMBER, APGAR_1, APGAR_5, APGAR_10, LAST_MATERNAL_BMI, LAST_MATERNAL_BMI_DTM, LAST_MATERNAL_WEIGHT_IN_OUNCES, LAST_MATERNAL_WEIGHT_DTM, PREGRAVID_BMI, PREGRAVID_WEIGHT_IN_OUNCES, DELIVERY_MODALITY, DELIVERY_MODALITY_REASON, DELIVERY_BABY_POSITION, DELIVERY_PRESENTATION, DELIVERY_PRESENTATION_A_P, DELIVERY_PRESENTATION_L_R, DELIVERY_LIVING_STATUS, DELIVERY_ANOMALIES, DELIVERY_COMPLICATIONS, DELIVERY_ANALGESIC, DELIVERY_ANESTHESIA_METHOD, DELIVERY_AUGMENTATION, DELIVERY_EPISIOTOMY, DELIVERY_EPISIOTOMY_REASON, DELIVERY_LACERATION, DELIVERY_PROCEDURES, INDUCTION_INDICATIONS, INDUCTION_METHODS, GRAVIDITY, PARITY, ABORTIONS, FULL_TERM, PREMATURE, MULTIPLE_BIRTHS, LAST_MENSTRUAL_PERIOD_DTM, ULTRASOUND_DTM, INFERTILITY_TREATMENT, PRIOR_CESAREAN_YN, PRIOR_CESAREAN_COUNT, LABOR_ATTEMPT_YN, FATHER_NAME, NUMBER_OF_PRENATAL_VISITS, OB_C_SECTION_PRIORITY, BABY_MCN`

## ID-like Columns
  PREGRAVID_BMI: 301 unique values
  PREGRAVID_WEIGHT_IN_OUNCES: 471 unique values
  GRAVIDITY: 15 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  INDUCTION_DTM: 2017-09-19 01:30:00 to 2025-12-23 09:32:00
  MEMBRANE_RUPTURE_DTM: 2017-07-26 08:32:00 to 2025-12-29 01:10:00
  DELIVERY_DTM: 2017-07-26 08:32:00 to 2025-12-29 05:10:00
  OB_DELIVERY_ADMIT_DTM: 2017-07-26 05:30:00 to 2025-12-28 19:38:00
  OB_DELIVERY_DISCHARGE_DTM: 2017-07-28 15:30:00 to 2025-12-31 14:01:00
  LAST_MATERNAL_BMI_DTM: 2017-07-26 05:30:00 to 2025-12-23 08:14:00
  LAST_MATERNAL_WEIGHT_DTM: 2017-07-26 05:30:00 to 2025-12-23 08:14:00
  LAST_MENSTRUAL_PERIOD_DTM: 2017-07-04 10:49:00 to 2025-10-09 13:11:00
  ULTRASOUND_DTM: 2017-07-11 08:26:00 to 2025-11-19 13:44:00


## Missing Values (columns with any NA)
  DELIVERY_EPISIOTOMY_REASON: 1222 (99.3%)
  INFERTILITY_TREATMENT: 1222 (99.3%)
  DELIVERY_PROCEDURES: 1220 (99.2%)
  DELIVERY_ANOMALIES: 1215 (98.8%)
  DELIVERY_ANALGESIC: 1213 (98.6%)
  APGAR_10: 1082 (88%)
  DELIVERY_AUGMENTATION: 1011 (82.2%)
  OB_C_SECTION_PRIORITY: 937 (76.2%)
  INDUCTION_DTM: 738 (60%)
  INDUCTION_INDICATIONS: 698 (56.7%)
  INDUCTION_METHODS: 630 (51.2%)
  FATHER_NAME: 618 (50.2%)
  DELIVERY_EPISIOTOMY: 616 (50.1%)
  DELIVERY_PRESENTATION_L_R: 592 (48.1%)
  PREMATURE: 541 (44%)
  DELIVERY_LACERATION: 540 (43.9%)
  DELIVERY_COMPLICATIONS: 523 (42.5%)
  ABORTIONS: 436 (35.4%)
  LABOR_ATTEMPT_YN: 381 (31%)
  DELIVERY_MODALITY_REASON: 346 (28.1%)
  DELIVERY_PRESENTATION_A_P: 322 (26.2%)
  DELIVERY_PRESENTATION: 313 (25.4%)
  ULTRASOUND_DTM: 250 (20.3%)
  MEMBRANE_RUPTURE_DTM: 213 (17.3%)
  LAST_MATERNAL_WEIGHT_IN_OUNCES: 209 (17%)
  LAST_MATERNAL_WEIGHT_DTM: 209 (17%)
  LAST_MATERNAL_BMI: 188 (15.3%)
  LAST_MATERNAL_BMI_DTM: 188 (15.3%)
  PREGRAVID_BMI: 143 (11.6%)
  PREGRAVID_WEIGHT_IN_OUNCES: 143 (11.6%)
  DELIVERY_ANESTHESIA_METHOD: 122 (9.9%)
  LAST_MENSTRUAL_PERIOD_DTM: 90 (7.3%)
  DELIVERY_BABY_POSITION: 83 (6.7%)
  FULL_TERM: 80 (6.5%)
  APGAR_5: 24 (2%)
  MULTIPLE_BIRTHS: 24 (2%)
  APGAR_1: 23 (1.9%)
  OB_DELIVERY_ADMIT_DTM: 19 (1.5%)
  OB_DELIVERY_DISCHARGE_DTM: 19 (1.5%)
  DELIVERY_LIVING_STATUS: 19 (1.5%)
  GRAVIDITY: 19 (1.5%)
  PARITY: 19 (1.5%)
  GESTATIONAL_AGE_IN_DAYS: 11 (0.9%)
  GESTATIONAL_AGE_IN_WEEKS: 11 (0.9%)
  DELIVERY_MODALITY: 9 (0.7%)
  BIRTH_WEIGHT_IN_OUNCES: 6 (0.5%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             1230  
Number of columns          61    
_______________________          
Column type frequency:           
  character                38    
  numeric                  12    
  POSIXct                  11    
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable              n_missing complete_rate min max empty n_unique
 1 OB_DELIVERY_FPK                    0       1        14  15     0     1170
 2 SITE                               0       1         3   4     0        2
 3 SITE_NAME                          0       1         4  20     0        2
 4 SOURCE                             0       1         4   4     0        1
 5 MATERNAL_ENCOUNTER_NUMBER          0       1        13  13     0     1147
 6 BABY_ENCOUNTER_NUMBER              0       1        13  13     0     1170
 7 APGAR_1                           23       0.981     1   2     0       11
 8 APGAR_5                           24       0.980     1   2     0       11
 9 APGAR_10                        1082       0.120     1   2     0       11
10 DELIVERY_MODALITY                  9       0.993    12  27     0       15
11 DELIVERY_MODALITY_REASON         346       0.719     3  50     0      158
12 DELIVERY_BABY_POSITION            83       0.933     4  10     0        6
13 DELIVERY_PRESENTATION            313       0.746     6   7     0        3
14 DELIVERY_PRESENTATION_A_P        322       0.738     8  10     0        3
15 DELIVERY_PRESENTATION_L_R        592       0.519     4   6     0        3
16 DELIVERY_LIVING_STATUS            19       0.985     6  15     0        3
17 DELIVERY_ANOMALIES              1215       0.0122    6  50     0       12
18 DELIVERY_COMPLICATIONS           523       0.575     4  50     0      108
19 DELIVERY_ANALGESIC              1213       0.0138    8  50     0        7
20 DELIVERY_ANESTHESIA_METHOD       122       0.901     5  50     0       38
21 DELIVERY_AUGMENTATION           1011       0.178     4  15     0        5
22 DELIVERY_EPISIOTOMY              616       0.499     4  18     0        3
23 DELIVERY_EPISIOTOMY_REASON      1222       0.00650  16  36     0        4
24 DELIVERY_LACERATION              540       0.561     2  10     0       10
25 DELIVERY_PROCEDURES             1220       0.00813  28  50     0        4
26 INDUCTION_INDICATIONS            698       0.433     3  50     0       95
27 INDUCTION_METHODS                630       0.488     4  50     0       84
28 GRAVIDITY                         19       0.985     1   2     0       15
29 PARITY                            19       0.985     1   2     0       12
30 ABORTIONS                        436       0.646     1   2     0       11
31 FULL_TERM                         80       0.935     1   2     0       12
32 PREMATURE                        541       0.560     1   1     0        5
33 MULTIPLE_BIRTHS                   24       0.980     1   1     0        2
34 INFERTILITY_TREATMENT           1222       0.00650   4   4     0        1
35 PRIOR_CESAREAN_YN                  0       1         1   1     0        2
36 LABOR_ATTEMPT_YN                 381       0.690     1   1     0        2
37 FATHER_NAME                      618       0.498     6  30     0      493
38 OB_C_SECTION_PRIORITY            937       0.238     4   9     0        4
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0
15          0
16          0
17          0
18          0
19          0
20          0
21          0
22          0
23          0
24          0
25          0
26          0
27          0
28          0
29          0
30          0
31          0
32          0
33          0
34          0
35          0
36          0
37          0
38          0

── Variable type: numeric ──────────────────────────────────────────────────────
   skim_variable                  n_missing complete_rate         mean
 1 CURR_CLINIC                            0         1      8518353.   
 2 current_age                            0         1           32.5  
 3 BIRTH_WEIGHT_IN_OUNCES                 6         0.995      116.   
 4 GESTATIONAL_AGE_IN_DAYS               11         0.991      264.   
 5 GESTATIONAL_AGE_IN_WEEKS              11         0.991       37.4  
 6 LAST_MATERNAL_BMI                    188         0.847       41.8  
 7 LAST_MATERNAL_WEIGHT_IN_OUNCES       209         0.830     4027.   
 8 PREGRAVID_BMI                        143         0.884       37.4  
 9 PREGRAVID_WEIGHT_IN_OUNCES           143         0.884     3603.   
10 PRIOR_CESAREAN_COUNT                   0         1            0.176
11 NUMBER_OF_PRENATAL_VISITS              0         1           11.0  
12 BABY_MCN                               0         1     13620536.   
            sd         p0        p25        p50        p75       p100 hist 
 1 2732495.    3502573     6366684.   8582080.   9902920.  14840800   ▃▃▇▂▂
 2       5.29       19          29         33         36         54   ▃▇▆▁▁
 3      26.8         2.29      105.       118.       132.       193.  ▁▁▆▇▁
 4      22.2        79         260        270        275        320   ▁▁▁▇▇
 5       3.19       11          37         38         39         45   ▁▁▁▇▇
 6       7.38       24.6        36.4       40.8       46.5       75.0 ▂▇▃▁▁
 7     780.       2155.       3471.      3940.      4462.      8320   ▃▇▃▁▁
 8       7.80       19.5        32.2       36.6       41.7       75   ▂▇▃▁▁
 9     796.       1834.       3034.      3520       4056.      6917.  ▂▇▃▁▁
10       0.439       0           0          0          0          2   ▇▁▁▁▁
11       4.87        0           8         11         14         35   ▂▇▂▁▁
12 2006062.     -99999    13140936.  14036922.  14552722.  15127782   ▁▁▁▁▇

── Variable type: POSIXct ──────────────────────────────────────────────────────
   skim_variable             n_missing complete_rate min                
 1 delv_date                         0         1     2018-06-24 00:00:00
 2 Birth_Dt                          0         1     1970-09-13 00:00:00
 3 INDUCTION_DTM                   738         0.4   2017-09-19 01:30:00
 4 MEMBRANE_RUPTURE_DTM            213         0.827 2017-07-26 08:32:00
 5 DELIVERY_DTM                      0         1     2017-07-26 08:32:00
 6 OB_DELIVERY_ADMIT_DTM            19         0.985 2017-07-26 05:30:00
 7 OB_DELIVERY_DISCHARGE_DTM        19         0.985 2017-07-28 15:30:00
 8 LAST_MATERNAL_BMI_DTM           188         0.847 2017-07-26 05:30:00
 9 LAST_MATERNAL_WEIGHT_DTM        209         0.830 2017-07-26 05:30:00
10 LAST_MENSTRUAL_PERIOD_DTM        90         0.927 2017-07-04 10:49:00
11 ULTRASOUND_DTM                  250         0.797 2017-07-11 08:26:00
   max                 median              n_unique
 1 2025-12-23 00:00:00 2024-05-20 00:00:00      565
 2 2006-01-28 00:00:00 1992-02-23 00:00:00      676
 3 2025-12-23 09:32:00 2023-10-18 19:04:30      463
 4 2025-12-29 01:10:00 2023-08-13 14:01:00      962
 5 2025-12-29 05:10:00 2023-08-10 17:59:00     1169
 6 2025-12-28 19:38:00 2023-07-30 07:56:00     1127
 7 2025-12-31 14:01:00 2023-08-01 11:39:00     1125
 8 2025-12-23 08:14:00 2023-08-25 14:55:00      966
 9 2025-12-23 08:14:00 2023-08-25 09:49:00      946
10 2025-10-09 13:11:00 2023-01-11 23:40:30     1060
11 2025-11-19 13:44:00 2023-02-05 11:58:30      910




---

# Dataset: `smoking`

## Dimensions
- Rows: 167209
- Columns: 11

## Column Types
character x 3,  logical x 1,  numeric x 3,  POSIXct x 4

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, tob_dt, tob_tm, tob_name, tob_value, tob_seq, tob_src_system, tob_src_key`

## ID-like Columns
  (none detected)


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  tob_dt: 2018-01-01 to 2026-03-08
  tob_tm: 1899-12-31 to 1899-12-31 23:35:00


## Missing Values (columns with any NA)
  tob_src_key: 167209 (100%)
  tob_value: 254 (0.2%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             167209
Number of columns          11    
_______________________          
Column type frequency:           
  character                3     
  logical                  1     
  numeric                  3     
  POSIXct                  4     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
  skim_variable  n_missing complete_rate min max empty n_unique whitespace
1 tob_name               0         1      17  22     0        4          0
2 tob_value            254         0.998   2  37     0       25          0
3 tob_src_system         0         1       6  20     0        2          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate mean count
1 tob_src_key      167209             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate       mean          sd      p0     p25
1 CURR_CLINIC           0             1 8320506.   2622994.    3502573 6331633
2 current_age           0             1      32.5        5.66       19      28
3 tob_seq               0             1       1.50       0.500       1       1
      p50     p75     p100 hist 
1 8487078 9640125 14840800 ▃▃▇▂▂
2      33      36       54 ▃▇▇▂▁
3       2       2        2 ▇▁▁▁▇

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate min                 max                
1 delv_date             0             1 2018-06-24 00:00:00 2025-12-23 00:00:00
2 Birth_Dt              0             1 1970-09-13 00:00:00 2006-01-28 00:00:00
3 tob_dt                0             1 2018-01-01 00:00:00 2026-03-08 00:00:00
4 tob_tm                0             1 1899-12-31 00:00:00 1899-12-31 23:35:00
  median              n_unique
1 2024-04-17 00:00:00      565
2 1992-01-17 00:00:00      676
3 2022-12-16 00:00:00     2941
4 1899-12-31 00:00:00      160




---

# Dataset: `ecg`

## Dimensions
- Rows: 4783
- Columns: 29

## Column Types
character x 14,  logical x 2,  numeric x 9,  POSIXct x 4

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, ECG_Date, ECG_Time, Accession, Heart_Rate, P_Wave, PR_Interval, QRS_Interval, QRS_Duration, QT_Interval, QTC, QTF, ECG_Code, ECG_Desc, ECG_Test_Desc, Sequence, Status, Service_Type, Service_Subtype, Service_Status, Encounter_Nbr, Source, Site, Site_Name, Site_State, Report`

## ID-like Columns
  (none detected)


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1976-10-29 to 2004-07-20
  ECG_Date: 2017-12-13 to 2026-03-09
  ECG_Time: 1899-12-31 00:12:00 to 1899-12-31 23:57:46


## Missing Values (columns with any NA)
  P_Wave: 4783 (100%)
  QRS_Interval: 4783 (100%)
  Report: 4776 (99.9%)
  Accession: 666 (13.9%)
  QTF: 650 (13.6%)
  Site_State: 424 (8.9%)
  Status: 49 (1%)
  Encounter_Nbr: 31 (0.6%)
  PR_Interval: 26 (0.5%)
  Heart_Rate: 23 (0.5%)
  QRS_Duration: 23 (0.5%)
  QT_Interval: 23 (0.5%)
  QTC: 23 (0.5%)
  Site: 2 (0%)
  Site_Name: 2 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             4783  
Number of columns          29    
_______________________          
Column type frequency:           
  character                14    
  logical                  2     
  numeric                  9     
  POSIXct                  4     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable   n_missing complete_rate min max empty n_unique whitespace
 1 Accession             666       0.861     4  16     0      610          0
 2 ECG_Code                0       1         2   7     0      203          0
 3 ECG_Desc                0       1         1  68     0      212          0
 4 ECG_Test_Desc           0       1         3  16     0        3          0
 5 Status                 49       0.990    10  21     0        4          0
 6 Service_Type            0       1         3  29     0        6          0
 7 Service_Subtype         0       1         3  29     0        7          0
 8 Service_Status          0       1         9  11     0        4          0
 9 Encounter_Nbr          31       0.994    13  13     0      605          0
10 Source                  0       1         4   4     0        2          0
11 Site                    2       1.000     3   5     0        3          0
12 Site_Name               2       1.000     4  20     0        3          0
13 Site_State            424       0.911     2   7     0        3          0
14 Report               4776       0.00146  35 177     0        2          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate mean count
1 P_Wave             4783             0  NaN ": " 
2 QRS_Interval       4783             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC           0         1     8348966.  2987959.   3518088 6141272
2 current_age           0         1          33.0       6.14      20      29
3 Heart_Rate           23         0.995      88.2      20.7       36      73
4 PR_Interval          26         0.995     147.       23.7        0     134
5 QRS_Duration         23         0.995      84.5      11.1       64      78
6 QT_Interval          23         0.995     369.       38.7      244     348
7 QTC                  23         0.995     439.       26.7      365     422
8 QTF                 650         0.864     413.       23.4      324     400
9 Sequence              0         1      -13586.    34273.    -99999       1
      p50     p75     p100 hist 
1 8423634 9830221 14526686 ▆▅▇▂▃
2      33      38       48 ▃▇▆▆▂
3      85      99      186 ▂▇▃▁▁
4     146     160      234 ▁▁▅▇▁
5      84      90      170 ▇▆▁▁▁
6     370     394      498 ▁▃▇▃▁
7     439     453      587 ▁▇▃▁▁
8     413     427      519 ▁▃▇▁▁
9       3       6       20 ▁▁▁▁▇

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable n_missing complete_rate min                 max                
1 delv_date             0             1 2018-06-24 00:00:00 2025-12-23 00:00:00
2 Birth_Dt              0             1 1976-10-29 00:00:00 2004-07-20 00:00:00
3 ECG_Date              0             1 2017-12-13 00:00:00 2026-03-09 00:00:00
4 ECG_Time              0             1 1899-12-31 00:12:00 1899-12-31 23:57:46
  median              n_unique
1 2024-04-15 00:00:00      282
2 1991-10-09 00:00:00      305
3 2024-07-31 00:00:00      490
4 1899-12-31 13:55:00     1089




---

# Dataset: `echo_ef`

## Dimensions
- Rows: 317
- Columns: 847

## Column Types
character x 385,  logical x 144,  numeric x 315,  POSIXct x 3

## Columns
`curr_clinic, input_clinic, first_name, last_name, birth_date, age_at_echo, gender, procedure_id, visit_id, procedure_date, procedure_time, height, weight, bmi, bsa, procedure_type, report_id, REPORT_COMMENTS, REPORT_COMMENTS2, location_name, domain_name, is_stress, is_research, phase_id, phase_name, RESEARCH_PROT_DEF_ID, STRESS_PROT_DEF_ID, imp02786, imp02787, imp02789, imp02795, imp02802, imp02810, imp02813, imp02844, imp02996, imp03134, imp03135, imp03136, imp03137, imp03139, imp03140, imp03257, imp03273, imp03281, imp03307, imp03359, imp03470, imp03479, imp03495, imp03518, imp03554, imp03556, imp03562, imp03577, imp03623, imp03631, imp03643, imp03651, imp03653, imp03666, imp03676, imp03694, imp03780, imp03839, imp03914, imp03918, imp03928, imp03930, imp03931, imp03937, imp03939, imp03946, imp03961, imp03975, imp03979, imp04036, imp04044, imp04046, imp04074, imp04075, imp04093, imp04116, imp04119, imp04120, imp04122, imp04195, imp04373, imp04374, imp04491, imp04508, imp04713, imp04791, imp04862, imp04864, imp04865, imp04869, imp04915, imp04931, imp05043, imp05044, imp05057, imp05065, imp05073, imp05094, imp05102, imp05120, imp05129, imp05231, imp05394, imp05396, imp05398, imp05399, imp05400, imp05401, imp05408, imp05541, imp05560, imp05564, imp05566, imp05585, imp05586, imp05587, imp05588, imp05589, imp05590, imp05591, imp05593, imp05598, imp05599, imp05614, imp05653, imp05712, imp05719, imp05733, imp05773, imp05774, imp05780, imp05795, imp05798, imp05804, imp05808, imp05858, imp06224, imp06232, imp06238, imp06512, imp06519, imp06520, imp06521, imp06522, imp06523, imp06591, imp06592, imp07245, imp07254, imp07259, imp07260, imp07265, imp07266, imp07270, imp07272, imp07285, imp07333, imp07334, imp07375, imp07440, imp07455, imp07474, imp07477, imp07480, imp07481, imp07511, imp07512, imp07513, imp07518, imp07519, imp07525, imp07551, imp07553, imp07560, imp07583, imp07994, imp08049, imp08069, imp08070, imp08071, imp08192, imp08243, imp08310, imp08529, imp08669, imp08689, imp08729, imp08912, imp09196, imp09202, imp09209, imp09255, imp09326, imp09929, imp09997, imp10006, imp10043, imp10402, imp10413, imp10423, imp10425, imp10426, imp10513, imp10514, imp10803, imp10816, imp10819, imp10820, imp10821, imp10860, imp10943, imp11100, imp11200, imp11299, imp11859, imp11879, imp11880, imp11979, imp12181, imp12199, imp12419, imp12445, imp12454, imp12479, imp12480, imp12619, imp12739, imp12799, imp12859, imp12999, imp13000, imp13059, imp13141, imp13148, imp13219, imp13260, imp13419, imp13479, imp50000, imp50022, imp50031, imp50032, imp50033, imp50034, imp50037, imp50038, imp50039, imp50040, imp50041, imp50042, imp50060, imp50105, imp50111, imp50209, imp50211, imp50212, imp50225, imp50235, imp50236, imp50237, imp50238, imp50252, imp50260, imp50266, imp50400, imp50401, imp50405, imp50406, imp50435, imp50470, imp50509, imp50536, imp50575, imp50576, imp50580, imp50581, imp50582, imp50583, imp50584, imp50585, imp50590, imp50675, imp50685, imp50740, imp50765, imp50766, imp50775, imp50805, imp50806, imp50815, imp50816, imp50825, imp50830, imp50831, imp50832, imp50835, imp50850, imp50855, imp50862, imp50875, imp50880, imp50890, imp50896, imp50910, imp50911, imp50912, imp50913, imp50920, imp50928, imp50966, imp50975, imp51000, imp51001, imp51025, imp51050, imp51055, imp51060, imp51061, imp51070, imp51075, imp51115, imp51120, imp51121, imp51125, imp51130, imp51145, imp51147, imp51151, imp51152, imp51164, imp51215, imp51220, imp51225, imp51240, imp51250, imp51256, imp51260, imp51261, imp51265, imp51325, imp51328, imp51370, imp51371, imp51430, imp51445, imp51470, imp51535, imp51536, imp51561, imp51565, imp51570, imp51595, imp51605, imp51675, imp51730, imp51755, imp51835, imp51875, imp51877, imp51878, imp51880, imp51881, imp51946, imp52005, imp52201, imp52206, meas0001, meas0002, meas0003, meas0004, meas0005, meas0006, meas0007, meas0008, meas0009, meas0010, meas0011, meas0012, meas0013, meas0014, meas0015, meas0016, meas0017, meas0019, meas0020, meas0021, meas0023, meas0024, meas0025, meas0026, meas0027, meas0028, meas0029, meas0030, meas0031, meas0032, meas0033, meas0034, meas0035, meas0036, meas0037, meas0038, meas0045, meas0046, meas0047, meas0048, meas0054, meas0066, meas0067, meas0074, meas0076, meas0079, meas0084, meas0085, meas0086, meas0087, meas0088, meas0089, meas0090, meas0101, meas0103, meas0104, meas0115, meas0116, meas0117, meas0118, meas0128, meas0129, meas0130, meas0131, meas0148, meas0156, meas0157, meas0215, meas0221, meas0223, meas0224, meas0227, meas0228, meas0230, meas0232, meas0234, meas0237, meas0238, meas0239, meas0240, meas0242, meas0245, meas0251, meas0252, meas0257, meas0263, meas0272, meas0275, meas0279, meas0280, meas0285, meas0289, meas0290, meas0291, meas0292, meas0294, meas0295, meas0296, meas0297, meas0298, meas0302, meas0305, meas0307, meas0308, meas0311, meas0313, meas0314, meas0315, meas0316, meas0317, meas0318, meas0322, meas0324, meas0325, meas0326, meas0330, meas0332, meas0333, meas0335, meas0341, meas0345, meas0347, meas0363, meas0369, meas0371, meas0374, meas0409, meas0410, meas0411, meas0412, meas0413, meas0414, meas0415, meas0416, meas0420, meas0421, meas0422, meas0423, meas0424, meas0425, meas0426, meas0427, meas0428, meas0429, meas0430, meas0431, meas0432, meas0440, meas0445, meas0447, meas0450, meas0456, meas0459, meas0460, meas0470, meas0473, meas0474, meas0475, meas0476, meas0477, meas0478, meas0480, meas0481, meas0482, meas0483, meas0484, meas0485, meas0486, meas0487, meas0488, meas0493, meas0510, meas0513, meas0514, meas0515, meas0516, meas0517, meas0518, meas0533, meas0544, meas0545, meas0562, meas0567, meas0577, meas0580, meas0581, meas0584, meas0586, meas0593, meas0596, meas0599, meas0600, meas0601, meas0603, meas0608, meas0611, meas0612, meas0613, meas0623, meas0629, meas0630, meas0646, meas0650, meas0651, meas0671, meas0675, meas0679, meas0680, meas0683, meas0689, meas0693, meas0716, meas0741, meas0765, meas0766, meas0767, meas0768, meas0769, meas0770, meas0771, meas0772, meas0773, meas0774, meas0782, meas0783, meas0789, meas0790, meas0791, meas0792, meas0793, meas0794, meas0795, meas0801, meas0803, meas0804, meas0817, meas0819, meas0858, meas0865, meas0874, meas0875, meas0877, meas0880, meas0881, meas0884, meas0887, meas0890, meas0891, meas0893, meas0894, meas0921, meas1232, meas1255, meas1260, meas1326, meas1327, meas1331, meas1336, meas1346, meas1347, meas1349, meas1353, meas1367, meas1368, meas1442, meas1443, meas1444, meas1445, meas1464, meas1466, meas1467, meas1470, meas1471, meas1473, meas1475, meas1476, meas1478, meas1479, meas1480, meas1481, meas1483, meas1484, meas1485, meas1486, meas1487, meas1488, meas1489, meas1490, meas1492, meas1497, meas1498, meas1499, meas1501, meas1504, meas1505, meas1506, meas1507, meas1509, meas1511, meas1512, meas1513, meas1514, meas1515, meas1516, meas1517, meas1520, meas1521, meas1522, meas1523, meas1524, meas1525, meas1526, meas1527, meas1529, meas1530, meas1531, meas1532, meas1536, meas1537, meas1539, meas1540, meas1541, meas1543, meas1547, meas1548, meas1549, meas1550, meas1551, meas1552, meas1553, meas1554, meas1558, meas1568, meas1574, meas1584, meas1585, meas1586, meas1587, meas1588, meas1589, meas1590, meas1591, meas1592, meas1618, meas1622, meas1663, meas1664, meas1683, meas1684, meas1703, meas1704, meas1743, meas1744, meas1745, meas1746, meas1747, meas1748, meas1749, meas1750, meas1751, meas1752, meas1763, meas1783, meas1923, meas1924, meas1925, meas1926, meas1931, meas1932, meas1943, meas1963, meas2023, meas2024, meas2025, meas2026, meas2027, meas2028, meas2029, meas2030, meas2031, meas2032, meas2033, meas2034, meas2063, meas2064, meas2065, meas2123, meas2124, meas2203, meas2291, meas2292, meas2293, meas2294, meas2295, meas2296, meas2314, meas2319, meas2320, meas2321, meas2343, meas2365, meas2366, meas2369, meas2370, meas2373, meas2374, meas2383, meas2423, meas2424, meas2425, meas2426, meas2447, meas2487, meas2607, meas2627, meas2628, meas2629, meas2630, meas2667, meas2707, meas2787, meas2788, meas2847, meas2867, meas2887, meas3187, meas3188, meas3189, meas3207, meas3247, meas3248, meas3307, meas3627, meas3927, meas3928, meas3947, meas3987, meas4007, meas4047, meas4067, meas4107, meas4108, meas4247, meas4287, meas4307, meas4327, meas4447, meas4627, meas4647, meas4767, meas4768, meas4787, meas4807, meas4827, meas4828, meas5527, meas5647, meas5667, meas5907, meas5927, meas6029, meas6032, meas6047, meas6247, meas6248, meas6268, meas6287, meas6288, meas6307, meas6507, meas6527, meas6547, meas6567, ef`

## ID-like Columns
  procedure_id: 276 unique values
  visit_id: 276 unique values
  report_id: 276 unique values
  phase_id: 4 unique values
  RESEARCH_PROT_DEF_ID: 2 unique values
  STRESS_PROT_DEF_ID: 1 unique values


## Date Columns and Ranges
  birth_date: 1973-03-26 to 2004-07-20
  procedure_date: 2018-03-21 to 2026-02-27
  procedure_time: 1899-12-31 06:24:34 to 1899-12-31 19:06:18


## Missing Values (columns with any NA)
  REPORT_COMMENTS2: 317 (100%)
  imp02789: 317 (100%)
  imp02795: 317 (100%)
  imp02996: 317 (100%)
  imp03137: 317 (100%)
  imp03257: 317 (100%)
  imp03281: 317 (100%)
  imp03307: 317 (100%)
  imp03359: 317 (100%)
  imp03518: 317 (100%)
  imp03562: 317 (100%)
  imp03631: 317 (100%)
  imp03643: 317 (100%)
  imp03666: 317 (100%)
  imp03676: 317 (100%)
  imp03694: 317 (100%)
  imp03914: 317 (100%)
  imp03937: 317 (100%)
  imp03939: 317 (100%)
  imp03975: 317 (100%)
  imp03979: 317 (100%)
  imp04046: 317 (100%)
  imp04074: 317 (100%)
  imp04075: 317 (100%)
  imp04093: 317 (100%)
  imp04116: 317 (100%)
  imp04120: 317 (100%)
  imp04122: 317 (100%)
  imp04491: 317 (100%)
  imp04713: 317 (100%)
  imp04931: 317 (100%)
  imp05102: 317 (100%)
  imp05589: 317 (100%)
  imp05590: 317 (100%)
  imp05591: 317 (100%)
  imp05593: 317 (100%)
  imp05712: 317 (100%)
  imp05733: 317 (100%)
  imp05773: 317 (100%)
  imp05795: 317 (100%)
  imp05858: 317 (100%)
  imp06224: 317 (100%)
  imp07245: 317 (100%)
  imp07259: 317 (100%)
  imp07260: 317 (100%)
  imp07334: 317 (100%)
  imp07440: 317 (100%)
  imp07455: 317 (100%)
  imp07474: 317 (100%)
  imp07477: 317 (100%)
  imp07511: 317 (100%)
  imp07512: 317 (100%)
  imp07513: 317 (100%)
  imp07518: 317 (100%)
  imp07519: 317 (100%)
  imp07583: 317 (100%)
  imp07994: 317 (100%)
  imp08192: 317 (100%)
  imp08310: 317 (100%)
  imp08529: 317 (100%)
  imp08689: 317 (100%)
  imp08912: 317 (100%)
  imp09255: 317 (100%)
  imp09997: 317 (100%)
  imp10006: 317 (100%)
  imp10803: 317 (100%)
  imp10860: 317 (100%)
  imp10943: 317 (100%)
  imp12181: 317 (100%)
  imp12199: 317 (100%)
  imp12419: 317 (100%)
  imp12479: 317 (100%)
  imp12799: 317 (100%)
  imp13141: 317 (100%)
  imp13219: 317 (100%)
  imp13479: 317 (100%)
  imp50022: 317 (100%)
  imp50105: 317 (100%)
  imp50111: 317 (100%)
  imp50209: 317 (100%)
  imp50225: 317 (100%)
  imp50536: 317 (100%)
  imp50580: 317 (100%)
  imp50581: 317 (100%)
  imp50582: 317 (100%)
  imp50583: 317 (100%)
  imp50584: 317 (100%)
  imp50585: 317 (100%)
  imp50590: 317 (100%)
  imp50685: 317 (100%)
  imp50740: 317 (100%)
  imp50805: 317 (100%)
  imp50875: 317 (100%)
  imp50928: 317 (100%)
  imp51000: 317 (100%)
  imp51001: 317 (100%)
  imp51061: 317 (100%)
  imp51130: 317 (100%)
  imp51151: 317 (100%)
  imp51152: 317 (100%)
  imp51256: 317 (100%)
  imp51260: 317 (100%)
  imp51570: 317 (100%)
  meas0014: 317 (100%)
  meas0030: 317 (100%)
  meas0038: 317 (100%)
  meas0085: 317 (100%)
  meas0148: 317 (100%)
  meas0215: 317 (100%)
  meas0228: 317 (100%)
  meas0369: 317 (100%)
  meas0371: 317 (100%)
  meas0374: 317 (100%)
  meas0470: 317 (100%)
  meas0544: 317 (100%)
  meas0716: 317 (100%)
  meas0783: 317 (100%)
  meas0801: 317 (100%)
  meas0858: 317 (100%)
  meas0874: 317 (100%)
  meas0894: 317 (100%)
  meas1232: 317 (100%)
  meas1326: 317 (100%)
  meas1331: 317 (100%)
  meas1464: 317 (100%)
  meas1471: 317 (100%)
  meas1497: 317 (100%)
  meas1507: 317 (100%)
  meas1536: 317 (100%)
  meas1539: 317 (100%)
  meas1589: 317 (100%)
  meas1590: 317 (100%)
  meas1591: 317 (100%)
  meas1592: 317 (100%)
  meas1749: 317 (100%)
  meas1923: 317 (100%)
  meas1924: 317 (100%)
  meas1926: 317 (100%)
  meas1943: 317 (100%)
  meas2667: 317 (100%)
  meas3247: 317 (100%)
  meas3248: 317 (100%)
  meas3307: 317 (100%)
  meas6567: 317 (100%)
  imp03134: 316 (99.7%)
  imp03136: 316 (99.7%)
  imp03273: 316 (99.7%)
  imp03495: 316 (99.7%)
  imp03577: 316 (99.7%)
  imp03651: 316 (99.7%)
  imp03653: 316 (99.7%)
  imp03839: 316 (99.7%)
  imp03928: 316 (99.7%)
  imp03931: 316 (99.7%)
  imp04036: 316 (99.7%)
  imp04119: 316 (99.7%)
  imp04862: 316 (99.7%)
  imp04865: 316 (99.7%)
  imp04869: 316 (99.7%)
  imp04915: 316 (99.7%)
  imp05043: 316 (99.7%)
  imp05065: 316 (99.7%)
  imp05073: 316 (99.7%)
  imp05401: 316 (99.7%)
  imp05560: 316 (99.7%)
  imp05566: 316 (99.7%)
  imp05614: 316 (99.7%)
  imp06232: 316 (99.7%)
  imp06238: 316 (99.7%)
  imp06512: 316 (99.7%)
  imp06520: 316 (99.7%)
  imp06522: 316 (99.7%)
  imp06523: 316 (99.7%)
  imp07270: 316 (99.7%)
  imp07480: 316 (99.7%)
  imp07481: 316 (99.7%)
  imp10402: 316 (99.7%)
  imp10816: 316 (99.7%)
  imp11299: 316 (99.7%)
  imp13148: 316 (99.7%)
  imp13260: 316 (99.7%)
  imp50060: 316 (99.7%)
  imp50576: 316 (99.7%)
  imp50775: 316 (99.7%)
  imp51120: 316 (99.7%)
  imp51125: 316 (99.7%)
  imp51147: 316 (99.7%)
  imp51164: 316 (99.7%)
  imp51265: 316 (99.7%)
  imp51430: 316 (99.7%)
  imp51675: 316 (99.7%)
  imp51755: 316 (99.7%)
  imp52201: 316 (99.7%)
  imp52206: 316 (99.7%)
  meas0079: 316 (99.7%)
  meas0088: 316 (99.7%)
  meas0101: 316 (99.7%)
  meas0221: 316 (99.7%)
  meas0230: 316 (99.7%)
  meas0460: 316 (99.7%)
  meas0562: 316 (99.7%)
  meas0608: 316 (99.7%)
  meas0611: 316 (99.7%)
  meas0612: 316 (99.7%)
  meas0623: 316 (99.7%)
  meas0629: 316 (99.7%)
  meas0646: 316 (99.7%)
  meas0650: 316 (99.7%)
  meas0651: 316 (99.7%)
  meas0671: 316 (99.7%)
  meas0675: 316 (99.7%)
  meas0693: 316 (99.7%)
  meas0819: 316 (99.7%)
  meas0877: 316 (99.7%)
  meas0880: 316 (99.7%)
  meas0884: 316 (99.7%)
  meas0887: 316 (99.7%)
  meas0890: 316 (99.7%)
  meas0891: 316 (99.7%)
  meas0893: 316 (99.7%)
  meas1346: 316 (99.7%)
  meas1368: 316 (99.7%)
  meas1683: 316 (99.7%)
  meas1684: 316 (99.7%)
  meas1746: 316 (99.7%)
  meas2314: 316 (99.7%)
  meas5647: 316 (99.7%)
  meas5667: 316 (99.7%)
  meas6247: 316 (99.7%)
  meas6248: 316 (99.7%)
  meas6268: 316 (99.7%)
  meas6507: 316 (99.7%)
  meas6527: 316 (99.7%)
  meas6547: 316 (99.7%)
  RESEARCH_PROT_DEF_ID: 315 (99.4%)
  imp03139: 315 (99.4%)
  imp03556: 315 (99.4%)
  imp03961: 315 (99.4%)
  imp04044: 315 (99.4%)
  imp04195: 315 (99.4%)
  imp04373: 315 (99.4%)
  imp04374: 315 (99.4%)
  imp05057: 315 (99.4%)
  imp05120: 315 (99.4%)
  imp05129: 315 (99.4%)
  imp07254: 315 (99.4%)
  imp08049: 315 (99.4%)
  imp08243: 315 (99.4%)
  imp09326: 315 (99.4%)
  imp10043: 315 (99.4%)
  imp10423: 315 (99.4%)
  imp10426: 315 (99.4%)
  imp10819: 315 (99.4%)
  imp10820: 315 (99.4%)
  imp10821: 315 (99.4%)
  imp12445: 315 (99.4%)
  imp12454: 315 (99.4%)
  imp50266: 315 (99.4%)
  imp50435: 315 (99.4%)
  imp50675: 315 (99.4%)
  imp51025: 315 (99.4%)
  imp51371: 315 (99.4%)
  imp51730: 315 (99.4%)
  meas0001: 315 (99.4%)
  meas0002: 315 (99.4%)
  meas0003: 315 (99.4%)
  meas0004: 315 (99.4%)
  meas0005: 315 (99.4%)
  meas0006: 315 (99.4%)
  meas0007: 315 (99.4%)
  meas0054: 315 (99.4%)
  meas0103: 315 (99.4%)
  meas0234: 315 (99.4%)
  meas0275: 315 (99.4%)
  meas0326: 315 (99.4%)
  meas0450: 315 (99.4%)
  meas0577: 315 (99.4%)
  meas0593: 315 (99.4%)
  meas0596: 315 (99.4%)
  meas0599: 315 (99.4%)
  meas0600: 315 (99.4%)
  meas0601: 315 (99.4%)
  meas0603: 315 (99.4%)
  meas0613: 315 (99.4%)
  meas0803: 315 (99.4%)
  meas1347: 315 (99.4%)
  meas1349: 315 (99.4%)
  meas1353: 315 (99.4%)
  meas1442: 315 (99.4%)
  meas1466: 315 (99.4%)
  meas1467: 315 (99.4%)
  meas1470: 315 (99.4%)
  meas1473: 315 (99.4%)
  meas1475: 315 (99.4%)
  meas1476: 315 (99.4%)
  meas1478: 315 (99.4%)
  meas1479: 315 (99.4%)
  meas1480: 315 (99.4%)
  meas1481: 315 (99.4%)
  meas1483: 315 (99.4%)
  meas1484: 315 (99.4%)
  meas1485: 315 (99.4%)
  meas1486: 315 (99.4%)
  meas1487: 315 (99.4%)
  meas1488: 315 (99.4%)
  meas1489: 315 (99.4%)
  meas1490: 315 (99.4%)
  meas1498: 315 (99.4%)
  meas1499: 315 (99.4%)
  meas1501: 315 (99.4%)
  meas1504: 315 (99.4%)
  meas1505: 315 (99.4%)
  meas1506: 315 (99.4%)
  meas1509: 315 (99.4%)
  meas1511: 315 (99.4%)
  meas1512: 315 (99.4%)
  meas1513: 315 (99.4%)
  meas1514: 315 (99.4%)
  meas1515: 315 (99.4%)
  meas1516: 315 (99.4%)
  meas1517: 315 (99.4%)
  meas1520: 315 (99.4%)
  meas1521: 315 (99.4%)
  meas1522: 315 (99.4%)
  meas1523: 315 (99.4%)
  meas1524: 315 (99.4%)
  meas1525: 315 (99.4%)
  meas1526: 315 (99.4%)
  meas1527: 315 (99.4%)
  meas1529: 315 (99.4%)
  meas1530: 315 (99.4%)
  meas1531: 315 (99.4%)
  meas1532: 315 (99.4%)
  meas1537: 315 (99.4%)
  meas1540: 315 (99.4%)
  meas1541: 315 (99.4%)
  meas1543: 315 (99.4%)
  meas1547: 315 (99.4%)
  meas1548: 315 (99.4%)
  meas1549: 315 (99.4%)
  meas1550: 315 (99.4%)
  meas1551: 315 (99.4%)
  meas1552: 315 (99.4%)
  meas1553: 315 (99.4%)
  meas1558: 315 (99.4%)
  meas1584: 315 (99.4%)
  meas1585: 315 (99.4%)
  meas1586: 315 (99.4%)
  meas1587: 315 (99.4%)
  meas1588: 315 (99.4%)
  meas1703: 315 (99.4%)
  meas1704: 315 (99.4%)
  meas1744: 315 (99.4%)
  meas1745: 315 (99.4%)
  meas1747: 315 (99.4%)
  meas1748: 315 (99.4%)
  meas2447: 315 (99.4%)
  meas2887: 315 (99.4%)
  meas3188: 315 (99.4%)
  meas3189: 315 (99.4%)
  meas4307: 315 (99.4%)
  meas4327: 315 (99.4%)
  meas4767: 315 (99.4%)
  meas4768: 315 (99.4%)
  meas4787: 315 (99.4%)
  meas4807: 315 (99.4%)
  meas4827: 315 (99.4%)
  meas4828: 315 (99.4%)
  imp02810: 314 (99.1%)
  imp03470: 314 (99.1%)
  imp03780: 314 (99.1%)
  imp04508: 314 (99.1%)
  imp04791: 314 (99.1%)
  imp05044: 314 (99.1%)
  imp05094: 314 (99.1%)
  imp05398: 314 (99.1%)
  imp06521: 314 (99.1%)
  imp07266: 314 (99.1%)
  imp07333: 314 (99.1%)
  imp07375: 314 (99.1%)
  imp07551: 314 (99.1%)
  imp09202: 314 (99.1%)
  imp09209: 314 (99.1%)
  imp09929: 314 (99.1%)
  imp13059: 314 (99.1%)
  imp50211: 314 (99.1%)
  imp50252: 314 (99.1%)
  imp50815: 314 (99.1%)
  imp50862: 314 (99.1%)
  imp50920: 314 (99.1%)
  imp51225: 314 (99.1%)
  imp51445: 314 (99.1%)
  imp51877: 314 (99.1%)
  imp51878: 314 (99.1%)
  imp51880: 314 (99.1%)
  imp51881: 314 (99.1%)
  imp51946: 314 (99.1%)
  meas0335: 314 (99.1%)
  meas0341: 314 (99.1%)
  meas0881: 314 (99.1%)
  meas1443: 314 (99.1%)
  meas1751: 314 (99.1%)
  meas1752: 314 (99.1%)
  meas2423: 314 (99.1%)
  meas2424: 314 (99.1%)
  meas2425: 314 (99.1%)
  meas2426: 314 (99.1%)
  meas6047: 314 (99.1%)
  imp03623: 313 (98.7%)
  imp03930: 313 (98.7%)
  imp04864: 313 (98.7%)
  imp05231: 313 (98.7%)
  imp05541: 313 (98.7%)
  imp05588: 313 (98.7%)
  imp07553: 313 (98.7%)
  imp08669: 313 (98.7%)
  imp12619: 313 (98.7%)
  imp13419: 313 (98.7%)
  imp50816: 313 (98.7%)
  imp50975: 313 (98.7%)
  imp51328: 313 (98.7%)
  imp51835: 313 (98.7%)
  imp51875: 313 (98.7%)
  meas0066: 313 (98.7%)
  meas0067: 313 (98.7%)
  meas0087: 313 (98.7%)
  meas0115: 313 (98.7%)
  meas0116: 313 (98.7%)
  meas0128: 313 (98.7%)
  meas0129: 313 (98.7%)
  meas0240: 313 (98.7%)
  meas0680: 313 (98.7%)
  meas1743: 313 (98.7%)
  meas1963: 313 (98.7%)
  meas3187: 313 (98.7%)
  meas3207: 313 (98.7%)
  meas3627: 313 (98.7%)
  meas4447: 313 (98.7%)
  meas5907: 313 (98.7%)
  imp03554: 312 (98.4%)
  imp05408: 312 (98.4%)
  imp07560: 312 (98.4%)
  imp08729: 312 (98.4%)
  imp51565: 312 (98.4%)
  meas0089: 312 (98.4%)
  meas0227: 312 (98.4%)
  meas0332: 312 (98.4%)
  meas0363: 312 (98.4%)
  meas0545: 312 (98.4%)
  meas1327: 312 (98.4%)
  meas1336: 312 (98.4%)
  meas1444: 312 (98.4%)
  meas1445: 312 (98.4%)
  meas1492: 312 (98.4%)
  meas2366: 312 (98.4%)
  meas2787: 312 (98.4%)
  meas2788: 312 (98.4%)
  meas3987: 312 (98.4%)
  meas6029: 312 (98.4%)
  meas6032: 312 (98.4%)
  meas6307: 312 (98.4%)
  imp05396: 311 (98.1%)
  imp11879: 311 (98.1%)
  imp51070: 311 (98.1%)
  imp51121: 311 (98.1%)
  imp51535: 311 (98.1%)
  meas0074: 311 (98.1%)
  meas0076: 311 (98.1%)
  meas0333: 311 (98.1%)
  meas0586: 311 (98.1%)
  meas0875: 311 (98.1%)
  meas1750: 311 (98.1%)
  meas4007: 311 (98.1%)
  imp02802: 310 (97.8%)
  imp07272: 310 (97.8%)
  imp50890: 310 (97.8%)
  imp51325: 310 (97.8%)
  imp51595: 310 (97.8%)
  meas1568: 310 (97.8%)
  meas1574: 310 (97.8%)
  meas1618: 310 (97.8%)
  meas2023: 310 (97.8%)
  meas2024: 310 (97.8%)
  meas2025: 310 (97.8%)
  meas2026: 310 (97.8%)
  meas2027: 310 (97.8%)
  meas2028: 310 (97.8%)
  meas2029: 310 (97.8%)
  meas2030: 310 (97.8%)
  meas2031: 310 (97.8%)
  meas2032: 310 (97.8%)
  meas2033: 310 (97.8%)
  meas2034: 310 (97.8%)
  meas2123: 310 (97.8%)
  meas2124: 310 (97.8%)
  meas2291: 310 (97.8%)
  meas2292: 310 (97.8%)
  meas2293: 310 (97.8%)
  meas2294: 310 (97.8%)
  meas2295: 310 (97.8%)
  meas4287: 310 (97.8%)
  imp12999: 309 (97.5%)
  imp50212: 309 (97.5%)
  imp51261: 309 (97.5%)
  meas0459: 309 (97.5%)
  meas1255: 309 (97.5%)
  meas2319: 309 (97.5%)
  meas2320: 309 (97.5%)
  meas2321: 309 (97.5%)
  meas2343: 309 (97.5%)
  imp50855: 308 (97.2%)
  imp50910: 308 (97.2%)
  imp50912: 308 (97.2%)
  meas0029: 308 (97.2%)
  meas1931: 308 (97.2%)
  imp05564: 307 (96.8%)
  imp09196: 307 (96.8%)
  imp12739: 307 (96.8%)
  imp13000: 307 (96.8%)
  imp50470: 307 (96.8%)
  imp50509: 307 (96.8%)
  meas0584: 307 (96.8%)
  meas1554: 307 (96.8%)
  meas2063: 307 (96.8%)
  meas2064: 307 (96.8%)
  meas2065: 307 (96.8%)
  meas2867: 307 (96.8%)
  meas3927: 307 (96.8%)
  meas3928: 307 (96.8%)
  meas3947: 307 (96.8%)
  imp11200: 306 (96.5%)
  meas0245: 306 (96.5%)
  meas0409: 306 (96.5%)
  meas0410: 306 (96.5%)
  meas0411: 306 (96.5%)
  meas0412: 306 (96.5%)
  meas0413: 306 (96.5%)
  meas0414: 306 (96.5%)
  meas0415: 306 (96.5%)
  meas0416: 306 (96.5%)
  meas0421: 306 (96.5%)
  meas0422: 306 (96.5%)
  meas0423: 306 (96.5%)
  meas0424: 306 (96.5%)
  meas0425: 306 (96.5%)
  meas0426: 306 (96.5%)
  meas0427: 306 (96.5%)
  meas0428: 306 (96.5%)
  meas0429: 306 (96.5%)
  meas0430: 306 (96.5%)
  meas0431: 306 (96.5%)
  meas0432: 306 (96.5%)
  meas0473: 306 (96.5%)
  meas0474: 306 (96.5%)
  meas0475: 306 (96.5%)
  meas0476: 306 (96.5%)
  meas0477: 306 (96.5%)
  meas0478: 306 (96.5%)
  meas0480: 306 (96.5%)
  meas0481: 306 (96.5%)
  meas0482: 306 (96.5%)
  meas0483: 306 (96.5%)
  meas0484: 306 (96.5%)
  meas0485: 306 (96.5%)
  meas0486: 306 (96.5%)
  meas0533: 306 (96.5%)
  meas0630: 306 (96.5%)
  meas0765: 306 (96.5%)
  meas0766: 306 (96.5%)
  meas0767: 306 (96.5%)
  meas0768: 306 (96.5%)
  meas0769: 306 (96.5%)
  meas0770: 306 (96.5%)
  meas0771: 306 (96.5%)
  meas0772: 306 (96.5%)
  meas0773: 306 (96.5%)
  meas0774: 306 (96.5%)
  meas0789: 306 (96.5%)
  meas0790: 306 (96.5%)
  meas0791: 306 (96.5%)
  meas0792: 306 (96.5%)
  meas0793: 306 (96.5%)
  meas0794: 306 (96.5%)
  meas1932: 306 (96.5%)
  imp03918: 305 (96.2%)
  imp05587: 305 (96.2%)
  imp11979: 305 (96.2%)
  imp50575: 305 (96.2%)
  imp51115: 305 (96.2%)
  meas0580: 305 (96.2%)
  meas0683: 305 (96.2%)
  meas0689: 305 (96.2%)
  meas0224: 304 (95.9%)
  meas0322: 304 (95.9%)
  meas0817: 304 (95.9%)
  meas2607: 304 (95.9%)
  meas5927: 304 (95.9%)
  imp02844: 303 (95.6%)
  imp10413: 303 (95.6%)
  imp51536: 303 (95.6%)
  imp51605: 303 (95.6%)
  meas0295: 303 (95.6%)
  meas6287: 303 (95.6%)
  imp03946: 302 (95.3%)
  imp05586: 302 (95.3%)
  meas0086: 302 (95.3%)
  meas2374: 301 (95%)
  STRESS_PROT_DEF_ID: 299 (94.3%)
  imp02786: 299 (94.3%)
  imp02787: 299 (94.3%)
  imp02813: 299 (94.3%)
  imp05585: 299 (94.3%)
  imp05598: 299 (94.3%)
  imp05653: 299 (94.3%)
  imp05719: 299 (94.3%)
  imp06591: 299 (94.3%)
  imp06592: 299 (94.3%)
  imp07285: 299 (94.3%)
  imp11100: 299 (94.3%)
  imp12480: 299 (94.3%)
  imp12859: 299 (94.3%)
  imp51060: 299 (94.3%)
  imp51215: 299 (94.3%)
  meas0223: 299 (94.3%)
  meas0325: 299 (94.3%)
  meas0345: 299 (94.3%)
  meas0347: 299 (94.3%)
  meas0741: 299 (94.3%)
  meas2365: 299 (94.3%)
  meas2370: 299 (94.3%)
  meas2627: 299 (94.3%)
  meas2628: 299 (94.3%)
  meas2629: 299 (94.3%)
  meas2630: 299 (94.3%)
  meas4108: 299 (94.3%)
  meas0257: 298 (94%)
  meas2369: 298 (94%)
  meas4107: 298 (94%)
  meas6288: 296 (93.4%)
  imp03140: 295 (93.1%)
  imp11859: 293 (92.4%)
  meas2373: 293 (92.4%)
  imp07525: 292 (92.1%)
  imp50765: 292 (92.1%)
  imp50766: 292 (92.1%)
  imp51055: 292 (92.1%)
  imp50911: 291 (91.8%)
  imp51470: 291 (91.8%)
  meas0238: 290 (91.5%)
  imp51240: 289 (91.2%)
  imp51250: 289 (91.2%)
  meas4247: 289 (91.2%)
  imp10425: 288 (90.9%)
  imp50850: 288 (90.9%)
  imp51050: 287 (90.5%)
  meas5527: 285 (89.9%)
  meas2383: 284 (89.6%)
  meas0090: 283 (89.3%)
  meas0308: 282 (89%)
  imp51370: 281 (88.6%)
  meas0280: 280 (88.3%)
  meas2296: 277 (87.4%)
  meas0239: 275 (86.8%)
  meas0037: 273 (86.1%)
  REPORT_COMMENTS: 270 (85.2%)
  imp52005: 268 (84.5%)
  meas0035: 266 (83.9%)
  meas0036: 266 (83.9%)
  meas0804: 266 (83.9%)
  meas0046: 265 (83.6%)
  meas0047: 265 (83.6%)
  meas0130: 265 (83.6%)
  meas0296: 265 (83.6%)
  meas0297: 265 (83.6%)
  imp51145: 264 (83.3%)
  imp50806: 263 (83%)
  imp51561: 262 (82.6%)
  meas0795: 261 (82.3%)
  imp06519: 260 (82%)
  meas4067: 260 (82%)
  imp50825: 258 (81.4%)
  meas0440: 258 (81.4%)
  meas0447: 258 (81.4%)
  meas0510: 258 (81.4%)
  meas0513: 258 (81.4%)
  meas0514: 258 (81.4%)
  meas0517: 258 (81.4%)
  meas0518: 258 (81.4%)
  meas2707: 258 (81.4%)
  meas2847: 258 (81.4%)
  imp10514: 256 (80.8%)
  meas0493: 256 (80.8%)
  imp50880: 255 (80.4%)
  imp51075: 255 (80.4%)
  imp11880: 254 (80.1%)
  meas0445: 254 (80.1%)
  meas0515: 254 (80.1%)
  meas0516: 254 (80.1%)
  meas0782: 254 (80.1%)
  meas0237: 252 (79.5%)
  meas0292: 252 (79.5%)
  meas0487: 252 (79.5%)
  meas0865: 252 (79.5%)
  meas0045: 249 (78.5%)
  meas0084: 249 (78.5%)
  meas0456: 249 (78.5%)
  meas0679: 249 (78.5%)
  meas0242: 248 (78.2%)
  meas0567: 248 (78.2%)
  imp50401: 245 (77.3%)
  imp50913: 245 (77.3%)
  meas0289: 245 (77.3%)
  meas0032: 244 (77%)
  imp03135: 242 (76.3%)
  imp10513: 242 (76.3%)
  meas4047: 242 (76.3%)
  meas0921: 239 (75.4%)
  meas1663: 239 (75.4%)
  meas1664: 239 (75.4%)
  meas2203: 239 (75.4%)
  meas2487: 239 (75.4%)
  meas0420: 238 (75.1%)
  meas0488: 238 (75.1%)
  meas0131: 237 (74.8%)
  meas4647: 236 (74.4%)
  meas4627: 234 (73.8%)
  imp51220: 233 (73.5%)
  meas0025: 233 (73.5%)
  meas0026: 233 (73.5%)
  meas0117: 233 (73.5%)
  meas0118: 233 (73.5%)
  meas1925: 233 (73.5%)
  imp50000: 232 (73.2%)
  meas0581: 230 (72.6%)
  meas0028: 227 (71.6%)
  meas0031: 227 (71.6%)
  meas0034: 227 (71.6%)
  meas1367: 226 (71.3%)
  meas0008: 222 (70%)
  meas0009: 222 (70%)
  meas0015: 222 (70%)
  meas0016: 222 (70%)
  meas0023: 222 (70%)
  meas0024: 222 (70%)
  meas0048: 222 (70%)
  meas0330: 222 (70%)
  meas0017: 220 (69.4%)
  meas0019: 220 (69.4%)
  meas0020: 220 (69.4%)
  meas0021: 220 (69.4%)
  meas0033: 220 (69.4%)
  meas0291: 220 (69.4%)
  meas1622: 220 (69.4%)
  imp50237: 216 (68.1%)
  meas0010: 213 (67.2%)
  meas0011: 213 (67.2%)
  meas0012: 213 (67.2%)
  meas0013: 213 (67.2%)
  imp50400: 212 (66.9%)
  meas0027: 212 (66.9%)
  meas0104: 212 (66.9%)
  meas0232: 212 (66.9%)
  imp07265: 209 (65.9%)
  imp50405: 207 (65.3%)
  imp50406: 205 (64.7%)
  imp50235: 204 (64.4%)
  imp50236: 204 (64.4%)
  meas0290: 203 (64%)
  imp05804: 201 (63.4%)
  imp50832: 201 (63.4%)
  imp50835: 201 (63.4%)
  meas0324: 200 (63.1%)
  meas0156: 199 (62.8%)
  meas0157: 199 (62.8%)
  imp03479: 198 (62.5%)
  imp50896: 198 (62.5%)
  imp05808: 197 (62.1%)
  imp50238: 196 (61.8%)
  imp05774: 189 (59.6%)
  imp05780: 189 (59.6%)
  imp05798: 189 (59.6%)
  imp50966: 189 (59.6%)
  meas1763: 189 (59.6%)
  meas1783: 189 (59.6%)
  ef: 189 (59.6%)
  meas0298: 184 (58%)
  imp50260: 183 (57.7%)
  imp50831: 183 (57.7%)
  meas0263: 182 (57.4%)
  meas0307: 181 (57.1%)
  imp50830: 180 (56.8%)
  meas0302: 179 (56.5%)
  meas0294: 178 (56.2%)
  meas0311: 178 (56.2%)
  meas0272: 177 (55.8%)
  meas0279: 168 (53%)
  meas0285: 165 (52.1%)
  meas0251: 164 (51.7%)
  meas0252: 164 (51.7%)
  meas0305: 164 (51.7%)
  imp05394: 158 (49.8%)
  imp08069: 156 (49.2%)
  imp50034: 155 (48.9%)
  imp50031: 154 (48.6%)
  meas0315: 154 (48.6%)
  imp05399: 153 (48.3%)
  imp50042: 152 (47.9%)
  meas0314: 152 (47.9%)
  meas0313: 151 (47.6%)
  meas1260: 151 (47.6%)
  imp08070: 150 (47.3%)
  imp50041: 150 (47.3%)
  imp05400: 149 (47%)
  imp50033: 149 (47%)
  meas0316: 149 (47%)
  imp50038: 147 (46.4%)
  imp50039: 145 (45.7%)
  imp08071: 143 (45.1%)
  imp50040: 140 (44.2%)
  imp05599: 136 (42.9%)
  imp50037: 136 (42.9%)
  meas0317: 133 (42%)
  meas0318: 133 (42%)
  imp50032: 132 (41.6%)
  height: 81 (25.6%)
  bmi: 81 (25.6%)
  bsa: 81 (25.6%)
  weight: 15 (4.7%)
  phase_id: 2 (0.6%)
  phase_name: 2 (0.6%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             317   
Number of columns          847   
_______________________          
Column type frequency:           
  character                385   
  logical                  144   
  numeric                  315   
  POSIXct                  3     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
    skim_variable   n_missing complete_rate min  max empty n_unique whitespace
  1 first_name              0       1         3   11     0      155          0
  2 last_name               0       1         3   18     0      190          0
  3 gender                  0       1         6    6     0        1          0
  4 procedure_type          0       1         5   37     0        9          0
  5 REPORT_COMMENTS       270       0.148    31 1071     0       25          0
  6 location_name           0       1         6   34     0       19          0
  7 domain_name             0       1         7   10     0        5          0
  8 phase_name              2       0.994     7   14     0       10          0
  9 imp02786              299       0.0568   40   76     0        4          0
 10 imp02787              299       0.0568   43  268     0        2          0
 11 imp02802              310       0.0221   24   24     0        1          0
 12 imp02810              314       0.00946  41   41     0        1          0
 13 imp02813              299       0.0568   57  234     0        2          0
 14 imp02844              303       0.0442   39   39     0        1          0
 15 imp03134              316       0.00315  56   56     0        1          0
 16 imp03135              242       0.237    60   80     0       18          0
 17 imp03136              316       0.00315  82   82     0        1          0
 18 imp03139              315       0.00631  37   90     0        2          0
 19 imp03140              295       0.0694   36   36     0       19          0
 20 imp03273              316       0.00315  33   33     0        1          0
 21 imp03470              314       0.00946  64  130     0        2          0
 22 imp03479              198       0.375    38   84     0        2          0
 23 imp03495              316       0.00315  21   21     0        1          0
 24 imp03554              312       0.0158   46   46     0        4          0
 25 imp03556              315       0.00631  34   34     0        2          0
 26 imp03577              316       0.00315  26   26     0        1          0
 27 imp03623              313       0.0126  175  275     0        4          0
 28 imp03651              316       0.00315  67   67     0        1          0
 29 imp03653              316       0.00315  88   88     0        1          0
 30 imp03780              314       0.00946 108  108     0        3          0
 31 imp03839              316       0.00315  43   43     0        1          0
 32 imp03918              305       0.0379   47   47     0        1          0
 33 imp03928              316       0.00315  84   84     0        1          0
 34 imp03930              313       0.0126   43   43     0        1          0
 35 imp03931              316       0.00315  35   35     0        1          0
 36 imp03946              302       0.0473   44   44     0        1          0
 37 imp03961              315       0.00631  39   39     0        1          0
 38 imp04036              316       0.00315  26   26     0        1          0
 39 imp04044              315       0.00631  33   33     0        1          0
 40 imp04119              316       0.00315  95   95     0        1          0
 41 imp04195              315       0.00631  30   30     0        1          0
 42 imp04373              315       0.00631  41   41     0        1          0
 43 imp04374              315       0.00631  54   54     0        1          0
 44 imp04508              314       0.00946  35   35     0        1          0
 45 imp04791              314       0.00946  66   66     0        1          0
 46 imp04862              316       0.00315  14   14     0        1          0
 47 imp04864              313       0.0126   85  102     0        2          0
 48 imp04865              316       0.00315  11   11     0        1          0
 49 imp04869              316       0.00315  11   11     0        1          0
 50 imp04915              316       0.00315 109  109     0        1          0
 51 imp05043              316       0.00315 162  162     0        1          0
 52 imp05044              314       0.00946 169  169     0        1          0
 53 imp05057              315       0.00631  36   36     0        1          0
 54 imp05065              316       0.00315 109  109     0        1          0
 55 imp05073              316       0.00315  36   36     0        1          0
 56 imp05094              314       0.00946  53   53     0        1          0
 57 imp05120              315       0.00631 129  141     0        2          0
 58 imp05129              315       0.00631  99  257     0        2          0
 59 imp05231              313       0.0126   39   74     0        3          0
 60 imp05394              158       0.502    29  450     0        9          0
 61 imp05396              311       0.0189   46   87     0        3          0
 62 imp05398              314       0.00946  78  282     0        3          0
 63 imp05399              153       0.517    32  863     0        4          0
 64 imp05400              149       0.530    32   32     0        1          0
 65 imp05401              316       0.00315 121  121     0        1          0
 66 imp05408              312       0.0158  138  143     0        2          0
 67 imp05541              313       0.0126   37   38     0        4          0
 68 imp05560              316       0.00315  37   37     0        1          0
 69 imp05564              307       0.0315  151  151     0        1          0
 70 imp05566              316       0.00315  75   75     0        1          0
 71 imp05585              299       0.0568   12   12     0        1          0
 72 imp05586              302       0.0473   12   12     0        1          0
 73 imp05587              305       0.0379   14   14     0        1          0
 74 imp05588              313       0.0126   15   15     0        1          0
 75 imp05598              299       0.0568   22   54     0        2          0
 76 imp05599              136       0.571     6  755     0      145          0
 77 imp05614              316       0.00315  36   36     0        1          0
 78 imp05653              299       0.0568   59   59     0        1          0
 79 imp05719              299       0.0568   32  101     0        2          0
 80 imp05774              189       0.404    15   15     0        1          0
 81 imp05780              189       0.404    20   20     0        1          0
 82 imp05798              189       0.404    16   16     0        1          0
 83 imp05804              201       0.366     6    6     0        1          0
 84 imp05808              197       0.379    15   15     0        1          0
 85 imp06232              316       0.00315 146  146     0        1          0
 86 imp06238              316       0.00315  31   31     0        1          0
 87 imp06512              316       0.00315  40   40     0        1          0
 88 imp06519              260       0.180   106  121     0        2          0
 89 imp06520              316       0.00315  32   32     0        1          0
 90 imp06521              314       0.00946  32   91     0        2          0
 91 imp06522              316       0.00315  41   41     0        1          0
 92 imp06523              316       0.00315  41   41     0        1          0
 93 imp06591              299       0.0568   37   37     0        5          0
 94 imp06592              299       0.0568   31   31     0        5          0
 95 imp07254              315       0.00631  19   19     0        1          0
 96 imp07265              209       0.341   157  157     0        1          0
 97 imp07266              314       0.00946 134  254     0        3          0
 98 imp07270              316       0.00315  65   65     0        1          0
 99 imp07272              310       0.0221   50   50     0        1          0
100 imp07285              299       0.0568   64   64     0        5          0
101 imp07333              314       0.00946  57   57     0        1          0
102 imp07375              314       0.00946  54   54     0        1          0
103 imp07480              316       0.00315  40   40     0        1          0
104 imp07481              316       0.00315  39   39     0        1          0
105 imp07525              292       0.0789  163  163     0        1          0
106 imp07551              314       0.00946  64   64     0        1          0
107 imp07553              313       0.0126   69   69     0        4          0
108 imp07560              312       0.0158   63   63     0        5          0
109 imp08049              315       0.00631  33   33     0        1          0
110 imp08069              156       0.508    25  234     0       13          0
111 imp08070              150       0.527    19  131     0        6          0
112 imp08071              143       0.549    36   84     0        4          0
113 imp08243              315       0.00631  47   51     0        2          0
114 imp08669              313       0.0126   58   92     0        2          0
115 imp08729              312       0.0158   64   64     0        4          0
116 imp09196              307       0.0315  146  163     0        2          0
117 imp09202              314       0.00946  63   63     0        1          0
118 imp09209              314       0.00946 173  173     0        1          0
119 imp09326              315       0.00631 100  100     0        1          0
120 imp09929              314       0.00946  48   48     0        1          0
121 imp10043              315       0.00631  48   87     0        2          0
122 imp10402              316       0.00315  38   38     0        1          0
123 imp10413              303       0.0442   52   52     0        1          0
124 imp10423              315       0.00631  33   48     0        2          0
125 imp10425              288       0.0915   36   36     0        1          0
126 imp10426              315       0.00631  36   36     0        1          0
127 imp10513              242       0.237    44   44     0        1          0
128 imp10514              256       0.192    39   39     0        1          0
129 imp10816              316       0.00315  96   96     0        1          0
130 imp10819              315       0.00631  14   14     0        1          0
131 imp10820              315       0.00631  10   10     0        1          0
132 imp10821              315       0.00631  15   15     0        1          0
133 imp11100              299       0.0568   69  120     0        5          0
134 imp11200              306       0.0347  156  254     0        7          0
135 imp11299              316       0.00315 106  106     0        1          0
136 imp11859              293       0.0757   45   78     0        4          0
137 imp11879              311       0.0189   31   31     0        1          0
138 imp11880              254       0.199    40   40     0        1          0
139 imp11979              305       0.0379   72  117     0       12          0
140 imp12445              315       0.00631  40   40     0        1          0
141 imp12454              315       0.00631  51   51     0        1          0
142 imp12480              299       0.0568   53   55     0        5          0
143 imp12619              313       0.0126   51   51     0        1          0
144 imp12739              307       0.0315   27   27     0        1          0
145 imp12859              299       0.0568   43   43     0        1          0
146 imp12999              309       0.0252   39   79     0        2          0
147 imp13000              307       0.0315   36   36     0        1          0
148 imp13059              314       0.00946  79   79     0        1          0
149 imp13148              316       0.00315  34   34     0        1          0
150 imp13260              316       0.00315  89   89     0        1          0
151 imp13419              313       0.0126   77  102     0        2          0
152 imp50000              232       0.268    28   28     0       26          0
153 imp50031              154       0.514    61  359     0       27          0
154 imp50032              132       0.584    65   77     0      167          0
155 imp50033              149       0.530    20   20     0        1          0
156 imp50034              155       0.511    19  239     0        8          0
157 imp50037              136       0.571    72  123     0       40          0
158 imp50038              147       0.536    36   36     0        1          0
159 imp50039              145       0.543    72   72     0        1          0
160 imp50040              140       0.558    36   72     0        2          0
161 imp50041              150       0.527    84   84     0        1          0
162 imp50042              152       0.521    40   40     0        1          0
163 imp50060              316       0.00315  45   45     0        1          0
164 imp50211              314       0.00946  78  162     0        3          0
165 imp50212              309       0.0252   64   64     0        1          0
166 imp50235              204       0.356    30   41     0        6          0
167 imp50236              204       0.356    30  100     0        4          0
168 imp50237              216       0.319    33   38     0        4          0
169 imp50238              196       0.382    35   83     0        6          0
170 imp50252              314       0.00946  48   48     0        1          0
171 imp50260              183       0.423    24  138     0       18          0
172 imp50266              315       0.00631  39   39     0        1          0
173 imp50400              212       0.331    20   69     0        6          0
174 imp50401              245       0.227    23   23     0        1          0
175 imp50405              207       0.347    20   36     0        4          0
176 imp50406              205       0.353    23   33     0        2          0
177 imp50435              315       0.00631 104  104     0        1          0
178 imp50470              307       0.0315   26  252     0        2          0
179 imp50509              307       0.0315   93   93     0        1          0
180 imp50575              305       0.0379   58   58     0        1          0
181 imp50576              316       0.00315  67   67     0        1          0
182 imp50675              315       0.00631  70  103     0        2          0
183 imp50765              292       0.0789  231  231     0        1          0
184 imp50766              292       0.0789  107  108     0        2          0
185 imp50775              316       0.00315  98   98     0        1          0
186 imp50806              263       0.170    24  133     0        3          0
187 imp50815              314       0.00946 128  129     0        3          0
188 imp50816              313       0.0126   33  162     0        4          0
189 imp50825              258       0.186    38  142     0        3          0
190 imp50830              180       0.432    38  217     0       34          0
191 imp50831              183       0.423    39  157     0       22          0
192 imp50832              201       0.366    26   54     0        7          0
193 imp50835              201       0.366    25   60     0       14          0
194 imp50850              288       0.0915   33   76     0        2          0
195 imp50855              308       0.0284   81  106     0        3          0
196 imp50862              314       0.00946  44   44     0        1          0
197 imp50880              255       0.196    68   69     0       24          0
198 imp50890              310       0.0221   22   28     0        2          0
199 imp50896              198       0.375    32  100     0       15          0
200 imp50910              308       0.0284   32   44     0        2          0
201 imp50911              291       0.0820   40   72     0       13          0
202 imp50912              308       0.0284   40   92     0        7          0
203 imp50913              245       0.227    35   89     0       18          0
204 imp50920              314       0.00946 100  150     0        3          0
205 imp50966              189       0.404    43  102     0       11          0
206 imp50975              313       0.0126   42   42     0        2          0
207 imp51025              315       0.00631 151  154     0        2          0
208 imp51050              287       0.0946   41  355     0       13          0
209 imp51055              292       0.0789   47   47     0       10          0
210 imp51060              299       0.0568   45   51     0        2          0
211 imp51070              311       0.0189   40   40     0        5          0
212 imp51075              255       0.196    36   46     0        4          0
213 imp51115              305       0.0379   30   30     0        1          0
214 imp51120              316       0.00315 136  136     0        1          0
215 imp51121              311       0.0189  122  124     0        2          0
216 imp51125              316       0.00315  29   29     0        1          0
217 imp51145              264       0.167    45   87     0        5          0
218 imp51147              316       0.00315  85   85     0        1          0
219 imp51164              316       0.00315  50   50     0        1          0
220 imp51215              299       0.0568   52   52     0        5          0
221 imp51220              233       0.265    43   50     0        2          0
222 imp51225              314       0.00946  53   53     0        1          0
223 imp51240              289       0.0883   41  129     0        5          0
224 imp51250              289       0.0883   67   67     0        1          0
225 imp51261              309       0.0252   68   68     0        1          0
226 imp51265              316       0.00315  41   41     0        1          0
227 imp51325              310       0.0221   14   14     0        1          0
228 imp51328              313       0.0126   73   73     0        1          0
229 imp51370              281       0.114    27   87     0       12          0
230 imp51371              315       0.00631 104  104     0        1          0
231 imp51430              316       0.00315 116  116     0        1          0
232 imp51445              314       0.00946  22   78     0        2          0
233 imp51470              291       0.0820   63   75     0        2          0
234 imp51535              311       0.0189   74   74     0        3          0
235 imp51536              303       0.0442   77   77     0        5          0
236 imp51561              262       0.174    76  122     0       25          0
237 imp51565              312       0.0158   75  121     0        3          0
238 imp51595              310       0.0221  112  217     0        6          0
239 imp51605              303       0.0442   36  100     0        3          0
240 imp51675              316       0.00315  47   47     0        1          0
241 imp51730              315       0.00631 156  156     0        1          0
242 imp51755              316       0.00315 167  167     0        1          0
243 imp51835              313       0.0126  115  119     0        4          0
244 imp51875              313       0.0126   41   50     0        2          0
245 imp51877              314       0.00946  87   87     0        1          0
246 imp51878              314       0.00946  81   81     0        1          0
247 imp51880              314       0.00946  75   75     0        1          0
248 imp51881              314       0.00946  54   54     0        1          0
249 imp51946              314       0.00946  80   82     0        3          0
250 imp52005              268       0.155    24   79     0        5          0
251 imp52201              316       0.00315 199  199     0        1          0
252 imp52206              316       0.00315  56   56     0        1          0
253 meas0054              315       0.00631   4    4     0        1          0
254 meas0104              212       0.331     2    4     0        3          0
255 meas0227              312       0.0158   11   12     0        3          0
256 meas0230              316       0.00315   5    5     0        1          0
257 meas0232              212       0.331     2    6     0        3          0
258 meas0234              315       0.00631  10   10     0        1          0
259 meas0409              306       0.0347    2    2     0        1          0
260 meas0410              306       0.0347    2    4     0        3          0
261 meas0411              306       0.0347    2    2     0        1          0
262 meas0412              306       0.0347    4    4     0        2          0
263 meas0413              306       0.0347    2    2     0        1          0
264 meas0414              306       0.0347    2    4     0        3          0
265 meas0415              306       0.0347    2    2     0        1          0
266 meas0416              306       0.0347    2    4     0        3          0
267 meas0421              306       0.0347    2    2     0        1          0
268 meas0422              306       0.0347    4    4     0        1          0
269 meas0423              306       0.0347    2    2     0        1          0
270 meas0424              306       0.0347    4    4     0        1          0
271 meas0425              306       0.0347    2    2     0        1          0
272 meas0426              306       0.0347    4    4     0        1          0
273 meas0427              306       0.0347    2    2     0        1          0
274 meas0428              306       0.0347    4    4     0        1          0
275 meas0429              306       0.0347    2    2     0        1          0
276 meas0430              306       0.0347    4    4     0        1          0
277 meas0431              306       0.0347    2    2     0        1          0
278 meas0432              306       0.0347    4    4     0        1          0
279 meas0473              306       0.0347    2    2     0        1          0
280 meas0474              306       0.0347    4    4     0        1          0
281 meas0475              306       0.0347    2    2     0        1          0
282 meas0476              306       0.0347    4    4     0        1          0
283 meas0477              306       0.0347    2    2     0        1          0
284 meas0478              306       0.0347    4    4     0        1          0
285 meas0480              306       0.0347    2    2     0        1          0
286 meas0481              306       0.0347    4    4     0        1          0
287 meas0482              306       0.0347    2    2     0        1          0
288 meas0483              306       0.0347    4    4     0        1          0
289 meas0484              306       0.0347    2    2     0        1          0
290 meas0485              306       0.0347    4    4     0        1          0
291 meas0613              315       0.00631   6    6     0        1          0
292 meas0646              316       0.00315   3    3     0        1          0
293 meas0650              316       0.00315   3    3     0        1          0
294 meas0765              306       0.0347    2    2     0        1          0
295 meas0766              306       0.0347    4    4     0        1          0
296 meas0767              306       0.0347    2    2     0        1          0
297 meas0768              306       0.0347    4    4     0        1          0
298 meas0769              306       0.0347    2    2     0        1          0
299 meas0770              306       0.0347    4    4     0        1          0
300 meas0771              306       0.0347    2    2     0        1          0
301 meas0772              306       0.0347    4    4     0        1          0
302 meas0773              306       0.0347    2    2     0        1          0
303 meas0774              306       0.0347    4    4     0        1          0
304 meas0789              306       0.0347    2    2     0        1          0
305 meas0790              306       0.0347    4    4     0        1          0
306 meas0791              306       0.0347    2    2     0        1          0
307 meas0792              306       0.0347    4    4     0        1          0
308 meas0793              306       0.0347    2    2     0        1          0
309 meas0794              306       0.0347    4    4     0        1          0
310 meas1327              312       0.0158    8    8     0        1          0
311 meas1346              316       0.00315   6    6     0        1          0
312 meas1347              315       0.00631   2    2     0        1          0
313 meas1349              315       0.00631   3    3     0        1          0
314 meas1353              315       0.00631   3    3     0        1          0
315 meas1442              315       0.00631   6    6     0        1          0
316 meas1443              314       0.00946   9    9     0        1          0
317 meas1466              315       0.00631   1    1     0        2          0
318 meas1467              315       0.00631   1    1     0        1          0
319 meas1470              315       0.00631   1    1     0        1          0
320 meas1473              315       0.00631   1    1     0        2          0
321 meas1475              315       0.00631   1    1     0        1          0
322 meas1476              315       0.00631   4    4     0        1          0
323 meas1478              315       0.00631   2   10     0        2          0
324 meas1479              315       0.00631  14   14     0        1          0
325 meas1480              315       0.00631   1    1     0        2          0
326 meas1481              315       0.00631   1    1     0        1          0
327 meas1483              315       0.00631   1    1     0        1          0
328 meas1484              315       0.00631   1    1     0        1          0
329 meas1485              315       0.00631   1    1     0        1          0
330 meas1486              315       0.00631   1    1     0        1          0
331 meas1487              315       0.00631   2    2     0        1          0
332 meas1488              315       0.00631   1    1     0        1          0
333 meas1489              315       0.00631   2    2     0        1          0
334 meas1490              315       0.00631   1    1     0        2          0
335 meas1492              312       0.0158    6    6     0        1          0
336 meas1498              315       0.00631   1    1     0        2          0
337 meas1499              315       0.00631   1    1     0        1          0
338 meas1501              315       0.00631   1    1     0        1          0
339 meas1504              315       0.00631   4    6     0        2          0
340 meas1505              315       0.00631   6    6     0        1          0
341 meas1506              315       0.00631   4    4     0        1          0
342 meas1509              315       0.00631  10   10     0        1          0
343 meas1511              315       0.00631  10   10     0        1          0
344 meas1512              315       0.00631   1    1     0        1          0
345 meas1513              315       0.00631   1    1     0        1          0
346 meas1514              315       0.00631   1    1     0        1          0
347 meas1515              315       0.00631   4    4     0        1          0
348 meas1516              315       0.00631   4    4     0        1          0
349 meas1517              315       0.00631   7   10     0        2          0
350 meas1520              315       0.00631   2    2     0        1          0
351 meas1521              315       0.00631   2    2     0        1          0
352 meas1522              315       0.00631   2    7     0        2          0
353 meas1523              315       0.00631   2    2     0        1          0
354 meas1524              315       0.00631   7    9     0        2          0
355 meas1525              315       0.00631   2    2     0        1          0
356 meas1526              315       0.00631   1    1     0        1          0
357 meas1527              315       0.00631   4    4     0        1          0
358 meas1529              315       0.00631   2    2     0        1          0
359 meas1530              315       0.00631   5    5     0        1          0
360 meas1531              315       0.00631   1    1     0        1          0
361 meas1532              315       0.00631   4    4     0        1          0
362 meas1537              315       0.00631   4    4     0        2          0
363 meas1540              315       0.00631   1    1     0        2          0
364 meas1541              315       0.00631   4    4     0        1          0
365 meas1543              315       0.00631   1    1     0        1          0
366 meas1547              315       0.00631   1    1     0        1          0
367 meas1548              315       0.00631   3    3     0        1          0
368 meas1558              315       0.00631   1    1     0        1          0
369 meas1588              315       0.00631   1    1     0        1          0
370 meas1703              315       0.00631   6   14     0        2          0
371 meas1704              315       0.00631  12   18     0        2          0
372 meas1963              313       0.0126    1    1     0        1          0
373 meas2447              315       0.00631  13   13     0        1          0
374 meas2607              304       0.0410    6   12     0        2          0
375 meas4007              311       0.0189    2    2     0        1          0
376 meas4627              234       0.262     2    3     0        2          0
377 meas4647              236       0.256     2    3     0        2          0
378 meas4768              315       0.00631   5    5     0        1          0
379 meas4787              315       0.00631   2    2     0        1          0
380 meas4807              315       0.00631   2   11     0        2          0
381 meas4827              315       0.00631   2    2     0        1          0
382 meas4828              315       0.00631  15   15     0        1          0
383 meas5527              285       0.101     2    3     0        2          0
384 meas5667              316       0.00315  21   21     0        1          0
385 meas6047              314       0.00946   7    7     0        1          0

── Variable type: logical ──────────────────────────────────────────────────────
    skim_variable    n_missing complete_rate mean count
  1 REPORT_COMMENTS2       317             0  NaN ": " 
  2 imp02789               317             0  NaN ": " 
  3 imp02795               317             0  NaN ": " 
  4 imp02996               317             0  NaN ": " 
  5 imp03137               317             0  NaN ": " 
  6 imp03257               317             0  NaN ": " 
  7 imp03281               317             0  NaN ": " 
  8 imp03307               317             0  NaN ": " 
  9 imp03359               317             0  NaN ": " 
 10 imp03518               317             0  NaN ": " 
 11 imp03562               317             0  NaN ": " 
 12 imp03631               317             0  NaN ": " 
 13 imp03643               317             0  NaN ": " 
 14 imp03666               317             0  NaN ": " 
 15 imp03676               317             0  NaN ": " 
 16 imp03694               317             0  NaN ": " 
 17 imp03914               317             0  NaN ": " 
 18 imp03937               317             0  NaN ": " 
 19 imp03939               317             0  NaN ": " 
 20 imp03975               317             0  NaN ": " 
 21 imp03979               317             0  NaN ": " 
 22 imp04046               317             0  NaN ": " 
 23 imp04074               317             0  NaN ": " 
 24 imp04075               317             0  NaN ": " 
 25 imp04093               317             0  NaN ": " 
 26 imp04116               317             0  NaN ": " 
 27 imp04120               317             0  NaN ": " 
 28 imp04122               317             0  NaN ": " 
 29 imp04491               317             0  NaN ": " 
 30 imp04713               317             0  NaN ": " 
 31 imp04931               317             0  NaN ": " 
 32 imp05102               317             0  NaN ": " 
 33 imp05589               317             0  NaN ": " 
 34 imp05590               317             0  NaN ": " 
 35 imp05591               317             0  NaN ": " 
 36 imp05593               317             0  NaN ": " 
 37 imp05712               317             0  NaN ": " 
 38 imp05733               317             0  NaN ": " 
 39 imp05773               317             0  NaN ": " 
 40 imp05795               317             0  NaN ": " 
 41 imp05858               317             0  NaN ": " 
 42 imp06224               317             0  NaN ": " 
 43 imp07245               317             0  NaN ": " 
 44 imp07259               317             0  NaN ": " 
 45 imp07260               317             0  NaN ": " 
 46 imp07334               317             0  NaN ": " 
 47 imp07440               317             0  NaN ": " 
 48 imp07455               317             0  NaN ": " 
 49 imp07474               317             0  NaN ": " 
 50 imp07477               317             0  NaN ": " 
 51 imp07511               317             0  NaN ": " 
 52 imp07512               317             0  NaN ": " 
 53 imp07513               317             0  NaN ": " 
 54 imp07518               317             0  NaN ": " 
 55 imp07519               317             0  NaN ": " 
 56 imp07583               317             0  NaN ": " 
 57 imp07994               317             0  NaN ": " 
 58 imp08192               317             0  NaN ": " 
 59 imp08310               317             0  NaN ": " 
 60 imp08529               317             0  NaN ": " 
 61 imp08689               317             0  NaN ": " 
 62 imp08912               317             0  NaN ": " 
 63 imp09255               317             0  NaN ": " 
 64 imp09997               317             0  NaN ": " 
 65 imp10006               317             0  NaN ": " 
 66 imp10803               317             0  NaN ": " 
 67 imp10860               317             0  NaN ": " 
 68 imp10943               317             0  NaN ": " 
 69 imp12181               317             0  NaN ": " 
 70 imp12199               317             0  NaN ": " 
 71 imp12419               317             0  NaN ": " 
 72 imp12479               317             0  NaN ": " 
 73 imp12799               317             0  NaN ": " 
 74 imp13141               317             0  NaN ": " 
 75 imp13219               317             0  NaN ": " 
 76 imp13479               317             0  NaN ": " 
 77 imp50022               317             0  NaN ": " 
 78 imp50105               317             0  NaN ": " 
 79 imp50111               317             0  NaN ": " 
 80 imp50209               317             0  NaN ": " 
 81 imp50225               317             0  NaN ": " 
 82 imp50536               317             0  NaN ": " 
 83 imp50580               317             0  NaN ": " 
 84 imp50581               317             0  NaN ": " 
 85 imp50582               317             0  NaN ": " 
 86 imp50583               317             0  NaN ": " 
 87 imp50584               317             0  NaN ": " 
 88 imp50585               317             0  NaN ": " 
 89 imp50590               317             0  NaN ": " 
 90 imp50685               317             0  NaN ": " 
 91 imp50740               317             0  NaN ": " 
 92 imp50805               317             0  NaN ": " 
 93 imp50875               317             0  NaN ": " 
 94 imp50928               317             0  NaN ": " 
 95 imp51000               317             0  NaN ": " 
 96 imp51001               317             0  NaN ": " 
 97 imp51061               317             0  NaN ": " 
 98 imp51130               317             0  NaN ": " 
 99 imp51151               317             0  NaN ": " 
100 imp51152               317             0  NaN ": " 
101 imp51256               317             0  NaN ": " 
102 imp51260               317             0  NaN ": " 
103 imp51570               317             0  NaN ": " 
104 meas0014               317             0  NaN ": " 
105 meas0030               317             0  NaN ": " 
106 meas0038               317             0  NaN ": " 
107 meas0085               317             0  NaN ": " 
108 meas0148               317             0  NaN ": " 
109 meas0215               317             0  NaN ": " 
110 meas0228               317             0  NaN ": " 
111 meas0369               317             0  NaN ": " 
112 meas0371               317             0  NaN ": " 
113 meas0374               317             0  NaN ": " 
114 meas0470               317             0  NaN ": " 
115 meas0544               317             0  NaN ": " 
116 meas0716               317             0  NaN ": " 
117 meas0783               317             0  NaN ": " 
118 meas0801               317             0  NaN ": " 
119 meas0858               317             0  NaN ": " 
120 meas0874               317             0  NaN ": " 
121 meas0894               317             0  NaN ": " 
122 meas1232               317             0  NaN ": " 
123 meas1326               317             0  NaN ": " 
124 meas1331               317             0  NaN ": " 
125 meas1464               317             0  NaN ": " 
126 meas1471               317             0  NaN ": " 
127 meas1497               317             0  NaN ": " 
128 meas1507               317             0  NaN ": " 
129 meas1536               317             0  NaN ": " 
130 meas1539               317             0  NaN ": " 
131 meas1589               317             0  NaN ": " 
132 meas1590               317             0  NaN ": " 
133 meas1591               317             0  NaN ": " 
134 meas1592               317             0  NaN ": " 
135 meas1749               317             0  NaN ": " 
136 meas1923               317             0  NaN ": " 
137 meas1924               317             0  NaN ": " 
138 meas1926               317             0  NaN ": " 
139 meas1943               317             0  NaN ": " 
140 meas2667               317             0  NaN ": " 
141 meas3247               317             0  NaN ": " 
142 meas3248               317             0  NaN ": " 
143 meas3307               317             0  NaN ": " 
144 meas6567               317             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
    skim_variable        n_missing complete_rate          mean           sd
  1 curr_clinic                  0       1       9127245.      3153170.    
  2 input_clinic                 0       1       9127245.      3153170.    
  3 age_at_echo                  0       1            32.8           5.15  
  4 procedure_id                 0       1       3743079.       295956.    
  5 visit_id                     0       1       3778005.       304593.    
  6 height                      81       0.744         1.65          0.0689
  7 weight                      15       0.953       114.           24.5   
  8 bmi                         81       0.744        42.0           8.08  
  9 bsa                         81       0.744         2.17          0.237 
 10 report_id                    0       1       3726206.       306175.    
 11 is_stress                    0       1             0.0568        0.232 
 12 is_research                  0       1             0.00631       0.0793
 13 phase_id                     2       0.994         0.149         0.498 
 14 RESEARCH_PROT_DEF_ID       315       0.00631    7438.          977.    
 15 STRESS_PROT_DEF_ID         299       0.0568        1             0     
 16 meas0001                   315       0.00631       9.5           0.707 
 17 meas0002                   315       0.00631       9.5           0.707 
 18 meas0003                   315       0.00631      47             5.66  
 19 meas0004                   315       0.00631      29.5           4.95  
 20 meas0005                   315       0.00631      60.5           3.54  
 21 meas0006                   315       0.00631     155            45.3   
 22 meas0007                   315       0.00631      79.5           6.36  
 23 meas0008                   222       0.300         9.45          1.56  
 24 meas0009                   222       0.300         9.45          1.29  
 25 meas0010                   213       0.328        49.2           5.03  
 26 meas0011                   213       0.328        32.5           3.98  
 27 meas0012                   213       0.328        56.3           4.94  
 28 meas0013                   213       0.328        60.1           4.42  
 29 meas0015                   222       0.300       167.           47.9   
 30 meas0016                   222       0.300        75.7          17.0   
 31 meas0017                   220       0.306         2.22          0.157 
 32 meas0019                   220       0.306         1.14          0.166 
 33 meas0020                   220       0.306        21.8           3.52  
 34 meas0021                   220       0.306        84.5          18.3   
 35 meas0023                   222       0.300         7.08          1.77  
 36 meas0024                   222       0.300         3.24          0.737 
 37 meas0025                   233       0.265         1.48          0.242 
 38 meas0026                   233       0.265        27.9           5.38  
 39 meas0027                   212       0.331         0.82          0.199 
 40 meas0028                   227       0.284         0.607         0.161 
 41 meas0029                   308       0.0284        0.447         0.125 
 42 meas0031                   227       0.284         1.44          0.496 
 43 meas0032                   244       0.230       175.           27.9   
 44 meas0033                   220       0.306         0.105         0.0232
 45 meas0034                   227       0.284         8.06          2.37  
 46 meas0035                   266       0.161         0.498         0.112 
 47 meas0036                   266       0.161         0.475         0.126 
 48 meas0037                   273       0.139         0.270         0.0930
 49 meas0045                   249       0.215         1.17          0.334 
 50 meas0046                   265       0.164         2.32          0.271 
 51 meas0047                   265       0.164        21.8           5.11  
 52 meas0048                   222       0.300         6.06          2.70  
 53 meas0066                   313       0.0126       24             2.71  
 54 meas0067                   313       0.0126       25             2.83  
 55 meas0074                   311       0.0189        6.83          1.17  
 56 meas0076                   311       0.0189        1.28          0.117 
 57 meas0079                   316       0.00315      29            NA     
 58 meas0084                   249       0.215        30.2           3.62  
 59 meas0086                   302       0.0473       30.2           3.86  
 60 meas0087                   313       0.0126       31.5           1.29  
 61 meas0088                   316       0.00315      27            NA     
 62 meas0089                   312       0.0158       27.2           4.76  
 63 meas0090                   283       0.107        31.7           3.79  
 64 meas0101                   316       0.00315      16            NA     
 65 meas0103                   315       0.00631      18.5           3.54  
 66 meas0115                   313       0.0126        1.79          0.189 
 67 meas0116                   313       0.0126        1.68          0.111 
 68 meas0117                   233       0.265         3.11          0.586 
 69 meas0118                   233       0.265         3.05          0.531 
 70 meas0128                   313       0.0126        4             2.16  
 71 meas0129                   313       0.0126       10             3.92  
 72 meas0130                   265       0.164         2.31          1.21  
 73 meas0131                   237       0.252         5             1.68  
 74 meas0156                   199       0.372        77.0          10.9   
 75 meas0157                   199       0.372       127.           18.6   
 76 meas0221                   316       0.00315       6.8          NA     
 77 meas0223                   299       0.0568      392.           74.1   
 78 meas0224                   304       0.0410      147.           48.5   
 79 meas0237                   252       0.205         4.40          0.998 
 80 meas0238                   290       0.0852        4.33          1.14  
 81 meas0239                   275       0.132         3.40          0.663 
 82 meas0240                   313       0.0126        4             0.816 
 83 meas0242                   248       0.218         5.14          1.27  
 84 meas0245                   306       0.0347        4.82          1.72  
 85 meas0251                   164       0.483         0.301         0.0468
 86 meas0252                   164       0.483         6.94          3.05  
 87 meas0257                   298       0.0599        3.11          0.809 
 88 meas0263                   182       0.426         9.70          2.45  
 89 meas0272                   177       0.442        17.6           4.00  
 90 meas0275                   315       0.00631       4             1.41  
 91 meas0279                   168       0.470         0.461         0.0922
 92 meas0280                   280       0.117         7.24          1.71  
 93 meas0285                   165       0.479         0.292         0.0817
 94 meas0289                   245       0.227         5.81          1.53  
 95 meas0290                   203       0.360         0.860         0.210 
 96 meas0291                   220       0.306         0.103         0.0903
 97 meas0292                   252       0.205         4.97          1.40  
 98 meas0294                   178       0.438         0.566         0.133 
 99 meas0295                   303       0.0442        0.143         0.0852
100 meas0296                   265       0.164         0.260         0.260 
101 meas0297                   265       0.164         0.275         0.115 
102 meas0298                   184       0.420         9.99          3.05  
103 meas0302                   179       0.435        16.1           3.97  
104 meas0305                   164       0.483        22.9           8.97  
105 meas0307                   181       0.429         0.525         0.398 
106 meas0308                   282       0.110         7.89          1.94  
107 meas0311                   178       0.438         0.324         0.0769
108 meas0313                   151       0.524         0.113         0.0423
109 meas0314                   152       0.521         0.212         0.0660
110 meas0315                   154       0.514         1.33          0.356 
111 meas0316                   149       0.530         0.382         0.0963
112 meas0317                   133       0.580       413.           26.8   
113 meas0318                   133       0.580       146.            9.23  
114 meas0322                   304       0.0410       11.7           1.60  
115 meas0324                   200       0.369        91.6          25.3   
116 meas0325                   299       0.0568      161.            3.15  
117 meas0326                   315       0.00631      69.5           6.36  
118 meas0330                   222       0.300        85.8          21.2   
119 meas0332                   312       0.0158      164.           11.1   
120 meas0333                   311       0.0189       78.5          10.1   
121 meas0335                   314       0.00946      73.3           6.66  
122 meas0341                   314       0.00946      70.3           2.08  
123 meas0345                   299       0.0568    17571.         6654.    
124 meas0347                   299       0.0568      189.            3.92  
125 meas0363                   312       0.0158       75.6          22.8   
126 meas0420                   238       0.249         0.790         0.0978
127 meas0440                   258       0.186        59.8           5.32  
128 meas0445                   254       0.199        60.1           5.64  
129 meas0447                   258       0.186        59.8           4.42  
130 meas0450                   315       0.00631      64.5           3.54  
131 meas0456                   249       0.215       179.           15.1   
132 meas0459                   309       0.0252       35.9           2.53  
133 meas0460                   316       0.00315      40            NA     
134 meas0486                   306       0.0347       95.5          10.1   
135 meas0487                   252       0.205         0.329         0.104 
136 meas0488                   238       0.249         0.804         0.108 
137 meas0493                   256       0.192         3             0.949 
138 meas0510                   258       0.186        78.9          21.9   
139 meas0513                   258       0.186       130.           39.2   
140 meas0514                   258       0.186        52.6          19.2   
141 meas0515                   254       0.199       134.           39.8   
142 meas0516                   254       0.199        53.7          19.0   
143 meas0517                   258       0.186       132.           37.5   
144 meas0518                   258       0.186        53.4          18.0   
145 meas0533                   306       0.0347        1.06          0.146 
146 meas0545                   312       0.0158      118             6.93  
147 meas0562                   316       0.00315       4.7          NA     
148 meas0567                   248       0.218       239.           16.1   
149 meas0577                   315       0.00631       0.145         0.0636
150 meas0580                   305       0.0379        0.0925        0.0222
151 meas0581                   230       0.274         0.133         0.0324
152 meas0584                   307       0.0315        0.086         0.0227
153 meas0586                   311       0.0189        3.17          0.983 
154 meas0593                   315       0.00631      36             4.24  
155 meas0596                   315       0.00631      85            31.1   
156 meas0599                   315       0.00631       5.86          0.523 
157 meas0600                   315       0.00631       0.605         0.0778
158 meas0601                   315       0.00631     201.           31.0   
159 meas0603                   315       0.00631      28.5           9.19  
160 meas0608                   316       0.00315      17            NA     
161 meas0611                   316       0.00315       1            NA     
162 meas0612                   316       0.00315      97            NA     
163 meas0623                   316       0.00315      45            NA     
164 meas0629                   316       0.00315      24            NA     
165 meas0630                   306       0.0347        9.36          1.57  
166 meas0651                   316       0.00315     100            NA     
167 meas0671                   316       0.00315      27            NA     
168 meas0675                   316       0.00315     122            NA     
169 meas0679                   249       0.215         6.01          4.11  
170 meas0680                   313       0.0126       11.8           2.99  
171 meas0683                   305       0.0379        4.25          1.54  
172 meas0689                   305       0.0379        0.983         0.195 
173 meas0693                   316       0.00315      44.8          NA     
174 meas0741                   299       0.0568    25667.         3716.    
175 meas0782                   254       0.199       178.           14.9   
176 meas0795                   261       0.177         0.365         0.107 
177 meas0803                   315       0.00631      17.4           4.74  
178 meas0804                   266       0.161        27.9           6.96  
179 meas0817                   304       0.0410        2.4           0.677 
180 meas0819                   316       0.00315       0            NA     
181 meas0865                   252       0.205       243.           20.1   
182 meas0875                   311       0.0189        0.35          0.0548
183 meas0877                   316       0.00315       0.37         NA     
184 meas0880                   316       0.00315     220            NA     
185 meas0881                   314       0.00946       2             0     
186 meas0884                   316       0.00315      37            NA     
187 meas0887                   316       0.00315     102.           NA     
188 meas0890                   316       0.00315       0.6          NA     
189 meas0891                   316       0.00315      83            NA     
190 meas0893                   316       0.00315      31            NA     
191 meas0921                   239       0.246         6.61          2.56  
192 meas1255                   309       0.0252        2.75          1.20  
193 meas1260                   151       0.524         0.656         0.157 
194 meas1336                   312       0.0158       86.8           5.81  
195 meas1367                   226       0.287        38.9           6.09  
196 meas1368                   316       0.00315      39            NA     
197 meas1444                   312       0.0158       56             2.92  
198 meas1445                   312       0.0158       66             5.48  
199 meas1549                   315       0.00631     120.           23.3   
200 meas1550                   315       0.00631     174            31.1   
201 meas1551                   315       0.00631      80            11.3   
202 meas1552                   315       0.00631     105            24.0   
203 meas1553                   315       0.00631      91.5          23.3   
204 meas1554                   307       0.0315        1             0     
205 meas1568                   310       0.0221      -16.4           3.95  
206 meas1574                   310       0.0221      -15             4.69  
207 meas1584                   315       0.00631     158            14.1   
208 meas1585                   315       0.00631      77             9.90  
209 meas1586                   315       0.00631      10             1.41  
210 meas1587                   315       0.00631      47             9.90  
211 meas1618                   310       0.0221        2.86          1.68  
212 meas1622                   220       0.306        38.5           6.93  
213 meas1663                   239       0.246        56.4          19.3   
214 meas1664                   239       0.246        55.2          18.2   
215 meas1683                   316       0.00315      19            NA     
216 meas1684                   316       0.00315      24            NA     
217 meas1743                   313       0.0126        1.08          0.275 
218 meas1744                   315       0.00631       0.45          0.0707
219 meas1745                   315       0.00631       1.92          0.460 
220 meas1746                   316       0.00315     141            NA     
221 meas1747                   315       0.00631       0.1           0.0141
222 meas1748                   315       0.00631       9.9           1.41  
223 meas1750                   311       0.0189        1.3           0.110 
224 meas1751                   314       0.00946       0.11          0     
225 meas1752                   314       0.00946      10.9           0     
226 meas1763                   189       0.404         2.09          0.440 
227 meas1783                   189       0.404        40.2          10.7   
228 meas1925                   233       0.265         0.138         0.0286
229 meas1931                   308       0.0284        0.0756        0.0101
230 meas1932                   306       0.0347        0.0927        0.0149
231 meas2023                   310       0.0221      -15.6           5.50  
232 meas2024                   310       0.0221      -19.1           3.89  
233 meas2025                   310       0.0221      -17.3           5.22  
234 meas2026                   310       0.0221      -12.9           5.84  
235 meas2027                   310       0.0221      -16.1           3.39  
236 meas2028                   310       0.0221      -16.6           6.24  
237 meas2029                   310       0.0221      -17.9           5.30  
238 meas2030                   310       0.0221      -18.3           3.59  
239 meas2031                   310       0.0221      -21.3           4.31  
240 meas2032                   310       0.0221      -17.7           4.68  
241 meas2033                   310       0.0221      -18             4.97  
242 meas2034                   310       0.0221      -18.4           2.88  
243 meas2063                   307       0.0315      127.           34.0   
244 meas2064                   307       0.0315       50.2          13.4   
245 meas2065                   307       0.0315       60.4           4.88  
246 meas2123                   310       0.0221      -23             3.16  
247 meas2124                   310       0.0221      -18.4           5.74  
248 meas2203                   239       0.246        57.3          19.1   
249 meas2291                   310       0.0221      -17.4           3.41  
250 meas2292                   310       0.0221      -24.9           4.22  
251 meas2293                   310       0.0221      -22.7           4.15  
252 meas2294                   310       0.0221      -21.3           2.93  
253 meas2295                   310       0.0221      -18.6           3.05  
254 meas2296                   277       0.126        21.7           4.63  
255 meas2314                   316       0.00315       0.12         NA     
256 meas2319                   309       0.0252      130.            7.84  
257 meas2320                   309       0.0252       79.9           5.54  
258 meas2321                   309       0.0252       79.4          12.0   
259 meas2343                   309       0.0252        2.34          0.413 
260 meas2365                   299       0.0568       44.4           7.37  
261 meas2366                   312       0.0158        6.46          2.19  
262 meas2369                   298       0.0599       21.7           5.03  
263 meas2370                   299       0.0568       12.0           3.30  
264 meas2373                   293       0.0757       29.3           4.94  
265 meas2374                   301       0.0505       72.2          10.7   
266 meas2383                   284       0.104        36.6           4.62  
267 meas2423                   314       0.00946     -18.3           4.04  
268 meas2424                   314       0.00946     -26             2.65  
269 meas2425                   314       0.00946     -26.3           7.37  
270 meas2426                   314       0.00946     -23.7           2.52  
271 meas2487                   239       0.246        25.7           7.54  
272 meas2627                   299       0.0568       66.7           9.29  
273 meas2628                   299       0.0568        7.53          1.22  
274 meas2629                   299       0.0568       11.2           0.392 
275 meas2630                   299       0.0568       10.2           0.392 
276 meas2707                   258       0.186        61.2          15.0   
277 meas2787                   312       0.0158       43.4          23.8   
278 meas2788                   312       0.0158       19.2           8.01  
279 meas2847                   258       0.186        36.5           8.99  
280 meas2867                   307       0.0315       76.6          22.6   
281 meas2887                   315       0.00631       2.25          0.354 
282 meas3187                   313       0.0126        1             0     
283 meas3188                   315       0.00631       1             0     
284 meas3189                   315       0.00631       2.75          0.354 
285 meas3207                   313       0.0126        7.5           1.29  
286 meas3627                   313       0.0126        2.62          0.655 
287 meas3927                   307       0.0315       58.3          15.2   
288 meas3928                   307       0.0315       23.4           7.28  
289 meas3947                   307       0.0315       35.2           9.04  
290 meas3987                   312       0.0158      -18.8           1.92  
291 meas4047                   242       0.237        34.8           1.61  
292 meas4067                   260       0.180        37.4           1.27  
293 meas4107                   298       0.0599        9.99          2.00  
294 meas4108                   299       0.0568        5.56          1.41  
295 meas4247                   289       0.0883       25.3           8.70  
296 meas4287                   310       0.0221       32.9           6.62  
297 meas4307                   315       0.00631     -23.6           2.90  
298 meas4327                   315       0.00631     -12.6           6.79  
299 meas4447                   313       0.0126      458.           79.7   
300 meas4767                   315       0.00631     -24.5           0.707 
301 meas5647                   316       0.00315       0            NA     
302 meas5907                   313       0.0126        3.47          1.52  
303 meas5927                   304       0.0410        0.784         0.124 
304 meas6029                   312       0.0158       29             8.80  
305 meas6032                   312       0.0158       30.4           6.69  
306 meas6247                   316       0.00315       1            NA     
307 meas6248                   316       0.00315     146            NA     
308 meas6268                   316       0.00315     410            NA     
309 meas6287                   303       0.0442        1.93          0.258 
310 meas6288                   296       0.0662        1.87          0.224 
311 meas6307                   312       0.0158        1.9           0.332 
312 meas6507                   316       0.00315       0.45         NA     
313 meas6527                   316       0.00315       1.1          NA     
314 meas6547                   316       0.00315       2.22         NA     
315 ef                         189       0.404        59.7           4.34  
            p0         p25         p50          p75        p100 hist 
  1 3518088    6495217     8818117     12121308     14496610    ▃▅▇▂▆
  2 3518088    6495217     8818117     12121308     14496610    ▃▅▇▂▆
  3      20         29          33           36           51    ▂▇▇▃▁
  4 2473613    3607857     3759270      3977682      4166648    ▁▁▃▆▇
  5 2441402    3640245     3796673      4012803      4211051    ▁▁▂▆▇
  6       1.48       1.61        1.65         1.69         1.83 ▂▃▇▃▁
  7      66         93.7       108.         131.         193.   ▃▇▅▂▁
  8      27.0       36.0        40.9         46.8         66.7  ▅▇▅▂▁
  9       1.64       2.00        2.15         2.34         2.83 ▂▇▇▆▁
 10 2441002    3582869     3746325      3974326      4163292    ▁▁▃▇▇
 11       0          0           0            0            1    ▇▁▁▁▁
 12       0          0           0            0            1    ▇▁▁▁▁
 13       0          0           0            0            3    ▇▁▁▁▁
 14    6748       7093.       7438.        7784.        8129    ▇▁▁▁▇
 15       1          1           1            1            1    ▁▁▇▁▁
 16       9          9.25        9.5          9.75        10    ▇▁▁▁▇
 17       9          9.25        9.5          9.75        10    ▇▁▁▁▇
 18      43         45          47           49           51    ▇▁▁▁▇
 19      26         27.8        29.5         31.2         33    ▇▁▁▁▇
 20      58         59.2        60.5         61.8         63    ▇▁▁▁▇
 21     123        139         155          171          187    ▇▁▁▁▇
 22      75         77.2        79.5         81.8         84    ▇▁▁▁▇
 23       6          8           9           10           15    ▁▇▆▂▁
 24       7          9           9           10           14    ▅▇▇▁▁
 25      34         46          49.5         54           64    ▂▃▇▆▁
 26      22         30          33           36           47    ▂▆▇▁▁
 27      41         54          56           60           68    ▁▂▇▃▂
 28      47         58          60           62.2         71    ▁▂▇▅▁
 29      80        137         162          194          311    ▃▇▃▂▁
 30      42         65          73           87          124    ▃▇▆▂▁
 31       1.9        2.1         2.2          2.3          2.8  ▂▇▆▁▁
 32       0.7        1           1.1          1.2          1.6  ▁▃▇▃▁
 33      12         19.6        21.9         23.5         32    ▁▅▇▂▁
 34      38         73          83           95          147    ▁▇▇▂▁
 35       4.03       5.85        6.91         7.88        16.4  ▇▇▂▁▁
 36       1.94       2.78        3.16         3.60         7.04 ▅▇▁▁▁
 37       1.1        1.3         1.5          1.7          2.1  ▇▇▆▂▁
 38      15.6       24          27.6         31.4         41    ▂▇▇▅▂
 39       0.5        0.7         0.8          0.9          1.6  ▇▇▂▁▁
 40       0.3        0.5         0.6          0.7          1.2  ▂▇▅▁▁
 41       0.3        0.36        0.4          0.46         0.69 ▇▅▅▂▂
 42       0.67       1.13        1.36         1.6          3.2  ▆▇▂▁▁
 43     126        152         173          186          263    ▅▇▅▂▁
 44       0.06       0.09        0.1          0.12         0.19 ▂▇▃▁▁
 45       3.3        6.7         7.7          8.9         16.7  ▂▇▃▁▁
 46       0.2        0.4         0.5          0.6          0.7  ▂▅▇▃▂
 47       0.3        0.4         0.5          0.5          0.9  ▇▅▃▁▁
 48       0.1        0.2         0.3          0.3          0.7  ▇▇▁▁▁
 49       0.7        1           1.1          1.3          2.5  ▇▇▁▁▁
 50       1.8        2.13        2.28         2.55         2.84 ▃▇▇▅▃
 51      13         18          20.5         26.2         32    ▃▇▅▅▂
 52       5          5           5            5           20    ▇▁▁▁▁
 53      22         22.8        23           24.2         28    ▇▁▁▁▂
 54      21         24          26           27           27    ▃▁▁▃▇
 55       6          6           6.5          7            9    ▇▅▁▁▂
 56       1.2        1.2         1.25         1.3          1.5  ▇▅▁▁▂
 57      29         29          29           29           29    ▁▁▇▁▁
 58      22         28          31           32           39    ▃▂▇▃▁
 59      25         28          29           32.5         40    ▇▂▆▁▁
 60      30         30.8        31.5         32.2         33    ▇▇▁▇▇
 61      27         27          27           27           27    ▁▁▇▁▁
 62      21         24          28           30           33    ▇▇▇▇▇
 63      26         29          31.5         33.8         43    ▇▇▇▁▂
 64      16         16          16           16           16    ▁▁▇▁▁
 65      16         17.2        18.5         19.8         21    ▇▁▁▁▇
 66       1.53       1.72        1.85         1.92         1.94 ▃▁▁▃▇
 67       1.53       1.62        1.69         1.75         1.78 ▃▁▃▁▇
 68       1.95       2.66        3.04         3.40         4.86 ▂▇▅▂▁
 69       1.93       2.68        2.93         3.46         4.52 ▂▇▅▃▁
 70       1          3.25        4.5          5.25         6    ▇▁▇▇▇
 71       5          8          10.5         12.5         14    ▇▁▇▇▇
 72       0          1           2            3            5    ▆▇▆▂▂
 73       2          4           5            6            9    ▅▃▇▂▁
 74      51         70.2        78           84          116    ▂▆▇▁▁
 75      90        116.        126          137.         184    ▃▇▇▁▁
 76       6.8        6.8         6.8          6.8          6.8  ▁▁▇▁▁
 77     276        321         407          428          481    ▃▃▁▇▃
 78      47        121         180          180          180    ▂▁▁▁▇
 79       3          4           4            5            7    ▃▇▃▃▁
 80       3          3           4            5            7    ▇▇▇▃▁
 81       2          3           3            4            5    ▁▇▁▃▁
 82       3          3.75        4            4.25         5    ▃▁▇▁▃
 83       3          4           5            6            9    ▇▇▃▂▁
 84       3          4           4            6            8    ▇▁▁▂▁
 85       0.15       0.27        0.3          0.33         0.46 ▁▅▇▃▁
 86       1.54       4.92        6.26         7.69        18.2  ▃▇▁▁▁
 87       2          3           3            3.5          5    ▃▇▁▃▁
 88       6          8           9           11           18    ▇▇▅▂▁
 89      11         15          17           20           32    ▇▇▅▂▁
 90       3          3.5         4            4.5          5    ▇▁▁▁▇
 91       0.26       0.4         0.46         0.5          0.73 ▂▇▇▃▁
 92       5          6           7            8           11    ▇▃▃▂▂
 93       0.14       0.238       0.285        0.33         0.52 ▅▇▆▅▁
 94       3          5           5.6          7           10    ▅▇▇▂▁
 95       0.18       0.722       0.85         0.99         1.47 ▁▃▇▃▁
 96       0.04       0.07        0.09         0.11         0.7  ▇▁▁▁▁
 97       2          4           5            6           11    ▁▇▂▁▁
 98       0.3        0.49        0.56         0.62         1.13 ▃▇▃▁▁
 99       0.1        0.1         0.1          0.175        0.4  ▇▂▁▁▁
100       0.1        0.2         0.2          0.3          2    ▇▁▁▁▁
101       0.1        0.2         0.3          0.3          0.6  ▇▅▃▁▁
102       4          8           9           11           23    ▂▇▂▁▁
103       9         13.2        16           18           30    ▅▇▃▂▁
104       8.6       17.1        20.8         25.7         53.9  ▆▇▂▁▁
105       0.25       0.41        0.5          0.55         5    ▇▁▁▁▁
106       4          6           8            9           11    ▂▆▇▆▆
107       0.18       0.29        0.3          0.37         0.59 ▂▇▃▁▁
108       0.04       0.08        0.1          0.13         0.28 ▅▇▃▁▁
109       0.06       0.17        0.21         0.24         0.46 ▂▇▅▁▁
110       0.69       1.13        1.32         1.46         3.29 ▅▇▁▁▁
111       0.19       0.328       0.37         0.42         0.74 ▃▇▃▁▁
112     353        396         410.         427          517    ▂▇▅▁▁
113     116        141         146.         152          170    ▁▃▇▇▁
114      10         10          12           12           14    ▇▁▇▁▅
115      55         73          86           99          181    ▇▇▂▁▁
116     155        158         162          163          163    ▂▂▁▁▇
117      65         67.2        69.5         71.8         74    ▇▁▁▁▇
118      56         72          83           94          227    ▇▃▁▁▁
119     153        155         164          166          181    ▇▃▃▁▃
120      66         72          77.5         83.8         94    ▇▃▃▃▃
121      69         69.5        70           75.5         81    ▇▁▁▁▃
122      68         69.5        71           71.5         72    ▇▁▁▇▇
123    8184      13083       17147        21942        30770    ▇▆▆▅▃
124     182        186         191          192          192    ▂▂▁▁▇
125      50         56          77           91          104    ▇▁▃▃▃
126       0.56       0.73        0.79         0.85         1    ▁▅▇▃▃
127      48         57.5        60           63           73    ▂▃▇▂▁
128      44         57          61           63           73    ▁▃▇▆▂
129      46         57.5        60           62           69    ▁▂▇▇▃
130      62         63.2        64.5         65.8         67    ▇▁▁▁▇
131     136        172.        181          188.         211    ▁▂▇▇▃
132      33         33.8        36           37.2         40    ▇▂▅▂▂
133      40         40          40           40           40    ▁▁▇▁▁
134      75        100         100          100          100    ▂▁▁▁▇
135       0.16       0.25        0.32         0.4          0.63 ▇▇▇▅▁
136       0.6        0.725       0.81         0.87         1.17 ▅▇▇▂▁
137       1          2           3            4            6    ▇▇▆▁▁
138      33         68.5        80           89.5        133    ▂▆▇▃▂
139      50        106         128          153          251    ▃▇▇▁▁
140      19         41          52           63          131    ▅▇▃▁▁
141      47        116.        136          150          257    ▂▇▇▂▁
142      18         44          53           61          135    ▂▇▂▁▁
143      52        115         136          146.         247    ▂▇▇▂▁
144      19         44          55           62          133    ▂▇▂▁▁
145       1          1           1            1            1.44 ▇▁▁▁▁
146     108        117         117          121          127    ▃▁▇▃▃
147       4.7        4.7         4.7          4.7          4.7  ▁▁▇▁▁
148     198        227         237          251          271    ▁▆▇▇▅
149       0.1        0.123       0.145        0.168        0.19 ▇▁▁▁▇
150       0.07       0.07        0.09         0.112        0.13 ▇▅▁▂▅
151       0.07       0.11        0.13         0.15         0.22 ▅▆▇▂▁
152       0.05       0.08        0.085        0.09         0.14 ▂▇▇▁▂
153       2          2.25        3.5          4            4    ▅▁▂▁▇
154      33         34.5        36           37.5         39    ▇▁▁▁▇
155      63         74          85           96          107    ▇▁▁▁▇
156       5.49       5.68        5.86         6.04         6.23 ▇▁▁▁▇
157       0.55       0.578       0.605        0.633        0.66 ▇▁▁▁▇
158     179.       190.        201.         212.         223.   ▇▁▁▁▇
159      22         25.2        28.5         31.8         35    ▇▁▁▁▇
160      17         17          17           17           17    ▁▁▇▁▁
161       1          1           1            1            1    ▁▁▇▁▁
162      97         97          97           97           97    ▁▁▇▁▁
163      45         45          45           45           45    ▁▁▇▁▁
164      24         24          24           24           24    ▁▁▇▁▁
165       8          8           9           10           13    ▇▂▁▁▁
166     100        100         100          100          100    ▁▁▇▁▁
167      27         27          27           27           27    ▁▁▇▁▁
168     122        122         122          122          122    ▁▁▇▁▁
169       2          4           5            7           25    ▇▂▁▁▁
170       8         10.2        12           13.5         15    ▇▁▇▇▇
171       3          3           4            5            8    ▇▂▁▁▁
172       0.8        0.8         1            1.1          1.4  ▇▅▃▂▂
173      44.8       44.8        44.8         44.8         44.8  ▁▁▇▁▁
174   20808      22320       25896        27880        30770    ▇▁▅▃▅
175     142        168.        178          184.         219    ▂▃▇▂▁
176       0.12       0.298       0.35         0.44         0.68 ▂▇▇▂▁
177      14         15.7        17.4         19.0         20.7  ▇▁▁▁▇
178      18         23          26           32           52    ▇▇▅▁▁
179       1.7        1.7         2.5          2.5          3.4  ▇▁▇▁▅
180       0          0           0            0            0    ▁▁▇▁▁
181     197        232         243          257          292    ▂▂▇▅▁
182       0.3        0.3         0.35         0.4          0.4  ▇▁▁▁▇
183       0.37       0.37        0.37         0.37         0.37 ▁▁▇▁▁
184     220        220         220          220          220    ▁▁▇▁▁
185       2          2           2            2            2    ▁▁▇▁▁
186      37         37          37           37           37    ▁▁▇▁▁
187     102.       102.        102.         102.         102.   ▁▁▇▁▁
188       0.6        0.6         0.6          0.6          0.6  ▁▁▇▁▁
189      83         83          83           83           83    ▁▁▇▁▁
190      31         31          31           31           31    ▁▁▇▁▁
191       2.7        5           5.85         7.88        16    ▇▇▂▁▁
192       1.5        2.03        2.5          2.88         5.33 ▇▇▂▁▂
193       0.33       0.53        0.66         0.768        1.05 ▃▇▇▅▂
194      81         82          86           90           95    ▇▃▁▃▃
195      29         35          38           42.5         59    ▆▇▅▁▁
196      39         39          39           39           39    ▁▁▇▁▁
197      53         54          55           58           60    ▇▃▁▃▃
198      60         60          70           70           70    ▅▁▁▁▇
199     103        111.        120.         128.         136    ▇▁▁▁▇
200     152        163         174          185          196    ▇▁▁▁▇
201      72         76          80           84           88    ▇▁▁▁▇
202      88         96.5       105          114.         122    ▇▁▁▁▇
203      75         83.2        91.5         99.8        108    ▇▁▁▁▇
204       1          1           1            1            1    ▁▁▇▁▁
205     -21        -19.5       -16          -14.5        -10    ▇▁▅▂▂
206     -24        -16         -14          -13           -9    ▂▁▅▇▂
207     148        153         158          163          168    ▇▁▁▁▇
208      70         73.5        77           80.5         84    ▇▁▁▁▇
209       9          9.5        10           10.5         11    ▇▁▁▁▇
210      40         43.5        47           50.5         54    ▇▁▁▁▇
211       1          2           2            3.5          6    ▇▂▂▁▂
212      21         34          37           42           60    ▁▆▇▂▁
213      22         44          53           66          141    ▅▇▃▁▁
214      23         44.2        53           63.5        128    ▃▇▂▁▁
215      19         19          19           19           19    ▁▁▇▁▁
216      24         24          24           24           24    ▁▁▇▁▁
217       0.8        0.875       1.05         1.25         1.4  ▇▁▁▃▃
218       0.4        0.425       0.45         0.475        0.5  ▇▁▁▁▇
219       1.6        1.76        1.92         2.09         2.25 ▇▁▁▁▇
220     141        141         141          141          141    ▁▁▇▁▁
221       0.09       0.095       0.1          0.105        0.11 ▇▁▁▁▇
222       8.9        9.4         9.9         10.4         10.9  ▇▁▁▁▇
223       1.2        1.2         1.3          1.4          1.4  ▇▁▁▁▇
224       0.11       0.11        0.11         0.11         0.11 ▁▁▇▁▁
225      10.9       10.9        10.9         10.9         10.9  ▁▁▇▁▁
226       0          1.96        2.12         2.28         2.83 ▁▁▁▇▃
227       0         34.4        40.2         45.2         64.7  ▁▁▆▇▂
228       0.07       0.12        0.14         0.15         0.22 ▂▇▇▂▁
229       0.06       0.07        0.07         0.08         0.09 ▂▇▁▃▃
230       0.07       0.085       0.1          0.1          0.12 ▅▃▇▁▂
231     -23        -19         -17          -11           -9    ▇▁▇▃▇
232     -22        -21.5       -21          -18.5        -11    ▇▃▁▁▂
233     -27        -19.5       -16          -13.5        -12    ▂▁▅▂▇
234     -21        -16.5       -13           -9           -5    ▇▁▇▃▇
235     -20        -19         -16          -14          -11    ▇▁▅▂▂
236     -28        -18.5       -17          -12.5         -9    ▂▁▇▂▅
237     -24        -21         -19          -15.5         -9    ▅▇▁▂▂
238     -23        -21.5       -17          -15          -15    ▅▂▁▂▇
239     -28        -23         -21          -20          -14    ▂▂▇▂▂
240     -25        -20.5       -17          -14.5        -12    ▃▃▃▇▇
241     -24        -21         -18          -16.5         -9    ▇▇▇▁▃
242     -23        -20         -18          -17          -14    ▃▇▃▇▃
243      76        105.        122.         144.         190    ▂▇▇▅▂
244      26         41.2        50.5         61.5         69    ▂▇▂▅▇
245      49         59.2        62           63           66    ▂▁▃▆▇
246     -27        -25         -24          -21          -18    ▂▇▂▂▂
247     -28        -21.5       -18          -14          -12    ▂▂▂▂▇
248      27         45.2        54.5         63          150    ▆▇▂▁▁
249     -24        -18.5       -16          -15          -15    ▂▁▂▂▇
250     -32        -26         -25          -23.5        -18    ▂▂▇▂▂
251     -28        -25.5       -23          -20.5        -16    ▇▃▇▃▃
252     -25        -23         -21          -20.5        -16    ▅▂▇▁▂
253     -23        -19.5       -19          -18          -13    ▂▇▂▁▂
254       9         18.8        22.5         25.2         29    ▂▁▇▆▆
255       0.12       0.12        0.12         0.12         0.12 ▁▁▇▁▁
256     121        126.        126          132.         144    ▃▇▁▂▂
257      72         77.2        78           85           88    ▅▇▁▁▇
258      70         71.5        74           83          103    ▇▂▁▂▂
259       1.72       2.02        2.34         2.71         2.83 ▂▅▂▂▇
260      27         40.5        45.5         48           56    ▁▂▇▇▅
261       4.17       4.24        7.18         7.53         9.17 ▇▁▁▇▃
262      11.6       18.7        21.4         24.3         34.2  ▂▆▇▂▁
263       5.06      10.2        12.1         13.9         19.1  ▁▇▇▇▁
264      18         26.8        30           33           36    ▃▂▅▆▇
265      54         62.5        76           80           85    ▅▃▃▆▇
266      27         34          37           40           47    ▃▅▇▆▂
267     -22        -20.5       -19          -16.5        -14    ▇▇▁▁▇
268     -28        -27.5       -27          -25          -23    ▇▁▁▁▃
269     -32        -30.5       -29          -23.5        -18    ▇▇▁▁▇
270     -26        -25         -24          -22.5        -21    ▇▇▁▁▇
271      13         22          25           28.8         60    ▅▇▂▁▁
272      51         60          68           71           78    ▃▃▁▇▃
273       5.6        6.4         7.8          8.1          9    ▃▃▁▇▃
274      10.5       10.9        11.4         11.5         11.5  ▂▂▁▁▇
275       9.5        9.9        10.4         10.5         10.5  ▂▂▁▁▇
276      27         56          60           71.5         98    ▂▁▇▃▁
277      21         35          37           40           84    ▂▇▁▁▂
278      13         15          16           19           33    ▇▂▁▁▂
279      16         32.5        36           43           56    ▂▃▇▃▂
280      50         60.8        70           87.8        121    ▇▆▂▂▂
281       2          2.12        2.25         2.38         2.5  ▇▁▁▁▇
282       1          1           1            1            1    ▁▁▇▁▁
283       1          1           1            1            1    ▁▁▇▁▁
284       2.5        2.62        2.75         2.88         3    ▇▁▁▁▇
285       6          6.75        7.5          8.25         9    ▇▇▁▇▇
286       2.2        2.28        2.35         2.7          3.6  ▇▁▁▁▂
287      36         48          57.5         72.8         77    ▃▃▂▂▇
288      12         18.5        23.5         27.8         35    ▅▇▁▇▅
289      23         30.5        34           43           48    ▅▅▇▁▇
290     -22        -19         -18          -18          -17    ▃▁▃▇▃
291      32         33.5        35           36           39    ▅▃▇▂▁
292      35         36          37           38           40    ▇▆▇▃▁
293       5.03       9.05        9.93        10.7         15.1  ▁▃▇▂▁
294       2.2        4.91        5.16         6.78         8.4  ▁▃▇▃▂
295      10         20.5        24.5         30.2         53    ▅▇▇▁▁
296      22         29.6        34           36           42.9  ▃▇▃▇▃
297     -25.6      -24.6       -23.6        -22.5        -21.5  ▇▁▁▁▇
298     -17.4      -15         -12.6        -10.2         -7.8  ▇▁▁▁▇
299     365        406.        470.         522.         529    ▃▃▁▁▇
300     -25        -24.8       -24.5        -24.2        -24    ▇▁▁▁▇
301       0          0           0            0            0    ▁▁▇▁▁
302       1.9        2.43        3.35         4.4          5.3  ▇▇▁▇▇
303       0.57       0.74        0.76         0.86         1    ▃▃▇▃▆
304      21         22          25           38           39    ▇▃▁▁▇
305      22         26          30           36           38    ▃▃▃▁▇
306       1          1           1            1            1    ▁▁▇▁▁
307     146        146         146          146          146    ▁▁▇▁▁
308     410        410         410          410          410    ▁▁▇▁▁
309       1.6        1.72        1.95         2            2.6  ▇▇▂▁▁
310       1.3        1.8         1.9          2            2.3  ▂▂▇▂▃
311       1.6        1.6         1.9          2            2.4  ▇▃▃▁▃
312       0.45       0.45        0.45         0.45         0.45 ▁▁▇▁▁
313       1.1        1.1         1.1          1.1          1.1  ▁▁▇▁▁
314       2.22       2.22        2.22         2.22         2.22 ▁▁▇▁▁
315      46         57          60           62           69    ▁▂▆▇▂

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable  n_missing complete_rate min                 max                
1 birth_date             0             1 1973-03-26 00:00:00 2004-07-20 00:00:00
2 procedure_date         0             1 2018-03-21 00:00:00 2026-02-27 00:00:00
3 procedure_time         0             1 1899-12-31 06:24:34 1899-12-31 19:06:18
  median              n_unique
1 1991-05-17 00:00:00      196
2 2024-04-15 00:00:00      239
3 1899-12-31 11:58:05      276




---

# Dataset: `echo_dict`

## Dimensions
- Rows: 26
- Columns: 2

## Column Types
character x 1,  numeric x 1

## Columns
`Variable Name, Variable Number`

## ID-like Columns
  (none detected)


## Date Columns and Ranges
  (none)


## Missing Values (columns with any NA)
  (none)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             26    
Number of columns          2     
_______________________          
Column type frequency:           
  character                1     
  numeric                  1     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
  skim_variable n_missing complete_rate min max empty n_unique whitespace
1 Variable Name         0             1   3  20     0       26          0

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable   n_missing complete_rate mean   sd p0  p25  p50  p75 p100 hist 
1 Variable Number         0             1 13.5 7.65  1 7.25 13.5 19.8   26 ▇▇▇▇▇




---

# Dataset: `glp1_meds`

## Dimensions
- Rows: 3834
- Columns: 40

## Column Types
character x 24,  logical x 5,  numeric x 3,  POSIXct x 8

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Order_Date, Order_Time, Order_Type, Order_Type_Desc, Order_Code, Order_Name, Order_ID, Ordering_Provider_Person_ID, Approving_Provider_Person_ID, Order_Desc, Source, Site, Site_Name, Inpatient_Flag, Location_Desc, Location_Code, Location_Level, Location_Nurse_Unit_Code, Location_Nurse_Unit_Name, Location_Room_Name, Site_State, Order_Start_Date, Order_Start_Time, Order_Stop_Date, Order_Stop_Time, Order_Dose_Amount, Order_Dose_Units, Order_Dose_Form_Route_Desc, Order_Strength, Order_Strength_Units, Med_Generic, Controlled_Med_Flag, Controlled_Med_Class, Order_Status, Order_Sub_Status, Encounter_Nbr`

## ID-like Columns
  Order_ID: 3640 unique values
  Ordering_Provider_Person_ID: 595 unique values
  Approving_Provider_Person_ID: 486 unique values
  Inpatient_Flag: 2 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Order_Date: 2018-12-13 to 2026-03-03
  Order_Time: 1899-12-31 to 1899-12-31 23:30:00
  Order_Start_Date: 2018-12-13 to 2026-07-17
  Order_Start_Time: 1899-12-31 to 1899-12-31
  Order_Stop_Date: 2019-02-26 to 9999-12-31
  Order_Stop_Time: 1899-12-31 to 1899-12-31 23:59:59


## Missing Values (columns with any NA)
  Location_Nurse_Unit_Code: 3834 (100%)
  Location_Nurse_Unit_Name: 3834 (100%)
  Location_Room_Name: 3834 (100%)
  Controlled_Med_Flag: 3834 (100%)
  Controlled_Med_Class: 3834 (100%)
  Order_Dose_Amount: 242 (6.3%)
  Order_Dose_Units: 242 (6.3%)
  Order_Sub_Status: 158 (4.1%)
  Order_Status: 115 (3%)
  Order_Start_Date: 35 (0.9%)
  Order_Start_Time: 35 (0.9%)
  Order_Strength: 7 (0.2%)
  Order_Strength_Units: 7 (0.2%)
  Order_Dose_Form_Route_Desc: 6 (0.2%)
  Site_State: 5 (0.1%)
  Ordering_Provider_Person_ID: 2 (0.1%)
  Order_Name: 1 (0%)
  Med_Generic: 1 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             3834  
Number of columns          40    
_______________________          
Column type frequency:           
  character                24    
  logical                  5     
  numeric                  3     
  POSIXct                  8     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable                n_missing complete_rate min max empty n_unique
 1 Order_Type                           0         1       3   3     0        1
 2 Order_Type_Desc                      0         1      11  11     0        1
 3 Order_Code                           0         1       6   6     0       76
 4 Order_Name                           1         1.000  23  70     0       45
 5 Order_ID                             0         1      13  13     0     3640
 6 Ordering_Provider_Person_ID          2         0.999   1   8     0      595
 7 Approving_Provider_Person_ID         0         1       1   8     0      486
 8 Order_Desc                           0         1      14  78     0       76
 9 Source                               0         1       4   4     0        1
10 Site                                 0         1       3   5     0        5
11 Site_Name                            0         1       4  21     0        5
12 Inpatient_Flag                       0         1       1   1     0        2
13 Location_Desc                        0         1      29  68     0      139
14 Location_Code                        0         1       7  12     0      139
15 Location_Level                       0         1      10  10     0        1
16 Site_State                           5         0.999   2   2     0        4
17 Order_Dose_Units                   242         0.937   2   7     0        4
18 Order_Dose_Form_Route_Desc           6         0.998   6  13     0        5
19 Order_Strength                       7         0.998   1  15     0       25
20 Order_Strength_Units                 7         0.998   2  15     0       12
21 Med_Generic                          1         1.000  23  35     0       39
22 Order_Status                       115         0.970   8  23     0        3
23 Order_Sub_Status                   158         0.959   4  12     0        5
24 Encounter_Nbr                        0         1      13  13     0     2143
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0
15          0
16          0
17          0
18          0
19          0
20          0
21          0
22          0
23          0
24          0

── Variable type: logical ──────────────────────────────────────────────────────
  skim_variable            n_missing complete_rate mean count
1 Location_Nurse_Unit_Code      3834             0  NaN ": " 
2 Location_Nurse_Unit_Name      3834             0  NaN ": " 
3 Location_Room_Name            3834             0  NaN ": " 
4 Controlled_Med_Flag           3834             0  NaN ": " 
5 Controlled_Med_Class          3834             0  NaN ": " 

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable     n_missing complete_rate       mean         sd         p0
1 CURR_CLINIC               0         1     8634182.   2975895.   3502573   
2 current_age               0         1          32.4        5.34      19   
3 Order_Dose_Amount       242         0.937       3.61       3.89       0.25
        p25       p50      p75     p100 hist 
1 6223246.  8581763   10283932 14840800 ▅▃▇▂▃
2      29        33         36       54 ▂▇▆▁▁
3       0.5       2.4        5       25 ▇▂▁▁▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable    n_missing complete_rate min                
1 delv_date                0         1     2018-06-24 00:00:00
2 Birth_Dt                 0         1     1970-09-13 00:00:00
3 Order_Date               0         1     2018-12-13 00:00:00
4 Order_Time               0         1     1899-12-31 00:00:00
5 Order_Start_Date        35         0.991 2018-12-13 00:00:00
6 Order_Start_Time        35         0.991 1899-12-31 00:00:00
7 Order_Stop_Date          0         1     2019-02-26 00:00:00
8 Order_Stop_Time          0         1     1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-06-04 00:00:00      565
2 2006-01-28 00:00:00 1992-02-22 00:00:00      676
3 2026-03-03 00:00:00 2025-02-08 12:00:00      853
4 1899-12-31 23:30:00 1899-12-31 11:48:00      692
5 2026-07-17 00:00:00 2025-02-20 00:00:00      941
6 1899-12-31 00:00:00 1899-12-31 00:00:00        1
7 9999-12-31 00:00:00 2025-06-23 00:00:00      842
8 1899-12-31 23:59:59 1899-12-31 00:00:00       34




---

# Dataset: `ord_meds`

## Dimensions
- Rows: 132819
- Columns: 40

## Column Types
character x 29,  numeric x 3,  POSIXct x 8

## Columns
`CURR_CLINIC, delv_date, Birth_Dt, current_age, Order_Date, Order_Time, Order_Type, Order_Type_Desc, Order_Code, Order_Name, Order_ID, Ordering_Provider_Person_ID, Approving_Provider_Person_ID, Order_Desc, Source, Site, Site_Name, Inpatient_Flag, Location_Desc, Location_Code, Location_Level, Location_Nurse_Unit_Code, Location_Nurse_Unit_Name, Location_Room_Name, Site_State, Order_Start_Date, Order_Start_Time, Order_Stop_Date, Order_Stop_Time, Order_Dose_Amount, Order_Dose_Units, Order_Dose_Form_Route_Desc, Order_Strength, Order_Strength_Units, Med_Generic, Controlled_Med_Flag, Controlled_Med_Class, Order_Status, Order_Sub_Status, Encounter_Nbr`

## ID-like Columns
  Order_ID: 132815 unique values
  Ordering_Provider_Person_ID: 4939 unique values
  Approving_Provider_Person_ID: 3355 unique values
  Inpatient_Flag: 2 unique values


## Date Columns and Ranges
  delv_date: 2018-06-24 to 2025-12-23
  Birth_Dt: 1970-09-13 to 2006-01-28
  Order_Date: 2017-07-11 to 2026-03-08
  Order_Time: 1899-12-31 to 1899-12-31 23:59:00
  Order_Start_Date: 2004-08-23 to 2026-07-17
  Order_Start_Time: 1899-12-31 to 1899-12-31 17:07:21
  Order_Stop_Date: 2017-07-19 to 9999-12-31
  Order_Stop_Time: 1899-12-31 to 1899-12-31 23:59:59


## Missing Values (columns with any NA)
  Location_Nurse_Unit_Code: 132806 (100%)
  Location_Room_Name: 132806 (100%)
  Location_Nurse_Unit_Name: 132791 (100%)
  Controlled_Med_Class: 119034 (89.6%)
  Controlled_Med_Flag: 119029 (89.6%)
  Order_Strength_Units: 34529 (26%)
  Order_Dose_Units: 25332 (19.1%)
  Order_Dose_Amount: 25330 (19.1%)
  Order_Strength: 11701 (8.8%)
  Order_Dose_Form_Route_Desc: 4266 (3.2%)
  Order_Name: 3995 (3%)
  Med_Generic: 3995 (3%)
  Order_Start_Date: 2989 (2.3%)
  Order_Start_Time: 2989 (2.3%)
  Order_Sub_Status: 2629 (2%)
  Order_Status: 1489 (1.1%)
  Site_State: 516 (0.4%)
  Location_Code: 511 (0.4%)
  Ordering_Provider_Person_ID: 43 (0%)
  Approving_Provider_Person_ID: 28 (0%)
  Order_Stop_Date: 2 (0%)


## Skim Summary
── Data Summary ────────────────────────
                           Values
Name                       df    
Number of rows             132819
Number of columns          40    
_______________________          
Column type frequency:           
  character                29    
  numeric                  3     
  POSIXct                  8     
________________________         
Group variables            None  

── Variable type: character ────────────────────────────────────────────────────
   skim_variable                n_missing complete_rate min max empty n_unique
 1 Order_Type                           0     1           2   3     0        3
 2 Order_Type_Desc                      0     1          11  42     0        4
 3 Order_Code                           0     1           2  11     0     2880
 4 Order_Name                        3995     0.970       4  70     0     2203
 5 Order_ID                             0     1           6  13     0   132815
 6 Ordering_Provider_Person_ID         43     1.000       1  10     0     4939
 7 Approving_Provider_Person_ID        28     1.000       1   8     0     3355
 8 Order_Desc                           0     1           1  99     0     2879
 9 Source                               0     1           4  13     0        3
10 Site                                 0     1           3   5     0        5
11 Site_Name                            0     1           4  21     0        5
12 Inpatient_Flag                       0     1           1   1     0        2
13 Location_Desc                        0     1           7  68     0      712
14 Location_Code                      511     0.996       5  12     0      706
15 Location_Level                       0     1           4  10     0        3
16 Location_Nurse_Unit_Code        132806     0.0000979   7   7     0        1
17 Location_Nurse_Unit_Name        132791     0.000211    7  18     0        6
18 Location_Room_Name              132806     0.0000979   7   7     0        1
19 Site_State                         516     0.996       2   7     0        5
20 Order_Dose_Units                 25332     0.809       1  10     0       82
21 Order_Dose_Form_Route_Desc        4266     0.968       3  49     0      161
22 Order_Strength                   11701     0.912       1  15     0      518
23 Order_Strength_Units             34529     0.740       1  15     0      302
24 Med_Generic                       3995     0.970       4  35     0     2102
25 Controlled_Med_Flag             119029     0.104       1   1     0        2
26 Controlled_Med_Class            119034     0.104       1   1     0        6
27 Order_Status                      1489     0.989       6  23     0        8
28 Order_Sub_Status                  2629     0.980       4  12     0        9
29 Encounter_Nbr                        0     1           9  13     0    25892
   whitespace
 1          0
 2          0
 3          0
 4          0
 5          0
 6          0
 7          0
 8          0
 9          0
10          0
11          0
12          0
13          0
14          0
15          0
16          0
17          0
18          0
19          0
20          0
21          0
22          0
23          0
24          0
25          0
26          0
27          0
28          0
29          0

── Variable type: numeric ──────────────────────────────────────────────────────
  skim_variable     n_missing complete_rate      mean         sd      p0     p25
1 CURR_CLINIC               0         1     8509142.  2941414.   3502573 6264981
2 current_age               0         1          32.9       5.63      19      29
3 Order_Dose_Amount     25330         0.809     225.     5186.         0       3
      p50     p75     p100 hist 
1 8500729 9944346 14840800 ▅▅▇▂▃
2      33      37       54 ▂▇▇▂▁
3      10      65   500000 ▇▁▁▁▁

── Variable type: POSIXct ──────────────────────────────────────────────────────
  skim_variable    n_missing complete_rate min                
1 delv_date                0         1     2018-06-24 00:00:00
2 Birth_Dt                 0         1     1970-09-13 00:00:00
3 Order_Date               0         1     2017-07-11 00:00:00
4 Order_Time               0         1     1899-12-31 00:00:00
5 Order_Start_Date      2989         0.977 2004-08-23 00:00:00
6 Order_Start_Time      2989         0.977 1899-12-31 00:00:00
7 Order_Stop_Date          2         1.000 2017-07-19 00:00:00
8 Order_Stop_Time          0         1     1899-12-31 00:00:00
  max                 median              n_unique
1 2025-12-23 00:00:00 2024-04-05 00:00:00      550
2 2006-01-28 00:00:00 1991-09-19 00:00:00      676
3 2026-03-08 00:00:00 2024-06-05 00:00:00     2424
4 1899-12-31 23:59:00 1899-12-31 10:59:00     1468
5 2026-07-17 00:00:00 2024-06-06 00:00:00     2567
6 1899-12-31 17:07:21 1899-12-31 00:00:00       18
7 9999-12-31 00:00:00 2024-11-05 00:00:00     2594
8 1899-12-31 23:59:59 1899-12-31 14:45:00     1443


