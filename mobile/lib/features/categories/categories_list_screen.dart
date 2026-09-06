import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../shared/app_illustration.dart';
import '../../shared/skeleton.dart';
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
      loading: () => const SkeletonList(count: 5),
      error: (e, _) =>
          AppErrorState(onRetry: () => ref.invalidate(categoriesListProvider(type))),
      data: (categories) {
        if (categories.isEmpty) {
          return AppEmptyState.categories();
        }
        final parents = categories.where((c) => c.parentId == null).toList();
        final children = categories.where((c) => c.parentId != null).toList();

        return ReorderableListView.builder(
          itemCount: parents.length,
          // Tahan-geser buat ubah urutan kategori (level atas). Sub ikut parent.
          onReorderItem: (oldIndex, newIndex) {
            final reordered = [...parents];
            reordered.insert(newIndex, reordered.removeAt(oldIndex));
            ref
                .read(categoriesRepositoryProvider)
                .reorder(reordered.map((c) => c.id).toList());
          },
          itemBuilder: (context, index) {
            final parent = parents[index];
            final subs = children.where((c) => c.parentId == parent.id).toList();
            return Column(
              key: ValueKey(parent.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(parent.name),
                  trailing: const Icon(Icons.drag_handle),
                  onTap: () => _openForm(context, parent),
                ),
                for (final sub in subs)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: ListTile(
                      title: Text(sub.name),
                      onTap: () => _openForm(context, sub),
                    ),
                  ),
              ],
            );
          },
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
