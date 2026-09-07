import 'package:flutter/material.dart';

/// Numpad kalkulator in-app buat semua input nominal (bukan keyboard OS).
/// Angka + `+ − × ÷` + hapus. Ga ada `=` — confirm-nya tombol di parent.
class CalcPad extends StatelessWidget {
  const CalcPad({
    super.key,
    required this.onInput,
    required this.onBackspace,
  });

  /// Token buat di-append ke expression: '0'..'9', '000', '+', '-', '*', '/'.
  final ValueChanged<String> onInput;
  final VoidCallback onBackspace;

  static const _rows = [
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '−'],
    ['0', '000', '⌫', '+'],
  ];

  static const _token = {'÷': '/', '×': '*', '−': '-', '+': '+'};

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
                      onPressed: key == '⌫'
                          ? onBackspace
                          : () => onInput(_token[key] ?? key),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
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
