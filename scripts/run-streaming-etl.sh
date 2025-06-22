#!/bin/bash

set -e

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLINK_HOME="$PROJECT_ROOT/flink-local/flink-1.18.0"
JAVA_ETL_DIR="$PROJECT_ROOT/flink/java-etl"
JAR_FILE="$JAVA_ETL_DIR/target/flink-etl-pipeline-1.0.0.jar"

echo "Starting Streaming ETL Pipeline..."

check_flink_cluster() {
    if ! curl -s "http://localhost:8081/config" > /dev/null 2>&1; then
        echo "Starting Flink cluster..."
        cd "$FLINK_HOME"
        ./bin/start-cluster.sh
        
        for i in {1..30}; do
            if curl -s "http://localhost:8081/config" > /dev/null 2>&1; then
                echo "Flink cluster ready"
                break
            fi
            sleep 2
            if [ $i -eq 30 ]; then
                echo "ERROR: Flink cluster failed to start"
                exit 1
            fi
        done
    fi
}

build_java_etl() {
    echo "Building Java ETL..."
    cd "$JAVA_ETL_DIR"
    
    if mvn clean package -DskipTests; then
        echo "Build completed"
    else
        echo "ERROR: Build failed"
        exit 1
    fi
    
    if [ ! -f "$JAR_FILE" ]; then
        echo "ERROR: JAR file not found"
        exit 1
    fi
}

cancel_existing_jobs() {
    JOBS=$(curl -s "http://localhost:8081/jobs" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    running_jobs = [job['id'] for job in data.get('jobs', []) if job.get('status') == 'RUNNING']
    print(' '.join(running_jobs))
except:
    pass
" 2>/dev/null)

    if [ -n "$JOBS" ]; then
        echo "Cancelling existing jobs..."
        cd "$FLINK_HOME"
        for job_id in $JOBS; do
            ./bin/flink cancel "$job_id" 2>/dev/null || true
        done
        sleep 5
    fi
}

submit_etl_job() {
    echo "Submitting ETL job..."
    cd "$FLINK_HOME"
    
    if ./bin/flink run --detached --class "com.vdt.etl.OdsETLJob" "$JAR_FILE"; then
        echo "ETL job submitted successfully"
    else
        echo "ERROR: Failed to submit ETL job"
        exit 1
    fi
    
    sleep 5
}

main() {
    if ! docker ps | grep -q starrocks-allin1; then
        echo "ERROR: StarRocks not running. Start with: docker compose up -d"
        exit 1
    fi
    
    if ! docker ps | grep -q postgres-cdc; then
        echo "ERROR: PostgreSQL not running. Start with: docker compose up -d"
        exit 1
    fi
    
    check_flink_cluster
    build_java_etl
    cancel_existing_jobs
    submit_etl_job
    
    echo ""
    echo "ETL Pipeline is RUNNING"
    echo "Access Points:"
    echo "  Flink Web UI: http://localhost:8081"
    echo "  StarRocks FE: http://localhost:8030"  
    echo "  Metabase: http://localhost:3000"
    echo ""
    echo "Check jobs: curl http://localhost:8081/jobs"
}

main "$@" 