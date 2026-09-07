import 'package:flutter/material.dart';

import 'calc_expression.dart';
import 'calc_pad.dart';
import 'currency_formatter.dart';
import 'money_field.dart';

export 'money_field.dart' show moneyValue, moneyText;

/// Pengganti input nominal berbasis keyboard OS. Field read-only; tap →
/// bottom sheet kalkulator (`CalcPad`). Nilai disimpan ke [controller] dalam
/// format Rupiah — baca balik pakai `moneyValue(controller.text)`.
class CalcAmountField extends StatelessWidget {
  const CalcAmountField({
    super.key,
    required this.controller,
    this.label = 'Nominal',
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  Future<void> _open(BuildContext context) async {
    final seed = moneyValue(controller.text);
    final result = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _CalcSheet(
        label: label,
        initial: seed > 0 ? '$seed' : '',
      ),
    );
    if (result != null) {
      controller.text = moneyText(result.round());
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      showCursor: false,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        suffixIcon: const Icon(Icons.calculate_outlined),
      ),
      onTap: () => _open(context),
      validator: validator ??
          (v) => moneyValue(v ?? '') <= 0 ? 'Wajib diisi' : null,
    );
  }
}

class _CalcSheet extends StatefulWidget {
  const _CalcSheet({required this.label, required this.initial});

  final String label;
  final String initial;

  @override
  State<_CalcSheet> createState() => _CalcSheetState();
}

class _CalcSheetState extends State<_CalcSheet> {
  late String _expr = widget.initial;

  @override
  Widget build(BuildContext context) {
    final result = evalExpression(_expr);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            _expr.isEmpty ? '0' : prettyExpression(_expr),
            textAlign: TextAlign.end,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            result == null
                ? '—'
                : '= ${formatRupiah(result.round())}',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: CalcPad(
              onInput: (t) => setState(() => _expr += t),
              onBackspace: () => setState(() {
                if (_expr.isNotEmpty) {
                  _expr = _expr.substring(0, _expr.length - 1);
                }
              }),
              onClear: () => setState(() => _expr = ''),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (result == null || result <= 0)
                ? null
                : () => Navigator.of(context).pop(result),
            child: const Text('Pakai'),
          ),
        ],
      ),
    );
  }
}
