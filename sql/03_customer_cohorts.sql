-- ============================================================
-- FILE: 03_customer_cohorts.sql
-- PURPOSE: Customer cohort retention analysis
-- ANALYST: Utsav Khadka
-- PROJECT: E-Commerce Revenue & Customer Lifecycle Analytics
--
-- BUSINESS CONTEXT:
-- Answers: "Are we retaining customers over time?"
-- Groups customers by first purchase month (cohort) and
-- tracks what % return each subsequent month.
--
-- NEW SQL CONCEPTS:
--   Chained CTEs      → 4 steps building on each other
--   MIN() GROUP BY    → find first purchase per customer
--   DATEDIFF()        → calculate months between dates
--   COUNT(DISTINCT)   → count unique returning customers
--
-- HOW TO RUN: Execute via notebooks/02_sql_analysis.ipynb
-- ============================================================


-- ============================================================
-- QUERY 1: CUSTOMER COHORT RETENTION RATE
-- Core cohort analysis — retention % by cohort by month
-- ============================================================
WITH cohort_base AS (
    -- Step 1: Find each customer's first purchase month
    -- This defines which cohort they belong to
    SELECT
        CustomerID,
        MIN(YearMonth)                          AS cohort_month
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
customer_activity AS (
    -- Step 2: Join every transaction back to the cohort base
    -- Tag each transaction with the customer's cohort month
    -- and calculate how many months after first purchase it is
    SELECT
        t.CustomerID,
        t.YearMonth                             AS transaction_month,
        c.cohort_month,

        -- How many months after first purchase is this transaction?
        -- Example: first bought Jan 2011, this transaction Apr 2011 = index 3
        (YEAR(STRPTIME(t.YearMonth, '%Y-%m')) * 12 +
         MONTH(STRPTIME(t.YearMonth, '%Y-%m')))
        -
        (YEAR(STRPTIME(c.cohort_month, '%Y-%m')) * 12 +
         MONTH(STRPTIME(c.cohort_month, '%Y-%m')))
                                                AS cohort_index

    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv') t
    INNER JOIN cohort_base c
        ON t.CustomerID = c.CustomerID
    WHERE t.is_cancelled = false
      AND t.CustomerID IS NOT NULL
),
cohort_size AS (
    -- Step 3: Count how many customers are in each cohort
    -- This is our denominator for retention rate calculation
    SELECT
        cohort_month,
        COUNT(DISTINCT CustomerID)              AS cohort_customers
    FROM cohort_base
    GROUP BY cohort_month
),
retention_data AS (
    -- Step 4: Count active customers per cohort per month index
    SELECT
        a.cohort_month,
        a.cohort_index,
        COUNT(DISTINCT a.CustomerID)            AS active_customers
    FROM customer_activity a
    GROUP BY a.cohort_month, a.cohort_index
)
-- Final: Calculate retention percentage
-- Active customers in month N / Total cohort size × 100
SELECT
    r.cohort_month,
    r.cohort_index,
    s.cohort_customers                          AS cohort_size,
    r.active_customers,
    ROUND(
        r.active_customers * 100.0 / s.cohort_customers,
        1
    )                                           AS retention_pct

FROM retention_data r
INNER JOIN cohort_size s
    ON r.cohort_month = s.cohort_month
ORDER BY r.cohort_month, r.cohort_index;


-- ============================================================
-- QUERY 2: COHORT SIZE SUMMARY
-- How many customers were acquired each month?
-- Declining cohort sizes = acquisition problem
-- ============================================================
WITH cohort_base AS (
    SELECT
        CustomerID,
        MIN(YearMonth)                          AS cohort_month
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    cohort_month,
    COUNT(DISTINCT CustomerID)                  AS new_customers,

    -- Running total of all customers acquired so far
    SUM(COUNT(DISTINCT CustomerID)) OVER (
        ORDER BY cohort_month
    )                                           AS cumulative_customers

FROM cohort_base
GROUP BY cohort_month
ORDER BY cohort_month;


-- ============================================================
-- QUERY 3: AVERAGE RETENTION BY COHORT INDEX
-- Across all cohorts — what is the average retention
-- at Month 1, Month 2, Month 3 etc?
-- This gives a single retention curve for the business.
-- ============================================================
WITH cohort_base AS (
    SELECT
        CustomerID,
        MIN(YearMonth) AS cohort_month
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
customer_activity AS (
    SELECT
        t.CustomerID,
        c.cohort_month,
        (YEAR(STRPTIME(t.YearMonth, '%Y-%m')) * 12 +
         MONTH(STRPTIME(t.YearMonth, '%Y-%m')))
        -
        (YEAR(STRPTIME(c.cohort_month, '%Y-%m')) * 12 +
         MONTH(STRPTIME(c.cohort_month, '%Y-%m'))) AS cohort_index
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv') t
    INNER JOIN cohort_base c ON t.CustomerID = c.CustomerID
    WHERE t.is_cancelled = false
      AND t.CustomerID IS NOT NULL
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT CustomerID) AS cohort_customers
    FROM cohort_base
    GROUP BY cohort_month
),
retention_data AS (
    SELECT
        a.cohort_month,
        a.cohort_index,
        COUNT(DISTINCT a.CustomerID) AS active_customers
    FROM customer_activity a
    GROUP BY a.cohort_month, a.cohort_index
),
retention_pct AS (
    SELECT
        r.cohort_index,
        ROUND(r.active_customers * 100.0 / s.cohort_customers, 1) AS retention_pct
    FROM retention_data r
    INNER JOIN cohort_size s ON r.cohort_month = s.cohort_month
)
SELECT
    cohort_index                                AS months_after_first_purchase,
    ROUND(AVG(retention_pct), 1)                AS avg_retention_pct,
    ROUND(MIN(retention_pct), 1)                AS min_retention_pct,
    ROUND(MAX(retention_pct), 1)                AS max_retention_pct
FROM retention_pct
GROUP BY cohort_index
ORDER BY cohort_index;


-- ============================================================
-- QUERY 4: COHORT REVENUE TRACKING
-- How much revenue does each cohort generate over time?
-- High revenue in later months = loyal, high-value customers
-- ============================================================
WITH cohort_base AS (
    SELECT
        CustomerID,
        MIN(YearMonth) AS cohort_month
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    c.cohort_month,
    (YEAR(STRPTIME(t.YearMonth, '%Y-%m')) * 12 +
     MONTH(STRPTIME(t.YearMonth, '%Y-%m')))
    -
    (YEAR(STRPTIME(c.cohort_month, '%Y-%m')) * 12 +
     MONTH(STRPTIME(c.cohort_month, '%Y-%m')))  AS cohort_index,
    COUNT(DISTINCT t.CustomerID)                AS active_customers,
    ROUND(SUM(t.Revenue), 2)                    AS cohort_revenue,
    ROUND(AVG(t.Revenue), 2)                    AS avg_revenue_per_transaction

FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv') t
INNER JOIN cohort_base c
    ON t.CustomerID = c.CustomerID
WHERE t.is_cancelled = false
  AND t.CustomerID IS NOT NULL
GROUP BY c.cohort_month, cohort_index
ORDER BY c.cohort_month, cohort_index;
