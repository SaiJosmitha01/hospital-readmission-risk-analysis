-- Reusable analytical view for SQL analysis and Tableau.
--
-- encounters_analysis standardizes fields that are repeatedly needed in later
-- analysis while retaining every original encounters column. The original
-- encounters table is not modified. A view stores reusable query logic rather
-- than creating and duplicating the underlying encounter data.

DROP VIEW IF EXISTS encounters_analysis;

CREATE VIEW encounters_analysis AS
SELECT
    encounters.*,

    -- A value of 1 identifies an encounter readmitted within 30 days; all other
    -- readmission outcomes receive 0.
    CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END AS readmit_30_flag,

    -- Project-level analytical grouping of the primary ICD-9 diagnosis in
    -- diag_1. Text prefixes are checked before numeric conversion because diag_1
    -- contains a mixture of numeric codes and V/E codes.
    CASE
        WHEN diag_1 IS NULL
             OR TRIM(diag_1) = ''
             OR TRIM(diag_1) = '?'
            THEN 'Unknown'
        WHEN UPPER(SUBSTR(TRIM(diag_1), 1, 1)) IN ('V', 'E')
            THEN 'Other'
        WHEN (CAST(TRIM(diag_1) AS REAL) BETWEEN 390 AND 459)
             OR CAST(TRIM(diag_1) AS REAL) = 785
            THEN 'Circulatory'
        WHEN (CAST(TRIM(diag_1) AS REAL) BETWEEN 460 AND 519)
             OR CAST(TRIM(diag_1) AS REAL) = 786
            THEN 'Respiratory'
        WHEN (CAST(TRIM(diag_1) AS REAL) BETWEEN 520 AND 579)
             OR CAST(TRIM(diag_1) AS REAL) = 787
            THEN 'Digestive'
        WHEN CAST(TRIM(diag_1) AS REAL) >= 250
             AND CAST(TRIM(diag_1) AS REAL) < 251
            THEN 'Diabetes'
        WHEN CAST(TRIM(diag_1) AS REAL) BETWEEN 800 AND 999
            THEN 'Injury'
        WHEN CAST(TRIM(diag_1) AS REAL) BETWEEN 710 AND 739
            THEN 'Musculoskeletal'
        WHEN (CAST(TRIM(diag_1) AS REAL) BETWEEN 580 AND 629)
             OR CAST(TRIM(diag_1) AS REAL) = 788
            THEN 'Genitourinary'
        WHEN CAST(TRIM(diag_1) AS REAL) BETWEEN 140 AND 239
            THEN 'Neoplasms'
        ELSE 'Other'
    END AS diagnosis_category
FROM encounters;

-- Validation 1: Total encounter rows exposed by the view.
SELECT COUNT(*) AS total_encounters
FROM encounters_analysis;

-- Validation 2: Total encounters readmitted within 30 days.
SELECT SUM(readmit_30_flag) AS readmitted_within_30_days
FROM encounters_analysis;

-- Validation 3: Overall 30-day readmission rate.
SELECT ROUND(AVG(readmit_30_flag) * 100.0, 2) AS readmission_rate_pct
FROM encounters_analysis;

-- Validation 4: Encounter counts by derived primary diagnosis category.
SELECT
    diagnosis_category,
    COUNT(*) AS total_encounters
FROM encounters_analysis
GROUP BY diagnosis_category
ORDER BY total_encounters DESC, diagnosis_category;

-- Validation 5: The view should expose exactly one row per encounters row.
SELECT
    (SELECT COUNT(*) FROM encounters) AS encounters_row_count,
    (SELECT COUNT(*) FROM encounters_analysis) AS analysis_view_row_count,
    (SELECT COUNT(*) FROM encounters_analysis)
        - (SELECT COUNT(*) FROM encounters) AS row_count_difference;
