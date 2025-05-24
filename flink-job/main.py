import time
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment, EnvironmentSettings

# 1. Khởi tạo môi trường
env = StreamExecutionEnvironment.get_execution_environment()
settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
t_env = StreamTableEnvironment.create(env, environment_settings=settings)

# 2. Định nghĩa source từ Postgres CDC
t_env.execute_sql("""
CREATE TABLE postgres_orders (
  id INT,
  user_id INT,
  total_amount DECIMAL(10, 2),
  status STRING,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'postgres-cdc',
  'hostname' = 'postgres',
  'port' = '5432',
  'username' = 'retail_user',
  'password' = 'retail_pass',
  'database-name' = 'retail_db',
  'schema-name' = 'public',
  'table-name' = 'orders',
  'slot.name' = 'flink_slot',
  'decoding.plugin.name' = 'pgoutput'
)
""")

# 3. Tạo temporary views cho clean + error
t_env.execute_sql("""
CREATE TEMPORARY VIEW valid_orders AS
SELECT * 
FROM postgres_orders
WHERE total_amount > 0 AND status IS NOT NULL
""")
t_env.execute_sql("""
CREATE TEMPORARY VIEW error_orders AS
SELECT *,
  CASE
    WHEN total_amount <= 0 THEN 'invalid amount'
    WHEN status IS NULL THEN 'missing status'
    ELSE 'unknown'
  END AS error_reason
FROM postgres_orders
WHERE total_amount <= 0 OR status IS NULL
""")

# 4. Tạo sink tables trong StarRocks qua JDBC (MySQL protocol)
t_env.execute_sql("""
CREATE TABLE ods_clean (
  id INT,
  user_id INT,
  total_amount DECIMAL(10,2),
  status STRING,
  created_at TIMESTAMP(3)
) WITH (
  'connector' = 'starrocks',
  'fenodes' = 'starrocks-quickstart:8030',
  'table.identifier' = 'retail.ods_orders_clean',
  'username' = 'root',
  'password' = '',
  'sink.label-prefix' = 'flink_stream_load',
  'sink.properties.format' = 'json',
  'sink.properties.strip_outer_array' = 'true'
);
""")
t_env.execute_sql("""
CREATE TABLE ods_error (
  id INT,
  user_id INT,
  total_amount DECIMAL(10,2),
  status STRING,
  created_at TIMESTAMP(3),
  error_reason STRING
) WITH (
  'connector' = 'starrocks',
  'fenodes' = 'starrocks-quickstart:8030',
  'table.identifier' = 'retail.ods_orders_error',
  'username' = 'root',
  'password' = '',
  'sink.label-prefix' = 'flink_stream_load',
  'sink.properties.format' = 'json',
  'sink.properties.strip_outer_array' = 'true'
);
""")

# 5. Đẩy dữ liệu từ view vào các bảng đích
t_env.execute_sql("""
INSERT INTO ods_clean
SELECT id, user_id, total_amount, status, created_at
FROM valid_orders
""")
t_env.execute_sql("""
INSERT INTO ods_error
SELECT id, user_id, total_amount, status, created_at, error_reason
FROM error_orders
""")

print("🚀 Pipeline đang chạy, giữ container alive…")
while True:
    time.sleep(60)