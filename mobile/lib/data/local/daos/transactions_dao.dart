import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Stream<List<Transaction>> watchAll(
    String userId, {
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) {
    final query = select(transactions)
      ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull());
    if (accountId != null) {
      query.where(
        (t) => t.accountId.equals(accountId) | t.transferToAccountId.equals(accountId),
      );
    }
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    if (from != null) {
      query.where((t) => t.occurredAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.occurredAt.isSmallerOrEqualValue(to));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    return query.watch();
  }

  Stream<List<Transaction>> watchRecent(String userId, {int limit = 5}) {
    return (select(transactions)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
          ..limit(limit))
        .watch();
  }

  Future<Transaction?> findById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Jumlah transaksi (belum kehapus) yang refer ke akun ini — akun asal
  /// maupun tujuan transfer. Buat warning sebelum hapus akun.
  Future<int> countForAccount(String accountId) async {
    final q = selectOnly(transactions)
      ..addColumns([transactions.id.count()])
      ..where((transactions.accountId.equals(accountId) |
              transactions.transferToAccountId.equals(accountId)) &
          transactions.deletedAt.isNull());
    final row = await q.getSingle();
    return row.read(transactions.id.count()) ?? 0;
  }

  /// Ada transaksi dari rule ini di tanggal ini? — termasuk yang udah dihapus
  /// (user hapus instance recurring = sengaja, jangan di-generate ulang).
  Future<bool> existsForRule(String ruleId, DateTime occurredAt) async {
    final row = await (selectOnly(transactions)
          ..addColumns([transactions.id.count()])
          ..where(transactions.recurringRuleId.equals(ruleId) &
              transactions.occurredAt.equals(occurredAt)))
        .getSingle();
    return (row.read(transactions.id.count()) ?? 0) > 0;
  }

  /// Total nominal transaksi (belum kehapus) yang di-tag ke goal ini — reaktif.
  /// Dipakai buat progress goal (plan 029, ganti perhitungan backend).
  Stream<double> watchGoalTotal(String goalId) {
    final q = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.goalId.equals(goalId) &
          transactions.deletedAt.isNull());
    return q.watchSingle().map((r) => r.read(transactions.amount.sum()) ?? 0);
  }

  /// Jumlah transaksi (belum kehapus) yang pakai kategori ini.
  Future<int> countForCategory(String categoryId) async {
    final q = selectOnly(transactions)
      ..addColumns([transactions.id.count()])
      ..where(transactions.categoryId.equals(categoryId) &
          transactions.deletedAt.isNull());
    final row = await q.getSingle();
    return row.read(transactions.id.count()) ?? 0;
  }

  Future<void> upsert(TransactionsCompanion row) =>
      into(transactions).insertOnConflictUpdate(row);

  Future<void> updateFields(String id, TransactionsCompanion row) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(row);

  Future<void> softDelete(String id, DateTime now) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

  Future<List<Transaction>> findPendingSync() =>
      (select(transactions)..where((t) => t.pendingSync.equals(true))).get();

  Future<void> clearPendingSync(String id) =>
      (update(transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(pendingSync: Value(false)));

  /// Saldo on-the-fly, reaktif (mirror logic backend plan 003):
  /// initial_balance akun + akumulasi transaksi terkait, arah sesuai type.
  /// Watch tabel `transactions` — otomatis update pas ada transaksi baru.
  Stream<double> watchAccountBalance(String accountId, double initialBalance) {
    final query = select(transactions)
      ..where((t) =>
          (t.accountId.equals(accountId) |
              t.transferToAccountId.equals(accountId)) &
          t.deletedAt.isNull());

    return query.watch().map((rows) {
      var balance = initialBalance;
      for (final row in rows) {
        if (row.accountId == accountId) {
          if (row.type == 'Income') {
            balance += row.amount;
          } else if (row.type == 'Expense' || row.type == 'Transfer') {
            balance -= row.amount;
          }
        } else if (row.transferToAccountId == accountId &&
            row.type == 'Transfer') {
          balance += row.amount;
        }
      }
      return balance;
    });
  }

  /// Net delta (income - expense, transfer internal net ke 0) buat
  /// sekumpulan akun sekaligus — dipake hitung total saldo gabungan
  /// (Home dashboard, plan 019).
  Stream<double> watchNetDeltaForAccounts(List<String> accountIds) {
    if (accountIds.isEmpty) return Stream.value(0);

    final query = select(transactions)
      ..where((t) =>
          (t.accountId.isIn(accountIds) | t.transferToAccountId.isIn(accountIds)) &
          t.deletedAt.isNull());

    return query.watch().map((rows) {
      var delta = 0.0;
      for (final row in rows) {
        if (accountIds.contains(row.accountId)) {
          if (row.type == 'Income') {
            delta += row.amount;
          } else if (row.type == 'Expense' || row.type == 'Transfer') {
            delta -= row.amount;
          }
        }
        if (row.transferToAccountId != null &&
            accountIds.contains(row.transferToAccountId) &&
            row.type == 'Transfer') {
          delta += row.amount;
        }
      }
      return delta;
    });
  }
}
