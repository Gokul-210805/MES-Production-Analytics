-- MES Production Analytics
-- PostgreSQL analysis queries
-- Dataset: MES_Machine_Production_data.xlsx

DROP TABLE IF EXISTS mes_production;

CREATE TABLE mes_production (
    production_date DATE,
    shift VARCHAR(50),
    machine_id VARCHAR(50),
    production_line VARCHAR(100),
    operator VARCHAR(100),
    planned_qty INTEGER,
    actual_qty INTEGER,
    downtime_mins INTEGER,
    defect_qty INTEGER,
    downtime_reason VARCHAR(255)
);

-- Import the Excel data after exporting it to CSV.
-- In pgAdmin, use Import/Export Data on the mes_production table.
-- Recommended CSV settings:
-- Header: ON
-- Delimiter: ,
-- Quote: "
-- Escape: "

-- ============================================================
-- 1. BASIC DATA CHECKS
-- ============================================================

SELECT COUNT(*) AS total_records
FROM mes_production;

SELECT *
FROM mes_production
LIMIT 10;

SELECT
    MIN(production_date) AS start_date,
    MAX(production_date) AS end_date
FROM mes_production;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT machine_id) AS total_machines,
    COUNT(DISTINCT production_line) AS total_lines,
    COUNT(DISTINCT operator) AS total_operators
FROM mes_production;

-- ============================================================
-- 2. OVERALL PRODUCTION KPIs
-- ============================================================

SELECT
    SUM(planned_qty) AS total_planned_qty,
    SUM(actual_qty) AS total_actual_qty,
    SUM(actual_qty) - SUM(planned_qty) AS production_variance,
    SUM(downtime_mins) AS total_downtime_mins,
    SUM(defect_qty) AS total_defect_qty
FROM mes_production;

-- Overall achievement percentage
SELECT
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage
FROM mes_production;

-- Overall defect percentage
SELECT
    ROUND(
        SUM(defect_qty)::NUMERIC / NULLIF(SUM(actual_qty), 0) * 100,
        2
    ) AS defect_percentage
FROM mes_production;

-- ============================================================
-- 3. DAILY PRODUCTION ANALYSIS
-- ============================================================

SELECT
    production_date,
    SUM(planned_qty) AS planned_qty,
    SUM(actual_qty) AS actual_qty,
    SUM(actual_qty) - SUM(planned_qty) AS variance,
    SUM(downtime_mins) AS downtime_mins,
    SUM(defect_qty) AS defect_qty,
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage
FROM mes_production
GROUP BY production_date
ORDER BY production_date;

-- ============================================================
-- 4. SHIFT ANALYSIS
-- ============================================================

SELECT
    shift,
    SUM(planned_qty) AS planned_qty,
    SUM(actual_qty) AS actual_qty,
    SUM(actual_qty) - SUM(planned_qty) AS variance,
    SUM(downtime_mins) AS downtime_mins,
    SUM(defect_qty) AS defect_qty,
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage
FROM mes_production
GROUP BY shift
ORDER BY achievement_percentage DESC;

-- ============================================================
-- 5. MACHINE PERFORMANCE
-- ============================================================

SELECT
    machine_id,
    SUM(planned_qty) AS planned_qty,
    SUM(actual_qty) AS actual_qty,
    SUM(actual_qty) - SUM(planned_qty) AS variance,
    SUM(downtime_mins) AS downtime_mins,
    SUM(defect_qty) AS defect_qty,
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage
FROM mes_production
GROUP BY machine_id
ORDER BY achievement_percentage DESC;

-- Machines below 90% achievement
SELECT
    machine_id,
    SUM(planned_qty) AS planned_qty,
    SUM(actual_qty) AS actual_qty,
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage
FROM mes_production
GROUP BY machine_id
HAVING SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100 < 90
ORDER BY achievement_percentage;

-- ============================================================
-- 6. PRODUCTION LINE ANALYSIS
-- ============================================================

