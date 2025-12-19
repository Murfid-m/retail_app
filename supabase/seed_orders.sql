-- Seed Orders Data from Dashboard Summary
-- This will create sample orders distributed across months from 2015-2018
-- Run this in Supabase SQL Editor

-- First, create a temp function to generate random orders for a month
DO $$
DECLARE
  v_user_id uuid;
  v_order_date timestamp;
  v_monthly_sales numeric;
  v_orders_count int;
  v_avg_order_value numeric;
  i int;
BEGIN
  -- Get a user_id (admin user for testing, replace with actual user_id)
  SELECT id INTO v_user_id FROM users WHERE is_admin = true LIMIT 1;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No admin user found. Please create an admin user first.';
  END IF;

  -- 2015 data
  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT 
    v_user_id,
    'Sample Customer',
    '081234567890',
    'customer@example.com',
    'Jakarta, Indonesia',
    (14205.71 / 5) * (1 + random() * 0.3), -- Distribute ~5 orders per month with variation
    'completed',
    timestamp '2015-01-01' + (random() * interval '30 days')
  FROM generate_series(1, 5);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (4519.89 / 3) * (1 + random() * 0.3), 'completed', timestamp '2015-02-01' + (random() * interval '28 days')
  FROM generate_series(1, 3);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (55205.8 / 10) * (1 + random() * 0.3), 'completed', timestamp '2015-03-01' + (random() * interval '30 days')
  FROM generate_series(1, 10);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (27906.86 / 6) * (1 + random() * 0.3), 'completed', timestamp '2015-04-01' + (random() * interval '30 days')
  FROM generate_series(1, 6);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (23644.3 / 5) * (1 + random() * 0.3), 'completed', timestamp '2015-05-01' + (random() * interval '30 days')
  FROM generate_series(1, 5);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (34322.94 / 7) * (1 + random() * 0.3), 'completed', timestamp '2015-06-01' + (random() * interval '30 days')
  FROM generate_series(1, 7);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (33781.54 / 7) * (1 + random() * 0.3), 'completed', timestamp '2015-07-01' + (random() * interval '30 days')
  FROM generate_series(1, 7);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (27117.54 / 6) * (1 + random() * 0.3), 'completed', timestamp '2015-08-01' + (random() * interval '30 days')
  FROM generate_series(1, 6);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (81623.53 / 12) * (1 + random() * 0.3), 'completed', timestamp '2015-09-01' + (random() * interval '30 days')
  FROM generate_series(1, 12);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (31453.39 / 7) * (1 + random() * 0.3), 'completed', timestamp '2015-10-01' + (random() * interval '30 days')
  FROM generate_series(1, 7);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (77907.66 / 12) * (1 + random() * 0.3), 'completed', timestamp '2015-11-01' + (random() * interval '30 days')
  FROM generate_series(1, 12);

  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    (68167.06 / 10) * (1 + random() * 0.3), 'completed', timestamp '2015-12-01' + (random() * interval '30 days')
  FROM generate_series(1, 10);

  -- Add recent data for testing (December 2024)
  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    50000 + (random() * 150000), 'completed', timestamp '2024-12-01' + (random() * interval '18 days')
  FROM generate_series(1, 15);

  -- Add today's data
  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    75000 + (random() * 125000), 'completed', CURRENT_DATE + (random() * interval '12 hours')
  FROM generate_series(1, 5);

  -- Add this week's data
  INSERT INTO orders (user_id, user_name, user_phone, user_email, shipping_address, total_amount, status, created_at)
  SELECT v_user_id, 'Sample Customer', '081234567890', 'customer@example.com', 'Jakarta, Indonesia',
    60000 + (random() * 140000), 'completed', CURRENT_DATE - (random() * interval '6 days')
  FROM generate_series(1, 20);

  RAISE NOTICE 'Successfully seeded orders data!';
END $$;

-- Verify the data
SELECT 
  DATE_TRUNC('month', created_at) as month,
  COUNT(*) as order_count,
  SUM(total_amount) as total_sales
FROM orders
WHERE status = 'completed'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC
LIMIT 12;
