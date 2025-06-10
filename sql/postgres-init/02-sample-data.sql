-- Load data from CSV files
-- Note: This assumes CSV files are mounted in container at /dataset/

-- Load customers data
COPY customers(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
FROM '/dataset/olist_customers_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Load sellers data  
COPY sellers(seller_id, seller_zip_code_prefix, seller_city, seller_state)
FROM '/dataset/olist_sellers_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Load products data
COPY products(product_id, product_category_name, product_name_lenght, product_description_lenght, 
              product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
FROM '/dataset/olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Load orders data
COPY orders(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at,
            order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
FROM '/dataset/olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Load order items data
COPY order_items(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
FROM '/dataset/olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Load payments data
COPY payments(order_id, payment_sequential, payment_type, payment_installments, payment_value)
FROM '/dataset/olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Load reviews data using temp table to handle duplicates
CREATE TEMP TABLE temp_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

COPY temp_reviews(review_id, order_id, review_score, review_comment_title, review_comment_message,
                  review_creation_date, review_answer_timestamp)
FROM '/dataset/olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Insert unique reviews only
INSERT INTO reviews(review_id, order_id, review_score, review_comment_title, review_comment_message,
                   review_creation_date, review_answer_timestamp)
SELECT DISTINCT ON (review_id) review_id, order_id, review_score, review_comment_title, 
       review_comment_message, review_creation_date, review_answer_timestamp
FROM temp_reviews
ON CONFLICT (review_id) DO NOTHING;

-- Update statistics
ANALYZE customers;
ANALYZE sellers;
ANALYZE products;
ANALYZE orders;
ANALYZE order_items;
ANALYZE payments;
ANALYZE reviews;

-- Print data summary
DO $$
BEGIN
    RAISE NOTICE 'Data loading completed!';
    RAISE NOTICE 'Customers: %', (SELECT COUNT(*) FROM customers);
    RAISE NOTICE 'Sellers: %', (SELECT COUNT(*) FROM sellers);
    RAISE NOTICE 'Products: %', (SELECT COUNT(*) FROM products);
    RAISE NOTICE 'Orders: %', (SELECT COUNT(*) FROM orders);
    RAISE NOTICE 'Order Items: %', (SELECT COUNT(*) FROM order_items);
    RAISE NOTICE 'Payments: %', (SELECT COUNT(*) FROM payments);
    RAISE NOTICE 'Reviews: %', (SELECT COUNT(*) FROM reviews);
END $$; 