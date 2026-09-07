import 'package:flutter/material.dart';

/// Numpad kalkulator in-app buat semua input nominal (bukan keyboard OS).
/// Angka + `+ − × ÷` + hapus + AC. Ga ada `=` — confirm-nya tombol di parent.
class CalcPad extends StatelessWidget {
  const CalcPad({
    super.key,
    required this.onInput,
    required this.onBackspace,
    required this.onClear,
  });

  /// Token buat di-append ke expression: '0'..'9', '+', '-', '*', '/'.
  final ValueChanged<String> onInput;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const _rows = [
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '−'],
    ['AC', '0', '⌫', '+'],
  ];

  static const _token = {'÷': '/', '×': '*', '−': '-', '+': '+'};

  void _tap(String key) {
    switch (key) {
      case 'AC':
        onClear();
      case '⌫':
        onBackspace();
      default:
        onInput(_token[key] ?? key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox(
                    width: 64,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => _tap(key),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: key == '⌫'
                          ? const Icon(Icons.backspace_outlined, size: 20)
                          : Text(key, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
