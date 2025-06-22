package com.vdt.etl;

import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.table.api.StatementSet;

public class ReviewProcessor {
    
    public static void processReviewsWithSQL(StreamTableEnvironment tableEnv) {        
        StatementSet statementSet = tableEnv.createStatementSet();
        
        statementSet.addInsertSql(
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
            "    is_deleted, " +
            "    CURRENT_TIMESTAMP as created_at, " +
            "    CURRENT_TIMESTAMP as updated_at " +
            "FROM reviews_source " +
            "WHERE order_id IS NOT NULL " +
            "  AND CHAR_LENGTH(order_id) <= 50 " +
            "  AND review_score IS NOT NULL " +
            "  AND review_score >= 1 " +
            "  AND review_score <= 5"
        );
        
        statementSet.addInsertSql(
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
        
        statementSet.execute();
        System.out.println("Reviews processing completed");
    }
} 