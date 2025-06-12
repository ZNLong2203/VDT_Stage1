#!/bin/bash

# =============================================================================
# 🚀 Enhanced Streaming ETL Pipeline with Data Validation
# PostgreSQL CDC → Validate → Transform → StarRocks Clean/Error Tables
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emoji functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLINK_HOME="$PROJECT_ROOT/flink-local/flink-1.18.0"
JAVA_ETL_DIR="$PROJECT_ROOT/flink/java-etl"
JAR_FILE="$JAVA_ETL_DIR/target/flink-etl-pipeline-1.0.0.jar"

log_info "🚀 Starting Enhanced Streaming ETL Pipeline with Data Validation..."
log_info "📍 Project root: $PROJECT_ROOT"
log_info "🎯 Features: Real-time validation, Error tables, Business rules"

# Function to check if Flink cluster is running
check_flink_cluster() {
    if ! curl -s "http://localhost:8081/config" > /dev/null 2>&1; then
        log_error "Flink cluster is not running!"
        log_info "🔧 Starting Flink cluster..."
        cd "$FLINK_HOME"
        ./bin/start-cluster.sh
        log_success "Flink cluster started"
        
        # Wait for Flink to be ready
        log_info "⏳ Waiting for Flink to be ready..."
        for i in {1..30}; do
            if curl -s "http://localhost:8081/config" > /dev/null 2>&1; then
                log_success "Flink cluster is ready!"
                break
            fi
            sleep 2
            if [ $i -eq 30 ]; then
                log_error "Flink cluster failed to start properly"
                exit 1
            fi
        done
    else
        log_success "Flink cluster is already running"
    fi
}

# Function to build Java ETL
build_java_etl() {
    log_info "🔨 Building Java ETL pipeline..."
    cd "$JAVA_ETL_DIR"
    
    if mvn clean package -DskipTests; then
        log_success "Java ETL built successfully"
    else
        log_error "Failed to build Java ETL"
        exit 1
    fi
    
    if [ ! -f "$JAR_FILE" ]; then
        log_error "JAR file not found: $JAR_FILE"
        exit 1
    fi
    
    log_success "JAR file ready: $(basename $JAR_FILE)"
}

# Function to cancel existing jobs
cancel_existing_jobs() {
    log_info "🧹 Checking for existing ETL jobs..."
    
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
        log_warning "Found existing running jobs, cancelling them..."
        cd "$FLINK_HOME"
        for job_id in $JOBS; do
            log_info "Cancelling job: $job_id"
            ./bin/flink cancel "$job_id" 2>/dev/null || true
        done
        sleep 5
        log_success "Existing jobs cancelled"
    else
        log_info "No existing jobs found"
    fi
}

