import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/contact_entity.dart';

abstract class PeopleLocalDataSource {
  PeopleDataEntity? getPeopleData(String userId);
  Future<void> savePeopleData(String userId, PeopleDataEntity data);
  Future<void> saveContact(String userId, ContactEntity contact);
  Future<void> updateContact(String userId, ContactEntity contact);
  Future<void> deleteContact(String userId, String contactId);
  bool hasFetchedFromServer(String userId);
  Future<void> setFetchedFromServer(String userId, bool value);
  bool needsLoginSync(String userId);
  Future<void> setNeedsLoginSync(String userId, bool value);
  Future<void> clearUserContacts(String userId);
  Future<void> clearAll();
}

class PeopleLocalDataSourceImpl implements PeopleLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _keyPrefix = 'cached_people_data_';
  static const String _fetchedPrefix = 'contacts_fetched_server_';
  static const String _needsLoginSyncPrefix = 'contacts_needs_login_sync_';

  PeopleLocalDataSourceImpl({required this.sharedPreferences});

  String _userKey(String userId) => '$_keyPrefix$userId';
  String _fetchedKey(String userId) => '$_fetchedPrefix$userId';
  String _syncKey(String userId) => '$_needsLoginSyncPrefix$userId';

  @override
  PeopleDataEntity? getPeopleData(String userId) {
    if (userId.isEmpty) return null;
    final jsonStr = sharedPreferences.getString(_userKey(userId));
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PeopleDataEntity.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePeopleData(String userId, PeopleDataEntity data) async {
    if (userId.isEmpty) return;
    final jsonStr = jsonEncode(data.toJson());
    await sharedPreferences.setString(_userKey(userId), jsonStr);
    await sharedPreferences.setBool(_fetchedKey(userId), true);
    await sharedPreferences.setBool(_syncKey(userId), false);
  }

  @override
  bool hasFetchedFromServer(String userId) {
    if (userId.isEmpty) return false;
    return sharedPreferences.getBool(_fetchedKey(userId)) ?? false;
  }

  @override
  Future<void> setFetchedFromServer(String userId, bool value) async {
    if (userId.isEmpty) return;
    await sharedPreferences.setBool(_fetchedKey(userId), value);
  }

  @override
  bool needsLoginSync(String userId) {
    if (userId.isEmpty) return false;
    return sharedPreferences.getBool(_syncKey(userId)) ?? false;
  }

  @override
  Future<void> setNeedsLoginSync(String userId, bool value) async {
    if (userId.isEmpty) return;
    await sharedPreferences.setBool(_syncKey(userId), value);
  }

  @override
  Future<void> saveContact(String userId, ContactEntity contact) async {
    if (userId.isEmpty) return;
    final current = getPeopleData(userId) ?? const PeopleDataEntity(
      favorites: [],
      frequentlyContacted: [],
      allContacts: [],
    );

    // Update allContacts: replace existing or prepend
    final updatedAll = List<ContactEntity>.from(current.allContacts);
    final existingIndex = updatedAll.indexWhere((c) => c.id == contact.id);
    if (existingIndex >= 0) {
      updatedAll[existingIndex] = contact;
    } else {
      updatedAll.insert(0, contact);
    }

    // Update favorites
    final updatedFavs = List<ContactEntity>.from(current.favorites);
    final favIndex = updatedFavs.indexWhere((c) => c.id == contact.id);
    if (contact.isFavorite) {
      if (favIndex >= 0) {
        updatedFavs[favIndex] = contact;
      } else {
        updatedFavs.insert(0, contact);
      }
    } else if (favIndex >= 0) {
      updatedFavs.removeAt(favIndex);
    }

    // Update frequentlyContacted if present
    final updatedFreq = List<ContactEntity>.from(current.frequentlyContacted);
    final freqIndex = updatedFreq.indexWhere((c) => c.id == contact.id);
    if (freqIndex >= 0) {
      updatedFreq[freqIndex] = contact;
    }

    final newEntity = PeopleDataEntity(
      favorites: updatedFavs,
      frequentlyContacted: updatedFreq,
      allContacts: updatedAll,
    );
    await savePeopleData(userId, newEntity);
  }

  @override
  Future<void> updateContact(String userId, ContactEntity contact) async {
    await saveContact(userId, contact);
  }

  @override
  Future<void> deleteContact(String userId, String contactId) async {
    if (userId.isEmpty) return;
    final current = getPeopleData(userId);
    if (current == null) return;

    final updatedAll = current.allContacts.where((c) => c.id != contactId).toList();
    final updatedFavs = current.favorites.where((c) => c.id != contactId).toList();
    final updatedFreq = current.frequentlyContacted.where((c) => c.id != contactId).toList();

    final newEntity = PeopleDataEntity(
      favorites: updatedFavs,
      frequentlyContacted: updatedFreq,
      allContacts: updatedAll,
    );
    await savePeopleData(userId, newEntity);
  }

  @override
  Future<void> clearUserContacts(String userId) async {
    if (userId.isEmpty) return;
    await sharedPreferences.remove(_userKey(userId));
    await sharedPreferences.remove(_fetchedKey(userId));
    await sharedPreferences.remove(_syncKey(userId));
  }

  @override
  Future<void> clearAll() async {
    final keys = sharedPreferences.getKeys().where((k) =>
        k.startsWith(_keyPrefix) ||
        k.startsWith(_fetchedPrefix) ||
        k.startsWith(_needsLoginSyncPrefix)).toList();
    for (final key in keys) {
      await sharedPreferences.remove(key);
    }
  }
}
