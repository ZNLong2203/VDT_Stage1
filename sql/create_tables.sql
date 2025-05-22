CREATE DATABASE IF NOT EXISTS retail;

USE retail;

CREATE TABLE retail_orders (
    order_id VARCHAR(32),
    user_id INT,
    total DOUBLE,
    created_at DATETIME,
    channel VARCHAR(16)
)
ENGINE=OLAP
DUPLICATE KEY(order_id)
DISTRIBUTED BY HASH(order_id) BUCKETS 3
PROPERTIES ("replication_num" = "1");
