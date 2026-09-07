import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/calc_amount_field.dart';
import '../../shared/calc_expression.dart';
import '../../shared/calc_pad.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/skeleton.dart';
import '../accounts/accounts_providers.dart';
import '../auth/current_user_provider.dart';
import '../categories/categories_providers.dart';
import '../goals/goals_providers.dart';
import 'transactions_providers.dart';

const _types = ['Expense', 'Income', 'Transfer'];

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.transactionId});

  final String? transactionId;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  String _type = 'Expense';
  String _expr = '';
  String? _accountId;
  String? _transferToAccountId;
  String? _categoryId;
  String? _goalId;
  DateTime _occurredAt = DateTime.now();
  final _noteController = TextEditingController();
  final _feeController = TextEditingController(); // biaya admin transfer (plan 028 Item 2)
  bool _saving = false;
  String? _error;
  bool _loadedExisting = false;

  bool get _isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExisting();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (_loadedExisting || widget.transactionId == null) return;
    _loadedExisting = true;
    final repo = ref.read(transactionsRepositoryProvider);
    final t = await repo.findById(widget.transactionId!);
    if (t == null || !mounted) return;
    setState(() {
      _type = t.type;
      _expr = t.amount.toStringAsFixed(0);
      _accountId = t.accountId;
      _transferToAccountId = t.transferToAccountId;
      _categoryId = t.categoryId;
      _goalId = t.goalId;
      _occurredAt = t.occurredAt;
      _noteController.text = t.note ?? '';
    });
  }

  void _onInput(String token) => setState(() => _expr += token);

  void _onBackspace() {
    if (_expr.isEmpty) return;
    setState(() => _expr = _expr.substring(0, _expr.length - 1));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Future<void> _submit() async {
    final amount = (evalExpression(_expr) ?? 0).toDouble();
    if (amount <= 0) {
      setState(() => _error = 'Isi nominal dulu');
      return;
    }
    if (_accountId == null) {
      setState(() => _error = 'Pilih akun dulu');
      return;
    }
    if (_type == 'Transfer' && _transferToAccountId == null) {
      setState(() => _error = 'Pilih akun tujuan transfer');
      return;
    }
    if (_type != 'Transfer' && _categoryId == null) {
      setState(() => _error = 'Pilih kategori dulu');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(transactionsRepositoryProvider);
      final note = _noteController.text.isEmpty ? null : _noteController.text;

      if (_isEdit) {
        await repo.update(
          id: widget.transactionId!,
          accountId: _accountId,
          transferToAccountId:
              _type == 'Transfer' ? _transferToAccountId : null,
          amount: amount,
          occurredAt: _occurredAt,
          categoryId: _type == 'Transfer' ? null : _categoryId,
          note: note,
          goalId: _goalId,
        );
      } else {
        final userId = await ref.read(currentUserIdProvider.future);
        await repo.create(
          userId: userId!,
          accountId: _accountId!,
          type: _type,
          amount: amount,
          occurredAt: _occurredAt,
          categoryId: _type == 'Transfer' ? null : _categoryId,
          transferToAccountId: _type == 'Transfer' ? _transferToAccountId : null,
          note: note,
          goalId: _goalId,
        );

        // Biaya admin transfer -> Expense turunan di akun asal (plan 028 Item 2).
        final fee = _type == 'Transfer'
            ? moneyValue(_feeController.text).toDouble()
            : 0.0;
        if (fee > 0) {
          await repo.createUncategorized(
            userId: userId,
            accountId: _accountId!,
            type: 'Expense',
            amount: fee,
            occurredAt: _occurredAt,
            note: 'Biaya transfer',
          );
        }
      }
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
    final categoriesAsync = _type == 'Transfer'
        ? null
        : ref.watch(categoriesListProvider(_type));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: _types
                  .map((t) => ButtonSegment(value: t, label: Text(t)))
                  .toList(),
              selected: {_type},
              onSelectionChanged: _isEdit
                  ? null
                  : (selection) => setState(() {
                        _type = selection.first;
                        _categoryId = null;
                      }),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    formatRupiah((evalExpression(_expr) ?? 0).round()),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (hasOperator(_expr)) ...[
                    const SizedBox(height: 2),
                    Text(
                      prettyExpression(_expr),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: CalcPad(
                onInput: _onInput,
                onBackspace: _onBackspace,
                onClear: () => setState(() => _expr = ''),
              ),
            ),
            const SizedBox(height: 16),
            Text('Akun', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            accountsAsync.when(
              loading: () => const SkeletonChips(),
              error: (e, _) => Text('Error: $e'),
              data: (accounts) => Wrap(
                spacing: 8,
                children: accounts.map((a) {
                  return ChoiceChip(
                    label: Text(a.name),
                    selected: _accountId == a.id,
                    onSelected: (_) => setState(() => _accountId = a.id),
                  );
                }).toList(),
              ),
            ),
            if (_type == 'Transfer') ...[
              const SizedBox(height: 16),
              Text('Akun tujuan', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              accountsAsync.when(
                loading: () => const SkeletonChips(),
                error: (e, _) => Text('Error: $e'),
                data: (accounts) => Wrap(
                  spacing: 8,
                  children: accounts
                      .where((a) => a.id != _accountId)
                      .map((a) {
                    return ChoiceChip(
                      label: Text(a.name),
                      selected: _transferToAccountId == a.id,
                      onSelected: (_) =>
                          setState(() => _transferToAccountId = a.id),
                    );
                  }).toList(),
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                CalcAmountField(
                  controller: _feeController,
                  label: 'Biaya admin (opsional)',
                  validator: (_) => null,
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              Text('Kategori', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              categoriesAsync!.when(
                loading: () => const SkeletonChips(),
                error: (e, _) => Text('Error: $e'),
                data: (categories) => Wrap(
                  spacing: 8,
                  children: categories.map((c) {
                    return ChoiceChip(
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_occurredAt)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final goalsAsync = ref.watch(goalsListProvider);
                return goalsAsync.maybeWhen(
                  data: (goals) {
                    if (goals.isEmpty) return const SizedBox.shrink();
                    return DropdownButtonFormField<String?>(
                      initialValue: _goalId,
                      decoration: const InputDecoration(labelText: 'Tag ke goal (opsional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tidak ditag')),
                        ...goals.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
                      ],
                      onChanged: (v) => setState(() => _goalId = v),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
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
          ],
        ),
      ),
    );
  }
}
