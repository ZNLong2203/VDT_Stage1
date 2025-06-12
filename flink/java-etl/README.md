# Java Flink ETL: ODS Raw → ODS Clean

This Java Flink ETL job transforms data from ODS Raw tables to ODS Clean tables with data enrichment and business logic.

## Overview

The ETL job reads data from StarRocks ODS Raw tables (populated by CDC) and applies transformations to create enriched, clean data for analytics.

## Transformations Applied

### 📋 Orders (`ods_orders`)
- **Data Cleaning**: Status normalization (UPPER case)
- **Date Extraction**: Year, month, day from purchase timestamp  
- **Business Logic**: Delivery delay calculation, delivery status flag
- **Enrichment**: `delivery_delay_days`, `is_delivered`, `order_year/month/day`

### 🛒 Order Items (`ods_order_items`)
- **Data Cleaning**: Handle NULL prices and freight values
- **Business Logic**: Total item value calculation
- **Categorization**: Price categories (HIGH ≥100, MEDIUM ≥50, LOW <50)
- **Enrichment**: `total_item_value`, `price_category`

### 📦 Products (`ods_products`)
- **Data Cleaning**: Handle NULL category names
- **Categorization**: Group products into business categories
  - Electronics (informatica, telefonia, eletronicos)
  - Home & Garden (casa, moveis, decoracao)
  - Sports (esporte, fitness)
  - Fashion (moda, roupas, calcados)
  - Beauty (beleza, perfumaria)
- **Enrichment**: `category_group`

### ⭐ Reviews (`ods_reviews`)
- **Data Cleaning**: Handle NULL review scores
- **Sentiment Analysis**: Review categorization
  - EXCELLENT (4-5 stars)
  - GOOD (3 stars)
  - AVERAGE (2 stars)
  - POOR (1 star)
- **Enrichment**: `review_category`, `is_positive_review`

### 💳 Payments (`ods_payments`)
- **Data Cleaning**: Normalize payment types (UPPER case)
- **Categorization**: Payment method grouping
  - CARD_PAYMENT (credit_card, debit_card)
  - BANK_TRANSFER (boleto)
  - VOUCHER_PAYMENT (voucher)
- **Business Logic**: High value payment flag (≥200)
- **Enrichment**: `payment_category`, `is_high_value`

## Quick Start

### 1. Build the Project
```bash
./scripts/build-java-etl.sh
```

### 2. Run ETL Job
```bash
./scripts/run-java-etl.sh
```

### 3. Run Complete Pipeline
```bash
./scripts/run-complete-etl.sh
```

## Architecture

```
PostgreSQL (Source)
    ↓ (CDC)
StarRocks ODS Raw
    ↓ (Java Flink ETL)
StarRocks ODS Clean
    ↓
Metabase (Analytics)
```

## Technologies

- **Apache Flink 1.18.0**: Stream processing engine
- **StarRocks Connector**: Source and sink for StarRocks
- **Maven**: Build and dependency management
- **Java 11+**: Programming language

## Configuration

Default connections (can be modified in `OdsETLJob.java`):
- **StarRocks JDBC**: `jdbc:mysql://localhost:9030`
- **StarRocks Load URL**: `localhost:8030`
- **Source Database**: `ecommerce_ods_raw`
- **Target Database**: `ecommerce_ods_clean`

## Monitoring

- **Flink Web UI**: http://localhost:8081
- **Job Parallelism**: 2 (configurable)
- **Checkpointing**: 30 seconds interval
- **State Backend**: Filesystem (`/tmp/flink-checkpoints`)

## Data Quality Features

- ✅ NULL value handling with COALESCE
- ✅ Data type validation and casting
- ✅ Business rule application
- ✅ Category standardization
- ✅ Metric calculation and enrichment

## Output Schema

All clean tables include original fields plus enriched business fields for enhanced analytics capabilities. 