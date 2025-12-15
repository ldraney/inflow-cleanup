-- Inventory issue detection views

-- Locations with negative stock quantities
CREATE VIEW IF NOT EXISTS inventory_negative_stock AS
SELECT
    il.inventory_line_id,
    il.product_id,
    p.name as product_name,
    p.sku,
    il.location_id,
    l.name as location_name,
    CAST(il.quantity_on_hand AS REAL) as quantity_on_hand,
    'Negative stock quantity' as issue_description
FROM inventory_lines il
JOIN products p ON il.product_id = p.product_id
JOIN locations l ON il.location_id = l.location_id
WHERE CAST(il.quantity_on_hand AS REAL) < 0;

-- Stock in inactive locations (phantom stock)
CREATE VIEW IF NOT EXISTS inventory_phantom_stock AS
SELECT
    il.inventory_line_id,
    il.product_id,
    p.name as product_name,
    p.sku,
    il.location_id,
    l.name as location_name,
    l.is_active as location_is_active,
    CAST(il.quantity_on_hand AS REAL) as quantity_on_hand,
    'Stock in inactive location' as issue_description
FROM inventory_lines il
JOIN products p ON il.product_id = p.product_id
JOIN locations l ON il.location_id = l.location_id
WHERE l.is_active = 0
  AND CAST(il.quantity_on_hand AS REAL) > 0;
