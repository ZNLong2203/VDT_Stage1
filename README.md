# Building a Real-Time Reporting System with ODS

## Architecture

```
PostgreSQL → Apache Flink → StarRocks → Metabase
```

Dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Features

- **Real-time CDC**: PostgreSQL replication slots for change capture
- **Stream Processing**: Apache Flink for real-time transformations
- **ODS**: StarRocks for analytical storage
- **Business Intelligence**: Metabase for dashboards and reporting
- **Data Quality**: Validation with clean/error table separation

## Quick Start

1. **Start Infrastructure**
   ```bash
   docker compose up -d
   ./scripts/setup-data.sh
   ```

2. **Run ETL Pipeline**
   ```bash
   ./scripts/run-streaming-etl.sh
   ```

3. **Generate Demo Data** 
   ```bash
   cd demo-data-generator
   mvn clean package
   mvn exec:java
   ```

## Access Points

| Service | URL | Description |
|---------|-----|-------------|
| **Flink Web UI** | http://localhost:8081 | Monitor streaming jobs |
| **StarRocks FE** | http://localhost:8030 | Query interface |
| **Metabase** | http://localhost:3000 | Analytics dashboards |
| **PostgreSQL** | localhost:5432 | Source database |

## Project Structure

```
├── docker-compose.yml          # Infrastructure setup
├── scripts/                    # Pipeline management scripts
├── flink/java-etl/            # Flink streaming jobs
├── demo-data-generator/       # Real-time data generator
├── sql/                       # Database schemas
└── metabase-queries/          # Dashboard queries
```
