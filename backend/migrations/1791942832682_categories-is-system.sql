-- Up Migration

ALTER TABLE categories ADD COLUMN is_system BOOLEAN NOT NULL DEFAULT false;

-- Down Migration

ALTER TABLE categories DROP COLUMN is_system;
