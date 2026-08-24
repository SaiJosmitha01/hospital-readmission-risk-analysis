-- Encounter-level analysis of hospitalization characteristics and 30-day
-- readmission. These results describe associations observed among encounters;
-- longer hospitalization or more medications does not necessarily cause
-- readmission. Medication count can reflect patient or treatment complexity.
-- Group sizes should always be considered alongside readmission percentages.

-- Query 1: Readmission metrics for each exact length of hospital stay.
SELECT
    time_in_hospital,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY time_in_hospital
ORDER BY time_in_hospital ASC;

-- Query 2: Length of stay grouped into natural analytical bands.
WITH length_of_stay_groups AS (
    SELECT
        readmitted,
        CASE
            WHEN time_in_hospital BETWEEN 1 AND 3 THEN '1-3 days'
            WHEN time_in_hospital BETWEEN 4 AND 7 THEN '4-7 days'
            WHEN time_in_hospital BETWEEN 8 AND 14 THEN '8-14 days'
        END AS length_of_stay_group,
        CASE
            WHEN time_in_hospital BETWEEN 1 AND 3 THEN 1
            WHEN time_in_hospital BETWEEN 4 AND 7 THEN 2
            WHEN time_in_hospital BETWEEN 8 AND 14 THEN 3
        END AS group_order
    FROM encounters
)
SELECT
    length_of_stay_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM length_of_stay_groups
WHERE length_of_stay_group IS NOT NULL
GROUP BY length_of_stay_group, group_order
ORDER BY group_order;

-- Query 3: Average hospitalization characteristics for encounters with and
-- without a 30-day readmission.
WITH readmission_outcomes AS (
    SELECT
        CASE
            WHEN readmitted = '<30' THEN '30-Day Readmission'
            ELSE 'No 30-Day Readmission'
        END AS readmission_outcome,
        time_in_hospital,
        num_medications,
        num_lab_procedures,
        num_procedures
    FROM encounters
)
SELECT
    readmission_outcome,
    COUNT(*) AS encounter_count,
    ROUND(AVG(time_in_hospital), 2) AS average_time_in_hospital,
    ROUND(AVG(num_medications), 2) AS average_num_medications,
    ROUND(AVG(num_lab_procedures), 2) AS average_num_lab_procedures,
    ROUND(AVG(num_procedures), 2) AS average_num_procedures
FROM readmission_outcomes
GROUP BY readmission_outcome
ORDER BY CASE readmission_outcome
    WHEN '30-Day Readmission' THEN 1
    ELSE 2
END;

-- Query 4: Medication counts grouped into natural analytical bands.
WITH medication_groups AS (
    SELECT
        readmitted,
        CASE
            WHEN num_medications BETWEEN 0 AND 5 THEN '0-5'
            WHEN num_medications BETWEEN 6 AND 10 THEN '6-10'
            WHEN num_medications BETWEEN 11 AND 15 THEN '11-15'
            WHEN num_medications BETWEEN 16 AND 20 THEN '16-20'
            WHEN num_medications BETWEEN 21 AND 30 THEN '21-30'
            WHEN num_medications >= 31 THEN '31+'
        END AS medication_group,
        CASE
            WHEN num_medications BETWEEN 0 AND 5 THEN 1
            WHEN num_medications BETWEEN 6 AND 10 THEN 2
            WHEN num_medications BETWEEN 11 AND 15 THEN 3
            WHEN num_medications BETWEEN 16 AND 20 THEN 4
            WHEN num_medications BETWEEN 21 AND 30 THEN 5
            WHEN num_medications >= 31 THEN 6
        END AS group_order
    FROM encounters
)
SELECT
    medication_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM medication_groups
WHERE medication_group IS NOT NULL
GROUP BY medication_group, group_order
ORDER BY group_order;

-- Query 5: Descriptive comparison by medication-count complexity.
WITH medication_complexity AS (
    SELECT
        readmitted,
        CASE
            WHEN num_medications >= 20 THEN '20+ medications'
            ELSE 'Fewer than 20 medications'
        END AS medication_complexity_group,
        CASE WHEN num_medications >= 20 THEN 2 ELSE 1 END AS group_order
    FROM encounters
)
SELECT
    medication_complexity_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM medication_complexity
GROUP BY medication_complexity_group, group_order
ORDER BY group_order;
