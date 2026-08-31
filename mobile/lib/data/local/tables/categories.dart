import 'package:drift/drift.dart';

// Drift default singularize cuma strip 's' trailing ("Categories" ->
// "Categorie") — override eksplisit biar data class-nya jadi `Category`.
@DataClassName('Category')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  TextColumn get type =>
      text().customConstraint("CHECK (type IN ('Income', 'Expense'))")();
  TextColumn get parentId => text().named('parent_id').nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  BoolColumn get pendingSync =>
      boolean().named('pending_sync').withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
