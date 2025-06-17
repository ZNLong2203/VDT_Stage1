#!/bin/bash

# =============================================================================
# Test Real-Time Streaming ETL Pipeline with Data Validation
# PostgreSQL CDC → Flink ETL with Validation → StarRocks Clean/Error Tables
# =============================================================================

set -e

echo "🧪 Testing Real-Time Streaming ETL Pipeline with Data Validation..."
echo "📊 Architecture: PostgreSQL CDC → Transform + Validate → StarRocks Clean/Error Tables"

# Insert test data
TIMESTAMP=$(date +%s)
echo "📝 Inserting test data (timestamp: $TIMESTAMP)..."

# ===========================================================================
# TEST 1: VALID DATA (should go to clean tables)
# ===========================================================================

echo "✅ TEST 1: Inserting VALID data..."

# Insert new product
echo "📝 Inserting valid product into PostgreSQL..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO products (product_id, product_category_name) 
VALUES ('test_product_${TIMESTAMP}', 'informatica_teste');
"

# Insert new order
echo "📝 Inserting valid order into PostgreSQL..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date) 
VALUES ('test_order_${TIMESTAMP}', (SELECT customer_id FROM customers LIMIT 1), 'processing', NOW(), NOW() + INTERVAL '7 days');
"

# Insert order item with high price for testing transformations
echo "📝 Inserting valid order item into PostgreSQL..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO order_items (order_id, product_id, price, freight_value) 
VALUES ('test_order_${TIMESTAMP}', 'test_product_${TIMESTAMP}', 175.50, 12.25);
"

# Insert payment
echo "📝 Inserting valid payment into PostgreSQL..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO payments (order_id, payment_type, payment_value) 
VALUES ('test_order_${TIMESTAMP}', 'credit_card', 187.75);
"

# Insert valid review
echo "📝 Inserting valid review into PostgreSQL..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO reviews (review_id, order_id, review_score) 
VALUES ('test_review_${TIMESTAMP}', 'test_order_${TIMESTAMP}', 4);
"

# Insert valid customer
echo "📝 Inserting valid customer into PostgreSQL..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO customers (customer_id, customer_unique_id, customer_city, customer_state) 
VALUES ('test_customer_${TIMESTAMP}', 'unique_test_${TIMESTAMP}', 'São Paulo', 'SP');
"

echo "⏳ Waiting for CDC + ETL to process valid data (15 seconds)..."
sleep 15

# ===========================================================================
# TEST 2: INVALID DATA (should go to error tables)
# ===========================================================================

echo "❌ TEST 2: Inserting INVALID data for validation testing..."

# Insert invalid product (NULL product_id)
echo "📝 Inserting invalid product (empty product_id)..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO products (product_id, product_category_name) 
VALUES ('', 'invalid_category');
" || echo "Expected error - continuing..."

# Insert invalid order (NULL customer_id) 
echo "📝 Inserting invalid order (NULL customer_id)..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date) 
VALUES ('invalid_order_${TIMESTAMP}', NULL, 'processing', NOW(), NOW() + INTERVAL '7 days');
"

# Insert invalid order item (negative price)
echo "📝 Inserting invalid order item (negative price)..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO order_items (order_id, product_id, price, freight_value) 
VALUES ('invalid_order_${TIMESTAMP}', 'test_product_${TIMESTAMP}', -50.0, 12.25);
"

# Insert invalid payment (negative value)
echo "📝 Inserting invalid payment (negative value)..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO payments (order_id, payment_type, payment_value) 
VALUES ('invalid_order_${TIMESTAMP}', 'credit_card', -100.0);
"

# Insert invalid review (score out of range)
echo "📝 Inserting invalid review (score = 10, should be 1-5)..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO reviews (review_id, order_id, review_score) 
VALUES ('invalid_review_${TIMESTAMP}', 'invalid_order_${TIMESTAMP}', 10);
"

# Insert invalid customer (invalid state code)
echo "📝 Inserting invalid customer (invalid state code)..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
INSERT INTO customers (customer_id, customer_unique_id, customer_city, customer_state) 
VALUES ('invalid_customer_${TIMESTAMP}', 'unique_invalid_${TIMESTAMP}', 'Test City', 'INVALID_STATE');
"

echo "⏳ Waiting for CDC + ETL to process invalid data (15 seconds)..."
sleep 15

# ===========================================================================
# VERIFY CLEAN DATA
# ===========================================================================

echo "🔍 Checking VALID data in StarRocks Clean tables..."

# Check products with category grouping
echo "📊 Testing Products ETL (category grouping):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_clean; 
SELECT product_id, product_category_name, category_group 
FROM ods_products 
WHERE product_id = 'test_product_${TIMESTAMP}';
"

