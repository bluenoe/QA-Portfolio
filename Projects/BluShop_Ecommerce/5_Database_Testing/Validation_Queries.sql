-- ==============================================================================
-- FILE: Validation_Queries.sql
-- DESCRIPTION: QA Database Queries for Shopping Cart Validation
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 1: Active Cart Item & User State Validation
-- QA Test Objective: Check if items are correctly inserted into 'carts' table.
-- Verifies user ownership, quantity sanity (>0), and active state.
-- ------------------------------------------------------------------------------
SELECT 
    c.id AS cart_item_id,
    c.user_id,
    c.product_id,
    p.name AS product_name,
    c.size,
    c.color,
    c.quantity,
    c.unit_price,
    (c.quantity * c.unit_price) AS line_total,
    c.created_at,
    c.updated_at
FROM carts c
INNER JOIN products p ON c.product_id = p.id
WHERE c.user_id = 42 -- Thay đổi user_id cần test tại đây
  AND c.quantity > 0
ORDER BY c.created_at DESC;


-- ------------------------------------------------------------------------------
-- QUERY 2: Cart Price Discrepancy & Subtotal Variance Audit
-- QA Test Objective: Verify if stored cart prices match current database product prices.
-- Flags any row where the cart line item price differs from the official products table.
-- ------------------------------------------------------------------------------
SELECT 
    c.user_id,
    c.product_id,
    p.name AS product_name,
    c.quantity,
    c.unit_price AS stored_cart_price,
    p.base_price AS current_product_price,
    (c.unit_price - p.base_price) AS unit_price_difference,
    (c.quantity * c.unit_price) AS calculated_line_total,
    (c.quantity * p.base_price) AS expected_line_total,
    CASE 
        WHEN c.unit_price <> p.base_price THEN 'MISMATCH / STALE PRICE'
        ELSE 'VALID'
    END AS integrity_status
FROM carts c
JOIN products p ON c.product_id = p.id
HAVING integrity_status = 'MISMATCH / STALE PRICE';


-- ------------------------------------------------------------------------------
-- QUERY 3: Orphaned Cart Item & Soft-Deleted Product Audit
-- QA Test Objective: Find orphaned cart records referencing deleted or missing products.
-- Uses LEFT JOIN to detect null foreign key references, soft-deleted, or inactive products.
-- ------------------------------------------------------------------------------
SELECT 
    c.id AS cart_item_id,
    c.user_id,
    c.product_id,
    c.quantity,
    c.created_at,
    CASE 
        WHEN p.id IS NULL THEN 'MISSING_PRODUCT'
        WHEN p.deleted_at IS NOT NULL THEN 'SOFT_DELETED_PRODUCT'
        WHEN p.is_active = 0 THEN 'INACTIVE_PRODUCT'
        ELSE 'UNKNOWN_ORPHAN'
    END AS orphan_reason
FROM carts c
LEFT JOIN products p ON c.product_id = p.id
WHERE p.id IS NULL 
   OR p.deleted_at IS NOT NULL 
   OR p.is_active = 0;
