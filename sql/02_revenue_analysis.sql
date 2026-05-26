-- ============================================================
-- FILE: 02_revenue_analysis.sql
-- PURPOSE: Revenue trends, MoM growth, running totals,
--          moving averages, and AOV analysis
-- ANALYST: Utsav Khadka
-- PROJECT: E-Commerce Revenue & Customer Lifecycle Analytics
--
-- BUSINESS CONTEXT:
-- The VP says "revenue looks flat." This file proves or
-- disproves that claim with month-over-month data.
--
-- NEW SQL CONCEPTS:
--   LAG()     → compare current vs previous period
--   SUM OVER  → running totals
--   AVG OVER  → moving averages
--   ROWS BETWEEN → define window frame
--
-- HOW TO RUN: Execute via notebooks/02_sql_analysis.ipynb
-- ============================================================


-- ============================================================
-- QUERY 1: MONTHLY REVENUE WITH MOM GROWTH
-- Is revenue growing or declining each month?
-- LAG() looks back 1 row to get last month's revenue
-- ============================================================
WITH monthly_revenue AS (
    -- Step 1: Calculate total revenue per month
    SELECT
        YearMonth,
        COUNT(DISTINCT InvoiceNo)               AS total_orders,
        COUNT(DISTINCT CustomerID)              AS active_customers,
        ROUND(SUM(Revenue), 2)                  AS monthly_revenue
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY YearMonth
),
mom_growth AS (
    -- Step 2: Use LAG() to get previous month revenue
    -- LAG(column, 1) = look back 1 row
    SELECT
        YearMonth,
        total_orders,
        active_customers,
        monthly_revenue,

        -- Get last month's revenue by looking back 1 row
        LAG(monthly_revenue, 1) OVER (
            ORDER BY YearMonth
        )                                       AS prev_month_revenue,

        -- Calculate MoM growth amount
        monthly_revenue - LAG(monthly_revenue, 1) OVER (
            ORDER BY YearMonth
        )                                       AS mom_change,

        -- Calculate MoM growth percentage
        ROUND(
            (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY YearMonth))
            * 100.0
            / LAG(monthly_revenue, 1) OVER (ORDER BY YearMonth),
            2
        )                                       AS mom_growth_pct
    FROM monthly_revenue
)
-- Step 3: Final output with running total
SELECT
    YearMonth,
    total_orders,
    active_customers,
    monthly_revenue,
    prev_month_revenue,
    mom_change,
    mom_growth_pct,

    -- Running total: cumulates revenue month by month
    ROUND(
        SUM(monthly_revenue) OVER (
            ORDER BY YearMonth
        ), 2
    )                                           AS running_total_revenue

FROM mom_growth
ORDER BY YearMonth;


-- ============================================================
-- QUERY 2: 3-MONTH MOVING AVERAGE
-- Smooths out seasonal spikes to reveal the true revenue trend
-- ROWS BETWEEN 2 PRECEDING AND CURRENT ROW = last 3 months
-- ============================================================
WITH monthly_revenue AS (
    SELECT
        YearMonth,
        ROUND(SUM(Revenue), 2)                  AS monthly_revenue
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY YearMonth
)
SELECT
    YearMonth,
    monthly_revenue,

    -- 3-month moving average
    -- ROWS BETWEEN 2 PRECEDING AND CURRENT ROW means:
    -- include current month + 2 months before it
    ROUND(
        AVG(monthly_revenue) OVER (
            ORDER BY YearMonth
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    )                                           AS moving_avg_3month,

    -- Also show difference: actual vs moving average
    -- Positive = above trend, Negative = below trend
    ROUND(
        monthly_revenue - AVG(monthly_revenue) OVER (
            ORDER BY YearMonth
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    )                                           AS variance_from_trend

FROM monthly_revenue
ORDER BY YearMonth;


-- ============================================================
-- QUERY 3: AVERAGE ORDER VALUE (AOV) TREND
-- Is the average order getting larger or smaller over time?
-- Declining AOV = customers spending less per visit
-- ============================================================
WITH order_totals AS (
    -- Step 1: Revenue per unique order
    SELECT
        YearMonth,
        InvoiceNo,
        SUM(Revenue)                            AS order_value
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY YearMonth, InvoiceNo
)
SELECT
    YearMonth,
    COUNT(InvoiceNo)                            AS total_orders,
    ROUND(SUM(order_value), 2)                  AS monthly_revenue,
    ROUND(AVG(order_value), 2)                  AS avg_order_value,
    ROUND(MIN(order_value), 2)                  AS min_order_value,
    ROUND(MAX(order_value), 2)                  AS max_order_value

FROM order_totals
GROUP BY YearMonth
ORDER BY YearMonth;


-- ============================================================
-- QUERY 4: REVENUE BY DAY OF WEEK
-- Which days generate the most revenue?
-- Operational insight: when are customers most active?
-- ============================================================
SELECT
    Day_of_Week,
    COUNT(DISTINCT InvoiceNo)                   AS total_orders,
    ROUND(SUM(Revenue), 2)                      AS total_revenue,
    ROUND(AVG(Revenue), 2)                      AS avg_revenue_per_transaction,

    -- Rank days by revenue
    RANK() OVER (
        ORDER BY SUM(Revenue) DESC
    )                                           AS revenue_rank

FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
WHERE is_cancelled = false
  AND CustomerID IS NOT NULL
GROUP BY Day_of_Week
ORDER BY total_revenue DESC;


-- ============================================================
-- QUERY 5: REVENUE BY HOUR OF DAY
-- When during the day do customers place orders?
-- Helps operations team with staffing and marketing timing
-- ============================================================
SELECT
    Hour,
    COUNT(DISTINCT InvoiceNo)                   AS total_orders,
    ROUND(SUM(Revenue), 2)                      AS total_revenue,
    ROUND(AVG(Revenue), 2)                      AS avg_order_value

FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
WHERE is_cancelled = false
  AND CustomerID IS NOT NULL
GROUP BY Hour
ORDER BY Hour;


-- ============================================================
-- QUERY 6: NEW VS RETURNING CUSTOMER REVENUE
-- Are we growing through new customers or retaining old ones?
-- First purchase = new customer, subsequent = returning
-- ============================================================
WITH customer_first_purchase AS (
    -- Step 1: Find each customer's very first purchase month
    SELECT
        CustomerID,
        MIN(YearMonth)                          AS first_purchase_month
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
tagged_orders AS (
    -- Step 2: Tag each transaction as new or returning
    SELECT
        t.YearMonth,
        t.InvoiceNo,
        t.CustomerID,
        t.Revenue,
        CASE
            WHEN t.YearMonth = c.first_purchase_month
            THEN 'New Customer'
            ELSE 'Returning Customer'
        END                                     AS customer_type
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv') t
    LEFT JOIN customer_first_purchase c
        ON t.CustomerID = c.CustomerID
    WHERE t.is_cancelled = false
      AND t.CustomerID IS NOT NULL
)
-- Step 3: Summarize revenue by customer type per month
SELECT
    YearMonth,
    customer_type,
    COUNT(DISTINCT CustomerID)                  AS customer_count,
    ROUND(SUM(Revenue), 2)                      AS total_revenue
FROM tagged_orders
GROUP BY YearMonth, customer_type
ORDER BY YearMonth, customer_type;
