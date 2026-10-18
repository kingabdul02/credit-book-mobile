import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../di/injection_container.dart';
import 'sync_service.dart';
import 'sync_queue_local_data_source.dart';

/// Central manager for tracking device network connectivity and triggering
/// automatic background data synchronization when connectivity is restored.
class ConnectivityManager with WidgetsBindingObserver {
  static final ConnectivityManager instance = ConnectivityManager._internal();
  ConnectivityManager._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  Timer? _periodicCheckTimer;
  bool _isChecking = false;
  bool _isInitialized = false;

  /// Initializes lifecycle observation and periodic background connectivity checks.
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check connectivity and sync pending items immediately when user returns to app
      checkConnectivity();
    }
  }

  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    // Check frequently (every 15s) when pending items are waiting, or every 60s idle
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await checkConnectivity();
    });
  }

  /// Manually or automatically check server reachability.
  Future<bool> checkConnectivity() async {
    if (_isChecking) return _isOnline;
    _isChecking = true;

    try {
      final baseUrl = dotenv.env['API_BASE_URL'];
      if (baseUrl == null || baseUrl.isEmpty) {
        _isChecking = false;
        return _isOnline;
      }

      final uri = Uri.parse('$baseUrl/sync/status');
      // Low timeout for quick liveness detection
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      // Any HTTP response (even 401 unauthenticated) means the server is reachable
      final wasOffline = !_isOnline;
      _isOnline = true;

      if (wasOffline) {
        _connectivityController.add(true);
        // Network connection just restored! Automatically trigger synchronization!
        _triggerAutoSync();
      } else {
        // If we have pending actions in the queue, sync them automatically
        _checkAndSyncPending();
      }
    } catch (_) {
      // Timeout, SocketException, etc.
      if (_isOnline) {
        _isOnline = false;
        _connectivityController.add(false);
      }
    } finally {
      _isChecking = false;
    }

    return _isOnline;
  }

  /// Called by HTTP interceptors whenever any authenticated request succeeds.
  void notifyOnline() {
    final wasOffline = !_isOnline;
    _isOnline = true;
    if (wasOffline) {
      _connectivityController.add(true);
      _triggerAutoSync();
    } else {
      _checkAndSyncPending();
    }
  }

  /// Called by HTTP interceptors or repositories when a network error is encountered.
  void notifyOffline() {
    if (_isOnline) {
      _isOnline = false;
      _connectivityController.add(false);
    }
  }

  Future<void> _checkAndSyncPending() async {
    try {
      final queueDataSource = sl<SyncQueueLocalDataSource>();
      final pending = await queueDataSource.getPendingActions();
      if (pending.isNotEmpty) {
        _triggerAutoSync();
      }
    } catch (_) {}
  }

  void _triggerAutoSync() {
    // Run sync in the background without blocking the caller
    Future.microtask(() async {
      try {
        await SyncService.triggerSync();
      } catch (_) {}
    });
  }

  void dispose() {
    _periodicCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }
}
