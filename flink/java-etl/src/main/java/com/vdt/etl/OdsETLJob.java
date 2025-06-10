package com.vdt.etl;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.configuration.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Main ETL Job to transform data from ODS Raw to ODS Clean tables
 * Processes: orders, order_items, products, reviews, payments
 */
public class OdsETLJob {
    
    private static final Logger LOG = LoggerFactory.getLogger(OdsETLJob.class);
    
    // StarRocks connection parameters
    private static final String STARROCKS_JDBC_URL = "jdbc:mysql://localhost:9030";
    private static final String STARROCKS_LOAD_URL = "localhost:8030";
    private static final String STARROCKS_USERNAME = "root";
    private static final String STARROCKS_PASSWORD = "";
    private static final String DATABASE_RAW = "ecommerce_ods_raw";
    private static final String DATABASE_CLEAN = "ecommerce_ods_clean";
    
    public static void main(String[] args) throws Exception {
        LOG.info("Starting ODS ETL Job - Raw to Clean transformation");
        
        // Setup Flink execution environment
        Configuration conf = new Configuration();
        conf.setString("execution.checkpointing.interval", "30s");
        conf.setString("execution.checkpointing.mode", "EXACTLY_ONCE");
        conf.setString("state.backend", "filesystem");
        conf.setString("state.checkpoints.dir", "file:///tmp/flink-checkpoints");
        
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment(conf);
        env.enableCheckpointing(30000); // 30 seconds
        env.setParallelism(2);
        
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);
        
