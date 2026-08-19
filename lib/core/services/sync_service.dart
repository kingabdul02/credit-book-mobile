import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'sync_status_model.dart';
import '../di/injection_container.dart';
import 'sync_queue_local_data_source.dart';
import '../../features/people/data/datasources/people_remote_data_source.dart';

class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Broadcast stream so any screen can listen for sync completion events
  static final _syncController = StreamController<SyncStatusModel>.broadcast();
  static Stream<SyncStatusModel> get onSyncComplete => _syncController.stream;

  static String get _baseUrl => dotenv.env['API_BASE_URL']!;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get the real-time sync status from the server.
  static Future<SyncStatusModel> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sync/status'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SyncStatusModel.fromJson(json);
      }
    } catch (_) {}
    return SyncStatusModel.empty;
  }

  /// Pull changes from server since last sync. Saves the new timestamp locally.
  static Future<SyncStatusModel> pull() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final since = prefs.getString(_lastSyncKey);

      final uri = Uri.parse('$_baseUrl/sync/pull${since != null ? '?since=$since' : ''}');
      final response = await http.get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final serverTimestamp = json['server_timestamp'] as String?;
        if (serverTimestamp != null) {
          await prefs.setString(_lastSyncKey, serverTimestamp);
        }
      }
    } catch (_) {}

    return getStatus();
  }

  /// Push any pending local actions to the server before pulling.
  static Future<void> pushPendingActions() async {
    final queueDataSource = sl<SyncQueueLocalDataSource>();
    final peopleRemote = sl<PeopleRemoteDataSource>();

    final queue = await queueDataSource.getQueue();
    if (queue.isEmpty) return;

    for (final item in queue) {
      try {
        if (item.actionType == 'CREATE_DEBT') {
          await peopleRemote.createDebt(item.payload);
        } else if (item.actionType == 'RECORD_PAYMENT') {
          await peopleRemote.recordPayment(
            debtId: item.payload['debtId'],
            amount: item.payload['amount'],
            note: item.payload['note'],
          );
        }
        // Action succeeded, remove from queue
        await queueDataSource.removeFromQueue(item.clientId);
      } catch (e) {
        // If it's a network error, we'll just stop pushing and wait for the next time
        if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
          break; // Stop processing the queue if we're offline
        }
        // If it's a 400 or other logical error from the server, we should probably still remove it
        // so it doesn't block the queue forever, or mark it as failed. For now, we'll remove it.
        await queueDataSource.removeFromQueue(item.clientId);
      }
    }
  }

  /// Trigger a full sync: push, pull from server, then broadcast completion.
  static Future<SyncStatusModel> triggerSync() async {
    await pushPendingActions();
    final status = await pull();
    _syncController.add(status);
    return status;
  }

  static Future<String?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }
}
