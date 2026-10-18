import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/features/people/data/datasources/people_local_data_source.dart';
import 'package:creditbook/features/people/data/datasources/people_remote_data_source.dart';
import 'package:creditbook/features/people/data/models/contact_model.dart';
import 'package:creditbook/features/people/data/models/debt_model.dart';
import 'package:creditbook/features/people/data/repositories/people_repository_impl.dart';
import 'package:creditbook/features/people/domain/entities/contact_entity.dart';
import 'package:creditbook/core/services/sync_queue_local_data_source.dart';
import 'package:creditbook/core/services/app_cache_manager.dart';

class _FakeRemoteDataSource implements PeopleRemoteDataSource {
  int getFavoritesCalls = 0;
  int getFrequentCalls = 0;
  int getAllContactsCalls = 0;

  List<ContactModel> mockFavorites = [];
  List<ContactModel> mockFrequent = [];
  List<ContactModel> mockAllContacts = [];

  @override
  Future<List<ContactModel>> getFavorites() async {
    getFavoritesCalls++;
    return mockFavorites;
  }

  @override
  Future<List<ContactModel>> getFrequentlyContacted() async {
    getFrequentCalls++;
    return mockFrequent;
  }

  @override
  Future<List<ContactModel>> getAllContacts() async {
    getAllContactsCalls++;
    return mockAllContacts;
  }

  @override
  Future<ContactModel> createContact(Map<String, dynamic> data) async {
    final contact = ContactModel(
      id: data['client_id'] ?? 'contact-new',
      fullName: data['full_name'] ?? 'New Person',
      nickname: data['nickname'],
      profilePicture: null,
      isFavorite: data['is_favorite'] == true,
      totalOwedToUser: 0,
      totalUserOwes: 0,
      updatedAt: DateTime.now().toIso8601String(),
    );
    mockAllContacts.add(contact);
    if (contact.isFavorite) mockFavorites.add(contact);
    return contact;
  }

  @override
  Future<ContactModel> updateContact(String id, Map<String, dynamic> data) async {
    final existing = mockAllContacts.firstWhere((c) => c.id == id);
    final updated = ContactModel(
      id: id,
      fullName: data['full_name'] ?? existing.fullName,
      nickname: data['nickname'] ?? existing.nickname,
      profilePicture: existing.profilePicture,
      isFavorite: data['is_favorite'] ?? existing.isFavorite,
      totalOwedToUser: existing.totalOwedToUser,
      totalUserOwes: existing.totalUserOwes,
      updatedAt: DateTime.now().toIso8601String(),
    );
    return updated;
  }

  @override
  Future<void> deleteContact(String id) async {
    mockAllContacts.removeWhere((c) => c.id == id);
    mockFavorites.removeWhere((c) => c.id == id);
    mockFrequent.removeWhere((c) => c.id == id);
  }

  @override
  Future<ContactModel> getContact(String id) async => throw UnimplementedError();

  @override
  Future<DebtModel> createDebt(Map<String, dynamic> data) async => throw UnimplementedError();

  @override
  Future<void> recordPayment({required String debtId, required double amount, String? note}) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getAllDebtsWithStats({String status = 'all'}) async => throw UnimplementedError();
}

class _FakeSyncQueue implements SyncQueueLocalDataSource {
  @override
  Future<void> clearQueue() async {}
  @override
  Future<void> enqueueAction(SyncActionItem item) async {}
  @override
  Future<List<SyncActionItem>> getQueue() async => [];
  @override
  Future<void> removeFromQueue(String clientId) async {}
}

