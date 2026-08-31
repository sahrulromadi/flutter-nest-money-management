import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/sync/sync_status_provider.dart';

class SyncTile extends ConsumerWidget {
  const SyncTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStatusProvider);
    final isSyncing = state.status == SyncStatus.syncing;

    final subtitle = switch (state.status) {
      SyncStatus.syncing => 'Syncing...',
      SyncStatus.error => 'Gagal sync: ${state.errorMessage}',
      _ => state.lastSyncedAt == null
          ? 'Belum pernah sync'
          : 'Terakhir sync: ${DateFormat('d MMM yyyy HH:mm', 'id_ID').format(state.lastSyncedAt!)}',
    };

    return ListTile(
      leading: isSyncing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      title: const Text('Sync'),
      subtitle: Text(subtitle),
      onTap: isSyncing ? null : () => ref.read(syncStatusProvider.notifier).syncNow(),
    );
  }
}
