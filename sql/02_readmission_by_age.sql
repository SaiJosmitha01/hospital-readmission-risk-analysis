-- 30-day readmission by age group
--
-- This is encounter-level analysis: each record represents an encounter, not a
-- unique patient. For every age group, the denominator is all encounters in that
-- group, and readmitted = '<30' identifies a 30-day readmission.
--
-- Rates are more useful than raw readmission counts when comparing age groups
-- because groups can contain different numbers of encounters. This descriptive
-- analysis identifies patterns in the data; it does not establish that age causes
-- readmission.

-- Query 1: Age-group readmission metrics in natural age-bin order.
SELECT
    age,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY age
ORDER BY CASE age
    WHEN '[0-10)' THEN 1
    WHEN '[10-20)' THEN 2
    WHEN '[20-30)' THEN 3
    WHEN '[30-40)' THEN 4
    WHEN '[40-50)' THEN 5
    WHEN '[50-60)' THEN 6
    WHEN '[60-70)' THEN 7
    WHEN '[70-80)' THEN 8
    WHEN '[80-90)' THEN 9
    WHEN '[90-100)' THEN 10
    ELSE 11
END;

-- Query 2: Rank age groups from highest to lowest 30-day readmission rate.
-- The raw counts remain visible to provide context for each group's rate.
SELECT
    age,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters
GROUP BY age
ORDER BY readmission_rate_pct DESC, CASE age
    WHEN '[0-10)' THEN 1
    WHEN '[10-20)' THEN 2
    WHEN '[20-30)' THEN 3
    WHEN '[30-40)' THEN 4
    WHEN '[40-50)' THEN 5
    WHEN '[50-60)' THEN 6
    WHEN '[60-70)' THEN 7
    WHEN '[70-80)' THEN 8
    WHEN '[80-90)' THEN 9
    WHEN '[90-100)' THEN 10
    ELSE 11
END;
