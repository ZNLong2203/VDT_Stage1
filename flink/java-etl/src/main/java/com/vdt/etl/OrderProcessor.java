package com.vdt.etl;

import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.table.api.StatementSet;

public class OrderProcessor {
    
    public static void processOrdersWithSQL(StreamTableEnvironment tableEnv) {        
        StatementSet statementSet = tableEnv.createStatementSet();
        
        statementSet.addInsertSql(
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
            "    CASE " +
            "        WHEN order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL " +
            "        THEN TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) " +
            "        ELSE NULL " +
            "    END as delivery_delay_days, " +
            "    CASE WHEN order_status = 'delivered' THEN true ELSE false END as is_delivered, " +
            "    is_deleted, " +
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
        
        statementSet.addInsertSql(
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
        
        statementSet.execute();
        System.out.println("Orders processing completed");
    }
} 