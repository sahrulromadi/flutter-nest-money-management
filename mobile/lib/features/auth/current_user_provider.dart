import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/jwt_utils.dart';
import '../../data/remote/token_storage.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

/// User id dari access token yang lagi kesimpen — cuma valid kalau
/// [AuthPhase.unlocked]. Dipake semua repository buat scoping query lokal.
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  ref.watch(authControllerProvider); // rebuild pas auth phase berubah
  final token = await TokenStorage.readAccessToken();
  if (token == null) return null;
  return decodeUserIdFromJwt(token);
});
