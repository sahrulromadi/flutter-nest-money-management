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
    query.orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
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

  /// Total nominal transaksi (belum kehapus) yang di-tag ke utang/piutang ini
  /// — reaktif. Progress pelunasan (plan 036 item 5).
  Stream<double> watchDebtTotal(String debtId) {
    final q = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.debtId.equals(debtId) &
          transactions.deletedAt.isNull());
    return q.watchSingle().map((r) => r.read(transactions.amount.sum()) ?? 0);
  }

  // ---------- laporan / budget (plan 029 Item 3, ganti /reports/*) ----------

  /// SUM Expense untuk 1 kategori dalam rentang tanggal — reaktif. Progress budget.
  Stream<double> watchExpenseForCategory(
    String categoryId,
    DateTime from,
    DateTime to,
  ) {
    final q = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.type.equals('Expense') &
          transactions.categoryId.equals(categoryId) &
          transactions.deletedAt.isNull() &
          transactions.occurredAt.isBetweenValues(from, to));
    return q.watchSingle().map((r) => r.read(transactions.amount.sum()) ?? 0);
  }

  /// Total income vs expense dalam rentang — reaktif.
  Stream<({double income, double expense})> watchSummary(
    String userId,
    DateTime from,
    DateTime to,
  ) {
    final q = select(transactions)
      ..where((t) =>
          t.userId.equals(userId) &
          t.deletedAt.isNull() &
          t.occurredAt.isBetweenValues(from, to));
    return q.watch().map((rows) {
      var income = 0.0, expense = 0.0;
      for (final t in rows) {
        if (t.type == 'Income') income += t.amount;
        if (t.type == 'Expense') expense += t.amount;
      }
      return (income: income, expense: expense);
    });
  }

  /// Breakdown per kategori buat 1 [type] (Income/Expense) dalam rentang —
  /// reaktif. `categoryId` null = transaksi tanpa kategori (penyesuaian
  /// saldo, biaya transfer) dikumpulin jadi 1 bucket "tanpa kategori".
  Stream<List<({String? categoryId, double total})>> watchCategoryBreakdown(
    String userId,
    String type,
    DateTime from,
    DateTime to,
  ) {
    final q = select(transactions)
      ..where((t) =>
          t.userId.equals(userId) &
          t.deletedAt.isNull() &
          t.type.equals(type) &
          t.occurredAt.isBetweenValues(from, to));
    return q.watch().map((rows) {
      final byCat = <String?, double>{};
      for (final t in rows) {
        byCat.update(t.categoryId, (v) => v + t.amount,
            ifAbsent: () => t.amount);
      }
      return byCat.entries
          .map((e) => (categoryId: e.key, total: e.value))
          .toList()
        ..sort((a, b) => b.total.compareTo(a.total));
    });
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

  /// Tipe (Income/Expense) yang masih punya transaksi tanpa kategori buat
  /// [userId] — dipake backfill kategori sistem (plan 036 item 2).
  Future<List<String>> findUncategorizedTypes(String userId) async {
    final rows = await (selectOnly(transactions, distinct: true)
          ..addColumns([transactions.type])
          ..where(transactions.userId.equals(userId) &
              transactions.categoryId.isNull() &
              transactions.type.isIn(const ['Income', 'Expense'])))
        .get();
    return rows.map((r) => r.read(transactions.type)!).toList();
  }

  /// Retag semua transaksi [type] milik [userId] yang category_id-nya NULL
  /// ke [categoryId] (kategori sistem) — backfill data lama (plan 036 item 2).
  Future<void> retagUncategorized(
    String userId,
    String type,
    String categoryId,
    DateTime now,
  ) =>
      (update(transactions)
            ..where((t) =>
                t.userId.equals(userId) &
                t.categoryId.isNull() &
                t.type.equals(type)))
          .write(TransactionsCompanion(
        categoryId: Value(categoryId),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ));

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
