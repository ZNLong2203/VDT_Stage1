CREATE DATABASE IF NOT EXISTS ecommerce_ods_error;
USE ecommerce_ods_error;

CREATE TABLE IF NOT EXISTS ods_error_log (
    error_id VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id VARCHAR(100) NOT NULL,
    error_type VARCHAR(50) NOT NULL,
    error_message VARCHAR(500) NOT NULL,
    error_timestamp DATETIME NOT NULL,
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

CREATE TABLE IF NOT EXISTS ods_customers_error (
    customer_id VARCHAR(50) NOT NULL,
    error_timestamp DATETIME NOT NULL,
    customer_unique_id VARCHAR(50),
    customer_city VARCHAR(100),
    customer_state VARCHAR(10),
    error_type VARCHAR(50) NOT NULL,
    error_message VARCHAR(500) NOT NULL,
    raw_data JSON,
    is_deleted BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PRIMARY KEY (customer_id, error_timestamp)
DISTRIBUTED BY HASH(customer_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true",
    "compression" = "LZ4"
);

SHOW TABLES; 