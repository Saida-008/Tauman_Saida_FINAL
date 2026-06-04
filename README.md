# Cosmetics Store Database

## Domain Description

A cosmetics store database for managing customers, products, orders, and payments.

## Database & Schema

* Schema: `cosmetics`

## Main Tables

* customers
* categories
* products
* orders
* order_items
* payments

## Run Instructions

1. Execute the SQL script.
2. Create tables and constraints.
3. Insert sample data.
4. Run updates, transactions, and role configuration.

## Design Decisions

* 3NF database design.
* Many-to-many relationship between orders and products via `order_items`.
* Data validation using CHECK, UNIQUE, and FOREIGN KEY constraints.
* Role-based access with `cosmetics_readonly` and `cosmetics_writer`.
* Transaction rollback used for safe testing.
