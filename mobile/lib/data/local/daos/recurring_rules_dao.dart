import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/recurring_rules.dart';

part 'recurring_rules_dao.g.dart';

@DriftAccessor(tables: [RecurringRules])
class RecurringRulesDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRulesDaoMixin {
  RecurringRulesDao(super.db);

  Stream<List<RecurringRule>> watchAll(String userId) {
    return (select(recurringRules)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.nextRunDate)]))
        .watch();
  }

  Future<void> upsert(RecurringRulesCompanion row) =>
      into(recurringRules).insertOnConflictUpdate(row);

  /// Rule yang jatuh tempo (buat generator, plan 029 — ganti cron backend).
  Future<List<RecurringRule>> findDue(String userId, DateTime today) {
    return (select(recurringRules)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.nextRunDate.isSmallerOrEqualValue(today) &
              (t.endDate.isNull() |
                  t.endDate.isBiggerOrEqual(t.nextRunDate))))
        .get();
  }

  /// Rule yang jatuh tempo dalam [until] (buat reminder notif, plan 029 Item 4).
  Future<List<RecurringRule>> findUpcoming(String userId, DateTime until) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return (select(recurringRules)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.nextRunDate.isSmallerOrEqualValue(until) &
              (t.endDate.isNull() |
                  t.endDate.isBiggerOrEqualValue(todayOnly)))
          ..orderBy([(t) => OrderingTerm.asc(t.nextRunDate)]))
        .get();
  }

  Future<void> advanceNextRun(String id, DateTime next, DateTime now) =>
      (update(recurringRules)..where((t) => t.id.equals(id))).write(
        RecurringRulesCompanion(
          nextRunDate: Value(next),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

  Future<void> softDelete(String id, DateTime now) =>
      (update(recurringRules)..where((t) => t.id.equals(id))).write(
        RecurringRulesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

  Future<List<RecurringRule>> findPendingSync() => (select(recurringRules)
        ..where((t) => t.pendingSync.equals(true)))
      .get();

  Future<void> clearPendingSync(String id) =>
      (update(recurringRules)..where((t) => t.id.equals(id)))
          .write(const RecurringRulesCompanion(pendingSync: Value(false)));
}
