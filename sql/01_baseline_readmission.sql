-- Baseline readmission analysis
--
-- Each row in encounters represents one encounter. Accordingly, all counts and
-- percentages below use encounter records as the denominator, not unique patients.

-- 1. Readmission category distribution
-- Show the number and percentage of encounters in each recorded readmission
-- category. Multiplying by 100.0 ensures SQLite performs decimal division.
SELECT
    readmitted,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM encounters), 2)
        AS percentage_of_total
FROM encounters
GROUP BY readmitted
ORDER BY encounter_count DESC, readmitted;

-- 2. Overall 30-day readmission KPI
-- The '<30' category is the 30-day readmission outcome. Encounters categorized
-- as 'NO' or '>30' are not counted as 30-day readmissions.
-- This KPI also uses all encounter records, rather than unique patients, as its
-- denominator.
SELECT
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM encounters;
