import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/session_manager.dart';

/// An HTTP Client wrapper that intercepts 401 Unauthorized / Unauthenticated responses
/// on authenticated endpoints and immediately triggers session expiration & logout.
class SessionInterceptorClient extends http.BaseClient {
  final http.Client _inner;
  final SessionManager _sessionManager;

  SessionInterceptorClient({
    http.Client? inner,
    SessionManager? sessionManager,
  })  : _inner = inner ?? http.Client(),
        _sessionManager = sessionManager ?? SessionManager.instance;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);

    if (response.statusCode == 401) {
      final path = request.url.path.toLowerCase();
      final normalizedPath = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
      // Exclude public/unauthenticated auth flow endpoints where 401 might mean invalid credentials
      final isPublicAuthFlow = normalizedPath.endsWith('/auth/login') ||
          normalizedPath.endsWith('/auth/register') ||
          normalizedPath.endsWith('/auth/forgot-pin') ||
          normalizedPath.endsWith('/auth/verify-code') ||
          normalizedPath.endsWith('/auth/reset-pin') ||
          normalizedPath.contains('/auth/2fa/');

      if (!isPublicAuthFlow) {
        _sessionManager.notifySessionExpired();
      }
    }

    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
