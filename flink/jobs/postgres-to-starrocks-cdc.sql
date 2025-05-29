-- Flink CDC Job: PostgreSQL to StarRocks
-- This job captures CDC events from PostgreSQL and streams them to StarRocks

-- Create PostgreSQL CDC source tables
CREATE TABLE customers_source (
    id INT,
    name STRING,
    email STRING,
    created_at TIMESTAMP(3),
    updated_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = 'localhost',
    'port' = '5432',
    'username' = 'postgres',
    'password' = 'postgres',
    'database-name' = 'ecommerce',
    'schema-name' = 'public',
    'table-name' = 'customers',
    'slot.name' = 'customers_slot',
    'decoding.plugin.name' = 'pgoutput'
);

CREATE TABLE products_source (
    id INT,
    name STRING,
    price DECIMAL(10,2),
    category STRING,
    created_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
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

CREATE TABLE orders_source (
    id INT,
    customer_id INT,
    total_amount DECIMAL(10,2),
    status STRING,
    order_date TIMESTAMP(3),
    created_at TIMESTAMP(3),
    updated_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
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
    id INT,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2),
    created_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
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

-- Create StarRocks sink tables
CREATE TABLE customers_sink (
    id INT,
    name STRING,
    email STRING,
    created_at TIMESTAMP(3),
    updated_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_dw',
    'table-name' = 'customers',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

CREATE TABLE products_sink (
    id INT,
    name STRING,
    price DECIMAL(10,2),
    category STRING,
    created_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_dw',
    'table-name' = 'products',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

CREATE TABLE orders_sink (
    id INT,
    customer_id INT,
    total_amount DECIMAL(10,2),
    status STRING,
    order_date TIMESTAMP(3),
    created_at TIMESTAMP(3),
    updated_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_dw',
    'table-name' = 'orders',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

CREATE TABLE order_items_sink (
    id INT,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2),
    created_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://localhost:9030',
    'load-url' = 'localhost:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'ecommerce_dw',
    'table-name' = 'order_items',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

-- Insert CDC data into StarRocks
INSERT INTO customers_sink SELECT * FROM customers_source;
INSERT INTO products_sink SELECT * FROM products_source;
INSERT INTO orders_sink SELECT * FROM orders_source;
INSERT INTO order_items_sink SELECT * FROM order_items_source; 