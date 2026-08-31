import 'package:dio/dio.dart';
import 'api_config.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

/// Dio polos, gak pake interceptor auth — dipake buat login/refresh
/// (endpoint public, dan refresh sendiri yang jadi sumber token baru,
/// jadi gak boleh lewat interceptor yang nyoba refresh lagi kalau gagal).
class AuthApi {
  AuthApi() : _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl));

  final Dio _dio;

  Future<AuthTokens> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthTokens.fromJson(response.data!);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthTokens.fromJson(response.data!);
  }
}
