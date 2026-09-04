import 'package:dio/dio.dart';
import 'api_config.dart';
import 'auth_api.dart';
import 'token_storage.dart';

/// Dio dengan interceptor: attach Bearer token, auto-refresh pas 401,
/// retry request asli. Dipake semua API call selain login/refresh.
class ApiClient {
  ApiClient(this._authApi, {required String baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: kApiConnectTimeout,
          receiveTimeout: kApiReceiveTimeout,
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          if (!isUnauthorized || alreadyRetried) {
            return handler.next(error);
          }

          try {
            final refreshToken = await TokenStorage.readRefreshToken();
            if (refreshToken == null) {
              return handler.next(error);
            }
            final tokens = await _authApi.refresh(refreshToken);
            await TokenStorage.saveTokens(
              accessToken: tokens.accessToken,
              refreshToken: tokens.refreshToken,
            );

            final retryOptions = error.requestOptions;
            retryOptions.extra['retried'] = true;
            retryOptions.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
            final response = await dio.fetch(retryOptions);
            return handler.resolve(response);
          } catch (_) {
            // Refresh token juga invalid/kadaluarsa — user harus login ulang.
            await TokenStorage.clearTokens();
            return handler.next(error);
          }
        },
      ),
    );
  }

  final Dio dio;
  final AuthApi _authApi;
}
