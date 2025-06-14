# Soft Delete and Primary Key Upgrade Documentation

## Tổng Quan Thay Đổi

Dự án đã được nâng cấp từ **DUPLICATE KEY** sang **PRIMARY KEY** trong StarRocks và bổ sung tính năng **Soft Delete** để hỗ trợ update/delete dữ liệu mà không mất dữ liệu lịch sử.

## Các Thay Đổi Chính

### 1. Schema Database Changes

#### 1.1 StarRocks Clean Tables (`sql/starrocks-init.sql`)
- **Thay đổi từ**: `DUPLICATE KEY` → `PRIMARY KEY` 
- **Thêm trường mới**:
  - `is_deleted BOOLEAN NOT NULL DEFAULT FALSE` - cho soft delete
  - `created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP` - audit trail
  - `updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP` - audit trail
- **Kích hoạt**: `enable_persistent_index = true` để hỗ trợ primary key hiệu quả

#### 1.2 StarRocks Error Tables (`sql/create-error-schema.sql`)  
- **Thay đổi tương tự**: `DUPLICATE KEY` → `PRIMARY KEY`
- **Thêm cùng các trường audit**: `is_deleted`, `created_at`, `updated_at`

### 2. Flink ETL Code Changes

#### 2.1 SqlQueries.java 
- **Cập nhật sink definitions** để bao gồm các trường mới
- **Thêm connector properties**:
  - `sink.semantic = exactly-once` - đảm bảo dữ liệu chính xác
  - `sink.properties.partial_update = true` - hỗ trợ partial updates
  - `sink.properties.partial_update_mode = column` - update theo column

#### 2.2 OdsETLJob.java
- **Cập nhật INSERT statements** để bao gồm:
  - `is_deleted = false` cho tất cả records mới
  - `created_at = CURRENT_TIMESTAMP`
  - `updated_at = CURRENT_TIMESTAMP`
- **Thêm utility methods**:
  - `softDeleteOrder()` - soft delete orders
  - `softDeleteProduct()` - soft delete products  
  - `createActiveViewsForAnalytics()` - tạo views chỉ chứa dữ liệu active

#### 2.3 DataValidation.java
- **Cập nhật validation methods** để kiểm tra `is_deleted` flag
- **Thêm validation methods mới**:
  - `validateAuditFields()` - validate created_at, updated_at
  - `validateSoftDeleteOperation()` - validate soft delete operations
  - `validateRestoreOperation()` - validate restore operations
- **Thêm utility methods**:
  - `getCurrentTimestamp()` - lấy timestamp hiện tại
  - `isActiveRecord()` - kiểm tra record có active không

## Lợi Ích Của Thay Đổi

### 3.1 Primary Key Benefits
- ✅ **Hỗ trợ UPDATE/DELETE operations** 
- ✅ **Đảm bảo unique constraints**
- ✅ **Hiệu suất query tốt hơn** với persistent index
- ✅ **Exactly-once processing** đảm bảo data consistency

### 3.2 Soft Delete Benefits  
- ✅ **Không mất dữ liệu lịch sử** khi delete
- ✅ **Có thể restore dữ liệu** đã xóa
- ✅ **Audit trail đầy đủ** với created_at/updated_at
- ✅ **Phân tích dữ liệu linh hoạt** (bao gồm cả deleted records nếu cần)

## Cách Sử Dụng Soft Delete

### 4.1 Soft Delete Operations

```sql
-- Soft delete một order
UPDATE ecommerce_ods_clean.ods_orders 
SET is_deleted = true, updated_at = CURRENT_TIMESTAMP 
WHERE order_id = 'ORDER123';

-- Soft delete một product
UPDATE ecommerce_ods_clean.ods_products 
SET is_deleted = true, updated_at = CURRENT_TIMESTAMP 
WHERE product_id = 'PROD456';
```

### 4.2 Restore Operations

```sql
-- Restore một deleted order
UPDATE ecommerce_ods_clean.ods_orders 
SET is_deleted = false, updated_at = CURRENT_TIMESTAMP 
WHERE order_id = 'ORDER123';
```

### 4.3 Query Active Records Only

```sql
-- Query chỉ active orders
SELECT * FROM ecommerce_ods_clean.ods_orders 
WHERE is_deleted = false;

-- Hoặc sử dụng views được tạo sẵn
SELECT * FROM active_orders;
```

### 4.4 Analytics Including Deleted Records

```sql
-- Phân tích tất cả records (bao gồm deleted)
SELECT 
    is_deleted,
    COUNT(*) as record_count,
    AVG(CASE WHEN is_deleted = false THEN 1 ELSE 0 END) as active_ratio
FROM ecommerce_ods_clean.ods_orders
GROUP BY is_deleted;
```

## Migration Steps

### 5.1 Database Migration
1. **Backup existing data** trước khi migration
2. **Chạy StarRocks init scripts**:
   ```bash
   # Chạy clean database schema
   mysql -h localhost -P 9030 -u root < sql/starrocks-init.sql
   
   # Chạy error database schema  
   mysql -h localhost -P 9030 -u root < sql/create-error-schema.sql
   ```

### 5.2 Application Deployment
1. **Deploy updated Flink job**:
   ```bash
   cd flink/java-etl
   mvn clean package
   # Deploy to Flink cluster
   ```

2. **Restart ETL pipeline**:
   ```bash
   # Sử dụng script có sẵn
   ./scripts/run-streaming-etl.sh
   ```

## Monitoring và Troubleshooting

### 6.1 Health Checks
```sql
-- Kiểm tra data consistency
SELECT 
    'orders' as table_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN is_deleted = false THEN 1 ELSE 0 END) as active_records,
    SUM(CASE WHEN is_deleted = true THEN 1 ELSE 0 END) as deleted_records
FROM ecommerce_ods_clean.ods_orders

UNION ALL

SELECT 
    'products' as table_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN is_deleted = false THEN 1 ELSE 0 END) as active_records,
    SUM(CASE WHEN is_deleted = true THEN 1 ELSE 0 END) as deleted_records
FROM ecommerce_ods_clean.ods_products;
```

### 6.2 Common Issues

1. **Primary Key Violations**
   - Đảm bảo không có duplicate keys khi migrate
   - Check constraint violations trong logs

2. **Partial Update Issues**  
   - Kiểm tra connector properties đã được set đúng
   - Monitor Flink job metrics

3. **Soft Delete Logic Errors**
   - Validate business rules trong DataValidation.java
   - Check audit trail consistency

## Best Practices

### 7.1 Data Operations
- ✅ **Always use soft delete** thay vì hard delete
- ✅ **Update updated_at timestamp** khi modify records  
- ✅ **Use active views** cho analytics thông thường
- ✅ **Regular cleanup** các deleted records cũ (nếu cần)

### 7.2 Code Development
- ✅ **Validate is_deleted flag** trong all operations
- ✅ **Include audit fields** trong INSERT/UPDATE statements
- ✅ **Use validation methods** từ DataValidation.java
- ✅ **Monitor data quality** qua error tables

## Kết Luận

Việc nâng cấp lên Primary Key và Soft Delete đã làm cho hệ thống:
- **Mạnh mẽ hơn** với khả năng update/delete 
- **An toàn hơn** với soft delete mechanism
- **Dễ audit hơn** với timestamp tracking
- **Hiệu suất tốt hơn** với persistent indexing

Hệ thống hiện tại đã sẵn sàng cho production với đầy đủ tính năng enterprise-grade data management. 