import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/core/services/app_cache_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppCacheManager cacheManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cacheManager = AppCacheManager(sharedPreferences: prefs);
  });

  group('AppCacheManager', () {
    test('put and get store and retrieve values in memory', () {
      cacheManager.put<String>('user_name', 'Alice');
      expect(cacheManager.get<String>('user_name'), 'Alice');
    });

    test('isFresh returns true when unexpired and false when expired', () {
      cacheManager.put<int>('count', 42, ttl: const Duration(milliseconds: 50));
      expect(cacheManager.isFresh('count'), isTrue);
      expect(cacheManager.get<int>('count'), 42);

      // Verify that after TTL expiration, isFresh is false
      cacheManager.put<int>('expired_count', 10, ttl: const Duration(milliseconds: -1));
      expect(cacheManager.isFresh('expired_count'), isFalse);
    });

    test('invalidate removes specific key', () {
      cacheManager.put<String>('token', 'abc123xyz');
      expect(cacheManager.get<String>('token'), 'abc123xyz');

      cacheManager.invalidate('token');
      expect(cacheManager.get<String>('token'), isNull);
    });

    test('invalidatePrefix removes all keys matching prefix', () {
      cacheManager.put('contact_1', 'Alice');
      cacheManager.put('contact_2', 'Bob');
      cacheManager.put('dashboard', 'Overview');

      cacheManager.invalidatePrefix('contact_');
      expect(cacheManager.get('contact_1'), isNull);
      expect(cacheManager.get('contact_2'), isNull);
      expect(cacheManager.get('dashboard'), 'Overview');
    });

    test('invalidateMany removes multiple specific keys', () {
      cacheManager.put('key1', 'v1');
      cacheManager.put('key2', 'v2');
      cacheManager.put('key3', 'v3');

      cacheManager.invalidateMany(['key1', 'key2']);
      expect(cacheManager.get('key1'), isNull);
      expect(cacheManager.get('key2'), isNull);
      expect(cacheManager.get('key3'), 'v3');
    });

    test('clear removes all entries', () {
      cacheManager.put('a', 1);
      cacheManager.put('b', 2);

      cacheManager.clear();
      expect(cacheManager.get('a'), isNull);
      expect(cacheManager.get('b'), isNull);
    });
  });
}
