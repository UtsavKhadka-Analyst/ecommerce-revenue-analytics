import duckdb
import pandas as pd

conn = duckdb.connect()

query = """
WITH rfm_base AS (
    SELECT
        CustomerID,
        DATE_DIFF('day', MAX(CAST(InvoiceDate AS DATE)), DATE '2011-12-09') AS recency_days,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        ROUND(SUM(Revenue), 2) AS monetary
    FROM read_csv_auto('data/cleaned/online_retail_cleaned.csv')
    WHERE is_cancelled = false AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
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
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 4                  THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3       THEN 'Potential Loyalist'
        WHEN r_score >= 4 AND f_score = 1                   THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Cannot Lose Them'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
        WHEN r_score = 3  AND f_score <= 2                  THEN 'Needs Attention'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating'
        ELSE 'Other'
    END AS customer_segment
FROM rfm_scores
"""

df = conn.execute(query).df()
df.to_csv('data/cleaned/customer_rfm_segments.csv', index=False)

print(f'Exported {len(df)} customers')
print()
print('Segment breakdown:')
print(df['customer_segment'].value_counts())
