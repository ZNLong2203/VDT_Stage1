package com.vdt.etl;

import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.table.api.StatementSet;

public class ProductProcessor {
    
    public static void processProductsWithSQL(StreamTableEnvironment tableEnv) {        
        StatementSet statementSet = tableEnv.createStatementSet();
        
        statementSet.addInsertSql(
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
            "    is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM products_source " +
            "WHERE product_id IS NOT NULL " +
            "  AND CHAR_LENGTH(product_id) <= 50 " +
            "  AND product_category_name IS NOT NULL " +
            "  AND CHAR_LENGTH(product_category_name) <= 100"
        );
        
        statementSet.addInsertSql(
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
        
        statementSet.execute();
        System.out.println("Products processing completed");
    }
} 