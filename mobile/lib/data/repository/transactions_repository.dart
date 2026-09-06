import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/accounts_dao.dart';
import '../local/daos/categories_dao.dart';
import '../local/daos/transactions_dao.dart';

class TransactionValidationException implements Exception {
  TransactionValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TransactionsRepository {
  TransactionsRepository(this._dao, this._accountsDao, this._categoriesDao);

  final TransactionsDao _dao;
  final AccountsDao _accountsDao;
  final CategoriesDao _categoriesDao;

  Stream<List<Transaction>> watchAll(
    String userId, {
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) =>
      _dao.watchAll(
        userId,
        accountId: accountId,
        categoryId: categoryId,
        from: from,
        to: to,
      );

  Stream<List<Transaction>> watchRecent(String userId, {int limit = 5}) =>
      _dao.watchRecent(userId, limit: limit);

  Future<Transaction?> findById(String id) => _dao.findById(id);

  Future<void> create({
    required String userId,
    required String accountId,
    required String type,
    required double amount,
    required DateTime occurredAt,
    String? categoryId,
    String? transferToAccountId,
    String? note,
    String? goalId,
  }) async {
    await _validate(
      accountId: accountId,
      type: type,
      categoryId: categoryId,
      transferToAccountId: transferToAccountId,
    );

    final now = DateTime.now().toUtc();
    await _dao.upsert(
      TransactionsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        accountId: accountId,
        categoryId: Value(categoryId),
        type: type,
        amount: amount,
        transferToAccountId: Value(transferToAccountId),
        occurredAt: occurredAt,
        note: Value(note),
        goalId: Value(goalId),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update({
    required String id,
    double? amount,
    DateTime? occurredAt,
    String? categoryId,
    String? note,
    String? goalId,
  }) {
    final now = DateTime.now().toUtc();
    return _dao.updateFields(
      id,
      TransactionsCompanion(
        amount: amount != null ? Value(amount) : const Value.absent(),
        occurredAt: occurredAt != null ? Value(occurredAt) : const Value.absent(),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        note: note != null ? Value(note) : const Value.absent(),
        goalId: goalId != null ? Value(goalId) : const Value.absent(),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ),
    );
  }

  Future<void> delete(String id) => _dao.softDelete(id, DateTime.now().toUtc());

  /// Transaksi turunan tanpa kategori (penyesuaian saldo, biaya transfer, dst).
  /// Skip [_validate] — `category_id` sengaja NULL, akun dijamin ada dari caller.
  Future<void> createUncategorized({
    required String userId,
    required String accountId,
    required String type, // 'Income' | 'Expense'
    required double amount,
    required DateTime occurredAt,
    required String note,
  }) async {
    final now = DateTime.now().toUtc();
    await _dao.upsert(
      TransactionsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        accountId: accountId,
        categoryId: const Value(null),
        type: type,
        amount: amount,
        occurredAt: occurredAt,
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _validate({
    required String accountId,
    required String type,
    String? categoryId,
    String? transferToAccountId,
  }) async {
    final account = await _accountsDao.findById(accountId);
    if (account == null) {
      throw TransactionValidationException('Akun tidak ditemukan');
    }

    if (type == 'Transfer') {
      if (transferToAccountId == null) {
        throw TransactionValidationException('Akun tujuan transfer wajib diisi');
      }
      if (transferToAccountId == accountId) {
        throw TransactionValidationException('Gak bisa transfer ke akun sendiri');
      }
      final target = await _accountsDao.findById(transferToAccountId);
      if (target == null) {
        throw TransactionValidationException('Akun tujuan tidak ditemukan');
      }
    } else {
      if (categoryId == null) {
        throw TransactionValidationException('Kategori wajib diisi');
      }
      final category = await _categoriesDao.findById(categoryId);
      if (category == null) {
        throw TransactionValidationException('Kategori tidak ditemukan');
      }
      if (category.type != type) {
        throw TransactionValidationException(
          'Tipe kategori harus sama dengan tipe transaksi',
        );
      }
    }
  }
}
