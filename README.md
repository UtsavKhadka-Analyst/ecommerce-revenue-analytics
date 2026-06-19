# E-Commerce Revenue & Customer Lifecycle Analytics

**Analyst:** Utsav Khadka
**Dataset:** UCI Online Retail (UK-based online gift retailer, Dec 2010 – Dec 2011)
**Tools:** SQL (DuckDB) · Python (Pandas, Matplotlib, Seaborn) · Tableau Public

🔗 **[View Live Dashboard on Tableau Public](https://public.tableau.com/app/profile/utsav.khadka/viz/Ecommerce_Revenue_Analysis/E-Commerce_Revenue_Analytics)**

---

## Business Question

> *"Revenue looks flat. Are we losing customers? Are our best customers spending less? Which products and regions are driving growth vs. declining?"*
> — VP of Sales

---

## Key Findings

### Revenue grew 83% — but the trend is fragile
Total revenue grew from **£821K (Dec 2010)** to a peak of **£1.5M (Nov 2011)**, totalling **£10.64M** over 13 months. Revenue is not flat — but growth is almost entirely driven by returning customers, not new ones.

### New customer acquisition collapsed 90%
New customers per month dropped from **417 (Jan 2011)** to **41 (Dec 2011)**. If returning customers slow their spending for any reason — economic, competitive, or seasonal — there is no acquisition pipeline to compensate.

### 22.5% of customers generate 65.2% of revenue
**Champions** (highest RFM scores) represent 975 customers but drive **£5.79M** — far more concentrated than a typical 80/20 split. Losing even a small number of top accounts would disproportionately damage revenue.

### 148 high-value customers have gone silent — £348K at risk
The **"Cannot Lose Them"** RFM segment: customers who historically spent **£2,385 on average** but haven't purchased in **120+ days**. Immediate win-back outreach is the highest-ROI action available.

### EIRE (Ireland) has the highest revenue per customer of any market
Only 3 identified EIRE customers generated **£265,000 total** — an average of **£88,420 per customer** with a 100% repeat rate. This wholesale account profile is the model to replicate internationally.

---

## Dashboard Preview

**[Live Tableau Dashboard →](https://public.tableau.com/app/profile/utsav.khadka/viz/Ecommerce_Revenue_Analysis/E-Commerce_Revenue_Analytics)**

| Section | Charts |
|---|---|
| KPI Summary | Total Revenue · Total Orders · Total Customers · AOV |
| Revenue Overview | Monthly Trend · New vs Returning · MoM Growth % |
| Customer Health | Cohort Retention Heatmap · RFM Segment Breakdown |
| Product & Geographic | Top 10 Products · Country Revenue (log scale) |

---

## Project Structure

```
ecommerce-revenue-analytics/
│
├── data/
│   └── raw/                          ← Original UCI dataset (read-only)
│
├── notebooks/
│   ├── 01_data_cleaning.ipynb        ← Phase 1: cleaning + quality report
│   └── 02_eda_analysis.ipynb         ← Phase 3: 8 insight-driven charts
│
├── sql/
│   ├── 01_data_exploration.sql       ← Data profiling and quality checks
│   ├── 02_revenue_analysis.sql       ← MoM growth, AOV, moving averages
│   ├── 03_customer_cohorts.sql       ← Cohort retention analysis
│   ├── 04_rfm_segmentation.sql       ← RFM scoring and segmentation
│   └── 05_product_geo_analysis.sql   ← Product and geographic deep dives
│
├── dashboards/
│   └── tableau_link.md               ← Tableau Public URL
│
├── deliverables/
│   └── executive_memo.md             ← One-page business recommendations
│
├── export_rfm_segments.py            ← RFM segment export for Tableau
└── requirements.txt                  ← Python dependencies
```

---

## Methodology

### Phase 1 — Data Cleaning (Python / Pandas)
- Removed duplicates, null prices, and zero-quantity rows
- Flagged cancellations (Invoice starting with 'C') without deleting — cancellation rate is a business metric
- Retained ~132,000 null CustomerID rows for revenue/product analysis; excluded only for customer-level analysis
- Engineered features: Revenue, Date parts (Year, Month, Day of Week, Hour), YearMonth, is_cancelled flag
- **Result:** 534,130 clean rows ready for analysis

### Phase 2 — SQL Analysis (DuckDB)
Five SQL files covering the full analytical spectrum:

| File | Analysis |
|---|---|
| `01_data_exploration.sql` | Row counts, null profiling, date range validation |
| `02_revenue_analysis.sql` | Monthly revenue, AOV, MoM growth, 3-month moving average |
| `03_customer_cohorts.sql` | Cohort retention matrix — tracks % of customers returning by month |
| `04_rfm_segmentation.sql` | NTILE(5) scoring across Recency, Frequency, Monetary → 8 named segments |
| `05_product_geo_analysis.sql` | Top/bottom products, H1 vs H2 growth, country-level metrics |

**Key SQL concepts demonstrated:** CTEs, window functions (NTILE, RANK, SUM OVER), UNION ALL, LOD-equivalent logic, conditional aggregation (SUM CASE WHEN), NULLIF for division safety, regexp_matches for pattern filtering

### Phase 3 — Python EDA (Matplotlib / Seaborn)
Eight insight-driven visualizations, each titled with the business finding (not just the metric):

1. Monthly Revenue Trend — annotated line chart
2. New vs Returning Customer Revenue — stacked bar (LOD-equivalent logic)
3. Cohort Retention Heatmap — sns.heatmap with retention % matrix
4. RFM Segment Revenue Contribution — pd.qcut scoring, np.select segmentation
5. Revenue by Day of Week — zero Saturday confirms B2B wholesale model
6. Revenue by Hour of Day — peak hour highlighted
7. Top 10 Products by Revenue — horizontal bar, filtered to real products (regex)
8. Top 10 Countries by Revenue — log-scale x-axis, UK highlighted

### Phase 4 — Tableau Dashboard
Single scrollable dashboard with 11 visualizations across 4 sections. Key Tableau techniques used:
- LOD expressions (`FIXED`) for customer type classification and cohort month calculation
- Context filters for Top N product ranking
- Logarithmic axis scaling for country revenue comparison
- Data blending (main CSV + RFM segments CSV joined on CustomerID)
- Calculated fields for AOV, Retention %, Segment Color highlighting

### Phase 5 — Executive Memo
One-page business memo written for a non-technical VP of Sales audience — findings first, numbers specific, recommendations prioritized by ROI and urgency.

---

## Key Business Metrics (Definitions)

| Metric | Definition |
|---|---|
| Revenue | Quantity × UnitPrice (non-cancelled transactions only) |
| AOV | Total Revenue / Total Distinct Orders |
| Cohort Retention | Customers active in Month N who also purchased in Month 0 / Cohort size |
| RFM Recency | Days between last purchase and dataset end date (2011-12-09) |
| RFM Frequency | Count of distinct invoices per customer |
| RFM Monetary | Total revenue per customer |

---

## Notable Analytical Decisions

| Decision | Rationale |
|---|---|
| Kept null CustomerIDs | Guest checkouts (~25%) still contribute real revenue and product data |
| Flagged cancellations, didn't delete | Cancellation rate is a business metric — hiding it is bad analysis |
| Used log scale for country revenue | UK (£9M) would make all other countries invisible on linear scale |
| NTILE(5) for RFM scoring | Equal-sized buckets — avoids bias from outliers vs percentile-based methods |
| h1_revenue > 0 filter in growth query | Products with zero H1 revenue produce undefined % change — they are "new launches", not "declining products" |
| Saturday excluded from weekday analysis | Zero transactions on Saturdays across all 13 months — confirms B2B wholesale operations model |

---

## Summary Statistics

| Metric | Value |
|---|---|
| Total Revenue | £10,642,128 |
| Total Orders | 19,959 |
| Total Customers (identified) | 4,338 |
| Average Order Value | £533.20 |
| Date Range | Dec 2010 – Dec 2011 (13 months) |
| Countries | 37 |
| Unique Products | 3,684+ |
| Raw Rows | 541,909 |
| Clean Rows | 534,130 |

---

## Tech Stack

| Tool | Purpose |
|---|---|
| Python 3.12 | Data cleaning, EDA, visualization |
| Pandas | Data manipulation and feature engineering |
| Matplotlib + Seaborn | All charts (no Plotly, no Dash — clean and professional) |
| DuckDB | SQL queries directly on CSV files (no database server needed) |
| Tableau Public | Interactive dashboard |
| Jupyter Notebook | Reproducible analysis environment |
| Git + GitHub | Version control |

---

## How to Run Locally

```bash
# Clone the repo
git clone https://github.com/UtsavKhadka-Analyst/ecommerce-revenue-analytics.git
cd ecommerce-revenue-analytics

# Set up Python environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run notebooks
jupyter notebook

# Run SQL analysis
# Open notebooks/02_sql_analysis.ipynb and run cells
# (DuckDB reads the CSV directly — no database setup needed)
```

---

*This project targets Data Analyst roles requiring SQL, Python, and Tableau skills.*
*Dataset: [UCI Online Retail Dataset](https://archive.ics.uci.edu/ml/datasets/Online+Retail) via Kaggle.*
