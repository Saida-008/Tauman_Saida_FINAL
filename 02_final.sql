
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;

-- PART 2: INITIALIZE ROLES 
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cosmetics_readonly') THEN
        CREATE ROLE cosmetics_readonly;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cosmetics_writer') THEN
        CREATE ROLE cosmetics_writer;
    END IF;
END $$;

-- ===== PART 3: CREATE TABLES & CONSTRAINTS =====

CREATE TABLE public.customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL CONSTRAINT uq_customer_email UNIQUE,
    phone_number VARCHAR(15),
    delivery_address TEXT NOT NULL,
    registration_date TIMESTAMP DEFAULT NOW() NOT NULL,
    CONSTRAINT chk_registration_date CHECK (registration_date > DATE '2026-01-01')
);

CREATE TABLE public.categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL CONSTRAINT uq_category_name UNIQUE,
    description TEXT
);

CREATE TABLE public.products (
    product_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    sku VARCHAR(30) NOT NULL CONSTRAINT uq_product_sku UNIQUE,
    unit_price NUMERIC(10,2) NOT NULL,
    stock_quantity INT NOT NULL,
    CONSTRAINT chk_unit_price CHECK (unit_price >= 0.00),
    CONSTRAINT chk_stock_quantity CHECK (stock_quantity >= 0),
    CONSTRAINT fk_products_categories FOREIGN KEY (category_id) 
        REFERENCES public.categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE public.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT NOW() NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' NOT NULL,
    CONSTRAINT chk_order_status CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    CONSTRAINT chk_order_date CHECK (order_date > DATE '2026-01-01'),
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) 
        REFERENCES public.customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE public.order_items (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    discount_amount NUMERIC(10,2) DEFAULT 0.00 NOT NULL,
    total_price NUMERIC(10,2) GENERATED ALWAYS AS ((quantity * 100 - discount_amount * 100) / 100.0) STORED,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT chk_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_discount CHECK (discount_amount >= 0.00),
    CONSTRAINT fk_items_orders FOREIGN KEY (order_id) 
        REFERENCES public.orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_items_products FOREIGN KEY (product_id) 
        REFERENCES public.products(product_id) ON DELETE RESTRICT
);

-- ===== PART 4: ALTER TABLE OPERATIONS =====

ALTER TABLE public.customers ALTER COLUMN phone_number TYPE VARCHAR(25);

ALTER TABLE public.customers ADD COLUMN loyalty_points INT DEFAULT 0 NOT NULL;

ALTER TABLE public.customers ADD CONSTRAINT chk_loyalty_points CHECK (loyalty_points >= 0);

ALTER TABLE public.categories RENAME COLUMN description TO category_description;

ALTER TABLE public.customers ADD COLUMN middle_name VARCHAR(50); 
ALTER TABLE public.customers DROP COLUMN middle_name;

-- ===== PART 5: INSERT DATA =====

TRUNCATE TABLE 
    public.order_items, 
    public.orders, 
    public.products, 
    public.categories, 
    public.customers 
RESTART IDENTITY CASCADE;

INSERT INTO public.categories (category_name, category_description) VALUES
('Skincare', 'Creams, serums, and cleansers for face care'),
('Haircare', 'Shampoos, conditioners, and hair masks'),
('Makeup', 'Foundations, lipsticks, and mascaras for beauty'),
('Fragrances', 'Perfumes and body mists'),
('Body Care', 'Body lotions, scrubs, and shower gels');

INSERT INTO public.customers (first_name, last_name, email, phone_number, delivery_address, registration_date) VALUES
('Ali', 'Askarov', 'ali.askarov@example.kz', '+77011112233', 'Abay Ave 45, Almaty', '2026-02-15 10:00:00'),
('Dana', 'Serikova', 'dana.s@example.kz', '+77023334455', 'Mangilik El 12, Astana', '2026-03-01 11:30:00'),
('Ivan', 'Ivanov', 'ivan.ivanov@example.kz', '+77056667788', 'Kabanbay Batyr 8, Astana', '2026-03-20 14:15:00'),
('Aigerim', 'Muratova', 'aiga.m@example.kz', '+77078889900', 'Satpayev St 22, Almaty', '2026-04-05 09:00:00'),
('Dmitry', 'Petrov', 'dima.p@example.kz', '+77471115599', 'Tole Bi 104, Almaty', '2026-05-10 16:45:00');

INSERT INTO public.products (category_id, product_name, sku, unit_price, stock_quantity) VALUES
((SELECT category_id FROM public.categories WHERE category_name = 'Skincare'), 'Hydrating Face Cream', 'SKIN-CREAM01', 12500.00, 50),
((SELECT category_id FROM public.categories WHERE category_name = 'Skincare'), 'Vitamin C Serum', 'SKIN-SERUM02', 18000.00, 35),
((SELECT category_id FROM public.categories WHERE category_name = 'Haircare'), 'Argan Oil Shampoo', 'HAIR-SHAM01', 6500.00, 60),
((SELECT category_id FROM public.categories WHERE category_name = 'Haircare'), 'Repair Hair Mask', 'HAIR-MASK02', 8200.00, 40),
((SELECT category_id FROM public.categories WHERE category_name = 'Makeup'), 'Matte Lipstick Red', 'MAKE-LIP01', 5500.00, 100),
((SELECT category_id FROM public.categories WHERE category_name = 'Makeup'), 'Liquid Foundation', 'MAKE-FOUND02', 14000.00, 45),
((SELECT category_id FROM public.categories WHERE category_name = 'Fragrances'), 'Eau de Parfum Jasmine', 'FRAG-PERF01', 35000.00, 20),
((SELECT category_id FROM public.categories WHERE category_name = 'Fragrances'), 'Vanilla Body Mist', 'FRAG-MIST02', 7500.00, 80),
((SELECT category_id FROM public.categories WHERE category_name = 'Body Care'), 'Coconut Body Scrub', 'BODY-SCRUB01', 4900.00, 90),
((SELECT category_id FROM public.categories WHERE category_name = 'Body Care'), 'Shea Body Lotion', 'BODY-LOTION02', 5800.00, 75);

