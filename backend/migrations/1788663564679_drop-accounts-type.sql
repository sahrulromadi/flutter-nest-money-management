-- Up Migration

ALTER TABLE accounts DROP COLUMN type;

-- Down Migration

ALTER TABLE accounts
  ADD COLUMN type TEXT NOT NULL DEFAULT 'Cash'
  CHECK (type IN ('Bank', 'Ewallet', 'Cash'));
