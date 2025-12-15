-- Materialize all issue views into snapshot tables
-- Run before each release to capture current issue state
-- Usage: sqlite3 data/inflow.sqlite < views/materialize.sql

-- Drop existing snapshot tables
DROP TABLE IF EXISTS issues_products_missing_cost;
DROP TABLE IF EXISTS issues_products_duplicate_names;
DROP TABLE IF EXISTS issues_products_no_vendor;
DROP TABLE IF EXISTS issues_products_orphaned_boms;
DROP TABLE IF EXISTS issues_products_inactive_in_active_boms;
DROP TABLE IF EXISTS issues_products_inconsistent_units;
DROP TABLE IF EXISTS issues_vendors_no_products;
DROP TABLE IF EXISTS issues_vendors_duplicate_names;
DROP TABLE IF EXISTS issues_customers_duplicate_names;
DROP TABLE IF EXISTS issues_customers_no_orders;
DROP TABLE IF EXISTS issues_orders_stale_draft;
DROP TABLE IF EXISTS issues_orders_orphaned_lines;
DROP TABLE IF EXISTS issues_inventory_negative_stock;
DROP TABLE IF EXISTS issues_inventory_phantom_stock;

-- Materialize product issues
CREATE TABLE issues_products_missing_cost AS
SELECT *, datetime('now') as captured_at FROM products_missing_cost;

CREATE TABLE issues_products_duplicate_names AS
SELECT *, datetime('now') as captured_at FROM products_duplicate_names;

CREATE TABLE issues_products_no_vendor AS
SELECT *, datetime('now') as captured_at FROM products_no_vendor;

CREATE TABLE issues_products_orphaned_boms AS
SELECT *, datetime('now') as captured_at FROM products_orphaned_boms;

CREATE TABLE issues_products_inactive_in_active_boms AS
SELECT *, datetime('now') as captured_at FROM products_inactive_in_active_boms;

CREATE TABLE issues_products_inconsistent_units AS
SELECT *, datetime('now') as captured_at FROM products_inconsistent_units;

-- Materialize vendor issues
CREATE TABLE issues_vendors_no_products AS
SELECT *, datetime('now') as captured_at FROM vendors_no_products;

CREATE TABLE issues_vendors_duplicate_names AS
SELECT *, datetime('now') as captured_at FROM vendors_duplicate_names;

-- Materialize customer issues
CREATE TABLE issues_customers_duplicate_names AS
SELECT *, datetime('now') as captured_at FROM customers_duplicate_names;

CREATE TABLE issues_customers_no_orders AS
SELECT *, datetime('now') as captured_at FROM customers_no_orders;

-- Materialize order issues
CREATE TABLE issues_orders_stale_draft AS
SELECT *, datetime('now') as captured_at FROM orders_stale_draft;

CREATE TABLE issues_orders_orphaned_lines AS
SELECT *, datetime('now') as captured_at FROM orders_orphaned_lines;

-- Materialize inventory issues
CREATE TABLE issues_inventory_negative_stock AS
SELECT *, datetime('now') as captured_at FROM inventory_negative_stock;

CREATE TABLE issues_inventory_phantom_stock AS
SELECT *, datetime('now') as captured_at FROM inventory_phantom_stock;

-- Summary table for quick overview
DROP TABLE IF EXISTS issues_summary;
CREATE TABLE issues_summary AS
SELECT
    'products_missing_cost' as view_name,
    (SELECT COUNT(*) FROM issues_products_missing_cost) as issue_count,
    datetime('now') as captured_at
UNION ALL SELECT 'products_duplicate_names', (SELECT COUNT(*) FROM issues_products_duplicate_names), datetime('now')
UNION ALL SELECT 'products_no_vendor', (SELECT COUNT(*) FROM issues_products_no_vendor), datetime('now')
UNION ALL SELECT 'products_orphaned_boms', (SELECT COUNT(*) FROM issues_products_orphaned_boms), datetime('now')
UNION ALL SELECT 'products_inactive_in_active_boms', (SELECT COUNT(*) FROM issues_products_inactive_in_active_boms), datetime('now')
UNION ALL SELECT 'products_inconsistent_units', (SELECT COUNT(*) FROM issues_products_inconsistent_units), datetime('now')
UNION ALL SELECT 'vendors_no_products', (SELECT COUNT(*) FROM issues_vendors_no_products), datetime('now')
UNION ALL SELECT 'vendors_duplicate_names', (SELECT COUNT(*) FROM issues_vendors_duplicate_names), datetime('now')
UNION ALL SELECT 'customers_duplicate_names', (SELECT COUNT(*) FROM issues_customers_duplicate_names), datetime('now')
UNION ALL SELECT 'customers_no_orders', (SELECT COUNT(*) FROM issues_customers_no_orders), datetime('now')
UNION ALL SELECT 'orders_stale_draft', (SELECT COUNT(*) FROM issues_orders_stale_draft), datetime('now')
UNION ALL SELECT 'orders_orphaned_lines', (SELECT COUNT(*) FROM issues_orders_orphaned_lines), datetime('now')
UNION ALL SELECT 'inventory_negative_stock', (SELECT COUNT(*) FROM issues_inventory_negative_stock), datetime('now')
UNION ALL SELECT 'inventory_phantom_stock', (SELECT COUNT(*) FROM issues_inventory_phantom_stock), datetime('now');

-- Print summary
SELECT view_name, issue_count FROM issues_summary ORDER BY issue_count DESC;
