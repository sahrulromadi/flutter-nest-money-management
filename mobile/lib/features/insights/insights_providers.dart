import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_client_provider.dart';
import '../../data/remote/budget_api.dart';
import '../../data/remote/reports_api.dart';

final budgetApiProvider = Provider<BudgetApi>((ref) {
  return BudgetApi(ref.watch(apiClientProvider).dio);
});

final reportsApiProvider = Provider<ReportsApi>((ref) {
  return ReportsApi(ref.watch(apiClientProvider).dio);
});

final activeBudgetPeriodProvider =
    FutureProvider.autoDispose<BudgetPeriodDto?>((ref) {
  return ref.watch(budgetApiProvider).getActivePeriod();
});

final budgetsProvider =
    FutureProvider.autoDispose.family<List<BudgetDto>, String?>((ref, periodId) {
  return ref.watch(budgetApiProvider).getBudgets(periodId: periodId);
});

final reportsSummaryProvider = FutureProvider.autoDispose<ReportsSummary>((ref) {
  return ref.watch(reportsApiProvider).summary();
});

final categoryBreakdownProvider =
    FutureProvider.autoDispose<List<CategoryBreakdownItem>>((ref) {
  return ref.watch(reportsApiProvider).categoryBreakdown(type: 'Expense');
});

final cashflowTrendProvider = FutureProvider.autoDispose<List<CashflowPoint>>((ref) {
  return ref.watch(reportsApiProvider).cashflowTrend();
});
