import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

const _key = 'server_base_url';
const _storage = FlutterSecureStorage();

/// Strip whitespace + trailing slash biar `${base}/auth/login` gak jadi `//`.
String normalizeServerUrl(String raw) {
  var u = raw.trim();
  while (u.endsWith('/')) {
    u = u.substring(0, u.length - 1);
  }
  return u;
}

/// Valid = http/https + ada host. Port opsional.
bool isValidServerUrl(String raw) {
  final uri = Uri.tryParse(normalizeServerUrl(raw));
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

/// Base URL backend yang lagi dipakai. Precedence:
/// URL tersimpan di secure storage  >  `--dart-define=API_BASE_URL`  >
/// `http://localhost:3000` (fallback dev, lihat [kApiBaseUrl]).
///
/// Semua HTTP client (`authApiProvider`, `apiClientProvider`) `ref.watch`
/// provider ini — begitu berubah, Riverpod rebuild semua yang depend.
final serverUrlProvider =
    NotifierProvider<ServerUrlController, String>(ServerUrlController.new);

class ServerUrlController extends Notifier<String> {
  @override
  String build() {
    _load();
    return kApiBaseUrl;
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    if (saved != null && saved.isNotEmpty) state = saved;
  }

  Future<void> set(String raw) async {
    final u = normalizeServerUrl(raw);
    await _storage.write(key: _key, value: u);
    state = u;
  }

  Future<void> resetToDefault() async {
    await _storage.delete(key: _key);
    state = kApiBaseUrl;
  }
}
