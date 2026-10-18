import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:creditbook/core/services/session_manager.dart';
import 'package:creditbook/core/network/session_interceptor_client.dart';

void main() {
  group('SessionInterceptorClient', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager.instance;
      sessionManager.reset();
    });

    test('notifies SessionManager when 401 received on authenticated endpoint', () async {
      bool sessionExpiredFired = false;
      final sub = sessionManager.onSessionExpired.listen((_) {
        sessionExpiredFired = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401);
      });

      final interceptorClient = SessionInterceptorClient(
        inner: mockClient,
        sessionManager: sessionManager,
      );

      final response = await interceptorClient.get(Uri.parse('https://example.com/api/contacts'));

      expect(response.statusCode, equals(401));
      expect(sessionExpiredFired, isTrue);

      await sub.cancel();
    });

    test('does NOT notify SessionManager when 401 received on public auth login', () async {
      bool sessionExpiredFired = false;
      final sub = sessionManager.onSessionExpired.listen((_) {
        sessionExpiredFired = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Invalid credentials'}), 401);
      });

      final interceptorClient = SessionInterceptorClient(
        inner: mockClient,
        sessionManager: sessionManager,
      );

      final response = await interceptorClient.post(Uri.parse('https://example.com/api/auth/login'));

      expect(response.statusCode, equals(401));
      expect(sessionExpiredFired, isFalse);

      await sub.cancel();
    });

    test('does NOT notify SessionManager on 200 OK responses', () async {
      bool sessionExpiredFired = false;
      final sub = sessionManager.onSessionExpired.listen((_) {
        sessionExpiredFired = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'data': []}), 200);
      });

      final interceptorClient = SessionInterceptorClient(
        inner: mockClient,
        sessionManager: sessionManager,
      );

      final response = await interceptorClient.get(Uri.parse('https://example.com/api/contacts'));

      expect(response.statusCode, equals(200));
      expect(sessionExpiredFired, isFalse);

      await sub.cancel();
    });

    test('debounces multiple rapid session expired notifications', () async {
      int fireCount = 0;
      final sub = sessionManager.onSessionExpired.listen((_) {
        fireCount++;
      });

      sessionManager.notifySessionExpired();
      sessionManager.notifySessionExpired();
      sessionManager.notifySessionExpired();

      await Future.delayed(Duration.zero);

      expect(fireCount, equals(1));

      await sub.cancel();
    });
  });
}
