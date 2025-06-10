#!/bin/bash

# Setup Data Pipeline for Olist E-commerce Dataset (Selected Tables Only)
set -e

echo "🚀 Setting up Real-Time Data Pipeline for Selected Olist Tables..."

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check PostgreSQL
echo "🔍 Checking PostgreSQL connection..."
until docker exec postgres-cdc pg_isready -U postgres; do
    echo "Waiting for PostgreSQL..."
    sleep 5
done
echo "✅ PostgreSQL is ready!"

# Check StarRocks
echo "🔍 Checking StarRocks connection..."
until mysql -h localhost -P 9030 -u root --protocol=TCP -e "SELECT 1;" >/dev/null 2>&1; do
    echo "Waiting for StarRocks..."
    sleep 5
done
echo "✅ StarRocks is ready!"

# Setup StarRocks schema
echo "📊 Setting up StarRocks schema..."
mysql -h localhost -P 9030 -u root --protocol=TCP < sql/starrocks-init.sql
echo "✅ StarRocks schema created!"

# Create replication slots in PostgreSQL (only for selected tables)
# echo "🔄 Creating replication slots in PostgreSQL..."
# docker exec postgres-cdc psql -U postgres -d ecommerce -c "
# SELECT pg_create_logical_replication_slot('orders_slot', 'pgoutput');
# SELECT pg_create_logical_replication_slot('order_items_slot', 'pgoutput');
# SELECT pg_create_logical_replication_slot('products_slot', 'pgoutput');
# SELECT pg_create_logical_replication_slot('reviews_slot', 'pgoutput');
# SELECT pg_create_logical_replication_slot('payments_slot', 'pgoutput');
# "
echo "✅ Replication slots created for 5 selected tables!"

# Show data summary
echo ""
echo "📈 Data Summary (All tables in PostgreSQL):"
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
echo "📋 CDC will stream 5 selected tables: orders, order_items, products, reviews, payments"

echo ""
echo "🎉 Data pipeline setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Start Flink cluster:"
echo "   cd flink-local/flink-1.18.0"
echo "   ./bin/start-cluster.sh"
echo ""
echo "2. Submit CDC job:"
echo "   ./scripts/run-flink-cdc-job.sh"
echo ""
echo "3. Access services:"
echo "   - Flink Web UI: http://localhost:8081"
echo "   - StarRocks FE: http://localhost:8030"
echo "   - Metabase: http://localhost:3000"
echo ""
echo "4. Test the pipeline:"
echo "   ./scripts/test-pipeline.sh" 