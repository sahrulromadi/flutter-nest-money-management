import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../shared/money_field.dart';
import '../auth/current_user_provider.dart';
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
  bool _saving = false;

  bool get _isEdit => widget.account != null;

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final repo = ref.read(accountsRepositoryProvider);
    if (_isEdit) {
      await repo.update(id: widget.account!.id, name: _nameController.text);
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
                MoneyField(
                  controller: _initialBalanceController,
                  label: 'Saldo awal',
                  validator: (_) => null,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
