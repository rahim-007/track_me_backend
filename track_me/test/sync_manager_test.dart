import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/core/sync/sync_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncQueue Tests', () {
    test('SyncAction serialization and deserialization', () {
      final action = SyncAction(
        id: 'action_1',
        type: SyncActionType.createHabit,
        endpoint: '/habits',
        method: 'POST',
        payload: {'name': 'Meditation', 'color': '#FF0000'},
        tempId: 'temp_123',
      );

      final json = action.toJson();
      final restored = SyncAction.fromJson(json);

      expect(restored.id, 'action_1');
      expect(restored.type, SyncActionType.createHabit);
      expect(restored.endpoint, '/habits');
      expect(restored.method, 'POST');
      expect(restored.payload?['name'], 'Meditation');
      expect(restored.tempId, 'temp_123');
      expect(restored.retryCount, 0);
    });

    test('enqueue, peek, and remove work cleanly', () async {
      final queue = SyncQueue.instance;
      await queue.clear();
      expect(queue.isEmpty, isTrue);

      final action = SyncAction(
        id: 'test_action',
        type: SyncActionType.toggleHabit,
        endpoint: '/habit-logs',
        method: 'POST',
        payload: {'habitId': 'h1', 'date': '2026-08-31'},
      );

      await queue.enqueue(action);
      expect(queue.length, 1);
      expect(queue.items.first.id, 'test_action');

      await queue.incrementRetry('test_action');
      expect(queue.items.first.retryCount, 1);

      await queue.remove('test_action');
      expect(queue.isEmpty, isTrue);
    });

    test('profile updates deduplicate in queue', () async {
      final queue = SyncQueue.instance;
      await queue.clear();

      final action1 = SyncAction(
        id: 'profile_1',
        type: SyncActionType.updateProfile,
        endpoint: '/users/me',
        method: 'PATCH',
        payload: {'name': 'Name 1'},
      );

      final action2 = SyncAction(
        id: 'profile_2',
        type: SyncActionType.updateProfile,
        endpoint: '/users/me',
        method: 'PATCH',
        payload: {'name': 'Name 2'},
      );

      await queue.enqueue(action1);
      await queue.enqueue(action2);

      expect(queue.length, 1);
      expect(queue.items.first.payload?['name'], 'Name 2');
    });
  });
}
