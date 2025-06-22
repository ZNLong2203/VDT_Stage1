SELECT 
    order_date,
    daily_orders
FROM ecommerce_ods_clean.mv_realtime_daily_metrics 
WHERE order_date >= CURDATE() - INTERVAL 7 DAY
ORDER BY order_date DESC;
-- CHART SETUP: Line Chart - X: order_date, Y: daily_orders
-- Daily Orders Count

SELECT 
    order_date as revenue_date,
    daily_revenue
FROM ecommerce_ods_clean.mv_realtime_daily_metrics 
WHERE order_date >= CURDATE() - INTERVAL 7 DAY
ORDER BY order_date DESC;
-- CHART SETUP: Line Chart - X: revenue_date, Y: daily_revenue
-- Daily Revenue

SELECT 
    product_category_name,
    category_group,
    SUM(order_count) as total_orders,
    ROUND(SUM(total_value), 2) as total_value
FROM ecommerce_ods_clean.mv_realtime_product_performance
WHERE order_date >= CURDATE() - INTERVAL 7 DAY
GROUP BY product_category_name, category_group
ORDER BY total_orders DESC
LIMIT 5;
-- CHART SETUP: Bar Chart - X: product_category_name, Y: order_count
-- Top 5 Best Selling Products

SELECT 
    'Late Delivery Rate' as metric,
    SUM(late_delivery_orders) as late_orders,
    SUM(total_delivered_orders) as total_delivered_orders,
    COALESCE(
        ROUND(
            SUM(late_delivery_orders) * 100.0 / 
            NULLIF(SUM(total_delivered_orders), 0), 
            2
        ), 
        0
    ) as late_delivery_rate_percent
FROM ecommerce_ods_clean.mv_realtime_daily_metrics 
WHERE order_date >= CURDATE() - INTERVAL 7 DAY;
-- CHART SETUP: Number Card showing late_delivery_rate_percent
-- Late Delivery Rate

SELECT 
    'Cancellation Rate' as metric,
    SUM(cancelled_orders) as cancelled_orders,
    SUM(daily_orders) as total_orders,
    COALESCE(
        ROUND(
            SUM(cancelled_orders) * 100.0 / 
            NULLIF(SUM(daily_orders), 0), 
            2
        ), 
        0
    ) as cancellation_rate_percent
FROM ecommerce_ods_clean.mv_realtime_daily_metrics 
WHERE order_date >= CURDATE() - INTERVAL 7 DAY;
-- CHART SETUP: Number Card showing cancellation_rate_percent
-- Cancellation Rate

SELECT 
    'delivered' as order_status,
    SUM(delivered_orders) as order_count,
    ROUND(SUM(delivered_orders) * 100.0 / SUM(daily_orders), 1) as percentage
FROM ecommerce_ods_clean.mv_realtime_daily_metrics 
WHERE order_date >= CURDATE() - INTERVAL 7 DAY

UNION ALL

SELECT 
    'cancelled' as order_status,
    SUM(cancelled_orders) as order_count,
    ROUND(SUM(cancelled_orders) * 100.0 / SUM(daily_orders), 1) as percentage
FROM ecommerce_ods_clean.mv_realtime_daily_metrics 
WHERE order_date >= CURDATE() - INTERVAL 7 DAY

UNION ALL

SELECT 
    'shipped' as order_status,
    SUM(shipped_orders) as order_count,
    ROUND(SUM(shipped_orders) * 100.0 / SUM(daily_orders), 1) as percentage
FROM ecommerce_ods_clean.mv_realtime_daily_metrics 
WHERE order_date >= CURDATE() - INTERVAL 7 DAY

UNION ALL

SELECT 
    'processing' as order_status,
    SUM(processing_orders) as order_count,
    ROUND(SUM(processing_orders) * 100.0 / SUM(daily_orders), 1) as percentage
FROM ecommerce_ods_clean.mv_realtime_daily_metrics 
WHERE order_date >= CURDATE() - INTERVAL 7 DAY

ORDER BY order_count DESC;
-- CHART SETUP: Pie Chart - showing order status distribution
-- Order Status Distribution
