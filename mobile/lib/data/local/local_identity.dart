import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _key = 'local_user_id';
const _storage = FlutterSecureStorage();

/// Identitas lokal buat scoping data Drift SEBELUM user login — app harus
/// kepakai penuh tanpa login (local-first, no forced auth gate). Sekali
/// dibikin, id ini stabil selama app terinstall.
///
/// Begitu user login pertama kali, [AuthController.login] mindahin semua
/// baris lokal dari id ini ke `sub` (user id) dari server, terus [adopt]
/// dipanggil biar id lokal = id server selamanya (data ga "ilang" pas
/// logout, dan re-login berikutnya ga migrasi ulang).
class LocalIdentity {
  const LocalIdentity._();

  static Future<String> ensure() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    await _storage.write(key: _key, value: generated);
    return generated;
  }

  static Future<void> adopt(String userId) =>
      _storage.write(key: _key, value: userId);
}
