import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _grouping = NumberFormat.decimalPattern('id_ID');

/// Ambil nilai integer dari teks `MoneyField` (buang titik ribuan & non-digit).
int moneyValue(String text) => int.tryParse(_digitsOnly(text)) ?? 0;

/// Teks awal ke-format buat prefill controller (mis. edit form).
String moneyText(num value) => value <= 0 ? '' : _grouping.format(value.round());

String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

/// Input nominal rupiah: keyboard numerik OS + pemisah ribuan live, tanpa
/// leading zero. Baca nilainya via `moneyValue(controller.text)`.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    this.label = 'Nominal',
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [_ThousandsFormatter()],
      decoration: InputDecoration(labelText: label, prefixText: 'Rp '),
      validator: validator ??
          (v) => moneyValue(v ?? '') <= 0 ? 'Wajib diisi' : null,
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digitsOnly(newValue.text);
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = _grouping.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
