import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../auth/current_user_provider.dart';
import 'categories_providers.dart';

const _iconChoices = [
  Icons.fastfood_outlined,
  Icons.directions_car_outlined,
  Icons.home_outlined,
  Icons.shopping_bag_outlined,
  Icons.local_hospital_outlined,
  Icons.school_outlined,
  Icons.movie_outlined,
  Icons.work_outline,
  Icons.savings_outlined,
  Icons.label_outline,
];

const _colorChoices = [
  Colors.orange,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.purple,
  Colors.teal,
];

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
  String? _icon;
  String? _color;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _parentId = widget.category?.parentId;
    _icon = widget.category?.icon;
    _color = widget.category?.color;
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
          icon: _icon,
          color: _color,
        );
      } else {
        final userId = await ref.read(currentUserIdProvider.future);
        await repo.create(
          userId: userId!,
          name: _nameController.text,
          type: _type,
          parentId: _parentId,
          icon: _icon,
          color: _color,
        );
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _iconChoices.map((icon) {
                  final selected = _icon == icon.codePoint.toString();
                  return IconButton(
                    isSelected: selected,
                    icon: Icon(icon),
                    onPressed: () =>
                        setState(() => _icon = icon.codePoint.toString()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colorChoices.map((color) {
                  final hex = '#${color.toARGB32().toRadixString(16).substring(2)}';
                  final selected = _color == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: selected ? 18 : 14,
                    ),
                  );
                }).toList(),
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
      ),
    );
  }
}
