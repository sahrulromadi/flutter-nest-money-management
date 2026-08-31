import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'widgets/pin_pad.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  static const _pinLength = 6;

  String _firstPin = '';
  String _pin = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String digit) {
    setState(() {
      _error = null;
      _pin += digit;
    });
    if (_pin.length == _pinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _confirming = true;
      });
      return;
    }

    if (_pin != _firstPin) {
      setState(() {
        _error = 'PIN gak sama, coba lagi';
        _pin = '';
        _confirming = false;
        _firstPin = '';
      });
      return;
    }

    await ref.read(authControllerProvider.notifier).setPin(_pin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _confirming ? 'Ulangi PIN' : 'Buat PIN 6 digit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            PinDots(length: _pinLength, filled: _pin.length),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 32),
            NumPad(onDigit: _onDigit, onBackspace: _onBackspace),
          ],
        ),
      ),
    );
  }
}
