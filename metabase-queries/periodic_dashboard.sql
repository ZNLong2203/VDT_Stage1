SELECT 
    customer_segment,
    COUNT(*) as customers,
    ROUND(AVG(total_spent), 2) as avg_clv,
    ROUND(AVG(order_count), 2) as avg_orders,
    ROUND(SUM(total_spent), 2) as segment_total_revenue
FROM (
    SELECT 
        o.customer_id,
        CASE 
            WHEN SUM(p.payment_value) >= 1000 THEN 'VIP'
            WHEN SUM(p.payment_value) >= 500 THEN 'Premium'
            WHEN SUM(p.payment_value) >= 200 THEN 'Regular'
            ELSE 'Basic'
        END as customer_segment,
        SUM(p.payment_value) as total_spent,
        COUNT(o.order_id) as order_count
    FROM ods_orders o
    JOIN ods_payments p ON o.order_id = p.order_id
    WHERE o.is_deleted = false 
        AND p.is_deleted = false
    GROUP BY o.customer_id
) customer_analysis
GROUP BY customer_segment
ORDER BY avg_clv DESC;
-- CHART SETUP:
-- Chart Type: Table
-- Columns: customer_segment, customers, avg_clv, avg_orders, segment_total_revenue
-- Title: Customer Segmentation by Lifetime Value

SELECT 
    p.category_group,
    COUNT(DISTINCT p.product_id) as total_products,
    COUNT(oi.order_id) as total_orders,
    ROUND(SUM(oi.total_item_value), 2) as total_revenue,
    ROUND(AVG(oi.price), 2) as avg_item_price
FROM ods_products p
JOIN ods_order_items oi ON p.product_id = oi.product_id
WHERE p.is_deleted = false 
    AND oi.is_deleted = false
GROUP BY p.category_group
ORDER BY total_revenue DESC;
-- CHART SETUP:
-- Chart Type: Bar Chart
-- X-axis: category_group
-- Y-axis: total_revenue
-- Title: Revenue by Product Category

SELECT 
    DAYOFWEEK(o.order_purchase_timestamp) as day_of_week,
    CASE DAYOFWEEK(o.order_purchase_timestamp)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END as day_name,
    COUNT(o.order_id) as order_count,
    ROUND(AVG(p.payment_value), 2) as avg_order_value
FROM ods_orders o
JOIN ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false 
    AND p.is_deleted = false
GROUP BY DAYOFWEEK(o.order_purchase_timestamp)
ORDER BY day_of_week;
-- CHART SETUP:
-- Chart Type: Bar Chart
-- X-axis: day_name
-- Y-axis: order_count
-- Title: Orders by Day of Week

SELECT 
    payment_type,
    COUNT(order_id) as transaction_count,
    ROUND(SUM(payment_value), 2) as total_value,
    ROUND(AVG(payment_value), 2) as avg_transaction_value,
    ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER(), 2) as percentage_share
FROM ods_payments
WHERE is_deleted = false
GROUP BY payment_type
ORDER BY total_value DESC;
-- CHART SETUP:
-- Chart Type: Pie Chart
-- Dimension: payment_type
-- Measure: total_value
-- Title: Revenue Distribution by Payment Method