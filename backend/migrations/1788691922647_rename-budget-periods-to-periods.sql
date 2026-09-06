-- Up Migration

ALTER TABLE budget_periods RENAME TO periods;
ALTER TABLE periods RENAME CONSTRAINT budget_periods_pkey TO periods_pkey;
ALTER TABLE periods RENAME CONSTRAINT budget_periods_user_id_fkey TO periods_user_id_fkey;
ALTER INDEX idx_budget_periods_user_id RENAME TO idx_periods_user_id;
ALTER INDEX idx_budget_periods_one_active_per_user RENAME TO idx_periods_one_active_per_user;

ALTER TABLE budgets RENAME COLUMN budget_period_id TO period_id;
ALTER TABLE budgets RENAME CONSTRAINT budgets_budget_period_id_fkey TO budgets_period_id_fkey;
ALTER TABLE budgets RENAME CONSTRAINT budgets_budget_period_id_category_id_key TO budgets_period_id_category_id_key;
ALTER INDEX idx_budgets_budget_period_id RENAME TO idx_budgets_period_id;

-- Down Migration

ALTER INDEX idx_budgets_period_id RENAME TO idx_budgets_budget_period_id;
ALTER TABLE budgets RENAME CONSTRAINT budgets_period_id_category_id_key TO budgets_budget_period_id_category_id_key;
ALTER TABLE budgets RENAME CONSTRAINT budgets_period_id_fkey TO budgets_budget_period_id_fkey;
ALTER TABLE budgets RENAME COLUMN period_id TO budget_period_id;

ALTER INDEX idx_periods_one_active_per_user RENAME TO idx_budget_periods_one_active_per_user;
ALTER INDEX idx_periods_user_id RENAME TO idx_budget_periods_user_id;
ALTER TABLE periods RENAME CONSTRAINT periods_user_id_fkey TO budget_periods_user_id_fkey;
ALTER TABLE periods RENAME CONSTRAINT periods_pkey TO budget_periods_pkey;
ALTER TABLE periods RENAME TO budget_periods;
