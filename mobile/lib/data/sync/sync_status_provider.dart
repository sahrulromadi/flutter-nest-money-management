import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database_provider.dart';
import '../remote/api_client_provider.dart';
import '../remote/sync_api.dart';
import 'sync_engine.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  const SyncState({required this.status, this.lastSyncedAt, this.errorMessage});

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  SyncState copyWith({SyncStatus? status, DateTime? lastSyncedAt, String? errorMessage}) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage,
    );
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return SyncEngine(SyncApi(apiClient.dio), db);
});

final syncStatusProvider = NotifierProvider<SyncStatusController, SyncState>(
  SyncStatusController.new,
);

class SyncStatusController extends Notifier<SyncState> {
  @override
  SyncState build() {
    _loadLastSyncedAt();
    return const SyncState(status: SyncStatus.idle);
  }

  Future<void> _loadLastSyncedAt() async {
    final last = await ref.read(syncEngineProvider).lastSyncedAt();
    state = state.copyWith(lastSyncedAt: last);
  }

  /// Dipanggil pas user tekan tombol Sync — satu-satunya cara sync jalan.
  Future<void> syncNow() async {
    state = state.copyWith(status: SyncStatus.syncing);
    try {
      await ref.read(syncEngineProvider).syncAll();
      state = SyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, errorMessage: e.toString());
    }
  }
}
