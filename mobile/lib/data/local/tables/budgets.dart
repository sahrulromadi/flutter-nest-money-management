import 'package:drift/drift.dart';

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get budgetPeriodId => text().named('budget_period_id')();
  TextColumn get categoryId => text().named('category_id')();
  RealColumn get limitAmount => real().named('limit_amount')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  BoolColumn get pendingSync =>
      boolean().named('pending_sync').withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
