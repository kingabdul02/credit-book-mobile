import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ErrorHandler {
  /// Detects whether an error or exception is caused by a network/connectivity issue.
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;

    if (error is SocketException ||
        error is http.ClientException ||
        error is TimeoutException ||
        error is HttpException ||
        error is HandshakeException ||
        error is TlsException) {
      return true;
    }

    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('clientexception') ||
        str.contains('connection closed') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable') ||
        str.contains('connection refused') ||
        str.contains('connection reset') ||
        str.contains('connection timed out') ||
        str.contains('timed out') ||
        str.contains('no internet') ||
        str.contains('network error') ||
        str.contains('software caused connection abort') ||
        str.contains('no address associated with hostname') ||
        str.contains('httpexception') ||
        str.contains('handshakeexception');
  }

  /// Returns a short, user-friendly title for the error.
  static String getTitle(dynamic error) {
    if (isNetworkError(error)) {
      return 'No Internet Connection';
    }

    final str = error?.toString().toLowerCase() ?? '';
    if (str.contains('401') || str.contains('unauthorized')) {
      return 'Session Expired';
    }
    if (str.contains('403') || str.contains('forbidden')) {
      return 'Access Denied';
    }
    if (str.contains('404') || str.contains('not found')) {
      return 'Not Found';
    }
    if (str.contains('500') ||
        str.contains('502') ||
        str.contains('503') ||
        str.contains('504') ||
        str.contains('server error')) {
      return 'Server Unavailable';
    }

    return 'Something Went Wrong';
  }

  /// Returns a clean, human-readable error description without technical jargon or stack traces.
  static String getFriendlyMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    if (isNetworkError(error)) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return 'The requested resource could not be found.';
    }
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('server error')) {
      return 'The server is temporarily unavailable. Please try again shortly.';
    }

    // Clean technical wrappers like "Exception: ", "ClientException: ", "Error: "
    var cleaned = raw
        .replaceAll(RegExp(r'^(Exception:\s*)+', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(Error:\s*)+', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(ClientException:\s*)+', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(FormatException:\s*)+', caseSensitive: false), '')
        .trim();

    // If string still contains technical error traces or raw URLs, avoid leaking them
    if (cleaned.contains('http://') ||
        cleaned.contains('https://') ||
        cleaned.contains('uri=') ||
        cleaned.contains('Stack trace:') ||
        cleaned.contains('#0 ') ||
        cleaned.contains('OS Error:')) {
      // If it started with a friendly prefix before the colon, keep just the prefix
      final firstColon = cleaned.indexOf(':');
      if (firstColon > 0 && firstColon < cleaned.length - 1) {
        final prefix = cleaned.substring(0, firstColon).trim();
        if (!prefix.toLowerCase().contains('exception') &&
            !prefix.toLowerCase().contains('error') &&
            prefix.length > 5) {
          return prefix;
        }
      }
      return 'Unable to complete the request. Please try again.';
    }

    if (cleaned.isEmpty || cleaned.toLowerCase() == 'exception') {
      return 'Something went wrong. Please try again.';
    }

    return cleaned;
  }
}
