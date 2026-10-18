import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/core/services/sync_queue_local_data_source.dart';

void main() {
  late SharedPreferences prefs;
  late SyncQueueLocalDataSourceImpl queueDataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    queueDataSource = SyncQueueLocalDataSourceImpl(sharedPreferences: prefs);
  });

  group('SyncQueueLocalDataSource', () {
    test('enqueues and retrieves action items', () async {
      final item = SyncActionItem(
        actionType: 'CREATE_DEBT',
        payload: {'amount': 5000},
        clientId: 'client-1',
        timestamp: DateTime.now().toIso8601String(),
      );

      await queueDataSource.enqueueAction(item);

      final queue = await queueDataSource.getQueue();
      expect(queue.length, 1);
      expect(queue.first.clientId, 'client-1');
      expect(queue.first.actionType, 'CREATE_DEBT');
      expect(queue.first.status, SyncItemStatus.pending);
    });

    test('replaces existing item with same clientId (idempotent enqueue)', () async {
      final item1 = SyncActionItem(
        actionType: 'CREATE_DEBT',
        payload: {'amount': 5000},
        clientId: 'client-1',
        timestamp: '2026-10-18T10:00:00Z',
      );
      final item2 = SyncActionItem(
        actionType: 'CREATE_DEBT',
        payload: {'amount': 7000},
        clientId: 'client-1',
        timestamp: '2026-10-18T10:05:00Z',
      );

      await queueDataSource.enqueueAction(item1);
      await queueDataSource.enqueueAction(item2);

      final queue = await queueDataSource.getQueue();
      expect(queue.length, 1);
      expect(queue.first.payload['amount'], 7000);
    });

    test('markInProgress, markFailed with retry count, markSuccess, and markConflict', () async {
      final item = SyncActionItem(
        actionType: 'RECORD_PAYMENT',
        payload: {'amount': 1000},
        clientId: 'pay-1',
        timestamp: DateTime.now().toIso8601String(),
      );

      await queueDataSource.enqueueAction(item);

      // In progress
      await queueDataSource.markInProgress('pay-1');
      var queue = await queueDataSource.getQueue();
      expect(queue.first.status, SyncItemStatus.inProgress);
      expect(queue.first.lastAttemptAt, isNotNull);

      // Failed
      await queueDataSource.markFailed('pay-1', 'Server timeout');
      queue = await queueDataSource.getQueue();
      expect(queue.first.status, SyncItemStatus.failed);
      expect(queue.first.retryCount, 1);
      expect(queue.first.errorMessage, 'Server timeout');

      // Eligible for retry in getPendingActions
      var pending = await queueDataSource.getPendingActions();
      expect(pending.length, 1);

      // Conflict
      await queueDataSource.markConflict('pay-1', 'Debt balance mismatch');
      queue = await queueDataSource.getQueue();
      expect(queue.first.status, SyncItemStatus.conflict);
      expect(queue.first.errorMessage, 'Debt balance mismatch');

      // Success removes from queue
      await queueDataSource.markSuccess('pay-1');
      queue = await queueDataSource.getQueue();
      expect(queue.isEmpty, true);
    });

    test('getStats correctly tallies pending, in_progress, failed, conflict counts', () async {
      await queueDataSource.enqueueAction(SyncActionItem(
        actionType: 'CREATE_DEBT',
        payload: {},
        clientId: 'c1',
        timestamp: '',
        status: SyncItemStatus.pending,
      ));
      await queueDataSource.enqueueAction(SyncActionItem(
        actionType: 'CREATE_DEBT',
        payload: {},
        clientId: 'c2',
        timestamp: '',
        status: SyncItemStatus.failed,
      ));
      await queueDataSource.enqueueAction(SyncActionItem(
        actionType: 'RECORD_PAYMENT',
        payload: {},
        clientId: 'c3',
        timestamp: '',
        status: SyncItemStatus.conflict,
      ));

      final stats = await queueDataSource.getStats();
      expect(stats['pending'], 1);
      expect(stats['failed'], 1);
      expect(stats['conflict'], 1);
      expect(stats['total'], 3);
    });
  });
}
