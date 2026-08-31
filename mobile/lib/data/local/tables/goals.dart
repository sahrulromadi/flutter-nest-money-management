import 'package:drift/drift.dart';

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get accountId => text().named('account_id').nullable()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real().named('target_amount')();
  DateTimeColumn get dueDate => dateTime().named('due_date').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  BoolColumn get pendingSync =>
      boolean().named('pending_sync').withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
