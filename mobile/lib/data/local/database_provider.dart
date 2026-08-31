import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Satu instance `AppDatabase` buat seluruh app (koneksi Drift lazy-open).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
