import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/money_field.dart';
import '../../shared/skeleton.dart';
import '../accounts/accounts_providers.dart';
import '../auth/current_user_provider.dart';
import '../categories/categories_providers.dart';
import 'recurring_providers.dart';

const _types = ['Expense', 'Income'];
const _intervalUnits = ['Day', 'Week', 'Month', 'DaysOfWeek'];
const _unitLabels = {
  'Day': 'Hari',
  'Week': 'Minggu',
  'Month': 'Bulan',
  'DaysOfWeek': 'Hari tertentu',
};
const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

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
  final Set<int> _daysOfWeek = {}; // 1=Sen..7=Min
  DateTime _startDate = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = moneyValue(_amountController.text).toDouble();
    if (amount <= 0) {
      setState(() => _error = 'Isi nominal dulu');
      return;
    }
    if (_accountId == null) {
      setState(() => _error = 'Pilih akun dulu');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Pilih kategori dulu');
      return;
    }
    if (_intervalUnit == 'DaysOfWeek' && _daysOfWeek.isEmpty) {
      setState(() => _error = 'Pilih minimal 1 hari');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      await ref.read(recurringRulesRepositoryProvider).create(
            userId: userId!,
            accountId: _accountId!,
            categoryId: _categoryId!,
            type: _type,
            amount: amount,
            intervalUnit: _intervalUnit,
            intervalValue: _intervalUnit == 'DaysOfWeek' ? 1 : _intervalValue,
            daysOfWeek: _intervalUnit == 'DaysOfWeek'
                ? (_daysOfWeek.toList()..sort()).join(',')
                : null,
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
          MoneyField(controller: _amountController, label: 'Nominal'),
          const SizedBox(height: 16),
          accountsAsync.when(
            loading: () => const SkeletonChips(),
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
            loading: () => const SkeletonChips(),
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
              if (_intervalUnit != 'DaysOfWeek') ...[
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: '1',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _intervalValue = int.tryParse(v) ?? 1,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              DropdownButton<String>(
                value: _intervalUnit,
                items: _intervalUnits
                    .map((u) => DropdownMenuItem(
                        value: u, child: Text(_unitLabels[u] ?? u)))
                    .toList(),
                onChanged: (v) => setState(() => _intervalUnit = v!),
              ),
            ],
          ),
          if (_intervalUnit == 'DaysOfWeek') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (var i = 1; i <= 7; i++)
                  FilterChip(
                    label: Text(_dayLabels[i - 1]),
                    selected: _daysOfWeek.contains(i),
                    onSelected: (on) => setState(() =>
                        on ? _daysOfWeek.add(i) : _daysOfWeek.remove(i)),
                  ),
              ],
            ),
          ],
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