# Function to submit ETL job
submit_etl_job() {
    log_info "📤 Submitting Enhanced ETL job with validation..."
    cd "$FLINK_HOME"
    
    if ./bin/flink run --detached --class "com.vdt.etl.OdsETLJob" "$JAR_FILE"; then
        log_success "Enhanced ETL job submitted successfully!"
    else
        log_error "Failed to submit ETL job"
        exit 1
    fi
    
    # Wait a bit for jobs to initialize
    sleep 5
    
    # Check job status
    log_info "📊 Checking job status..."
    RUNNING_JOBS=$(curl -s "http://localhost:8081/jobs" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    running_jobs = [job for job in data.get('jobs', []) if job.get('status') == 'RUNNING']
    print(f'Found {len(running_jobs)} running jobs')
    for job in running_jobs[:5]:  # Show first 5
        job_name = job.get('id', 'unknown')[:8] + '...'
        print(f'  - Job {job_name}: RUNNING')
except Exception as e:
    print('Could not parse job status')
" 2>/dev/null)
    
    log_success "ETL Pipeline Status:"
    echo "$RUNNING_JOBS"
}

# Function to verify data flow
verify_data_flow() {
    log_info "🔍 Verifying data flow..."
    
    # Check PostgreSQL
    PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
        SELECT 'PostgreSQL Source' as component, 
               COUNT(*) as total_records 
        FROM orders 
        UNION ALL
        SELECT 'Order Items', COUNT(*) FROM order_items
        UNION ALL  
        SELECT 'Products', COUNT(*) FROM products
        UNION ALL
        SELECT 'Payments', COUNT(*) FROM payments
        UNION ALL
        SELECT 'Reviews', COUNT(*) FROM reviews;
    " 2>/dev/null | head -10
    
    echo ""
    log_info "⏳ Waiting 10 seconds for data to flow through pipeline..."
    sleep 10
    
    # Check StarRocks Clean tables
    mysql -h 127.0.0.1 -P 9030 -u root -e "
        USE ecommerce_ods_clean;
        SELECT 'StarRocks Clean - Orders' as component, COUNT(*) as records FROM ods_orders
        UNION ALL
        SELECT 'StarRocks Clean - Order Items', COUNT(*) FROM ods_order_items  
        UNION ALL
        SELECT 'StarRocks Clean - Products', COUNT(*) FROM ods_products
        UNION ALL
        SELECT 'StarRocks Clean - Payments', COUNT(*) FROM ods_payments
        UNION ALL
        SELECT 'StarRocks Clean - Reviews', COUNT(*) FROM ods_reviews
        UNION ALL
        SELECT 'Error Tables - Orders', COUNT(*) FROM ods_orders_error
        UNION ALL
        SELECT 'Error Log - All', COUNT(*) FROM ods_error_log;
    " 2>/dev/null | head -15
}

# Function to test pipeline with new data
test_pipeline() {
    log_info "🧪 Testing pipeline with new data..."
    
    # Insert test data (both valid and invalid)
    TIMESTAMP=$(date +%s)
    PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d ecommerce -c "
        -- Insert valid test product
        INSERT INTO products (product_id, product_category_name) 
        VALUES ('test_product_${TIMESTAMP}', 'informatica_teste');
        
        -- Insert valid test order
        INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date)
        VALUES ('test_order_${TIMESTAMP}', (SELECT customer_id FROM customers LIMIT 1), 'processing', NOW(), NOW() + INTERVAL '7 days');
        
        -- Insert valid test order item
        INSERT INTO order_items (order_id, product_id, price, freight_value)
        VALUES ('test_order_${TIMESTAMP}', 'test_product_${TIMESTAMP}', 175.50, 12.25);
        
        -- Insert valid test payment
        INSERT INTO payments (order_id, payment_type, payment_value)
        VALUES ('test_order_${TIMESTAMP}', 'credit_card', 187.75);
        
        -- Insert INVALID test data to test error handling
        INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp) 
        VALUES ('', (SELECT customer_id FROM customers LIMIT 1), 'invalid_status', NOW());
        
        INSERT INTO order_items (order_id, product_id, price, freight_value)
        VALUES ('test_order_${TIMESTAMP}', '', -50.0, 12.25);
    " 2>/dev/null
    
    log_success "Test data inserted (timestamp: $TIMESTAMP)"
    
    log_info "⏳ Waiting 15 seconds for CDC to process..."
    sleep 15
    
    # Verify transformations
    log_info "🔍 Verifying ETL transformations..."
    mysql -h 127.0.0.1 -P 9030 -u root -e "
        USE ecommerce_ods_clean;
        SELECT 'Test Order' as type, order_id, order_status, order_year, is_delivered 
        FROM ods_orders WHERE order_id = 'test_order_${TIMESTAMP}'
        UNION ALL
        SELECT 'Test Order Item' as type, order_id, price, total_item_value, price_category 
        FROM ods_order_items WHERE order_id = 'test_order_${TIMESTAMP}'
        UNION ALL  
        SELECT 'Test Payment' as type, order_id, payment_type, payment_category, is_high_value
        FROM ods_payments WHERE order_id = 'test_order_${TIMESTAMP}'
        UNION ALL
        SELECT 'Test Product' as type, product_id, product_category_name, category_group, NULL
        FROM ods_products WHERE product_id = 'test_product_${TIMESTAMP}';
    " 2>/dev/null
    
    log_success "🎉 Pipeline test completed!"
}

# Main execution
main() {
    echo "=================================================="
    echo "🚀 Enhanced Streaming ETL Pipeline with Validation"
    echo "=================================================="
    echo "📊 Architecture: PostgreSQL CDC → Validate → Transform → StarRocks Clean/Error"
    echo "⚡ Features: Real-time validation, error handling, business rules, data quality"
    echo ""
    
    # Check if services are running
    if ! docker ps | grep -q starrocks-allin1; then
        log_error "StarRocks container is not running!"
        log_info "Please start with: docker compose up -d"
        exit 1
    fi
    
    if ! docker ps | grep -q postgres-cdc; then
        log_error "PostgreSQL container is not running!"
        log_info "Please start with: docker compose up -d"
        exit 1
    fi
    
    # Execute pipeline
    check_flink_cluster
    build_java_etl
    cancel_existing_jobs
    submit_etl_job
    verify_data_flow
    
    if [ "${1:-}" = "--test" ]; then
        test_pipeline
    fi
    
    echo ""
    echo "=================================================="
    log_success "🎉 Enhanced Streaming ETL Pipeline with Validation is RUNNING!"
    echo "=================================================="
    echo ""
    echo "📍 Access Points:"
    echo "  🌐 Flink Web UI:    http://localhost:8081"
    echo "  🗄️  StarRocks FE:    http://localhost:8030"  
    echo "  📊 Metabase:        http://localhost:3000"
    echo ""
    echo "🔧 Management Commands:"
    echo "  📊 Check jobs:      curl http://localhost:8081/jobs"
    echo "  📈 Check data:      mysql -h 127.0.0.1 -P 9030 -u root -e 'USE ecommerce_ods_clean; SELECT COUNT(*) FROM ods_orders;'"
    echo "  🧪 Test pipeline:   $0 --test"
    echo "  ❌ Check errors:    mysql -h 127.0.0.1 -P 9030 -u root -e 'USE ecommerce_ods_clean; SELECT * FROM ods_orders_error LIMIT 5;'"
    echo ""
    echo "🎯 Pipeline is processing real-time CDC events with data validation and error handling!"
    echo "✅ Valid records → Clean tables | ❌ Invalid records → Error tables"
}

# Run main function
main "$@" 