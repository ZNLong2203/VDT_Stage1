package com.vdt.etl;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

public class OdsETLJob {

    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.setParallelism(4); 
        env.enableCheckpointing(30000); 
        
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(
            env, EnvironmentSettings.newInstance().inStreamingMode().build()
        );
        
        System.out.println("=== Starting Production ODS ETL Job with Pure Flink SQL ===");

        createSourceTables(tableEnv);
        
        createSinkTables(tableEnv);
        
        processOrdersWithSQL(tableEnv);
        processOrderItemsWithSQL(tableEnv);
        processProductsWithSQL(tableEnv);
        processReviewsWithSQL(tableEnv);
        processPaymentsWithSQL(tableEnv);
        processCustomersWithSQL(tableEnv);
        
        System.out.println("=== Production ETL Job Completed - All SQL Pipelines Started ===");
    }
    
    private static void createSourceTables(StreamTableEnvironment tableEnv) {
        System.out.println("Creating PostgreSQL CDC source tables...");
        
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_CUSTOMERS_SOURCE);
        
        System.out.println("Source tables created");
    }
    
    private static void createSinkTables(StreamTableEnvironment tableEnv) {
        System.out.println("Creating StarRocks sink tables...");
        
        // Clean data sinks
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_CUSTOMERS_SINK);
        
        // Error data sinks
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_CUSTOMERS_ERROR_SINK);
        
        System.out.println("Sink tables created");
    }
    
    private static void processOrdersWithSQL(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Orders with optimized SQL validation...");
        
        tableEnv.executeSql(
            "INSERT INTO orders_sink " +
            "SELECT " +
            "    order_id, " +
            "    customer_id, " +
            "    order_status, " +
            "    order_purchase_timestamp, " +
            "    order_delivered_customer_date, " +
            "    order_estimated_delivery_date, " +
            "    CAST(EXTRACT(YEAR FROM order_purchase_timestamp) AS INT) as order_year, " +
            "    CAST(EXTRACT(MONTH FROM order_purchase_timestamp) AS INT) as order_month, " +
            "    CAST(EXTRACT(DAY FROM order_purchase_timestamp) AS INT) as order_day, " +
            "    0 as delivery_delay_days, " +
            "    CASE WHEN order_status = 'delivered' THEN true ELSE false END as is_delivered, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM orders_source " +
            "WHERE order_id IS NOT NULL " +
            "  AND CHAR_LENGTH(order_id) <= 50 " +
            "  AND customer_id IS NOT NULL " +
            "  AND CHAR_LENGTH(customer_id) <= 50 " +
            "  AND order_status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled') " +
            "  AND order_purchase_timestamp IS NOT NULL"
        );
        
        tableEnv.executeSql(
            "INSERT INTO orders_error_sink " +
            "SELECT " +
            "    order_id, " +
            "    customer_id, " +
            "    order_status, " +
            "    order_purchase_timestamp, " +
            "    order_delivered_customer_date, " +
            "    order_estimated_delivery_date, " +
            "    'VALIDATION_ERROR' as error_type, " +
            "    CASE " +
            "        WHEN order_id IS NULL OR CHAR_LENGTH(order_id) > 50 THEN 'Invalid order ID' " +
            "        WHEN customer_id IS NULL OR CHAR_LENGTH(customer_id) > 50 THEN 'Invalid customer ID' " +
            "        WHEN order_status NOT IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled') THEN 'Invalid order status' " +
            "        WHEN order_purchase_timestamp IS NULL THEN 'Missing timestamp' " +
            "        ELSE 'Unknown validation error' " +
            "    END as error_message, " +
            "    CURRENT_TIMESTAMP as error_timestamp, " +
            "    CONCAT('{\"order_id\":\"', COALESCE(order_id, 'null'), '\"}') as raw_data, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM orders_source " +
            "WHERE NOT (order_id IS NOT NULL " +
            "      AND CHAR_LENGTH(order_id) <= 50 " +
            "      AND customer_id IS NOT NULL " +
            "      AND CHAR_LENGTH(customer_id) <= 50 " +
            "      AND order_status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled') " +
            "      AND order_purchase_timestamp IS NOT NULL)"
        );
        
        System.out.println("✓ Orders processing with SQL optimization completed");
    }
    
    private static void processOrderItemsWithSQL(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Order Items with optimized SQL validation...");
        
        tableEnv.executeSql(
            "INSERT INTO order_items_sink " +
            "SELECT " +
            "    order_id, " +
            "    product_id, " +
            "    price, " +
            "    freight_value, " +
            "    (COALESCE(price, 0) + COALESCE(freight_value, 0)) as total_item_value, " +
            "    CASE " +
            "        WHEN price > 100 THEN 'HIGH' " +
            "        WHEN price > 50 THEN 'MEDIUM' " +
            "        ELSE 'LOW' " +
            "    END as price_category, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM order_items_source " +
            "WHERE order_id IS NOT NULL " +
            "  AND CHAR_LENGTH(order_id) <= 50 " +
            "  AND product_id IS NOT NULL " +
            "  AND CHAR_LENGTH(product_id) <= 50 " +
            "  AND price IS NOT NULL " +
            "  AND price >= 0 " +
            "  AND price <= 10000 " +
            "  AND freight_value IS NOT NULL " +
            "  AND freight_value >= 0 " +
            "  AND freight_value <= 10000"
        );
        
        tableEnv.executeSql(
            "INSERT INTO order_items_error_sink " +
            "SELECT " +
            "    order_id, " +
            "    product_id, " +
            "    price, " +
            "    freight_value, " +
            "    'VALIDATION_ERROR' as error_type, " +
            "    CASE " +
            "        WHEN order_id IS NULL OR CHAR_LENGTH(order_id) > 50 THEN 'Invalid order ID' " +
            "        WHEN product_id IS NULL OR CHAR_LENGTH(product_id) > 50 THEN 'Invalid product ID' " +
            "        WHEN price IS NULL OR price < 0 OR price > 10000 THEN 'Invalid price' " +
            "        WHEN freight_value IS NULL OR freight_value < 0 OR freight_value > 10000 THEN 'Invalid freight value' " +
            "        ELSE 'Unknown validation error' " +
            "    END as error_message, " +
            "    CURRENT_TIMESTAMP as error_timestamp, " +
            "    CONCAT('{\"order_id\":\"', COALESCE(order_id, 'null'), '\"}') as raw_data, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM order_items_source " +
            "WHERE NOT (order_id IS NOT NULL " +
            "      AND CHAR_LENGTH(order_id) <= 50 " +
            "      AND product_id IS NOT NULL " +
            "      AND CHAR_LENGTH(product_id) <= 50 " +
            "      AND price IS NOT NULL " +
            "      AND price >= 0 " +
            "      AND price <= 10000 " +
            "      AND freight_value IS NOT NULL " +
            "      AND freight_value >= 0 " +
            "      AND freight_value <= 10000)"
        );
        
        System.out.println("Order Items processing with SQL optimization completed");
    }
    
    private static void processProductsWithSQL(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Products with optimized SQL validation...");
        
        tableEnv.executeSql(
            "INSERT INTO products_sink " +
            "SELECT " +
            "    product_id, " +
            "    product_category_name, " +
            "    CASE " +
            "        WHEN LOWER(product_category_name) LIKE '%informatica%' OR LOWER(product_category_name) LIKE '%eletronic%' THEN 'Electronics' " +
            "        WHEN LOWER(product_category_name) LIKE '%fashion%' OR LOWER(product_category_name) LIKE '%moda%' THEN 'Fashion' " +
            "        WHEN LOWER(product_category_name) LIKE '%casa%' OR LOWER(product_category_name) LIKE '%home%' THEN 'Home' " +
            "        WHEN LOWER(product_category_name) LIKE '%esporte%' OR LOWER(product_category_name) LIKE '%sport%' THEN 'Sports' " +
            "        ELSE 'Other' " +
            "    END as category_group, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM products_source " +
            "WHERE product_id IS NOT NULL " +
            "  AND CHAR_LENGTH(product_id) <= 50 " +
            "  AND product_category_name IS NOT NULL " +
            "  AND CHAR_LENGTH(product_category_name) <= 100"
        );
        
        tableEnv.executeSql(
            "INSERT INTO products_error_sink " +
            "SELECT " +
            "    product_id, " +
            "    product_category_name, " +
            "    'VALIDATION_ERROR' as error_type, " +
            "    CASE " +
            "        WHEN product_id IS NULL OR CHAR_LENGTH(product_id) > 50 THEN 'Invalid product ID' " +
            "        WHEN product_category_name IS NULL OR CHAR_LENGTH(product_category_name) > 100 THEN 'Invalid category name' " +
            "        ELSE 'Unknown validation error' " +
            "    END as error_message, " +
            "    CURRENT_TIMESTAMP as error_timestamp, " +
            "    CONCAT('{\"product_id\":\"', COALESCE(product_id, 'null'), '\"}') as raw_data, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM products_source " +
            "WHERE NOT (product_id IS NOT NULL " +
            "      AND CHAR_LENGTH(product_id) <= 50 " +
            "      AND product_category_name IS NOT NULL " +
            "      AND CHAR_LENGTH(product_category_name) <= 100)"
        );
        
        System.out.println("Products processing with SQL optimization completed");
    }
    
    private static void processReviewsWithSQL(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Reviews with optimized SQL validation...");
        
        tableEnv.executeSql(
            "INSERT INTO reviews_sink " +
            "SELECT " +
            "    order_id, " +
            "    review_score, " +
            "    CASE " +
            "        WHEN review_score >= 4 THEN 'Excellent' " +
            "        WHEN review_score = 3 THEN 'Good' " +
            "        WHEN review_score = 2 THEN 'Fair' " +
            "        ELSE 'Poor' " +
            "    END as review_category, " +
            "    CASE WHEN review_score >= 3 THEN true ELSE false END as is_positive_review, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM reviews_source " +
            "WHERE order_id IS NOT NULL " +
            "  AND CHAR_LENGTH(order_id) <= 50 " +
            "  AND review_score IS NOT NULL " +
            "  AND review_score >= 1 " +
            "  AND review_score <= 5"
        );
        
        tableEnv.executeSql(
            "INSERT INTO reviews_error_sink " +
            "SELECT " +
            "    order_id, " +
            "    review_score, " +
            "    'VALIDATION_ERROR' as error_type, " +
            "    CASE " +
            "        WHEN order_id IS NULL OR CHAR_LENGTH(order_id) > 50 THEN 'Invalid order ID' " +
            "        WHEN review_score IS NULL OR review_score < 1 OR review_score > 5 THEN 'Invalid review score (must be 1-5)' " +
            "        ELSE 'Unknown validation error' " +
            "    END as error_message, " +
            "    CURRENT_TIMESTAMP as error_timestamp, " +
            "    CONCAT('{\"order_id\":\"', COALESCE(order_id, 'null'), '\"}') as raw_data, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM reviews_source " +
            "WHERE NOT (order_id IS NOT NULL " +
            "      AND CHAR_LENGTH(order_id) <= 50 " +
            "      AND review_score IS NOT NULL " +
            "      AND review_score >= 1 " +
            "      AND review_score <= 5)"
        );
        
        System.out.println("Reviews processing with SQL optimization completed");
    }
    
    private static void processPaymentsWithSQL(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Payments with optimized SQL validation...");
        
        tableEnv.executeSql(
            "INSERT INTO payments_sink " +
            "SELECT " +
            "    order_id, " +
            "    payment_type, " +
            "    payment_value, " +
            "    CASE " +
            "        WHEN payment_value > 1000 THEN 'High Value Payment' " +
            "        WHEN payment_value > 100 THEN 'Medium Value Payment' " +
            "        ELSE 'Low Value Payment' " +
            "    END as payment_category, " +
            "    CASE WHEN payment_value > 1000 THEN true ELSE false END as is_high_value, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM payments_source " +
            "WHERE order_id IS NOT NULL " +
            "  AND CHAR_LENGTH(order_id) <= 50 " +
            "  AND payment_type IN ('credit_card', 'debit_card', 'voucher', 'boleto') " +
            "  AND payment_value IS NOT NULL " +
            "  AND payment_value > 0 " +
            "  AND payment_value <= 50000"
        );
        
        tableEnv.executeSql(
            "INSERT INTO payments_error_sink " +
            "SELECT " +
            "    order_id, " +
            "    payment_type, " +
            "    CURRENT_TIMESTAMP as error_timestamp, " +
            "    payment_value, " +
            "    'VALIDATION_ERROR' as error_type, " +
            "    CASE " +
            "        WHEN order_id IS NULL OR CHAR_LENGTH(order_id) > 50 THEN 'Invalid order ID' " +
            "        WHEN payment_type NOT IN ('credit_card', 'debit_card', 'voucher', 'boleto') THEN 'Invalid payment type' " +
            "        WHEN payment_value IS NULL OR payment_value <= 0 THEN 'Invalid payment value' " +
            "        WHEN payment_value > 50000 THEN 'Payment value too high' " +
            "        ELSE 'Unknown validation error' " +
            "    END as error_message, " +
            "    CONCAT('{\"order_id\":\"', COALESCE(order_id, 'null'), '\"}') as raw_data, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM payments_source " +
            "WHERE NOT (order_id IS NOT NULL " +
            "      AND CHAR_LENGTH(order_id) <= 50 " +
            "      AND payment_type IN ('credit_card', 'debit_card', 'voucher', 'boleto') " +
            "      AND payment_value IS NOT NULL " +
            "      AND payment_value > 0 " +
            "      AND payment_value <= 50000)"
        );
        
        System.out.println("Payments processing with SQL optimization completed");
    }
    
    private static void processCustomersWithSQL(StreamTableEnvironment tableEnv) {
        System.out.println("Processing Customers with optimized SQL validation...");
        
        tableEnv.executeSql(
            "INSERT INTO customers_sink " +
            "SELECT " +
            "    customer_id, " +
            "    customer_unique_id, " +
            "    customer_city, " +
            "    customer_state, " +
            "    CASE " +
            "        WHEN customer_state IN ('SP', 'RJ', 'MG') THEN 'Southeast' " +
            "        WHEN customer_state IN ('RS', 'SC', 'PR') THEN 'South' " +
            "        WHEN customer_state IN ('GO', 'MT', 'MS', 'DF') THEN 'Center-West' " +
            "        WHEN customer_state IN ('BA', 'SE', 'AL', 'PE', 'PB', 'RN', 'CE', 'PI', 'MA') THEN 'Northeast' " +
            "        WHEN customer_state IN ('AM', 'RR', 'AP', 'PA', 'TO', 'RO', 'AC') THEN 'North' " +
            "        ELSE 'Unknown' " +
            "    END as state_region, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM customers_source " +
            "WHERE customer_id IS NOT NULL " +
            "  AND CHAR_LENGTH(customer_id) <= 50 " +
            "  AND customer_unique_id IS NOT NULL " +
            "  AND CHAR_LENGTH(customer_unique_id) <= 50 " +
            "  AND customer_city IS NOT NULL " +
            "  AND CHAR_LENGTH(customer_city) <= 100 " +
            "  AND customer_state IS NOT NULL " +
            "  AND CHAR_LENGTH(customer_state) = 2"
        );
        
        tableEnv.executeSql(
            "INSERT INTO customers_error_sink " +
            "SELECT " +
            "    customer_id, " +
            "    customer_unique_id, " +
            "    customer_city, " +
            "    customer_state, " +
            "    'VALIDATION_ERROR' as error_type, " +
            "    CASE " +
            "        WHEN customer_id IS NULL OR CHAR_LENGTH(customer_id) > 50 THEN 'Invalid customer ID' " +
            "        WHEN customer_unique_id IS NULL OR CHAR_LENGTH(customer_unique_id) > 50 THEN 'Invalid customer unique ID' " +
            "        WHEN customer_city IS NULL OR CHAR_LENGTH(customer_city) > 100 THEN 'Invalid city name' " +
            "        WHEN customer_state IS NULL OR CHAR_LENGTH(customer_state) <> 2 THEN 'Invalid state code (must be 2 characters)' " +
            "        ELSE 'Unknown validation error' " +
            "    END as error_message, " +
            "    CURRENT_TIMESTAMP as error_timestamp, " +
            "    CONCAT('{\"customer_id\":\"', COALESCE(customer_id, 'null'), '\"}') as raw_data, " +
            "    false as is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM customers_source " +
            "WHERE NOT (customer_id IS NOT NULL " +
            "      AND CHAR_LENGTH(customer_id) <= 50 " +
            "      AND customer_unique_id IS NOT NULL " +
            "      AND CHAR_LENGTH(customer_unique_id) <= 50 " +
            "      AND customer_city IS NOT NULL " +
            "      AND CHAR_LENGTH(customer_city) <= 100 " +
            "      AND customer_state IS NOT NULL " +
            "      AND CHAR_LENGTH(customer_state) = 2)"
        );
        
        System.out.println("Customers processing with SQL optimization completed");
    }
    
    public static void softDeleteOrderSQL(StreamTableEnvironment tableEnv, String orderId) {
        System.out.println("Performing optimized soft delete for order: " + orderId);
        
        if (orderId != null && orderId.trim().length() > 0 && orderId.length() <= 50) {
            tableEnv.executeSql(
                "UPDATE orders_sink " +
                "SET is_deleted = true, updated_at = CURRENT_TIMESTAMP " +
                "WHERE order_id = '" + orderId + "'"
            );
            System.out.println("Soft delete completed for order: " + orderId);
        } else {
            System.err.println("Soft delete validation failed for order: " + orderId);
        }
    }
    
    public static void createOptimizedAnalyticsViews(StreamTableEnvironment tableEnv) {
        System.out.println("Creating optimized analytics views...");
        
        tableEnv.executeSql(
            "CREATE VIEW active_orders_analytics AS " +
            "SELECT * FROM orders_sink " +
            "WHERE is_deleted = false " +
            "  AND order_purchase_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1' YEAR"
        );
        
        System.out.println("Optimized analytics views created");
    }
} 