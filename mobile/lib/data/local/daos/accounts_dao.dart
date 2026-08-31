import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/accounts.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Stream<List<Account>> watchAll(String userId) {
    return (select(accounts)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<Account?> findById(String id) =>
      (select(accounts)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Full-row upsert — dipake buat create lokal (semua kolom wajib keisi)
  /// & sync engine (plan 020, pull row lengkap dari backend).
  Future<void> upsert(AccountsCompanion row) =>
      into(accounts).insertOnConflictUpdate(row);

  /// Partial update (cuma kolom yang di-set di [row] yang berubah) —
  /// dipake buat edit lokal biar gak perlu isi ulang semua kolom.
  Future<void> updateFields(String id, AccountsCompanion row) =>
      (update(accounts)..where((t) => t.id.equals(id))).write(row);

  Future<void> softDelete(String id, DateTime now) =>
      (update(accounts)..where((t) => t.id.equals(id))).write(
        AccountsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

  /// Row yang belum ke-sync ke backend (dipake sync engine, plan 020).
  Future<List<Account>> findPendingSync() =>
      (select(accounts)..where((t) => t.pendingSync.equals(true))).get();

  /// Abis berhasil di-push, matiin flag dirty-nya (gak nyentuh updated_at).
  Future<void> clearPendingSync(String id) =>
      (update(accounts)..where((t) => t.id.equals(id)))
          .write(const AccountsCompanion(pendingSync: Value(false)));
}
