import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../shared/calc_amount_field.dart';
import '../auth/current_user_provider.dart';
import '../transactions/transactions_providers.dart';
import 'accounts_providers.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});

  final Account? account;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.account?.name ?? '');
  late final _initialBalanceController = TextEditingController(
    text: moneyText(widget.account?.initialBalance ?? 0),
  );
  // Edit mode: saldo berjalan buat rekonsiliasi (plan 028 Item 1).
  final _currentBalanceController = TextEditingController();
  double? _snapshotBalance;
  bool _saving = false;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadBalanceSnapshot();
  }

  Future<void> _loadBalanceSnapshot() async {
    try {
      final bal = await ref.read(accountBalanceProvider(widget.account!).future);
      if (!mounted) return;
      setState(() {
        _snapshotBalance = bal;
        if (_currentBalanceController.text.isEmpty) {
          _currentBalanceController.text = moneyText(bal);
        }
      });
    } catch (_) {
      // biarin — field disable, edit nama tetap jalan
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _currentBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final repo = ref.read(accountsRepositoryProvider);
    if (_isEdit) {
      await repo.update(id: widget.account!.id, name: _nameController.text);
      await _applyBalanceAdjustment();
    } else {
      final userId = await ref.read(currentUserIdProvider.future);
      await repo.create(
        userId: userId!,
        name: _nameController.text,
        initialBalance: moneyValue(_initialBalanceController.text).toDouble(),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  /// Selisih saldo yang diketik vs snapshot -> transaksi penyesuaian.
  Future<void> _applyBalanceAdjustment() async {
    final snapshot = _snapshotBalance;
    if (snapshot == null) return;
    final entered = moneyValue(_currentBalanceController.text).toDouble();
    final delta = entered - snapshot;
    if (delta.abs() < 0.5) return;

    await ref.read(transactionsRepositoryProvider).createUncategorized(
          userId: widget.account!.userId,
          accountId: widget.account!.id,
          type: delta > 0 ? 'Income' : 'Expense',
          amount: delta.abs(),
          occurredAt: DateTime.now(),
          note: 'Penyesuaian saldo',
        );
  }

  Future<void> _delete() async {
    final repo = ref.read(accountsRepositoryProvider);
    final count = await repo.transactionCount(widget.account!.id);
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: Text(
          count == 0
              ? 'Akun "${widget.account!.name}" bakal dihapus.'
              : 'Akun "${widget.account!.name}" dipakai di $count transaksi. '
                  'Transaksi lama tetap tersimpan, tapi akun hilang dari daftar '
                  '& total saldo. Lanjut hapus?',
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

    await repo.delete(widget.account!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Akun' : 'Tambah Akun')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama akun'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                CalcAmountField(
                  controller: _initialBalanceController,
                  label: 'Saldo awal',
                  validator: (_) => null,
                ),
              ] else if (_snapshotBalance != null) ...[
                const SizedBox(height: 16),
                CalcAmountField(
                  controller: _currentBalanceController,
                  label: 'Saldo saat ini',
                  validator: (_) => null,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ubah kalau saldo di app beda sama saldo asli. Selisihnya '
                  'dicatat sebagai transaksi "Penyesuaian saldo".',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
                  child: const Text('Hapus akun'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
