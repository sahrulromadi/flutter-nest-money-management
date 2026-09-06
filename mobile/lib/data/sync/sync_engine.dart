import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../local/app_database.dart';
import '../remote/sync_api.dart';
import 'sync_serializers.dart';

const _lastSyncedAtKey = 'last_synced_at';
const _secureStorage = FlutterSecureStorage();

/// Sync manual doang — dipanggil pas user tekan tombol Sync (More screen),
/// gak ada auto-trigger connectivity/periodic (keputusan eksplisit user).
class SyncEngine {
  SyncEngine(this._api, this._db);

  final SyncApi _api;
  final AppDatabase _db;

  Future<void> push() async {
    final changes = <String, List<Map<String, dynamic>>>{};

    final accounts = await _db.accountsDao.findPendingSync();
    if (accounts.isNotEmpty) changes['accounts'] = accounts.map(accountToJson).toList();

    final categories = await _db.categoriesDao.findPendingSync();
    if (categories.isNotEmpty) {
      changes['categories'] = categories.map(categoryToJson).toList();
    }

    final goals = await _db.goalsDao.findPendingSync();
    if (goals.isNotEmpty) changes['goals'] = goals.map(goalToJson).toList();

    final rules = await _db.recurringRulesDao.findPendingSync();
    if (rules.isNotEmpty) {
      changes['recurring_rules'] = rules.map(recurringRuleToJson).toList();
    }

    final transactions = await _db.transactionsDao.findPendingSync();
    if (transactions.isNotEmpty) {
      changes['transactions'] = transactions.map(transactionToJson).toList();
    }

    final periods = await _db.budgetPeriodsDao.findPendingSync();
    if (periods.isNotEmpty) {
      changes['budget_periods'] = periods.map(budgetPeriodToJson).toList();
    }

    final budgets = await _db.budgetsDao.findPendingSync();
    if (budgets.isNotEmpty) changes['budgets'] = budgets.map(budgetToJson).toList();

    if (changes.isEmpty) return;
    await _api.push(changes);

    for (final a in accounts) {
      await _db.accountsDao.clearPendingSync(a.id);
    }
    for (final c in categories) {
      await _db.categoriesDao.clearPendingSync(c.id);
    }
    for (final g in goals) {
      await _db.goalsDao.clearPendingSync(g.id);
    }
    for (final r in rules) {
      await _db.recurringRulesDao.clearPendingSync(r.id);
    }
    for (final t in transactions) {
      await _db.transactionsDao.clearPendingSync(t.id);
    }
    for (final p in periods) {
      await _db.budgetPeriodsDao.clearPendingSync(p.id);
    }
    for (final b in budgets) {
      await _db.budgetsDao.clearPendingSync(b.id);
    }
  }

  Future<void> pull() async {
    final since = await _readLastSyncedAt();
    final result = await _api.pull(since);

    for (final row in result['accounts'] ?? const []) {
      await _db.accountsDao.upsert(accountFromJson(row));
    }
    for (final row in result['categories'] ?? const []) {
      await _db.categoriesDao.upsert(categoryFromJson(row));
    }
    for (final row in result['goals'] ?? const []) {
      await _db.goalsDao.upsert(goalFromJson(row));
    }
    for (final row in result['recurring_rules'] ?? const []) {
      await _db.recurringRulesDao.upsert(recurringRuleFromJson(row));
    }
    for (final row in result['transactions'] ?? const []) {
      await _db.transactionsDao.upsert(transactionFromJson(row));
    }
    for (final row in result['budget_periods'] ?? const []) {
      await _db.budgetPeriodsDao.upsert(budgetPeriodFromJson(row));
    }
    for (final row in result['budgets'] ?? const []) {
      await _db.budgetsDao.upsert(budgetFromJson(row));
    }

    await _saveLastSyncedAt(DateTime.now());
  }

  /// Push dulu baru pull — perubahan lokal harus kekirim sebelum narik
  /// perubahan lain (TECH_STACK.md #6).
  Future<void> syncAll() async {
    await push();
    await pull();
  }

  Future<DateTime?> _readLastSyncedAt() async {
    final raw = await _secureStorage.read(key: _lastSyncedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> _saveLastSyncedAt(DateTime time) =>
      _secureStorage.write(key: _lastSyncedAtKey, value: time.toUtc().toIso8601String());

  Future<DateTime?> lastSyncedAt() => _readLastSyncedAt();
}
