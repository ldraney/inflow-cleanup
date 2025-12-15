-- Order issue detection views

-- Draft purchase orders older than 30 days (stale)
CREATE VIEW IF NOT EXISTS orders_stale_draft AS
SELECT
    po.purchase_order_id as order_id,
    'PO' as order_type,
    po.order_number,
    po.status,
    po.order_date,
    v.name as counterparty_name,
    CAST(julianday('now') - julianday(po.order_date) AS INTEGER) as days_old,
    'Draft order older than 30 days' as issue_description
FROM purchase_orders po
LEFT JOIN vendors v ON po.vendor_id = v.vendor_id
WHERE po.status = 'Draft'
  AND julianday('now') - julianday(po.order_date) > 30

UNION ALL

SELECT
    so.sales_order_id as order_id,
    'SO' as order_type,
    so.order_number,
    so.status,
    so.order_date,
    c.name as counterparty_name,
    CAST(julianday('now') - julianday(so.order_date) AS INTEGER) as days_old,
    'Draft order older than 30 days' as issue_description
FROM sales_orders so
LEFT JOIN customers c ON so.customer_id = c.customer_id
WHERE so.status = 'Draft'
  AND julianday('now') - julianday(so.order_date) > 30;

-- Order lines referencing deleted or inactive products
CREATE VIEW IF NOT EXISTS orders_orphaned_lines AS
SELECT
    pol.purchase_order_line_id as line_id,
    'PO' as order_type,
    po.order_number,
    po.status,
    pol.product_id,
    p.name as product_name,
    p.is_active as product_is_active,
    CASE
        WHEN p.product_id IS NULL THEN 'Product deleted'
        WHEN p.is_active = 0 THEN 'Product inactive'
    END as issue_description
FROM purchase_order_lines pol
JOIN purchase_orders po ON pol.purchase_order_id = po.purchase_order_id
LEFT JOIN products p ON pol.product_id = p.product_id
WHERE po.status IN ('Draft', 'Issued', 'Partial')
  AND (p.product_id IS NULL OR p.is_active = 0)

UNION ALL

SELECT
    sol.sales_order_line_id as line_id,
    'SO' as order_type,
    so.order_number,
    so.status,
    sol.product_id,
    p.name as product_name,
    p.is_active as product_is_active,
    CASE
        WHEN p.product_id IS NULL THEN 'Product deleted'
        WHEN p.is_active = 0 THEN 'Product inactive'
    END as issue_description
FROM sales_order_lines sol
JOIN sales_orders so ON sol.sales_order_id = so.sales_order_id
LEFT JOIN products p ON sol.product_id = p.product_id
WHERE so.status IN ('Draft', 'Issued', 'Partial')
  AND (p.product_id IS NULL OR p.is_active = 0);
