--1. CREATE TABLE TO IMPORT RAW DATA
CREATE TABLE creatives_raw (
  creative_id VARCHAR(50),
  install_date DATE,
  impressions INT,
  clicks INT,
  installs INT,
  cost FLOAT,
  count_payer_day0 INT,
  revenue_day0 FLOAT
);


--2. CREATE NEW TABLE FOR ANALYSIS WITH PARSING AND METRICS
CREATE TABLE creative_analysis AS
SELECT *,
--parsing the creative_id to categories
  SUBSTRING(clean_id FROM 'V(\d+_\d+)') AS creative_number,
  SUBSTRING(clean_id FROM '_IC_(\d+_\d+)') AS base_creative_number,
  CASE WHEN clean_id LIKE '%_IC_%' THEN 1 ELSE 0 END AS is_iteration,
  SUBSTRING(clean_id FROM 'm(\d+)')::INT AS music,
  SUBSTRING(clean_id FROM 'c(\d+)')::INT AS concept,
  SUBSTRING(clean_id FROM 'z(\d+)')::INT AS policy,
  SUBSTRING(clean_id FROM '_(S|M|L)_') AS length,
  SUBSTRING(clean_id FROM 'sr(\d+)')::INT AS series,
  -- metrics (%)
  ROUND((clicks * 100.0 / NULLIF(impressions, 0))::numeric, 2) AS CTR,
  ROUND((installs * 100.0 / NULLIF(clicks, 0))::numeric, 2) AS CR,
  ROUND((count_payer_day0 * 100.0 / NULLIF(installs, 0))::numeric, 2) AS payer_rate,
  -- metrics (absolute)
  ROUND((cost / NULLIF(installs, 0))::numeric, 3) AS CPI,
  ROUND((revenue_day0 / NULLIF(cost, 0))::numeric, 3) AS ROAS_day0
  --replacing cyrillic "c" to get correct results
FROM (
  SELECT *, REPLACE(creative_id, 'с', 'c') AS clean_id
  FROM creatives_raw
) creatives_cyrillic_c_replace
WHERE impressions > 0 AND cost > 0 AND clicks > 0 AND installs > 0;

-- 3. CREATE TABLE COMPARING ITERATION TO THE BASE
CREATE TABLE creative_comparison AS
SELECT
  i.clean_id AS iteration_id,
  i.creative_number AS iteration_number,
  i.base_creative_number,
  b.clean_id AS base_id,
  b.creative_number AS base_number,

  -- Metrics from the iteration
  i.CTR AS iteration_CTR,
  i.CR AS iteration_CR,
  i.payer_rate AS iteration_payer_rate,
  i.CPI AS iteration_CPI,
  i.ROAS_day0 AS iteration_ROAS_day0,

  -- Metrics from the base creative
  b.CTR AS base_CTR,
  b.CR AS base_CR,
  b.payer_rate AS base_payer_rate,
  b.CPI AS base_CPI,
  b.ROAS_day0 AS base_ROAS_day0,

  -- Differences between iteration and base (deltas)
  ROUND(i.CTR - b.CTR, 2) AS delta_CTR,
  ROUND(i.CR - b.CR, 2) AS delta_CR,
  ROUND(i.payer_rate - b.payer_rate, 2) AS delta_payer_rate,
  ROUND(i.CPI - b.CPI, 3) AS delta_CPI,
  ROUND(i.ROAS_day0 - b.ROAS_day0, 3) AS delta_ROAS_day0,

  -- Iteration attributes for further analysis
  i.music,
  i.concept,
  i.policy,
  i.length,
  i.series

FROM creative_analysis i
JOIN creative_analysis b
  ON i.base_creative_number = b.creative_number
WHERE i.is_iteration = 1;

-- 4. MUSIC ANALYSIS
SELECT
  music,
  COUNT(*) AS total_iterations,
  SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) AS improved_count,
  ROUND(AVG(delta_ROAS_day0), 3) AS avg_delta_roas,
  ROUND(100.0 * SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS improvement_rate
FROM creative_comparison
GROUP BY music
ORDER BY avg_delta_roas DESC;

-- 5. CONCEPT ANALYSIS
SELECT
  concept,
  COUNT(*) AS total_iterations,
  SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) AS improved_count,
  ROUND(AVG(delta_ROAS_day0), 3) AS avg_delta_roas,
  ROUND(100.0 * SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS improvement_rate
FROM creative_comparison
GROUP BY concept
ORDER BY avg_delta_roas DESC;

-- 6. POLICY ANALYSIS
SELECT
  policy,
  COUNT(*) AS total_iterations,
  SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) AS improved_count,
  ROUND(AVG(delta_ROAS_day0), 3) AS avg_delta_roas,
  ROUND(100.0 * SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS improvement_rate
FROM creative_comparison
GROUP BY policy
ORDER BY avg_delta_roas DESC;

-- 6. LENGTH ANALYSIS
SELECT
  length,
  COUNT(*) AS total_iterations,
  SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) AS improved_count,
  ROUND(AVG(delta_ROAS_day0), 3) AS avg_delta_roas,
  ROUND(100.0 * SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS improvement_rate
FROM creative_comparison
GROUP BY length
ORDER BY avg_delta_roas DESC;

-- 6. SERIES ANALYSIS
SELECT
  series,
  COUNT(*) AS total_iterations,
  SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) AS improved_count,
  ROUND(AVG(delta_ROAS_day0), 3) AS avg_delta_roas,
  ROUND(100.0 * SUM(CASE WHEN delta_ROAS_day0 > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS improvement_rate
FROM creative_comparison
GROUP BY series
ORDER BY avg_delta_roas DESC;



