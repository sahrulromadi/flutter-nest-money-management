import 'package:drift/drift.dart';

class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get direction => text()
      .customConstraint("CHECK (direction IN ('Utang', 'Piutang'))")();
  TextColumn get counterparty => text()();
  RealColumn get amount => real()();
  DateTimeColumn get dueDate => dateTime().named('due_date').nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  BoolColumn get pendingSync =>
      boolean().named('pending_sync').withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
