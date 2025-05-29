#!/bin/bash

# Setup Flink CDC Local Environment
set -e

FLINK_VERSION="1.18.0"
FLINK_SCALA_VERSION="2.12"
FLINK_DIR="flink-${FLINK_VERSION}"
FLINK_PACKAGE="flink-${FLINK_VERSION}-bin-scala_${FLINK_SCALA_VERSION}.tgz"
FLINK_URL="https://archive.apache.org/dist/flink/flink-${FLINK_VERSION}/${FLINK_PACKAGE}"

echo "🚀 Setting up Flink CDC Local Environment..."

# Create flink directory if it doesn't exist
mkdir -p flink-local

cd flink-local

# Download Flink if not already downloaded
if [ ! -d "$FLINK_DIR" ]; then
    echo "📥 Downloading Flink ${FLINK_VERSION}..."
    if [ ! -f "$FLINK_PACKAGE" ]; then
        wget "$FLINK_URL"
    fi
    
    echo "📦 Extracting Flink..."
    tar -xzf "$FLINK_PACKAGE"
    
    echo "🧹 Cleaning up archive..."
    rm "$FLINK_PACKAGE"
fi

cd "$FLINK_DIR"

# Download CDC connectors
echo "📥 Downloading Flink CDC connectors..."

# Create lib directory for connectors
mkdir -p lib-cdc

# Download PostgreSQL CDC connector (using com.ververica group)
CDC_VERSION="3.0.1"
POSTGRES_CDC_JAR="flink-sql-connector-postgres-cdc-${CDC_VERSION}.jar"
if [ ! -f "lib-cdc/$POSTGRES_CDC_JAR" ]; then
    echo "  - PostgreSQL CDC connector..."
    wget -O "lib-cdc/$POSTGRES_CDC_JAR" \
        "https://repo1.maven.org/maven2/com/ververica/flink-sql-connector-postgres-cdc/${CDC_VERSION}/${POSTGRES_CDC_JAR}"
fi

# Download StarRocks connector
STARROCKS_VERSION="1.2.9_flink-1.18"
STARROCKS_JAR="flink-connector-starrocks-${STARROCKS_VERSION}.jar"
if [ ! -f "lib-cdc/$STARROCKS_JAR" ]; then
    echo "  - StarRocks connector..."
    wget -O "lib-cdc/$STARROCKS_JAR" \
        "https://repo1.maven.org/maven2/com/starrocks/flink-connector-starrocks/${STARROCKS_VERSION}/${STARROCKS_JAR}"
fi

# Download PostgreSQL JDBC driver
POSTGRES_JDBC_VERSION="42.7.1"
POSTGRES_JDBC_JAR="postgresql-${POSTGRES_JDBC_VERSION}.jar"
if [ ! -f "lib-cdc/$POSTGRES_JDBC_JAR" ]; then
    echo "  - PostgreSQL JDBC driver..."
    wget -O "lib-cdc/$POSTGRES_JDBC_JAR" \
        "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_JDBC_VERSION}/${POSTGRES_JDBC_JAR}"
fi

# Copy connectors to Flink lib directory
echo "📋 Installing connectors to Flink lib..."
cp lib-cdc/*.jar lib/

# Update Flink configuration
echo "⚙️  Updating Flink configuration..."
cat >> conf/flink-conf.yaml << EOF

# CDC Configuration
execution.checkpointing.interval: 3s
execution.checkpointing.mode: EXACTLY_ONCE
state.backend: rocksdb
state.checkpoints.dir: file:///tmp/flink-checkpoints
state.savepoints.dir: file:///tmp/flink-savepoints

# Memory configuration
taskmanager.memory.process.size: 2g
jobmanager.memory.process.size: 1g

# Parallelism
parallelism.default: 1
EOF

echo "✅ Flink CDC setup completed!"
echo ""
echo "📍 Flink installation location: $(pwd)"
echo "🎯 To start Flink cluster:"
echo "   cd $(pwd)"
echo "   ./bin/start-cluster.sh"
echo ""
echo "🌐 Flink Web UI will be available at: http://localhost:8081"
echo "🛑 To stop Flink cluster:"
echo "   ./bin/stop-cluster.sh" 