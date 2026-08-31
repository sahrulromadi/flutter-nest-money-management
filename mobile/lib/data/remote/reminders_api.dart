import 'package:dio/dio.dart';

class UpcomingBillDto {
  const UpcomingBillDto({required this.id, required this.amount, required this.nextRunDate});

  final String id;
  final double amount;
  final DateTime nextRunDate;

  factory UpcomingBillDto.fromJson(Map<String, dynamic> j) => UpcomingBillDto(
        id: j['id'] as String,
        amount: double.parse(j['amount'] as String),
        nextRunDate: DateTime.parse(j['next_run_date'] as String),
      );
}

/// Wrap `/reminders/*` (backend plan 011).
class RemindersApi {
  RemindersApi(this._dio);

  final Dio _dio;

  Future<List<UpcomingBillDto>> upcomingBills({int withinDays = 3}) async {
    final res = await _dio.get<List<dynamic>>(
      '/reminders/upcoming-bills',
      queryParameters: {'withinDays': withinDays},
    );
    return res.data!.map((e) => UpcomingBillDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> hasTransactionToday() async {
    final res = await _dio.get<Map<String, dynamic>>('/reminders/daily-check');
    return res.data!['hasTransactionToday'] as bool;
  }
}
