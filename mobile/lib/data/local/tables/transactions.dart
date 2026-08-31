import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get accountId => text().named('account_id')();
  TextColumn get categoryId => text().named('category_id').nullable()();
  TextColumn get type => text().customConstraint(
      "CHECK (type IN ('Income', 'Expense', 'Transfer'))")();
  RealColumn get amount => real()();
  TextColumn get transferToAccountId =>
      text().named('transfer_to_account_id').nullable()();
  DateTimeColumn get occurredAt => dateTime().named('occurred_at')();
  TextColumn get note => text().nullable()();
  TextColumn get recurringRuleId =>
      text().named('recurring_rule_id').nullable()();
  TextColumn get goalId => text().named('goal_id').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  BoolColumn get pendingSync =>
      boolean().named('pending_sync').withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
