package com.vdt.etl;

import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.table.api.StatementSet;

public class PaymentProcessor {
    
    public static void processPaymentsWithSQL(StreamTableEnvironment tableEnv) {        
        StatementSet statementSet = tableEnv.createStatementSet();
        
        statementSet.addInsertSql(
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
            "    is_deleted, " +
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
        
        statementSet.addInsertSql(
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
        
        statementSet.execute();
        System.out.println("Payments processing completed");
    }
} 