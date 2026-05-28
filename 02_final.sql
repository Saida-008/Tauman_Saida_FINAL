-- Drop existing tables to ensure clean, re-runnable execution
drop table if exists public.order_items cascade;
drop table if exists public.orders cascade;
drop table if exists public.products cascade;
drop table if exists public.categories cascade;
drop table if exists public.customers cascade;

-- PART 2: INITIALIZE ROLES WITH PURPOSE COMMENTS
do $$ 
begin
    -- Role 1: Designed for data analysts and reporting systems to securely read data without modification risks
    if not exists (select 1 from pg_roles where rolname = 'cosmetics_readonly') then
        create role cosmetics_readonly;
    end if;
    -- Role 2: Designed for order managers and cashiers who require write permissions on the transactional tables
    if not exists (select 1 from pg_roles where rolname = 'cosmetics_writer') then
        create role cosmetics_writer;
    end if;
end $$;

-- ===== PART 3: CREATE TABLES & CONSTRAINTS =====

create table public.customers (
    customer_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    email varchar(100) not null constraint uq_customer_email unique,
    phone_number varchar(15),
    delivery_address text not null,
    registration_date timestamp default now() not null,
    constraint chk_registration_date check (registration_date > date '2026-01-01')
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
    constraint chk_unit_price check (unit_price >= 0.00),
    constraint chk_stock_quantity check (stock_quantity >= 0),
    constraint fk_products_categories foreign key (category_id) 
        references public.categories(category_id) on delete restrict
);

create table public.orders (
    order_id serial primary key,
    customer_id int not null,
    order_date timestamp default now() not null,
    status varchar(20) default 'pending' not null,
    constraint chk_order_status check (status in ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    constraint chk_order_date check (order_date > date '2026-01-01'),
    constraint fk_orders_customers foreign key (customer_id) 
        references public.customers(customer_id) on delete cascade
);

create table public.order_items (
    order_id int not null,
    product_id int not null,
    quantity int not null,
    discount_amount numeric(10,2) default 0.00 not null,
    total_price numeric(10,2) generated always as ((quantity * 100 - discount_amount * 100) / 100.0) stored,
    primary key (order_id, product_id),
    constraint chk_item_quantity check (quantity > 0),
    constraint chk_discount check (discount_amount >= 0.00),
    constraint fk_items_orders foreign key (order_id) 
        references public.orders(order_id) on delete cascade,
    constraint fk_items_products foreign key (product_id) 
        references public.products(product_id) on delete restrict
);

-- ===== PART 4: ALTER TABLE OPERATIONS WITH BUSINESS REASONS =====

-- Business Reason: Expand phone number column length to accommodate international numbering formats (+7...)
alter table public.customers alter column phone_number type varchar(25);

-- Business Reason: Introduce a marketing loyalty program to allow tracked customers to earn reward points
alter table public.customers add column loyalty_points int default 0 not null;

-- Business Reason: Enforce operational policy ensuring loyalty points balances can never drop below zero
alter table public.customers add constraint chk_loyalty_points check (loyalty_points >= 0);

-- Business Reason: Rename column to match explicit context naming standards across the microservice schema
alter table public.categories rename column description to category_description;

-- Business Reason: Temporary addition for testing middle name collection, subsequently dropped due to updated privacy compliance rules
alter table public.customers add column middle_name varchar(50); 
alter table public.customers drop column middle_name;

-- ===== PART 5: INSERT DATA =====

truncate table 
    public.order_items, 
    public.orders, 
    public.products, 
    public.categories, 
    public.customers 
restart identity cascade;

insert into public.categories (category_name, category_description) values
('Skincare', 'Creams, serums, and cleansers for face care'),
('Haircare', 'Shampoos, conditioners, and hair masks'),
('Makeup', 'Foundations, lipsticks, and mascaras for beauty'),
('Fragrances', 'Perfumes and body mists'),
('Body Care', 'Body lotions, scrubs, and shower gels');

insert into public.customers (first_name, last_name, email, phone_number, delivery_address, registration_date) values
('Ali', 'Askarov', 'ali.askarov@example.kz', '+77011112233', 'Abay Ave 45, Almaty', '2026-02-15 10:00:00'),
('Dana', 'Serikova', 'dana.s@example.kz', '+77023334455', 'Mangilik El 12, Astana', '2026-03-01 11:30:00'),
('Ivan', 'Ivanov', 'ivan.ivanov@example.kz', '+77056667788', 'Kabanbay Batyr 8, Astana', '2026-03-20 14:15:00'),
('Aigerim', 'Muratova', 'aiga.m@example.kz', '+77078889900', 'Satpayev St 22, Almaty', '2026-04-05 09:00:00'),
('Dmitry', 'Petrov', 'dima.p@example.kz', '+77471115599', 'Tole Bi 104, Almaty', '2026-05-10 16:45:00');

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
((select category_id from public.categories where category_name = 'Body Care'), 'Shea Body Lotion', 'BODY-LOTION02', 5800.00, 75);

insert into public.orders (customer_id, order_date, status) values
((select customer_id from public.customers where email = 'ali.askarov@example.kz'), '2026-03-05 12:00:00', 'delivered'),
((select customer_id from public.customers where email = 'dana.s@example.kz'), '2026-03-10 15:30:00', 'delivered'),
((select customer_id from public.customers where email = 'ivan.ivanov@example.kz'), '2026-04-12 18:20:00', 'shipped'),
((select customer_id from public.customers where email = 'aiga.m@example.kz'), '2026-05-01 10:15:00', 'processing'),
((select customer_id from public.customers where email = 'dima.p@example.kz'), '2026-05-20 14:00:00', 'cancelled');

insert into public.order_items (order_id, product_id, quantity, discount_amount) values
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'ali.askarov@example.kz') and order_date = '2026-03-05 12:00:00'),
    (select product_id from public.products where sku = 'SKIN-CREAM01'), 1, 500.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'ali.askarov@example.kz') and order_date = '2026-03-05 12:00:00'),
    (select product_id from public.products where sku = 'BODY-SCRUB01'), 2, 0.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'dana.s@example.kz') and order_date = '2026-03-10 15:30:00'),
    (select product_id from public.products where sku = 'SKIN-SERUM02'), 1, 0.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'dana.s@example.kz') and order_date = '2026-03-10 15:30:00'),
    (select product_id from public.products where sku = 'MAKE-LIP01'), 1, 200.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'ivan.ivanov@example.kz') and order_date = '2026-04-12 18:20:00'),
    (select product_id from public.products where sku = 'FRAG-PERF01'), 1, 3000.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'ivan.ivanov@example.kz') and order_date = '2026-04-12 18:20:00'),
    (select product_id from public.products where sku = 'HAIR-SHAM01'), 1, 0.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'aiga.m@example.kz') and order_date = '2026-05-01 10:15:00'),
    (select product_id from public.products where sku = 'MAKE-FOUND02'), 1, 0.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'aiga.m@example.kz') and order_date = '2026-05-01 10:15:00'),
    (select product_id from public.products where sku = 'FRAG-MIST02'), 1, 500.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'dima.p@example.kz') and order_date = '2026-05-20 14:00:00'),
    (select product_id from public.products where sku = 'HAIR-MASK02'), 1, 0.00
),
(
    (select order_id from public.orders where customer_id = (select customer_id from public.customers where email = 'dima.p@example.kz') and order_date = '2026-05-20 14:00:00'),
    (select product_id from public.products where sku = 'BODY-LOTION02'), 1, 0.00
);

