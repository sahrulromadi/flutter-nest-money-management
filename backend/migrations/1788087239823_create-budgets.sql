-- Up Migration

CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_period_id UUID NOT NULL REFERENCES budget_periods(id),
  category_id UUID NOT NULL REFERENCES categories(id),
  limit_amount NUMERIC(18,2) NOT NULL CHECK (limit_amount > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (budget_period_id, category_id)
);

CREATE INDEX idx_budgets_budget_period_id ON budgets(budget_period_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);

-- Down Migration

DROP TABLE IF EXISTS budgets;