SELECT
    production_line,
    SUM(planned_qty) AS planned_qty,
    SUM(actual_qty) AS actual_qty,
    SUM(actual_qty) - SUM(planned_qty) AS variance,
    SUM(downtime_mins) AS downtime_mins,
    SUM(defect_qty) AS defect_qty,
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage
FROM mes_production
GROUP BY production_line
ORDER BY achievement_percentage DESC;

-- ============================================================
-- 7. OPERATOR PERFORMANCE
-- ============================================================

SELECT
    operator,
    SUM(planned_qty) AS planned_qty,
    SUM(actual_qty) AS actual_qty,
    SUM(downtime_mins) AS downtime_mins,
    SUM(defect_qty) AS defect_qty,
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage
FROM mes_production
GROUP BY operator
ORDER BY achievement_percentage DESC;

-- ============================================================
-- 8. DOWNTIME ANALYSIS
-- ============================================================

SELECT
    downtime_reason,
    COUNT(*) AS occurrences,
    SUM(downtime_mins) AS total_downtime_mins,
    ROUND(AVG(downtime_mins), 2) AS avg_downtime_mins
FROM mes_production
GROUP BY downtime_reason
ORDER BY total_downtime_mins DESC;

-- Top downtime reasons
SELECT
    downtime_reason,
    SUM(downtime_mins) AS total_downtime_mins
FROM mes_production
GROUP BY downtime_reason
ORDER BY total_downtime_mins DESC
LIMIT 5;

-- ============================================================
-- 9. DEFECT / QUALITY ANALYSIS
-- ============================================================

SELECT
    machine_id,
    SUM(actual_qty) AS actual_qty,
    SUM(defect_qty) AS defect_qty,
    ROUND(
        SUM(defect_qty)::NUMERIC / NULLIF(SUM(actual_qty), 0) * 100,
        2
    ) AS defect_percentage
FROM mes_production
GROUP BY machine_id
ORDER BY defect_percentage DESC;

-- Lines with highest defect percentage
SELECT
    production_line,
    SUM(actual_qty) AS actual_qty,
    SUM(defect_qty) AS defect_qty,
    ROUND(
        SUM(defect_qty)::NUMERIC / NULLIF(SUM(actual_qty), 0) * 100,
        2
    ) AS defect_percentage
FROM mes_production
GROUP BY production_line
ORDER BY defect_percentage DESC;

-- ============================================================
-- 10. CASE WHEN ANALYSIS
-- ============================================================

SELECT
    machine_id,
    SUM(planned_qty) AS planned_qty,
    SUM(actual_qty) AS actual_qty,
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage,
    CASE
        WHEN SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100 >= 100
            THEN 'Above Target'
        WHEN SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100 >= 90
            THEN 'Near Target'
        ELSE 'Below Target'
    END AS performance_status
FROM mes_production
GROUP BY machine_id
ORDER BY achievement_percentage DESC;

-- ============================================================
-- 11. SUBQUERY ANALYSIS
-- ============================================================

-- Machines with downtime above the average machine downtime
SELECT
    machine_id,
    SUM(downtime_mins) AS total_downtime_mins
FROM mes_production
GROUP BY machine_id
HAVING SUM(downtime_mins) >
       (
           SELECT AVG(machine_downtime)
           FROM (
               SELECT
                   machine_id,
                   SUM(downtime_mins) AS machine_downtime
               FROM mes_production
               GROUP BY machine_id
           ) AS machine_summary
       )
ORDER BY total_downtime_mins DESC;

-- ============================================================
-- 12. CTE ANALYSIS
-- ============================================================

