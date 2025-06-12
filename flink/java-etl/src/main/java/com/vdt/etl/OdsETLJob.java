package com.vdt.etl;

import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.Table;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.types.Row;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Enhanced ODS ETL Job with Java-based Data Validation
 * 
 * Fresher-friendly approach:
 * - Easy to understand validation logic
 * - Clear separation of clean vs error data
 * - Good for learning Java and Flink
 */
public class OdsETLJob {

    public static void main(String[] args) throws Exception {
        
        // Setup Flink environment
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);
        
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(
            env, EnvironmentSettings.newInstance().inStreamingMode().build()
        );
        
        System.out.println("=== Starting ODS ETL Job with Java Validation ===");
        
        // 1. Create source tables (PostgreSQL CDC)
        createSourceTables(tableEnv);
        
        // 2. Create sink tables (StarRocks clean + error tables)
        createSinkTables(tableEnv);
        
        // 3. Process each table with Java validation
        processOrdersWithValidation(tableEnv);
        processOrderItemsWithValidation(tableEnv);
        processProductsWithValidation(tableEnv);
        processReviewsWithValidation(tableEnv);
        processPaymentsWithValidation(tableEnv);
        
        // 4. Start the job
        System.out.println("=== ETL Job Started - Processing with Java Validation ===");
        env.execute("ODS ETL Job with Java Validation");
    }
    
    private static void createSourceTables(StreamTableEnvironment tableEnv) {
        System.out.println("Creating PostgreSQL CDC source tables...");
        
        // Orders source
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_SOURCE);
        
        // Order Items source  
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_SOURCE);
        
        // Products source
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_SOURCE);
        
        // Reviews source
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_SOURCE);
        
        // Payments source
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_SOURCE);
        
        System.out.println("✓ Source tables created");
    }
    
    private static void createSinkTables(StreamTableEnvironment tableEnv) {
        System.out.println("Creating StarRocks sink tables...");
        
        // Clean data sinks
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_SINK);
        
        // Error data sinks
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_ERROR_SINK);
        
        System.out.println("✓ Sink tables created");
    }
    
    /**
     * Process Orders with SQL-based processing (simpler approach)
     */
    private static void processOrdersWithValidation(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Orders with SQL validation...");
        
        // Clean data - insert valid records
        tableEnv.executeSql("INSERT INTO orders_sink " +
            "SELECT order_id, customer_id, order_status, order_purchase_timestamp, " +
            "       order_delivered_customer_date, order_estimated_delivery_date, " +
                    "       CAST(EXTRACT(YEAR FROM order_purchase_timestamp) AS INT) as order_year, " +
        "       CAST(EXTRACT(MONTH FROM order_purchase_timestamp) AS INT) as order_month, " +
        "       CAST(EXTRACT(DAY FROM order_purchase_timestamp) AS INT) as order_day, " +
            "       0 as delivery_delay_days, " +
            "       CASE WHEN order_status = 'delivered' THEN true ELSE false END as is_delivered " +
            "FROM orders_source " +
            "WHERE order_id IS NOT NULL AND customer_id IS NOT NULL " +
            "  AND order_status IS NOT NULL AND order_purchase_timestamp IS NOT NULL");
        
        // Error data - insert invalid records  
        tableEnv.executeSql("INSERT INTO orders_error_sink " +
            "SELECT order_id, customer_id, order_status, order_purchase_timestamp, " +
            "       order_delivered_customer_date, order_estimated_delivery_date, " +
            "       'VALIDATION_ERROR' as error_type, " +
            "       'Missing required fields' as error_message, " +
            "       CURRENT_TIMESTAMP as error_timestamp, " +
            "       CAST(order_id AS STRING) as raw_data " +
            "FROM orders_source " +
            "WHERE order_id IS NULL OR customer_id IS NULL " +
            "   OR order_status IS NULL OR order_purchase_timestamp IS NULL");
        
        System.out.println("✓ Orders processing setup completed");
    }
    
    /**
     * Process Order Items with SQL-based processing
     */
    private static void processOrderItemsWithValidation(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Order Items with SQL validation...");
        
        // Clean data - valid order items
        tableEnv.executeSql("INSERT INTO order_items_sink " +
            "SELECT order_id, product_id, price, freight_value, " +
            "       (COALESCE(price, 0) + COALESCE(freight_value, 0)) as total_item_value, " +
            "       CASE WHEN price > 100 THEN 'HIGH' " +
            "            WHEN price > 50 THEN 'MEDIUM' " +
            "            ELSE 'LOW' END as price_category " +
            "FROM order_items_source " +
            "WHERE order_id IS NOT NULL AND product_id IS NOT NULL " +
            "  AND price >= 0 AND freight_value >= 0");
        
        // Error data - invalid order items
        tableEnv.executeSql("INSERT INTO order_items_error_sink " +
            "SELECT order_id, product_id, price, freight_value, " +
            "       'VALIDATION_ERROR' as error_type, " +
            "       'Invalid order item data' as error_message, " +
            "       CURRENT_TIMESTAMP as error_timestamp, " +
            "       CAST(order_id AS STRING) as raw_data " +
            "FROM order_items_source " +
            "WHERE order_id IS NULL OR product_id IS NULL " +
            "   OR price < 0 OR freight_value < 0");
        
        System.out.println("✓ Order Items processing setup completed");
    }
    
    /**
     * Process Products, Reviews, Payments with SQL  
     */
    private static void processProductsWithValidation(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Products with SQL validation...");
        
        // Clean products
        tableEnv.executeSql("INSERT INTO products_sink " +
            "SELECT product_id, product_category_name, " +
            "       CASE WHEN LOWER(product_category_name) LIKE '%informatica%' THEN 'Electronics' " +
            "            WHEN LOWER(product_category_name) LIKE '%fashion%' THEN 'Fashion' " +
            "            WHEN LOWER(product_category_name) LIKE '%casa%' THEN 'Home' " +
            "            ELSE 'Other' END as category_group " +
            "FROM products_source " +
            "WHERE product_id IS NOT NULL AND product_category_name IS NOT NULL");
        
        // Error products
        tableEnv.executeSql("INSERT INTO products_error_sink " +
            "SELECT product_id, product_category_name, " +
            "       'VALIDATION_ERROR' as error_type, " +
            "       'Missing required product fields' as error_message, " +
            "       CURRENT_TIMESTAMP as error_timestamp, " +
            "       CAST(product_id AS STRING) as raw_data " +
            "FROM products_source " +
            "WHERE product_id IS NULL OR product_category_name IS NULL");
        
        System.out.println("✓ Products processing completed");
    }
    
    private static void processReviewsWithValidation(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Reviews with SQL validation...");
        
        // Clean reviews
        tableEnv.executeSql("INSERT INTO reviews_sink " +
            "SELECT order_id, review_score, " +
            "       CASE WHEN review_score >= 4 THEN 'Excellent' " +
            "            WHEN review_score = 3 THEN 'Good' " +
            "            WHEN review_score = 2 THEN 'Fair' " +
            "            ELSE 'Poor' END as review_category, " +
            "       CASE WHEN review_score >= 3 THEN true ELSE false END as is_positive_review " +
            "FROM reviews_source " +
            "WHERE order_id IS NOT NULL AND review_score BETWEEN 1 AND 5");
        
        // Error reviews
        tableEnv.executeSql("INSERT INTO reviews_error_sink " +
            "SELECT order_id, review_score, " +
            "       'VALIDATION_ERROR' as error_type, " +
            "       'Invalid review data or score out of range' as error_message, " +
            "       CURRENT_TIMESTAMP as error_timestamp, " +
            "       CAST(order_id AS STRING) as raw_data " +
            "FROM reviews_source " +
            "WHERE order_id IS NULL OR review_score IS NULL " +
            "   OR review_score < 1 OR review_score > 5");
        
        System.out.println("✓ Reviews processing completed");
    }
    
    private static void processPaymentsWithValidation(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Payments with SQL validation...");
        
        // Clean payments
        tableEnv.executeSql("INSERT INTO payments_sink " +
            "SELECT order_id, payment_type, payment_value, " +
            "       CASE WHEN payment_value > 1000 THEN 'High Value Payment' " +
            "            WHEN payment_value > 100 THEN 'Medium Value Payment' " +
            "            ELSE 'Low Value Payment' END as payment_category, " +
            "       CASE WHEN payment_value > 1000 THEN true ELSE false END as is_high_value " +
            "FROM payments_source " +
            "WHERE order_id IS NOT NULL AND payment_type IS NOT NULL AND payment_value > 0");
        
        // Error payments
        tableEnv.executeSql("INSERT INTO payments_error_sink " +
            "SELECT order_id, payment_type, " +
            "       CURRENT_TIMESTAMP as error_timestamp, " +
            "       payment_value, " +
            "       'VALIDATION_ERROR' as error_type, " +
            "       'Invalid payment data or negative value' as error_message, " +
            "       CAST(order_id AS STRING) as raw_data " +
            "FROM payments_source " +
            "WHERE order_id IS NULL OR payment_type IS NULL " +
            "   OR payment_value IS NULL OR payment_value <= 0");
        
        System.out.println("✓ Payments processing completed");
    }
    
} 