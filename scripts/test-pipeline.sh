#!/bin/bash

# Test Real-Time Data Pipeline
set -e

echo "🧪 Testing Real-Time Data Pipeline..."

# Insert new customer into PostgreSQL
echo "📝 Inserting new customer into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO customers (name, email) 
VALUES ('Test User', 'test.user@example.com');
"

# Insert new product
echo "📝 Inserting new product into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO products (name, price, category) 
VALUES ('Test Product', 99.99, 'Test Category');
"

# Get the new customer and product IDs
CUSTOMER_ID=$(docker exec postgres-cdc psql -U postgres -d ecommerce -t -c "SELECT id FROM customers WHERE email = 'test.user@example.com';" | xargs)
PRODUCT_ID=$(docker exec postgres-cdc psql -U postgres -d ecommerce -t -c "SELECT id FROM products WHERE name = 'Test Product';" | xargs)

echo "📝 New Customer ID: $CUSTOMER_ID"
echo "📝 New Product ID: $PRODUCT_ID"

# Insert new order
echo "📝 Inserting new order into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO orders (customer_id, total_amount, status) 
VALUES ($CUSTOMER_ID, 199.98, 'pending');
"

# Get the new order ID
ORDER_ID=$(docker exec postgres-cdc psql -U postgres -d ecommerce -t -c "SELECT id FROM orders WHERE customer_id = $CUSTOMER_ID;" | xargs)
echo "📝 New Order ID: $ORDER_ID"

# Insert order items
echo "📝 Inserting order items into PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO order_items (order_id, product_id, quantity, price) 
VALUES ($ORDER_ID, $PRODUCT_ID, 2, 99.99);
"

echo "⏳ Waiting for CDC to propagate changes (10 seconds)..."
sleep 10

# Check if data appeared in StarRocks
echo "🔍 Checking data in StarRocks..."

# Check customers
STARROCKS_CUSTOMERS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_dw; SELECT COUNT(*) FROM customers WHERE email = 'test.user@example.com';")
echo "📊 Customers in StarRocks with test email: $STARROCKS_CUSTOMERS"

# Check products
STARROCKS_PRODUCTS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_dw; SELECT COUNT(*) FROM products WHERE name = 'Test Product';")
echo "📊 Products in StarRocks with test name: $STARROCKS_PRODUCTS"

# Check orders
STARROCKS_ORDERS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_dw; SELECT COUNT(*) FROM orders WHERE customer_id = $CUSTOMER_ID;")
echo "📊 Orders in StarRocks for test customer: $STARROCKS_ORDERS"

# Check order items
STARROCKS_ORDER_ITEMS=$(mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -s -N -e "USE ecommerce_dw; SELECT COUNT(*) FROM order_items WHERE order_id = $ORDER_ID;")
echo "📊 Order items in StarRocks for test order: $STARROCKS_ORDER_ITEMS"

# Verify results
if [ "$STARROCKS_CUSTOMERS" -eq "1" ] && [ "$STARROCKS_PRODUCTS" -eq "1" ] && [ "$STARROCKS_ORDERS" -eq "1" ] && [ "$STARROCKS_ORDER_ITEMS" -eq "1" ]; then
    echo "✅ Pipeline test PASSED! All data successfully replicated to StarRocks."
else
    echo "❌ Pipeline test FAILED! Some data was not replicated."
    echo "Expected: 1 customer, 1 product, 1 order, 1 order item"
    echo "Got: $STARROCKS_CUSTOMERS customers, $STARROCKS_PRODUCTS products, $STARROCKS_ORDERS orders, $STARROCKS_ORDER_ITEMS order items"
fi

echo ""
echo "📈 Current data summary:"
echo "PostgreSQL:"
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
SELECT 
    (SELECT COUNT(*) FROM customers) as customers,
    (SELECT COUNT(*) FROM products) as products,
    (SELECT COUNT(*) FROM orders) as orders,
    (SELECT COUNT(*) FROM order_items) as order_items;
"

echo ""
echo "StarRocks:"
mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -e "
USE ecommerce_dw;
SELECT 
    (SELECT COUNT(*) FROM customers) as customers,
    (SELECT COUNT(*) FROM products) as products,
    (SELECT COUNT(*) FROM orders) as orders,
    (SELECT COUNT(*) FROM order_items) as order_items;
"