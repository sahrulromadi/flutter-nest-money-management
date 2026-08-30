-- Up Migration

CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  account_id UUID REFERENCES accounts(id),
  name TEXT NOT NULL,
  target_amount NUMERIC(18,2) NOT NULL,
  due_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_goals_user_id ON goals(user_id);

-- Down Migration

DROP TABLE IF EXISTS goals;
