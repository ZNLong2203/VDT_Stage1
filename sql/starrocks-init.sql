-- StarRocks Data Warehouse Schema (5 Selected Tables Only)
-- Create database for the data warehouse
CREATE DATABASE IF NOT EXISTS ecommerce_ods_raw;
USE ecommerce_ods_raw;

-- Drop existing tables if they exist to recreate with correct schema
DROP TABLE IF EXISTS ods_orders_raw;
DROP TABLE IF EXISTS ods_order_items_raw;
DROP TABLE IF EXISTS ods_products_raw;
DROP TABLE IF EXISTS ods_reviews_raw;
DROP TABLE IF EXISTS ods_payments_raw;

CREATE TABLE IF NOT EXISTS ods_orders_raw (
    order_id STRING NOT NULL,
    customer_id STRING,
    order_status STRING,
    order_purchase_timestamp DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
) ENGINE=OLAP
DUPLICATE KEY(order_id)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1"
);

CREATE TABLE IF NOT EXISTS ods_order_items_raw (
    order_id STRING NOT NULL,
    product_id STRING,
    price DOUBLE,
    freight_value DOUBLE
) ENGINE=OLAP
DUPLICATE KEY(order_id, product_id)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1"
);

CREATE TABLE IF NOT EXISTS ods_products_raw (
    product_id STRING NOT NULL,
    product_category_name STRING
) ENGINE=OLAP
DUPLICATE KEY(product_id)
DISTRIBUTED BY HASH(product_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1"
);

CREATE TABLE IF NOT EXISTS ods_reviews_raw (
    order_id STRING NOT NULL,
    review_score INT
) ENGINE=OLAP
DUPLICATE KEY(order_id)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1"
);

CREATE TABLE IF NOT EXISTS ods_payments_raw (
    order_id STRING NOT NULL,
    payment_type STRING,
    payment_value DOUBLE
) ENGINE=OLAP
DUPLICATE KEY(order_id, payment_type)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1"
);

-- View: Tổng doanh thu và số đơn theo ngày
CREATE VIEW IF NOT EXISTS daily_order_summary AS
SELECT
    DATE(order_purchase_timestamp) AS order_date,
    COUNT(order_id) AS total_orders
FROM ods_orders_raw
GROUP BY DATE(order_purchase_timestamp)
ORDER BY order_date DESC;

-- View: Tổng doanh thu theo loại thanh toán
CREATE VIEW IF NOT EXISTS payment_by_type AS
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS num_orders,
    SUM(payment_value) AS total_revenue
FROM ods_payments_raw
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- View: Review trung bình theo trạng thái đơn
CREATE VIEW IF NOT EXISTS review_by_status AS
SELECT
    o.order_status,
    AVG(r.review_score) AS avg_review_score,
    COUNT(*) AS num_reviews
FROM ods_orders_raw o
JOIN ods_reviews_raw r ON o.order_id = r.order_id
GROUP BY o.order_status; 