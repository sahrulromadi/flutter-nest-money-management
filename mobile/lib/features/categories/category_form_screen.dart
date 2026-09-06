import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../auth/current_user_provider.dart';
import 'categories_providers.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.category, this.defaultType});

  final Category? category;
  final String? defaultType;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.category?.name ?? '');
  late String _type = widget.category?.type ?? widget.defaultType ?? 'Expense';
  String? _parentId;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _parentId = widget.category?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(categoriesRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.update(
          id: widget.category!.id,
          name: _nameController.text,
        );
      } else {
        final userId = await ref.read(currentUserIdProvider.future);
        await repo.create(
          userId: userId!,
          name: _nameController.text,
          type: _type,
          parentId: _parentId,
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
    final repo = ref.read(categoriesRepositoryProvider);
    final count = await repo.transactionCount(widget.category!.id);
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text(
          count == 0
              ? 'Kategori "${widget.category!.name}" & subkategori-nya bakal dihapus.'
              : 'Kategori "${widget.category!.name}" dipakai di $count transaksi. '
                  'Transaksi lama tetap tersimpan. Kategori & subkategori-nya '
                  'bakal dihapus. Lanjut?',
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

    await repo.delete(widget.category!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Cuma kategori top-level (parentId null) yang boleh dipilih jadi induk
    // — dibatasin 2 level biar UI gak ribet (DESIGN.md: gak mau ribet).
    final topLevelAsync = ref.watch(categoriesListProvider(_type));

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Kategori' : 'Tambah Kategori')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama kategori'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: ['Expense', 'Income'].map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: _type == type,
                      onSelected: (_) => setState(() {
                        _type = type;
                        _parentId = null;
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                topLevelAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (categories) {
                    final topLevel = categories.where((c) => c.parentId == null);
                    return DropdownButtonFormField<String?>(
                      initialValue: _parentId,
                      decoration: const InputDecoration(labelText: 'Kategori induk (opsional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tanpa induk')),
                        ...topLevel.map(
                          (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (value) => setState(() => _parentId = value),
                    );
                  },
                ),
              ],
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
                  child: const Text('Hapus kategori'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
