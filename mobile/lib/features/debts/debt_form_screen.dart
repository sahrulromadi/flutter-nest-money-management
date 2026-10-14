import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../../shared/calc_amount_field.dart';
import '../auth/current_user_provider.dart';
import 'debts_providers.dart';

const _directions = ['Utang', 'Piutang'];

class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key, this.debt, this.initialDirection});

  final Debt? debt;
  final String? initialDirection;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  late String _direction = widget.debt?.direction ?? widget.initialDirection ?? 'Utang';
  late final _counterpartyController =
      TextEditingController(text: widget.debt?.counterparty ?? '');
  late final _amountController =
      TextEditingController(text: moneyText(widget.debt?.amount ?? 0));
  late final _noteController = TextEditingController(text: widget.debt?.note ?? '');
  late DateTime? _dueDate = widget.debt?.dueDate;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.debt != null;

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
      final repo = ref.read(debtsRepositoryProvider);
      final note = _noteController.text.isEmpty ? null : _noteController.text;
      if (_isEdit) {
        await repo.update(
          id: widget.debt!.id,
          direction: _direction,
          counterparty: _counterpartyController.text.trim(),
          amount: amount,
          dueDate: _dueDate,
          note: note,
        );
      } else {
        final userId = await ref.read(currentUserIdProvider.future);
        await repo.create(
          userId: userId!,
          direction: _direction,
          counterparty: _counterpartyController.text.trim(),
          amount: amount,
          dueDate: _dueDate,
          note: note,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus?'),
        content: Text(
          'Catatan ${_direction == 'Utang' ? 'utang ke' : 'piutang dari'} '
          '"${widget.debt!.counterparty}" bakal dihapus. Transaksi yang '
          'udah ditag ke sini tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(debtsRepositoryProvider).delete(widget.debt!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Utang/Piutang' : 'Tambah Utang/Piutang'),
      ),
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
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
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
            child: Text(_isEdit ? 'Simpan' : 'Tambah'),
          ),
          if (_isEdit) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : _delete,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Hapus'),
            ),
          ],
        ],
      ),
    );
  }
}
