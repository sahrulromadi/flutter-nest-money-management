import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/categories_dao.dart';
import '../local/daos/transactions_dao.dart';

class CategoryValidationException implements Exception {
  CategoryValidationException(this.message);
  final String message;
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
}
