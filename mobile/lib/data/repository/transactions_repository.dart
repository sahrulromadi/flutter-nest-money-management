import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/accounts_dao.dart';
import '../local/daos/transactions_dao.dart';
import 'categories_repository.dart';

class TransactionValidationException implements Exception {
  TransactionValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// `occurred_at` selalu date-only (jam dibuang) — biar konsisten sama sync
/// (`_dateOnly` di serializer) & query rentang laporan.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class TransactionsRepository {
  TransactionsRepository(this._dao, this._accountsDao, this._categoriesRepo);

  final TransactionsDao _dao;
  final AccountsDao _accountsDao;
  final CategoriesRepository _categoriesRepo;

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
    String? debtId,
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
        occurredAt: _dateOnly(occurredAt),
        note: Value(note),
        goalId: Value(goalId),
        debtId: Value(debtId),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update({
    required String id,
    String? accountId,
    String? transferToAccountId,
    double? amount,
    DateTime? occurredAt,
    String? categoryId,
    String? note,
    String? goalId,
    String? debtId,
  }) {
    final now = DateTime.now().toUtc();
    return _dao.updateFields(
      id,
      TransactionsCompanion(
        accountId:
            accountId != null ? Value(accountId) : const Value.absent(),
        transferToAccountId: transferToAccountId != null
            ? Value(transferToAccountId)
            : const Value.absent(),
        amount: amount != null ? Value(amount) : const Value.absent(),
        occurredAt: occurredAt != null
            ? Value(_dateOnly(occurredAt))
            : const Value.absent(),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        note: note != null ? Value(note) : const Value.absent(),
        goalId: goalId != null ? Value(goalId) : const Value.absent(),
        debtId: debtId != null ? Value(debtId) : const Value.absent(),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ),
    );
  }

  Future<void> delete(String id) => _dao.softDelete(id, DateTime.now().toUtc());

  /// Transaksi turunan (penyesuaian saldo, biaya transfer, dst) — ditag ke
  /// kategori sistem "Penyesuaian" (plan 036 item 2), bukan tanpa kategori.
  /// Skip [_validate] — akun dijamin ada dari caller.
  Future<void> createUncategorized({
    required String userId,
    required String accountId,
    required String type, // 'Income' | 'Expense'
    required double amount,
    required DateTime occurredAt,
    required String note,
  }) async {
    final systemCategory = await _categoriesRepo.ensureSystemCategory(userId, type);
    final now = DateTime.now().toUtc();
    await _dao.upsert(
      TransactionsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        accountId: accountId,
        categoryId: Value(systemCategory.id),
        type: type,
        amount: amount,
        occurredAt: _dateOnly(occurredAt),
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
      final category = await _categoriesRepo.findById(categoryId);
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
