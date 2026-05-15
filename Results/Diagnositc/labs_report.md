# Labs Dataset Report

## Dataset Dimensions
- Rows: 224910
- Columns: 31

## Column Names
-  CURR_CLINIC
-  delv_date
-  Birth_Dt
-  current_age
-  Lab_Date
-  Lab_Time
-  Lab_Result_Date
-  Lab_Result_Time
-  Test_Code
-  TestDesc
-  Lab_Panel_Code
-  Lab_Panel_Desc
-  Lab_Panel_Type
-  Sample_Type_Desc
-  Resultn
-  Resultc
-  Accession
-  Units
-  Ranges
-  Rang_Ind
-  Range_Ind_Description
-  Status
-  Lab_type
-  Lab_Subtype
-  Source
-  Site
-  Site_Name
-  Site_State
-  Facility
-  Encounter_Nbr
-  Comments

## Preview of Data

| CURR_CLINIC|delv_date  |Birth_Dt   | current_age|Lab_Date   |Lab_Time            |Lab_Result_Date |Lab_Result_Time     |Test_Code |TestDesc                     |Lab_Panel_Code |Lab_Panel_Desc                |Lab_Panel_Type        |Sample_Type_Desc | Resultn|Resultc     |Accession    |Units |Ranges      |Rang_Ind |Range_Ind_Description |Status       |Lab_type                      |Lab_Subtype                  |Source |Site |Site_Name            |Site_State |Facility                                      |Encounter_Nbr |Comments                                                                                                                                                                                                                                                                                                                                     |
|-----------:|:----------|:----------|-----------:|:----------|:-------------------|:---------------|:-------------------|:---------|:----------------------------|:--------------|:-----------------------------|:---------------------|:----------------|-------:|:-----------|:------------|:-----|:-----------|:--------|:---------------------|:------------|:-----------------------------|:----------------------------|:------|:----|:--------------------|:----------|:---------------------------------------------|:-------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|     3502573|2020-10-30 |1980-09-30 |          44|2020-09-23 |1899-12-31 12:20:00 |2020-09-24      |1899-12-31 09:12:00 |10496     |VARICELLA IGG ANTIBODY INDEX |LAB162         |VARICELLA-ZOSTER AB, IGG, S   |MICROBIOLOGY          |BLOOD            |     1.4|1.4         |F623029667:2 |NA    |NA          |UNK      |Unknown               |FINAL RESULT |VARICELLA-ZOSTER AB, IGG, S   |Varicella IgG Antibody Index |Epic   |RST  |Rochester, Minnesota |MN         |RST MCH Methodist Campus - RST LAB ROCH LO    |2000354157885 |NA                                                                                                                                                                                                                                                                                                                                           |
|     3502573|2020-10-30 |1980-09-30 |          44|2020-09-23 |1899-12-31 12:20:00 |2020-09-24      |1899-12-31 09:12:00 |1552053   |VARICELLA ZOSTER IGG         |LAB162         |VARICELLA-ZOSTER AB, IGG, S   |MICROBIOLOGY          |BLOOD            |      NA|Positive    |F623029667:2 |NA    |NA          |UNK      |Unknown               |FINAL RESULT |VARICELLA-ZOSTER AB, IGG, S   |Varicella-Zoster Ab, IgG, S  |Epic   |RST  |Rochester, Minnesota |MN         |RST MCH Methodist Campus - RST LAB ROCH LO    |2000354157885 |Results suggest response to immunization or
prior exposure to the virus.
 ----REFERENCE VALUE----
Vaccinated: Positive (>=1.1 AI)
Unvaccinated: Negative (<=0.8 AI)                                                                                                                                                                              |
|     3502573|2020-10-30 |1980-09-30 |          44|2020-09-23 |1899-12-31 12:20:00 |2020-09-23      |1899-12-31 13:37:00 |1810064   |ANTIBODY SCRN, RBC           |LAB278         |ANTIBODY SCREEN, B            |LAB                   |BLOOD            |      NA|Negative    |F623029666:1 |NA    |Negative    |UNK      |Unknown               |FINAL RESULT |ANTIBODY SCREEN, B            |Antibody Screen              |Epic   |RST  |Rochester, Minnesota |MN         |RST MCH Methodist Campus - RST LAB ROCH LO    |2000354157885 |NA                                                                                                                                                                                                                                                                                                                                           |
|     3502573|2020-10-30 |1980-09-30 |          44|2020-09-23 |1899-12-31 12:20:00 |2020-09-24      |1899-12-31 09:12:00 |26976     |SYPHILIS TOTAL AB W/ REFLEX  |LAB104539      |SYPHILIS TOTAL AB W/ REFLEX S |LAB                   |BLOOD            |      NA|Nonreactive |F623029665:1 |NA    |Nonreactive |UNK      |Unknown               |FINAL RESULT |SYPHILIS TOTAL AB W/ REFLEX S |Syphilis Total Ab w/ Reflex  |Epic   |RST  |Rochester, Minnesota |MN         |RST MCH Methodist Campus - RST LAB ROCH LO    |2000365651549 |No serologic evidence of infection with T. pallidum
(syphilis).  Repeat testing may be considered in patients
with suspected acute or primary syphilis in 2-4 weeks.
For additional information on interpretation of 
the syphilis reverse algorithm and results, see: 
https://www.mayocliniclabs.com/
it-mmfiles/Syphilis_Serology_Algorithm.pdf |
|     3502573|2020-10-30 |1980-09-30 |          44|2020-10-30 |1899-12-31 08:07:00 |2020-10-30      |1899-12-31 08:12:00 |25192     |SAMPLE SITE, POCT            |POC531         |GLUCOSE POCT, B               |POINT OF CARE TESTING |BLOOD            |      NA|Capillary   |F730009782:1 |NA    |NA          |UNK      |Unknown               |FINAL RESULT |GLUCOSE POCT, B               |Site                         |Epic   |RST  |Rochester, Minnesota |MN         |RST MCH Methodist Campus - RST ROEI 03 2 PPOB |2000372037775 |NA                                                                                                                                                                                                                                                                                                                                           |
|     3502573|2020-10-30 |1980-09-30 |          44|2020-10-30 |1899-12-31 08:07:00 |2020-10-30      |1899-12-31 08:12:00 |25194     |GLUCOSE, POCT, B             |POC531         |GLUCOSE POCT, B               |POINT OF CARE TESTING |BLOOD            |   110.0|110         |F730009782:1 |mg/dL |70 - 140    |UNK      |Unknown               |FINAL RESULT |GLUCOSE POCT, B               |Glucose, POCT, B             |Epic   |RST  |Rochester, Minnesota |MN         |RST MCH Methodist Campus - RST ROEI 03 2 PPOB |2000372037775 |NA                                                                                                                                                                                                                                                                                                                                           |
