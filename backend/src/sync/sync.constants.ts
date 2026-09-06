export interface SyncTableConfig {
  name: string;
  columns: string[];
  /** SQL WHERE fragment (table unqualified, param $2 = userId) scoping rows to the current user */
  userScopeWhere: string;
  hasUserIdColumn: boolean;
}

export const SYNC_TABLES: SyncTableConfig[] = [
  {
    name: 'accounts',
    columns: [
      'id',
      'user_id',
      'name',
      'initial_balance',
      'currency',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    userScopeWhere: 'user_id = $2',
    hasUserIdColumn: true,
  },
  {
    name: 'categories',
    columns: [
      'id',
      'user_id',
      'name',
      'type',
      'parent_id',
      'sort_order',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    userScopeWhere: 'user_id = $2',
    hasUserIdColumn: true,
  },
  {
    name: 'goals',
    columns: [
      'id',
      'user_id',
      'account_id',
      'name',
      'target_amount',
      'due_date',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    userScopeWhere: 'user_id = $2',
    hasUserIdColumn: true,
  },
  {
    name: 'recurring_rules',
    columns: [
      'id',
      'user_id',
      'account_id',
      'category_id',
      'type',
      'amount',
      'note',
      'interval_unit',
      'interval_value',
      'start_date',
      'next_run_date',
      'end_date',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    userScopeWhere: 'user_id = $2',
    hasUserIdColumn: true,
  },
  {
    name: 'transactions',
    columns: [
      'id',
      'user_id',
      'account_id',
      'category_id',
      'type',
      'amount',
      'transfer_to_account_id',
      'occurred_at',
      'note',
      'recurring_rule_id',
      'goal_id',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    userScopeWhere: 'user_id = $2',
    hasUserIdColumn: true,
  },
  {
    name: 'budget_periods',
    columns: [
      'id',
      'user_id',
      'started_at',
      'ended_at',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    userScopeWhere: 'user_id = $2',
    hasUserIdColumn: true,
  },
  {
    name: 'budgets',
    columns: [
      'id',
      'budget_period_id',
      'category_id',
      'limit_amount',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    userScopeWhere:
      'budget_period_id IN (SELECT id FROM budget_periods WHERE user_id = $2)',
    hasUserIdColumn: false,
  },
];

export function getSyncTable(name: string): SyncTableConfig | undefined {
  return SYNC_TABLES.find((t) => t.name === name);
}
