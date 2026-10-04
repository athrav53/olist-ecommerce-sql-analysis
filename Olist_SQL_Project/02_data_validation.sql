-- =====================================================
-- OLIST E-COMMERCE SQL PROJECT
-- DATA VALIDATION
-- =====================================================


-- 1. Check total rows in each table

SELECT COUNT(*) AS total_customers
FROM customers;

SELECT COUNT(*) AS total_orders
FROM orders;

SELECT COUNT(*) AS total_products
FROM products;

SELECT COUNT(*) AS total_sellers
FROM sellers;

SELECT COUNT(*) AS total_order_items
FROM order_items;

SELECT COUNT(*) AS total_payments
FROM payments;

SELECT COUNT(*) AS total_reviews
FROM reviews;

SELECT COUNT(*) AS total_categories
FROM category_translation;

-- =====================================================
-- 2. NULL VALUE CHECKS
-- =====================================================

-- Missing customer information
SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS missing_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS missing_state
FROM customers;


-- Missing product information
SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS missing_category
FROM products;


-- Missing important order dates
SELECT
    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_date,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_date
FROM orders;

-- =====================================================
-- 3. DUPLICATE CHECKS
-- =====================================================

-- Duplicate order IDs
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Duplicate customer IDs
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Duplicate product IDs
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- =====================================================
-- 4. ORDER STATUS VALIDATION
-- =====================================================

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- =====================================================
-- 5. DATASET DATE RANGE
-- =====================================================

SELECT
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM orders;

-- =====================================================
-- 6. PRICE VALIDATION
-- =====================================================

SELECT
    COUNT(*) AS invalid_price_records
FROM order_items
WHERE price < 0
   OR freight_value < 0;

-- =====================================================
-- 7. REFERENTIAL INTEGRITY CHECK
-- =====================================================

SELECT COUNT(*) AS orders_without_customer
FROM orders o

LEFT JOIN customers c
    ON o.customer_id = c.customer_id

WHERE c.customer_id IS NULL;



















