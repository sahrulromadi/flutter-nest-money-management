import 'package:dio/dio.dart';

class SyncApi {
  SyncApi(this._dio);

  final Dio _dio;

  Future<void> push(Map<String, List<Map<String, dynamic>>> changes) {
    return _dio.post('/sync/push', data: {'changes': changes});
  }

  Future<Map<String, List<Map<String, dynamic>>>> pull(DateTime? since) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sync/pull',
      queryParameters: since == null ? null : {'since': since.toUtc().toIso8601String()},
    );
    final data = response.data ?? {};
    return data.map(
      (key, value) => MapEntry(key, (value as List).cast<Map<String, dynamic>>()),
    );
  }
}
