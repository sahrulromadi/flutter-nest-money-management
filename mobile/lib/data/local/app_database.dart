import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'daos/accounts_dao.dart';
import 'daos/periods_dao.dart';
import 'daos/budgets_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/goals_dao.dart';
import 'daos/recurring_rules_dao.dart';
import 'daos/transactions_dao.dart';
import 'tables/accounts.dart';
import 'tables/periods.dart';
import 'tables/budgets.dart';
import 'tables/categories.dart';
import 'tables/goals.dart';
import 'tables/recurring_rules.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

const _dbEncryptionKeyStorageKey = 'db_encryption_key';
const _secureStorage = FlutterSecureStorage();

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Goals,
    RecurringRules,
    Transactions,
    Periods,
    Budgets,
  ],
  daos: [
    AccountsDao,
    CategoriesDao,
    GoalsDao,
    RecurringRulesDao,
    TransactionsDao,
    PeriodsDao,
    BudgetsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // APK masih fase development. Naikin `schemaVersion` tiap ubah struktur tabel
  // → `onUpgrade` DROP semua + createAll (data lokal ke-reset, ga perlu
  // uninstall manual). Migrasi stepwise beneran ditambah pas rilis.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          for (final t in [
            'budgets',
            'periods',
            'budget_periods',
            'transactions',
            'recurring_rules',
            'goals',
            'categories',
            'accounts',
          ]) {
            await m.database.customStatement('DROP TABLE IF EXISTS $t');
          }
          await m.createAll();
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'money_management.sqlite'));
      final key = await _getOrCreateEncryptionKey();

      return NativeDatabase.createInBackground(
        dbFile,
        setup: (rawDb) {
          // Kolom key harus di-set sebelum query lain jalan — sesuai
          // dokumentasi SQLCipher. `hooks.user_defines` di pubspec.yaml
          // udah pilih native build SQLCipher (bukan sqlite3_flutter_libs
          // yang EOL), jadi PRAGMA ini beneran ngenkripsi filenya.
          rawDb.execute("PRAGMA key = '$key';");
        },
      );
    });
  }

  /// Ada data lokal buat [userId]? (plan 031 — warning pas login.)
  Future<bool> hasLocalData(String userId) async {
    final rows = await Future.wait([
      (select(accounts)..where((t) => t.userId.equals(userId))).get(),
      (select(transactions)..where((t) => t.userId.equals(userId))).get(),
      (select(categories)..where((t) => t.userId.equals(userId))).get(),
      (select(goals)..where((t) => t.userId.equals(userId))).get(),
      (select(recurringRules)..where((t) => t.userId.equals(userId))).get(),
      (select(periods)..where((t) => t.userId.equals(userId))).get(),
    ]);
    return rows.any((r) => r.isNotEmpty);
  }

  /// Hapus SEMUA data lokal (semua tabel). Encryption key ga disentuh.
  /// plan 031 — pas login "Ganti (pakai data akun)".
  Future<void> wipeAll() async {
    await transaction(() async {
      await delete(budgets).go();
      await delete(periods).go();
      await delete(transactions).go();
      await delete(recurringRules).go();
      await delete(goals).go();
      await delete(categories).go();
      await delete(accounts).go();
    });
  }

  /// Re-tag semua row lokal dari [from] ke [to] + tandai dirty — dipanggil pas
  /// login "Gabung (data lokal ke akun)". Sync berikutnya push data ini ke server.
  /// `budgets` ikut lewat period-nya (ga punya kolom user_id).
  Future<void> reassignUserData(String from, String to) async {
    if (from == to) return;
    final owner = Value(to);
    const dirty = Value(true);
    await transaction(() async {
      await (update(accounts)..where((t) => t.userId.equals(from)))
          .write(AccountsCompanion(userId: owner, pendingSync: dirty));
      await (update(categories)..where((t) => t.userId.equals(from)))
          .write(CategoriesCompanion(userId: owner, pendingSync: dirty));
      await (update(goals)..where((t) => t.userId.equals(from)))
          .write(GoalsCompanion(userId: owner, pendingSync: dirty));
      await (update(recurringRules)..where((t) => t.userId.equals(from)))
          .write(RecurringRulesCompanion(userId: owner, pendingSync: dirty));
      await (update(transactions)..where((t) => t.userId.equals(from)))
          .write(TransactionsCompanion(userId: owner, pendingSync: dirty));
      await (update(periods)..where((t) => t.userId.equals(from)))
          .write(PeriodsCompanion(userId: owner, pendingSync: dirty));
      await (update(budgets)..where((t) => t.deletedAt.isNull()))
          .write(const BudgetsCompanion(pendingSync: dirty));
    });
  }

  static Future<String> _getOrCreateEncryptionKey() async {
    final existing = await _secureStorage.read(key: _dbEncryptionKeyStorageKey);
    if (existing != null) return existing;

    final generated = const Uuid().v4();
    await _secureStorage.write(
      key: _dbEncryptionKeyStorageKey,
      value: generated,
    );
    return generated;
  }
}
