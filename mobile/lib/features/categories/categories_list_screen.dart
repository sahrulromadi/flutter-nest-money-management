import 'package:flutter/foundation.dart' show listEquals;
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

class _CategoryTypeList extends ConsumerStatefulWidget {
  const _CategoryTypeList({required this.type});

  final String type;

  @override
  ConsumerState<_CategoryTypeList> createState() => _CategoryTypeListState();
}

class _CategoryTypeListState extends ConsumerState<_CategoryTypeList> {
  /// Urutan optimistik abis drag — dipakai sampai stream Drift nyusul,
  /// biar item ga "mental balik" lalu lompat lagi.
  List<Category>? _pending;

  @override
  Widget build(BuildContext context) {
    final provider = categoriesListProvider(widget.type);
    final categoriesAsync = ref.watch(provider);

    // Begitu stream cocok sama urutan optimistik, lepas override-nya.
    ref.listen(provider, (_, next) {
      final list = next.valueOrNull;
      if (list == null || _pending == null) return;
      final streamIds =
          list.where((c) => c.parentId == null).map((c) => c.id).toList();
      final pendingIds = _pending!.map((c) => c.id).toList();
      if (listEquals(streamIds, pendingIds)) setState(() => _pending = null);
    });

    return categoriesAsync.when(
      loading: () => const SkeletonList(count: 5),
      error: (e, _) =>
          AppErrorState(onRetry: () => ref.invalidate(provider)),
      data: (categories) {
        if (categories.isEmpty) {
          return AppEmptyState.categories();
        }
        final streamParents =
            categories.where((c) => c.parentId == null).toList();
        final parents = _pending ?? streamParents;
        final children = categories.where((c) => c.parentId != null).toList();

        return ReorderableListView.builder(
          itemCount: parents.length,
          // Tahan-geser buat ubah urutan kategori (level atas). Sub ikut parent.
          onReorderItem: (oldIndex, newIndex) {
            final reordered = [...parents];
            reordered.insert(newIndex, reordered.removeAt(oldIndex));
            setState(() => _pending = reordered);
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
