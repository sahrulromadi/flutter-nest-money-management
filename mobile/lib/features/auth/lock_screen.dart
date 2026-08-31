import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_controller.dart';
import 'widgets/pin_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  static const _pinLength = 6;
  final _localAuth = LocalAuthentication();

  String _pin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Buka Money Management',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (didAuthenticate && mounted) {
        ref.read(authControllerProvider.notifier).unlockWithBiometric();
      }
    } catch (_) {
      // Biometric gak tersedia/dibatalkan — fallback ke PIN, gak perlu
      // ditampilin sbg error ke user.
    }
  }

  void _onDigit(String digit) {
    setState(() {
      _error = null;
      _pin += digit;
    });
    if (_pin.length == _pinLength) {
      _checkPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _checkPin() async {
    final ok = await ref.read(authControllerProvider.notifier).unlockWithPin(_pin);
    if (!ok && mounted) {
      setState(() {
        _error = 'PIN salah';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text('Masukkan PIN', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            PinDots(length: _pinLength, filled: _pin.length),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 32),
            NumPad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _tryBiometric,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Pakai biometric'),
            ),
          ],
        ),
      ),
    );
  }
}
