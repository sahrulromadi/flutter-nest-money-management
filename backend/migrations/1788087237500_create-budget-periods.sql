-- Up Migration

CREATE TABLE budget_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  started_at DATE NOT NULL,
  ended_at DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_budget_periods_user_id ON budget_periods(user_id);

-- only one active (ended_at IS NULL) period per user at a time
CREATE UNIQUE INDEX idx_budget_periods_one_active_per_user
  ON budget_periods(user_id)
  WHERE ended_at IS NULL AND deleted_at IS NULL;

-- Down Migration

DROP TABLE IF EXISTS budget_periods;
