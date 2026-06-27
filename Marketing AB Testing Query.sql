CREATE DATABASE IF NOT EXISTS marketing_project;
USE marketing_project;

DROP TABLE IF EXISTS marketing_ab;

CREATE TABLE marketing_ab (
    user_id        INT PRIMARY KEY,
    test_group     VARCHAR(3),
    converted      TINYINT(1),
    total_ads      INT,
    most_ads_day   VARCHAR(10),
    most_ads_hour  TINYINT
);

USE marketing_project;

LOAD DATA LOCAL INFILE 'C:/Users/kumar_/Desktop/KS/Analytics/PROJECTS/Marketing AB Testing/marketing_AB.csv'
INTO TABLE marketing_ab
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@skip, user_id, test_group, @conv, total_ads, most_ads_day, most_ads_hour)
SET converted = IF(@conv = 'True', 1, 0);

SET GLOBAL local_infile = 1;

USE marketing_project;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/marketing_AB.csv'
INTO TABLE marketing_ab
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@skip, user_id, test_group, @conv, total_ads, most_ads_day, most_ads_hour)
SET converted = IF(@conv = 'True', 1, 0);

-- Check row count
SELECT COUNT(*) FROM marketing_ab;
-- Should show: 588,101 ✅

-- Check first 5 rows
SELECT * FROM marketing_ab LIMIT 5;

-- Check converted values are 0/1 only
SELECT DISTINCT converted FROM marketing_ab;
-- Should show only: 0 and 1 ✅

-- Check no nulls
SELECT 
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user,
    SUM(CASE WHEN converted IS NULL THEN 1 ELSE 0 END) AS null_converted,
    SUM(CASE WHEN total_ads IS NULL THEN 1 ELSE 0 END) AS null_ads
FROM marketing_ab;
-- All should show 0 ✅




-- Query 1 — Overall KPIs:
SELECT
    COUNT(*)                                           AS total_users,
    SUM(converted)                                     AS total_conversions,
    ROUND(AVG(converted) * 100, 4)                    AS overall_conv_rate_pct,
    COUNT(DISTINCT test_group)                         AS test_groups,
    ROUND(AVG(total_ads), 2)                           AS avg_ads_shown,
    MAX(total_ads)                                     AS max_ads_shown
FROM marketing_ab;

-- Query 2 — Ad vs PSA Group Comparison (Core A/B Result):
SELECT
    test_group,
    COUNT(*)                                           AS total_users,
    SUM(converted)                                     AS conversions,
    ROUND(AVG(converted) * 100, 4)                    AS conversion_rate_pct,
    ROUND(AVG(total_ads), 2)                           AS avg_ads_shown,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM marketing_ab), 2)       AS group_share_pct
FROM marketing_ab
GROUP BY test_group;

-- Query 3 — Conversion Rate by Day:
SELECT
    most_ads_day,
    COUNT(*)                                           AS total_users,
    SUM(converted)                                     AS conversions,
    ROUND(AVG(converted) * 100, 4)                    AS conv_rate_pct,
    ROUND(AVG(total_ads), 1)                           AS avg_ads
FROM marketing_ab
GROUP BY most_ads_day
ORDER BY conv_rate_pct DESC;

-- Query 4 — Conversion Rate by Hour:
SELECT
    most_ads_hour,
    COUNT(*)                                           AS total_users,
    SUM(converted)                                     AS conversions,
    ROUND(AVG(converted) * 100, 4)                    AS conv_rate_pct
FROM marketing_ab
GROUP BY most_ads_hour
ORDER BY most_ads_hour;

-- Query 5 — Conversion by Total Ads Bucket:
SELECT
    CASE
        WHEN total_ads BETWEEN 1 AND 10   THEN '01 — 1 to 10 ads'
        WHEN total_ads BETWEEN 11 AND 25  THEN '02 — 11 to 25 ads'
        WHEN total_ads BETWEEN 26 AND 50  THEN '03 — 26 to 50 ads'
        WHEN total_ads BETWEEN 51 AND 100 THEN '04 — 51 to 100 ads'
        WHEN total_ads BETWEEN 101 AND 200 THEN '05 — 101 to 200 ads'
        WHEN total_ads > 200              THEN '06 — 200+ ads'
    END                                                AS ads_bucket,
    COUNT(*)                                           AS total_users,
    SUM(converted)                                     AS conversions,
    ROUND(AVG(converted) * 100, 4)                    AS conv_rate_pct
FROM marketing_ab
GROUP BY ads_bucket
ORDER BY ads_bucket;

-- Query 6 — Best Day + Hour Combinations:
SELECT
    most_ads_day,
    most_ads_hour,
    COUNT(*)                                           AS total_users,
    SUM(converted)                                     AS conversions,
    ROUND(AVG(converted) * 100, 4)                    AS conv_rate_pct
FROM marketing_ab
GROUP BY most_ads_day, most_ads_hour
HAVING total_users >= 100
ORDER BY conv_rate_pct DESC
LIMIT 15;

-- Query 7 — Create Analytical VIEW:
CREATE OR REPLACE VIEW vw_ab_summary AS
SELECT
    test_group,
    most_ads_day,
    most_ads_hour,
    CASE
        WHEN total_ads BETWEEN 1 AND 10   THEN '01-10 ads'
        WHEN total_ads BETWEEN 11 AND 25  THEN '11-25 ads'
        WHEN total_ads BETWEEN 26 AND 50  THEN '26-50 ads'
        WHEN total_ads BETWEEN 51 AND 100 THEN '51-100 ads'
        WHEN total_ads BETWEEN 101 AND 200 THEN '101-200 ads'
        WHEN total_ads > 200              THEN '200+ ads'
    END                                                AS ads_bucket,
    COUNT(*)                                           AS total_users,
    SUM(converted)                                     AS conversions,
    ROUND(AVG(converted) * 100, 4)                    AS conv_rate_pct,
    ROUND(AVG(total_ads), 2)                           AS avg_ads
FROM marketing_ab
GROUP BY test_group, most_ads_day, most_ads_hour, ads_bucket;