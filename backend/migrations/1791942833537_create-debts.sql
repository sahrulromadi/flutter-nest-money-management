-- Up Migration

CREATE TABLE debts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  direction TEXT NOT NULL CHECK (direction IN ('Utang', 'Piutang')),
  counterparty TEXT NOT NULL,
  amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
  due_date DATE,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_debts_user_id ON debts(user_id);

-- Down Migration

DROP TABLE IF EXISTS debts;
