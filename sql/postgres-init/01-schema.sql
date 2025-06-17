ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 20;
ALTER SYSTEM SET max_wal_senders = 20;

CREATE TABLE orders (
  "order_id" TEXT PRIMARY KEY,
  "customer_id" TEXT,
  "order_status" TEXT,
  "order_purchase_timestamp" TIMESTAMP,
  "order_approved_at" TIMESTAMP,
  "order_delivered_carrier_date" TIMESTAMP,
  "order_delivered_customer_date" TIMESTAMP,
  "order_estimated_delivery_date" TIMESTAMP,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
  "customer_id" TEXT PRIMARY KEY,
  "customer_unique_id" TEXT,
  "customer_zip_code_prefix" TEXT,
  "customer_city" TEXT,
  "customer_state" TEXT,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
  "id" SERIAL PRIMARY KEY,
  "order_id" TEXT,
  "order_item_id" INTEGER,
  "product_id" TEXT,
  "seller_id" TEXT,
  "shipping_limit_date" TIMESTAMP,
  "price" DOUBLE PRECISION,
  "freight_value" DOUBLE PRECISION,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
  "id" SERIAL PRIMARY KEY,
  "order_id" TEXT,
  "payment_sequential" INTEGER,
  "payment_type" TEXT,
  "payment_installments" INTEGER,
  "payment_value" DOUBLE PRECISION,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
  "review_id" TEXT PRIMARY KEY,
  "order_id" TEXT,
  "review_score" INTEGER,
  "review_comment_title" TEXT,
  "review_comment_message" TEXT,
  "review_creation_date" TIMESTAMP,
  "review_answer_timestamp" TIMESTAMP,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
  "product_id" TEXT PRIMARY KEY,
  "product_category_name" TEXT,
  "product_name_lenght" INTEGER,
  "product_description_lenght" INTEGER,
  "product_photos_qty" INTEGER,
  "product_weight_g" DOUBLE PRECISION,
  "product_length_cm" DOUBLE PRECISION,
  "product_height_cm" DOUBLE PRECISION,
  "product_width_cm" DOUBLE PRECISION,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sellers (
  "seller_id" TEXT PRIMARY KEY,
  "seller_zip_code_prefix" TEXT,
  "seller_city" TEXT,
  "seller_state" TEXT,
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

SELECT pg_create_logical_replication_slot('orders_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('order_items_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('products_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('reviews_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('payments_slot', 'pgoutput');
SELECT pg_create_logical_replication_slot('customers_slot', 'pgoutput'); 