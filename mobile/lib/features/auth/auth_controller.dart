import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database_provider.dart';
import '../../data/local/local_identity.dart';
import '../../data/remote/api_client_provider.dart';
import '../../data/remote/jwt_utils.dart';
import '../../data/remote/token_storage.dart';
import 'auth_state.dart';

enum LocalDataAction { merge, replace }

final authControllerProvider =
    NotifierProvider<AuthController, AuthPhase>(AuthController.new);

class AuthController extends Notifier<AuthPhase> {
  @override
  AuthPhase build() {
    _init();
    return AuthPhase.loading;
  }

  Future<void> _init() async {
    try {
      state = await TokenStorage.hasTokens()
          ? AuthPhase.unlocked
          : AuthPhase.loggedOut;
    } catch (_) {
      state = AuthPhase.loggedOut;
    }
  }

  /// [localData] nentuin nasib data lokal pas login di device yang belum pernah
  /// login (plan 031, opsi C): `merge` = push lokal ke akun, `replace` = wipe
  /// lokal pakai data akun. Kalau ga ada data lokal / id lokal == id server,
  /// diabaikan.
  Future<void> login(
    String email,
    String password, {
    LocalDataAction localData = LocalDataAction.replace,
  }) async {
    final tokens = await ref.read(authApiProvider).login(email, password);
    await TokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    final serverUserId = decodeUserIdFromJwt(tokens.accessToken);
    if (serverUserId != null) {
      final localId = await LocalIdentity.ensure();
      if (localId != serverUserId) {
        final db = ref.read(appDatabaseProvider);
        if (localData == LocalDataAction.merge) {
          await db.reassignUserData(localId, serverUserId);
        } else {
          await db.wipeAll();
        }
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
