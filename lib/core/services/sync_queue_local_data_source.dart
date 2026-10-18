import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncItemStatus {
  pending,
  inProgress,
  success,
  failed,
  conflict,
}

class SyncActionItem {
  final String actionType; // e.g. 'CREATE_DEBT', 'RECORD_PAYMENT'
  final Map<String, dynamic> payload;
  final String clientId;
  final String timestamp;
  final SyncItemStatus status;
  final int retryCount;
  final String? lastAttemptAt;
  final String? errorMessage;

  SyncActionItem({
    required this.actionType,
    required this.payload,
    required this.clientId,
    required this.timestamp,
    this.status = SyncItemStatus.pending,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.errorMessage,
  });

  SyncActionItem copyWith({
    String? actionType,
    Map<String, dynamic>? payload,
    String? clientId,
    String? timestamp,
    SyncItemStatus? status,
    int? retryCount,
    String? lastAttemptAt,
    String? errorMessage,
  }) {
    return SyncActionItem(
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      clientId: clientId ?? this.clientId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'action_type': actionType,
        'payload': payload,
        'client_id': clientId,
        'timestamp': timestamp,
        'status': status.name,
        'retry_count': retryCount,
        'last_attempt_at': lastAttemptAt,
        'error_message': errorMessage,
      };

  factory SyncActionItem.fromJson(Map<String, dynamic> json) {
    SyncItemStatus parsedStatus = SyncItemStatus.pending;
    if (json['status'] != null) {
      for (final s in SyncItemStatus.values) {
        if (s.name == json['status']) {
          parsedStatus = s;
          break;
        }
      }
    }

    return SyncActionItem(
      actionType: json['action_type'] ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      clientId: json['client_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      status: parsedStatus,
      retryCount: (json['retry_count'] as int?) ?? 0,
      lastAttemptAt: json['last_attempt_at'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }
}

abstract class SyncQueueLocalDataSource {
  Future<void> enqueueAction(SyncActionItem item);
  Future<List<SyncActionItem>> getQueue();
  Future<List<SyncActionItem>> getPendingActions();
  Future<void> markInProgress(String clientId);
  Future<void> markSuccess(String clientId);
  Future<void> markFailed(String clientId, String errorMessage);
  Future<void> markConflict(String clientId, String errorMessage);
  Future<void> removeFromQueue(String clientId);
  Future<void> clearQueue();
  Future<Map<String, int>> getStats();
}

class SyncQueueLocalDataSourceImpl implements SyncQueueLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _queueKey = 'sync_action_queue';

  SyncQueueLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> enqueueAction(SyncActionItem item) async {
    final queue = await getQueue();
    // Replace if already exists (for idempotency)
    queue.removeWhere((i) => i.clientId == item.clientId);
    queue.add(item);
    await _saveQueue(queue);
  }

  @override
  Future<List<SyncActionItem>> getQueue() async {
    final jsonString = sharedPreferences.getString(_queueKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => SyncActionItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<SyncActionItem>> getPendingActions() async {
    final queue = await getQueue();
    // Items that are pending or failed (eligible for retry)
    return queue.where((i) => i.status == SyncItemStatus.pending || i.status == SyncItemStatus.failed).toList();
  }

  @override
  Future<void> markInProgress(String clientId) async {
    await _updateItem(clientId, (item) => item.copyWith(
      status: SyncItemStatus.inProgress,
      lastAttemptAt: DateTime.now().toIso8601String(),
    ));
  }

  @override
  Future<void> markSuccess(String clientId) async {
    await removeFromQueue(clientId);
  }

  @override
  Future<void> markFailed(String clientId, String errorMessage) async {
    await _updateItem(clientId, (item) => item.copyWith(
      status: SyncItemStatus.failed,
      retryCount: item.retryCount + 1,
      lastAttemptAt: DateTime.now().toIso8601String(),
      errorMessage: errorMessage,
    ));
  }

  @override
  Future<void> markConflict(String clientId, String errorMessage) async {
    await _updateItem(clientId, (item) => item.copyWith(
      status: SyncItemStatus.conflict,
      lastAttemptAt: DateTime.now().toIso8601String(),
      errorMessage: errorMessage,
    ));
  }

  @override
  Future<void> removeFromQueue(String clientId) async {
    final queue = await getQueue();
    queue.removeWhere((item) => item.clientId == clientId);
    await _saveQueue(queue);
  }

  @override
  Future<void> clearQueue() async {
    await sharedPreferences.remove(_queueKey);
  }

  @override
  Future<Map<String, int>> getStats() async {
    final queue = await getQueue();
    int pending = 0;
    int inProgress = 0;
    int failed = 0;
    int conflict = 0;

    for (final item in queue) {
      switch (item.status) {
        case SyncItemStatus.pending:
          pending++;
          break;
        case SyncItemStatus.inProgress:
          inProgress++;
          break;
        case SyncItemStatus.failed:
          failed++;
          break;
        case SyncItemStatus.conflict:
          conflict++;
          break;
        case SyncItemStatus.success:
          break;
      }
    }

    return {
      'pending': pending,
      'in_progress': inProgress,
      'failed': failed,
      'conflict': conflict,
      'total': queue.length,
    };
  }

  Future<void> _updateItem(String clientId, SyncActionItem Function(SyncActionItem) updateFn) async {
    final queue = await getQueue();
    final index = queue.indexWhere((i) => i.clientId == clientId);
    if (index >= 0) {
      queue[index] = updateFn(queue[index]);
      await _saveQueue(queue);
    }
  }

  Future<void> _saveQueue(List<SyncActionItem> queue) async {
    final jsonString = jsonEncode(queue.map((e) => e.toJson()).toList());
    await sharedPreferences.setString(_queueKey, jsonString);
  }
}
