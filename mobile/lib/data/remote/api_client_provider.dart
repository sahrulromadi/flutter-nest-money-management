import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Satu `ApiClient` (Dio + interceptor Bearer/refresh) buat seluruh app.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
