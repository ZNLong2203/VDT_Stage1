-- Create Error Database and Tables in StarRocks
-- Separate schema for data quality monitoring
-- Updated with PRIMARY KEY and is_deleted for soft delete functionality

-- Create Error Database
CREATE DATABASE IF NOT EXISTS ecommerce_ods_error;
USE ecommerce_ods_error;

-- Common Error Log Table (for all validation errors)
CREATE TABLE IF NOT EXISTS ods_error_log (
    error_id VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id VARCHAR(100) NOT NULL,
    error_type VARCHAR(50) NOT NULL,
    error_message VARCHAR(500) NOT NULL,
    error_timestamp DATETIME NOT NULL,
    raw_data JSON,
    retry_count INT,
    is_resolved BOOLEAN,
    is_deleted BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PRIMARY KEY (error_id)
DISTRIBUTED BY HASH(error_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true",
    "compression" = "LZ4"
);

-- Orders Error Table (failed validation orders)
CREATE TABLE IF NOT EXISTS ods_orders_error (
    order_id VARCHAR(50) NOT NULL,
    error_timestamp DATETIME NOT NULL,
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    error_type VARCHAR(50) NOT NULL,
    error_message VARCHAR(500) NOT NULL,
    raw_data JSON,
    is_deleted BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PRIMARY KEY (order_id, error_timestamp)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true",
    "compression" = "LZ4"
);

-- Order Items Error Table (failed validation order items)
CREATE TABLE IF NOT EXISTS ods_order_items_error (
    order_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50),
    error_timestamp DATETIME NOT NULL,
    price DOUBLE,
    freight_value DOUBLE,
    error_type VARCHAR(50) NOT NULL,
    error_message VARCHAR(500) NOT NULL,
    raw_data JSON,
    is_deleted BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PRIMARY KEY (order_id, product_id, error_timestamp)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true",
    "compression" = "LZ4"
);

-- Products Error Table (failed validation products)
CREATE TABLE IF NOT EXISTS ods_products_error (
    product_id VARCHAR(50) NOT NULL,
    error_timestamp DATETIME NOT NULL,
    product_category_name VARCHAR(100),
    error_type VARCHAR(50) NOT NULL,
    error_message VARCHAR(500) NOT NULL,
    raw_data JSON,
    is_deleted BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PRIMARY KEY (product_id, error_timestamp)
DISTRIBUTED BY HASH(product_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true",
    "compression" = "LZ4"
);

-- Reviews Error Table (failed validation reviews)
CREATE TABLE IF NOT EXISTS ods_reviews_error (
    order_id VARCHAR(50) NOT NULL,
    error_timestamp DATETIME NOT NULL,
    review_score INT,
    error_type VARCHAR(50) NOT NULL,
    error_message VARCHAR(500) NOT NULL,
    raw_data JSON,
    is_deleted BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PRIMARY KEY (order_id, error_timestamp)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true",
    "compression" = "LZ4"
);

-- Payments Error Table (failed validation payments)
CREATE TABLE IF NOT EXISTS ods_payments_error (
    order_id VARCHAR(50) NOT NULL,
    payment_type VARCHAR(50),
    error_timestamp DATETIME NOT NULL,
    payment_value DOUBLE,
    error_type VARCHAR(50) NOT NULL,
    error_message VARCHAR(500) NOT NULL,
    raw_data JSON,
    is_deleted BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PRIMARY KEY (order_id, payment_type, error_timestamp)
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true",
    "compression" = "LZ4"
);

-- Show created error tables
SHOW TABLES; 