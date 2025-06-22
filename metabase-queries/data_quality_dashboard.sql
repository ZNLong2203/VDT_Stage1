SELECT 
    error_date,
    SUM(error_count) as total_errors
FROM (
    SELECT error_date, SUM(error_count) as error_count FROM ecommerce_ods_error.mv_orders_error_trends 
    WHERE error_date >= CURDATE() - INTERVAL 7 DAY GROUP BY error_date
    
    UNION ALL
    
    SELECT error_date, SUM(error_count) as error_count FROM ecommerce_ods_error.mv_order_items_error_trends 
    WHERE error_date >= CURDATE() - INTERVAL 7 DAY GROUP BY error_date
    
    UNION ALL
    
    SELECT error_date, SUM(error_count) as error_count FROM ecommerce_ods_error.mv_products_error_trends 
    WHERE error_date >= CURDATE() - INTERVAL 7 DAY GROUP BY error_date
    
    UNION ALL
    
    SELECT error_date, SUM(error_count) as error_count FROM ecommerce_ods_error.mv_reviews_error_trends 
    WHERE error_date >= CURDATE() - INTERVAL 7 DAY GROUP BY error_date
    
    UNION ALL
    
    SELECT error_date, SUM(error_count) as error_count FROM ecommerce_ods_error.mv_payments_error_trends 
    WHERE error_date >= CURDATE() - INTERVAL 7 DAY GROUP BY error_date
    
    UNION ALL
    
    SELECT error_date, SUM(error_count) as error_count FROM ecommerce_ods_error.mv_customers_error_trends 
    WHERE error_date >= CURDATE() - INTERVAL 7 DAY GROUP BY error_date
) all_errors
GROUP BY error_date
ORDER BY error_date DESC;
-- Shows error trends from ALL error tables - will show 0 if no errors
-- Use as LINE CHART in Metabase
-- Daily Error Count

SELECT 
    table_name,
    errors_24h as error_count
FROM (
    SELECT table_name, errors_24h FROM ecommerce_ods_error.mv_orders_error_summary
    UNION ALL
    SELECT table_name, errors_24h FROM ecommerce_ods_error.mv_order_items_error_summary
    UNION ALL
    SELECT table_name, errors_24h FROM ecommerce_ods_error.mv_products_error_summary
    UNION ALL
    SELECT table_name, errors_24h FROM ecommerce_ods_error.mv_reviews_error_summary
    UNION ALL
    SELECT table_name, errors_24h FROM ecommerce_ods_error.mv_payments_error_summary
    UNION ALL
    SELECT table_name, errors_24h FROM ecommerce_ods_error.mv_customers_error_summary
) all_table_errors
WHERE errors_24h > 0
ORDER BY error_count DESC;
-- Shows which tables have most errors - ALL error tables included
-- Use as BAR CHART in Metabase
-- Error Types Distribution

SELECT 
    error_type,
    error_message,
    table_name,
    error_date,
    error_count as frequency
FROM (
    SELECT error_type, error_message, table_name, error_date, error_count FROM ecommerce_ods_error.mv_orders_error_trends
    WHERE error_date >= CURDATE() - INTERVAL 1 DAY
    UNION ALL
    SELECT error_type, error_message, table_name, error_date, error_count FROM ecommerce_ods_error.mv_order_items_error_trends
    WHERE error_date >= CURDATE() - INTERVAL 1 DAY
    UNION ALL
    SELECT error_type, error_message, table_name, error_date, error_count FROM ecommerce_ods_error.mv_products_error_trends
    WHERE error_date >= CURDATE() - INTERVAL 1 DAY
    UNION ALL
    SELECT error_type, error_message, table_name, error_date, error_count FROM ecommerce_ods_error.mv_reviews_error_trends
    WHERE error_date >= CURDATE() - INTERVAL 1 DAY
    UNION ALL
    SELECT error_type, error_message, table_name, error_date, error_count FROM ecommerce_ods_error.mv_payments_error_trends
    WHERE error_date >= CURDATE() - INTERVAL 1 DAY
    UNION ALL
    SELECT error_type, error_message, table_name, error_date, error_count FROM ecommerce_ods_error.mv_customers_error_trends
    WHERE error_date >= CURDATE() - INTERVAL 1 DAY
) all_recent_errors
ORDER BY error_date DESC, error_count DESC
LIMIT 20;
-- Shows actual error messages from orders table
-- Use as TABLE in Metabase
-- Recent Error Messages

SELECT 
    ROUND(
        (SELECT SUM(daily_orders) FROM ecommerce_ods_clean.mv_realtime_daily_metrics WHERE order_date = CURDATE()) * 100.0 /
        NULLIF((SELECT SUM(daily_orders) FROM ecommerce_ods_clean.mv_realtime_daily_metrics WHERE order_date = CURDATE()) + 
               (SELECT SUM(errors_24h) FROM (
                   SELECT errors_24h FROM ecommerce_ods_error.mv_orders_error_summary
                   UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_order_items_error_summary
                   UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_products_error_summary
                   UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_reviews_error_summary
                   UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_payments_error_summary
                   UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_customers_error_summary
               ) all_errors), 0),
        2
    ) as success_rate_percentage,
    (SELECT SUM(daily_orders) FROM ecommerce_ods_clean.mv_realtime_daily_metrics WHERE order_date = CURDATE()) as clean_records,
    (SELECT SUM(errors_24h) FROM (
        SELECT errors_24h FROM ecommerce_ods_error.mv_orders_error_summary
        UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_order_items_error_summary
        UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_products_error_summary
        UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_reviews_error_summary
        UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_payments_error_summary
        UNION ALL SELECT errors_24h FROM ecommerce_ods_error.mv_customers_error_summary
    ) all_errors) as error_records;
-- Overall success rate percentage
-- Use as NUMBER CARD in Metabase

SELECT 
    COUNT(*) as critical_tables_count
FROM (
    SELECT 'orders' as table_name, COUNT(*) as errors_24h 
    FROM ecommerce_ods_error.ods_orders_error 
    WHERE error_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) AND is_deleted = false
    
    UNION ALL 
    SELECT 'order_items' as table_name, COUNT(*) as errors_24h 
    FROM ecommerce_ods_error.ods_order_items_error 
    WHERE error_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) AND is_deleted = false
    
    UNION ALL 
    SELECT 'products' as table_name, COUNT(*) as errors_24h 
    FROM ecommerce_ods_error.ods_products_error 
    WHERE error_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) AND is_deleted = false
    
    UNION ALL 
    SELECT 'reviews' as table_name, COUNT(*) as errors_24h 
    FROM ecommerce_ods_error.ods_reviews_error 
    WHERE error_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) AND is_deleted = false
    
    UNION ALL 
    SELECT 'payments' as table_name, COUNT(*) as errors_24h 
    FROM ecommerce_ods_error.ods_payments_error 
    WHERE error_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) AND is_deleted = false
    
    UNION ALL 
    SELECT 'customers' as table_name, COUNT(*) as errors_24h 
    FROM ecommerce_ods_error.ods_customers_error 
    WHERE error_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) AND is_deleted = false
) all_table_status
WHERE errors_24h > 20;
-- Trigger to send email daily error in 24h