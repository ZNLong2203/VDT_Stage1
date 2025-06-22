USE ecommerce_ods_clean;

DROP MATERIALIZED VIEW IF EXISTS mv_realtime_daily_metrics;
DROP MATERIALIZED VIEW IF EXISTS mv_realtime_product_performance;
DROP MATERIALIZED VIEW IF EXISTS mv_customer_lifetime_analysis;
DROP MATERIALIZED VIEW IF EXISTS mv_business_patterns;
DROP MATERIALIZED VIEW IF EXISTS mv_category_revenue_analysis;

-- 1. Realtime Dashboard: Daily Orders & Revenue (Last 7 Days)
CREATE MATERIALIZED VIEW mv_realtime_daily_metrics
DISTRIBUTED BY HASH(order_date) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    DATE(o.order_purchase_timestamp) as order_date,
    COUNT(*) as daily_orders,
    COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) as delivered_orders,
    COUNT(CASE WHEN o.order_status = 'cancelled' THEN 1 END) as cancelled_orders,
    COUNT(CASE WHEN o.order_status = 'shipped' THEN 1 END) as shipped_orders,
    COUNT(CASE WHEN o.order_status = 'processing' THEN 1 END) as processing_orders,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) as late_delivery_orders,
    COUNT(CASE WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL THEN 1 END) as total_delivered_orders,
    ROUND(SUM(p.payment_value), 2) as daily_revenue,
    ROUND(AVG(p.payment_value), 2) as avg_order_value
FROM ods_orders o
JOIN ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false AND p.is_deleted = false
GROUP BY DATE(o.order_purchase_timestamp);

-- 2. Realtime Dashboard: Top Products Performance (Last 7 Days)
CREATE MATERIALIZED VIEW mv_realtime_product_performance
DISTRIBUTED BY HASH(product_category_name) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    pr.product_category_name,
    pr.category_group,
    DATE(o.order_purchase_timestamp) as order_date,
    COUNT(*) as order_count,
    ROUND(SUM(oi.total_item_value), 2) as total_value,
    COUNT(DISTINCT pr.product_id) as unique_products,
    ROUND(AVG(oi.price), 2) as avg_item_price
FROM ods_products pr
JOIN ods_order_items oi ON pr.product_id = oi.product_id
JOIN ods_orders o ON oi.order_id = o.order_id
WHERE pr.is_deleted = false 
    AND oi.is_deleted = false 
    AND o.is_deleted = false
GROUP BY pr.product_category_name, pr.category_group, DATE(o.order_purchase_timestamp);

-- 3. Periodic Dashboard: Customer Lifetime Value Analysis
CREATE MATERIALIZED VIEW mv_customer_lifetime_analysis
DISTRIBUTED BY HASH(customer_id) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    o.customer_id,
    COUNT(o.order_id) as total_orders,
    ROUND(SUM(p.payment_value), 2) as total_spent,
    ROUND(AVG(p.payment_value), 2) as avg_order_value,
    MIN(o.order_purchase_timestamp) as first_order_date,
    MAX(o.order_purchase_timestamp) as last_order_date,
    CASE 
        WHEN SUM(p.payment_value) >= 1000 THEN 'VIP'
        WHEN SUM(p.payment_value) >= 500 THEN 'Premium'
        WHEN SUM(p.payment_value) >= 200 THEN 'Regular'
        ELSE 'Basic'
    END as customer_segment
FROM ods_orders o
JOIN ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false AND p.is_deleted = false
GROUP BY o.customer_id;

-- 4. Periodic Dashboard: Business Patterns Analysis
CREATE MATERIALIZED VIEW mv_business_patterns
DISTRIBUTED BY HASH(day_of_week) BUCKETS 7
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    DAYOFWEEK(o.order_purchase_timestamp) as day_of_week,
    CASE DAYOFWEEK(o.order_purchase_timestamp)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END as day_name,
    COUNT(o.order_id) as order_count,
    ROUND(AVG(p.payment_value), 2) as avg_order_value,
    p.payment_type,
    COUNT(*) as payment_count,
    ROUND(SUM(p.payment_value), 2) as payment_total
FROM ods_orders o
JOIN ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false AND p.is_deleted = false
GROUP BY DAYOFWEEK(o.order_purchase_timestamp), p.payment_type;

-- 5. Periodic Dashboard: Category Revenue Analysis
CREATE MATERIALIZED VIEW mv_category_revenue_analysis
DISTRIBUTED BY HASH(category_group) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    p.category_group,
    p.product_category_name,
    COUNT(DISTINCT p.product_id) as total_products,
    COUNT(oi.order_id) as total_orders,
    ROUND(SUM(oi.total_item_value), 2) as total_revenue,
    ROUND(AVG(oi.price), 2) as avg_item_price,
    COUNT(DISTINCT o.customer_id) as unique_customers
FROM ods_products p
JOIN ods_order_items oi ON p.product_id = oi.product_id
JOIN ods_orders o ON oi.order_id = o.order_id
WHERE p.is_deleted = false AND oi.is_deleted = false AND o.is_deleted = false
GROUP BY p.category_group, p.product_category_name;

-- 6. Data Quality Dashboard: Orders Error Trends (Simple MV)
USE ecommerce_ods_error;

DROP MATERIALIZED VIEW IF EXISTS mv_orders_error_trends;
DROP MATERIALIZED VIEW IF EXISTS mv_orders_error_summary;

