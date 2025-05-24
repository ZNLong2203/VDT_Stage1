CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INT,
  total_amount NUMERIC,
  status TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO orders (user_id, total_amount, status)
VALUES (1, 100.0, 'completed'),
       (2, -50.0, 'error'), -- bản ghi lỗi để test
       (3, 75.0, null);     -- lỗi thiếu status
