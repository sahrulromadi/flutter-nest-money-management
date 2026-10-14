import 'package:drift/drift.dart';

import '../local/app_database.dart';

/// Konversi row Drift <-> JSON snake_case yang dipahami endpoint
/// `/sync/push` & `/sync/pull` backend (lihat backend plan 006). Kolom
/// `DATE` (occurred_at, started_at, dst) dikirim 'YYYY-MM-DD', kolom
/// `TIMESTAMPTZ` (created_at, updated_at, deleted_at) dikirim ISO8601 full.
String _dateOnly(DateTime d) => d.toIso8601String().substring(0, 10);
String _timestamp(DateTime d) => d.toUtc().toIso8601String();
DateTime _parseDate(String s) => DateTime.parse(s);
DateTime? _parseNullableDate(dynamic s) => s == null ? null : DateTime.parse(s as String);

// ---------- accounts ----------

Map<String, dynamic> accountToJson(Account a) => {
      'id': a.id,
      'user_id': a.userId,
      'name': a.name,
      'initial_balance': a.initialBalance,
      'currency': a.currency,
      'sort_order': a.sortOrder,
      'created_at': _timestamp(a.createdAt),
      'updated_at': _timestamp(a.updatedAt),
      'deleted_at': a.deletedAt == null ? null : _timestamp(a.deletedAt!),
    };

AccountsCompanion accountFromJson(Map<String, dynamic> j) => AccountsCompanion.insert(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      name: j['name'] as String,
      initialBalance: (j['initial_balance'] as num).toDouble(),
      currency: Value(j['currency'] as String? ?? 'IDR'),
      sortOrder: Value((j['sort_order'] as num?)?.toInt() ?? 0),
      createdAt: _parseDate(j['created_at'] as String),
      updatedAt: _parseDate(j['updated_at'] as String),
      deletedAt: Value(_parseNullableDate(j['deleted_at'])),
      pendingSync: const Value(false),
    );

// ---------- categories ----------

Map<String, dynamic> categoryToJson(Category c) => {
      'id': c.id,
      'user_id': c.userId,
      'name': c.name,
      'type': c.type,
      'parent_id': c.parentId,
      'sort_order': c.sortOrder,
      'is_system': c.isSystem,
      'created_at': _timestamp(c.createdAt),
      'updated_at': _timestamp(c.updatedAt),
      'deleted_at': c.deletedAt == null ? null : _timestamp(c.deletedAt!),
    };

CategoriesCompanion categoryFromJson(Map<String, dynamic> j) => CategoriesCompanion.insert(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      name: j['name'] as String,
      type: j['type'] as String,
      parentId: Value(j['parent_id'] as String?),
      sortOrder: Value((j['sort_order'] as num?)?.toInt() ?? 0),
      isSystem: Value(j['is_system'] as bool? ?? false),
      createdAt: _parseDate(j['created_at'] as String),
      updatedAt: _parseDate(j['updated_at'] as String),
      deletedAt: Value(_parseNullableDate(j['deleted_at'])),
      pendingSync: const Value(false),
    );

// ---------- goals ----------

Map<String, dynamic> goalToJson(Goal g) => {
      'id': g.id,
      'user_id': g.userId,
      'account_id': g.accountId,
      'name': g.name,
      'target_amount': g.targetAmount,
      'due_date': g.dueDate == null ? null : _dateOnly(g.dueDate!),
      'created_at': _timestamp(g.createdAt),
      'updated_at': _timestamp(g.updatedAt),
      'deleted_at': g.deletedAt == null ? null : _timestamp(g.deletedAt!),
    };

GoalsCompanion goalFromJson(Map<String, dynamic> j) => GoalsCompanion.insert(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      accountId: Value(j['account_id'] as String?),
      name: j['name'] as String,
      targetAmount: (j['target_amount'] as num).toDouble(),
      dueDate: Value(_parseNullableDate(j['due_date'])),
      createdAt: _parseDate(j['created_at'] as String),
      updatedAt: _parseDate(j['updated_at'] as String),
      deletedAt: Value(_parseNullableDate(j['deleted_at'])),
      pendingSync: const Value(false),
    );

// ---------- recurring_rules ----------

Map<String, dynamic> recurringRuleToJson(RecurringRule r) => {
      'id': r.id,
      'user_id': r.userId,
      'account_id': r.accountId,
      'category_id': r.categoryId,
      'type': r.type,
      'amount': r.amount,
      'note': r.note,
      'interval_unit': r.intervalUnit,
      'interval_value': r.intervalValue,
      'start_date': _dateOnly(r.startDate),
      'next_run_date': _dateOnly(r.nextRunDate),
      'end_date': r.endDate == null ? null : _dateOnly(r.endDate!),
      'days_of_week': r.daysOfWeek,
      'created_at': _timestamp(r.createdAt),
      'updated_at': _timestamp(r.updatedAt),
      'deleted_at': r.deletedAt == null ? null : _timestamp(r.deletedAt!),
    };

