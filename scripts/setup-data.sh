#!/bin/bash

# Setup Data Pipeline
set -e

echo "🚀 Setting up Real-Time Data Pipeline..."

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
until curl -f http://localhost:8030 >/dev/null 2>&1; do
    echo "Waiting for StarRocks..."
    sleep 5
done
echo "✅ StarRocks is ready!"

# Setup StarRocks schema
echo "📊 Setting up StarRocks schema..."
mysql -h localhost -P 9030 -u root < sql/starrocks-init.sql
echo "✅ StarRocks schema created!"

# Create replication slots in PostgreSQL
echo "🔄 Creating replication slots in PostgreSQL..."
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
SELECT pg_create_logical_replication_slot('customers_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('products_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('orders_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('order_items_slot', 'pgoutput');
"
echo "✅ Replication slots created!"

echo ""
echo "🎉 Data pipeline setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Setup Flink CDC locally:"
echo "   ./scripts/setup-flink-cdc.sh"
echo ""
echo "2. Start Flink cluster:"
echo "   cd flink-local/flink-1.18.0"
echo "   ./bin/start-cluster.sh"
echo ""
echo "3. Submit CDC job:"
echo "   ./scripts/run-flink-cdc-job.sh"
echo ""
echo "4. Access services:"
echo "   - Flink Web UI: http://localhost:8081"
echo "   - StarRocks FE: http://localhost:8030"
echo "   - Metabase: http://localhost:3000"
echo ""
echo "5. Test the pipeline:"
echo "   ./scripts/test-pipeline.sh" 