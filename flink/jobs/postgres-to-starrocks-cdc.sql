-- Flink CDC Job: PostgreSQL to StarRocks (Olist Selected Tables & Columns)
-- This job captures CDC events from PostgreSQL and streams selected data to StarRocks

-- Create PostgreSQL CDC source tables (selected columns only)

CREATE TABLE orders_source (
    order_id STRING,
    customer_id STRING,
    order_status STRING,
    order_purchase_timestamp TIMESTAMP(3),
    order_delivered_customer_date TIMESTAMP(3),
    order_estimated_delivery_date TIMESTAMP(3),
    PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = 'localhost',
    'port' = '5432',
    'username' = 'postgres',
    'password' = 'postgres',
    'database-name' = 'ecommerce',
    'schema-name' = 'public',
    'table-name' = 'orders',
    'slot.name' = 'orders_slot',
    'decoding.plugin.name' = 'pgoutput'
);

CREATE TABLE order_items_source (
    order_id STRING,
    product_id STRING,
    price DOUBLE,
    freight_value DOUBLE,
    PRIMARY KEY (order_id, product_id) NOT ENFORCED
) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = 'localhost',
    'port' = '5432',
    'username' = 'postgres',
    'password' = 'postgres',
    'database-name' = 'ecommerce',
    'schema-name' = 'public',
    'table-name' = 'order_items',
    'slot.name' = 'order_items_slot',
    'decoding.plugin.name' = 'pgoutput'
);

CREATE TABLE products_source (
    product_id STRING,
    product_category_name STRING,
    PRIMARY KEY (product_id) NOT ENFORCED
) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = 'localhost',
    'port' = '5432',
    'username' = 'postgres',
    'password' = 'postgres',
    'database-name' = 'ecommerce',
    'schema-name' = 'public',
    'table-name' = 'products',
    'slot.name' = 'products_slot',
    'decoding.plugin.name' = 'pgoutput'
);

CREATE TABLE reviews_source (
    order_id STRING,
    review_score INT,
    PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = 'localhost',
    'port' = '5432',
    'username' = 'postgres',
    'password' = 'postgres',
    'database-name' = 'ecommerce',
    'schema-name' = 'public',
    'table-name' = 'reviews',
    'slot.name' = 'reviews_slot',
    'decoding.plugin.name' = 'pgoutput'
);

CREATE TABLE payments_source (
    order_id STRING,
    payment_type STRING,
    payment_value DOUBLE,
    PRIMARY KEY (order_id, payment_type) NOT ENFORCED
) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = 'localhost',
    'port' = '5432',
    'username' = 'postgres',
    'password' = 'postgres',
    'database-name' = 'ecommerce',
    'schema-name' = 'public',
    'table-name' = 'payments',
    'slot.name' = 'payments_slot',
    'decoding.plugin.name' = 'pgoutput'
);

-- Create StarRocks sink tables (matching ODS schema)

CREATE TABLE orders_sink (
    order_id STRING,
    customer_id STRING,
    order_status STRING,
    order_purchase_timestamp TIMESTAMP(3),
    order_delivered_customer_date TIMESTAMP(3),
    order_estimated_delivery_date TIMESTAMP(3),
    PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_ods_raw',
    'table-name' = 'ods_orders_raw',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

CREATE TABLE order_items_sink (
    order_id STRING,
    product_id STRING,
    price DOUBLE,
    freight_value DOUBLE,
    PRIMARY KEY (order_id, product_id) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_ods_raw',
    'table-name' = 'ods_order_items_raw',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

CREATE TABLE products_sink (
    product_id STRING,
    product_category_name STRING,
    PRIMARY KEY (product_id) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_ods_raw',
    'table-name' = 'ods_products_raw',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

CREATE TABLE reviews_sink (
    order_id STRING,
    review_score INT,
    PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_ods_raw',
    'table-name' = 'ods_reviews_raw',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

CREATE TABLE payments_sink (
    order_id STRING,
    payment_type STRING,
    payment_value DOUBLE,
    PRIMARY KEY (order_id, payment_type) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_ods_raw',
    'table-name' = 'ods_payments_raw',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

-- Insert CDC data into StarRocks (selected columns only)
INSERT INTO orders_sink SELECT * FROM orders_source;
INSERT INTO order_items_sink SELECT * FROM order_items_source;
INSERT INTO products_sink SELECT * FROM products_source;
INSERT INTO reviews_sink SELECT * FROM reviews_source;
INSERT INTO payments_sink SELECT * FROM payments_source; 