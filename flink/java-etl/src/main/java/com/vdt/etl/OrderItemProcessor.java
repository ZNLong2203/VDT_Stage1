package com.vdt.etl;

import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.table.api.StatementSet;

public class OrderItemProcessor {
    
    public static void processOrderItemsWithSQL(StreamTableEnvironment tableEnv) {        
        StatementSet statementSet = tableEnv.createStatementSet();
        
        statementSet.addInsertSql(
            "INSERT INTO order_items_sink " +
            "SELECT " +
            "    order_id, " +
            "    product_id, " +
            "    price, " +
            "    freight_value, " +
            "    (price + freight_value) as total_item_value, " +
            "    CASE " +
            "        WHEN price > 500 THEN 'Premium' " +
            "        WHEN price > 100 THEN 'Standard' " +
            "        ELSE 'Budget' " +
            "    END as price_category, " +
            "    is_deleted, " +
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
        
        statementSet.addInsertSql(
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
        
        statementSet.execute();
        System.out.println("Order Items processing completed");
    }
} 