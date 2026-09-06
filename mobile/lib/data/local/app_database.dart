import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'daos/accounts_dao.dart';
import 'daos/budget_periods_dao.dart';
import 'daos/budgets_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/goals_dao.dart';
import 'daos/recurring_rules_dao.dart';
import 'daos/transactions_dao.dart';
import 'tables/accounts.dart';
import 'tables/budget_periods.dart';
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
    BudgetPeriods,
    Budgets,
  ],
  daos: [
    AccountsDao,
    CategoriesDao,
    GoalsDao,
    RecurringRulesDao,
    TransactionsDao,
    BudgetPeriodsDao,
    BudgetsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Item 1: buang accounts.type. Item 6: buang categories.icon+color.
            // Item 4: tambah categories.sort_order (default 0).
            await m.alterTable(TableMigration(accounts));
            await m.alterTable(
              TableMigration(categories, newColumns: [categories.sortOrder]),
            );
          }
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

  /// Pindahin semua baris lokal punya [from] jadi punya [to] — dipanggil
  /// sekali pas login pertama kali, biar data yang udah dicatat sblm login
  /// (di bawah [LocalIdentity]) ke-link ke akun server & ikut ke-sync.
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
      await (update(budgetPeriods)..where((t) => t.userId.equals(from)))
          .write(BudgetPeriodsCompanion(userId: owner, pendingSync: dirty));
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
