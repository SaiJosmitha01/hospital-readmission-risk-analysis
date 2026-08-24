-- Encounter-level 30-day readmission analysis by prior healthcare utilization.
--
-- number_inpatient, number_emergency, and number_outpatient represent prior
-- healthcare utilization recorded in the dataset. Rates are calculated using all
-- encounters within each utilization group as the denominator. Comparing rates is
-- more informative than comparing raw readmission counts alone because group sizes
-- differ. Very small high-utilization groups should be interpreted cautiously.
-- These results describe associations at the encounter level and do not establish
-- that prior utilization causes readmission.

-- Query 1: Readmission metrics for each exact number of prior inpatient visits.
SELECT
    number_inpatient,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY number_inpatient
ORDER BY number_inpatient ASC;

-- Query 2: Prior inpatient visits grouped into analytical utilization bands.
WITH inpatient_groups AS (
    SELECT
        readmitted,
        CASE
            WHEN number_inpatient = 0 THEN '0 visits'
            WHEN number_inpatient = 1 THEN '1 visit'
            WHEN number_inpatient = 2 THEN '2 visits'
            WHEN number_inpatient = 3 THEN '3 visits'
            ELSE '4+ visits'
        END AS inpatient_utilization_group,
        CASE
            WHEN number_inpatient = 0 THEN 0
            WHEN number_inpatient = 1 THEN 1
            WHEN number_inpatient = 2 THEN 2
            WHEN number_inpatient = 3 THEN 3
            ELSE 4
        END AS group_order
    FROM encounters
)
SELECT
    inpatient_utilization_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM inpatient_groups
GROUP BY inpatient_utilization_group, group_order
ORDER BY group_order;

-- Query 3: Prior emergency visits grouped into analytical utilization bands.
WITH emergency_groups AS (
    SELECT
        readmitted,
        CASE
            WHEN number_emergency = 0 THEN '0 visits'
            WHEN number_emergency = 1 THEN '1 visit'
            WHEN number_emergency = 2 THEN '2 visits'
            ELSE '3+ visits'
        END AS emergency_utilization_group,
        CASE
            WHEN number_emergency = 0 THEN 0
            WHEN number_emergency = 1 THEN 1
            WHEN number_emergency = 2 THEN 2
            ELSE 3
        END AS group_order
    FROM encounters
)
SELECT
    emergency_utilization_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM emergency_groups
GROUP BY emergency_utilization_group, group_order
ORDER BY group_order;

-- Query 4: Prior outpatient visits grouped into analytical utilization bands.
WITH outpatient_groups AS (
    SELECT
        readmitted,
        CASE
            WHEN number_outpatient = 0 THEN '0 visits'
            WHEN number_outpatient = 1 THEN '1 visit'
            WHEN number_outpatient = 2 THEN '2 visits'
            ELSE '3+ visits'
        END AS outpatient_utilization_group,
        CASE
            WHEN number_outpatient = 0 THEN 0
            WHEN number_outpatient = 1 THEN 1
            WHEN number_outpatient = 2 THEN 2
            ELSE 3
        END AS group_order
    FROM encounters
)
SELECT
    outpatient_utilization_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM outpatient_groups
GROUP BY outpatient_utilization_group, group_order
ORDER BY group_order;

-- Query 5: Compare encounters with no recorded prior utilization against those
-- with at least one prior inpatient, emergency, or outpatient visit.
WITH combined_utilization AS (
    SELECT
        readmitted,
        CASE
            WHEN number_inpatient = 0
                 AND number_emergency = 0
                 AND number_outpatient = 0
                THEN 'No prior utilization'
            ELSE 'Any prior utilization'
        END AS utilization_group,
        CASE
            WHEN number_inpatient = 0
                 AND number_emergency = 0
                 AND number_outpatient = 0
                THEN 0
            ELSE 1
        END AS group_order
    FROM encounters
)
SELECT
    utilization_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM combined_utilization
GROUP BY utilization_group, group_order
ORDER BY group_order;
