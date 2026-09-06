import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/dismiss_background.dart';
import '../../shared/skeleton.dart';
import '../../theme/app_semantic_colors.dart';
import 'goal_form_screen.dart';
import 'goals_providers.dart';

class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: goalsAsync.when(
        loading: () => const SkeletonList(count: 4),
        error: (e, _) =>
            AppErrorState(onRetry: () => ref.invalidate(goalsListProvider)),
        data: (goals) {
          if (goals.isEmpty) {
            return AppEmptyState.goals(onAdd: () => _openForm(context));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: goals.map((g) => _GoalCard(goal: g)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GoalFormScreen()),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = context.semanticColors;
    final collected = ref.watch(goalProgressProvider(goal.id)).valueOrNull ?? 0;
    final pct = goal.targetAmount > 0
        ? (collected / goal.targetAmount * 100).round()
        : 0;
    final color = pct >= 100
        ? semantic.income
        : Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: const DismissDeleteBackground(),
      onDismissed: (_) =>
          ref.read(goalsRepositoryProvider).delete(goal.id),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: Theme.of(context).textTheme.titleMedium),
              if (goal.dueDate != null)
                Text(
                  'Tenggat: ${DateFormat('d MMM yyyy', 'id_ID').format(goal.dueDate!)}',
                ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0, 1).toDouble(),
                  color: color,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatRupiah(collected)} / ${formatRupiah(goal.targetAmount)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
