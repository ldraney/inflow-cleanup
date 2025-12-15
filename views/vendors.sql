-- Vendor issue detection views

-- Vendors with no linked products (potentially unused)
CREATE VIEW IF NOT EXISTS vendors_no_products AS
SELECT
    v.vendor_id,
    v.name,
    v.vendor_code,
    v.is_active,
    v.last_modified_date_time,
    'No products linked' as issue_description
FROM vendors v
LEFT JOIN vendor_items vi ON v.vendor_id = vi.vendor_id
WHERE vi.vendor_item_id IS NULL;

-- Vendors with duplicate names (potential merge candidates)
CREATE VIEW IF NOT EXISTS vendors_duplicate_names AS
SELECT
    v.vendor_id,
    v.name,
    v.vendor_code,
    v.is_active,
    v.last_modified_date_time,
    cnt.duplicate_count,
    'Duplicate vendor name' as issue_description
FROM vendors v
JOIN (
    SELECT name, COUNT(*) as duplicate_count
    FROM vendors
    WHERE name IS NOT NULL AND name != ''
    GROUP BY name
    HAVING COUNT(*) > 1
) cnt ON v.name = cnt.name
ORDER BY v.name, v.last_modified_date_time DESC;
