# Marketing-A/B-Testing

# 📊 Marketing A/B Testing Campaign Dashboard

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Records](https://img.shields.io/badge/Records-588%2C101-7C3AED?style=for-the-badge)
![Lift](https://img.shields.io/badge/Ad%20Lift-43.09%25-10B981?style=for-the-badge)

![Marketing AB Testing Dashboard](marketing-ab-testing-dashboard-1.jpeg)

![Marketing AB Testing Dashboard 2](marketing-ab-testing-dashboard-2.jpeg)

![Marketing AB Testing Dashboard 3](marketing-ab-testing-dashboard-3.jpeg)

> Data Analytics · IK.S. · Tools: MySQL → Power BI
> **Note: Excel was NOT used — EDA confirmed it was unnecessary**

---

## 📌 Project Overview

Conducted systematic EDA confirming zero nulls, zero duplicates, and no formatting issues — determining Excel was NOT required. • Imported 588,101 A/B testing records directly into MySQL via LOAD DATA LOCAL INFILE in 6.922 seconds — skipping the row-index column and converting boolean True/False to integer 0/1 inline. • Executed 7 analytical SQL queries quantifying a 43.09% ad campaign lift, identifying Monday 14:00–17:00 as optimal targeting window, and discovering a 52.7x conversion improvement from minimal (0.33%) to optimal (17.37%) ad exposure. • Built a 2-page Power BI dashboard with 8 DAX measures and 16 visuals including a Day × Hour conversion heatmap.

---

## 🎯 Problem Statement

A marketing team ran an A/B test exposing 588,101 users to real ads (ad group) or public service announcements (PSA — control group) with no reporting layer to quantify campaign effectiveness, optimal timing, or exposure frequency impact on conversion rates.

---

## 🎯 Objectives

- Perform EDA to assess data quality and determine if Excel pre-processing is needed
- Import CSV directly to MySQL — skip index column, convert boolean to integer inline
- Execute 7 SQL queries quantifying A/B results, timing patterns, and exposure effects
- Create vw_ab_summary VIEW for Power BI performance optimisation
- Build 2-page dashboard with DAX measures, heatmap, and Sync Slicers
- Deliver actionable recommendations for ad timing and frequency targeting

---

## 📁 Dataset

| Attribute | Detail |
|-----------|--------|
| **Name** | Marketing A/B Testing Dataset |
| **Source** | [Kaggle — faviovaz/marketing-ab-testing](https://www.kaggle.com/datasets/faviovaz/marketing-ab-testing) |
| **Format** | CSV (.csv) |
| **Records** | 588,101 rows · 6 usable columns (Unnamed:0 index dropped at import) |
| **Null Values** | Zero ✅ |
| **Duplicates** | Zero ✅ |
| **Excel Used** | **NO** — EDA confirmed not required |

### EDA Summary — Why Excel Was Skipped

| Check | Result | Action |
|-------|--------|--------|
| Null values | 0 across all columns | ✅ No action needed |
| Duplicate rows | 0 | ✅ No action needed |
| Duplicate user IDs | 0 | ✅ No action needed |
| Date format issues | No date columns | ✅ No action needed |
| Currency formatting | None | ✅ No action needed |
| Boolean converted column | True/False text | ✅ Handled in LOAD DATA command |
| Unnamed index column | Present | ✅ Skipped in LOAD DATA command |
| **Conclusion** | **CSV → MySQL directly** | **Excel phase skipped** |

### Column Definitions

| Column | MySQL Type | Description |
|--------|-----------|-------------|
| user_id | INT PRIMARY KEY | Unique user identifier (588,101 distinct) |
| test_group | VARCHAR(3) | 'ad' = real ad (564,577 · 96%) · 'psa' = control (23,524 · 4%) |
| converted | TINYINT(1) | 1 = converted · 0 = not (imported from True/False boolean) |
| total_ads | INT | Ads shown per user (min:1 · max:2,065 · mean:24.82 · median:13) |
| most_ads_day | VARCHAR(10) | Day of week user saw the most ads |
| most_ads_hour | TINYINT | Hour 0–23 when user saw the most ads |

---

## 🛠️ Tools & Technologies

| Tool | Phase | Purpose |
|------|-------|---------|
| **MySQL 8.0** | Phase 1 | Database, LOAD DATA INFILE, 7 queries, 1 VIEW |
| **MySQL Workbench** | Phase 1 | Query execution and result verification |
| **Power BI Desktop** | Phase 2 | Live MySQL connection, DAX, 2-page dashboard |
| **DAX** | Phase 2 | 8 measures including CALCULATE for group filtering |
| **Sync Slicers** | Phase 2 | Cross-page filter synchronisation |

---

## ⚙️ PHASE 1 — MySQL

### Database & Table

```sql
CREATE DATABASE IF NOT EXISTS marketing_project;
USE marketing_project;

CREATE TABLE marketing_ab (
    user_id        INT PRIMARY KEY,
    test_group     VARCHAR(3),
    converted      TINYINT(1),
    total_ads      INT,
    most_ads_day   VARCHAR(10),
    most_ads_hour  TINYINT
);
```

### LOAD DATA LOCAL INFILE — Direct Import with Inline Transformations

```sql
LOAD DATA LOCAL INFILE 'C:/path/to/marketing_AB.csv'
INTO TABLE marketing_ab
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@skip, user_id, test_group, @conv, total_ads, most_ads_day, most_ads_hour)
SET converted = IF(@conv = 'True', 1, 0);

-- Result: 588,101 rows in 6.922 seconds · 0 warnings · 0 errors
```

> **@skip** → silently discards 'Unnamed: 0' index column
> **@conv + IF()** → converts 'True'/'False' text to TINYINT 1/0

### 7 Analytical Queries

```sql
-- Q1: Overall KPIs
SELECT COUNT(*) total_users, SUM(converted) total_conversions,
       ROUND(AVG(converted)*100,4) overall_conv_rate_pct,
       ROUND(AVG(total_ads),2) avg_ads_shown, MAX(total_ads) max_ads_shown
FROM marketing_ab;
-- 588,101 · 14,843 · 2.5239% · 24.82 avg · 2,065 max

-- Q2: A/B Group Comparison (Core Result)
SELECT test_group, COUNT(*) total_users, SUM(converted) conversions,
       ROUND(AVG(converted)*100,4) conversion_rate_pct,
       ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM marketing_ab),2) group_share_pct
FROM marketing_ab GROUP BY test_group;
-- ad: 564,577 users · 14,423 conv · 2.5547% · 96% share
-- psa: 23,524 users · 420 conv · 1.7854% · 4% share

-- Q3: Conversion Rate by Day
SELECT most_ads_day, COUNT(*) total_users, SUM(converted) conversions,
       ROUND(AVG(converted)*100,4) conv_rate_pct
FROM marketing_ab GROUP BY most_ads_day ORDER BY conv_rate_pct DESC;
-- Monday: 3.2812% · Tuesday: 2.9840% · Saturday: 2.1051% (worst)

-- Q4: Conversion Rate by Hour
SELECT most_ads_hour, COUNT(*) total_users, SUM(converted) conversions,
       ROUND(AVG(converted)*100,4) conv_rate_pct
FROM marketing_ab GROUP BY most_ads_hour ORDER BY most_ads_hour;
-- Hour 16: 3.0772% (best) · Hour 2: 0.7313% (worst)

-- Q5: Conversion by Ads Exposure Bucket
SELECT CASE
    WHEN total_ads BETWEEN 1 AND 10 THEN '01 — 1 to 10 ads'
    WHEN total_ads BETWEEN 11 AND 25 THEN '02 — 11 to 25 ads'
    WHEN total_ads BETWEEN 26 AND 50 THEN '03 — 26 to 50 ads'
    WHEN total_ads BETWEEN 51 AND 100 THEN '04 — 51 to 100 ads'
    WHEN total_ads BETWEEN 101 AND 200 THEN '05 — 101 to 200 ads'
    WHEN total_ads > 200 THEN '06 — 200+ ads'
END AS ads_bucket,
COUNT(*) total_users, SUM(converted) conversions,
ROUND(AVG(converted)*100,4) conv_rate_pct
FROM marketing_ab GROUP BY ads_bucket ORDER BY ads_bucket;

-- Q6: Best Day + Hour Combinations
SELECT most_ads_day, most_ads_hour, COUNT(*) total_users,
       SUM(converted) conversions, ROUND(AVG(converted)*100,4) conv_rate_pct
FROM marketing_ab GROUP BY most_ads_day, most_ads_hour
HAVING total_users >= 100 ORDER BY conv_rate_pct DESC LIMIT 15;
-- Saturday 06:00: 4.91% · Tuesday 16:00: 4.53% · Monday 14:00: 4.44%

-- Q7: Create Analytical VIEW
CREATE OR REPLACE VIEW vw_ab_summary AS
SELECT test_group, most_ads_day, most_ads_hour,
    CASE
        WHEN total_ads BETWEEN 1 AND 10 THEN '01-10 ads'
        WHEN total_ads BETWEEN 11 AND 25 THEN '11-25 ads'
        WHEN total_ads BETWEEN 26 AND 50 THEN '26-50 ads'
        WHEN total_ads BETWEEN 51 AND 100 THEN '51-100 ads'
        WHEN total_ads BETWEEN 101 AND 200 THEN '101-200 ads'
        WHEN total_ads > 200 THEN '200+ ads'
    END AS ads_bucket,
    COUNT(*) total_users, SUM(converted) conversions,
    ROUND(AVG(converted)*100,4) conv_rate_pct,
    ROUND(AVG(total_ads),2) avg_ads
FROM marketing_ab
GROUP BY test_group, most_ads_day, most_ads_hour, ads_bucket;
```

---

## 📐 DAX Measures (Power BI)

```dax
Total Users = COUNTROWS(marketing_ab)
-- 588,101

Total Conversions = SUM(marketing_ab[converted])
-- 14,843

Conversion Rate = DIVIDE([Total Conversions], [Total Users]) * 100
-- 2.5239%

Ad Group Users = CALCULATE([Total Users], marketing_ab[test_group] = "ad")
-- 564,577 (96%)

PSA Group Users = CALCULATE([Total Users], marketing_ab[test_group] = "psa")
-- 23,524 (4%)

Ad Conversion Rate = CALCULATE([Conversion Rate], marketing_ab[test_group] = "ad")
-- 2.5547%

PSA Conversion Rate = CALCULATE([Conversion Rate], marketing_ab[test_group] = "psa")
-- 1.7854%

Conversion Lift % = DIVIDE([Ad Conversion Rate] - [PSA Conversion Rate],
                            [PSA Conversion Rate]) * 100
-- 43.09%
```

---

## 📊 2-Page Dashboard (16 Visuals)

### Page 1 — Campaign Overview
| # | Visual | Fields | Value |
|---|--------|--------|-------|
| 1 | KPI Card | Total Users | 588,101 |
| 2 | KPI Card | Total Conversions | 14,843 |
| 3 | KPI Card | Conversion Rate | 2.52% |
| 4 | KPI Card | Conversion Lift % | 43.09% |
| 5 | KPI Card | Ad Conversion Rate | 2.55% |
| 6 | KPI Card | PSA Conversion Rate | 1.79% |
| 7 | Clustered Bar | test_group → Conversion Rate | ad vs psa visual gap |
| 8 | Donut Chart | test_group → Total Users | 96% ad / 4% psa |
| 9 | Slicer | test_group (Dropdown) | Synced to Page 2 |
| 10 | Slicer | most_ads_day (Dropdown) | Synced to Page 2 |

### Page 2 — Timing & Exposure Analysis
| # | Visual | Fields | Value |
|---|--------|--------|-------|
| 11 | Clustered Bar | most_ads_day → Conv Rate | Monday 3.28% → Saturday 2.11% |
| 12 | Line Chart | most_ads_hour → Conv Rate | Peak 14:00–17:00 visible |
| 13 | Clustered Bar | ads_bucket → Conv Rate | 0.33% → 17.37% rising trend |
| 14 | Matrix (Heatmap) | Day × Hour → Conv Rate | Best: Tue 16:00, Mon 14:00 |
| 15 | Slicer | most_ads_hour (Between) | 0–23 range slider |
| 16 | Slicer | test_group (Synced) | From Page 1 |

---

## 📈 Key Insights & Results

### Core A/B Test Result
- **Ad campaign delivered 43.09% conversion lift** over PSA control
- Ad group: **2.5547%** conversion (14,423 / 564,577 users)
- PSA group: **1.7854%** conversion (420 / 23,524 users)
- Absolute difference: **+0.77 percentage points**
- Both groups had nearly identical avg ads shown (24.82 vs 24.76) — lift is purely from ad creative

### Conversion by Day of Week
| Day | Users | Conversions | Conv Rate |
|-----|-------|-------------|-----------|
| **Monday** | 87,073 | 2,857 | **3.2812%** ← Best |
| Tuesday | 77,479 | 2,312 | 2.9840% |
| Wednesday | 80,908 | 2,018 | 2.4942% |
| Sunday | 85,391 | 2,090 | 2.4476% |
| Friday | 92,608 | 2,057 | 2.2212% |
| Thursday | 82,982 | 1,790 | 2.1571% |
| **Saturday** | 81,660 | 1,719 | **2.1051%** ← Worst |

### Conversion by Hour (Key Hours)
| Hour | Users | Conv Rate | Label |
|------|-------|-----------|-------|
| **16** | 37,567 | **3.0772%** | Best hour |
| 15 | 44,683 | 2.9653% | Prime window |
| 20 | 28,923 | 2.9803% | Evening peak |
| 14 | 45,648 | 2.8063% | Afternoon start |
| **2** | 5,333 | **0.7313%** | Worst hour |

### Conversion by Ads Exposure
| Bucket | Users | Conversions | Conv Rate |
|--------|-------|-------------|-----------|
| 1-10 ads | 260,775 | 858 | 0.33% |
| 11-25 ads | 169,247 | 1,720 | 1.02% |
| 26-50 ads | 89,013 | 3,124 | 3.51% |
| 51-100 ads | 46,002 | 5,242 | 11.40% |
| **101-200 ads** | 17,112 | 2,972 | **17.37%** ← Peak |
| 200+ ads | 5,952 | 927 | 15.57% |

> **52.7x conversion improvement** from minimum to optimal exposure

### Best Day + Hour Combinations
| Day | Hour | Users | Conv Rate |
|-----|------|-------|-----------|
| Saturday | 06:00 | 265 | 4.91% |
| **Tuesday** | **16:00** | **4,262** | **4.53%** ← Best volume |
| Monday | 14:00 | 6,335 | 4.44% |
| Sunday | 20:00 | 3,892 | 4.32% |
| Monday | 15:00 | 6,684 | 4.25% |

---

## 📊 KPI Summary

| KPI | Value | KPI | Value |
|-----|-------|-----|-------|
| Total Users | **588,101** | Conversion Lift | **43.09%** |
| Total Conversions | **14,843** | Ad Conv Rate | **2.5547%** |
| Overall Conv Rate | **2.5239%** | PSA Conv Rate | **1.7854%** |
| Ad Group Users | 564,577 (96%) | PSA Group Users | 23,524 (4%) |
| Best Day | Monday 3.28% | Worst Day | Saturday 2.11% |
| Best Hour | Hour 16 — 3.08% | Worst Hour | Hour 2 — 0.73% |
| Best Day+Hour | Tuesday 16:00 — 4.53% | Best Exposure | 101-200 ads — 17.37% |
| Exposure Lift | **52.7x** (low → optimal) | Max Ads Shown | 2,065 |

---

## ⚡ Challenges & Solutions

**Challenge 1 — Determining Excel Necessity**
Systematic EDA before any instruction — 0 nulls, 0 duplicates, no formatting issues confirmed Excel unnecessary. Saved the entire Phase 1 Excel workflow.

**Challenge 2 — Unnamed:0 Index Column**
Used @skip variable in LOAD DATA column list to silently discard without preprocessing.

**Challenge 3 — Boolean True/False vs MySQL TINYINT**
Used @conv + SET converted = IF(@conv='True',1,0) in LOAD DATA command — zero post-import updates needed.

**Challenge 4 — DAX CALCULATE for Group Filtering**
CALCULATE([Conversion Rate], test_group="ad") overrides filter context to compute group-specific rates that respond correctly to all slicers.

**Challenge 5 — Alphabetical Bucket Sorting**
Prefixed CASE labels with sort keys ('01 —', '02 —') so alphabetical = numerical order in Power BI visuals.

---

## 🎓 Skills Learned

- **EDA-First Methodology** — Tool selection based on data evidence, not assumption
- **Advanced LOAD DATA INFILE** — @variable placeholders for column skipping and inline transformation
- **A/B Test Analysis** — Absolute vs relative lift; statistical interpretation
- **DAX CALCULATE** — Context modification for group-filtered measures
- **SQL Prefix Sorting** — Numbered bucket labels for correct visual sort order
- **Matrix Heatmap** — Day × Hour conversion analysis with conditional background color
- **Exposure Frequency Analysis** — Dose-response curve; frequency capping recommendations

---

## 🎨 Custom Theme

`Digital_Marketing_Purple_Theme.json` — Apply via **View → Themes → Browse for themes**

| Element | Color | Meaning |
|---------|-------|---------|
| Canvas | `#0F0F23` — Deep Dark | Modern digital analytics |
| Visuals | `#1A1A35` — Dark Purple | Premium dark panels |
| KPI Borders | `#7C3AED` — Vivid Purple | Brand identity |
| KPI Numbers | `#A78BFA` — Light Purple | High readability |
| Data Color 1 | `#7C3AED` — Purple | Primary series |
| Data Color 2 | `#06B6D4` — Cyan | Contrast accent |
| Data Color 3 | `#10B981` — Green | Positive/conversion |

---

## 📂 Repository Structure

```
marketing-ab-testing-dashboard/
│
├── 📊 Marketing_AB_Testing_Dashboard.pbix
├── 📁 Dataset/
│   └── marketing_AB.csv                      # Raw source (Kaggle)
├── 📁 MySQL/
│   ├── create_table.sql
│   ├── load_data.sql
│   └── analytical_queries.sql
├── 📁 Theme/
│   └── Digital_Marketing_Purple_Theme.json
├── 📄 Marketing_AB_Testing_Portfolio_Documentation.pdf
└── 📄 README.md
```

---

---

*Data Analytics Portfolio · Project 5 of 9 · Intermediate · Tools: MySQL + Power BI · Dataset: Kaggle*
