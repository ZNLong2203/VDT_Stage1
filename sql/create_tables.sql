CREATE DATABASE IF NOT EXISTS retail;
USE retail;

CREATE TABLE ods_orders_clean (
  `id` INT,
  `user_id` INT,
  `total_amount` DECIMAL(10,2),
  `status` VARCHAR(20),
  `created_at` DATETIME
)
ENGINE=OLAP
PRIMARY KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 4
PROPERTIES ("replication_num" = "1");

CREATE TABLE ods_orders_error (
  `id` INT,
  `user_id` INT,
  `total_amount` DECIMAL(10,2),
  `status` VARCHAR(20),
  `created_at` DATETIME,
  `error_reason` STRING
)
ENGINE=OLAP
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 4
PROPERTIES ("replication_num" = "1");
