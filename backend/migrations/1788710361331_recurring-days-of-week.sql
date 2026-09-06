-- Up Migration

ALTER TABLE recurring_rules ADD COLUMN days_of_week TEXT;

ALTER TABLE recurring_rules DROP CONSTRAINT recurring_rules_interval_unit_check;
ALTER TABLE recurring_rules ADD CONSTRAINT recurring_rules_interval_unit_check
  CHECK (interval_unit IN ('Day', 'Week', 'Month', 'DaysOfWeek'));

-- Down Migration

ALTER TABLE recurring_rules DROP CONSTRAINT recurring_rules_interval_unit_check;
ALTER TABLE recurring_rules ADD CONSTRAINT recurring_rules_interval_unit_check
  CHECK (interval_unit IN ('Day', 'Week', 'Month'));

ALTER TABLE recurring_rules DROP COLUMN days_of_week;