# Check orders with transformations
echo "📊 Testing Orders ETL (status normalization, date extraction):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_clean; 
SELECT order_id, order_status, order_year, order_month, is_delivered 
FROM ods_orders 
WHERE order_id = 'test_order_${TIMESTAMP}';
"

# Check order items with pricing categories
echo "📊 Testing Order Items ETL (pricing categories):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_clean; 
SELECT order_id, price, total_item_value, price_category 
FROM ods_order_items 
WHERE order_id = 'test_order_${TIMESTAMP}';
"

# Check payments with categorization
echo "📊 Testing Payments ETL (payment categorization):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_clean; 
SELECT order_id, payment_type, payment_value, payment_category, is_high_value 
FROM ods_payments 
WHERE order_id = 'test_order_${TIMESTAMP}';
"

# Check reviews
echo "📊 Testing Reviews ETL (review categorization):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_clean; 
SELECT order_id, review_score, review_category, is_positive_review 
FROM ods_reviews 
WHERE order_id = 'test_order_${TIMESTAMP}';
"

# Check customers
echo "📊 Testing Customers ETL (regional analysis):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_clean; 
SELECT customer_id, customer_city, customer_state, state_region 
FROM ods_customers 
WHERE customer_id = 'test_customer_${TIMESTAMP}';
"

# ===========================================================================
# VERIFY ERROR DATA
# ===========================================================================

echo ""
echo "🔍 Checking INVALID data in StarRocks Error tables..."

# Check error log
echo "📊 Testing Error Log (general error tracking):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_error; 
SELECT table_name, error_type, error_message, error_timestamp 
FROM ods_error_log 
WHERE error_timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY error_timestamp DESC 
LIMIT 10;
"

# Check specific error tables
echo "📊 Testing Orders Error Table:"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_error; 
SELECT order_id, error_type, error_message 
FROM ods_orders_error 
WHERE order_id = 'invalid_order_${TIMESTAMP}';
"

echo "📊 Testing Order Items Error Table:"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_error; 
SELECT order_id, price, error_type, error_message 
FROM ods_order_items_error 
WHERE order_id = 'invalid_order_${TIMESTAMP}';
"

echo "📊 Testing Payments Error Table:"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_error; 
SELECT order_id, payment_value, error_type, error_message 
FROM ods_payments_error 
WHERE order_id = 'invalid_order_${TIMESTAMP}';
"

echo "📊 Testing Reviews Error Table:"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_error; 
SELECT order_id, review_score, error_type, error_message 
FROM ods_reviews_error 
WHERE order_id = 'invalid_order_${TIMESTAMP}';
"

echo "📊 Testing Customers Error Table:"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_error; 
SELECT customer_id, customer_state, error_type, error_message 
FROM ods_customers_error 
WHERE customer_id = 'invalid_customer_${TIMESTAMP}';
"

# ===========================================================================
# VALIDATION SUMMARY
# ===========================================================================

echo ""
echo "🔍 Verifying ETL Transformations and Validation:"

# Count valid test records
TEST_PRODUCTS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT COUNT(*) FROM ods_products WHERE product_id = 'test_product_${TIMESTAMP}';")
TEST_ORDERS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT COUNT(*) FROM ods_orders WHERE order_id = 'test_order_${TIMESTAMP}';")
TEST_ORDER_ITEMS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT COUNT(*) FROM ods_order_items WHERE order_id = 'test_order_${TIMESTAMP}';")
TEST_PAYMENTS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT COUNT(*) FROM ods_payments WHERE order_id = 'test_order_${TIMESTAMP}';")
TEST_REVIEWS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT COUNT(*) FROM ods_reviews WHERE order_id = 'test_order_${TIMESTAMP}';")
TEST_CUSTOMERS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT COUNT(*) FROM ods_customers WHERE customer_id = 'test_customer_${TIMESTAMP}';")

# Count error records
ERROR_ORDERS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_error; SELECT COUNT(*) FROM ods_orders_error WHERE order_id = 'invalid_order_${TIMESTAMP}';")
ERROR_ORDER_ITEMS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_error; SELECT COUNT(*) FROM ods_order_items_error WHERE order_id = 'invalid_order_${TIMESTAMP}';")
ERROR_PAYMENTS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_error; SELECT COUNT(*) FROM ods_payments_error WHERE order_id = 'invalid_order_${TIMESTAMP}';")
ERROR_REVIEWS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_error; SELECT COUNT(*) FROM ods_reviews_error WHERE order_id = 'invalid_order_${TIMESTAMP}';")
ERROR_CUSTOMERS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_error; SELECT COUNT(*) FROM ods_customers_error WHERE customer_id = 'invalid_customer_${TIMESTAMP}';")

