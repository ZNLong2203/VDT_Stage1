-- Create ODS Clean Database and Tables in StarRocks
-- These tables store cleaned and enriched data from ODS Raw

-- Create ODS Clean Database
CREATE DATABASE IF NOT EXISTS ecommerce_ods_clean;
USE ecommerce_ods_clean;

-- Orders Clean Table (enriched with business metrics)
CREATE TABLE IF NOT EXISTS ods_orders (
    order_id VARCHAR(50) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    order_year INT NOT NULL,
    order_month INT NOT NULL,
    order_day INT NOT NULL,
    delivery_delay_days INT,
    is_delivered BOOLEAN NOT NULL
)
DUPLICATE KEY (order_id)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);

-- Order Items Clean Table (enriched with pricing metrics)
CREATE TABLE IF NOT EXISTS ods_order_items (
    order_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    price DOUBLE NOT NULL,
    freight_value DOUBLE NOT NULL,
    total_item_value DOUBLE NOT NULL,
    price_category VARCHAR(10) NOT NULL
)
DUPLICATE KEY (order_id, product_id)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);

-- Products Clean Table (enriched with category grouping)
CREATE TABLE IF NOT EXISTS ods_products (
    product_id VARCHAR(50) NOT NULL,
    product_category_name VARCHAR(100) NOT NULL,
    category_group VARCHAR(50) NOT NULL
)
DUPLICATE KEY (product_id)
DISTRIBUTED BY HASH(product_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);

-- Reviews Clean Table (enriched with sentiment analysis)
CREATE TABLE IF NOT EXISTS ods_reviews (
    order_id VARCHAR(50) NOT NULL,
    review_score INT NOT NULL,
    review_category VARCHAR(20) NOT NULL,
    is_positive_review BOOLEAN NOT NULL
)
DUPLICATE KEY (order_id)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);

-- Payments Clean Table (enriched with payment categorization)
CREATE TABLE IF NOT EXISTS ods_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_value DOUBLE NOT NULL,
    payment_category VARCHAR(30) NOT NULL,
    is_high_value BOOLEAN NOT NULL
)
DUPLICATE KEY (order_id, payment_type)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);

-- Show created clean data tables
SHOW TABLES;

-- Display clean table structures for verification
DESCRIBE ods_orders;
DESCRIBE ods_order_items;
DESCRIBE ods_products;
DESCRIBE ods_reviews;
DESCRIBE ods_payments;