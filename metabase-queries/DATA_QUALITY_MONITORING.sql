-- ===================================================================
-- CHART 1: ERROR OVERVIEW - Daily Error Count by Table
-- ===================================================================
-- Shows error trends over time by table
-- Use as LINE CHART in Metabase

SELECT 
    DATE(error_timestamp) as error_date,
    table_name,
    COUNT(*) as error_count
FROM ecommerce_ods_error.ods_error_log 
WHERE error_timestamp >= CURDATE() - INTERVAL 7 DAY
  AND is_deleted = false
GROUP BY DATE(error_timestamp), table_name
ORDER BY error_date DESC, error_count DESC;

-- ===================================================================
-- CHART 2: ERROR TYPES BREAKDOWN - Current Error Status
-- ===================================================================
-- Shows what types of errors are happening most
-- Use as PIE CHART in Metabase

SELECT 
    error_type,
    COUNT(*) as error_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as percentage
FROM ecommerce_ods_error.ods_error_log 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false
GROUP BY error_type
ORDER BY error_count DESC;

-- ===================================================================
-- CHART 3: PIPELINE HEALTH SUMMARY - Clean vs Error Records
-- ===================================================================
-- Shows overall pipeline health - how much data is clean vs errors
-- Use as BAR CHART in Metabase

SELECT 
    'Clean Orders' as data_type,
    COUNT(*) as record_count,
    'success' as status
FROM ecommerce_ods_clean.ods_orders 
WHERE created_at >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

UNION ALL

SELECT 
    'Error Orders' as data_type,
    COUNT(*) as record_count,
    'error' as status
FROM ecommerce_ods_error.ods_orders_error 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

UNION ALL

SELECT 
    'Clean Order Items' as data_type,
    COUNT(*) as record_count,
    'success' as status
FROM ecommerce_ods_clean.ods_order_items 
WHERE created_at >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

UNION ALL

SELECT 
    'Error Order Items' as data_type,
    COUNT(*) as record_count,
    'error' as status
FROM ecommerce_ods_error.ods_order_items_error 
WHERE error_timestamp >= CURDATE() - INTERVAL 1 DAY
  AND is_deleted = false

ORDER BY data_type;

-- ===================================================================
-- ADDITIONAL SIMPLE QUERIES FOR MONITORING
-- ===================================================================

-- Query 4: Recent Error Details (for table/list view)
SELECT 
    table_name,
    error_type,
    error_message,
    error_timestamp,
    record_id
FROM ecommerce_ods_error.ods_error_log 
WHERE error_timestamp >= NOW() - INTERVAL 2 HOUR
  AND is_deleted = false
ORDER BY error_timestamp DESC
LIMIT 20;

-- Query 5: Error Rate by Hour (for monitoring real-time issues)
SELECT 
    HOUR(error_timestamp) as error_hour,
    COUNT(*) as hourly_errors
FROM ecommerce_ods_error.ods_error_log 
WHERE DATE(error_timestamp) = CURDATE()
  AND is_deleted = false
GROUP BY HOUR(error_timestamp)
ORDER BY error_hour;

-- Query 6: Data Processing Success Rate (percentage)
SELECT 
    ROUND(
        (SELECT COUNT(*) FROM ecommerce_ods_clean.ods_orders WHERE DATE(created_at) = CURDATE()) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM ecommerce_ods_clean.ods_orders WHERE DATE(created_at) = CURDATE()) + 
               (SELECT COUNT(*) FROM ecommerce_ods_error.ods_orders_error WHERE DATE(error_timestamp) = CURDATE()), 0),
        2
    ) as success_rate_percentage,
    (SELECT COUNT(*) FROM ecommerce_ods_clean.ods_orders WHERE DATE(created_at) = CURDATE()) as clean_records,
    (SELECT COUNT(*) FROM ecommerce_ods_error.ods_orders_error WHERE DATE(error_timestamp) = CURDATE()) as error_records; 