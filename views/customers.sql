-- Customer issue detection views

-- Customers with duplicate names (potential merge candidates)
CREATE VIEW IF NOT EXISTS customers_duplicate_names AS
SELECT
    c.customer_id,
    c.name,
    c.customer_code,
    c.is_active,
    c.last_modified_date_time,
    cnt.duplicate_count,
    'Duplicate customer name' as issue_description
FROM customers c
JOIN (
    SELECT name, COUNT(*) as duplicate_count
    FROM customers
    WHERE name IS NOT NULL AND name != ''
    GROUP BY name
    HAVING COUNT(*) > 1
) cnt ON c.name = cnt.name
ORDER BY c.name, c.last_modified_date_time DESC;

-- Customers with no order history (potentially unused)
CREATE VIEW IF NOT EXISTS customers_no_orders AS
SELECT
    c.customer_id,
    c.name,
    c.customer_code,
    c.is_active,
    c.last_modified_date_time,
    'No order history' as issue_description
FROM customers c
LEFT JOIN sales_orders so ON c.customer_id = so.customer_id
WHERE so.sales_order_id IS NULL;
