-- Up Migration

ALTER TABLE accounts ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;

UPDATE accounts a
SET sort_order = s.rn - 1
FROM (
  SELECT id, row_number() OVER (
    PARTITION BY user_id ORDER BY created_at
  ) AS rn
  FROM accounts
) s
WHERE a.id = s.id;

-- Down Migration

ALTER TABLE accounts DROP COLUMN sort_order;
