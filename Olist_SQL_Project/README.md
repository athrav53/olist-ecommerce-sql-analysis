# Olist E-Commerce SQL Analysis
I built this project to practise real-world SQL on a messy, multi-table dataset. I used PostgreSQL to analyse around 100k orders from Olist, a Brazilian e-commerce marketplace, and tried to answer the kinds of questions a business team would actually ask: what's selling, where, who's buying, how deliveries are going, and whether customers come back.

The short version: Olist delivers reliably and most customers are happy, but almost nobody buys a second time. About 97% of customers placed just one order. That turned out to be the most interesting finding in the whole project.

---

## Tools I Used

PostgreSQL, pgAdmin 4, VS Code and GitHub.

## The Dataset

The data is the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle. It covers orders placed between 2016 and 2018 and is split across 8 tables: customers, orders, order_items, products, sellers, payments, reviews and category_translation.

This is how the tables connect:

```text
customers ──< orders ──< order_items >── products ── category_translation
                 │              │
                 ├──< payments  └──> sellers
                 └──< reviews
```

One thing that caught me out early on: in this dataset, customer_id is created fresh for every order, so the same person can have several customer_ids. To count real people, you need customer_unique_id. I used that for every customer-level metric (unique customers, repeat rate, RFM and cohorts).

---

## Project Structure

```text
olist-sql-analysis/
├── README.md
├── sql/
│   ├── 01_database_setup.sql      -- creating tables and importing the CSVs
│   ├── 02_data_validation.sql     -- checking data quality before analysis
│   └── 03_business_analysis.sql   -- the 15 business questions
└── screenshots/                   -- query results for the key questions
```

## Running It Yourself

1. Download the dataset from Kaggle and create a PostgreSQL database.
2. Run 01_database_setup.sql to create the tables, then import each CSV file.
3. Run 02_data_validation.sql to check the data.
4. Run 03_business_analysis.sql to see the analysis.

---

## Checking the Data First

Before running any analysis, I wanted to make sure the data was trustworthy. I checked row counts for every table, looked for missing values in important columns, made sure there were no duplicate IDs, reviewed the different order statuses, confirmed the date range, checked for negative prices, and made sure every order linked to a real customer.

I also decided to focus only on delivered orders. Including cancelled or unfinished orders would have inflated the sales numbers.

---

## Questions I Answered

| # | Question | SQL used |
|---|----------|----------|
| 1 | What are the overall business KPIs? | Aggregates, COUNT DISTINCT |
| 2 | Which categories sell the most? | LEFT JOIN, COALESCE |
| 3 | How do sales change month by month? | DATE_TRUNC |
| 4 | What's the month-over-month growth? | CTE, LAG, NULLIF |
| 5 | Which states bring in the most sales? | Multi-table joins |
| 6 | Who are the top sellers? | GROUP BY |
| 7 | How do customers prefer to pay? | Aggregates |
| 8 | How are customers rating their orders? | Window function percentages |
| 9 | Are orders arriving on time? | CASE, EXTRACT |
| 10 | Who are the biggest spenders? | GROUP BY customer_unique_id |
| 11 | How many customers come back? | CTE, CASE |
| 12 | What are the top 3 products in each category? | DENSE_RANK, PARTITION BY |
| 13 | How can customers be segmented? | RFM with NTILE |
| 14 | How does retention look over time? | Cohort analysis with multiple CTEs |
| 15 | What does the executive summary look like? | Order-level CTE |

---

## What I Found

### The big picture

| Metric | Value |
|--------|-------|
| Delivered orders | 96,478 |
| Unique customers | 93,358 |
| Items sold | 110,197 |
| Product sales | about R$13.22M |
| Freight | about R$2.20M |
| Average sales per order | about R$137 |

### Products

Health & Beauty was the top category, bringing in about R$1.23M. Interestingly, Bed, Bath & Table sold more individual items but made less money. Selling the most units doesn't always mean making the most revenue.

### Where customers are

São Paulo is by far the biggest market. It accounted for about R$5.07M in sales and 40,501 delivered orders, which is roughly 42% of all orders.

### Payments

Credit cards dominate, with about R$12.10M in payments. Customers split their payments into about 3.5 instalments on average, which suggests that paying in instalments matters a lot to Brazilian shoppers.

### Reviews

Customers are mostly happy. Around 58% of reviews are 5 stars and about 77% are 4 or 5 stars.

### Delivery

| Status | Orders | Average delivery time |
|--------|--------|-----------------------|
| On time | 88,644 | 10.88 days |
| Late | 7,826 | 31.52 days |

About 92% of orders arrived on time. When an order was late, though, it was very late, taking almost three times as long on average.

### Do customers come back?

Mostly, no. 97% of customers only ever placed one order. The cohort analysis backs this up: of the 717 customers who first ordered in January 2017, only 2 came back the following month.

---

## Customer Segmentation (RFM)

I grouped customers using three measures:

- Recency: how recently they bought something
- Frequency: how many orders they placed
- Monetary: how much they spent in total

Recency and monetary were scored from 1 to 5 using NTILE. Frequency needed a different approach. Since almost everyone ordered only once, splitting them into five equal groups would have given different scores to customers who behaved exactly the same. Instead, I used simple fixed ranges. Customers were then grouped into segments: Champions, Loyal Customers, At Risk, Recent Customers and Regular Customers.

---

## If I Were Advising Olist

1. Focus on getting customers to come back. With only 3% returning, even a small improvement, such as a follow-up email or a discount on a second order, could make a big difference.
2. Dig into late deliveries. Finding out which states or sellers cause the delays, and whether late orders get worse reviews, would be my next step.
3. Look beyond São Paulo. Sales are heavily concentrated there, so other large states might have room to grow.
4. Keep instalment payments easy. They clearly matter to customers.

---

## Limitations

- The first and last few months of the dataset only have partial data, so the growth figures for those months aren't reliable.
- Sales figures are based on item prices without freight, while payment figures include freight and instalment interest, so the two don't match exactly.
- The review analysis includes all reviews, not just those for delivered orders.

---

## What I Learned

The biggest lesson was about table grain. One order can have several items and several payments, so if you join everything together carelessly, revenue gets counted more than once. In the executive summary, I fixed this by totalling everything at the order level first.

I also learned to question the data instead of trusting column names (the customer_id issue), and got hands-on practice with window functions, multi-step CTEs, RFM segmentation and cohort analysis. Most importantly, I practised turning query results into findings that a non-technical person could act on.

## Project Screenshots

### Executive Business Summary
![Executive Business Summary](Screenshots/executive_summary.jpeg)

### Delivery Performance
![Delivery Performance](Screenshots/delivery_performance.jpeg)

### Payment Method Analysis
![Payment Analysis](Screenshots/payment_analysis.jpeg)

### RFM Customer Segmentation
![RFM Segmentation](Screenshots/rfm_segmentation.jpeg)

### Top Product Categories
![Top Categories](Screenshots/top_categories.jpeg)



## About Me

Athrav Potdar
Data Analytics | SQL | Python | Power BI


