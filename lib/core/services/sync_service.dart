import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'sync_status_model.dart';
import '../di/injection_container.dart';
import 'sync_queue_local_data_source.dart';
import '../error/error_handler.dart';
import '../../features/people/data/datasources/people_remote_data_source.dart';
import '../../features/people/data/datasources/people_local_data_source.dart';
import '../../features/people/domain/entities/contact_entity.dart';
import '../../features/people/domain/repositories/people_repository.dart';

class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Broadcast streams so any screen can listen for sync events
  static final _syncCompleteController = StreamController<SyncStatusModel>.broadcast();
  static Stream<SyncStatusModel> get onSyncComplete => _syncCompleteController.stream;

  static final _syncStatusController = StreamController<SyncStatusModel>.broadcast();
  static Stream<SyncStatusModel> get onSyncStatusChanged => _syncStatusController.stream;

  static bool _isSyncing = false;
  static bool get isSyncing => _isSyncing;

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

  /// Get the real-time sync status, merging local pending/failed queue stats with server status.
  static Future<SyncStatusModel> getStatus() async {
    int localPending = 0;
    int localFailed = 0;

    try {
      final queueDataSource = sl<SyncQueueLocalDataSource>();
      final stats = await queueDataSource.getStats();
      localPending = stats['pending'] ?? 0;
      localFailed = stats['failed'] ?? 0;
    } catch (_) {}

    try {
      final client = sl<http.Client>();
      final response = await client.get(
        Uri.parse('$_baseUrl/sync/status'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final serverModel = SyncStatusModel.fromJson(json);
        final merged = serverModel.copyWith(
          pendingCount: serverModel.pendingCount + localPending,
          failedCount: localFailed,
          isSyncing: _isSyncing,
        );
        _syncStatusController.add(merged);
        return merged;
      }
    } catch (_) {}

    final fallback = SyncStatusModel(
      pendingCount: localPending,
      conflictCount: 0,
      failedCount: localFailed,
      lastSyncedAt: await getLastSyncTimestamp(),
      isSyncing: _isSyncing,
    );
    _syncStatusController.add(fallback);
    return fallback;
  }

  /// Pull changes from server since last sync. Saves the new timestamp locally.
  static Future<SyncStatusModel> pull() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final since = prefs.getString(_lastSyncKey);

      final uri = Uri.parse('$_baseUrl/sync/pull${since != null ? '?since=$since' : ''}');
      final client = sl<http.Client>();
      final response = await client.get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final serverTimestamp = json['server_timestamp'] as String?;
        if (serverTimestamp != null) {
          await prefs.setString(_lastSyncKey, serverTimestamp);
        }

        // If there were server changes, refresh local contacts in background
        final changes = json['changes'] as List?;
        if (changes != null && changes.isNotEmpty) {
          try {
            final peopleRepo = sl<PeopleRepository>();
            await peopleRepo.getPeopleData(forceRefresh: true);
          } catch (_) {}
        }
      }
    } catch (_) {}

    return getStatus();
  }

  /// Push any pending local actions to the server before pulling.
  static Future<void> pushPendingActions() async {
    final queueDataSource = sl<SyncQueueLocalDataSource>();
    final peopleRemote = sl<PeopleRemoteDataSource>();

    final pendingItems = await queueDataSource.getPendingActions();
    if (pendingItems.isEmpty) return;

    for (final item in pendingItems) {
      await queueDataSource.markInProgress(item.clientId);

      try {
        if (item.actionType == 'CREATE_DEBT') {
          final remoteDebt = await peopleRemote.createDebt(item.payload);
          try {
            final contactId = item.payload['contact_id']?.toString() ?? '';
            final prefs = await SharedPreferences.getInstance();
            final userString = prefs.getString('cached_user') ?? prefs.getString('user_profile');
            String? userId = prefs.getString('current_user_id');
            if (userId == null && userString != null) {
              final userMap = jsonDecode(userString);
              userId = userMap['id']?.toString();
            }
            if (userId != null && contactId.isNotEmpty) {
              final peopleLocal = sl<PeopleLocalDataSource>();
              await peopleLocal.addOfflineDebt(userId, contactId, remoteDebt, replaceClientId: item.clientId);
            }
          } catch (_) {}
        } else if (item.actionType == 'RECORD_PAYMENT') {
          await peopleRemote.recordPayment(
            debtId: item.payload['debtId'],
            amount: (item.payload['amount'] as num).toDouble(),
            note: item.payload['note'],
            clientId: item.payload['client_id'] ?? item.clientId,
          );
        }

        // Successfully synced with server
        await queueDataSource.markSuccess(item.clientId);
      } catch (e) {
        final errorStr = e.toString().toLowerCase();

        // 1. Network connectivity failure: halt queue processing to retry once connection is restored
        if (ErrorHandler.isNetworkError(e)) {
          // Revert to pending so it will be retried on next connection restoration
          await queueDataSource.markFailed(item.clientId, 'Network disconnected');
          break;
        }

        // 2. Duplicate / already-processed idempotency check
        if (errorStr.contains('already') ||
            errorStr.contains('client_id') ||
            errorStr.contains('unique') ||
            errorStr.contains('taken')) {
          // The action was already processed on the server (e.g. earlier request reached server before timeout)
          await queueDataSource.markSuccess(item.clientId);
          continue;
        }

        // 3. Other server or validation error: record failure and retry count
        await queueDataSource.markFailed(item.clientId, ErrorHandler.getFriendlyMessage(e));
      }
    }
  }

  /// Trigger a full sync: push pending local changes, pull from server, and broadcast completion.
  static Future<SyncStatusModel> triggerSync() async {
    if (_isSyncing) return getStatus();
    _isSyncing = true;

    // Notify listeners that sync has started
    _syncStatusController.add(SyncStatusModel(
      pendingCount: 0,
      conflictCount: 0,
      isSyncing: true,
      lastSyncedAt: await getLastSyncTimestamp(),
    ));

    try {
      await pushPendingActions();
      final status = await pull();
      _isSyncing = false;
      final finalStatus = status.copyWith(isSyncing: false);
      _syncCompleteController.add(finalStatus);
      _syncStatusController.add(finalStatus);
      return finalStatus;
    } catch (_) {
      _isSyncing = false;
      final fallback = await getStatus();
      _syncCompleteController.add(fallback);
      return fallback;
    }
  }

  static Future<String?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }
}
