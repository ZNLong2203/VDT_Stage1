-- A. Job load dữ liệu sạch
CREATE ROUTINE LOAD load_clean_orders
ON retail.retail_orders
COLUMNS(order_id, user_id, total, created_at, channel)
FROM KAFKA (
  "kafka_broker_list" = "kafka:9092",
  "topic"             = "clean_orders",
  "properties.group.id" = "retail-clean-loader",
  "format"            = "json"
);

-- B. (Tuỳ chọn) Job load dữ liệu lỗi
CREATE ROUTINE LOAD load_error_orders
ON retail.retail_order_errors
COLUMNS(order_id, user_id, total, created_at, channel, error_msg)
FROM KAFKA (
  "kafka_broker_list" = "kafka:9092",
  "topic"             = "error_orders",
  "properties.group.id" = "retail-error-loader",
  "format"            = "json"
);
