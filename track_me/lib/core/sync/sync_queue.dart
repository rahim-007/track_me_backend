import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../local/json_file_cache.dart';

enum SyncActionType {
  createHabit,
  updateHabit,
  toggleHabit,
  skipHabit,
  deleteHabit,
  createGoal,
  updateGoal,
  updateGoalProgress,
  deleteGoal,
  updateProfile,
  createCashFlowTransaction,
  updateCashFlowTransaction,
  deleteCashFlowTransaction,
  genericRequest,
}

class SyncAction {
  final String id;
  final SyncActionType type;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? payload;
  final String? tempId;
  final int createdAt;
  int retryCount;

  SyncAction({
    String? id,
    required this.type,
    required this.endpoint,
    required this.method,
    this.payload,
    this.tempId,
    int? createdAt,
    this.retryCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'tempId': tempId,
        'createdAt': createdAt,
        'retryCount': retryCount,
      };

  factory SyncAction.fromJson(Map<String, dynamic> json) => SyncAction(
        id: json['id'] as String,
        type: SyncActionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SyncActionType.genericRequest,
        ),
        endpoint: json['endpoint'] as String,
        method: json['method'] as String,
        payload: json['payload'] as Map<String, dynamic>?,
        tempId: json['tempId'] as String?,
        createdAt: json['createdAt'] as int? ?? 0,
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

/// Persistent queue for background sync actions.
class SyncQueue {
  SyncQueue._();
  static final SyncQueue instance = SyncQueue._();

  static const String _cacheKey = 'pending_sync_queue';
  List<SyncAction> _queue = [];
  bool _isLoaded = false;

  /// Load pending queue from persistent storage.
  Future<List<SyncAction>> load() async {
    if (_isLoaded) return _queue;
    try {
      final list = await JsonFileCache.read<List<SyncAction>>(
        _cacheKey,
        (json) => (json as List)
            .map((e) => SyncAction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      _queue = list ?? [];
      _isLoaded = true;
    } catch (e) {
      debugPrint('[SyncQueue] Error loading queue: $e');
      _queue = [];
      _isLoaded = true;
    }
    return _queue;
  }

  /// Get pending actions.
  List<SyncAction> get items => List.unmodifiable(_queue);
  List<SyncAction> get actions => List.unmodifiable(_queue);

  /// Number of pending actions.
  int get length => _queue.length;

  /// Whether the queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Add a sync action to the queue and persist.
  Future<void> enqueue(SyncAction action) async {
    await load();

    // Smart deduplication:
    // If updating profile, keep only the latest update
    if (action.type == SyncActionType.updateProfile) {
      _queue.removeWhere((a) => a.type == SyncActionType.updateProfile);
    }

    _queue.add(action);
    await _persist();
    debugPrint('[SyncQueue] Enqueued ${action.type.name} (${action.endpoint}). Queue size: ${_queue.length}');
  }

  /// Remove a completed action by ID.
  Future<void> remove(String id) async {
    await load();
    _queue.removeWhere((a) => a.id == id);
    await _persist();
  }

  /// Increment retry count or remove if exceeded limit.
  Future<void> incrementRetry(String id, {int maxRetries = 5}) async {
    await load();
    final index = _queue.indexWhere((a) => a.id == id);
    if (index != -1) {
      final action = _queue[index];
      action.retryCount += 1;
      if (action.retryCount >= maxRetries) {
        debugPrint('[SyncQueue] Max retries reached for ${action.id} (${action.type.name}). Dropping action.');
        _queue.removeAt(index);
      }
      await _persist();
    }
  }

  /// Clear the entire queue (e.g. on logout).
  Future<void> clear() async {
    _queue.clear();
    _isLoaded = true;
    await JsonFileCache.write(_cacheKey, null);
    debugPrint('[SyncQueue] Cleared sync queue');
  }

  Future<void> _persist() async {
    try {
      await JsonFileCache.write(
        _cacheKey,
        _queue.map((a) => a.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('[SyncQueue] Error saving queue: $e');
    }
  }
}
