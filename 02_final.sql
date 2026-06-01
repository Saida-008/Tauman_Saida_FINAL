-- SECTION 1: DATABASE RESET (REVERSE DEPENDENCY ORDER)
drop table if exists public.payments cascade;
drop table if exists public.order_items cascade;
drop table if exists public.orders cascade;
drop table if exists public.products cascade;
drop table if exists public.categories cascade;
drop table if exists public.customers cascade;

-- SECTION 2: ROLE CONFIGURATION
do $$ 
begin
    -- Purpose: For analytical tools and business intelligence reporting. Read-only access.
    if not exists (select 1 from pg_roles where rolname = 'cosmetics_readonly') then
        create role cosmetics_readonly;
    end if;
    -- Purpose: For backend application services to manage fulfillment workflows. Write access.
    if not exists (select 1 from pg_roles where rolname = 'cosmetics_writer') then
        create role cosmetics_writer;
    end if;
end $$;

-- SECTION 3: TABLE CREATION (STRICT 3NF & ALL 5 REQUIRED KINDS OF CHECKS)

create table public.customers (
    customer_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    full_name varchar(101) generated always as (first_name || ' ' || last_name) stored,
    email varchar(100) not null constraint uq_customer_email unique, -- Check Kind 1: UNIQUE
    phone_number varchar(20) not null, -- Бастапқы сыйымдылық (ALTER арқылы 35-ке өседі)
    delivery_address text not null, 
    registration_date timestamp default now() not null, -- Meaningful DEFAULT
    constraint chk_registration_date check (registration_date > date '2026-01-01'), -- Check Kind 2: Date Threshold
    constraint chk_valid_phone_format check (phone_number ~ '^\+[0-9\s\-()]+$') -- Check Kind 3: Regular Expression
);

create table public.categories (
    category_id serial primary key,
    category_name varchar(50) not null constraint uq_category_name unique,
    description text
);

create table public.products (
    product_id serial primary key,
    category_id int not null,
    product_name varchar(100) not null,
    sku varchar(30) not null constraint uq_product_sku unique,
    unit_price numeric(10,2) not null,
    stock_quantity int not null,
    constraint chk_unit_price check (unit_price >= 0.00), -- Check Kind 4: Non-negative value
    constraint fk_products_categories foreign key (category_id) 
        references public.categories(category_id) on delete restrict 
);

create table public.orders (
    order_id serial primary key,
    customer_id int not null,
    order_date timestamp default now() not null,
    status varchar(20) default 'pending' not null,
    constraint chk_order_status check (status in ('pending', 'processing', 'shipped', 'delivered', 'cancelled')), -- Check Kind 5: Enumerated array
    constraint chk_order_date check (order_date > date '2026-01-01'),
    constraint fk_orders_customers foreign key (customer_id) 
        references public.customers(customer_id) on delete cascade 
);

-- Complies fully with 3NF: Derived total_price calculations removed to eliminate transitive dependency.
create table public.order_items (
    order_id int not null,
    product_id int not null,
    quantity int not null,
    discount_amount numeric(10,2) default 0.00 not null,
    primary key (order_id, product_id),
    constraint chk_item_quantity check (quantity > 0),
    constraint chk_discount check (discount_amount >= 0.00),
    constraint fk_items_orders foreign key (order_id) 
        references public.orders(order_id) on delete cascade,
    constraint fk_items_products foreign key (product_id) 
        references public.products(product_id) on delete restrict
);

-- NEW 6TH TABLE: Achieves explicit operational separation of business concerns.
create table public.payments (
    payment_id serial primary key,
    order_id int not null constraint uq_payment_order unique,
    payment_date timestamp default now() not null,
    amount numeric(10,2) not null,
    payment_method varchar(30) default 'card' not null,
    payment_status varchar(20) default 'completed' not null, -- Диаграммадағыдай баған бірден қосылды
    constraint chk_payment_amount check (amount > 0.00),
    constraint chk_payment_date check (payment_date > date '2026-01-01'),
    constraint chk_payment_method check (payment_method in ('card', 'cash', 'qr_code')),
    constraint fk_payments_orders foreign key (order_id) 
        references public.orders(order_id) on delete cascade
);

-- SECTION 4: ALTER TABLE STATEMENTS (5 DISTINCT OPERATIONS)

-- Alter 1: Increase structural capacity to safely handle long international phone strings.
alter table public.customers alter column phone_number type varchar(35);

-- Alter 2: Append marketing analytical attributes to fuel corporate CRM loyalty mechanics.
alter table public.customers add column loyalty_points int default 0 not null;

-- Alter 3: Secure the database with integrity logic so application layer bugs cannot corrupt balances.
alter table public.customers add constraint chk_loyalty_points check (loyalty_points >= 0);

