-- Up Migration

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  account_id UUID NOT NULL REFERENCES accounts(id),
  category_id UUID REFERENCES categories(id),
  type TEXT NOT NULL CHECK (type IN ('Income', 'Expense', 'Transfer')),
  amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
  transfer_to_account_id UUID REFERENCES accounts(id),
  occurred_at DATE NOT NULL,
  note TEXT,
  recurring_rule_id UUID REFERENCES recurring_rules(id),
  goal_id UUID REFERENCES goals(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CHECK (type <> 'Transfer' OR transfer_to_account_id IS NOT NULL),
  CHECK (type = 'Transfer' OR category_id IS NOT NULL),
  CHECK (transfer_to_account_id IS NULL OR transfer_to_account_id <> account_id)
);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_transfer_to_account_id ON transactions(transfer_to_account_id);
CREATE INDEX idx_transactions_category_id ON transactions(category_id);
CREATE INDEX idx_transactions_occurred_at ON transactions(occurred_at);
CREATE INDEX idx_transactions_goal_id ON transactions(goal_id);
CREATE INDEX idx_transactions_recurring_rule_id ON transactions(recurring_rule_id);

-- Down Migration

DROP TABLE IF EXISTS transactions;
