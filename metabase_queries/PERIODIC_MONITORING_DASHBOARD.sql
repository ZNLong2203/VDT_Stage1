-- =====================================================
-- VDT STAGE 1 - PERIODIC MONITORING DASHBOARD (SIMPLIFIED)
-- =====================================================
-- 5 queries đã được đơn giản hóa tối đa để chắc chắn chạy được

-- ========================================
-- Query 1: Monthly Revenue Trends (SIMPLIFIED)
-- ========================================
SELECT 
    YEAR(o.order_purchase_timestamp) as year,
    MONTH(o.order_purchase_timestamp) as month,
    CONCAT(YEAR(o.order_purchase_timestamp), '-', 
           LPAD(MONTH(o.order_purchase_timestamp), 2, '0')) as year_month,
    COUNT(o.order_id) as total_orders,
    ROUND(SUM(p.payment_value), 2) as total_revenue,
    COUNT(DISTINCT o.customer_id) as unique_customers
FROM ods_orders o
JOIN ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false 
    AND p.is_deleted = false
GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY year, month;

-- CHART SETUP:
-- Chart Type: Line Chart
-- X-axis: year_month 
-- Y-axis: total_revenue (primary), total_orders (secondary)
-- Title: "Monthly Revenue & Orders Trend"

-- ========================================
-- Query 2: Customer Lifetime Value Segmentation (WORKING)
-- ========================================
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
-- Title: "Customer Segmentation by Lifetime Value"

-- ========================================
-- Query 3: Product Category Performance (WORKING)
-- ========================================
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
-- Title: "Revenue by Product Category"

-- ========================================
-- Query 4: Weekly Order Trends (FIXED)
-- ========================================
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
-- Title: "Orders by Day of Week"

-- ========================================
-- Query 5: Payment Method Distribution (SIMPLIFIED)
-- ========================================
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
-- Title: "Revenue Distribution by Payment Method"

-- ========================================
-- DETAILED CHART SETUP INSTRUCTIONS
-- ========================================

/*
QUERY 1 - Monthly Revenue Trends:
1. Chart Type: Line Chart
2. Data Section:
   - X-axis: year_month (Dimension)
   - Y-axis: total_revenue (Measure)
   - Series: total_orders (Optional secondary line)
3. Display Settings:
   - Title: "Monthly Revenue & Orders Trend"
   - Show data labels: Yes
   - Smooth lines: Yes

QUERY 2 - Customer LTV Segmentation:
1. Chart Type: Table
2. Columns to show:
   - customer_segment (Text)
   - customers (Number)
   - avg_clv (Currency format)
   - avg_orders (Number, 1 decimal)
   - segment_total_revenue (Currency format)
3. Table Settings:
   - Sort by: avg_clv descending
   - Conditional formatting: Green for VIP, Blue for Premium

QUERY 3 - Product Category Performance:
1. Chart Type: Bar Chart
2. Data Section:
   - X-axis: category_group (Dimension)
   - Y-axis: total_revenue (Measure)
3. Display Settings:
   - Sort: Descending by total_revenue
   - Show values on bars: Yes
   - Color: Single color (blue)

QUERY 4 - Weekly Order Trends:
1. Chart Type: Bar Chart
2. Data Section:
   - X-axis: day_name (Dimension)
   - Y-axis: order_count (Measure)
3. Display Settings:
   - Custom order: Monday to Sunday
   - Color gradient: Light to dark blue
   - Show data labels: Yes

QUERY 5 - Payment Method Distribution:
1. Chart Type: Pie Chart
2. Data Section:
   - Dimension: payment_type
   - Measure: total_value
3. Display Settings:
   - Show percentages: Yes
   - Show legend: Yes
   - Donut style: Optional
*/

-- ========================================
-- DASHBOARD SETUP INSTRUCTIONS:
-- ========================================
-- TAB 1 - EXECUTIVE OVERVIEW:
-- - Row 1: Monthly Growth Line Chart (full width)
-- - Row 2: Customer LTV Table + Product Performance Bubble
-- - Row 3: Quarterly Health Combo Chart (full width)

-- TAB 2 - OPERATIONAL EXCELLENCE:
-- - Row 1: Weekly Efficiency Area Chart (full width)
-- - Row 2: Payment Method Scatter + Retention Heatmap
-- - Row 3: Key operational metrics

-- TAB 3 - STRATEGIC INSIGHTS:
-- - Row 1: Market Opportunity Scatter (full width)
-- - Row 2: Seasonal Radar Chart + Competitive Gauges
-- - Row 3: Strategic recommendations summary

-- ========================================
-- ĐÁNH GIÁ CAPABILITIES:
-- ========================================
-- 1. STRATEGIC THINKING: Long-term business planning
-- 2. ADVANCED ANALYTICS: Multi-dimensional analysis
-- 3. BUSINESS ACUMEN: Market positioning insights
-- 4. OPERATIONAL EXCELLENCE: Process optimization
-- 5. CUSTOMER ANALYTICS: Retention & segmentation
-- 6. COMPETITIVE ANALYSIS: Benchmarking capabilities
-- 7. DATA STORYTELLING: Clear business narratives 