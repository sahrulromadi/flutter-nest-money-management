import 'package:drift/drift.dart';

class RecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get accountId => text().named('account_id')();
  TextColumn get categoryId => text().named('category_id')();
  TextColumn get type =>
      text().customConstraint("CHECK (type IN ('Income', 'Expense'))")();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  TextColumn get intervalUnit => text().named('interval_unit').customConstraint(
      "CHECK (interval_unit IN ('Day', 'Week', 'Month', 'DaysOfWeek'))")();
  IntColumn get intervalValue => integer().named('interval_value')();
  // CSV hari (1=Senin..7=Minggu) kalau interval_unit = 'DaysOfWeek'.
  TextColumn get daysOfWeek => text().named('days_of_week').nullable()();
  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get nextRunDate => dateTime().named('next_run_date')();
  DateTimeColumn get endDate => dateTime().named('end_date').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  BoolColumn get pendingSync =>
      boolean().named('pending_sync').withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
