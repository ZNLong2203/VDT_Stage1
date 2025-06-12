package com.vdt.etl;

/**
 * SQL DDL Statements for Flink ETL
 * 
 * Contains all source and sink table definitions
 * Compatible with Java 11 (no text blocks)
 */
public class SqlQueries {
    
    // =============================================================================
    // SOURCE TABLES - Read from PostgreSQL CDC
    // =============================================================================
    
    public static final String CREATE_ORDERS_SOURCE = 
        "CREATE TABLE orders_source (" +
        "    order_id STRING," +
        "    customer_id STRING," +
        "    order_status STRING," +
        "    order_purchase_timestamp TIMESTAMP(3)," +
        "    order_delivered_customer_date TIMESTAMP(3)," +
        "    order_estimated_delivery_date TIMESTAMP(3)," +
        "    PRIMARY KEY (order_id) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'postgres-cdc'," +
        "    'hostname' = 'localhost'," +
        "    'port' = '5432'," +
        "    'username' = 'postgres'," +
        "    'password' = 'postgres'," +
        "    'database-name' = 'ecommerce'," +
        "    'schema-name' = 'public'," +
        "    'table-name' = 'orders'," +
        "    'slot.name' = 'etl_orders_slot'," +
        "    'decoding.plugin.name' = 'pgoutput'" +
        ")";
    
    public static final String CREATE_ORDER_ITEMS_SOURCE = 
        "CREATE TABLE order_items_source (" +
        "    order_id STRING," +
        "    product_id STRING," +
        "    price DOUBLE," +
        "    freight_value DOUBLE," +
        "    PRIMARY KEY (order_id, product_id) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'postgres-cdc'," +
        "    'hostname' = 'localhost'," +
        "    'port' = '5432'," +
        "    'username' = 'postgres'," +
        "    'password' = 'postgres'," +
        "    'database-name' = 'ecommerce'," +
        "    'schema-name' = 'public'," +
        "    'table-name' = 'order_items'," +
        "    'slot.name' = 'etl_order_items_slot'," +
        "    'decoding.plugin.name' = 'pgoutput'" +
        ")";
    
    public static final String CREATE_PRODUCTS_SOURCE = 
        "CREATE TABLE products_source (" +
        "    product_id STRING," +
        "    product_category_name STRING," +
        "    PRIMARY KEY (product_id) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'postgres-cdc'," +
        "    'hostname' = 'localhost'," +
        "    'port' = '5432'," +
        "    'username' = 'postgres'," +
        "    'password' = 'postgres'," +
        "    'database-name' = 'ecommerce'," +
        "    'schema-name' = 'public'," +
        "    'table-name' = 'products'," +
        "    'slot.name' = 'etl_products_slot'," +
        "    'decoding.plugin.name' = 'pgoutput'" +
        ")";
    
    public static final String CREATE_REVIEWS_SOURCE = 
        "CREATE TABLE reviews_source (" +
        "    order_id STRING," +
        "    review_score INT," +
        "    PRIMARY KEY (order_id) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'postgres-cdc'," +
        "    'hostname' = 'localhost'," +
        "    'port' = '5432'," +
        "    'username' = 'postgres'," +
        "    'password' = 'postgres'," +
        "    'database-name' = 'ecommerce'," +
        "    'schema-name' = 'public'," +
        "    'table-name' = 'reviews'," +
        "    'slot.name' = 'etl_reviews_slot'," +
        "    'decoding.plugin.name' = 'pgoutput'" +
        ")";
    
    public static final String CREATE_PAYMENTS_SOURCE = 
        "CREATE TABLE payments_source (" +
        "    order_id STRING," +
        "    payment_type STRING," +
        "    payment_value DOUBLE," +
        "    PRIMARY KEY (order_id, payment_type) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'postgres-cdc'," +
        "    'hostname' = 'localhost'," +
        "    'port' = '5432'," +
        "    'username' = 'postgres'," +
        "    'password' = 'postgres'," +
        "    'database-name' = 'ecommerce'," +
        "    'schema-name' = 'public'," +
        "    'table-name' = 'payments'," +
        "    'slot.name' = 'etl_payments_slot'," +
        "    'decoding.plugin.name' = 'pgoutput'" +
        ")";
    
    // =============================================================================
    // CLEAN SINK TABLES - Write clean data to StarRocks
    // =============================================================================
    
    public static final String CREATE_ORDERS_SINK = 
        "CREATE TABLE orders_sink (" +
        "    order_id STRING," +
        "    customer_id STRING," +
        "    order_status STRING," +
        "    order_purchase_timestamp TIMESTAMP(3)," +
        "    order_delivered_customer_date TIMESTAMP(3)," +
        "    order_estimated_delivery_date TIMESTAMP(3)," +
        "    order_year INT," +
        "    order_month INT," +
        "    order_day INT," +
        "    delivery_delay_days INT," +
        "    is_delivered BOOLEAN," +
        "    PRIMARY KEY (order_id) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_clean'," +
        "    'table-name' = 'ods_orders'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'," +
        "    'sink.semantic' = 'at-least-once'," +
        "    'sink.properties.partial_update' = 'false'" +
        ")";
    