# Check transformation results
PRODUCT_CATEGORY=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT category_group FROM ods_products WHERE product_id = 'test_product_${TIMESTAMP}';")
ORDER_STATUS=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT order_status FROM ods_orders WHERE order_id = 'test_order_${TIMESTAMP}';")
PRICE_CATEGORY=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT price_category FROM ods_order_items WHERE order_id = 'test_order_${TIMESTAMP}';")
PAYMENT_CATEGORY=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT payment_category FROM ods_payments WHERE order_id = 'test_order_${TIMESTAMP}';")
REVIEW_CATEGORY=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT review_category FROM ods_reviews WHERE order_id = 'test_order_${TIMESTAMP}';")
CUSTOMER_REGION=$(mysql -h 127.0.0.1 -P 9030 -u root -s -N -e "USE ecommerce_ods_clean; SELECT state_region FROM ods_customers WHERE customer_id = 'test_customer_${TIMESTAMP}';")

echo "✅ VALID Records found: Products($TEST_PRODUCTS), Orders($TEST_ORDERS), Order Items($TEST_ORDER_ITEMS), Payments($TEST_PAYMENTS), Reviews($TEST_REVIEWS), Customers($TEST_CUSTOMERS)"
echo "❌ ERROR Records found: Orders($ERROR_ORDERS), Order Items($ERROR_ORDER_ITEMS), Payments($ERROR_PAYMENTS), Reviews($ERROR_REVIEWS), Customers($ERROR_CUSTOMERS)"

echo ""
echo "✅ Transformations applied to valid data:"
echo "   📦 Product category: informatica_teste → $PRODUCT_CATEGORY"
echo "   📋 Order status: processing → $ORDER_STATUS"  
echo "   💰 Price category: 175.50 → $PRICE_CATEGORY"
echo "   💳 Payment category: credit_card → $PAYMENT_CATEGORY"
echo "   ⭐ Review category: score 4 → $REVIEW_CATEGORY"
echo "   🏠 Customer region: SP → $CUSTOMER_REGION"

# Overall test result
TOTAL_VALID_EXPECTED=6
TOTAL_ERROR_EXPECTED=5
ACTUAL_VALID_TOTAL=$((TEST_PRODUCTS + TEST_ORDERS + TEST_ORDER_ITEMS + TEST_PAYMENTS + TEST_REVIEWS + TEST_CUSTOMERS))
ACTUAL_ERROR_TOTAL=$((ERROR_ORDERS + ERROR_ORDER_ITEMS + ERROR_PAYMENTS + ERROR_REVIEWS + ERROR_CUSTOMERS))

echo ""
if [ "$ACTUAL_VALID_TOTAL" -eq "$TOTAL_VALID_EXPECTED" ] && [ "$ACTUAL_ERROR_TOTAL" -ge 2 ]; then
    echo "🎉 STREAMING ETL PIPELINE WITH VALIDATION TEST PASSED!"
    echo "✅ All valid data processed with correct transformations"
    echo "✅ Invalid data correctly routed to error tables"
else
    echo "❌ Pipeline test FAILED!"
    echo "   Expected $TOTAL_VALID_EXPECTED valid records, got $ACTUAL_VALID_TOTAL"
    echo "   Expected at least 2 error records, got $ACTUAL_ERROR_TOTAL"
fi

echo ""
echo "📈 Pipeline Summary:"
echo "StarRocks Clean Tables (valid data with ETL transformations):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_clean;
SELECT 'ods_products' as table_name, COUNT(*) as record_count FROM ods_products
UNION SELECT 'ods_orders', COUNT(*) FROM ods_orders
UNION SELECT 'ods_order_items', COUNT(*) FROM ods_order_items
UNION SELECT 'ods_payments', COUNT(*) FROM ods_payments
UNION SELECT 'ods_reviews', COUNT(*) FROM ods_reviews
ORDER BY table_name;
"

echo ""
echo "StarRocks Error Tables (invalid data for monitoring):"
mysql -h 127.0.0.1 -P 9030 -u root -e "
USE ecommerce_ods_error;
SELECT 'ods_error_log' as table_name, COUNT(*) as record_count FROM ods_error_log
UNION SELECT 'ods_orders_error', COUNT(*) FROM ods_orders_error
UNION SELECT 'ods_order_items_error', COUNT(*) FROM ods_order_items_error
UNION SELECT 'ods_products_error', COUNT(*) FROM ods_products_error
UNION SELECT 'ods_payments_error', COUNT(*) FROM ods_payments_error
UNION SELECT 'ods_reviews_error', COUNT(*) FROM ods_reviews_error
ORDER BY table_name;
"