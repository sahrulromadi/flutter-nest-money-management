import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/repository/categories_repository.dart';
import '../auth/current_user_provider.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoriesRepository(db.categoriesDao, db.transactionsDao);
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

/// Kategori termasuk yang udah kehapus — buat lookup nama kategori di row
/// transaksi historis walau kategorinya udah di-delete.
final _allCategoriesProvider =
    StreamProvider.autoDispose<List<Category>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  yield* ref
      .watch(categoriesRepositoryProvider)
      .watchAllIncludingDeleted(userId);
});

final categoriesByIdProvider =
    Provider.autoDispose<Map<String, Category>>((ref) {
  final list =
      ref.watch(_allCategoriesProvider).valueOrNull ?? const <Category>[];
  return {for (final c in list) c.id: c};
});
