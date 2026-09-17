import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../network/dio_cache_interceptor.dart';
import '../network/dio_client.dart';
import 'sync_queue.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Central engine for background data synchronization and offline action draining.
class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  final _secureStorage = const FlutterSecureStorage();
  Timer? _periodicTimer;
  bool _isSyncing = false;
  Future<void>? _inFlightSync;

  final _stateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateController.stream;

  SyncState _currentState = const SyncState();
  SyncState get currentState => _currentState;

  void _updateState(SyncState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Initialize the background sync engine and setup periodic sync.
  Future<void> initialize() async {
    await SyncQueue.instance.load();
    _updateState(_currentState.copyWith(
      pendingCount: SyncQueue.instance.length,
    ));

    // Periodic heartbeat: checks every 30 seconds if there are pending actions
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (SyncQueue.instance.length > 0) {
        sync();
      }
    });

    // Initial background sync
    unawaited(sync());
  }

  /// Enqueue an action and trigger a background sync attempt.
  Future<void> enqueue(SyncAction action) async {
    await SyncQueue.instance.enqueue(action);
    _updateState(_currentState.copyWith(
      pendingCount: SyncQueue.instance.length,
      status: SyncStatus.idle,
    ));
    unawaited(sync());
  }

  /// Trigger a background sync run.
  Future<void> sync() {
    if (_inFlightSync != null) return _inFlightSync!;

    final future = _doSync();
    _inFlightSync = future;
    future.whenComplete(() {
      if (identical(_inFlightSync, future)) {
        _inFlightSync = null;
      }
    });
    return future;
  }

  Future<void> _doSync() async {
    if (_isSyncing) return;

    // Verify authentication
    final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
    if (token == null || token.isEmpty) {
      return;
    }

    final queue = await SyncQueue.instance.load();
    if (queue.isEmpty) {
      _updateState(_currentState.copyWith(
        status: SyncStatus.synced,
        pendingCount: 0,
        lastSyncTime: DateTime.now(),
      ));
      return;
    }

    _isSyncing = true;
    _updateState(_currentState.copyWith(
      status: SyncStatus.syncing,
      pendingCount: queue.length,
    ));
    debugPrint('[SyncManager] Starting background sync (${queue.length} actions queued)...');

    final dio = DioClient().dio;
    final itemsToProcess = List<SyncAction>.from(queue);
    bool hadNetworkFailure = false;

    for (final action in itemsToProcess) {
      try {
        final options = Options(
          method: action.method,
          extra: {'noCache': true},
        );

        final response = await dio.request(
          action.endpoint,
          data: action.payload,
          options: options,
        );

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          debugPrint('[SyncManager] Action succeeded: ${action.type.name} (${action.endpoint})');
          await SyncQueue.instance.remove(action.id);
        } else {
          await SyncQueue.instance.incrementRetry(action.id);
        }
      } on DioException catch (dioErr) {
        final status = dioErr.response?.statusCode;

        // 400..409: Non-retryable client validation or conflict error (drop to prevent queue block)
        if (status != null && status >= 400 && status < 500 && status != 408) {
          debugPrint('[SyncManager] Client error $status for ${action.type.name}. Dropping action.');
          await SyncQueue.instance.remove(action.id);
          continue;
        }

        // Network error / server downtime: back off and retry later
        debugPrint('[SyncManager] Network error during sync (${dioErr.message}). Pausing sync cycle.');
        await SyncQueue.instance.incrementRetry(action.id);
        hadNetworkFailure = true;
        break; // Stop draining remaining items until next connection opportunity
      } catch (e) {
        debugPrint('[SyncManager] Unexpected error: $e');
        await SyncQueue.instance.incrementRetry(action.id);
      }
    }

    _isSyncing = false;
    final remaining = SyncQueue.instance.length;

    // Invalidate caches to ensure UI shows authoritative backend data
    DioCacheInterceptor().clear();

    _updateState(_currentState.copyWith(
      status: hadNetworkFailure
          ? SyncStatus.offline
          : (remaining == 0 ? SyncStatus.synced : SyncStatus.idle),
      pendingCount: remaining,
      lastSyncTime: DateTime.now(),
    ));

    debugPrint('[SyncManager] Sync cycle completed. Remaining pending actions: $remaining');
  }

  /// Clean up sync engine on logout or dispose.
  void dispose() {
    _periodicTimer?.cancel();
    _stateController.close();
  }
}

// ─── Riverpod Providers ──────────────────────────────────────────────────────

final syncStateProvider = StreamProvider<SyncState>((ref) {
  return SyncManager.instance.stateStream;
});

final syncPendingCountProvider = Provider<int>((ref) {
  final syncAsync = ref.watch(syncStateProvider);
  return syncAsync.valueOrNull?.pendingCount ?? SyncManager.instance.currentState.pendingCount;
});