-- Alter 4: Standardize schema layouts against structural keywords by refining naming patterns.
alter table public.categories rename column description to category_description;

-- Alter 5: Add data validation check constraint to the payment status lifecycle.
alter table public.payments add constraint chk_payment_status check (payment_status in ('pending', 'completed', 'failed', 'refunded'));

-- SECTION 5: RE-RUNNABLE RESET
truncate table 
    public.payments,
    public.order_items, 
    public.orders, 
    public.products, 
    public.categories, 
    public.customers 
restart identity cascade;

-- SECTION 6: DATA INSERTS (DYNAMIC SCALAR SUBQUERIES)

insert into public.categories (category_name, category_description) values
('Skincare', 'Creams, serums, and cleansers for face care'),
('Haircare', 'Shampoos, conditioners, and hair masks'),
('Makeup', 'Foundations, lipsticks, and mascaras for beauty'),
('Fragrances', 'Perfumes and body mists'),
('Body Care', 'Body lotions, scrubs, and shower gels'),
('Tools', 'Makeup brushes, sponges, and mirrors');

insert into public.customers (first_name, last_name, email, phone_number, delivery_address, registration_date) values
('Saida', 'Askarova', 'ali.askarov@example.kz', '+77011112233', 'Abay Ave 45, Almaty', '2026-02-15 10:00:00'),
('Dana', 'Serikova', 'dana.s@example.kz', '+77023334455', 'Mangilik El 12, Astana', '2026-03-01 11:30:00'),
('Beknaz', 'Turegalieva', 'ivan.ivanov@example.kz', '+77056667788', 'Kabanbay Batyr 8, Astana', '2026-03-20 14:15:00'),
('Aigerim', 'Muratova', 'aiga.m@example.kz', '+77078889900', 'Satpayev St 22, Almaty', '2026-04-05 09:00:00'),
('Symbat', 'Kadirgali', 'dima.p@example.kz', '+77471115599', 'Tole Bi 104, Almaty', '2026-05-10 16:45:00'),
('Zarina', 'Kalykova', 'zarina.k@example.kz', '+77085554433', 'Dostyk Ave 10, Almaty', '2026-05-12 11:00:00');

-- Products Table expanded to 12 items to satisfy 10+ largest table condition
insert into public.products (category_id, product_name, sku, unit_price, stock_quantity) values
((select category_id from public.categories where category_name = 'Skincare'), 'Hydrating Face Cream', 'SKIN-CREAM01', 12500.00, 50),
((select category_id from public.categories where category_name = 'Skincare'), 'Vitamin C Serum', 'SKIN-SERUM02', 18000.00, 35),
((select category_id from public.categories where category_name = 'Haircare'), 'Argan Oil Shampoo', 'HAIR-SHAM01', 6500.00, 60),
((select category_id from public.categories where category_name = 'Haircare'), 'Repair Hair Mask', 'HAIR-MASK02', 8200.00, 40),
((select category_id from public.categories where category_name = 'Makeup'), 'Matte Lipstick Red', 'MAKE-LIP01', 5500.00, 100),
((select category_id from public.categories where category_name = 'Makeup'), 'Liquid Foundation', 'MAKE-FOUND02', 14000.00, 45),
((select category_id from public.categories where category_name = 'Fragrances'), 'Eau de Parfum Jasmine', 'FRAG-PERF01', 35000.00, 20),
((select category_id from public.categories where category_name = 'Fragrances'), 'Vanilla Body Mist', 'FRAG-MIST02', 7500.00, 80),
((select category_id from public.categories where category_name = 'Body Care'), 'Coconut Body Scrub', 'BODY-SCRUB01', 4900.00, 90),
((select category_id from public.categories where category_name = 'Body Care'), 'Shea Body Lotion', 'BODY-LOTION02', 5800.00, 75),
((select category_id from public.categories where category_name = 'Tools'), 'Blending Sponge', 'TOOL-SPON01', 2500.00, 150),
((select category_id from public.categories where category_name = 'Tools'), 'Eye Brush Set', 'TOOL-BRUSH02', 8900.00, 30);

insert into public.orders (customer_id, order_date, status) values
((select customer_id from public.customers where email = 'ali.askarov@example.kz'), '2026-03-05 12:00:00', 'delivered'),
((select customer_id from public.customers where email = 'dana.s@example.kz'), '2026-03-10 15:30:00', 'delivered'),
((select customer_id from public.customers where email = 'ivan.ivanov@example.kz'), '2026-04-12 18:20:00', 'shipped'),
((select customer_id from public.customers where email = 'aiga.m@example.kz'), '2026-05-01 10:15:00', 'processing'),
((select customer_id from public.customers where email = 'dima.p@example.kz'), '2026-05-20 14:00:00', 'cancelled'),
((select customer_id from public.customers where email = 'zarina.k@example.kz'), '2026-05-22 09:30:00', 'pending');