void main() {
  late SharedPreferences prefs;
  late PeopleLocalDataSource localDataSource;
  late _FakeRemoteDataSource remoteDataSource;
  late PeopleRepositoryImpl repository;
  late AppCacheManager cacheManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localDataSource = PeopleLocalDataSourceImpl(sharedPreferences: prefs);
    remoteDataSource = _FakeRemoteDataSource();
    cacheManager = AppCacheManager(sharedPreferences: prefs);
    repository = PeopleRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      syncQueue: _FakeSyncQueue(),
      sharedPreferences: prefs,
      cacheManager: cacheManager,
    );
  });

  group('PeopleLocalDataSource - Storage and Isolation', () {
    test('saves and retrieves contacts partitioned by userId', () async {
      const userA = 'user-a';
      const userB = 'user-b';

      final contactA = ContactEntity(
        id: 'c-1',
        fullName: 'Alice Smith',
        isFavorite: true,
        totalOwedToUser: 100,
        totalUserOwes: 0,
        updatedAt: '2026-10-18T10:00:00Z',
      );

      final contactB = ContactEntity(
        id: 'c-2',
        fullName: 'Bob Jones',
        isFavorite: false,
        totalOwedToUser: 0,
        totalUserOwes: 50,
        updatedAt: '2026-10-18T10:00:00Z',
      );

      await localDataSource.saveContact(userA, contactA);
      await localDataSource.saveContact(userB, contactB);

      // User A contacts
      final dataA = localDataSource.getPeopleData(userA);
      expect(dataA, isNotNull);
      expect(dataA!.allContacts.length, 1);
      expect(dataA.allContacts.first.fullName, 'Alice Smith');
      expect(dataA.favorites.length, 1);

      // User B contacts - must NOT contain Alice Smith
      final dataB = localDataSource.getPeopleData(userB);
      expect(dataB, isNotNull);
      expect(dataB!.allContacts.length, 1);
      expect(dataB.allContacts.first.fullName, 'Bob Jones');
      expect(dataB.favorites, isEmpty);

      // User C (unregistered) - must be null
      expect(localDataSource.getPeopleData('user-c'), isNull);
    });

    test('updates and deletes contacts in local storage immediately', () async {
      const user = 'user-123';
      final contact = ContactEntity(
        id: 'c-10',
        fullName: 'Charlie Brown',
        isFavorite: false,
        totalOwedToUser: 0,
        totalUserOwes: 0,
        updatedAt: '2026-10-18T10:00:00Z',
      );

      await localDataSource.saveContact(user, contact);
      expect(localDataSource.getPeopleData(user)!.allContacts.first.fullName, 'Charlie Brown');

      // Update contact
      final updated = contact.copyWith(fullName: 'Charlie Brown Updated', isFavorite: true);
      await localDataSource.updateContact(user, updated);
      final afterUpdate = localDataSource.getPeopleData(user)!;
      expect(afterUpdate.allContacts.first.fullName, 'Charlie Brown Updated');
      expect(afterUpdate.favorites.length, 1);

      // Delete contact
      await localDataSource.deleteContact(user, 'c-10');
      final afterDelete = localDataSource.getPeopleData(user)!;
      expect(afterDelete.allContacts, isEmpty);
      expect(afterDelete.favorites, isEmpty);
    });
  });

  group('PeopleRepositoryImpl - Offline-First Local Storage & Account Switching', () {
    test('loads from local storage on People screen open without calling server', () async {
      // Simulate User A logged in
      await prefs.setString('current_user_id', 'user-A');
      await prefs.setString('cached_user', '{"id":"user-A","name":"User A"}');

      // Seed remote data
      remoteDataSource.mockAllContacts = [
        const ContactModel(
          id: 'c-1',
          fullName: 'Alice',
          isFavorite: false,
          totalOwedToUser: 0,
          totalUserOwes: 0,
          updatedAt: '2026-10-18T10:00:00Z',
        ),
      ];

      // 1. Initial login / first fetch: calls server and stores in local storage
      final initialData = await repository.getPeopleData();
      expect(initialData.allContacts.length, 1);
      expect(remoteDataSource.getAllContactsCalls, 1);

      // 2. Subsequent screen opens: must read from local storage with NO new server calls
      final secondOpen = await repository.getPeopleData();
      expect(secondOpen.allContacts.length, 1);
      expect(secondOpen.allContacts.first.fullName, 'Alice');
      expect(remoteDataSource.getAllContactsCalls, 1); // NO NEW CALL

      final thirdOpen = await repository.getPeopleData();
      expect(thirdOpen.allContacts.length, 1);
      expect(remoteDataSource.getAllContactsCalls, 1); // STILL NO NEW CALL

      // 3. User manual pull-to-refresh: calls server when forceRefresh is true
      final refreshed = await repository.getPeopleData(forceRefresh: true);
      expect(refreshed.allContacts.length, 1);
      expect(remoteDataSource.getAllContactsCalls, 2);
    });

    test('immediately updates local storage when adding, updating, or deleting a contact', () async {
      await prefs.setString('current_user_id', 'user-A');
      await prefs.setString('cached_user', '{"id":"user-A","name":"User A"}');

      // Create contact
      final created = await repository.createContact({
        'client_id': 'c-new',
        'full_name': 'David Banner',
        'is_favorite': true,
      });

      expect(created.fullName, 'David Banner');

      // Verify immediate local storage reflection
      final localData = repository.getCachedPeopleData();
      expect(localData, isNotNull);
      expect(localData!.allContacts.any((c) => c.id == 'c-new'), isTrue);
      expect(localData.favorites.any((c) => c.id == 'c-new'), isTrue);

      // Update contact
      final updated = await repository.updateContact('c-new', {
        'full_name': 'Bruce Banner',
        'is_favorite': false,
      });
      expect(updated.fullName, 'Bruce Banner');

      final localAfterUpdate = repository.getCachedPeopleData()!;
      expect(localAfterUpdate.allContacts.firstWhere((c) => c.id == 'c-new').fullName, 'Bruce Banner');
      expect(localAfterUpdate.favorites.any((c) => c.id == 'c-new'), isFalse);

      // Delete contact
      await repository.deleteContact('c-new');
      final localAfterDelete = repository.getCachedPeopleData()!;
      expect(localAfterDelete.allContacts.any((c) => c.id == 'c-new'), isFalse);
    });

    test('account switching correctly isolates contacts between different users', () async {
      // User A logs in
      await prefs.setString('current_user_id', 'user-A');
      await prefs.setString('cached_user', '{"id":"user-A","name":"User A"}');
      await repository.createContact({
        'client_id': 'contact-A',
        'full_name': 'User A Contact',
        'is_favorite': true,
      });

      // Verify User A sees contact-A
      expect(repository.getCachedPeopleData()!.allContacts.first.fullName, 'User A Contact');

      // User A logs out and User B logs in
      cacheManager.clear();
      await prefs.remove('current_user_id');
      await prefs.remove('cached_user');

      await prefs.setString('current_user_id', 'user-B');
      await prefs.setString('cached_user', '{"id":"user-B","name":"User B"}');

      // User B has not fetched or created contacts yet: MUST NOT see User A's contacts!
      final userBCached = repository.getCachedPeopleData();
      expect(userBCached, isNull);

      remoteDataSource.mockAllContacts = [
        const ContactModel(
          id: 'contact-B',
          fullName: 'User B Contact',
          isFavorite: false,
          totalOwedToUser: 0,
          totalUserOwes: 0,
          updatedAt: '2026-10-18T10:00:00Z',
        ),
      ];

      // When User B logs in and gets data, only User B's contacts are returned
      final userBData = await repository.getPeopleData();
      expect(userBData.allContacts.length, 1);
      expect(userBData.allContacts.first.fullName, 'User B Contact');
      expect(userBData.allContacts.any((c) => c.fullName == 'User A Contact'), isFalse);

      // Switch back to User A
      cacheManager.clear();
      await prefs.setString('current_user_id', 'user-A');
      await prefs.setString('cached_user', '{"id":"user-A","name":"User A"}');

      // User A's contacts are intact in User A's partition and never contain User B's
      final userAReloaded = repository.getCachedPeopleData()!;
      expect(userAReloaded.allContacts.first.fullName, 'User A Contact');
      expect(userAReloaded.allContacts.any((c) => c.fullName == 'User B Contact'), isFalse);
    });
  });
}
