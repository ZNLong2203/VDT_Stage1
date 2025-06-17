#!/bin/bash

set -e

# Check PostgreSQL
echo "Checking PostgreSQL connection..."
until docker exec postgres-cdc pg_isready -U postgres; do
    echo "Waiting for PostgreSQL..."
    sleep 5
done
echo "PostgreSQL is ready!"

# Check StarRocks
echo "Checking StarRocks connection..."
until mysql -h localhost -P 9030 -u root --protocol=TCP -e "SELECT 1;" >/dev/null 2>&1; do
    echo "Waiting for StarRocks..."
    sleep 5
done
echo "StarRocks is ready!"

# Setup StarRocks schema
echo "Setting up StarRocks Clean Data schema..."
mysql -h localhost -P 9030 -u root --protocol=TCP < sql/starrocks-init.sql
echo "StarRocks Clean Data schema created!"

echo "Setting up StarRocks Error Data schema..."
mysql -h localhost -P 9030 -u root --protocol=TCP < sql/create-error-schema.sql
echo "StarRocks Error Data schema created!"

# Show data summary
echo ""
echo "Data Summary (All tables in PostgreSQL):"
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
echo "Data pipeline setup completed!"
echo ""