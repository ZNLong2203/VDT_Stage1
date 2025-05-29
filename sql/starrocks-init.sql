-- StarRocks Data Warehouse Schema
-- Create database for the data warehouse
CREATE DATABASE IF NOT EXISTS ecommerce_dw;
USE ecommerce_dw;

-- Drop existing tables if they exist to recreate with correct schema
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- Customers table in StarRocks
CREATE TABLE IF NOT EXISTS customers (
    id INT NOT NULL,
    name STRING,
    email STRING,
    created_at DATETIME,
    updated_at DATETIME
) ENGINE=OLAP
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT"
);

-- Products table in StarRocks
CREATE TABLE IF NOT EXISTS products (
    id INT NOT NULL,
    name STRING,
    price DECIMAL(10,2),
    category STRING,
    created_at DATETIME
) ENGINE=OLAP
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT"
);

-- Orders table in StarRocks
CREATE TABLE IF NOT EXISTS orders (
    id INT NOT NULL,
    customer_id INT,
    total_amount DECIMAL(10,2),
    status STRING,
    order_date DATETIME,
    created_at DATETIME,
    updated_at DATETIME
) ENGINE=OLAP
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT"
);

-- Order items table in StarRocks
CREATE TABLE IF NOT EXISTS order_items (
    id INT NOT NULL,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2),
    created_at DATETIME
) ENGINE=OLAP
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT"
);

-- Create analytical views for Metabase
-- Customer summary view
CREATE VIEW IF NOT EXISTS customer_summary AS
SELECT 
    c.id,
    c.name,
    c.email,
    COUNT(o.id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as total_spent,
    MAX(o.order_date) as last_order_date
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.email;

-- Product performance view
CREATE VIEW IF NOT EXISTS product_performance AS
SELECT 
    p.id,
    p.name,
    p.category,
    p.price,
    COUNT(oi.id) as times_ordered,
    COALESCE(SUM(oi.quantity), 0) as total_quantity_sold,
    COALESCE(SUM(oi.quantity * oi.price), 0) as total_revenue
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.name, p.category, p.price;

-- Daily sales summary view
CREATE VIEW IF NOT EXISTS daily_sales AS
SELECT 
    DATE(o.order_date) as sale_date,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as total_revenue,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    AVG(o.total_amount) as avg_order_value
FROM orders o
GROUP BY DATE(o.order_date)
ORDER BY sale_date DESC;

-- Order details view for comprehensive analysis
CREATE VIEW IF NOT EXISTS order_details AS
SELECT 
    o.id as order_id,
    o.order_date,
    o.status,
    o.total_amount,
    c.name as customer_name,
    c.email as customer_email,
    COUNT(oi.id) as item_count,
    SUM(oi.quantity) as total_items
FROM orders o
JOIN customers c ON o.customer_id = c.id
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.order_date, o.status, o.total_amount, c.name, c.email; 