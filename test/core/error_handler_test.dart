import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:creditbook/core/error/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('detects SocketException as network error', () {
      final error = const SocketException('Failed host lookup: creditbook.example.com');
      expect(ErrorHandler.isNetworkError(error), isTrue);
      expect(ErrorHandler.getTitle(error), equals('No Internet Connection'));
      expect(
        ErrorHandler.getFriendlyMessage(error),
        equals('Unable to connect to the server. Please check your internet connection and try again.'),
      );
    });

    test('detects ClientException with connection closed as network error', () {
      final error = http.ClientException(
        'Connection closed before full header was received, uri=https://creditbook.smartapps.com.ng/api/v1/contacts/123',
      );
      expect(ErrorHandler.isNetworkError(error), isTrue);
      expect(ErrorHandler.getTitle(error), equals('No Internet Connection'));
      expect(
        ErrorHandler.getFriendlyMessage(error),
        equals('Unable to connect to the server. Please check your internet connection and try again.'),
      );
    });

    test('detects wrapped string exceptions containing network terms', () {
      const errorStr =
          'Exception: Failed to fetch contact details: ClientException: Connection closed before full header was received, uri=https://creditbook.smartapps.com.ng/api/v1/contacts/019f15d0-ecf4-7148-9bba-51b346431225';
      expect(ErrorHandler.isNetworkError(errorStr), isTrue);
      expect(ErrorHandler.getTitle(errorStr), equals('No Internet Connection'));
      expect(
        ErrorHandler.getFriendlyMessage(errorStr),
        equals('Unable to connect to the server. Please check your internet connection and try again.'),
      );
    });

    test('detects TimeoutException as network error', () {
      final error = TimeoutException('The request timed out');
      expect(ErrorHandler.isNetworkError(error), isTrue);
      expect(ErrorHandler.getTitle(error), equals('No Internet Connection'));
    });

    test('handles 401 unauthorized gracefully', () {
      const error = '401 Unauthorized: Invalid credentials';
      expect(ErrorHandler.isNetworkError(error), isFalse);
      expect(ErrorHandler.isSessionExpired(error), isTrue);
      expect(ErrorHandler.getTitle(error), equals('Session Expired'));
      expect(ErrorHandler.getFriendlyMessage(error), equals('Your session has expired. Please sign in again.'));
    });

    test('handles Sanctum Unauthenticated error gracefully', () {
      const error = 'Exception: Unauthenticated.';
      expect(ErrorHandler.isNetworkError(error), isFalse);
      expect(ErrorHandler.isSessionExpired(error), isTrue);
      expect(ErrorHandler.getTitle(error), equals('Session Expired'));
      expect(ErrorHandler.getFriendlyMessage(error), equals('Your session has expired. Please sign in again.'));
    });


    test('handles 500 server errors gracefully', () {
      const error = '500 Internal Server Error';
      expect(ErrorHandler.isNetworkError(error), isFalse);
      expect(ErrorHandler.getTitle(error), equals('Server Unavailable'));
      expect(
        ErrorHandler.getFriendlyMessage(error),
        equals('The server is temporarily unavailable. Please try again shortly.'),
      );
    });

    test('strips Exception prefix from regular errors without leaking URLs', () {
      const error = 'Exception: Invalid verification code entered.';
      expect(ErrorHandler.isNetworkError(error), isFalse);
      expect(ErrorHandler.getFriendlyMessage(error), equals('Invalid verification code entered.'));
    });

    test('handles null safely', () {
      expect(ErrorHandler.isNetworkError(null), isFalse);
      expect(ErrorHandler.getTitle(null), equals('Something Went Wrong'));
      expect(ErrorHandler.getFriendlyMessage(null), equals('An unexpected error occurred. Please try again.'));
    });
  });
}
