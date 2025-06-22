ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 20;
ALTER SYSTEM SET max_wal_senders = 20;

CREATE TABLE orders (
  "order_id" VARCHAR(50) PRIMARY KEY,
  "customer_id" VARCHAR(50),
  "order_status" VARCHAR(20),
  "order_purchase_timestamp" TIMESTAMP,
  "order_approved_at" TIMESTAMP,
  "order_delivered_carrier_date" TIMESTAMP,
  "order_delivered_customer_date" TIMESTAMP,
  "order_estimated_delivery_date" TIMESTAMP,
  "is_deleted" BOOLEAN DEFAULT FALSE,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
  "customer_id" VARCHAR(50) PRIMARY KEY,
  "customer_unique_id" VARCHAR(50),
  "customer_zip_code_prefix" VARCHAR(10),
  "customer_city" VARCHAR(100),
  "customer_state" VARCHAR(10),
  "is_deleted" BOOLEAN DEFAULT FALSE,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
  "id" SERIAL PRIMARY KEY,
  "order_id" VARCHAR(50),
  "order_item_id" INTEGER,
  "product_id" VARCHAR(50),
  "seller_id" VARCHAR(50),
  "shipping_limit_date" TIMESTAMP,
  "price" DOUBLE PRECISION,
  "freight_value" DOUBLE PRECISION,
  "is_deleted" BOOLEAN DEFAULT FALSE,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
  "id" SERIAL PRIMARY KEY,
  "order_id" VARCHAR(50),
  "payment_sequential" INTEGER,
  "payment_type" VARCHAR(20),
  "payment_installments" INTEGER,
  "payment_value" DOUBLE PRECISION,
  "is_deleted" BOOLEAN DEFAULT FALSE,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
  "review_id" VARCHAR(50) PRIMARY KEY,
  "order_id" VARCHAR(50),
  "review_score" INTEGER,
  "review_comment_title" VARCHAR(500),
  "review_comment_message" TEXT,
  "review_creation_date" TIMESTAMP,
  "review_answer_timestamp" TIMESTAMP,
  "is_deleted" BOOLEAN DEFAULT FALSE,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
  "product_id" VARCHAR(50) PRIMARY KEY,
  "product_category_name" VARCHAR(100),
  "product_name_lenght" INTEGER,
  "product_description_lenght" INTEGER,
  "product_photos_qty" INTEGER,
  "product_weight_g" DOUBLE PRECISION,
  "product_length_cm" DOUBLE PRECISION,
  "product_height_cm" DOUBLE PRECISION,
  "product_width_cm" DOUBLE PRECISION,
  "is_deleted" BOOLEAN DEFAULT FALSE,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sellers (
  "seller_id" VARCHAR(50) PRIMARY KEY,
  "seller_zip_code_prefix" VARCHAR(10),
  "seller_city" VARCHAR(100),
  "seller_state" VARCHAR(10),
  "is_deleted" BOOLEAN DEFAULT FALSE,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE orders ADD CONSTRAINT fk_orders_customer 
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items ADD CONSTRAINT fk_order_items_order 
    FOREIGN KEY (order_id) REFERENCES orders(order_id);
    
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_product 
    FOREIGN KEY (product_id) REFERENCES products(product_id);
    
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_seller 
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE payments ADD CONSTRAINT fk_payments_order 
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE reviews ADD CONSTRAINT fk_reviews_order 
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_purchase_timestamp ON orders(order_purchase_timestamp);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_reviews_order_id ON reviews(order_id);

CREATE PUBLICATION dbz_publication FOR ALL TABLES;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sellers_updated_at BEFORE UPDATE ON sellers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

SELECT pg_create_logical_replication_slot('etl_orders_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('etl_order_items_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('etl_products_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('etl_reviews_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('etl_payments_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('etl_customers_slot', 'pgoutput'); 