CREATE MATERIALIZED VIEW mv_orders_error_trends
DISTRIBUTED BY HASH(error_date) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    DATE(error_timestamp) as error_date,
    'orders' as table_name,
    COUNT(*) as error_count,
    error_type,
    error_message
FROM ods_orders_error 
WHERE is_deleted = false
GROUP BY DATE(error_timestamp), error_type, error_message;

-- 7. Data Quality Dashboard: Orders Error Summary (Simple MV)
CREATE MATERIALIZED VIEW mv_orders_error_summary
DISTRIBUTED BY HASH(table_name) BUCKETS 6
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    'orders' as table_name,
    COUNT(*) as total_errors,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 24 HOUR THEN 1 END) as errors_24h,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 2 HOUR THEN 1 END) as errors_2h,
    MAX(error_timestamp) as last_error_time
FROM ods_orders_error 
WHERE is_deleted = false;

CREATE MATERIALIZED VIEW mv_order_items_error_trends
DISTRIBUTED BY HASH(error_date) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    DATE(error_timestamp) as error_date,
    'order_items' as table_name,
    COUNT(*) as error_count,
    error_type,
    error_message
FROM ods_order_items_error 
WHERE is_deleted = false
GROUP BY DATE(error_timestamp), error_type, error_message;

CREATE MATERIALIZED VIEW mv_order_items_error_summary
DISTRIBUTED BY HASH(table_name) BUCKETS 1
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    'order_items' as table_name,
    COUNT(*) as total_errors,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 24 HOUR THEN 1 END) as errors_24h,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 2 HOUR THEN 1 END) as errors_2h,
    MAX(error_timestamp) as last_error_time
FROM ods_order_items_error 
WHERE is_deleted = false;

CREATE MATERIALIZED VIEW mv_products_error_trends
DISTRIBUTED BY HASH(error_date) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    DATE(error_timestamp) as error_date,
    'products' as table_name,
    COUNT(*) as error_count,
    error_type,
    error_message
FROM ods_products_error 
WHERE is_deleted = false
GROUP BY DATE(error_timestamp), error_type, error_message;

CREATE MATERIALIZED VIEW mv_products_error_summary
DISTRIBUTED BY HASH(table_name) BUCKETS 1
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    'products' as table_name,
    COUNT(*) as total_errors,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 24 HOUR THEN 1 END) as errors_24h,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 2 HOUR THEN 1 END) as errors_2h,
    MAX(error_timestamp) as last_error_time
FROM ods_products_error 
WHERE is_deleted = false;

CREATE MATERIALIZED VIEW mv_reviews_error_trends
DISTRIBUTED BY HASH(error_date) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    DATE(error_timestamp) as error_date,
    'reviews' as table_name,
    COUNT(*) as error_count,
    error_type,
    error_message
FROM ods_reviews_error 
WHERE is_deleted = false
GROUP BY DATE(error_timestamp), error_type, error_message;

CREATE MATERIALIZED VIEW mv_reviews_error_summary
DISTRIBUTED BY HASH(table_name) BUCKETS 1
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    'reviews' as table_name,
    COUNT(*) as total_errors,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 24 HOUR THEN 1 END) as errors_24h,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 2 HOUR THEN 1 END) as errors_2h,
    MAX(error_timestamp) as last_error_time
FROM ods_reviews_error 
WHERE is_deleted = false;

CREATE MATERIALIZED VIEW mv_payments_error_trends
DISTRIBUTED BY HASH(error_date) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    DATE(error_timestamp) as error_date,
    'payments' as table_name,
    COUNT(*) as error_count,
    error_type,
    error_message
FROM ods_payments_error 
WHERE is_deleted = false
GROUP BY DATE(error_timestamp), error_type, error_message;

CREATE MATERIALIZED VIEW mv_payments_error_summary
DISTRIBUTED BY HASH(table_name) BUCKETS 1
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    'payments' as table_name,
    COUNT(*) as total_errors,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 24 HOUR THEN 1 END) as errors_24h,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 2 HOUR THEN 1 END) as errors_2h,
    MAX(error_timestamp) as last_error_time
FROM ods_payments_error 
WHERE is_deleted = false;

CREATE MATERIALIZED VIEW mv_customers_error_trends
DISTRIBUTED BY HASH(error_date) BUCKETS 10
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    DATE(error_timestamp) as error_date,
    'customers' as table_name,
    COUNT(*) as error_count,
    error_type,
    error_message
FROM ods_customers_error 
WHERE is_deleted = false
GROUP BY DATE(error_timestamp), error_type, error_message;

CREATE MATERIALIZED VIEW mv_customers_error_summary
DISTRIBUTED BY HASH(table_name) BUCKETS 1
REFRESH ASYNC EVERY(INTERVAL 1 MINUTE)
PROPERTIES (
    "replication_num" = "1",
    "storage_medium" = "SSD"
)
AS
SELECT 
    'customers' as table_name,
    COUNT(*) as total_errors,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 24 HOUR THEN 1 END) as errors_24h,
    COUNT(CASE WHEN error_timestamp >= NOW() - INTERVAL 2 HOUR THEN 1 END) as errors_2h,
    MAX(error_timestamp) as last_error_time
FROM ods_customers_error 
WHERE is_deleted = false;

-- Show created materialized views
USE ecommerce_ods_clean;
SHOW MATERIALIZED VIEWS;

USE ecommerce_ods_error;
SHOW MATERIALIZED VIEWS;
