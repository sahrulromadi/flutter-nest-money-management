import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../shared/money_field.dart';
import '../../shared/skeleton.dart';
import '../categories/categories_providers.dart';
import 'insights_providers.dart';

Future<void> showBudgetFormSheet(BuildContext context, {String? periodId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BudgetFormSheet(periodId: periodId),
  );
}

class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({super.key, this.periodId});

  final String? periodId;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  String? _categoryId;
  final _limitController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final limit = moneyValue(_limitController.text).toDouble();
    if (_categoryId == null) {
      setState(() => _error = 'Pilih kategori dulu');
      return;
    }
    if (limit <= 0) {
      setState(() => _error = 'Isi limit dulu');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final periodId =
          widget.periodId ?? ref.read(viewedPeriodProvider)?.id;
      if (periodId == null) {
        setState(() => _error = 'Belum ada periode aktif');
        return;
      }
      await ref.read(budgetRepositoryProvider).setBudget(
            periodId: periodId,
            categoryId: _categoryId!,
            limitAmount: limit,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider('Expense'));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set Budget Kategori', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          categoriesAsync.when(
            loading: () => const Skeleton(height: 48, radius: 4),
            error: (e, _) => Text('Error: $e'),
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: categories
                  .map((Category c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ),
          const SizedBox(height: 16),
          MoneyField(controller: _limitController, label: 'Limit nominal'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
