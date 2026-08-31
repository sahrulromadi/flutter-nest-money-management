import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/currency_formatter.dart';
import '../../theme/app_semantic_colors.dart';
import 'goal_form_screen.dart';
import 'goals_providers.dart';

class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsListProvider);
    final semantic = context.semanticColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) return const Center(child: Text('Belum ada goal'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: goals.map((g) {
              final color = g.percentage >= 100 ? semantic.income : Theme.of(context).colorScheme.primary;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name, style: Theme.of(context).textTheme.titleMedium),
                      if (g.dueDate != null)
                        Text('Tenggat: ${DateFormat('d MMM yyyy', 'id_ID').format(g.dueDate!)}'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (g.percentage / 100).clamp(0, 1),
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${formatRupiah(g.currentAmount)} / ${formatRupiah(g.targetAmount)}'),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GoalFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
