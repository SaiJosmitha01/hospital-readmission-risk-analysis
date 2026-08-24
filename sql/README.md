# Phase 4 — SQL Analysis

This directory contains the portfolio's SQLite analysis of encounter-level 30-day readmission patterns. The analysis uses `readmitted = '<30'` to identify a 30-day readmission. Unless explicitly stated otherwise, calculations use encounters—not unique patients—as the unit of analysis.

## Data and database

- Source: `data/processed/diabetic_data_cleaned.csv`
- SQLite database: `database/hospital_readmission.db`
- Base table: `encounters`
- Analytical view: `encounters_analysis`

The validated database contains 101,763 encounters, 48 source columns, 101,763 unique encounter IDs, and 71,515 unique patients. The processed CSV and SQLite database are generated locally and ignored by Git; SQL source files and documentation are version controlled.

Generate the database from the project root:

```bash
python database/load_data.py
```

Run an analysis file with the SQLite command-line client. For example:

```bash
sqlite3 -header -column database/hospital_readmission.db < sql/01_baseline_readmission.sql
```

Run `07_create_analysis_view.sql` before querying `encounters_analysis` in a newly generated database.

## SQL files

| File | Purpose |
| --- | --- |
| `01_baseline_readmission.sql` | Establishes the readmission outcome distribution and overall 30-day readmission KPI. |
| `02_readmission_by_age.sql` | Compares encounter counts and 30-day readmission rates across naturally ordered age groups. |
| `03_readmission_by_diagnosis.sql` | Groups primary ICD-9 diagnosis codes from `diag_1` into project-level categories and compares both category rates and volumes. |
| `04_readmission_by_prior_utilization.sql` | Examines prior inpatient, emergency, outpatient, and combined healthcare utilization. |
| `05_readmission_by_hospitalization.sql` | Describes readmission patterns by length of stay, medication count, and other hospitalization characteristics. |
| `06_readmission_by_diabetes_management.sql` | Compares A1C, glucose, insulin, diabetes medication, and medication-change groups. |
| `07_create_analysis_view.sql` | Creates and validates `encounters_analysis`, adding standardized `readmit_30_flag` and `diagnosis_category` fields without modifying `encounters`. |

## Interpretation

The SQL results describe associations in this dataset and do not establish causation. Group sizes should be assessed alongside percentages, and “Not Recorded” laboratory values mean only that the dataset lacks a recorded result—not necessarily that a test was not performed.
