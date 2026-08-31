import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import 'categories_providers.dart';
import 'category_form_screen.dart';

class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kategori'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Expense'), Tab(text: 'Income')],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryTypeList(type: 'Expense'),
            _CategoryTypeList(type: 'Income'),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabIndex = DefaultTabController.of(context).index;
            final type = tabIndex == 0 ? 'Expense' : 'Income';
            return FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryFormScreen(defaultType: type),
                ),
              ),
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTypeList extends ConsumerWidget {
  const _CategoryTypeList({required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider(type));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('Belum ada kategori'));
        }
        final parents = categories.where((c) => c.parentId == null).toList();
        final children = categories.where((c) => c.parentId != null).toList();

        return ListView(
          children: parents.map((parent) {
            final subs = children.where((c) => c.parentId == parent.id).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(parent.name),
                  onTap: () => _openForm(context, parent),
                ),
                for (final sub in subs)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: ListTile(
                      leading: const Icon(Icons.subdirectory_arrow_right),
                      title: Text(sub.name),
                      onTap: () => _openForm(context, sub),
                    ),
                  ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  void _openForm(BuildContext context, Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );
  }
}
