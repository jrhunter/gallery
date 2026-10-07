-- Analytical model over the IPEDS snapshot in data/.
-- Loaded by report.qmd, index.qmd, and scripts/render_all.py, so every output
-- is built from the same definitions.

-- Smallest cohort for which a rate is reported. Below this, one or two
-- students move a rate by several points.
CREATE OR REPLACE MACRO min_cohort() AS 30;

CREATE OR REPLACE VIEW institutions AS
SELECT
    d.unitid,
    d.inst_name,
    d.city,
    d.state_abbr,
    d.inst_control,
    d.cc_basic_2021 AS carnegie,
    CASE d.inst_control
        WHEN 1 THEN 'Public'
        WHEN 2 THEN 'Private nonprofit'
        WHEN 3 THEN 'Private for-profit'
    END AS control_label,
    coalesce(c.label, 'Carnegie class ' || d.cc_basic_2021::INT) AS carnegie_label,
    -- file name of this institution's rendered report
    d.unitid || '-' || trim(regexp_replace(lower(d.inst_name), '[^a-z0-9]+', '-', 'g'), '-')
        || '.html' AS report_file
FROM read_parquet('data/directory.parquet') AS d
LEFT JOIN (
    VALUES
        (14, 'Baccalaureate/Associate''s: Associate''s Dominant'),
        (15, 'Doctoral: Very High Research Activity'),
        (16, 'Doctoral: High Research Activity'),
        (17, 'Doctoral/Professional'),
        (18, 'Master''s: Larger Programs'),
        (19, 'Master''s: Medium Programs'),
        (20, 'Master''s: Small Programs'),
        (21, 'Baccalaureate: Arts & Sciences'),
        (22, 'Baccalaureate: Diverse Fields'),
        (23, 'Baccalaureate/Associate''s: Mixed'),
        (24, 'Special Focus: Faith-Related'),
        (26, 'Special Focus: Other Health Professions'),
        (28, 'Special Focus: Engineering & Technology'),
        (29, 'Special Focus: Business & Management'),
        (30, 'Special Focus: Arts, Music & Design'),
        (32, 'Special Focus: Other'),
        (33, 'Tribal Colleges & Universities')
) AS c (code, label) ON c.code = d.cc_basic_2021
WHERE d.cc_basic_2021 > 0;

-- One row per institution, year, and measure. Rates are recomputed from counts
-- (the API rounds them to two decimals); the portal's negative missing-data
-- codes and cohorts under min_cohort() drop out here.
CREATE OR REPLACE VIEW metrics AS
SELECT
    unitid, year, 'grad_rate' AS metric,
    completers_150pct / cohort_adj_150pct AS value,
    cohort_adj_150pct AS base
FROM read_parquet('data/grad_rates.parquet')
WHERE race = 99 AND completers_150pct >= 0 AND cohort_adj_150pct >= min_cohort()
UNION ALL
SELECT
    unitid, year, 'retention_rate',
    returning_students / prev_cohort_adj,
    prev_cohort_adj
FROM read_parquet('data/fall_retention.parquet')
WHERE returning_students >= 0 AND prev_cohort_adj >= min_cohort()
UNION ALL
SELECT unitid, year, 'enrollment', enrollment_fall, enrollment_fall
FROM read_parquet('data/fall_enrollment.parquet')
WHERE enrollment_fall > 0;

-- Six-year graduation rate by race/ethnicity, latest year only.
CREATE OR REPLACE VIEW grad_by_race AS
SELECT
    g.unitid,
    g.year,
    r.label AS race,
    r.sort_order,
    g.completers_150pct AS completers,
    g.cohort_adj_150pct AS cohort
FROM read_parquet('data/grad_rates.parquet') AS g
JOIN (
    VALUES
        (5, 'American Indian or Alaska Native', 1),
        (4, 'Asian', 2),
        (2, 'Black', 3),
        (3, 'Hispanic', 4),
        (6, 'Native Hawaiian or Pacific Islander', 5),
        (1, 'White', 6),
        (7, 'Two or more races', 7),
        (8, 'U.S. nonresident', 8)
) AS r (code, label, sort_order) ON r.code = g.race
WHERE g.year = (SELECT max(year) FROM read_parquet('data/grad_rates.parquet'))
  AND g.completers_150pct >= 0 AND g.cohort_adj_150pct > 0;

-- Peer group: every other institution with the same control and the same
-- 2021 Carnegie Basic classification, nationwide.
CREATE OR REPLACE VIEW peer_pairs AS
SELECT a.unitid, b.unitid AS peer_unitid
FROM institutions AS a
JOIN institutions AS b USING (inst_control, carnegie)
WHERE a.unitid <> b.unitid;

-- Institutions that get a report: a current graduation rate of their own and
-- at least ten peers that have one too.
CREATE OR REPLACE VIEW report_universe AS
WITH latest AS (
    SELECT unitid
    FROM metrics
    WHERE metric = 'grad_rate'
      AND year = (SELECT max(year) FROM metrics WHERE metric = 'grad_rate')
)
SELECT i.*, count(*) AS n_peers
FROM institutions AS i
JOIN latest USING (unitid)
JOIN peer_pairs AS p USING (unitid)
JOIN latest AS l ON l.unitid = p.peer_unitid
GROUP BY ALL
HAVING count(*) >= 10;
