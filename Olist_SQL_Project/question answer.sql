# What are the overall business KPIs?

Select
count(distinct o.order_id) as total_orders,
count(distinct o.customer_id) as total_customers,
count(oi.order_item_id) as total_items_sold,
round(sum(oi.price), 2) as total_product_sales,
round(avg(oi.price), 2) as avg_item_price

from orders o
join order_items oi
on o.order_id = oi.order_id
where o.order_status = 'delivered';

-- =====================================================
-- Q2. Top 10 Product Categories by Sales
-- =====================================================

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,
    
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS total_sales

FROM order_items oi

JOIN orders o
    ON oi.order_id = o.order_id

JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name

WHERE o.order_status = 'delivered'

GROUP BY category

ORDER BY total_sales DESC

LIMIT 10;

-- =====================================================
-- Q3. Monthly Sales Trend
-- =====================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- =====================================================
-- Q4. Month-over-Month Sales Growth
-- =====================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        ROUND(SUM(oi.price), 2) AS total_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
),

sales_with_previous_month AS (
    SELECT
        month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales
    FROM monthly_sales
)

SELECT
    month,
    total_sales,
    previous_month_sales,
    ROUND(
        ((total_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0)) * 100,
        2
    ) AS mom_growth_percentage
FROM sales_with_previous_month
ORDER BY month;

-- =====================================================
-- Q5. Sales Performance by Customer State
-- =====================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM customers c

JOIN orders o
    ON c.customer_id = o.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_state

ORDER BY total_sales DESC;

-- =====================================================
-- Q6. Top 10 Sellers by Product Sales
-- =====================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM sellers s

JOIN order_items oi
    ON s.seller_id = oi.seller_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered'

GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state

ORDER BY total_sales DESC

LIMIT 10;

-- =====================================================
-- Q7. Payment Method Analysis
-- =====================================================

SELECT
    p.payment_type,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT p.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS total_payment_value,
    ROUND(AVG(p.payment_value), 2) AS avg_payment_value,
    ROUND(AVG(p.payment_installments), 2) AS avg_installments
FROM payments p

JOIN orders o
    ON p.order_id = o.order_id

WHERE o.order_status = 'delivered'

GROUP BY p.payment_type

ORDER BY total_payment_value DESC;

-- =====================================================
-- Q8. Customer Review Score Analysis
-- =====================================================

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_reviews
FROM reviews

GROUP BY review_score

ORDER BY review_score;

-- =====================================================
-- Q9. Delivery Performance Analysis
-- =====================================================

SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS avg_delivery_days

FROM orders

WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL

GROUP BY delivery_status

ORDER BY total_orders DESC;

-- =====================================================
-- Q10. Top 10 Customers by Spending
-- =====================================================

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items,
    ROUND(SUM(oi.price), 2) AS total_spent
FROM customers c

JOIN orders o
    ON c.customer_id = o.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_unique_id

ORDER BY total_spent DESC

LIMIT 10;

-- =====================================================
-- Q11. One-Time vs Repeat Customer Analysis
-- =====================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_orders

GROUP BY customer_type

ORDER BY total_customers DESC;

-- =====================================================
-- Q12. Top 3 Products Within Each Category
-- =====================================================

WITH product_sales AS (

    SELECT
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS category,

        p.product_id,

        COUNT(*) AS items_sold,

        ROUND(SUM(oi.price), 2) AS total_sales

    FROM order_items oi

    JOIN orders o
        ON oi.order_id = o.order_id

    JOIN products p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name

    WHERE o.order_status = 'delivered'

    GROUP BY
        category,
        p.product_id
),

ranked_products AS (

    SELECT
        category,
        product_id,
        items_sold,
        total_sales,

        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY total_sales DESC
        ) AS product_rank

    FROM product_sales
)

SELECT
    category,
    product_id,
    items_sold,
    total_sales,
    product_rank

FROM ranked_products

WHERE product_rank <= 3

