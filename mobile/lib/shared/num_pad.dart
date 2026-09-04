import 'package:flutter/material.dart';

/// Numpad custom buat input nominal transaksi (bukan keyboard qwerty —
/// DESIGN.md §6 "Add Transaction").
class NumPad extends StatelessWidget {
  const NumPad({super.key, required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 64, height: 64);
            return SizedBox(
              width: 64,
              height: 64,
              child: TextButton(
                onPressed: key == '⌫' ? onBackspace : () => onDigit(key),
                child: Text(key, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
