import 'package:flutter/material.dart';

class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, required this.filled});

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        );
      }),
    );
  }
}

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
