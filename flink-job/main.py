import time
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment, EnvironmentSettings

# 1. Khởi tạo môi trường + bật checkpoint
env = StreamExecutionEnvironment.get_execution_environment()
env.enable_checkpointing(5000)   # checkpoint mỗi 5 giây
settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
t_env = StreamTableEnvironment.create(env, environment_settings=settings)

# 2. Source: Postgres CDC
print("🔌 Creating source table from Postgres CDC...")
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
  'slot.name' = 'flink_slot_v2',
  'decoding.plugin.name' = 'pgoutput',
  'scan.startup.mode' = 'initial'
)
""")

# 3. Views: valid vs error
print("🧹 Creating views for valid and error records...")
t_env.execute_sql("""
CREATE TEMPORARY VIEW valid_orders AS
SELECT * FROM postgres_orders
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

# 4. Sink: StarRocks với buffer‐flush & flush‐on‐checkpoint
print("📥 Creating StarRocks sink tables...")
t_env.execute_sql("""
CREATE TABLE ods_clean (
  id           INT,
  user_id      INT,
  total_amount DECIMAL(10,2),
  status       STRING,
  created_at   TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector'       = 'starrocks',
  'jdbc-url'        = 'jdbc:mysql://starrocks-quickstart:9030',
  'load-url'        = 'http://starrocks-quickstart:8030',
  'database-name'   = 'retail',
  'table-name'      = 'ods_orders_clean',
  'username'        = 'root',
  'password'        = '',
  'sink.label-prefix' = 'flink_stream_load_clean',

  -- exactly-once settings
  'sink.semantic'                     = 'exactly-once',
  'sink.version'                      = 'V1',
  'sink.exactly-once.enable-label-gen'       = 'true',
  'sink.exactly-once.enable-abort-lingering-txn' = 'true',

  -- format
  'sink.properties.format'            = 'json',
  'sink.properties.strip_outer_array' = 'true'
);
""")
t_env.execute_sql("""
CREATE TABLE ods_error (
  id           INT,
  user_id      INT,
  total_amount DECIMAL(10,2),
  status       STRING,
  created_at   TIMESTAMP(3),
  error_reason STRING,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector'       = 'starrocks',
  'jdbc-url'        = 'jdbc:mysql://starrocks-quickstart:9030',
  'load-url'        = 'http://starrocks-quickstart:8030',
  'database-name'   = 'retail',
  'table-name'      = 'ods_orders_error',
  'username'        = 'root',
  'password'        = '',
  'sink.label-prefix' = 'flink_stream_load_error',

  -- exactly-once settings
  'sink.semantic'                     = 'exactly-once',
  'sink.version'                      = 'V1',
  'sink.exactly-once.enable-label-gen'       = 'true',
  'sink.exactly-once.enable-abort-lingering-txn' = 'true',

  -- format
  'sink.properties.format'            = 'json',
  'sink.properties.strip_outer_array' = 'true'
);
""")

# 5. Insert streaming
print("🚀 Submitting dataflow from views into StarRocks...")
result1 = t_env.execute_sql("""
INSERT INTO ods_clean
SELECT id, user_id, total_amount, status, created_at
FROM valid_orders
""")
result2 = t_env.execute_sql("""
INSERT INTO ods_error
SELECT id, user_id, total_amount, status, created_at, error_reason
FROM error_orders
""")

# 6. Giữ job chạy liên tục
print("🎯 Waiting for streaming job to remain alive... (CTRL+C to stop)")
job_client1 = result1.get_job_client()
job_client2 = result2.get_job_client()

job_client1.get_job_execution_result().result()
job_client2.get_job_execution_result().result()