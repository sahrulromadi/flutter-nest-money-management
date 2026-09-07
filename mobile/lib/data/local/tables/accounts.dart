import 'package:drift/drift.dart';

/// Mirror `SCHEMA.md` accounts. `pendingSync` kolom lokal doang (gak ada di
/// backend) — dipake sync engine (plan 020) buat tau row mana yang perlu di-push.
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  RealColumn get initialBalance => real().named('initial_balance')();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  BoolColumn get pendingSync =>
      boolean().named('pending_sync').withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
