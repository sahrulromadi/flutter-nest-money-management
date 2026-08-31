import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/categories_dao.dart';

class CategoryValidationException implements Exception {
  CategoryValidationException(this.message);
  final String message;
}

class CategoriesRepository {
  CategoriesRepository(this._dao);

  final CategoriesDao _dao;

  Stream<List<Category>> watchAll(String userId, {String? type}) =>
      _dao.watchAll(userId, type: type);

  Future<Category?> findById(String id) => _dao.findById(id);

  Future<void> create({
    required String userId,
    required String name,
    required String type,
    String? parentId,
    String? icon,
    String? color,
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
        icon: Value(icon),
        color: Value(color),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) {
    final now = DateTime.now().toUtc();
    return _dao.updateFields(
      id,
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ),
    );
  }

  Future<void> delete(String id) =>
      _dao.softDelete(id, DateTime.now().toUtc());
}
