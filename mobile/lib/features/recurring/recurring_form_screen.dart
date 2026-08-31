import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../accounts/accounts_providers.dart';
import '../categories/categories_providers.dart';
import 'recurring_providers.dart';

const _types = ['Expense', 'Income'];
const _intervalUnits = ['Day', 'Week', 'Month'];

class RecurringFormScreen extends ConsumerStatefulWidget {
  const RecurringFormScreen({super.key});

  @override
  ConsumerState<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends ConsumerState<RecurringFormScreen> {
  String _type = 'Expense';
  String? _accountId;
  String? _categoryId;
  final _amountController = TextEditingController();
  String _intervalUnit = 'Month';
  int _intervalValue = 1;
  DateTime _startDate = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (_accountId == null || _categoryId == null || amount == null || amount <= 0) {
      setState(() => _error = 'Semua field wajib diisi bener');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(recurringRulesApiProvider).create(
            accountId: _accountId!,
            categoryId: _categoryId!,
            type: _type,
            amount: amount,
            intervalUnit: _intervalUnit,
            intervalValue: _intervalValue,
            startDate: _startDate,
          );
      ref.invalidate(recurringRulesListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider(_type));

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Aturan Berulang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: _types.map((t) {
              return ChoiceChip(
                label: Text(t),
                selected: _type == t,
                onSelected: (_) => setState(() {
                  _type = t;
                  _categoryId = null;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal'),
          ),
          const SizedBox(height: 16),
          accountsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (accounts) => DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Akun'),
              items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Tiap'),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: '1',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _intervalValue = int.tryParse(v) ?? 1,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _intervalUnit,
                items: _intervalUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _intervalUnit = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_startDate)),
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
