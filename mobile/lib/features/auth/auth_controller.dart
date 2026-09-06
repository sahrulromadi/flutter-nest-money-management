import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database_provider.dart';
import '../../data/local/local_identity.dart';
import '../../data/remote/api_client_provider.dart';
import '../../data/remote/jwt_utils.dart';
import '../../data/remote/token_storage.dart';
import 'auth_state.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthPhase>(AuthController.new);

class AuthController extends Notifier<AuthPhase> {
  @override
  AuthPhase build() {
    _init();
    return AuthPhase.loading;
  }

  Future<void> _init() async {
    state = await TokenStorage.hasTokens()
        ? AuthPhase.unlocked
        : AuthPhase.loggedOut;
  }

  Future<void> login(String email, String password) async {
    final tokens = await ref.read(authApiProvider).login(email, password);
    await TokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    // plan 031 — server menang: device baru login ke akun → data lokal
    // (kalau ada) udah dikonfirmasi buat dihapus di layar Login. Wipe +
    // adopt id server; sync pull yang bawa data akun turun.
    final serverUserId = decodeUserIdFromJwt(tokens.accessToken);
    if (serverUserId != null) {
      final localId = await LocalIdentity.ensure();
      if (localId != serverUserId) {
        await ref.read(appDatabaseProvider).wipeAll();
        await LocalIdentity.adopt(serverUserId);
      }
    }

    state = AuthPhase.unlocked;
  }

  Future<void> logout() async {
    await TokenStorage.clearTokens();
    state = AuthPhase.loggedOut;
  }
}
