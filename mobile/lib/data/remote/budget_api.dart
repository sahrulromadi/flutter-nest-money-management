import 'package:dio/dio.dart';

class BudgetPeriodDto {
  const BudgetPeriodDto({
    required this.id,
    required this.startedAt,
    required this.endedAt,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;

  factory BudgetPeriodDto.fromJson(Map<String, dynamic> j) => BudgetPeriodDto(
        id: j['id'] as String,
        startedAt: DateTime.parse(j['started_at'] as String),
        endedAt: j['ended_at'] == null ? null : DateTime.parse(j['ended_at'] as String),
      );
}

class BudgetDto {
  const BudgetDto({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.spent,
    required this.percentage,
  });

  final String id;
  final String categoryId;
  final double limitAmount;
  final double spent;
  final int percentage;

  factory BudgetDto.fromJson(Map<String, dynamic> j) => BudgetDto(
        id: j['id'] as String,
        categoryId: j['category_id'] as String,
        limitAmount: (j['limit_amount'] as num).toDouble(),
        spent: (j['spent'] as num).toDouble(),
        percentage: j['percentage'] as int,
      );
}

/// Wrap `/budget-periods` & `/budgets` (backend plan 007). Beda dari fitur
/// Rilis 1 — langsung ke backend, bukan local-first (lihat plan 021 Context).
class BudgetApi {
  BudgetApi(this._dio);

  final Dio _dio;

  Future<BudgetPeriodDto?> getActivePeriod() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/budget-periods/active');
      return BudgetPeriodDto.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<BudgetPeriodDto>> getAllPeriods() async {
    final res = await _dio.get<List<dynamic>>('/budget-periods');
    return res.data!.map((e) => BudgetPeriodDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BudgetPeriodDto> startNewPeriod(DateTime startedAt) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/budget-periods',
      data: {'startedAt': startedAt.toIso8601String().substring(0, 10)},
    );
    return BudgetPeriodDto.fromJson(res.data!);
  }

  Future<List<BudgetDto>> getBudgets({String? periodId}) async {
    final res = await _dio.get<List<dynamic>>(
      '/budgets',
      queryParameters: periodId == null ? null : {'periodId': periodId},
    );
    return res.data!.map((e) => BudgetDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createBudget({
    required String categoryId,
    required double limitAmount,
    String? periodId,
  }) {
    return _dio.post(
      '/budgets',
      queryParameters: periodId == null ? null : {'periodId': periodId},
      data: {'categoryId': categoryId, 'limitAmount': limitAmount},
    );
  }
}
