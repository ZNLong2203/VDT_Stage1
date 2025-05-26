CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  total_amount NUMERIC NOT NULL,
  status TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO orders (user_id, total_amount, status)
VALUES
  (1, 100.0, 'completed'),
  (2, -50.0, 'error'),
  (3, 75.0, null);
