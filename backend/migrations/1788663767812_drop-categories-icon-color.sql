-- Up Migration

ALTER TABLE categories DROP COLUMN icon;
ALTER TABLE categories DROP COLUMN color;

-- Down Migration

ALTER TABLE categories ADD COLUMN icon TEXT;
ALTER TABLE categories ADD COLUMN color TEXT;
