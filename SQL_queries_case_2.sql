--1. CREATE TABLE TO IMPORT RAW DATA
CREATE TABLE traffic_data (
  install_date DATE,
  country VARCHAR(50),
  media_source VARCHAR(50),
  installs INTEGER,
  payers_day1 INTEGER,
  revenue_day1 FLOAT,
  cost FLOAT
);

-- 2. CALCULATE GROSS PROFIT PER MEDIA SOURCE
SELECT 
  media_source,
  -- total installs and cost
  SUM(installs) AS total_installs,
  SUM(cost) AS total_cost,
  -- revenue for day 1 and year
  SUM(revenue_day1) AS total_revenue_day1,
  ROUND(SUM(revenue_day1)::numeric * 6, 2) AS total_revenue_year,
  -- gross profit
  ROUND(SUM(revenue_day1)::numeric * 6 - SUM(cost)::numeric, 2) AS gross_profit_year
FROM traffic_data
GROUP BY media_source
ORDER BY gross_profit_year DESC;

-- 3. CALCULATE CHANGES TO media_source_4
SELECT 
  'media_source_4' AS media_source,
  -- new cost after 50% reduction
  ROUND(SUM(cost)::numeric * 0.5, 2) AS new_cost,
  -- new revenue +20%
  ROUND(SUM(revenue_day1)::numeric * 1.2 * 6, 2) AS new_revenue_year,
  -- new gross profit
  ROUND(SUM(revenue_day1)::numeric * 1.2 * 6 - SUM(cost)::numeric * 0.5, 2) AS new_gross_profit_year
FROM traffic_data
WHERE media_source = 'media_source_4';

-- 4. COMPARISON OF media_source_4 BEFORE AND AFTER OPTIMIZATION
-- combining two previous queries and filering by media_source_4 
-- original values of media_source_4 
SELECT 
  'Before Optimization' AS opt,
  SUM(installs) AS installs,
  SUM(cost) AS cost,
  SUM(revenue_day1) AS revenue_day1,
  ROUND(SUM(revenue_day1)::numeric * 6, 2) AS revenue_year,
  ROUND(SUM(revenue_day1)::numeric * 6 - SUM(cost)::numeric, 2) AS gross_profit
FROM traffic_data
WHERE media_source = 'media_source_4'

UNION ALL
-- new values of media_source_4 
SELECT 
  'After Optimization' AS opt,
  ROUND(SUM(installs) * 0.5) AS installs,                 
  ROUND(SUM(cost)::numeric * 0.5, 2) AS cost,                       
  ROUND(SUM(revenue_day1)::numeric * 1.2, 2) AS revenue_day1,         
  ROUND(SUM(revenue_day1)::numeric * 1.2 * 6, 2) AS revenue_year,     
  ROUND(SUM(revenue_day1)::numeric * 1.2 * 6 - SUM(cost)::numeric * 0.5, 2) AS gross_profit
FROM traffic_data
WHERE media_source = 'media_source_4';

-- 5. ALL SOURCES BEFORE AND AFTER OPTIMIZATION (CHANGES ONLY IN media_source_4 TO COMPARE WITH OTHER SOURCES)
-- original values of all sources
SELECT 
  media_source,
  SUM(installs) AS total_installs,
  SUM(cost) AS original_cost,
  SUM(revenue_day1) AS original_day1_revenue,
  ROUND(SUM(revenue_day1)::numeric * 6, 2) AS original_year_revenue,
  ROUND(SUM(revenue_day1)::numeric * 6 - SUM(cost)::numeric, 2) AS original_gross_profit,
  -- filtering sources to calculate new values for edia_source_4
  CASE 
    WHEN media_source = 'media_source_4' THEN ROUND(SUM(cost)::numeric * 0.5, 2)
    ELSE SUM(cost)
  END AS adjusted_cost,
  CASE 
    WHEN media_source = 'media_source_4' THEN ROUND(SUM(revenue_day1)::numeric * 1.2, 2)
    ELSE SUM(revenue_day1)
  END AS adjusted_day1_revenue,
  CASE 
    WHEN media_source = 'media_source_4' THEN ROUND(SUM(revenue_day1)::numeric * 1.2 * 6, 2)
    ELSE ROUND(SUM(revenue_day1)::numeric * 6, 2)
  END AS adjusted_year_revenue,
  CASE 
    WHEN media_source = 'media_source_4' THEN ROUND(SUM(revenue_day1)::numeric * 1.2 * 6 - SUM(cost)::numeric * 0.5, 2)
    ELSE ROUND(SUM(revenue_day1)::numeric * 6 - SUM(cost)::numeric, 2)
  END AS adjusted_gross_profit
FROM traffic_data
GROUP BY media_source
ORDER BY adjusted_gross_profit DESC;
