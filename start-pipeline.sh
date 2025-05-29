#!/bin/bash

# Master Script: Start Complete Real-Time Data Pipeline
set -e

echo "🚀 Starting Real-Time Data Pipeline..."
echo "======================================"

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check Docker Compose (v1 or v2)
DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Using Docker Compose: $DOCKER_COMPOSE_CMD"

# Check Java
if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed. Please install Java 8+ first."
    exit 1
fi

# Check MySQL client
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL client is not installed. Please install MySQL client first."
    exit 1
fi

echo "✅ All prerequisites satisfied!"

# Step 1: Start containerized services
echo ""
echo "📦 Step 1: Starting containerized services..."
$DOCKER_COMPOSE_CMD up -d

# Step 2: Setup Flink CDC locally
echo ""
echo "⚙️  Step 2: Setting up Flink CDC locally..."
if [ ! -d "flink-local" ]; then
    ./scripts/setup-flink-cdc.sh
else
    echo "✅ Flink already set up, skipping download..."
fi

# Step 3: Wait for services and initialize data
echo ""
echo "⏳ Step 3: Waiting for services and initializing data..."
./scripts/setup-data.sh

# Step 4: Start Flink cluster
echo ""
echo "🔥 Step 4: Starting Flink cluster..."
cd flink-local/flink-1.18.0
./bin/start-cluster.sh
cd ../..

# Wait a bit for Flink to be ready
echo "⏳ Waiting for Flink cluster to be ready..."
sleep 10

# Step 5: Submit CDC job
echo ""
echo "📤 Step 5: Submitting CDC job..."
./scripts/run-flink-cdc-job.sh

# Step 6: Test the pipeline
echo ""
echo "🧪 Step 6: Testing the pipeline..."
sleep 5  # Give CDC job time to start
./scripts/test-pipeline.sh

# Final status
echo ""
echo "🎉 Pipeline startup completed!"
echo "=============================="
echo ""
echo "📊 Service URLs:"
echo "  - Flink Web UI: http://localhost:8081"
echo "  - StarRocks FE: http://localhost:8030"
echo "  - Metabase: http://localhost:3000"
echo ""
echo "🔧 Management Commands:"
echo "  - Check pipeline status: $DOCKER_COMPOSE_CMD ps"
echo "  - View logs: $DOCKER_COMPOSE_CMD logs [service]"
echo "  - Test pipeline: ./scripts/test-pipeline.sh"
echo "  - Stop pipeline: ./stop-pipeline.sh"
echo ""
echo "📈 Next Steps:"
echo "1. Open Metabase at http://localhost:3000"
echo "2. Configure StarRocks connection:"
echo "   - Type: MySQL"
echo "   - Host: localhost"
echo "   - Port: 9030"
echo "   - Database: ecommerce_dw"
echo "   - Username: root"
echo "   - Password: (empty)"
echo "3. Create dashboards using the analytical views"
echo ""
echo "✨ Your real-time data pipeline is now running!" 