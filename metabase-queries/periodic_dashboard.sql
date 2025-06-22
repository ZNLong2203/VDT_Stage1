SELECT 
    customer_segment,
    COUNT(*) as customers,
    ROUND(AVG(total_spent), 2) as avg_clv,
    ROUND(AVG(total_orders), 2) as avg_orders,
    ROUND(SUM(total_spent), 2) as segment_total_revenue,
    ROUND(MIN(total_spent), 2) as min_clv,
    ROUND(MAX(total_spent), 2) as max_clv
FROM ecommerce_ods_clean.mv_customer_lifetime_analysis
GROUP BY customer_segment
ORDER BY avg_clv DESC;
-- CHART SETUP:
-- Chart Type: Table
-- Columns: customer_segment, customers, avg_clv, avg_orders, segment_total_revenue
-- Title: Customer Segmentation by Lifetime Value

SELECT 
    category_group,
    SUM(total_products) as total_products,
    SUM(total_orders) as total_orders,
    ROUND(SUM(total_revenue), 2) as total_revenue,
    ROUND(AVG(avg_item_price), 2) as avg_item_price,
    SUM(unique_customers) as unique_customers,
    ROUND(SUM(total_revenue) / SUM(unique_customers), 2) as revenue_per_customer
FROM ecommerce_ods_clean.mv_category_revenue_analysis
GROUP BY category_group
ORDER BY total_revenue DESC;
-- CHART SETUP:
-- Chart Type: Bar Chart
-- X-axis: category_group
-- Y-axis: total_revenue
-- Title: Revenue by Product Category

SELECT 
    day_of_week,
    day_name,
    SUM(order_count) as total_orders,
    ROUND(AVG(avg_order_value), 2) as avg_order_value,
    ROUND(SUM(payment_total), 2) as total_revenue
FROM ecommerce_ods_clean.mv_business_patterns
GROUP BY day_of_week, day_name
ORDER BY day_of_week;
-- CHART SETUP:
-- Chart Type: Bar Chart
-- X-axis: day_name
-- Y-axis: order_count
-- Title: Orders by Day of Week

SELECT 
    payment_type,
    SUM(payment_count) as transaction_count,
    ROUND(SUM(payment_total), 2) as total_value,
    ROUND(AVG(avg_order_value), 2) as avg_transaction_value,
    ROUND(SUM(payment_total) * 100.0 / (SELECT SUM(payment_total) FROM ecommerce_ods_clean.mv_business_patterns), 2) as percentage_share
FROM ecommerce_ods_clean.mv_business_patterns
GROUP BY payment_type
ORDER BY total_value DESC;
-- CHART SETUP:
-- Chart Type: Pie Chart
-- Dimension: payment_type
-- Measure: total_value
-- Title: Revenue Distribution by Payment Method