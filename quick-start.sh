#!/bin/bash

# Quick Start Script for Real-Time Data Pipeline
# Run this script every time you start your machine

set -e

echo "🚀 Quick Start: Real-Time Data Pipeline"
echo "======================================"

# 1. Start Docker containers
echo "📦 Starting Docker containers..."
docker compose up -d

# 2. Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 15

# 3. Check if Flink is already running
if ! curl -s http://localhost:8081 > /dev/null 2>&1; then
    echo "🔧 Starting Flink cluster..."
    cd flink-local/flink-1.18.0
    ./bin/start-cluster.sh
    cd ../..
    sleep 10
else
    echo "✅ Flink cluster already running"
fi

# 4. Check if CDC jobs are running by checking job overview
FLINK_RESPONSE=$(curl -s http://localhost:8081/overview 2>/dev/null || echo "")
if [[ "$FLINK_RESPONSE" == *"\"jobs-running\":0"* ]] || [[ -z "$FLINK_RESPONSE" ]]; then
    echo "🔄 Starting CDC jobs..."
    ./scripts/run-flink-cdc-job.sh
else
    echo "✅ CDC jobs already running"
fi

# 5. Show status
echo ""
echo "📊 Pipeline Status:"
echo "==================="
echo "🌐 Flink Web UI: http://localhost:8081"
echo "📈 Metabase: http://localhost:3000"
echo "🗄️  StarRocks: mysql -h 127.0.0.1 -P 9030 -u root --protocol=TCP"

echo ""
echo "📋 Quick Commands:"
echo "  Test pipeline: ./scripts/test-pipeline.sh"
echo "  Stop pipeline: ./stop-pipeline.sh"
echo "  Check status:  ./check-status.sh"

echo ""
echo "✅ Pipeline is ready!" 