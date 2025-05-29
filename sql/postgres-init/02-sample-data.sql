-- Sample Data for E-commerce Database

-- Insert sample customers
INSERT INTO customers (first_name, last_name, email, phone, address, city, country) VALUES
('John', 'Doe', 'john.doe@email.com', '+1-555-0101', '123 Main St', 'New York', 'USA'),
('Jane', 'Smith', 'jane.smith@email.com', '+1-555-0102', '456 Oak Ave', 'Los Angeles', 'USA'),
('Bob', 'Johnson', 'bob.johnson@email.com', '+1-555-0103', '789 Pine Rd', 'Chicago', 'USA'),
('Alice', 'Brown', 'alice.brown@email.com', '+1-555-0104', '321 Elm St', 'Houston', 'USA'),
('Charlie', 'Wilson', 'charlie.wilson@email.com', '+1-555-0105', '654 Maple Dr', 'Phoenix', 'USA'),
('Diana', 'Davis', 'diana.davis@email.com', '+1-555-0106', '987 Cedar Ln', 'Philadelphia', 'USA'),
('Eva', 'Miller', 'eva.miller@email.com', '+1-555-0107', '147 Birch Way', 'San Antonio', 'USA'),
('Frank', 'Garcia', 'frank.garcia@email.com', '+1-555-0108', '258 Spruce St', 'San Diego', 'USA'),
('Grace', 'Martinez', 'grace.martinez@email.com', '+1-555-0109', '369 Willow Ave', 'Dallas', 'USA'),
('Henry', 'Anderson', 'henry.anderson@email.com', '+1-555-0110', '741 Poplar Rd', 'San Jose', 'USA');

-- Insert sample products
INSERT INTO products (name, description, category, price, stock_quantity) VALUES
('Laptop Pro 15"', 'High-performance laptop with 16GB RAM', 'Electronics', 1299.99, 50),
('Wireless Headphones', 'Noise-cancelling Bluetooth headphones', 'Electronics', 199.99, 100),
('Coffee Maker', 'Programmable drip coffee maker', 'Home & Kitchen', 89.99, 75),
('Running Shoes', 'Lightweight running shoes for men', 'Sports & Outdoors', 129.99, 200),
('Smartphone', 'Latest model with 128GB storage', 'Electronics', 699.99, 80),
('Desk Chair', 'Ergonomic office chair with lumbar support', 'Furniture', 249.99, 30),
('Backpack', 'Water-resistant laptop backpack', 'Bags & Luggage', 59.99, 150),
('Tablet', '10-inch tablet with stylus', 'Electronics', 399.99, 60),
('Water Bottle', 'Insulated stainless steel water bottle', 'Sports & Outdoors', 24.99, 300),
('Book Light', 'LED reading light with clip', 'Books & Media', 19.99, 120);

-- Insert sample orders
INSERT INTO orders (customer_id, status, total_amount, shipping_address) VALUES
(1, 'completed', 1499.98, '123 Main St, New York, USA'),
(2, 'shipped', 289.98, '456 Oak Ave, Los Angeles, USA'),
(3, 'pending', 219.98, '789 Pine Rd, Chicago, USA'),
(4, 'completed', 699.99, '321 Elm St, Houston, USA'),
(5, 'processing', 379.97, '654 Maple Dr, Phoenix, USA'),
(6, 'completed', 89.99, '987 Cedar Ln, Philadelphia, USA'),
(7, 'shipped', 189.98, '147 Birch Way, San Antonio, USA'),
(8, 'pending', 459.98, '258 Spruce St, San Diego, USA'),
(9, 'completed', 154.98, '369 Willow Ave, Dallas, USA'),
(10, 'processing', 44.98, '741 Poplar Rd, San Jose, USA');

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
-- Order 1: Laptop + Headphones
(1, 1, 1, 1299.99, 1299.99),
(1, 2, 1, 199.99, 199.99),

-- Order 2: Headphones + Running Shoes
(2, 2, 1, 199.99, 199.99),
(2, 4, 1, 129.99, 129.99),

-- Order 3: Coffee Maker + Running Shoes
(3, 3, 1, 89.99, 89.99),
(3, 4, 1, 129.99, 129.99),

-- Order 4: Smartphone
(4, 5, 1, 699.99, 699.99),

-- Order 5: Desk Chair + Backpack + Water Bottle
(5, 6, 1, 249.99, 249.99),
(5, 7, 1, 59.99, 59.99),
(5, 9, 2, 24.99, 49.98),

-- Order 6: Coffee Maker
(6, 3, 1, 89.99, 89.99),

-- Order 7: Running Shoes + Backpack
(7, 4, 1, 129.99, 129.99),
(7, 7, 1, 59.99, 59.99),

-- Order 8: Tablet + Book Light
(8, 8, 1, 399.99, 399.99),
(8, 10, 3, 19.99, 59.99),

-- Order 9: Running Shoes + Water Bottle
(9, 4, 1, 129.99, 129.99),
(9, 9, 1, 24.99, 24.99),

-- Order 10: Water Bottle + Book Light
(10, 9, 1, 24.99, 24.99),
(10, 10, 1, 19.99, 19.99); 