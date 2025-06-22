package com.vdt.etl;

import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.table.api.StatementSet;

public class CustomerProcessor {
    
    public static void processCustomersWithSQL(StreamTableEnvironment tableEnv) {
        StatementSet statementSet = tableEnv.createStatementSet();
        
        statementSet.addInsertSql(
            "INSERT INTO customers_sink " +
            "SELECT " +
            "    customer_id, " +
            "    customer_unique_id, " +
            "    customer_city, " +
            "    customer_state, " +
            "    CASE " +
            "        WHEN customer_state IN ('SP', 'RJ', 'MG') THEN 'Southeast' " +
            "        WHEN customer_state IN ('RS', 'SC', 'PR') THEN 'South' " +
            "        WHEN customer_state IN ('BA', 'SE', 'AL', 'PE', 'PB', 'RN', 'CE', 'PI', 'MA') THEN 'Northeast' " +
            "        WHEN customer_state IN ('GO', 'MT', 'MS', 'DF') THEN 'Central-West' " +
            "        ELSE 'North' " +
            "    END as state_region, " +
            "    is_deleted, " +
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
            "  AND CHAR_LENGTH(customer_state) <= 10"
        );
        
        statementSet.addInsertSql(
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
            "        WHEN customer_city IS NULL OR CHAR_LENGTH(customer_city) > 100 THEN 'Invalid customer city' " +
            "        WHEN customer_state IS NULL OR CHAR_LENGTH(customer_state) > 10 THEN 'Invalid customer state' " +
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
            "      AND CHAR_LENGTH(customer_state) <= 10)"
        );

        statementSet.execute();
        System.out.println("Customers processing completed");
    }
} 