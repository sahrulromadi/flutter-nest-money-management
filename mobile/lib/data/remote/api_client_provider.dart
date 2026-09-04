import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'auth_api.dart';
import 'server_url.dart';

/// `AuthApi` polos (login/refresh). Rebuild pas server URL berubah.
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(serverUrlProvider));
});

/// Satu `ApiClient` (Dio + interceptor Bearer/refresh) buat seluruh app.
/// Rebuild pas server URL berubah → semua API yang depend ikut rebuild.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.watch(authApiProvider),
    baseUrl: ref.watch(serverUrlProvider),
  );
});