ORDER BY
    category,
    product_rank;

-- =====================================================
-- Q13. RFM Customer Segmentation
-- =====================================================

WITH customer_metrics AS (

    SELECT
        c.customer_unique_id,

        MAX(o.order_purchase_timestamp) AS last_purchase_date,

        COUNT(DISTINCT o.order_id) AS frequency,

        ROUND(SUM(oi.price), 2) AS monetary

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

rfm_values AS (

    SELECT
        customer_unique_id,

        (
            MAX(last_purchase_date) OVER ()
            - last_purchase_date
        ) AS recency,

        frequency,
        monetary

    FROM customer_metrics
),

rfm_scores AS (

    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,

        6 - NTILE(5) OVER (
            ORDER BY recency
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary
        ) AS monetary_score

    FROM rfm_values
)

SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,

    CASE
        WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
            THEN 'Champions'

        WHEN recency_score >= 3
             AND frequency_score >= 3
            THEN 'Loyal Customers'

        WHEN recency_score <= 2
             AND frequency_score >= 3
            THEN 'At Risk'

        WHEN recency_score >= 4
             AND frequency_score <= 2
            THEN 'Recent Customers'

        ELSE 'Regular Customers'

    END AS customer_segment

FROM rfm_scores

ORDER BY monetary DESC;

-- =====================================================
-- Q14. Monthly Customer Cohort Retention Analysis
-- =====================================================

WITH customer_orders AS (

    -- Step 1: Get every customer's purchase month
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

customer_cohorts AS (

    -- Step 2: Find each customer's first purchase month
    SELECT
        customer_unique_id,
        order_month,
        MIN(order_month) OVER (
            PARTITION BY customer_unique_id
        ) AS cohort_month

    FROM customer_orders
),

cohort_activity AS (

    -- Step 3: Calculate months since first purchase
    SELECT
        customer_unique_id,
        cohort_month,
        order_month,

        (
            EXTRACT(YEAR FROM AGE(order_month, cohort_month)) * 12
            +
            EXTRACT(MONTH FROM AGE(order_month, cohort_month))
        )::INTEGER AS month_number

    FROM customer_cohorts
),

cohort_counts AS (

    -- Step 4: Count active customers
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers

    FROM cohort_activity

    GROUP BY
        cohort_month,
        month_number
),

cohort_sizes AS (

    -- Step 5: Find original size of each cohort
    SELECT
        cohort_month,
        active_customers AS cohort_size

    FROM cohort_counts

    WHERE month_number = 0
)

-- Step 6: Calculate retention percentage

SELECT
    cc.cohort_month,
    cc.month_number,
    cc.active_customers,
    cs.cohort_size,

    ROUND(
        cc.active_customers * 100.0 /
        NULLIF(cs.cohort_size, 0),
        2
    ) AS retention_rate

FROM cohort_counts cc

JOIN cohort_sizes cs
    ON cc.cohort_month = cs.cohort_month

ORDER BY
    cc.cohort_month,
    cc.month_number;

-- =====================================================
-- Q15. Executive Business Summary
-- =====================================================

WITH order_summary AS (

    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.price) AS product_sales,
        SUM(oi.freight_value) AS freight_value,
        COUNT(oi.order_item_id) AS items

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        o.order_id,
        o.customer_id
)

SELECT
    COUNT(DISTINCT os.order_id) AS total_orders,

    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,

    SUM(os.items) AS total_items_sold,

    ROUND(SUM(os.product_sales), 2) AS total_product_sales,

    ROUND(SUM(os.freight_value), 2) AS total_freight_value,

    ROUND(AVG(os.product_sales), 2) AS avg_order_product_value,

    ROUND(
        SUM(os.product_sales)
        / NULLIF(COUNT(DISTINCT os.order_id), 0),
        2
    ) AS product_sales_per_order

FROM order_summary os

JOIN customers c
    ON os.customer_id = c.customer_id;

























































































