import 'package:dio/dio.dart';

class GoalDto {
  const GoalDto({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.percentage,
    required this.dueDate,
    required this.accountId,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final int percentage;
  final DateTime? dueDate;
  final String? accountId;

  factory GoalDto.fromJson(Map<String, dynamic> j) => GoalDto(
        id: j['id'] as String,
        name: j['name'] as String,
        targetAmount: (j['target_amount'] as num).toDouble(),
        currentAmount: (j['currentAmount'] as num).toDouble(),
        percentage: j['percentage'] as int,
        dueDate: j['due_date'] == null ? null : DateTime.parse(j['due_date'] as String),
        accountId: j['account_id'] as String?,
      );
}

/// Wrap `/goals` (backend plan 010).
class GoalsApi {
  GoalsApi(this._dio);

  final Dio _dio;

  Future<List<GoalDto>> getAll() async {
    final res = await _dio.get<List<dynamic>>('/goals');
    return res.data!.map((e) => GoalDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({
    required String name,
    required double targetAmount,
    DateTime? dueDate,
    String? accountId,
  }) {
    return _dio.post('/goals', data: {
      'name': name,
      'targetAmount': targetAmount,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String().substring(0, 10),
      if (accountId != null) 'accountId': accountId,
    });
  }

  Future<void> delete(String id) => _dio.delete('/goals/$id');
}
