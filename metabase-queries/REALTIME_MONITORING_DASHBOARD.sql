-- ========================================
-- Query 1: Today's Key Performance Indicators (WORKING)
-- ========================================
SELECT 
    'Today Orders' as metric,
    COUNT(*) as current_value,
    COUNT(CASE WHEN DATE(order_purchase_timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN 1 END) as yesterday_value,
    ROUND(
        (COUNT(*) - COUNT(CASE WHEN DATE(order_purchase_timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN 1 END)) * 100.0 / 
        NULLIF(COUNT(CASE WHEN DATE(order_purchase_timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN 1 END), 0), 2
    ) as change_percent
FROM ods_orders 
WHERE is_deleted = false
    AND DATE(order_purchase_timestamp) IN (CURRENT_DATE(), DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))

UNION ALL

SELECT 
    'Today Revenue' as metric,
    ROUND(SUM(CASE WHEN DATE(o.order_purchase_timestamp) = CURRENT_DATE() THEN p.payment_value ELSE 0 END), 2) as current_value,
    ROUND(SUM(CASE WHEN DATE(o.order_purchase_timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN p.payment_value ELSE 0 END), 2) as yesterday_value,
    ROUND(
        (SUM(CASE WHEN DATE(o.order_purchase_timestamp) = CURRENT_DATE() THEN p.payment_value ELSE 0 END) - 
         SUM(CASE WHEN DATE(o.order_purchase_timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN p.payment_value ELSE 0 END)) * 100.0 / 
        NULLIF(SUM(CASE WHEN DATE(o.order_purchase_timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN p.payment_value ELSE 0 END), 0), 2
    ) as change_percent
FROM ods_orders o
JOIN ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false 
    AND p.is_deleted = false
    AND o.order_status = 'delivered'
    AND DATE(o.order_purchase_timestamp) IN (CURRENT_DATE(), DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY));

-- CHART SETUP: Number cards với change indicators, auto-refresh 5 minutes

-- ========================================
-- Query 2: Recent Orders (ULTRA SIMPLE - NO TIME FILTER)
-- ========================================
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM ods_orders
WHERE is_deleted = false
ORDER BY order_purchase_timestamp DESC
LIMIT 30;

-- CHART SETUP: Table - Most recent 30 orders (no time filter)

-- ========================================
-- Query 3: Order Status Summary (WORKING)
-- ========================================
SELECT 
    order_status,
    COUNT(*) as order_count
FROM ods_orders 
WHERE is_deleted = false
GROUP BY order_status
ORDER BY order_count DESC;

-- CHART SETUP: Bar Chart - X-axis: order_status, Y-axis: order_count

-- ========================================
-- Query 4: Customer Order Count (ULTRA SIMPLE)
-- ========================================
SELECT 
    customer_id,
    COUNT(*) as total_orders
FROM ods_orders
WHERE is_deleted = false
GROUP BY customer_id
ORDER BY total_orders DESC
LIMIT 20;

-- CHART SETUP: Table - Top 20 customers by order count (all time)

-- ========================================
-- Query 5: System Health Alert Dashboard (WORKING)
-- ========================================
SELECT 
    'Order Processing Rate' as indicator,
    ROUND(COUNT(*) / 24.0, 2) as current_rate,
    'orders/hour' as unit,
    CASE 
        WHEN COUNT(*) / 24.0 >= 50 THEN 'Healthy'
        WHEN COUNT(*) / 24.0 >= 20 THEN 'Warning'
        ELSE 'Critical'
    END as status
FROM ods_orders 
WHERE is_deleted = false
    AND order_purchase_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)

UNION ALL

SELECT 
    'Payment Success Rate' as indicator,
    ROUND(COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) * 100.0 / COUNT(*), 2) as current_rate,
    '%' as unit,
    CASE 
        WHEN COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) * 100.0 / COUNT(*) >= 95 THEN 'Healthy'
        WHEN COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) * 100.0 / COUNT(*) >= 90 THEN 'Warning'
        ELSE 'Critical'
    END as status
FROM ods_orders o
JOIN ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false 
    AND p.is_deleted = false
    AND o.order_purchase_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)

UNION ALL

