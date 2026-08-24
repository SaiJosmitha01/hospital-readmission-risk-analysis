-- Encounter-level 30-day readmission analysis by primary diagnosis.
--
-- Diagnosis categories are derived only from the primary diagnosis in diag_1.
-- This project-level analytical grouping consolidates ICD-9 codes into broader
-- categories; it is not a replacement for the underlying clinical codes.
-- Rates use all encounters within each diagnosis category as the denominator.
-- A high readmission rate and high encounter volume are different concepts, so
-- both views are included below. This analysis is descriptive and does not
-- establish that a diagnosis category causes readmission.

-- Query 1: Diagnosis categories ranked by 30-day readmission rate.
WITH categorized_encounters AS (
    SELECT
        diag_1,
        readmitted,
        CASE
            WHEN diag_1 IS NULL
                 OR TRIM(diag_1) = ''
                 OR TRIM(diag_1) = '?'
                THEN 'Unknown'
            -- Test V/E prefixes before numeric conversion because SQLite casts
            -- nonnumeric text such as V45 or E849 to zero.
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
    FROM encounters
)
SELECT
    diagnosis_category,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM categorized_encounters
GROUP BY diagnosis_category
ORDER BY readmission_rate_pct DESC, diagnosis_category;

-- Query 2: The same category metrics ranked by encounter volume, highlighting
-- categories that are common even when they do not have the highest rate.
WITH categorized_encounters AS (
    SELECT
        diag_1,
        readmitted,
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
    FROM encounters
)
SELECT
    diagnosis_category,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM categorized_encounters
GROUP BY diagnosis_category
ORDER BY total_encounters DESC, diagnosis_category;

-- Query 3: The 15 most common raw primary diagnosis codes assigned to the
-- Diabetes category. Each code's denominator is all encounters with that code.
WITH categorized_encounters AS (
    SELECT
        diag_1,
        readmitted,
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
    FROM encounters
)
SELECT
    diag_1,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM categorized_encounters
WHERE diagnosis_category = 'Diabetes'
GROUP BY diag_1
ORDER BY total_encounters DESC, readmission_rate_pct DESC, diag_1
LIMIT 15;
