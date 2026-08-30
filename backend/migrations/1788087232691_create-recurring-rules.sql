-- Up Migration

CREATE TABLE recurring_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  account_id UUID NOT NULL REFERENCES accounts(id),
  category_id UUID NOT NULL REFERENCES categories(id),
  type TEXT NOT NULL CHECK (type IN ('Income', 'Expense')),
  amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
  note TEXT,
  interval_unit TEXT NOT NULL CHECK (interval_unit IN ('Day', 'Week', 'Month')),
  interval_value INT NOT NULL DEFAULT 1 CHECK (interval_value > 0),
  start_date DATE NOT NULL,
  next_run_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_recurring_rules_user_id ON recurring_rules(user_id);
CREATE INDEX idx_recurring_rules_next_run_date ON recurring_rules(next_run_date);

-- Down Migration

DROP TABLE IF EXISTS recurring_rules;