-- Advanced INSERT ... SELECT Operation populating the junction table dynamically
insert into public.order_items (order_id, product_id, quantity, discount_amount)
select 
    o.order_id, 
    (select product_id from public.products where sku = 'BODY-SCRUB01'), 
    1, 
    4900.00
from public.orders o
join public.order_items oi on o.order_id = oi.order_id
join public.products p on oi.product_id = p.product_id
where p.category_id = (select category_id from public.categories where category_name = 'Haircare')
on conflict (order_id, product_id) do nothing;

-- ===== PART 6: UPDATE & DELETE WITH BUSINESS REASONS =====

-- Business Reason (Simple UPDATE): Award 150 loyalty points to early customers registered before April 1st as part of a promotional campaign
update public.customers
set loyalty_points = loyalty_points + 150
where registration_date < '2026-04-01 00:00:00';

-- Business Reason (Subquery UPDATE): Apply an additional 10% unit-price discount on items belonging to active, unfulfilled Makeup orders
update public.order_items
set discount_amount = discount_amount + (0.10 * (select unit_price from public.products p where p.product_id = order_items.product_id))
where product_id in (select product_id from public.products where category_id = (select category_id from public.categories where category_name = 'Makeup'))
  and order_id in (select order_id from public.orders where status in ('pending', 'processing'));

-- Business Reason (Transactional DELETE): Purge cancelled orders from active visibility while logging the removed data before executing a testing rollback
begin;

delete from public.orders 
where status = 'cancelled'
returning order_id, customer_id, order_date, status;

rollback;

-- ===== PART 7: PRIVILEGES WITH COMMENTS =====

-- Business Reason: Grant read-only structural permissions on public schema to the analytical reporting role
grant select on all tables in schema public to cosmetics_readonly;

-- Business Reason: Grant write permissions on the orders table to the order management processing role
grant insert, update on public.orders to cosmetics_writer;

-- Business Reason: Revoke data modification permissions from the writer role to enforce data consistency controls
revoke update on public.orders from cosmetics_writer;
