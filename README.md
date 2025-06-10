# Real-Time Data Pipeline: PostgreSQL CDC → Flink → StarRocks → Metabase

Dự án này minh họa một data pipeline real-time hoàn chỉnh sử dụng **Olist Brazilian E-Commerce Dataset** thật:
- **PostgreSQL** làm CDC source với Olist e-commerce data (7 bảng nguồn, CDC 5 bảng chọn lọc)
- **Apache Flink 1.18** với CDC connectors cho real-time streaming (local installation)
- **StarRocks** all-in-one làm OLAP analytical database
- **Metabase** cho business intelligence và dashboarding

## Architecture Overview

```
PostgreSQL (Olist Dataset) → Flink CDC (5 Selected Tables) → StarRocks ODS → Metabase (BI)
```

## 📊 Olist Dataset Schema

Pipeline sử dụng **Olist Brazilian E-Commerce Dataset** với **CDC 5 bảng chính**:

### PostgreSQL Source (7 tables total):
- **`customers`** - Thông tin khách hàng (customer_id, city, state, zip_code)
- **`sellers`** - Thông tin người bán (seller_id, city, state, zip_code)  
- **`products`** - Catalog sản phẩm (product_id, category, dimensions, weight)
- **`orders`** - Đơn hàng (order_id, status, timestamps, customer_id)
- **`order_items`** - Chi tiết sản phẩm trong đơn (order_id, product_id, seller_id, price)
- **`payments`** - Thanh toán (order_id, payment_type, value, installments)
- **`reviews`** - Đánh giá (review_id, order_id, score, comments)

### StarRocks ODS (5 selected tables with filtered columns):
- **`ods_orders`** - Order facts (order_id, customer_id, status, timestamps)
- **`ods_order_items`** - Order item facts (order_id, product_id, price, freight_value)
- **`ods_products`** - Product dimension (product_id, category_name)
- **`ods_payments`** - Payment facts (order_id, payment_type, payment_value)
- **`ods_reviews`** - Review facts (order_id, review_score)

## 🚀 Quick Start (Lần đầu mở project)

### Prerequisites
- **Docker và Docker Compose** - để chạy các services containerized
- **Java 8+** - để chạy Flink local
- **MySQL client** - để kết nối StarRocks
- **Ít nhất 8GB RAM** để chạy tất cả services
- **Dataset CSV files** - đặt trong folder `dataset/`

### 1. First Time Setup (Chạy một lần duy nhất)

```bash
# Clone project
git clone <repository>
cd VDT_Stage1

# Đảm bảo có dataset CSV files trong folder dataset/
ls dataset/
# Cần có: olist_customers_dataset.csv, olist_sellers_dataset.csv, 
#         olist_products_dataset.csv, olist_orders_dataset.csv,
#         olist_order_items_dataset.csv, olist_order_payments_dataset.csv,
#         olist_order_reviews_dataset.csv

# Khởi động toàn bộ pipeline (first time)
./start-pipeline.sh
```

Script này sẽ tự động:
- ✅ Kiểm tra prerequisites (Docker, Java, MySQL client)
- ✅ Start tất cả Docker containers (PostgreSQL, StarRocks, Metabase)
- ✅ Download và setup Flink CDC local
- ✅ Load toàn bộ Olist dataset vào PostgreSQL (7 bảng)
- ✅ Tạo replication slots cho 5 bảng được chọn
- ✅ Setup StarRocks ODS schema (5 bảng)
- ✅ Start Flink cluster
- ✅ Submit 5 CDC jobs
- ✅ Chạy test pipeline tự động

### 2. Subsequent Starts (Những lần sau)

```bash
# Quick start cho những lần mở project tiếp theo
./quick-start.sh
```

## 🧪 Testing Pipeline

### Test Real-time CDC
```bash
# Test luồng CDC real-time với 5 bảng được chọn
./scripts/test-pipeline.sh
```

Test này sẽ:
- Insert test records vào 5 bảng PostgreSQL
- Kiểm tra dữ liệu có xuất hiện trong StarRocks ODS trong <15 giây
- Báo cáo kết quả PASS/FAIL cho 5 bảng được CDC

### Kiểm tra Status
```bash
# Kiểm tra trạng thái toàn bộ pipeline
./check-status.sh
```

### Manual Testing
```bash
# Insert test data vào PostgreSQL
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp) 
VALUES ('manual_test_001', (SELECT customer_id FROM customers LIMIT 1), 'processing', NOW());
"

# Kiểm tra trong StarRocks (sau ~5 giây)
mysql -h localhost -P 9030 -u root --protocol=TCP -e "
USE ecommerce_dw; 
SELECT * FROM ods_orders WHERE order_id = 'manual_test_001';
"
```

## 📊 Services và Ports

| Service | Port | Description | URL |
|---------|------|-------------|-----|
| PostgreSQL | 5432 | Source database với Olist dataset (7 bảng) | `postgresql://localhost:5432/ecommerce` |
| Flink Web UI | 8081 | Flink cluster management (5 CDC jobs) | http://localhost:8081 |
| StarRocks FE | 8030 | StarRocks Frontend (HTTP) | http://localhost:8030 |
| StarRocks MySQL | 9030 | StarRocks MySQL protocol | `mysql://localhost:9030` |
| Metabase | 3000 | BI Dashboard | http://localhost:3000 |

