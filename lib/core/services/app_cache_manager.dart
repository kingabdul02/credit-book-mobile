import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a cached entry with its payload, timestamp, and time-to-live.
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  final String? etag;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
    this.etag,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  bool get isFresh => !isExpired;
}

/// Central application cache manager supporting high-speed in-memory caching
/// with optional local storage persistence via [SharedPreferences].
class AppCacheManager {
  final SharedPreferences? _prefs;

  // In-memory cache for 0ms retrieval
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};

  // Default TTL for standard cached responses (3 minutes)
  static const Duration defaultTtl = Duration(minutes: 3);

  AppCacheManager({SharedPreferences? sharedPreferences})
      : _prefs = sharedPreferences;

  /// Store an object in memory cache (and optionally persist as JSON string)
  void put<T>(
    String key,
    T value, {
    Duration? ttl,
    String? etag,
    bool persist = false,
  }) {
    final entry = CacheEntry<T>(
      data: value,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTtl,
      etag: etag,
    );

    _memoryCache[key] = entry;

    if (persist && _prefs != null) {
      try {
        if (value is Map || value is List) {
          _prefs.setString('cache_$key', jsonEncode(value));
          _prefs.setString('cache_${key}_ts', entry.timestamp.toIso8601String());
        }
      } catch (e) {
        debugPrint('⚠️ AppCacheManager: Failed to persist cache for key $key: $e');
      }
    }
  }

  /// Retrieve cached data.
  /// If [allowStale] is true, returns data even if past TTL.
  /// If [allowStale] is false, returns null when expired.
  T? get<T>(String key, {bool allowStale = true}) {
    final entry = _memoryCache[key];
    if (entry != null) {
      if (!allowStale && entry.isExpired) {
        return null;
      }
      return entry.data as T?;
    }
    return null;
  }

  /// Checks if a cache entry exists and is still within its TTL.
  bool isFresh(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return false;
    return entry.isFresh;
  }

  /// Checks if any cache entry exists for the given key (even if stale).
  bool has(String key) => _memoryCache.containsKey(key);

  /// Get the ETag associated with a cached key, if any.
  String? getEtag(String key) => _memoryCache[key]?.etag;

  /// Invalidate a specific cache key.
  void invalidate(String key) {
    _memoryCache.remove(key);
    _prefs?.remove('cache_$key');
    _prefs?.remove('cache_${key}_ts');
  }

  /// Invalidate all cache keys matching a prefix (e.g. 'ledger_', 'insights_').
  void invalidatePrefix(String prefix) {
    final keysToRemove = _memoryCache.keys
        .where((k) => k.startsWith(prefix))
        .toList();
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _prefs?.remove('cache_$key');
      _prefs?.remove('cache_${key}_ts');
    }
  }

  /// Invalidate multiple cache keys at once.
  void invalidateMany(List<String> keys) {
    for (final key in keys) {
      invalidate(key);
    }
  }

  /// Clear the entire memory cache (e.g. on user logout).
  void clear() {
    _memoryCache.clear();
  }
}
