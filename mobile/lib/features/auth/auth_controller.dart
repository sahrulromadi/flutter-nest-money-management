import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/auth_api.dart';
import '../../data/remote/token_storage.dart';
import 'auth_state.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

final authControllerProvider =
    NotifierProvider<AuthController, AuthPhase>(AuthController.new);

class AuthController extends Notifier<AuthPhase> {
  @override
  AuthPhase build() {
    _init();
    return AuthPhase.loading;
  }

  Future<void> _init() async {
    final hasTokens = await TokenStorage.hasTokens();
    if (!hasTokens) {
      state = AuthPhase.loggedOut;
      return;
    }
    final hasPin = await TokenStorage.hasPinSet();
    state = hasPin ? AuthPhase.locked : AuthPhase.needsPinSetup;
  }

  Future<void> login(String email, String password) async {
    final tokens = await ref.read(authApiProvider).login(email, password);
    await TokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    final hasPin = await TokenStorage.hasPinSet();
    state = hasPin ? AuthPhase.unlocked : AuthPhase.needsPinSetup;
  }

  Future<void> setPin(String pin) async {
    await TokenStorage.savePinHash(_hashPin(pin));
    state = AuthPhase.unlocked;
  }

  Future<bool> unlockWithPin(String pin) async {
    final storedHash = await TokenStorage.readPinHash();
    if (storedHash == _hashPin(pin)) {
      state = AuthPhase.unlocked;
      return true;
    }
    return false;
  }

  void unlockWithBiometric() {
    state = AuthPhase.unlocked;
  }

  /// Dipanggil pas app balik dari background — sesuai PRD, dikunci lagi
  /// tiap "dibuka" (bukan cuma cold start).
  void relock() {
    if (state == AuthPhase.unlocked) {
      state = AuthPhase.locked;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearTokens();
    state = AuthPhase.loggedOut;
  }

  String _hashPin(String pin) {
    // Bukan buat nahan brute-force (secure storage/OS keystore udah gerbang
    // utama) — cuma hindari nyimpen PIN plain text di storage.
    return sha256.convert(utf8.encode('karasuno:$pin')).toString();
  }
}
