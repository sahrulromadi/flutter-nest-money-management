import 'dart:convert';

/// Decode payload JWT tanpa verifikasi signature — cukup buat ambil `sub`
/// (user id) di sisi client, krn signature udah diverifikasi backend pas
/// token diterbitkan. Jangan dipake buat validasi keamanan.
String? decodeUserIdFromJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final normalized = base64Url.normalize(parts[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return map['sub'] as String?;
  } catch (_) {
    return null;
  }
}