insert into public.order_items (order_id, product_id, quantity, discount_amount) values
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'ali.askarov@example.kz' and o.order_date = '2026-03-05 12:00:00'),
    (select product_id from public.products where sku = 'SKIN-CREAM01'), 1, 500.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'ali.askarov@example.kz' and o.order_date = '2026-03-05 12:00:00'),
    (select product_id from public.products where sku = 'BODY-SCRUB01'), 2, 0.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'dana.s@example.kz' and o.order_date = '2026-03-10 15:30:00'),
    (select product_id from public.products where sku = 'SKIN-SERUM02'), 1, 0.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'dana.s@example.kz' and o.order_date = '2026-03-10 15:30:00'),
    (select product_id from public.products where sku = 'MAKE-LIP01'), 1, 200.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'ivan.ivanov@example.kz' and o.order_date = '2026-04-12 18:20:00'),
    (select product_id from public.products where sku = 'FRAG-PERF01'), 1, 3000.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'ivan.ivanov@example.kz' and o.order_date = '2026-04-12 18:20:00'),
    (select product_id from public.products where sku = 'HAIR-SHAM01'), 1, 0.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'aiga.m@example.kz' and o.order_date = '2026-05-01 10:15:00'),
    (select product_id from public.products where sku = 'MAKE-FOUND02'), 1, 0.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'aiga.m@example.kz' and o.order_date = '2026-05-01 10:15:00'),
    (select product_id from public.products where sku = 'FRAG-MIST02'), 1, 500.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'dima.p@example.kz' and o.order_date = '2026-05-20 14:00:00'),
    (select product_id from public.products where sku = 'HAIR-MASK02'), 1, 0.00
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'dima.p@example.kz' and o.order_date = '2026-05-20 14:00:00'),
    (select product_id from public.products where sku = 'BODY-LOTION02'), 1, 0.00
);

-- INSERT ... SELECT: Marketing promotion gifting a Blending Sponge on Haircare product orders.
insert into public.order_items (order_id, product_id, quantity, discount_amount)
select 
    o.order_id, 
    (select product_id from public.products where sku = 'TOOL-SPON01'), 
    1, 
    0.00
from public.orders o
join public.order_items oi on o.order_id = oi.order_id
join public.products p on oi.product_id = p.product_id
where p.category_id = (select category_id from public.categories where category_name = 'Haircare')
on conflict (order_id, product_id) do nothing;

-- 6th Table Data Population via Subqueries
insert into public.payments (order_id, payment_date, amount, payment_method) values
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'ali.askarov@example.kz' and o.order_date = '2026-03-05 12:00:00'),
    '2026-03-05 12:05:00', 21800.00, 'card'
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'dana.s@example.kz' and o.order_date = '2026-03-10 15:30:00'),
    '2026-03-10 15:32:00', 23300.00, 'qr_code'
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'ivan.ivanov@example.kz' and o.order_date = '2026-04-12 18:20:00'),
    '2026-04-12 18:25:00', 38500.00, 'card'
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'aiga.m@example.kz' and o.order_date = '2026-05-01 10:15:00'),
    '2026-05-01 10:18:00', 21000.00, 'card'
),
(
    (select order_id from public.orders o join public.customers c on o.customer_id = c.customer_id where c.email = 'zarina.k@example.kz' and o.order_date = '2026-05-22 09:30:00'),
    '2026-05-22 09:35:00', 5000.00, 'cash'
);

-- SECTION 7: DATA UPDATES (WITH EXPLICIT BUSINESS RATIONALE)

-- Update 1 (Simple): Loyalty retention bonus applied to customers who registered in Q1 of 2026.
update public.customers
set loyalty_points = loyalty_points + 150
where registration_date < '2026-04-01 00:00:00';

-- Update 2 (Subquery): Strategic promotional campaign injecting a baseline discount on pending/processing makeup lines.
update public.order_items oi
set discount_amount = oi.discount_amount + (0.10 * (select p.unit_price from public.products p where p.product_id = oi.product_id))
where oi.product_id in (select product_id from public.products where category_id = (select category_id from public.categories where category_name = 'Makeup'))
  and oi.order_id in (select order_id from public.orders where status in ('pending', 'processing'));

-- SECTION 8: TRANSACTION CONTROL
begin;
delete from public.orders 
where status = 'cancelled'
returning order_id, customer_id, order_date, status;
rollback;

-- SECTION 9: DATA CONTROL LANGUAGE (DCL)
grant select on all tables in schema public to cosmetics_readonly;
grant insert, update on public.orders to cosmetics_writer;
revoke update on public.orders from cosmetics_writer;
