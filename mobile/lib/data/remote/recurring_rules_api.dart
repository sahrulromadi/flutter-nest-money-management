import 'package:dio/dio.dart';

class RecurringRuleDto {
  const RecurringRuleDto({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.note,
    required this.intervalUnit,
    required this.intervalValue,
    required this.startDate,
    required this.nextRunDate,
    required this.endDate,
  });

  final String id;
  final String accountId;
  final String categoryId;
  final String type;
  final double amount;
  final String? note;
  final String intervalUnit;
  final int intervalValue;
  final DateTime startDate;
  final DateTime nextRunDate;
  final DateTime? endDate;

  factory RecurringRuleDto.fromJson(Map<String, dynamic> j) => RecurringRuleDto(
        id: j['id'] as String,
        accountId: j['account_id'] as String,
        categoryId: j['category_id'] as String,
        type: j['type'] as String,
        amount: double.parse(j['amount'] as String),
        note: j['note'] as String?,
        intervalUnit: j['interval_unit'] as String,
        intervalValue: j['interval_value'] as int,
        startDate: DateTime.parse(j['start_date'] as String),
        nextRunDate: DateTime.parse(j['next_run_date'] as String),
        endDate: j['end_date'] == null ? null : DateTime.parse(j['end_date'] as String),
      );
}

/// Wrap `/recurring-rules` (backend plan 009).
class RecurringRulesApi {
  RecurringRulesApi(this._dio);

  final Dio _dio;

  Future<List<RecurringRuleDto>> getAll() async {
    final res = await _dio.get<List<dynamic>>('/recurring-rules');
    return res.data!.map((e) => RecurringRuleDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({
    required String accountId,
    required String categoryId,
    required String type,
    required double amount,
    String? note,
    required String intervalUnit,
    required int intervalValue,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    return _dio.post('/recurring-rules', data: {
      'accountId': accountId,
      'categoryId': categoryId,
      'type': type,
      'amount': amount,
      if (note != null) 'note': note,
      'intervalUnit': intervalUnit,
      'intervalValue': intervalValue,
      'startDate': startDate.toIso8601String().substring(0, 10),
      if (endDate != null) 'endDate': endDate.toIso8601String().substring(0, 10),
    });
  }

  Future<void> delete(String id) => _dio.delete('/recurring-rules/$id');
}