    public static final String CREATE_ORDER_ITEMS_SINK = 
        "CREATE TABLE order_items_sink (" +
        "    order_id STRING," +
        "    product_id STRING," +
        "    price DOUBLE," +
        "    freight_value DOUBLE," +
        "    total_item_value DOUBLE," +
        "    price_category STRING," +
        "    PRIMARY KEY (order_id, product_id) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_clean'," +
        "    'table-name' = 'ods_order_items'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
    
    public static final String CREATE_PRODUCTS_SINK = 
        "CREATE TABLE products_sink (" +
        "    product_id STRING," +
        "    product_category_name STRING," +
        "    category_group STRING," +
        "    PRIMARY KEY (product_id) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_clean'," +
        "    'table-name' = 'ods_products'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
    
    public static final String CREATE_REVIEWS_SINK = 
        "CREATE TABLE reviews_sink (" +
        "    order_id STRING," +
        "    review_score INT," +
        "    review_category STRING," +
        "    is_positive_review BOOLEAN," +
        "    PRIMARY KEY (order_id) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_clean'," +
        "    'table-name' = 'ods_reviews'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
    
    public static final String CREATE_PAYMENTS_SINK = 
        "CREATE TABLE payments_sink (" +
        "    order_id STRING," +
        "    payment_type STRING," +
        "    payment_value DOUBLE," +
        "    payment_category STRING," +
        "    is_high_value BOOLEAN," +
        "    PRIMARY KEY (order_id, payment_type) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_clean'," +
        "    'table-name' = 'ods_payments'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
    
    // =============================================================================
    // ERROR SINK TABLES - Write invalid data to error tables
    // =============================================================================
    
    public static final String CREATE_ORDERS_ERROR_SINK = 
        "CREATE TABLE orders_error_sink (" +
        "    order_id STRING," +
        "    customer_id STRING," +
        "    order_status STRING," +
        "    order_purchase_timestamp TIMESTAMP(3)," +
        "    order_delivered_customer_date TIMESTAMP(3)," +
        "    order_estimated_delivery_date TIMESTAMP(3)," +
        "    error_type STRING," +
        "    error_message STRING," +
        "    error_timestamp TIMESTAMP(3)," +
        "    raw_data STRING" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_error'," +
        "    'table-name' = 'ods_orders_error'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
    
    public static final String CREATE_ORDER_ITEMS_ERROR_SINK = 
        "CREATE TABLE order_items_error_sink (" +
        "    order_id STRING," +
        "    product_id STRING," +
        "    price DOUBLE," +
        "    freight_value DOUBLE," +
        "    error_type STRING," +
        "    error_message STRING," +
        "    error_timestamp TIMESTAMP(3)," +
        "    raw_data STRING" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_error'," +
        "    'table-name' = 'ods_order_items_error'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
    
    public static final String CREATE_PRODUCTS_ERROR_SINK = 
        "CREATE TABLE products_error_sink (" +
        "    product_id STRING," +
        "    product_category_name STRING," +
        "    error_type STRING," +
        "    error_message STRING," +
        "    error_timestamp TIMESTAMP(3)," +
        "    raw_data STRING" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_error'," +
        "    'table-name' = 'ods_products_error'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
    
    public static final String CREATE_REVIEWS_ERROR_SINK = 
        "CREATE TABLE reviews_error_sink (" +
        "    order_id STRING," +
        "    review_score INT," +
        "    error_type STRING," +
        "    error_message STRING," +
        "    error_timestamp TIMESTAMP(3)," +
        "    raw_data STRING" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_error'," +
        "    'table-name' = 'ods_reviews_error'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
    
    public static final String CREATE_PAYMENTS_ERROR_SINK = 
        "CREATE TABLE payments_error_sink (" +
        "    order_id STRING," +
        "    payment_type STRING," +
        "    error_timestamp TIMESTAMP(3)," +
        "    payment_value DOUBLE," +
        "    error_type STRING," +
        "    error_message STRING," +
        "    raw_data STRING," +
        "    PRIMARY KEY (order_id, payment_type, error_timestamp) NOT ENFORCED" +
        ") WITH (" +
        "    'connector' = 'starrocks'," +
        "    'jdbc-url' = 'jdbc:mysql://localhost:9030'," +
        "    'load-url' = 'localhost:8030'," +
        "    'username' = 'root'," +
        "    'password' = ''," +
        "    'database-name' = 'ecommerce_ods_error'," +
        "    'table-name' = 'ods_payments_error'," +
        "    'sink.properties.format' = 'json'," +
        "    'sink.properties.strip_outer_array' = 'true'," +
        "    'sink.buffer-flush.max-rows' = '64000'," +
        "    'sink.buffer-flush.interval-ms' = '5000'" +
        ")";
} 