        try {
            // Create source tables (ODS Raw)
            createSourceTables(tableEnv);
            
            // Create sink tables (ODS Clean)
            createSinkTables(tableEnv);
            
            // Execute ETL transformations
            executeETLTransformations(tableEnv);
            
            LOG.info("All ETL jobs submitted successfully");
            
        } catch (Exception e) {
            LOG.error("Failed to execute ETL job", e);
            throw e;
        }
    }
    
    private static void createSourceTables(StreamTableEnvironment tableEnv) {
        LOG.info("Creating source tables from ODS Raw...");
        
        // Orders Raw Source
        tableEnv.executeSql(
            "CREATE TABLE orders_raw_source (" +
            "  order_id STRING," +
            "  customer_id STRING," +
            "  order_status STRING," +
            "  order_purchase_timestamp TIMESTAMP(3)," +
            "  order_delivered_customer_date TIMESTAMP(3)," +
            "  order_estimated_delivery_date TIMESTAMP(3)," +
            "  PRIMARY KEY (order_id) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_RAW + "'," +
            "  'table-name' = 'ods_orders_raw'," +
            "  'scan.connect.timeout-ms' = '30000'," +
            "  'scan.params.keep-alive-min' = '10'" +
            ")"
        );
        
        // Order Items Raw Source
        tableEnv.executeSql(
            "CREATE TABLE order_items_raw_source (" +
            "  order_id STRING," +
            "  product_id STRING," +
            "  price DOUBLE," +
            "  freight_value DOUBLE," +
            "  PRIMARY KEY (order_id, product_id) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_RAW + "'," +
            "  'table-name' = 'ods_order_items_raw'," +
            "  'scan.connect.timeout-ms' = '30000'," +
            "  'scan.params.keep-alive-min' = '10'" +
            ")"
        );
        
        // Products Raw Source
        tableEnv.executeSql(
            "CREATE TABLE products_raw_source (" +
            "  product_id STRING," +
            "  product_category_name STRING," +
            "  PRIMARY KEY (product_id) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_RAW + "'," +
            "  'table-name' = 'ods_products_raw'," +
            "  'scan.connect.timeout-ms' = '30000'," +
            "  'scan.params.keep-alive-min' = '10'" +
            ")"
        );
        
        // Reviews Raw Source
        tableEnv.executeSql(
            "CREATE TABLE reviews_raw_source (" +
            "  order_id STRING," +
            "  review_score INT," +
            "  PRIMARY KEY (order_id) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_RAW + "'," +
            "  'table-name' = 'ods_reviews_raw'," +
            "  'scan.connect.timeout-ms' = '30000'," +
            "  'scan.params.keep-alive-min' = '10'" +
            ")"
        );
        
        // Payments Raw Source
        tableEnv.executeSql(
            "CREATE TABLE payments_raw_source (" +
            "  order_id STRING," +
            "  payment_type STRING," +
            "  payment_value DOUBLE," +
            "  PRIMARY KEY (order_id, payment_type) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_RAW + "'," +
            "  'table-name' = 'ods_payments_raw'," +
            "  'scan.connect.timeout-ms' = '30000'," +
            "  'scan.params.keep-alive-min' = '10'" +
            ")"
        );
        
        LOG.info("Source tables created successfully");
    }
    
    private static void createSinkTables(StreamTableEnvironment tableEnv) {
        LOG.info("Creating sink tables for ODS Clean...");
        
        // Orders Clean Sink
        tableEnv.executeSql(
            "CREATE TABLE orders_clean_sink (" +
            "  order_id STRING," +
            "  customer_id STRING," +
            "  order_status STRING," +
            "  order_purchase_timestamp TIMESTAMP(3)," +
            "  order_delivered_customer_date TIMESTAMP(3)," +
            "  order_estimated_delivery_date TIMESTAMP(3)," +
            "  order_year INT," +
            "  order_month INT," +
            "  order_day INT," +
            "  delivery_delay_days INT," +
            "  is_delivered BOOLEAN," +
            "  PRIMARY KEY (order_id) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_CLEAN + "'," +
            "  'table-name' = 'ods_orders'," +
            "  'sink.properties.format' = 'json'," +
            "  'sink.properties.strip_outer_array' = 'true'" +
            ")"
        );
        
        // Order Items Clean Sink
        tableEnv.executeSql(
            "CREATE TABLE order_items_clean_sink (" +
            "  order_id STRING," +
            "  product_id STRING," +
            "  price DOUBLE," +
            "  freight_value DOUBLE," +
            "  total_item_value DOUBLE," +
            "  price_category STRING," +
            "  PRIMARY KEY (order_id, product_id) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_CLEAN + "'," +
            "  'table-name' = 'ods_order_items'," +
            "  'sink.properties.format' = 'json'," +
            "  'sink.properties.strip_outer_array' = 'true'" +
            ")"
        );
        
        // Products Clean Sink
        tableEnv.executeSql(
            "CREATE TABLE products_clean_sink (" +
            "  product_id STRING," +
            "  product_category_name STRING," +
            "  category_group STRING," +
            "  PRIMARY KEY (product_id) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_CLEAN + "'," +
            "  'table-name' = 'ods_products'," +
            "  'sink.properties.format' = 'json'," +
            "  'sink.properties.strip_outer_array' = 'true'" +
            ")"
        );
        
        // Reviews Clean Sink
        tableEnv.executeSql(
            "CREATE TABLE reviews_clean_sink (" +
            "  order_id STRING," +
            "  review_score INT," +
            "  review_category STRING," +
            "  is_positive_review BOOLEAN," +
            "  PRIMARY KEY (order_id) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_CLEAN + "'," +
            "  'table-name' = 'ods_reviews'," +
            "  'sink.properties.format' = 'json'," +
            "  'sink.properties.strip_outer_array' = 'true'" +
            ")"
        );
        
        // Payments Clean Sink
        tableEnv.executeSql(
            "CREATE TABLE payments_clean_sink (" +
            "  order_id STRING," +
            "  payment_type STRING," +
            "  payment_value DOUBLE," +
            "  payment_category STRING," +
            "  is_high_value BOOLEAN," +
            "  PRIMARY KEY (order_id, payment_type) NOT ENFORCED" +
            ") WITH (" +
            "  'connector' = 'starrocks'," +
            "  'jdbc-url' = '" + STARROCKS_JDBC_URL + "'," +
            "  'load-url' = '" + STARROCKS_LOAD_URL + "'," +
            "  'username' = '" + STARROCKS_USERNAME + "'," +
            "  'password' = '" + STARROCKS_PASSWORD + "'," +
            "  'database-name' = '" + DATABASE_CLEAN + "'," +
            "  'table-name' = 'ods_payments'," +
            "  'sink.properties.format' = 'json'," +
            "  'sink.properties.strip_outer_array' = 'true'" +
            ")"
        );
        
        LOG.info("Sink tables created successfully");
    }
    
    private static void executeETLTransformations(StreamTableEnvironment tableEnv) {
        LOG.info("Executing ETL transformations...");
        
        // Transform Orders with enrichment
        tableEnv.executeSql(
            "INSERT INTO orders_clean_sink " +
            "SELECT " +
            "  order_id, " +
            "  customer_id, " +
            "  UPPER(order_status) as order_status, " +
            "  order_purchase_timestamp, " +
            "  order_delivered_customer_date, " +
            "  order_estimated_delivery_date, " +
            "  EXTRACT(YEAR FROM order_purchase_timestamp) as order_year, " +
            "  EXTRACT(MONTH FROM order_purchase_timestamp) as order_month, " +
            "  EXTRACT(DAY FROM order_purchase_timestamp) as order_day, " +
            "  CASE " +
            "    WHEN order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL " +
            "    THEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) " +
            "    ELSE NULL " +
            "  END as delivery_delay_days, " +
            "  CASE " +
            "    WHEN order_status = 'delivered' THEN true " +
            "    ELSE false " +
            "  END as is_delivered " +
            "FROM orders_raw_source " +
            "WHERE order_id IS NOT NULL"
        );
        
        // Transform Order Items with enrichment
        tableEnv.executeSql(
            "INSERT INTO order_items_clean_sink " +
            "SELECT " +
            "  order_id, " +
            "  product_id, " +
            "  COALESCE(price, 0.0) as price, " +
            "  COALESCE(freight_value, 0.0) as freight_value, " +
            "  COALESCE(price, 0.0) + COALESCE(freight_value, 0.0) as total_item_value, " +
            "  CASE " +
            "    WHEN COALESCE(price, 0.0) >= 100.0 THEN 'HIGH' " +
            "    WHEN COALESCE(price, 0.0) >= 50.0 THEN 'MEDIUM' " +
            "    ELSE 'LOW' " +
            "  END as price_category " +
            "FROM order_items_raw_source " +
            "WHERE order_id IS NOT NULL AND product_id IS NOT NULL"
        );
        
        // Transform Products with categorization
        tableEnv.executeSql(
            "INSERT INTO products_clean_sink " +
            "SELECT " +
            "  product_id, " +
            "  COALESCE(product_category_name, 'unknown') as product_category_name, " +
            "  CASE " +
            "    WHEN product_category_name LIKE '%informatica%' OR product_category_name LIKE '%telefonia%' " +
            "         OR product_category_name LIKE '%eletronicos%' THEN 'Electronics' " +
            "    WHEN product_category_name LIKE '%casa%' OR product_category_name LIKE '%moveis%' " +
            "         OR product_category_name LIKE '%decoracao%' THEN 'Home & Garden' " +
            "    WHEN product_category_name LIKE '%esporte%' OR product_category_name LIKE '%fitness%' THEN 'Sports' " +
            "    WHEN product_category_name LIKE '%moda%' OR product_category_name LIKE '%roupas%' " +
            "         OR product_category_name LIKE '%calcados%' THEN 'Fashion' " +
            "    WHEN product_category_name LIKE '%beleza%' OR product_category_name LIKE '%perfumaria%' THEN 'Beauty' " +
            "    ELSE 'Others' " +
            "  END as category_group " +
            "FROM products_raw_source " +
            "WHERE product_id IS NOT NULL"
        );
        
        // Transform Reviews with sentiment analysis
        tableEnv.executeSql(
            "INSERT INTO reviews_clean_sink " +
            "SELECT " +
            "  order_id, " +
            "  COALESCE(review_score, 0) as review_score, " +
            "  CASE " +
            "    WHEN review_score >= 4 THEN 'EXCELLENT' " +
            "    WHEN review_score = 3 THEN 'GOOD' " +
            "    WHEN review_score = 2 THEN 'AVERAGE' " +
            "    WHEN review_score = 1 THEN 'POOR' " +
            "    ELSE 'UNKNOWN' " +
            "  END as review_category, " +
            "  CASE " +
            "    WHEN review_score >= 4 THEN true " +
            "    ELSE false " +
            "  END as is_positive_review " +
            "FROM reviews_raw_source " +
            "WHERE order_id IS NOT NULL"
        );
        
        // Transform Payments with categorization
        tableEnv.executeSql(
            "INSERT INTO payments_clean_sink " +
            "SELECT " +
            "  order_id, " +
            "  UPPER(COALESCE(payment_type, 'unknown')) as payment_type, " +
            "  COALESCE(payment_value, 0.0) as payment_value, " +
            "  CASE " +
            "    WHEN payment_type = 'credit_card' THEN 'CARD_PAYMENT' " +
            "    WHEN payment_type = 'boleto' THEN 'BANK_TRANSFER' " +
            "    WHEN payment_type = 'voucher' THEN 'VOUCHER_PAYMENT' " +
            "    WHEN payment_type = 'debit_card' THEN 'CARD_PAYMENT' " +
            "    ELSE 'OTHER_PAYMENT' " +
            "  END as payment_category, " +
            "  CASE " +
            "    WHEN COALESCE(payment_value, 0.0) >= 200.0 THEN true " +
            "    ELSE false " +
            "  END as is_high_value " +
            "FROM payments_raw_source " +
            "WHERE order_id IS NOT NULL AND payment_type IS NOT NULL"
        );
        
        LOG.info("ETL transformations completed successfully");
    }
} 