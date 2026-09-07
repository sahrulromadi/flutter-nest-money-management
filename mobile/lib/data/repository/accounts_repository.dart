import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/accounts_dao.dart';
import '../local/daos/transactions_dao.dart';

class AccountsRepository {
  AccountsRepository(this._accountsDao, this._transactionsDao);

  final AccountsDao _accountsDao;
  final TransactionsDao _transactionsDao;

  Stream<List<Account>> watchAll(String userId) => _accountsDao.watchAll(userId);

  Stream<double> watchBalance(Account account) =>
      _transactionsDao.watchAccountBalance(account.id, account.initialBalance);

  /// Total saldo gabungan semua akun user (Home dashboard, plan 019).
  Stream<double> watchTotalBalance(String userId) async* {
    await for (final accounts in _accountsDao.watchAll(userId)) {
      final initialSum =
          accounts.fold<double>(0, (sum, a) => sum + a.initialBalance);
      final ids = accounts.map((a) => a.id).toList();
      if (ids.isEmpty) {
        yield initialSum;
        continue;
      }
      yield* _transactionsDao
          .watchNetDeltaForAccounts(ids)
          .map((delta) => initialSum + delta);
    }
  }

  Future<Account?> findById(String id) => _accountsDao.findById(id);

  Future<void> create({
    required String userId,
    required String name,
    required double initialBalance,
  }) {
    final now = DateTime.now().toUtc();
    return _accountsDao.upsert(
      AccountsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        initialBalance: initialBalance,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update({
    required String id,
    String? name,
  }) {
    final now = DateTime.now().toUtc();
    return _accountsDao.updateFields(
      id,
      AccountsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ),
    );
  }

  /// Urutan baru buat daftar id akun.
  Future<void> reorder(List<String> orderedIds) =>
      _accountsDao.reorder(orderedIds, DateTime.now().toUtc());

  Stream<List<Account>> watchAllIncludingDeleted(String userId) =>
      _accountsDao.watchAllIncludingDeleted(userId);

  Future<int> transactionCount(String accountId) =>
      _transactionsDao.countForAccount(accountId);

  Future<void> delete(String id) =>
      _accountsDao.softDelete(id, DateTime.now().toUtc());
}
