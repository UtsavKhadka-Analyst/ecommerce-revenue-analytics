-- ============================================================
-- FILE: 01_data_exploration.sql
-- PURPOSE: Initial data profiling and exploration
-- ANALYST: Utsav Khadka
-- PROJECT: E-Commerce Revenue & Customer Lifecycle Analytics
--
-- BUSINESS CONTEXT:
-- Before answering the VP's revenue question, we must first
-- understand what the data contains, its date range, and
-- key business metrics at a high level.
--
-- HOW TO RUN: Execute via notebooks/02_sql_analysis.ipynb
-- ============================================================


-- ============================================================
-- QUERY 1: DATASET OVERVIEW
-- What is the overall shape and date range of our data?
-- ============================================================
SELECT
    COUNT(*)                                    AS total_rows,
    COUNT(DISTINCT InvoiceNo)                   AS unique_invoices,
    COUNT(DISTINCT CustomerID)                  AS unique_customers,
    COUNT(DISTINCT StockCode)                   AS unique_products,
    COUNT(DISTINCT Country)                     AS unique_countries,
    MIN(InvoiceDate)                            AS earliest_date,
    MAX(InvoiceDate)                            AS latest_date
FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv');


-- ============================================================
-- QUERY 2: REVENUE OVERVIEW
-- What is total revenue, average order value, and revenue
-- per transaction?
-- ============================================================
WITH order_revenue AS (
    -- Step 1: Calculate revenue per unique invoice (order)
    -- One invoice can have multiple product rows — we sum them
    SELECT
        InvoiceNo,
        CustomerID,
        SUM(Revenue) AS order_total
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false          -- exclude cancellations
      AND CustomerID IS NOT NULL        -- exclude guest checkouts
    GROUP BY InvoiceNo, CustomerID
)
SELECT
    -- Step 2: Calculate business-level metrics
    ROUND(SUM(order_total), 2)          AS total_revenue,
    COUNT(DISTINCT InvoiceNo)           AS total_orders,
    ROUND(AVG(order_total), 2)          AS avg_order_value,   -- AOV
    ROUND(MIN(order_total), 2)          AS min_order_value,
    ROUND(MAX(order_total), 2)          AS max_order_value
FROM order_revenue;


-- ============================================================
-- QUERY 3: TOP 10 COUNTRIES BY REVENUE
-- Which markets generate the most revenue?
-- This answers: "Which regions are driving growth?"
-- ============================================================
SELECT
    Country,
    COUNT(DISTINCT InvoiceNo)           AS total_orders,
    COUNT(DISTINCT CustomerID)          AS total_customers,
    ROUND(SUM(Revenue), 2)              AS total_revenue,

    -- Calculate each country's % share of total revenue
    ROUND(
        SUM(Revenue) * 100.0 /
        SUM(SUM(Revenue)) OVER (),      -- window function: total revenue
        2
    )                                   AS revenue_pct

FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
WHERE is_cancelled = false
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- QUERY 4: TOP 10 PRODUCTS BY REVENUE
-- Which products generate the most revenue?
-- This answers: "Which products are driving growth?"
-- ============================================================
SELECT
    StockCode,
    Description,
    SUM(Quantity)                       AS total_units_sold,
    ROUND(SUM(Revenue), 2)              AS total_revenue,
    ROUND(AVG(UnitPrice), 2)            AS avg_unit_price,

    -- Rank products by revenue (1 = highest revenue)
    RANK() OVER (ORDER BY SUM(Revenue) DESC) AS revenue_rank

FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
WHERE is_cancelled = false
  AND Description IS NOT NULL
GROUP BY StockCode, Description
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- QUERY 5: MONTHLY TRANSACTION VOLUME
-- How many orders and customers do we serve each month?
-- This shows business scale and seasonality.
-- ============================================================
SELECT
    YearMonth,
    COUNT(DISTINCT InvoiceNo)           AS total_orders,
    COUNT(DISTINCT CustomerID)          AS active_customers,
    ROUND(SUM(Revenue), 2)              AS monthly_revenue,
    ROUND(AVG(Revenue), 2)              AS avg_transaction_value

FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
WHERE is_cancelled = false
  AND CustomerID IS NOT NULL
GROUP BY YearMonth
ORDER BY YearMonth;


-- ============================================================
-- QUERY 6: CUSTOMER OVERVIEW
-- What does the customer base look like at a high level?
-- ============================================================
WITH customer_summary AS (
    -- Step 1: Calculate per-customer metrics
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo)       AS total_orders,
        ROUND(SUM(Revenue), 2)          AS total_spent,
        MIN(InvoiceDate)                AS first_purchase,
        MAX(InvoiceDate)                AS last_purchase
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    -- Step 2: Summarize across all customers
    COUNT(CustomerID)                   AS total_customers,
    ROUND(AVG(total_orders), 1)         AS avg_orders_per_customer,
    ROUND(AVG(total_spent), 2)          AS avg_revenue_per_customer,
    ROUND(MIN(total_spent), 2)          AS min_customer_revenue,
    ROUND(MAX(total_spent), 2)          AS max_customer_revenue
FROM customer_summary;
