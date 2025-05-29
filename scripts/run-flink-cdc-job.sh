#!/bin/bash

# Run Flink CDC Job
set -e

FLINK_HOME="flink-local/flink-1.18.0"

echo "🚀 Submitting Flink CDC Job..."

# Check if Flink is running
if ! curl -f http://localhost:8081 >/dev/null 2>&1; then
    echo "❌ Flink cluster is not running!"
    echo "Please start Flink first:"
    echo "  cd $FLINK_HOME"
    echo "  ./bin/start-cluster.sh"
    exit 1
fi

echo "✅ Flink cluster is running!"

# Submit the CDC job using Flink SQL CLI
echo "📤 Submitting CDC job..."
cd "$FLINK_HOME"

# Run the SQL file
./bin/sql-client.sh -f ../../flink/jobs/postgres-to-starrocks-cdc.sql

echo "✅ CDC job submitted successfully!"
echo ""
echo "🌐 Monitor the job at: http://localhost:8081"
echo "📊 Check data in StarRocks:"
echo "  mysql -h localhost -P 9030 -u root -e 'USE ecommerce_dw; SELECT COUNT(*) FROM customers;'" 