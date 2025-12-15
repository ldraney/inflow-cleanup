-- Product issue detection views

-- Products with no vendor item cost (or zero cost)
-- These need pricing data to be useful for costing
CREATE VIEW IF NOT EXISTS products_missing_cost AS
SELECT
    p.product_id,
    p.name,
    p.sku,
    p.item_type,
    p.is_active,
    COALESCE(MAX(CAST(vi.cost AS REAL)), 0) as max_vendor_cost,
    'No vendor cost defined' as issue_description
FROM products p
LEFT JOIN vendor_items vi ON p.product_id = vi.product_id
WHERE p.is_active = 1
GROUP BY p.product_id
HAVING max_vendor_cost = 0 OR max_vendor_cost IS NULL;

-- Products with duplicate names (potential merge candidates)
CREATE VIEW IF NOT EXISTS products_duplicate_names AS
SELECT
    p.product_id,
    p.name,
    p.sku,
    p.item_type,
    p.is_active,
    p.last_modified_date_time,
    cnt.duplicate_count,
    'Duplicate product name' as issue_description
FROM products p
JOIN (
    SELECT name, COUNT(*) as duplicate_count
    FROM products
    WHERE name IS NOT NULL AND name != ''
    GROUP BY name
    HAVING COUNT(*) > 1
) cnt ON p.name = cnt.name
ORDER BY p.name, p.last_modified_date_time DESC;

-- Active products with no vendor link
CREATE VIEW IF NOT EXISTS products_no_vendor AS
SELECT
    p.product_id,
    p.name,
    p.sku,
    p.item_type,
    p.is_active,
    'No vendor linked' as issue_description
FROM products p
LEFT JOIN vendor_items vi ON p.product_id = vi.product_id
WHERE p.is_active = 1
  AND p.item_type IN ('Stocked', 'Serialized', 'Lot Tracked', 'Non-Stocked')
  AND vi.vendor_item_id IS NULL;

-- BOM items referencing products that no longer exist or are inactive
CREATE VIEW IF NOT EXISTS products_orphaned_boms AS
SELECT
    b.item_bom_id,
    b.product_id as parent_product_id,
    parent.name as parent_name,
    b.child_product_id,
    child.name as child_name,
    child.is_active as child_is_active,
    CASE
        WHEN child.product_id IS NULL THEN 'Child product deleted'
        WHEN child.is_active = 0 THEN 'Child product inactive'
    END as issue_description
FROM item_boms b
JOIN products parent ON b.product_id = parent.product_id
LEFT JOIN products child ON b.child_product_id = child.product_id
WHERE parent.is_active = 1
  AND (child.product_id IS NULL OR child.is_active = 0);

-- Inactive products still used in active BOMs
CREATE VIEW IF NOT EXISTS products_inactive_in_active_boms AS
SELECT
    p.product_id,
    p.name,
    p.sku,
    p.is_active,
    COUNT(b.item_bom_id) as bom_usage_count,
    GROUP_CONCAT(DISTINCT parent.name) as used_in_products,
    'Inactive but used in active BOMs' as issue_description
FROM products p
JOIN item_boms b ON p.product_id = b.child_product_id
JOIN products parent ON b.product_id = parent.product_id
WHERE p.is_active = 0
  AND parent.is_active = 1
GROUP BY p.product_id;

-- Products with inconsistent UOM (standard_uom differs from BOM uom)
CREATE VIEW IF NOT EXISTS products_inconsistent_units AS
SELECT
    p.product_id,
    p.name,
    p.standard_uom_name,
    b.uom_name as bom_uom_name,
    parent.name as parent_product,
    'UOM mismatch between product and BOM' as issue_description
FROM products p
JOIN item_boms b ON p.product_id = b.child_product_id
JOIN products parent ON b.product_id = parent.product_id
WHERE p.standard_uom_name IS NOT NULL
  AND b.uom_name IS NOT NULL
  AND p.standard_uom_name != b.uom_name;