SELECT 
    'Customer Activity Rate' as indicator,
    COUNT(DISTINCT customer_id) as current_rate,
    'unique customers/24h' as unit,
    CASE 
        WHEN COUNT(DISTINCT customer_id) >= 100 THEN 'Healthy'
        WHEN COUNT(DISTINCT customer_id) >= 50 THEN 'Warning'
        ELSE 'Critical'
    END as status
FROM ods_orders 
WHERE is_deleted = false
    AND order_purchase_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- CHART SETUP: Table với status colors - Green (Healthy), Yellow (Warning), Red (Critical)

-- ========================================
-- Query 6: High-Value Orders (ULTRA SIMPLE - NO DATE FILTER)
-- ========================================
SELECT 
    o.order_id,
    o.customer_id,
    ROUND(p.payment_value, 2) as order_value
FROM ods_orders o
JOIN ods_payments p ON o.order_id = p.order_id
WHERE o.is_deleted = false 
    AND p.is_deleted = false
    AND p.payment_value >= 100
ORDER BY p.payment_value DESC
LIMIT 20;

-- CHART SETUP: Table - Top 20 high-value orders (all time, >= 100)

-- ========================================
-- DETAILED CHART SETUP INSTRUCTIONS
-- ========================================

/*
QUERY 1 - Today's KPIs:
1. Chart Type: Number (2 cards side by side)
2. Metrics: current_value, change_percent
3. Format: Numbers with +/- change indicators
4. Colors: Green (positive), Red (negative)
5. Auto-refresh: Every 5 minutes

QUERY 2 - Recent Orders:
1. Chart Type: Table
2. Columns: order_id, customer_id, order_status, order_purchase_timestamp
3. Format: DateTime for timestamp
4. Sort: By timestamp descending
5. Title: "Most Recent 30 Orders"

QUERY 3 - Order Status Summary:
1. Chart Type: Bar Chart
2. X-axis: order_status
3. Y-axis: order_count
4. Sort: Descending by count
5. Title: "Order Status Distribution"

QUERY 4 - Customer Order Count:
1. Chart Type: Table
2. Columns: customer_id, total_orders
3. Sort: By total_orders descending
4. Title: "Top 20 Customers by Order Count"

QUERY 5 - System Health:
1. Chart Type: Table with conditional formatting
2. Columns: indicator, current_rate, unit, status
3. Status Colors: Green (Healthy), Yellow (Warning), Red (Critical)
4. Title: "System Health Indicators"
5. Auto-refresh: Every 2 minutes

QUERY 6 - High-Value Orders:
1. Chart Type: Table
2. Columns: order_id, customer_id, order_value
3. Format: Currency for order_value
4. Sort: By order_value descending
5. Title: "Top 20 High-Value Orders (≥100)"
*/

-- ========================================
-- DASHBOARD SETUP INSTRUCTIONS:
-- ========================================
-- TAB 1 - LIVE OPERATIONS:
-- - Row 1: Today's KPIs (4 Number cards)
-- - Row 2: Hourly Pattern Combo Chart (full width)
-- - Row 3: Order Status Funnel + Payment Processing

-- TAB 2 - ALERTS & ANOMALIES:
-- - Row 1: System Health Progress Bars (full width)
-- - Row 2: Anomaly Detection Table + Geographic Heatmap
-- - Row 3: Alert notifications and thresholds

-- TAB 3 - PERFORMANCE METRICS:
-- - Row 1: Performance Scorecard Gauges (full width)
-- - Row 2: Customer Behavior Treemap + System Load Area
-- - Row 3: Real-time insights summary

-- ========================================
-- AUTO-REFRESH SETTINGS:
-- ========================================
-- Tab 1: Every 5 minutes
-- Tab 2: Every 2 minutes (for alerts)
-- Tab 3: Every 10 minutes

-- ========================================
-- ĐÁNH GIÁ CAPABILITIES:
-- ========================================
-- 1. REAL-TIME MONITORING: Live operational metrics
-- 2. PROACTIVE ALERTING: Anomaly detection systems
-- 3. PERFORMANCE MANAGEMENT: KPI tracking & targets
-- 4. SYSTEM MONITORING: Load & capacity analysis
-- 5. CUSTOMER INSIGHTS: Real-time behavior analysis
-- 6. GEOGRAPHIC ANALYSIS: Location-based patterns
-- 7. OPERATIONAL EXCELLENCE: Process optimization 