SELECT 
    DATE(order_purchase_timestamp) as order_date,
    COUNT(*) as daily_orders
FROM ecommerce_ods_clean.ods_orders 
WHERE is_deleted = false
  AND order_purchase_timestamp >= CURDATE() - INTERVAL 7 DAY
GROUP BY DATE(order_purchase_timestamp)
ORDER BY order_date DESC;
-- CHART SETUP: Line Chart - X: order_date, Y: daily_orders
-- Daily Orders Count

SELECT 
    DATE(o.order_purchase_timestamp) as revenue_date,
    ROUND(SUM(p.payment_value), 2) as daily_revenue
FROM ecommerce_ods_clean.ods_orders o
JOIN ecommerce_ods_clean.ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false 
  AND p.is_deleted = false
  AND o.order_purchase_timestamp >= CURDATE() - INTERVAL 7 DAY
GROUP BY DATE(o.order_purchase_timestamp)
ORDER BY revenue_date DESC;
-- CHART SETUP: Line Chart - X: revenue_date, Y: daily_revenue
-- Daily Revenue

SELECT 
    pr.product_category_name,
    pr.category_group,
    COUNT(*) as order_count,
    ROUND(SUM(oi.total_item_value), 2) as total_value
FROM ecommerce_ods_clean.ods_order_items oi
JOIN ecommerce_ods_clean.ods_products pr ON oi.product_id = pr.product_id
JOIN ecommerce_ods_clean.ods_orders o ON oi.order_id = o.order_id
WHERE oi.is_deleted = false 
  AND pr.is_deleted = false
  AND o.is_deleted = false
  AND o.order_purchase_timestamp >= CURDATE() - INTERVAL 7 DAY
GROUP BY pr.product_category_name, pr.category_group
ORDER BY order_count DESC
LIMIT 5;
-- CHART SETUP: Bar Chart - X: product_category_name, Y: order_count
-- Top 5 Best Selling Products

SELECT 
    'Late Delivery Rate' as metric,
    COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) as late_orders,
    COUNT(*) as total_delivered_orders,
    COALESCE(
        ROUND(
            COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) * 100.0 / 
            NULLIF(COUNT(*), 0), 
            2
        ), 
        0
    ) as late_delivery_rate_percent
FROM ecommerce_ods_clean.ods_orders 
WHERE is_deleted = false
  AND order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_purchase_timestamp >= CURDATE() - INTERVAL 7 DAY;
-- CHART SETUP: Number Card showing late_delivery_rate_percent
-- Late Delivery Rate

SELECT 
    'Cancellation Rate' as metric,
    COUNT(CASE WHEN order_status = 'cancelled' THEN 1 END) as cancelled_orders,
    COUNT(*) as total_orders,
    COALESCE(
        ROUND(
            COUNT(CASE WHEN order_status = 'cancelled' THEN 1 END) * 100.0 / 
            NULLIF(COUNT(*), 0), 
            2
        ), 
        0
    ) as cancellation_rate_percent
FROM ecommerce_ods_clean.ods_orders 
WHERE is_deleted = false AND order_purchase_timestamp >= CURDATE() - INTERVAL 7 DAY;
-- CHART SETUP: Number Card showing cancellation_rate_percent
-- Cancellation Rate

SELECT 
    order_status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as percentage
FROM ecommerce_ods_clean.ods_orders 
WHERE is_deleted = false
  AND order_purchase_timestamp >= CURDATE() - INTERVAL 7 DAY
GROUP BY order_status
ORDER BY order_count DESC;
-- CHART SETUP: Pie Chart - showing order status distribution
-- Order Status Distribution
