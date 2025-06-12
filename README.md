# 🚀 Real-Time Streaming ETL Pipeline

**Modern CDC + ETL Pipeline with Real-time Transformations**

## 📊 Architecture Overview

```
PostgreSQL → CDC (Real-time) → Flink ETL → StarRocks Clean Tables
```

**Option 2: Unified Streaming Pipeline**
- Direct CDC from PostgreSQL with replication slots
- Real-time business transformations in Flink
- Enriched data streamed to StarRocks clean tables
- No intermediate raw storage required

## ⚡ Key Features

### 🔄 **Real-time CDC Capture**
- PostgreSQL replication slots for change capture
- Zero-latency data streaming
- Fault-tolerant with exactly-once processing

### 🛠️ **Business Transformations**
- **Orders**: Status normalization, date extraction, delivery analysis
- **Order Items**: Pricing categorization (HIGH/MEDIUM/LOW) 
- **Products**: Category grouping (Electronics, Fashion, etc.)
- **Reviews**: Sentiment analysis (EXCELLENT/GOOD/AVERAGE/POOR)
- **Payments**: Payment type categorization, high-value detection

### 📈 **Analytics-Ready Output**
- Clean, transformed data in StarRocks
- Optimized for real-time analytics
- Business logic pre-applied

## 🚀 Quick Start

### 1. Start Infrastructure
```bash
docker compose up -d
./scripts/setup-data.sh
```

### 2. Run Streaming ETL Pipeline  
```bash
./scripts/run-streaming-etl.sh
```

### 3. Test the Pipeline
```bash
./scripts/test-pipeline.sh
```

## 🎯 Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **Flink Web UI** | http://localhost:8081 | Monitor streaming jobs |
| **StarRocks FE** | http://localhost:8030 | Query interface |
| **Metabase** | http://localhost:3000 | Analytics dashboards |

## 📋 Project Structure

```
├── docker-compose.yml          # Infrastructure setup
├── scripts/
│   ├── setup-data.sh          # Database initialization  
│   ├── run-streaming-etl.sh   # Main pipeline script
│   └── test-pipeline.sh       # Pipeline testing
├── flink/
│   └── java-etl/              # Streaming ETL jobs
├── sql/
│   ├── postgres/              # PostgreSQL schemas
│   └── starrocks/             # StarRocks schemas
└── metabase/                  # Dashboard configs
```

## 🔧 Management Commands

### Check Pipeline Status
```bash
# Check running Flink jobs
curl http://localhost:8081/jobs

# Check data in StarRocks
mysql -h 127.0.0.1 -P 9030 -u root -e "USE ecommerce_ods_clean; SELECT COUNT(*) FROM ods_orders;"
```

### Pipeline Operations
```bash
# Start pipeline
./scripts/run-streaming-etl.sh

# Test with sample data  
./scripts/run-streaming-etl.sh --test

# Test transformations
./scripts/test-pipeline.sh
```

## 📊 Data Flow Examples

### Order Processing
```sql
-- Input (PostgreSQL)
INSERT INTO orders VALUES ('O001', 'C001', 'processing', NOW(), ...);

-- Output (StarRocks Clean)
SELECT order_id, order_status, order_year, is_delivered 
FROM ods_orders WHERE order_id = 'O001';
-- Result: 'O001', 'PROCESSING', 2025, false
```

### Pricing Analytics
```sql
-- Input: price = 150.00, freight = 15.50
-- Output: total_value = 165.50, category = 'HIGH'
```

### Category Grouping
```sql
-- Input: 'informatica_acessorios' 
-- Output: category_group = 'Electronics'
```

## 🧪 Sample Transformations

| Component | Input | Transformation | Output |
|-----------|-------|---------------|--------|
| **Orders** | `'processing'` | Status normalization | `'PROCESSING'` |
| **Orders** | `order_purchase_timestamp` | Date extraction | `order_year`, `order_month` |
| **Order Items** | `price >= 100` | Pricing category | `'HIGH'` |
| **Products** | `'informatica_%'` | Category grouping | `'Electronics'` |
| **Reviews** | `review_score >= 4` | Sentiment analysis | `'GOOD'`, `is_positive = true` |
| **Payments** | `'credit_card'` | Payment categorization | `'CARD_PAYMENT'` |

## 🛡️ Fault Tolerance

- **Checkpointing**: 30-second intervals
- **Exactly-once processing**: No data loss or duplication  
- **Replication slots**: Persistent CDC state
- **Automatic restart**: Failed jobs auto-recover

## 📈 Performance

- **Latency**: < 5 seconds end-to-end
- **Throughput**: Handles high-volume e-commerce data
- **Scalability**: Flink parallelism configurable
- **Storage**: Optimized StarRocks columnar format

## 🔍 Monitoring

### Flink Dashboard
- Job status and metrics
- Throughput and latency graphs
- Checkpoint status
- Error logs and recovery

### Data Quality
```bash
# Verify data consistency
./scripts/test-pipeline.sh

# Check transformation accuracy
mysql -h 127.0.0.1 -P 9030 -u root -e "
SELECT 
    price_category,
    COUNT(*) as items,
    AVG(price) as avg_price
FROM ecommerce_ods_clean.ods_order_items 
GROUP BY price_category;
"
```

## 🎯 Use Cases

- **Real-time Analytics**: Live dashboards with transformed data
- **Business Intelligence**: Clean data for reporting
- **Machine Learning**: Feature-ready datasets  
- **Data Lake**: Structured data for advanced analytics

---

**Built with:** Apache Flink • PostgreSQL CDC • StarRocks • Docker 