SELECT 
    error_date,
    SUM(error_count) as total_errors
FROM (
    SELECT 
        DATE(error_timestamp) as error_date,
        COUNT(*) as error_count
    FROM ecommerce_ods_error.ods_orders_error 
    WHERE error_timestamp >= CURDATE() - INTERVAL 7 DAY
      AND is_deleted = false
    GROUP BY DATE(error_timestamp)
    
    UNION ALL
    
    SELECT 
        DATE(error_timestamp) as error_date,
        COUNT(*) as error_count
    FROM ecommerce_ods_error.ods_order_items_error 
    WHERE error_timestamp >= CURDATE() - INTERVAL 7 DAY
      AND is_deleted = false
    GROUP BY DATE(error_timestamp)
    
    UNION ALL
    
    SELECT 
        DATE(error_timestamp) as error_date,
        COUNT(*) as error_count
    FROM ecommerce_ods_error.ods_products_error 
    WHERE error_timestamp >= CURDATE() - INTERVAL 7 DAY
      AND is_deleted = false
    GROUP BY DATE(error_timestamp)
    
    UNION ALL
    
    SELECT 
        DATE(error_timestamp) as error_date,
        COUNT(*) as error_count
    FROM ecommerce_ods_error.ods_reviews_error 
    WHERE error_timestamp >= CURDATE() - INTERVAL 7 DAY
      AND is_deleted = false
    GROUP BY DATE(error_timestamp)
    
    UNION ALL
    
    SELECT 
        DATE(error_timestamp) as error_date,
        COUNT(*) as error_count
    FROM ecommerce_ods_error.ods_payments_error 
    WHERE error_timestamp >= CURDATE() - INTERVAL 7 DAY
      AND is_deleted = false
    GROUP BY DATE(error_timestamp)
    
    UNION ALL
    
    SELECT 
        DATE(error_timestamp) as error_date,
        COUNT(*) as error_count
    FROM ecommerce_ods_error.ods_customers_error 
    WHERE error_timestamp >= CURDATE() - INTERVAL 7 DAY
      AND is_deleted = false
    GROUP BY DATE(error_timestamp)
) all_errors
GROUP BY error_date
ORDER BY error_date DESC;
-- Shows error trends from ALL error tables - will show 0 if no errors
-- Use as LINE CHART in Metabase
-- Daily Error Count

SELECT 
    'Orders Errors' as table_name,
    COUNT(*) as error_count
FROM ecommerce_ods_error.ods_orders_error 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

UNION ALL

SELECT 
    'Order Items Errors' as table_name,
    COUNT(*) as error_count
FROM ecommerce_ods_error.ods_order_items_error 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

UNION ALL

SELECT 
    'Products Errors' as table_name,
    COUNT(*) as error_count
FROM ecommerce_ods_error.ods_products_error 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

UNION ALL

SELECT 
    'Reviews Errors' as table_name,
    COUNT(*) as error_count
FROM ecommerce_ods_error.ods_reviews_error 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

UNION ALL

SELECT 
    'Payments Errors' as table_name,
    COUNT(*) as error_count
FROM ecommerce_ods_error.ods_payments_error 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

UNION ALL

SELECT 
    'Customers Errors' as table_name,
    COUNT(*) as error_count
FROM ecommerce_ods_error.ods_customers_error 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

ORDER BY error_count DESC;
-- Shows which tables have most errors - ALL error tables included
-- Use as BAR CHART in Metabase
-- Error Types Distribution

SELECT 
    error_type,
    error_message,
    error_timestamp,
    order_id as record_id
FROM ecommerce_ods_error.ods_orders_error 
WHERE error_timestamp >= NOW() - INTERVAL 2 HOUR
  AND is_deleted = false
ORDER BY error_timestamp DESC
LIMIT 10;
-- Shows actual error messages from orders table
-- Use as TABLE in Metabase
-- Recent Error Messages

SELECT 
    ROUND(
        (SELECT COUNT(*) FROM ecommerce_ods_clean.ods_orders WHERE DATE(created_at) = CURDATE()) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM ecommerce_ods_clean.ods_orders WHERE DATE(created_at) = CURDATE()) + 
               (SELECT COUNT(*) FROM ecommerce_ods_error.ods_orders_error WHERE DATE(error_timestamp) = CURDATE()), 0),
        2
    ) as success_rate_percentage,
    (SELECT COUNT(*) FROM ecommerce_ods_clean.ods_orders WHERE DATE(created_at) = CURDATE()) as clean_records,
    (SELECT COUNT(*) FROM ecommerce_ods_error.ods_orders_error WHERE DATE(error_timestamp) = CURDATE()) as error_records; 
-- Overall success rate percentage
-- Use as NUMBER CARD in Metabase
-- Overall success rate percentage
