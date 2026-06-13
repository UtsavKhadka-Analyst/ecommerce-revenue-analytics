-- ============================================================
-- FILE: 05_product_geo_analysis.sql
-- PURPOSE: Product performance deep dive and geographic
--          customer behavior analysis
-- ANALYST: Utsav Khadka
-- PROJECT: E-Commerce Revenue & Customer Lifecycle Analytics
--
-- BUSINESS CONTEXT:
-- Files 1-4 answered "are we growing, are we retaining
-- customers, who are our best customers." File 5 answers the
-- operational question: "which products and which countries
-- should we focus on, and which should we reconsider?"
--
-- DEFERRED DECISION (from File 1 / CLAUDE.md Section 9):
-- File 1 found DOT, POST, M ranking in the "top products" by
-- revenue. These are shipping/admin charges, not real
-- products (DOT = Dotcom Postage, POST = Postage,
-- M = Manual adjustment). Query 1 below FINDS all such codes
-- with evidence; Queries 2-3 then EXCLUDE them so product
-- rankings reflect actual merchandise only.
--
-- NEW SQL CONCEPTS:
--   regexp_matches()        → pattern-match StockCode to tell
--                              real product codes (start with
--                              a digit) from fee/admin codes
--                              (start with a letter)
--   SUM(CASE WHEN ...)       → conditional aggregation — split
--                              one column's totals into two
--                              time periods, side by side
--   UNION ALL                → stack "Top 10" and "Bottom 10"
--                              results into one labeled table
--
-- HOW TO RUN: Execute via notebooks/02_sql_analysis.ipynb
-- ============================================================


-- ============================================================
-- QUERY 1: IDENTIFY NON-PRODUCT STOCK CODES
-- Real product codes in this dataset start with a digit
-- (e.g. 85123A, 71053). Find every StockCode that DOESN'T
-- start with a digit, and how much revenue it represents.
-- This is the evidence base for the filter used in Query 2/3.
-- ============================================================
SELECT
    StockCode,
    Description,
    COUNT(*)                                    AS transaction_count,
    ROUND(SUM(Revenue), 2)                      AS total_revenue

FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
WHERE is_cancelled = false
  AND NOT regexp_matches(StockCode, '^[0-9]')
GROUP BY StockCode, Description
ORDER BY total_revenue DESC;


-- ============================================================
-- QUERY 2: TOP 10 AND BOTTOM 10 PRODUCTS BY REVENUE
-- Now that fee/admin codes are identified, exclude them and
-- rank only real merchandise. UNION ALL stacks the "Top 10"
-- and "Bottom 10" into one labeled result set.
-- ============================================================
WITH real_products AS (
    -- Step 1: Aggregate revenue per real product (digit-prefixed codes only)
    SELECT
        StockCode,
        Description,
        SUM(Quantity)                           AS total_units_sold,
        ROUND(SUM(Revenue), 2)                  AS total_revenue,
        ROUND(AVG(UnitPrice), 2)                AS avg_unit_price
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND regexp_matches(StockCode, '^[0-9]')
      AND Description IS NOT NULL
    GROUP BY StockCode, Description
),
ranked AS (
    -- Step 2: Rank from both directions (highest and lowest revenue)
    SELECT
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS rank_top,
        RANK() OVER (ORDER BY total_revenue ASC)  AS rank_bottom
    FROM real_products
)
-- Step 3: Combine top 10 and bottom 10 into one table
SELECT
    'Top 10'                                    AS category,
    StockCode,
    Description,
    total_units_sold,
    total_revenue,
    avg_unit_price
FROM ranked
WHERE rank_top <= 10

UNION ALL

SELECT
    'Bottom 10'                                 AS category,
    StockCode,
    Description,
    total_units_sold,
    total_revenue,
    avg_unit_price
FROM ranked
WHERE rank_bottom <= 10

ORDER BY category, total_revenue DESC;


-- ============================================================
-- QUERY 3: PRODUCT GROWTH — FIRST HALF VS SECOND HALF OF 2011
-- Compares each product's revenue in H1 2011 (Jan-Jun) vs
-- H2 2011 (Jul-Dec) to find growing vs declining products.
-- Only considers products with meaningful total revenue
-- (>£1,000) to avoid noise from one-off small items.
--
-- NOTE: Products with h1_revenue = 0 are excluded. These are
-- products that didn't exist/sell at all in H1 (new launches
-- or seasonal items), so "% change vs H1" is undefined for
-- them (division by zero) — they are a different question
-- ("new products"), not "declining products".
-- ============================================================
WITH product_period_revenue AS (
    SELECT
        StockCode,
        Description,

        -- Revenue earned Jan-Jun 2011 only
        SUM(
            CASE WHEN YearMonth BETWEEN '2011-01' AND '2011-06'
                 THEN Revenue ELSE 0 END
        )                                        AS h1_revenue,

        -- Revenue earned Jul-Dec 2011 only
        SUM(
            CASE WHEN YearMonth BETWEEN '2011-07' AND '2011-12'
                 THEN Revenue ELSE 0 END
        )                                        AS h2_revenue,

        ROUND(SUM(Revenue), 2)                   AS total_revenue

    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND regexp_matches(StockCode, '^[0-9]')
      AND Description IS NOT NULL
    GROUP BY StockCode, Description
)
SELECT
    StockCode,
    Description,
    ROUND(h1_revenue, 2)                         AS h1_revenue,
    ROUND(h2_revenue, 2)                         AS h2_revenue,
    ROUND(h2_revenue - h1_revenue, 2)            AS revenue_change,

    -- % change from H1 to H2. NULLIF avoids divide-by-zero
    -- for products with no H1 revenue.
    ROUND(
        (h2_revenue - h1_revenue) * 100.0 / NULLIF(h1_revenue, 0),
        1
    )                                            AS pct_change

FROM product_period_revenue
WHERE total_revenue > 1000
  AND h1_revenue > 0
ORDER BY pct_change DESC;


-- ============================================================
-- QUERY 4: GEOGRAPHIC DEEP DIVE — COUNTRY-LEVEL METRICS
-- For the top 10 countries by revenue: how many customers,
-- what's the AOV, and what % of customers come back for a
-- second order (repeat rate)? UK vs non-UK behavior often
-- looks very different in wholesale datasets.
-- ============================================================
WITH customer_country AS (
    -- Step 1: Per-customer totals, tagged with their country
    SELECT
        CustomerID,
        Country,
        COUNT(DISTINCT InvoiceNo)                AS customer_orders,
        SUM(Revenue)                             AS customer_revenue
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID, Country
)
SELECT
    Country,
    COUNT(DISTINCT CustomerID)                   AS total_customers,
    SUM(customer_orders)                         AS total_orders,
    ROUND(SUM(customer_revenue), 2)              AS total_revenue,

    -- Average order value = total revenue / total orders
    ROUND(SUM(customer_revenue) / SUM(customer_orders), 2) AS aov,

    -- Average revenue per customer
    ROUND(SUM(customer_revenue) / COUNT(DISTINCT CustomerID), 2) AS revenue_per_customer,

    -- % of customers who placed more than 1 order
    ROUND(
        100.0 * SUM(CASE WHEN customer_orders > 1 THEN 1 ELSE 0 END)
        / COUNT(DISTINCT CustomerID),
        1
    )                                            AS repeat_customer_pct

FROM customer_country
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;
