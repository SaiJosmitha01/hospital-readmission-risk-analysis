# Phase 4 — SQL Analysis Summary

## Scope and validated data

Phase 4 uses SQLite to analyze encounter-level 30-day readmission patterns from `data/processed/diabetic_data_cleaned.csv`. The local database is `database/hospital_readmission.db`, and its base table is `encounters`.

The validated database contains:

- 101,763 encounters
- 48 source columns
- 101,763 unique encounter IDs
- 71,515 unique patients

A 30-day readmission is defined as `readmitted = '<30'`. By this definition, 11,357 encounters were readmitted within 30 days, an overall encounter-level rate of 11.16%.

All findings below are descriptive associations. They do not establish that the characteristics analyzed cause readmission.

## Key findings

### Age

The highest observed age-group rate was among ages 20–30: 236 readmissions across 1,657 encounters, or 14.24%. This group was considerably smaller than the major older age groups, so its rate should be interpreted with appropriate attention to volume.

Among larger older groups, ages 70–80 had 3,069 readmissions across 26,066 encounters (11.77%), while ages 80–90 had 2,078 readmissions across 17,197 encounters (12.08%). These differences do not demonstrate that age causes readmission.

### Primary diagnosis category

Among substantive project-level diagnosis categories, Diabetes had the highest readmission rate: 1,137 readmissions across 8,757 encounters (12.98%). Injury followed with 854 readmissions across 6,972 encounters (12.25%). Circulatory diagnoses had a rate of 11.45% and the largest absolute number of readmissions—3,485 across 30,436 encounters.

The Unknown category was excluded from headline risk interpretation because it contained only 21 encounters. Diagnosis categories are analytical groupings based on primary diagnosis (`diag_1`); individual ICD-9 subcodes should not be given clinical interpretations beyond what the data supports.

### Prior healthcare utilization

Prior inpatient utilization showed one of the strongest and clearest descriptive relationships with 30-day readmission in Phase 4:

| Prior inpatient visits | Encounters | 30-day readmissions | Rate |
| --- | ---: | ---: | ---: |
| 0 visits | 67,627 | 5,706 | 8.44% |
| 1 visit | 19,521 | 2,523 | 12.92% |
| 2 visits | 7,566 | 1,319 | 17.43% |
| 3 visits | 3,411 | 692 | 20.29% |
| 4+ visits | 3,638 | 1,117 | 30.70% |

Prior emergency utilization rates also increased across the defined bands: 10.47% for 0 visits, 14.35% for 1 visit, 18.27% for 2 visits, and 24.94% for 3+ visits. Prior outpatient rates were 10.67%, 13.92%, 13.75%, and 12.98%, respectively, across the same 0, 1, 2, and 3+ visit structure.

Encounters with no prior inpatient, emergency, or outpatient utilization had 4,564 readmissions across 55,825 encounters (8.18%). Encounters with any prior utilization had 6,793 readmissions across 45,938 encounters (14.79%). These patterns are associations and should not be interpreted causally.

### Hospitalization characteristics

Readmission rates differed across length-of-stay bands:

| Length of stay | Encounters | Readmission rate |
| --- | ---: | ---: |
| 1–3 days | 49,186 | 9.69% |
| 4–7 days | 37,288 | 12.19% |
| 8–14 days | 15,289 | 13.38% |

Average characteristics also differed by outcome:

| Outcome | Time in hospital | Medications | Lab procedures | Procedures |
| --- | ---: | ---: | ---: | ---: |
| 30-Day Readmission | 4.77 | 16.90 | 44.23 | 1.28 |
| No 30-Day Readmission | 4.35 | 15.91 | 42.95 | 1.35 |

Encounters involving fewer than 20 medications had a 10.54% readmission rate across 74,194 encounters. Encounters involving 20 or more medications had a 12.82% rate across 27,569 encounters. Longer stays and higher medication counts may reflect greater patient or treatment complexity and should not be interpreted as causes of readmission.

### Diabetes management and laboratory results

A1C results were recorded for 17,018 encounters, including 1,676 readmissions (9.85%). A1C was not recorded for 84,745 encounters, including 9,681 readmissions (11.42%).

Maximum glucose serum readmission rates were 11.09% for Not Recorded, 11.36% for Normal, 12.46% for >200, and 14.32% for >300. Both `A1Cresult` and `max_glu_serum` contain substantial missingness. “Not Recorded” indicates only that the dataset does not contain a recorded result; it is not proof that testing was not performed.

Other diabetes-management comparisons were:

- Insulin: No 10.04%, Steady 11.13%, Up 12.99%, and Down 13.90%.
- Diabetes medication: Yes 11.63% and No 9.60%.
- Medication change: Change 11.82% and No change 10.59%.

Medication and insulin status may reflect underlying disease severity or treatment decisions. These differences are descriptive and should not be interpreted causally.

## Reusable analytical view

The `encounters_analysis` view retains all original fields and adds:

- `readmit_30_flag`: 1 when `readmitted = '<30'`, otherwise 0
- `diagnosis_category`: the standardized project-level grouping derived from primary diagnosis (`diag_1`)

The view stores reusable query logic without modifying `encounters` or duplicating its underlying data. Validation confirmed 101,763 rows in both `encounters` and `encounters_analysis`, a difference of 0. The view produced `SUM(readmit_30_flag) = 11,357` and an overall readmission rate of 11.16%.

## Reproducibility and interpretation

The processed CSV and SQLite database are generated locally and ignored by Git, while SQL source files and documentation are version controlled. Analyses are encounter-level unless explicitly stated otherwise. Results should be interpreted as portfolio-ready descriptive evidence, with group sizes, missingness, and treatment complexity considered alongside percentages; none of the observed associations establishes causation.
