#!/bin/bash

# Check Pipeline Status
echo "📊 Real-Time Data Pipeline Status"
echo "================================="

# Check Docker containers
echo ""
echo "🐳 Docker Containers:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Check Flink cluster
echo ""
echo "⚡ Flink Cluster:"
if curl -s http://localhost:8081 > /dev/null 2>&1; then
    echo "✅ Flink Web UI: http://localhost:8081"
    
    # Check Flink jobs
    echo ""
    echo "🔄 Flink Jobs:"
    curl -s http://localhost:8081/jobs | jq '.jobs[] | {id: .id[0:8], status: .status}' || echo "❌ Failed to get job status"
else
    echo "❌ Flink cluster not running"
fi

# Check data counts
echo ""
echo "📈 Data Summary:"
echo "PostgreSQL:"
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
SELECT 
    'customers' as table_name, COUNT(*) as count FROM customers 
UNION SELECT 'products', COUNT(*) FROM products 
UNION SELECT 'orders', COUNT(*) FROM orders 
UNION SELECT 'order_items', COUNT(*) FROM order_items 
ORDER BY table_name;" 2>/dev/null || echo "❌ PostgreSQL connection failed"

echo ""
echo "StarRocks:"
mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP -e "
USE ecommerce_ods_raw; 
SELECT 
    'customers' as table_name, COUNT(*) as count FROM customers 
UNION SELECT 'products', COUNT(*) FROM products 
UNION SELECT 'orders', COUNT(*) FROM orders 
UNION SELECT 'order_items', COUNT(*) FROM order_items 
ORDER BY table_name;" 2>/dev/null || echo "❌ StarRocks connection failed"

# Check replication slots
echo ""
echo "🔌 PostgreSQL Replication Slots:"
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
SELECT slot_name, active, restart_lsn FROM pg_replication_slots ORDER BY slot_name;" 2>/dev/null || echo "❌ Failed to check replication slots"

echo ""
echo "🌐 Web Interfaces:"
echo "  Flink Web UI: http://localhost:8081"
echo "  Metabase: http://localhost:3000" 