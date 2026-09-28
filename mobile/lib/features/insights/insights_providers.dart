import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/repository/budget_repository.dart';
import '../auth/current_user_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BudgetRepository(db.periodsDao, db.budgetsDao, db.transactionsDao);
});

final activePeriodProvider = StreamProvider.autoDispose<Period?>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield null;
    return;
  }
  yield* ref.watch(budgetRepositoryProvider).watchActivePeriod(userId);
});

final allPeriodsProvider =
    StreamProvider.autoDispose<List<Period>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(budgetRepositoryProvider).watchAllPeriods(userId);
});

/// id periode yang lagi dilihat di Insights. null = periode aktif.
final selectedPeriodIdProvider = StateProvider.autoDispose<String?>((_) => null);

/// Periode yang lagi dilihat (resolve dari selection; fallback ke aktif).
final viewedPeriodProvider = Provider.autoDispose<Period?>((ref) {
  final selectedId = ref.watch(selectedPeriodIdProvider);
  final all = ref.watch(allPeriodsProvider).valueOrNull ?? const <Period>[];
  if (selectedId != null) {
    return all.firstWhereOrNull((p) => p.id == selectedId);
  }
  return ref.watch(activePeriodProvider).valueOrNull;
});

/// Periode yang dilihat udah ditutup? (budget jadi read-only)
final viewedPeriodClosedProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(viewedPeriodProvider)?.endedAt != null;
});

typedef ReportRange = ({DateTime from, DateTime to});

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Akhir hari — biar transaksi yang `occurred_at`-nya masih nyimpen jam
/// (mis. dibuat hari ini tanpa ubah tanggal) tetap ke-cover.
DateTime _endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

ReportRange _rangeFor(Period? period) {
  final now = DateTime.now();
  if (period == null) {
    // Belum ada periode → bulan kalender berjalan.
    return (from: DateTime(now.year, now.month, 1), to: _endOfDay(now));
  }
  return (
    from: _dateOnly(period.startedAt),
    to: _endOfDay(period.endedAt ?? now),
  );
}

/// Rentang laporan = periode yang lagi dilihat.
final reportRangeProvider = Provider.autoDispose<ReportRange>((ref) {
  return _rangeFor(ref.watch(viewedPeriodProvider));
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

/// Breakdown per kategori buat 1 type ('Expense' / 'Income') di periode
/// yang lagi dilihat. `categoryId` null = bucket "tanpa kategori".
final categoryBreakdownProvider = StreamProvider.autoDispose
    .family<List<({String? categoryId, double total})>, String>(
        (ref, type) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  final r = ref.watch(reportRangeProvider);
  yield* ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .watchCategoryBreakdown(userId, type, r.from, r.to);
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

typedef PeriodSummary = ({Period period, double income, double expense});

/// Income vs expense buat SEMUA periode — section "Ringkasan per Periode".
/// Watch semua transaksi user sekali, bucket per periode by occurred_at.
final periodSummariesProvider =
    StreamProvider.autoDispose<List<PeriodSummary>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  final periods = ref.watch(allPeriodsProvider).valueOrNull;
  if (userId == null || periods == null || periods.isEmpty) {
    yield const [];
    return;
  }
  final txnDao = ref.watch(appDatabaseProvider).transactionsDao;

  yield* txnDao.watchAll(userId).map((txns) {
    return [
      for (final p in periods)
        () {
          final r = _rangeFor(p);
          var income = 0.0, expense = 0.0;
          for (final t in txns) {
            final d = _dateOnly(t.occurredAt);
            if (d.isBefore(r.from) || d.isAfter(r.to)) continue;
            if (t.type == 'Income') income += t.amount;
            if (t.type == 'Expense') expense += t.amount;
          }
          return (period: p, income: income, expense: expense);
        }(),
    ];
  });
});

typedef BudgetProgress = ({Budget budget, double spent, int pct});

/// Budget mentah periode yang dilihat (stream tunggal).
final _viewedBudgetsProvider =
    StreamProvider.autoDispose<List<Budget>>((ref) {
  final period = ref.watch(viewedPeriodProvider);
  if (period == null) return Stream.value(const <Budget>[]);
  return ref.watch(appDatabaseProvider).budgetsDao.watchByPeriod(period.id);
});

/// Budget + realisasi + persen. Dipakai Insights & banner Home.
/// Gabung 2 stream lewat provider (bukan nested stream — biar dua-duanya
/// reaktif).
final budgetsWithProgressProvider =
    Provider.autoDispose<AsyncValue<List<BudgetProgress>>>((ref) {
  final budgetsAsync = ref.watch(_viewedBudgetsProvider);
  final spentByCat = {
    for (final e in ref.watch(categoryBreakdownProvider('Expense')).valueOrNull ??
        const <({String? categoryId, double total})>[])
      if (e.categoryId != null) e.categoryId!: e.total,
  };
  return budgetsAsync.whenData((budgets) => [
        for (final b in budgets)
          (
            budget: b,
            spent: spentByCat[b.categoryId] ?? 0.0,
            pct: b.limitAmount > 0
                ? ((spentByCat[b.categoryId] ?? 0) / b.limitAmount * 100).round()
                : 0,
          ),
      ]);
});
