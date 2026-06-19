# Executive Memo

---

**TO:** VP of Sales
**FROM:** Utsav Khadka, Data Analyst
**DATE:** June 2026
**RE:** Revenue & Customer Health Analysis — UK Online Retail (Dec 2010 – Dec 2011)

---

## Situation

You raised a concern that revenue looks flat and asked three questions:
- Are we losing customers?
- Are our best customers spending less?
- Which products and regions are driving growth vs. declining?

This memo summarizes findings from a full analysis of 534,000+ transactions across 13 months.

**Interactive dashboard:** https://public.tableau.com/app/profile/utsav.khadka/viz/Ecommerce_Revenue_Analysis/E-Commerce_Revenue_Analytics

---

## Bottom Line Up Front

**Revenue is NOT flat — it grew 83% over 12 months.** However, this growth is masking a serious underlying problem: new customer acquisition has nearly collapsed, and we are almost entirely dependent on a small group of loyal customers to sustain revenue. Without immediate action on acquisition and at-risk customers, growth will reverse within the next 2–3 quarters.

---

## Key Findings

### 1. Revenue Grew 83% — But the Trend Is Fragile
- Total revenue (Dec 2010 – Dec 2011): **£10.64M**
- Revenue grew from **£821K (Dec 2010)** to a peak of **£1.5M (Nov 2011)** — an 83% increase
- Growth is driven almost entirely by **returning customers**, not new ones
- Month-over-month growth is inconsistent (+43% in May, -25% in April), suggesting no sustainable demand driver beyond seasonality

### 2. New Customer Acquisition Is Collapsing
- New customers per month fell from **~417 (Jan 2011)** to **41 (Dec 2011)** — a **90% decline**
- Only **9 customers** out of 4,338 scored as high-potential "New Customers" in RFM segmentation
- If returning customer activity slows for any reason (economic, competitive, seasonal), there is no new customer pipeline to compensate

### 3. Revenue Is Dangerously Concentrated in Champions
- **Champions** (our best customers) represent only **22.5% of customers** but generate **65.2% of total revenue** — far more concentrated than a typical 80/20 rule
- This concentration means losing even a small number of top customers would disproportionately damage revenue
- Average Order Value is **£533** — confirming this is a B2B wholesale business where a few large accounts drive most of the numbers

### 4. 148 High-Value Customers Have Gone Silent — £348K at Risk
- The **"Cannot Lose Them"** segment: 148 customers who historically spent an average of **£2,385 each**, but have not purchased in the last **120+ days**
- Combined, this group represents approximately **£348,000 in revenue at risk**
- These customers were once frequent, high-spending buyers — their silence is a warning sign, not a natural cycle

### 5. Seasonal Demand Is Being Mistaken for Product Growth
- Products showing the highest H1→H2 growth (Wooden Star Christmas, Glitter Christmas Star, etc.) are **seasonal items**, not true growth products
- These products had near-zero revenue in H1 (Jan–Jun) and spiked in H2 (Jul–Dec) due to Q4 Christmas demand
- Planning and inventory decisions should account for this seasonality explicitly

### 6. 10 Products Disappeared Entirely in H2 — ~£16K Lost
- 10 products with real H1 revenue (e.g., Antique Silver Tea Glass Etched: **£3,222**, Ivory Giant Garden Thermometer: **£3,026**) recorded **£0 revenue in H2**
- This represents approximately **£15,955 in revenue that simply vanished**
- Cause is unknown — could be stockouts, supplier issues, or deliberate discontinuation — requires investigation

### 7. UK Dominates, But EIRE Shows the Highest Growth Potential
- **United Kingdom:** Largest market by volume and revenue, **65%+ repeat customer rate**
- **EIRE (Ireland):** Only 3 identified customers, yet generating **£265,000 total** — an average of **£88,420 per customer** with a 100% repeat rate
- EIRE represents the highest revenue-per-customer of any market — a wholesale account model worth replicating in other European markets

---

## Recommendations

### Recommendation 1: Launch an Immediate Win-Back Campaign for "Cannot Lose Them" (Priority: HIGH)
Target the 148 silent high-value customers with a personalized outreach campaign within the next 30 days.
- Offer: Volume discount, dedicated account manager contact, or early access to new stock
- Goal: Reactivate at least 30% of this segment = **~£105,000 in recovered revenue**
- Timeline: Campaign live within 2 weeks; results measurable within 60 days

### Recommendation 2: Invest in New Customer Acquisition Before Q1 (Priority: HIGH)
The 90% drop in new customers is the single biggest long-term risk to the business.
- Identify which channels brought in the 417 new customers in Jan 2011 and why those have dried up
- Set a target of at least **100 new customers per month** by Q1 2027
- Consider referral programs targeting existing Champions — they know similar wholesale buyers

### Recommendation 3: Protect the Champions Segment (Priority: HIGH)
Our top customers generate 65% of revenue and cannot be taken for granted.
- Assign dedicated account managers to the top 50 Champions by revenue
- Implement a proactive check-in cadence (monthly call or email) for accounts >£5,000 annual spend
- Monitor for any drop in order frequency as an early warning signal

### Recommendation 4: Investigate the 10 Discontinued Products (Priority: MEDIUM)
- Determine whether the £15,955 revenue loss in H2 was due to stockouts or deliberate discontinuation
- If stockouts: reorder immediately ahead of the next seasonal cycle
- If discontinued: confirm whether customer demand shifted to a replacement product

### Recommendation 5: Build a Holiday Inventory Plan for Q4 (Priority: MEDIUM)
- Seasonal gift products (Christmas items) drove significant H2 revenue spikes
- Begin stocking seasonal products by **August** to capture early wholesale orders
- Use the H1→H2 growth data to forecast Q4 demand by product category

### Recommendation 6: Develop the EIRE Wholesale Model (Priority: LOW / LONG TERM)
- The EIRE account profile (£88K per customer, 100% repeat) is the ideal customer archetype
- Identify similar wholesale distributors in Netherlands, Germany, and France (markets already in our top 10)
- Assign a dedicated international account development resource

---

## Supporting Data

| Metric | Value |
|---|---|
| Total Revenue (excl. cancellations) | £10,642,128 |
| Total Orders | 19,959 |
| Total Customers (identified) | 4,338 |
| Average Order Value | £533.20 |
| Champions % of Revenue | 65.2% |
| New Customers (Dec 2011) | 41/month (down from 417) |
| "Cannot Lose Them" Revenue at Risk | ~£348,000 |
| Top Product | Regency Cakestand 3 Tier |
| Highest Value Market | EIRE (£88,420/customer) |

**Full interactive dashboard:** https://public.tableau.com/app/profile/utsav.khadka/viz/Ecommerce_Revenue_Analysis/E-Commerce_Revenue_Analytics

**Data source:** UCI Online Retail Dataset | 534,130 transactions | Dec 2010 – Dec 2011

---

*Analysis conducted using SQL (DuckDB), Python (Pandas, Matplotlib, Seaborn), and Tableau Public.*
*All revenue figures exclude cancelled transactions. Customer-level analysis excludes ~132,000 guest checkouts (no CustomerID).*
