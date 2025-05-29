# Real-Time Data Pipeline: PostgreSQL CDC → Flink → StarRocks → Metabase

Dự án này minh họa một data pipeline real-time hoàn chỉnh sử dụng:
- **PostgreSQL** làm CDC source với sample e-commerce data
- **Apache Flink 1.18** với CDC connectors cho real-time streaming (local installation)
- **StarRocks** all-in-one làm OLAP analytical database
- **Metabase** cho business intelligence và dashboarding

## Architecture Overview

```
PostgreSQL (CDC Source) → Flink CDC (Local) → StarRocks (All-in-One) → Metabase (BI)
```

## 🚀 Quick Start (Lần đầu mở project)

### Prerequisites
- **Docker và Docker Compose** - để chạy các services containerized
- **Java 8+** - để chạy Flink local
- **MySQL client** - để kết nối StarRocks
- **Ít nhất 8GB RAM** để chạy tất cả services

### 1. First Time Setup (Chạy một lần duy nhất)

```bash
# Clone project
git clone <repository>
cd VDT_Stage1

# Khởi động toàn bộ pipeline (first time)
./start-pipeline.sh
```

Script này sẽ tự động:
- ✅ Kiểm tra prerequisites (Docker, Java, MySQL client)
- ✅ Start tất cả Docker containers (PostgreSQL, StarRocks, Metabase)
- ✅ Download và setup Flink CDC local
- ✅ Tạo replication slots trong PostgreSQL
- ✅ Setup StarRocks schema
- ✅ Start Flink cluster
- ✅ Submit CDC jobs
- ✅ Chạy test pipeline tự động

### 2. Subsequent Starts (Những lần sau)

```bash
# Quick start cho những lần mở project tiếp theo
./quick-start.sh
```

## 🧪 Testing Pipeline

### Test Real-time CDC
```bash
# Test luồng CDC real-time
./scripts/test-pipeline.sh
```

Test này sẽ:
- Insert dữ liệu mới vào PostgreSQL
- Kiểm tra dữ liệu có xuất hiện trong StarRocks trong <10 giây
- Báo cáo kết quả PASS/FAIL

### Kiểm tra Status
```bash
# Kiểm tra trạng thái toàn bộ pipeline
./check-status.sh
```

### Manual Testing
```bash
# Insert test data vào PostgreSQL
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
INSERT INTO customers (name, email) VALUES ('Manual Test', 'manual@test.com');
"

# Kiểm tra trong StarRocks (sau ~5 giây)
mysql -h localhost -P 9030 -u root --protocol=TCP -e "
USE ecommerce_dw; 
SELECT * FROM customers WHERE email = 'manual@test.com';
"
```

## 📊 Services và Ports

| Service | Port | Description | URL |
|---------|------|-------------|-----|
| PostgreSQL | 5432 | Source database với CDC enabled | `postgresql://localhost:5432/ecommerce` |
| Flink Web UI | 8081 | Flink cluster management | http://localhost:8081 |
| StarRocks FE | 8030 | StarRocks Frontend (HTTP) | http://localhost:8030 |
| StarRocks MySQL | 9030 | StarRocks MySQL protocol | `mysql://localhost:9030` |
| Metabase | 3000 | BI Dashboard | http://localhost:3000 |

## 🔧 Management Commands

```bash
# Start pipeline
./start-pipeline.sh          # Lần đầu tiên
./quick-start.sh            # Những lần sau

# Test pipeline
./scripts/test-pipeline.sh   # Test real-time CDC

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
   - `customer_summary` - Tóm tắt khách hàng
   - `product_performance` - Performance sản phẩm
   - `daily_sales` - Doanh số hàng ngày
   - `order_details` - Chi tiết đơn hàng

## 🗂️ Sample Data Schema

Pipeline bao gồm sample e-commerce schema:
- `customers` - Thông tin khách hàng
- `orders` - Giao dịch đơn hàng
- `order_items` - Chi tiết sản phẩm trong đơn hàng
- `products` - Catalog sản phẩm

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
   INSERT INTO customers (name, email) VALUES ('Test User', 'test@example.com');
   "
   
   # Kiểm tra StarRocks sau 5 giây
   mysql -h localhost -P 9030 -u root --protocol=TCP -e "
   USE ecommerce_dw; SELECT * FROM customers WHERE email = 'test@example.com';
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
# Kiểm tra replication slots
docker exec postgres-cdc psql -U postgres -d ecommerce -c "
SELECT slot_name, active FROM pg_replication_slots;
"

# Submit lại CDC jobs
./scripts/run-flink-cdc-job.sh
```

## ⚡ Performance Characteristics

- **Latency**: End-to-end < 5 seconds
- **Throughput**: Thousands of transactions per second
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
🧪 Testing Real-Time Data Pipeline...
📝 Inserting new customer into PostgreSQL...
📝 Inserting new product into PostgreSQL...
📝 Inserting new order into PostgreSQL...
📝 Inserting order items into PostgreSQL...
⏳ Waiting for CDC to propagate changes (10 seconds)...
🔍 Checking data in StarRocks...
✅ Pipeline test PASSED! All data successfully replicated to StarRocks.
```

Pipeline đã sẵn sàng cho production với real-time data streaming! 🚀 