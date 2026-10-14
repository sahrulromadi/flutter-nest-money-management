import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/calc_amount_field.dart';
import '../auth/current_user_provider.dart';
import 'debts_providers.dart';

const _directions = ['Utang', 'Piutang'];

class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key});

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  String _direction = 'Utang';
  final _counterpartyController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _counterpartyController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = moneyValue(_amountController.text).toDouble();
    if (_counterpartyController.text.trim().isEmpty) {
      setState(() => _error = _direction == 'Utang'
          ? 'Isi nama yang kamu utangi dulu'
          : 'Isi nama yang berutang dulu');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = 'Isi nominal dulu');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      await ref.read(debtsRepositoryProvider).create(
            userId: userId!,
            direction: _direction,
            counterparty: _counterpartyController.text.trim(),
            amount: amount,
            dueDate: _dueDate,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          );
      ref.invalidate(debtsListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Utang/Piutang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: _directions.map((d) {
              return ChoiceChip(
                label: Text(d),
                selected: _direction == d,
                onSelected: (_) => setState(() => _direction = d),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _counterpartyController,
            decoration: InputDecoration(
              labelText:
                  _direction == 'Utang' ? 'Utang ke siapa' : 'Piutang dari siapa',
            ),
          ),
          const SizedBox(height: 16),
          CalcAmountField(controller: _amountController, label: 'Nominal'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _dueDate == null
                  ? 'Tenggat (opsional)'
                  : DateFormat('d MMMM yyyy', 'id_ID').format(_dueDate!),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
