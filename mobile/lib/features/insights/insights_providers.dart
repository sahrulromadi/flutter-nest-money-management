import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/repository/budget_repository.dart';
import '../auth/current_user_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BudgetRepository(db.budgetPeriodsDao, db.budgetsDao, db.transactionsDao);
});

final activeBudgetPeriodProvider =
    StreamProvider.autoDispose<BudgetPeriod?>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield null;
    return;
  }
  yield* ref.watch(budgetRepositoryProvider).watchActivePeriod(userId);
});

typedef ReportRange = ({DateTime from, DateTime to});

/// Rentang laporan = periode budget aktif; kalau belum ada → bulan kalender berjalan.
final reportRangeProvider = Provider.autoDispose<ReportRange>((ref) {
  final now = DateTime.now();
  final to = DateTime(now.year, now.month, now.day);
  final period = ref.watch(activeBudgetPeriodProvider).valueOrNull;
  final from = period != null
      ? DateTime(period.startedAt.year, period.startedAt.month,
          period.startedAt.day)
      : DateTime(now.year, now.month, 1);
  return (from: from, to: to);
});

final insightsSummaryProvider =
    StreamProvider.autoDispose<({double income, double expense})>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield (income: 0, expense: 0);
    return;
  }
  final r = ref.watch(reportRangeProvider);
  yield* ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .watchSummary(userId, r.from, r.to);
});

final categoryBreakdownProvider = StreamProvider.autoDispose<
    List<({String categoryId, double total})>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  final r = ref.watch(reportRangeProvider);
  yield* ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .watchCategoryBreakdown(userId, r.from, r.to);
});

final cashflowTrendProvider = StreamProvider.autoDispose<
    List<({DateTime day, double income, double expense})>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  final r = ref.watch(reportRangeProvider);
  yield* ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .watchCashflowTrend(userId, r.from, r.to);
});

typedef BudgetProgress = ({Budget budget, double spent, int pct});

/// Budget periode aktif + realisasi + persen. Dipakai Insights & banner Home.
final budgetsWithProgressProvider =
    StreamProvider.autoDispose<List<BudgetProgress>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  final period = ref.watch(activeBudgetPeriodProvider).valueOrNull;
  if (userId == null || period == null) {
    yield const [];
    return;
  }
  final r = ref.watch(reportRangeProvider);
  final db = ref.watch(appDatabaseProvider);

  await for (final budgets in db.budgetsDao.watchByPeriod(period.id)) {
    yield* db.transactionsDao
        .watchCategoryBreakdown(userId, r.from, r.to)
        .map((breakdown) {
      final spentByCat = {for (final e in breakdown) e.categoryId: e.total};
      return [
        for (final b in budgets)
          (
            budget: b,
            spent: spentByCat[b.categoryId] ?? 0.0,
            pct: b.limitAmount > 0
                ? ((spentByCat[b.categoryId] ?? 0) / b.limitAmount * 100).round()
                : 0,
          ),
      ];
    });
  }
});
