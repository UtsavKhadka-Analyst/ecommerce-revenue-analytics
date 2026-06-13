-- ============================================================
-- FILE: 04_rfm_segmentation.sql
-- PURPOSE: RFM (Recency, Frequency, Monetary) customer
--          segmentation — classify every customer into
--          actionable marketing/retention segments
-- ANALYST: Utsav Khadka
-- PROJECT: E-Commerce Revenue & Customer Lifecycle Analytics
--
-- BUSINESS CONTEXT:
-- Files 1-3 showed revenue is growing but new customer
-- acquisition is collapsing. This file answers the next
-- question: "Out of the customers we DO have, who are our
-- best customers, who is slipping away, and who is already
-- lost?" This turns one giant customer list into groups the
-- VP's team can act on (e.g. win-back emails for At Risk).
--
-- RFM DEFINITIONS (from CLAUDE.md Section 8):
--   Recency   = Days between customer's last purchase and
--               dataset end date (2011-12-09). Lower = better.
--   Frequency = Total number of unique invoices per customer.
--               Higher = better.
--   Monetary  = Total revenue per customer. Higher = better.
--
-- NEW SQL CONCEPTS:
--   NTILE(5)   → splits customers into 5 equal-sized buckets
--                (quintiles) based on a ranking. Bucket 5 =
--                top 20%, Bucket 1 = bottom 20%.
--   CASE WHEN  → maps combinations of R/F/M scores to a
--                human-readable segment name.
--
-- HOW TO RUN: Execute via notebooks/02_sql_analysis.ipynb
-- ============================================================


-- ============================================================
-- QUERY 1: RFM BASE METRICS
-- Calculate raw Recency, Frequency, and Monetary value for
-- every customer. This is the foundation for everything else.
-- ============================================================
SELECT
    CustomerID,

    -- RECENCY: days between last purchase and dataset end date
    -- Dataset ends 2011-12-09 (the day after the last invoice)
    DATE_DIFF(
        'day',
        MAX(CAST(InvoiceDate AS DATE)),
        DATE '2011-12-09'
    )                                            AS recency_days,

    -- FREQUENCY: how many separate orders has this customer placed?
    COUNT(DISTINCT InvoiceNo)                   AS frequency,

    -- MONETARY: total revenue from this customer
    ROUND(SUM(Revenue), 2)                      AS monetary

FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
WHERE is_cancelled = false
  AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY monetary DESC;


-- ============================================================
-- QUERY 2: RFM SCORES (1-5 PER DIMENSION)
-- Convert raw R/F/M values into 1-5 scores using NTILE(5),
-- then combine into a single 3-digit RFM score (e.g. "555").
-- ============================================================
WITH rfm_base AS (
    -- Step 1: Same as Query 1 — raw R/F/M per customer
    SELECT
        CustomerID,
        DATE_DIFF(
            'day',
            MAX(CAST(InvoiceDate AS DATE)),
            DATE '2011-12-09'
        )                                        AS recency_days,
        COUNT(DISTINCT InvoiceNo)               AS frequency,
        ROUND(SUM(Revenue), 2)                  AS monetary
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    recency_days,
    frequency,
    monetary,

    -- R SCORE: smaller recency_days = more recent = BETTER.
    -- Order DESC so the customer with the LARGEST recency_days
    -- (oldest, worst) lands in bucket 1, and the most recent
    -- customer lands in bucket 5.
    NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,

    -- F SCORE: more orders = better.
    -- Order ASC so the lowest frequency lands in bucket 1,
    -- and the highest frequency lands in bucket 5.
    NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,

    -- M SCORE: more revenue = better. Same logic as frequency.
    NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score

FROM rfm_base
ORDER BY monetary DESC;


-- ============================================================
-- QUERY 3: CUSTOMER SEGMENTATION
-- Combine R, F, M scores into a named segment using CASE WHEN.
-- This is the output the marketing team would actually use.
-- ============================================================
WITH rfm_base AS (
    SELECT
        CustomerID,
        DATE_DIFF(
            'day',
            MAX(CAST(InvoiceDate AS DATE)),
            DATE '2011-12-09'
        )                                        AS recency_days,
        COUNT(DISTINCT InvoiceNo)               AS frequency,
        ROUND(SUM(Revenue), 2)                  AS monetary
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
rfm_scores AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_base
)
SELECT
    CustomerID,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,

    -- Combine all 3 scores into one number for reference
    -- e.g. r_score=5, f_score=5, m_score=4 -> 554
    (r_score * 100 + f_score * 10 + m_score)    AS rfm_score,

    -- SEGMENT: maps score combinations to business-friendly names
    -- Ordered from best customers to worst/lost customers.
    CASE
        -- Best customers: bought recently, often, and spend a lot
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'

        -- Buy regularly and recently, but not top spenders yet
        WHEN r_score >= 3 AND f_score >= 4
            THEN 'Loyal Customers'

        -- Bought recently and showing good frequency growth
        WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3
            THEN 'Potential Loyalist'

        -- Bought recently but only once — first impression matters
        WHEN r_score >= 4 AND f_score = 1
            THEN 'New Customers'

        -- Used to buy often and spend a lot, but haven't been back
        -- recently — highest priority for win-back campaigns
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4
            THEN 'Cannot Lose Them'

        -- Below-average recency with decent frequency — slipping away
        WHEN r_score <= 2 AND f_score >= 3
            THEN 'At Risk'

        -- Mid-recency, low frequency — needs attention before they leave
        WHEN r_score = 3 AND f_score <= 2
            THEN 'Needs Attention'

        -- Long time since last purchase, low frequency and spend
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
            THEN 'Hibernating'

        -- Catch-all for any remaining combination
        ELSE 'Other'
    END                                          AS customer_segment

FROM rfm_scores
ORDER BY rfm_score DESC;


-- ============================================================
-- QUERY 4: SEGMENT SUMMARY
-- How many customers are in each segment, and how much revenue
-- does each segment represent? This is the slide the VP sees.
-- ============================================================
WITH rfm_base AS (
    SELECT
        CustomerID,
        DATE_DIFF(
            'day',
            MAX(CAST(InvoiceDate AS DATE)),
            DATE '2011-12-09'
        )                                        AS recency_days,
        COUNT(DISTINCT InvoiceNo)               AS frequency,
        ROUND(SUM(Revenue), 2)                  AS monetary
    FROM read_csv_auto('../data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
rfm_scores AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_base
),
segmented AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3
                THEN 'Potential Loyalist'
            WHEN r_score >= 4 AND f_score = 1
                THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4
                THEN 'Cannot Lose Them'
            WHEN r_score <= 2 AND f_score >= 3
                THEN 'At Risk'
            WHEN r_score = 3 AND f_score <= 2
                THEN 'Needs Attention'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
                THEN 'Hibernating'
            ELSE 'Other'
        END                                      AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(CustomerID)                           AS num_customers,

    -- % of total customer base in this segment
    ROUND(
        COUNT(CustomerID) * 100.0 / SUM(COUNT(CustomerID)) OVER (),
        1
    )                                            AS pct_of_customers,

    ROUND(AVG(recency_days), 1)                 AS avg_recency_days,
    ROUND(AVG(frequency), 1)                    AS avg_frequency,
    ROUND(AVG(monetary), 2)                     AS avg_monetary,

    ROUND(SUM(monetary), 2)                     AS total_revenue,

    -- % of total revenue this segment represents
    -- This is the number that gets a VP's attention
    ROUND(
        SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (),
        1
    )                                            AS pct_of_revenue

FROM segmented
GROUP BY customer_segment
ORDER BY total_revenue DESC;
