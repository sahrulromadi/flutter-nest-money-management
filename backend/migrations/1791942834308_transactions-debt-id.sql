-- Up Migration

ALTER TABLE transactions ADD COLUMN debt_id UUID REFERENCES debts(id);

CREATE INDEX idx_transactions_debt_id ON transactions(debt_id);

-- Down Migration

DROP INDEX IF EXISTS idx_transactions_debt_id;
ALTER TABLE transactions DROP COLUMN debt_id;