WITH machine_summary AS (
    SELECT
        machine_id,
        SUM(planned_qty) AS planned_qty,
        SUM(actual_qty) AS actual_qty,
        SUM(downtime_mins) AS downtime_mins,
        SUM(defect_qty) AS defect_qty
    FROM mes_production
    GROUP BY machine_id
)
SELECT
    machine_id,
    planned_qty,
    actual_qty,
    downtime_mins,
    defect_qty,
    ROUND(
        actual_qty::NUMERIC / NULLIF(planned_qty, 0) * 100,
        2
    ) AS achievement_percentage
FROM machine_summary
ORDER BY achievement_percentage DESC;

-- ============================================================
-- 13. WINDOW FUNCTIONS
-- ============================================================

-- Rank machines by production achievement
WITH machine_performance AS (
    SELECT
        machine_id,
        SUM(planned_qty) AS planned_qty,
        SUM(actual_qty) AS actual_qty
    FROM mes_production
    GROUP BY machine_id
)
SELECT
    machine_id,
    planned_qty,
    actual_qty,
    ROUND(
        actual_qty::NUMERIC / NULLIF(planned_qty, 0) * 100,
        2
    ) AS achievement_percentage,
    RANK() OVER (
        ORDER BY actual_qty::NUMERIC / NULLIF(planned_qty, 0) DESC
    ) AS machine_rank
FROM machine_performance
ORDER BY machine_rank;

-- ============================================================
-- 14. DAILY PRODUCTION WITH LAG
-- ============================================================

WITH daily_production AS (
    SELECT
        production_date,
        SUM(actual_qty) AS actual_qty
    FROM mes_production
    GROUP BY production_date
)
SELECT
    production_date,
    actual_qty,
    LAG(actual_qty) OVER (
        ORDER BY production_date
    ) AS previous_day_actual_qty,
    actual_qty -
    LAG(actual_qty) OVER (
        ORDER BY production_date
    ) AS change_from_previous_day
FROM daily_production
ORDER BY production_date;

-- ============================================================
-- 15. MACHINE RANK WITHIN EACH PRODUCTION LINE
-- ============================================================

WITH machine_line AS (
    SELECT
        production_line,
        machine_id,
        SUM(planned_qty) AS planned_qty,
        SUM(actual_qty) AS actual_qty
    FROM mes_production
    GROUP BY production_line, machine_id
)
SELECT
    production_line,
    machine_id,
    planned_qty,
    actual_qty,
    ROUND(
        actual_qty::NUMERIC / NULLIF(planned_qty, 0) * 100,
        2
    ) AS achievement_percentage,
    RANK() OVER (
        PARTITION BY production_line
        ORDER BY actual_qty::NUMERIC / NULLIF(planned_qty, 0) DESC
    ) AS machine_rank_in_line
FROM machine_line
ORDER BY production_line, machine_rank_in_line;

-- ============================================================
-- 16. HIGH DOWNTIME RECORDS
-- ============================================================

SELECT *
FROM mes_production
WHERE downtime_mins > (
    SELECT AVG(downtime_mins)
    FROM mes_production
)
ORDER BY downtime_mins DESC;

-- ============================================================
-- 17. HIGH DEFECT RECORDS
-- ============================================================

SELECT *
FROM mes_production
WHERE defect_qty > (
    SELECT AVG(defect_qty)
    FROM mes_production
)
ORDER BY defect_qty DESC;

-- ============================================================
-- 18. FINAL MANAGEMENT SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT machine_id) AS total_machines,
    COUNT(DISTINCT production_line) AS total_lines,
    SUM(planned_qty) AS total_planned_qty,
    SUM(actual_qty) AS total_actual_qty,
    SUM(downtime_mins) AS total_downtime_mins,
    SUM(defect_qty) AS total_defect_qty,
    ROUND(
        SUM(actual_qty)::NUMERIC / NULLIF(SUM(planned_qty), 0) * 100,
        2
    ) AS achievement_percentage,
    ROUND(
        SUM(defect_qty)::NUMERIC / NULLIF(SUM(actual_qty), 0) * 100,
        2
    ) AS defect_percentage
FROM mes_production;
