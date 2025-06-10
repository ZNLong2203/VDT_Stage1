#!/bin/bash

# Test Real-Time Data Pipeline for Selected Olist Tables
set -e

echo "🧪 Testing Real-Time Data Pipeline for 5 Selected Tables..."

# Insert new product (needed first for foreign key)
echo "📝 Inserting new product into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO products (product_id, product_category_name) 
VALUES ('test_product_001', 'test_category');
"

# Insert new order
echo "📝 Inserting new order into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp, order_delivered_customer_date) 
VALUES ('test_order_001', (SELECT customer_id FROM customers LIMIT 1), 'processing', NOW(), NOW() + INTERVAL '7 days');
"

# Insert order item
echo "📝 Inserting order item into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO order_items (order_id, order_item_id, product_id, seller_id, price, freight_value) 
VALUES ('test_order_001', 1, 'test_product_001', (SELECT seller_id FROM sellers LIMIT 1), 99.99, 15.50);
"

# Insert payment
echo "📝 Inserting payment into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO payments (order_id, payment_sequential, payment_type, payment_installments, payment_value) 
VALUES ('test_order_001', 1, 'credit_card', 1, 115.49);
"

# Insert review
echo "📝 Inserting review into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO reviews (review_id, order_id, review_score, review_creation_date) 
VALUES ('test_review_001', 'test_order_001', 5, NOW());
"

echo "⏳ Waiting for CDC to propagate changes (15 seconds)..."
sleep 15

# Check if data appeared in StarRocks (5 selected tables only)
echo "🔍 Checking data in StarRocks ODS tables..."

# Check products (should have test_product_001)
STARROCKS_PRODUCTS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_ods_raw; SELECT COUNT(*) FROM ods_products_raw WHERE product_id = 'test_product_001';")
echo "📊 Test products in StarRocks: $STARROCKS_PRODUCTS"

# Check orders (should have test_order_001)
STARROCKS_ORDERS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_ods_raw; SELECT COUNT(*) FROM ods_orders_raw WHERE order_id = 'test_order_001';")
echo "📊 Test orders in StarRocks: $STARROCKS_ORDERS"

# Check order items (should have test_order_001)
STARROCKS_ORDER_ITEMS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_ods_raw; SELECT COUNT(*) FROM ods_order_items_raw WHERE order_id = 'test_order_001';")
echo "📊 Test order items in StarRocks: $STARROCKS_ORDER_ITEMS"

# Check payments (should have test_order_001)
STARROCKS_PAYMENTS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_ods_raw; SELECT COUNT(*) FROM ods_payments_raw WHERE order_id = 'test_order_001';")
echo "📊 Test payments in StarRocks: $STARROCKS_PAYMENTS"

# Check reviews (should have test_order_001) 
STARROCKS_REVIEWS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_ods_raw; SELECT COUNT(*) FROM ods_reviews_raw WHERE order_id = 'test_order_001';")
echo "📊 Test reviews in StarRocks: $STARROCKS_REVIEWS"

# Verify results for 5 selected tables
EXPECTED_COUNT=1
TOTAL_EXPECTED=5
ACTUAL_TOTAL=$((STARROCKS_PRODUCTS + STARROCKS_ORDERS + STARROCKS_ORDER_ITEMS + STARROCKS_PAYMENTS + STARROCKS_REVIEWS))

if [ "$ACTUAL_TOTAL" -eq "$TOTAL_EXPECTED" ]; then
    echo "✅ Pipeline test PASSED! All 5 selected tables successfully replicated to StarRocks."
else
    echo "❌ Pipeline test FAILED! Expected $TOTAL_EXPECTED records, got $ACTUAL_TOTAL."
    echo "Details: $STARROCKS_PRODUCTS products, $STARROCKS_ORDERS orders, $STARROCKS_ORDER_ITEMS order_items, $STARROCKS_PAYMENTS payments, $STARROCKS_REVIEWS reviews"
fi

echo ""
echo "📈 Current data summary:"
echo "PostgreSQL (All tables):"
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
SELECT 
    'customers' as table_name, COUNT(*) as record_count FROM customers
UNION SELECT 'sellers', COUNT(*) FROM sellers
UNION SELECT 'products', COUNT(*) FROM products  
UNION SELECT 'orders', COUNT(*) FROM orders
UNION SELECT 'order_items', COUNT(*) FROM order_items
UNION SELECT 'payments', COUNT(*) FROM payments
UNION SELECT 'reviews', COUNT(*) FROM reviews
ORDER BY table_name;
"

echo ""
echo "StarRocks (Selected 5 tables only):"
mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -e "
USE ecommerce_ods_raw;
SELECT 'products' as table_name, COUNT(*) as record_count FROM ods_products_raw
UNION SELECT 'orders', COUNT(*) FROM ods_orders_raw
UNION SELECT 'order_items', COUNT(*) FROM ods_order_items_raw
UNION SELECT 'payments', COUNT(*) FROM ods_payments_raw
UNION SELECT 'reviews', COUNT(*) FROM ods_reviews_raw
ORDER BY table_name;
"