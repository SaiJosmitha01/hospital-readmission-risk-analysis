-- Encounter-level analysis of diabetes management, laboratory results, and
-- 30-day readmission.
--
-- A1Cresult and max_glu_serum contain substantial missingness. "Not Recorded"
-- means that the dataset does not contain a recorded result; it should not
-- automatically be interpreted as evidence that the test was not performed.
-- Differences between groups are descriptive associations only. Medication and
-- insulin status may reflect underlying disease severity or treatment decisions,
-- so these results should not be interpreted causally.

-- Query 1: A1C result categories, including "Not Recorded," ranked by volume.
SELECT
    A1Cresult,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY A1Cresult
ORDER BY total_encounters DESC, A1Cresult;

-- Query 2: Maximum glucose serum result categories, including "Not Recorded,"
-- ranked by encounter volume.
SELECT
    max_glu_serum,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY max_glu_serum
ORDER BY total_encounters DESC, max_glu_serum;

-- Query 3: Insulin status ranked by 30-day readmission rate.
SELECT
    insulin,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY insulin
ORDER BY readmission_rate_pct DESC, insulin;

-- Query 4: Diabetes medication status.
SELECT
    diabetesMed,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY diabetesMed
ORDER BY total_encounters DESC, diabetesMed;

-- Query 5: Medication change status.
SELECT
    change,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY change
ORDER BY total_encounters DESC, change;

-- Query 6: Compare encounters with a recorded A1C result against encounters for
-- which the dataset contains no recorded A1C result.
WITH a1c_recording_groups AS (
    SELECT
        readmitted,
        CASE
            WHEN A1Cresult = 'Not Recorded' THEN 'A1C Not Recorded'
            ELSE 'A1C Recorded'
        END AS a1c_recording_group,
        CASE WHEN A1Cresult = 'Not Recorded' THEN 2 ELSE 1 END AS group_order
    FROM encounters
)
SELECT
    a1c_recording_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM a1c_recording_groups
GROUP BY a1c_recording_group, group_order
ORDER BY group_order;