RecurringRulesCompanion recurringRuleFromJson(Map<String, dynamic> j) =>
    RecurringRulesCompanion.insert(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      accountId: j['account_id'] as String,
      categoryId: j['category_id'] as String,
      type: j['type'] as String,
      amount: (j['amount'] as num).toDouble(),
      note: Value(j['note'] as String?),
      intervalUnit: j['interval_unit'] as String,
      intervalValue: (j['interval_value'] as num).toInt(),
      startDate: _parseDate(j['start_date'] as String),
      nextRunDate: _parseDate(j['next_run_date'] as String),
      endDate: Value(_parseNullableDate(j['end_date'])),
      daysOfWeek: Value(j['days_of_week'] as String?),
      createdAt: _parseDate(j['created_at'] as String),
      updatedAt: _parseDate(j['updated_at'] as String),
      deletedAt: Value(_parseNullableDate(j['deleted_at'])),
      pendingSync: const Value(false),
    );

// ---------- transactions ----------

Map<String, dynamic> transactionToJson(Transaction t) => {
      'id': t.id,
      'user_id': t.userId,
      'account_id': t.accountId,
      'category_id': t.categoryId,
      'type': t.type,
      'amount': t.amount,
      'transfer_to_account_id': t.transferToAccountId,
      'occurred_at': _dateOnly(t.occurredAt),
      'note': t.note,
      'recurring_rule_id': t.recurringRuleId,
      'goal_id': t.goalId,
      'debt_id': t.debtId,
      'created_at': _timestamp(t.createdAt),
      'updated_at': _timestamp(t.updatedAt),
      'deleted_at': t.deletedAt == null ? null : _timestamp(t.deletedAt!),
    };

TransactionsCompanion transactionFromJson(Map<String, dynamic> j) =>
    TransactionsCompanion.insert(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      accountId: j['account_id'] as String,
      categoryId: Value(j['category_id'] as String?),
      type: j['type'] as String,
      amount: (j['amount'] as num).toDouble(),
      transferToAccountId: Value(j['transfer_to_account_id'] as String?),
      occurredAt: _parseDate(j['occurred_at'] as String),
      note: Value(j['note'] as String?),
      recurringRuleId: Value(j['recurring_rule_id'] as String?),
      goalId: Value(j['goal_id'] as String?),
      debtId: Value(j['debt_id'] as String?),
      createdAt: _parseDate(j['created_at'] as String),
      updatedAt: _parseDate(j['updated_at'] as String),
      deletedAt: Value(_parseNullableDate(j['deleted_at'])),
      pendingSync: const Value(false),
    );

// ---------- debts ----------

Map<String, dynamic> debtToJson(Debt d) => {
      'id': d.id,
      'user_id': d.userId,
      'direction': d.direction,
      'counterparty': d.counterparty,
      'amount': d.amount,
      'due_date': d.dueDate == null ? null : _dateOnly(d.dueDate!),
      'note': d.note,
      'created_at': _timestamp(d.createdAt),
      'updated_at': _timestamp(d.updatedAt),
      'deleted_at': d.deletedAt == null ? null : _timestamp(d.deletedAt!),
    };

DebtsCompanion debtFromJson(Map<String, dynamic> j) => DebtsCompanion.insert(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      direction: j['direction'] as String,
      counterparty: j['counterparty'] as String,
      amount: (j['amount'] as num).toDouble(),
      dueDate: Value(_parseNullableDate(j['due_date'])),
      note: Value(j['note'] as String?),
      createdAt: _parseDate(j['created_at'] as String),
      updatedAt: _parseDate(j['updated_at'] as String),
      deletedAt: Value(_parseNullableDate(j['deleted_at'])),
      pendingSync: const Value(false),
    );

// ---------- periods ----------

Map<String, dynamic> periodToJson(Period b) => {
      'id': b.id,
      'user_id': b.userId,
      'started_at': _dateOnly(b.startedAt),
      'ended_at': b.endedAt == null ? null : _dateOnly(b.endedAt!),
      'created_at': _timestamp(b.createdAt),
      'updated_at': _timestamp(b.updatedAt),
      'deleted_at': b.deletedAt == null ? null : _timestamp(b.deletedAt!),
    };

PeriodsCompanion periodFromJson(Map<String, dynamic> j) =>
    PeriodsCompanion.insert(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      startedAt: _parseDate(j['started_at'] as String),
      endedAt: Value(_parseNullableDate(j['ended_at'])),
      createdAt: _parseDate(j['created_at'] as String),
      updatedAt: _parseDate(j['updated_at'] as String),
      deletedAt: Value(_parseNullableDate(j['deleted_at'])),
      pendingSync: const Value(false),
    );

// ---------- budgets ----------

Map<String, dynamic> budgetToJson(Budget b) => {
      'id': b.id,
      'period_id': b.periodId,
      'category_id': b.categoryId,
      'limit_amount': b.limitAmount,
      'created_at': _timestamp(b.createdAt),
      'updated_at': _timestamp(b.updatedAt),
      'deleted_at': b.deletedAt == null ? null : _timestamp(b.deletedAt!),
    };

BudgetsCompanion budgetFromJson(Map<String, dynamic> j) => BudgetsCompanion.insert(
      id: j['id'] as String,
      periodId: j['period_id'] as String,
      categoryId: j['category_id'] as String,
      limitAmount: (j['limit_amount'] as num).toDouble(),
      createdAt: _parseDate(j['created_at'] as String),
      updatedAt: _parseDate(j['updated_at'] as String),
      deletedAt: Value(_parseNullableDate(j['deleted_at'])),
      pendingSync: const Value(false),
    );
