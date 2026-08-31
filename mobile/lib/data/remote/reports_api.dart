import 'package:dio/dio.dart';

class ReportsSummary {
  const ReportsSummary({required this.totalIncome, required this.totalExpense, required this.net});
  final double totalIncome;
  final double totalExpense;
  final double net;

  factory ReportsSummary.fromJson(Map<String, dynamic> j) => ReportsSummary(
        totalIncome: (j['totalIncome'] as num).toDouble(),
        totalExpense: (j['totalExpense'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
      );
}

class CategoryBreakdownItem {
  const CategoryBreakdownItem({required this.categoryId, required this.categoryName, required this.total});
  final String categoryId;
  final String categoryName;
  final double total;

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> j) => CategoryBreakdownItem(
        categoryId: j['category_id'] as String,
        categoryName: j['category_name'] as String,
        total: double.parse(j['total'] as String),
      );
}

class CashflowPoint {
  const CashflowPoint({required this.day, required this.income, required this.expense});
  final DateTime day;
  final double income;
  final double expense;

  factory CashflowPoint.fromJson(Map<String, dynamic> j) => CashflowPoint(
        day: DateTime.parse(j['day'] as String),
        income: double.parse(j['income'] as String),
        expense: double.parse(j['expense'] as String),
      );
}

/// Wrap `/reports/*` (backend plan 008).
class ReportsApi {
  ReportsApi(this._dio);

  final Dio _dio;

  Future<ReportsSummary> summary({DateTime? from, DateTime? to}) async {
    final res = await _dio.get<Map<String, dynamic>>('/reports/summary', queryParameters: _range(from, to));
    return ReportsSummary.fromJson(res.data!);
  }

  Future<List<CategoryBreakdownItem>> categoryBreakdown({DateTime? from, DateTime? to, String? type}) async {
    final params = _range(from, to);
    if (type != null) params['type'] = type;
    final res = await _dio.get<List<dynamic>>('/reports/category-breakdown', queryParameters: params);
    return res.data!.map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CashflowPoint>> cashflowTrend({DateTime? from, DateTime? to}) async {
    final res = await _dio.get<List<dynamic>>('/reports/cashflow-trend', queryParameters: _range(from, to));
    return res.data!.map((e) => CashflowPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _range(DateTime? from, DateTime? to) {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from.toIso8601String().substring(0, 10);
    if (to != null) params['to'] = to.toIso8601String().substring(0, 10);
    return params;
  }
}
