-- QA Defect Analytics: SQL versions of the key questions.
-- Runs against the cleaned table `bugs` (see notebooks/defect_analysis.ipynb, which loads
-- data/clean/firefox_bugs_clean.csv into SQLite and runs every query below).

-- name: outcome_breakdown
-- What happens to bug reports once they're filed?
SELECT
    outcome,
    COUNT(*) AS bugs,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM bugs), 1) AS pct_of_reports
FROM bugs
GROUP BY outcome
ORDER BY bugs DESC;

-- name: components_fixed_and_regressions
-- Which parts of Firefox produce the most real (fixed) bugs, and how many are regressions?
SELECT
    component,
    COUNT(*) AS reports,
    SUM(outcome = 'Fixed') AS fixed_bugs,
    SUM(is_regression) AS regressions,
    ROUND(100.0 * SUM(is_regression) / COUNT(*), 1) AS regression_rate_pct
FROM bugs
GROUP BY component
HAVING COUNT(*) >= 200
ORDER BY fixed_bugs DESC
LIMIT 10;

-- name: fix_time_by_severity
-- How long do fixed bugs take to resolve, by severity? (Average shown next to the bug count;
-- the notebook uses the median because a few very old bugs drag the average up.)
SELECT
    severity,
    COUNT(*) AS fixed_bugs,
    ROUND(AVG(days_to_resolve), 1) AS avg_days_to_fix
FROM bugs
WHERE outcome = 'Fixed'
GROUP BY severity
ORDER BY severity;

-- name: regression_vs_other
-- Do regressions get treated differently from other bugs?
SELECT
    CASE WHEN is_regression = 1 THEN 'Regression' ELSE 'Other bug' END AS bug_kind,
    COUNT(*) AS reports,
    ROUND(100.0 * SUM(outcome = 'Fixed') / COUNT(*), 1) AS fix_rate_pct
FROM bugs
GROUP BY bug_kind;

-- name: open_backlog_by_year
-- How big is the open backlog, and how much of it was never given a severity?
SELECT
    created_year,
    COUNT(*) AS open_bugs,
    SUM(severity = 'Not set') AS open_without_severity
FROM bugs
WHERE outcome = 'Still open'
GROUP BY created_year
ORDER BY created_year;
