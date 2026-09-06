-- Up Migration

ALTER TABLE categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;

UPDATE categories c
SET sort_order = s.rn - 1
FROM (
  SELECT id, row_number() OVER (
    PARTITION BY user_id, type, parent_id ORDER BY created_at
  ) AS rn
  FROM categories
) s
WHERE c.id = s.id;

-- Down Migration

ALTER TABLE categories DROP COLUMN sort_order;
