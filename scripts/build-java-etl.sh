#!/bin/bash

# Build Java ETL Project
# This script compiles and packages the Java Flink ETL job

set -e

echo "🔧 Building Java Flink ETL Project..."

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven is not installed. Please install Maven first."
    echo "   Ubuntu/Debian: sudo apt install maven"
    echo "   CentOS/RHEL: sudo yum install maven"
    exit 1
fi

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed. Please install Java 11 or later."
    exit 1
fi

# Navigate to Java ETL project directory
cd flink/java-etl

echo "📦 Cleaning previous builds..."
mvn clean

echo "🔨 Compiling and packaging ETL job..."
mvn package -DskipTests

if [ $? -eq 0 ]; then
    echo "✅ Java ETL build completed successfully!"
    echo "📁 JAR file location: flink/java-etl/target/flink-etl-pipeline-1.0.0.jar"
    
    # Check if jar file exists
    if [ -f "target/flink-etl-pipeline-1.0.0.jar" ]; then
        echo "📊 JAR file size: $(du -h target/flink-etl-pipeline-1.0.0.jar | cut -f1)"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "🎯 Next steps:"
echo "   1. Run the ETL job: ./scripts/run-java-etl.sh"
echo "   2. Monitor job status in Flink UI: http://localhost:8081" 