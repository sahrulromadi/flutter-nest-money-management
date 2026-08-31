import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../auth/current_user_provider.dart';
import 'accounts_providers.dart';

const _accountTypes = ['Bank', 'Ewallet', 'Cash'];

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
    text: widget.account?.initialBalance.toStringAsFixed(0) ?? '0',
  );
  late String _type = widget.account?.type ?? _accountTypes.first;
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
      await repo.update(id: widget.account!.id, name: _nameController.text, type: _type);
    } else {
      final userId = await ref.read(currentUserIdProvider.future);
      await repo.create(
        userId: userId!,
        name: _nameController.text,
        type: _type,
        initialBalance: double.tryParse(_initialBalanceController.text) ?? 0,
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _accountTypes.map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  );
                }).toList(),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _initialBalanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Saldo awal'),
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
