import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/repository/categories_repository.dart';
import '../auth/current_user_provider.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoriesRepository(db.categoriesDao);
});

final categoriesListProvider =
    StreamProvider.autoDispose.family<List<Category>, String?>((ref, type) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  final repo = ref.watch(categoriesRepositoryProvider);
  yield* repo.watchAll(userId, type: type);
});

/// Map id -> Category (semua tipe), buat lookup cepat di row transaksi
/// (nampilin icon+warna kategori). Reuse `categoriesListProvider(null)`,
/// re-compute tiap list berubah. Kosong selama list masih loading.
final categoriesByIdProvider =
    Provider.autoDispose<Map<String, Category>>((ref) {
  final list = ref.watch(categoriesListProvider(null)).valueOrNull ??
      const <Category>[];
  return {for (final c in list) c.id: c};
});