## 🔧 Management Commands

```bash
# Start pipeline
./start-pipeline.sh          # Lần đầu tiên (load dataset)
./quick-start.sh            # Những lần sau

# Test pipeline
./scripts/test-pipeline.sh   # Test real-time CDC cho 5 bảng được chọn

# Check status
./check-status.sh           # Kiểm tra trạng thái tất cả services

# Stop pipeline
./stop-pipeline.sh          # Dừng toàn bộ pipeline

# Manual operations
docker compose ps           # Xem containers
docker compose logs postgres # Xem logs PostgreSQL
```

## 📈 Metabase Setup

1. Mở http://localhost:3000
2. Complete initial setup
3. Add StarRocks database:
   - **Type**: MySQL
   - **Host**: localhost
   - **Port**: 9030
   - **Database**: ecommerce_dw
   - **Username**: root
   - **Password**: (để trống)

4. Sử dụng các analytical views có sẵn:
   - `daily_order_summary` - Tóm tắt đơn hàng theo ngày
   - `payment_by_type` - Phân tích thanh toán theo loại
   - `review_by_status` - Review theo trạng thái đơn hàng

## 🗂️ Real Dataset Information

**Olist Brazilian E-Commerce Dataset** bao gồm:
- **~100K orders** từ 2016-2018
- **~100K customers** trên toàn Brazil
- **~3K sellers** 
- **~33K products** với 74 categories
- **~100K payments** với nhiều phương thức
- **~100K reviews** với scores 1-5

**CDC chỉ stream 5 bảng quan trọng** để tối ưu hóa performance và tập trung vào analytical workload.

## 📋 Real-Time Testing Workflow

1. **Kiểm tra pipeline status**:
   ```bash
   ./check-status.sh
   ```

2. **Chạy automated test**:
   ```bash
   ./scripts/test-pipeline.sh
   ```

3. **Test manual real-time**:
   ```bash
   # Insert trong PostgreSQL
   docker exec postgres-cdc psql -U postgres -d ecommerce -c "
   INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp) 
   VALUES ('manual_order_001', (SELECT customer_id FROM customers LIMIT 1), 'processing', NOW());
   "
   
   # Kiểm tra StarRocks sau 5 giây
   mysql -h localhost -P 9030 -u root --protocol=TCP -e "
   USE ecommerce_dw; SELECT * FROM ods_orders WHERE order_id = 'manual_order_001';
   "
   ```

## 🛠️ Troubleshooting

### Flink không start được
```bash
# Kiểm tra Java version
java -version

# Restart Flink
cd flink-local/flink-1.18.0
./bin/stop-cluster.sh
./bin/start-cluster.sh
```

### StarRocks connection failed
```bash
# Kiểm tra container
docker ps | grep starrocks

# Kiểm tra MySQL connection
mysql -h localhost -P 9030 -u root --protocol=TCP -e "SELECT 1;"
```

### CDC jobs không chạy
```bash
# Kiểm tra replication slots (should see 5 slots)
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
SELECT slot_name, active FROM pg_replication_slots;
"

# Submit lại CDC jobs
./scripts/run-flink-cdc-job.sh
```

### Dataset loading issues
```bash
# Kiểm tra CSV files
ls -la dataset/

# Kiểm tra PostgreSQL logs
docker logs postgres-cdc

# Manual data check
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
SELECT 'customers', COUNT(*) FROM customers UNION
SELECT 'orders', COUNT(*) FROM orders;
"
```

## ⚡ Performance Characteristics

- **Latency**: End-to-end < 5 seconds cho real-time updates
- **Throughput**: Thousands of transactions per second  
- **Data Volume**: ~600K+ records từ Olist dataset (PostgreSQL), CDC chỉ 5 bảng quan trọng
- **Reliability**: Exactly-once processing semantics
- **Scalability**: Horizontal scaling via Flink parallelism

## 🧹 Cleanup

```bash
# Stop toàn bộ pipeline
./stop-pipeline.sh

# Xóa tất cả data
docker compose down -v

# Xóa Flink installation (optional)
rm -rf flink-local/
```

## 📚 Architecture Details

Chi tiết technical documentation xem trong `docs/architecture.md`.

## 🎯 Expected Results

Sau khi chạy `./scripts/test-pipeline.sh`, bạn sẽ thấy:

```
🧪 Testing Real-Time Data Pipeline for 5 Selected Tables...
📝 Inserting new product into PostgreSQL...
📝 Inserting new order into PostgreSQL...
📝 Inserting order item into PostgreSQL...
📝 Inserting payment into PostgreSQL...
📝 Inserting review into PostgreSQL...
⏳ Waiting for CDC to propagate changes (15 seconds)...
🔍 Checking data in StarRocks ODS tables...
✅ Pipeline test PASSED! All 5 selected tables successfully replicated to StarRocks.
```

Pipeline đã sẵn sàng với **5 bảng được chọn lọc** từ Olist e-commerce data và real-time streaming tối ưu! 🚀 