import 'dart:async';

/// Central coordinator for user session lifecycle events across the app.
class SessionManager {
  static final SessionManager instance = SessionManager._internal();
  SessionManager._internal();

  final _sessionExpiredController = StreamController<String?>.broadcast();

  /// Stream emitting whenever an authenticated request detects session expiration (401).
  Stream<String?> get onSessionExpired => _sessionExpiredController.stream;

  DateTime? _lastNotificationTime;

  /// Notify all listeners that the session has expired and the app must log the user out.
  void notifySessionExpired([String? reason]) {
    final now = DateTime.now();
    // Debounce to prevent multiple parallel 401 API responses from spamming logout events
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastNotificationTime = now;
    _sessionExpiredController.add(reason);
  }

  /// Reset internal timer (useful for testing)
  void reset() {
    _lastNotificationTime = null;
  }
}