INSERT INTO public.orders (customer_id, order_date, status) VALUES
((SELECT customer_id FROM public.customers WHERE email = 'ali.askarov@example.kz'), '2026-03-05 12:00:00', 'delivered'),
((SELECT customer_id FROM public.customers WHERE email = 'dana.s@example.kz'), '2026-03-10 15:30:00', 'delivered'),
((SELECT customer_id FROM public.customers WHERE email = 'ivan.ivanov@example.kz'), '2026-04-12 18:20:00', 'shipped'),
((SELECT customer_id FROM public.customers WHERE email = 'aiga.m@example.kz'), '2026-05-01 10:15:00', 'processing'),
((SELECT customer_id FROM public.customers WHERE email = 'dima.p@example.kz'), '2026-05-20 14:00:00', 'cancelled');

INSERT INTO public.order_items (order_id, product_id, quantity, discount_amount) VALUES
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'ali.askarov@example.kz') AND order_date = '2026-03-05 12:00:00'),
    (SELECT product_id FROM public.products WHERE sku = 'SKIN-CREAM01'), 1, 500.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'ali.askarov@example.kz') AND order_date = '2026-03-05 12:00:00'),
    (SELECT product_id FROM public.products WHERE sku = 'BODY-SCRUB01'), 2, 0.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'dana.s@example.kz') AND order_date = '2026-03-10 15:30:00'),
    (SELECT product_id FROM public.products WHERE sku = 'SKIN-SERUM02'), 1, 0.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'dana.s@example.kz') AND order_date = '2026-03-10 15:30:00'),
    (SELECT product_id FROM public.products WHERE sku = 'MAKE-LIP01'), 1, 200.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'ivan.ivanov@example.kz') AND order_date = '2026-04-12 18:20:00'),
    (SELECT product_id FROM public.products WHERE sku = 'FRAG-PERF01'), 1, 3000.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'ivan.ivanov@example.kz') AND order_date = '2026-04-12 18:20:00'),
    (SELECT product_id FROM public.products WHERE sku = 'HAIR-SHAM01'), 1, 0.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'aiga.m@example.kz') AND order_date = '2026-05-01 10:15:00'),
    (SELECT product_id FROM public.products WHERE sku = 'MAKE-FOUND02'), 1, 0.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'aiga.m@example.kz') AND order_date = '2026-05-01 10:15:00'),
    (SELECT product_id FROM public.products WHERE sku = 'FRAG-MIST02'), 1, 500.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'dima.p@example.kz') AND order_date = '2026-05-20 14:00:00'),
    (SELECT product_id FROM public.products WHERE sku = 'HAIR-MASK02'), 1, 0.00
),
(
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE email = 'dima.p@example.kz') AND order_date = '2026-05-20 14:00:00'),
    (SELECT product_id FROM public.products WHERE sku = 'BODY-LOTION02'), 1, 0.00
);

INSERT INTO public.order_items (order_id, product_id, quantity, discount_amount)
SELECT 
    o.order_id, 
    (SELECT product_id FROM public.products WHERE sku = 'BODY-SCRUB01'), 
    1, 
    4900.00
FROM public.orders o
JOIN public.order_items oi ON o.order_id = oi.order_id
JOIN public.products p ON oi.product_id = p.product_id
WHERE p.category_id = (SELECT category_id FROM public.categories WHERE category_name = 'Haircare')
ON CONFLICT (order_id, product_id) DO NOTHING;

-- ===== PART 6: UPDATE & DELETE =====

UPDATE public.customers
SET loyalty_points = loyalty_points + 150
WHERE registration_date < '2026-04-01 00:00:00';

UPDATE public.order_items
SET discount_amount = discount_amount + (0.10 * (SELECT unit_price FROM public.products p WHERE p.product_id = order_items.product_id))
WHERE product_id IN (SELECT product_id FROM public.products WHERE category_id = (SELECT category_id FROM public.categories WHERE category_name = 'Makeup'))
  AND order_id IN (SELECT order_id FROM public.orders WHERE status IN ('pending', 'processing'));

DELETE FROM public.orders WHERE status = 'cancelled';

-- ===== PART 7: PRIVILEGES =====

GRANT SELECT ON ALL TABLES IN SCHEMA public TO cosmetics_readonly;

GRANT INSERT, UPDATE ON public.orders TO cosmetics_writer;

REVOKE UPDATE ON public.orders FROM cosmetics_writer;