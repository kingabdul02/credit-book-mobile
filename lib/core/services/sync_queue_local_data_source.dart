import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SyncActionItem {
  final String actionType; // e.g. 'CREATE_DEBT', 'RECORD_PAYMENT'
  final Map<String, dynamic> payload;
  final String clientId;
  final String timestamp;

  SyncActionItem({
    required this.actionType,
    required this.payload,
    required this.clientId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'action_type': actionType,
        'payload': payload,
        'client_id': clientId,
        'timestamp': timestamp,
      };

  factory SyncActionItem.fromJson(Map<String, dynamic> json) => SyncActionItem(
        actionType: json['action_type'],
        payload: json['payload'],
        clientId: json['client_id'],
        timestamp: json['timestamp'],
      );
}

abstract class SyncQueueLocalDataSource {
  Future<void> enqueueAction(SyncActionItem item);
  Future<List<SyncActionItem>> getQueue();
  Future<void> removeFromQueue(String clientId);
  Future<void> clearQueue();
}

class SyncQueueLocalDataSourceImpl implements SyncQueueLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _queueKey = 'sync_action_queue';

  SyncQueueLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> enqueueAction(SyncActionItem item) async {
    final queue = await getQueue();
    // Replace if already exists (should be rare, but good for idempotency if retried before sync)
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
      return decoded.map((e) => SyncActionItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
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

  Future<void> _saveQueue(List<SyncActionItem> queue) async {
    final jsonString = jsonEncode(queue.map((e) => e.toJson()).toList());
    await sharedPreferences.setString(_queueKey, jsonString);
  }
}
