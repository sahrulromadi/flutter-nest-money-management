import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_identity.dart';
import '../../data/remote/jwt_utils.dart';
import '../../data/remote/token_storage.dart';
import 'auth_controller.dart';

/// User id efektif buat scoping semua query lokal — dipake SEMUA repository.
/// Prioritas: user id dari access token (kalau login) > id lokal ([LocalIdentity],
/// dibikin sekali & stabil). App harus tetap kepakai penuh sebelum login;
/// data yang dicatat waktu itu ke-link ke akun server pas login pertama
/// kali (lihat [AuthController.login]).
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  ref.watch(authControllerProvider); // rebuild pas auth phase berubah
  final token = await TokenStorage.readAccessToken();
  final fromToken = token == null ? null : decodeUserIdFromJwt(token);
  return fromToken ?? LocalIdentity.ensure();
});
