import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/categories_dao.dart';
import '../local/daos/transactions_dao.dart';

class CategoryValidationException implements Exception {
  CategoryValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CategoriesRepository {
  CategoriesRepository(this._dao, this._txnDao);

  final CategoriesDao _dao;
  final TransactionsDao _txnDao;

  Stream<List<Category>> watchAll(String userId, {String? type}) =>
      _dao.watchAll(userId, type: type);

  Stream<List<Category>> watchAllIncludingDeleted(String userId) =>
      _dao.watchAllIncludingDeleted(userId);

  Future<Category?> findById(String id) => _dao.findById(id);

  Future<int> transactionCount(String categoryId) =>
      _txnDao.countForCategory(categoryId);

  Future<void> create({
    required String userId,
    required String name,
    required String type,
    String? parentId,
  }) async {
    if (parentId != null) {
      final parent = await _dao.findById(parentId);
      if (parent == null) {
        throw CategoryValidationException('Kategori induk tidak ditemukan');
      }
      if (parent.type != type) {
        throw CategoryValidationException(
          'Tipe subkategori harus sama dengan kategori induk',
        );
      }
    }

    final now = DateTime.now().toUtc();
    await _dao.upsert(
      CategoriesCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        type: type,
        parentId: Value(parentId),
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
    return _dao.updateFields(
      id,
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ),
    );
  }

  /// Urutan baru untuk daftar id kategori (level atas dalam 1 grup type).
  Future<void> reorder(List<String> orderedIds) =>
      _dao.reorder(orderedIds, DateTime.now().toUtc());

  /// Soft delete kategori + subkategori-nya (cascade).
  Future<void> delete(String id) =>
      _dao.softDelete(id, DateTime.now().toUtc());

  /// Kategori sistem "Penyesuaian" buat [type] — dibuat sekali per user,
  /// dipake transaksi turunan tanpa kategori asli (penyesuaian saldo, biaya
  /// transfer). Ga muncul di picker manual (plan 036 item 2).
  Future<Category> ensureSystemCategory(String userId, String type) async {
    final existing = await _dao.findSystemCategory(userId, type);
    if (existing != null) return existing;

    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();
    await _dao.upsert(
      CategoriesCompanion.insert(
        id: id,
        userId: userId,
        name: 'Penyesuaian',
        type: type,
        isSystem: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await _dao.findById(id))!;
  }

  /// Retag transaksi lama (sebelum kategori sistem ada) yang `category_id`-
  /// nya NULL ke kategori "Penyesuaian". Idempotent — aman dipanggil tiap
  /// startup (plan 036 item 2).
  Future<void> backfillUncategorizedTransactions(String userId) async {
    final types = await _txnDao.findUncategorizedTypes(userId);
    final now = DateTime.now().toUtc();
    for (final type in types) {
      final sysCat = await ensureSystemCategory(userId, type);
      await _txnDao.retagUncategorized(userId, type, sysCat.id, now);
    }
  }
}
