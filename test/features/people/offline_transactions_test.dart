import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/core/services/app_cache_manager.dart';
import 'package:creditbook/core/services/sync_queue_local_data_source.dart';
import 'package:creditbook/features/people/data/datasources/people_local_data_source.dart';
import 'package:creditbook/features/people/data/datasources/people_remote_data_source.dart';
import 'package:creditbook/features/people/data/models/contact_model.dart';
import 'package:creditbook/features/people/data/models/debt_model.dart';
import 'package:creditbook/features/people/data/models/transaction_model.dart';
import 'package:creditbook/features/people/data/repositories/people_repository_impl.dart';
import 'package:creditbook/features/people/domain/entities/contact_entity.dart';
import 'package:creditbook/features/people/data/models/debt_model.dart';

class _MockRemoteDataSource implements PeopleRemoteDataSource {
  bool shouldFailWithNetworkError = false;
  final List<Map<String, dynamic>> recordedDebts = [];
  final List<Map<String, dynamic>> recordedPayments = [];

  @override
  Future<DebtModel> createDebt(Map<String, dynamic> data) async {
    if (shouldFailWithNetworkError) {
      throw const SocketException('No route to host');
    }
    recordedDebts.add(data);
    return DebtModel(
      id: 'server-debt-${data['client_id']}',
      transactionType: data['transaction_type'] ?? 'THEY_OWE_ME',
      originalAmount: (data['amount'] as num).toDouble(),
      paidAmount: 0.0,
      outstandingAmount: (data['amount'] as num).toDouble(),
      progressPercentage: 0.0,
      status: 'pending',
      transactions: [],
    );
  }

  @override
  Future<void> recordPayment({
    required String debtId,
    required double amount,
    String? note,
    String? clientId,
    String? contactId,
  }) async {
    if (shouldFailWithNetworkError) {
      throw const SocketException('Network unreachable');
    }
    recordedPayments.add({
      'debtId': debtId,
      'amount': amount,
      'note': note,
      'clientId': clientId,
      'contactId': contactId,
    });
  }

  @override
  Future<ContactModel> getContact(String id) async {
    if (shouldFailWithNetworkError) {
      throw const SocketException('Network unreachable');
    }
    return ContactModel(
      id: id,
      fullName: 'Test Contact',
      totalOwedToUser: 0.0,
      totalUserOwes: 0.0,
      isFavorite: false,
      updatedAt: DateTime.now().toIso8601String(),
      debts: [],
    );
  }

  @override
  Future<List<ContactModel>> getAllContacts() async => [];
  @override
  Future<List<ContactModel>> getFavorites() async => [];
  @override
  Future<List<ContactModel>> getFrequentlyContacted() async => [];
  @override
  Future<ContactModel> createContact(Map<String, dynamic> data) async => throw UnimplementedError();
  @override
  Future<ContactModel> updateContact(String id, Map<String, dynamic> data) async => throw UnimplementedError();
  @override
  Future<void> deleteContact(String id) async {}
  @override
  Future<Map<String, dynamic>> getAllDebtsWithStats({String status = 'all'}) async => throw UnimplementedError();
}

void main() {
  late SharedPreferences prefs;
  late PeopleLocalDataSource localDataSource;
  late _MockRemoteDataSource remoteDataSource;
  late SyncQueueLocalDataSourceImpl syncQueue;
  late AppCacheManager cacheManager;
  late PeopleRepositoryImpl repository;

  const testUserId = 'user-abc-123';
  const testContactId = 'contact-xyz-789';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'cached_user': '{"id":"$testUserId","name":"Test User"}',
      'current_user_id': testUserId,
    });
    prefs = await SharedPreferences.getInstance();
    localDataSource = PeopleLocalDataSourceImpl(sharedPreferences: prefs);
    remoteDataSource = _MockRemoteDataSource();
    syncQueue = SyncQueueLocalDataSourceImpl(sharedPreferences: prefs);
    cacheManager = AppCacheManager(sharedPreferences: prefs);

    repository = PeopleRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      sharedPreferences: prefs,
      syncQueue: syncQueue,
      cacheManager: cacheManager,
    );

    // Seed local storage with an initial contact
    final initialContact = ContactModel(
      id: testContactId,
      fullName: 'John Doe',
      totalOwedToUser: 0.0,
      totalUserOwes: 0.0,
      isFavorite: false,
      updatedAt: DateTime.now().toIso8601String(),
      debts: [],
    );
    await localDataSource.saveContact(testUserId, initialContact);
  });

  group('Offline-First Transactions & Auto-Sync Queue', () {
    test('creates debt while offline, updates local storage and enqueues sync action', () async {
      remoteDataSource.shouldFailWithNetworkError = true;

      final debt = await repository.createDebt({
        'contact_id': testContactId,
        'amount': 25000.0,
        'transaction_type': 'THEY_OWE_ME',
        'note': 'Lent cash for supplies',
        'client_id': 'debt-client-uuid-1',
      });

      // 1. Debt should be returned immediately without throwing exception
      expect(debt, isNotNull);
      expect(debt.originalAmount, 25000.0);
      expect(debt.id, 'debt-client-uuid-1');

      // 2. Local contact balances should be updated immediately on device
      final localContact = localDataSource.getContactById(testUserId, testContactId);
      expect(localContact, isNotNull);
      expect(localContact!.totalOwedToUser, 25000.0);
      expect(localContact.debts, isNotNull);
      expect(localContact.debts!.length, 1);

      // 3. Sync action item should be enqueued into SyncQueueLocalDataSource
      final pendingActions = await syncQueue.getPendingActions();
      expect(pendingActions.length, 1);
      expect(pendingActions.first.actionType, 'CREATE_DEBT');
      expect(pendingActions.first.clientId, 'debt-client-uuid-1');
      expect(pendingActions.first.payload['amount'], 25000.0);
    });

    test('records payment while offline, immediately updates balances and enqueues payment sync', () async {
      // First, seed debt locally
      await localDataSource.addOfflineDebt(
        testUserId,
        testContactId,
        DebtModel(
          id: 'debt-client-uuid-1',
          transactionType: 'THEY_OWE_ME',
          originalAmount: 25000.0,
          paidAmount: 0.0,
          outstandingAmount: 25000.0,
          progressPercentage: 0.0,
          status: 'pending',
          transactions: [],
        ),
      );

      // Disconnect network
      remoteDataSource.shouldFailWithNetworkError = true;

      // Record 10,000 partial payment
      await repository.recordPayment(
        debtId: 'debt-client-uuid-1',
        amount: 10000.0,
        note: 'Partial cash payment',
        contactId: testContactId,
        clientId: 'pay-client-uuid-1',
      );

      // 1. Local contact balance must be decremented immediately
      final updatedContact = localDataSource.getContactById(testUserId, testContactId);
      expect(updatedContact, isNotNull);
      expect(updatedContact!.totalOwedToUser, 15000.0); // 25,000 - 10,000

      // 2. Debt in local contact must reflect payment transaction
      final debt = updatedContact.debts!.first as DebtEntity;
      expect(debt.paidAmount, 10000.0);
      expect(debt.outstandingAmount, 15000.0);
      expect(debt.transactions.length, 1);
      expect(debt.transactions.first.amount, 10000.0);

      // 3. Sync queue must contain RECORD_PAYMENT item
      final pending = await syncQueue.getPendingActions();
      expect(pending.length, 1);
      expect(pending.first.actionType, 'RECORD_PAYMENT');
      expect(pending.first.clientId, 'pay-client-uuid-1');
      expect(pending.first.payload['amount'], 10000.0);
    });

    test('prevents duplicate payment recording on retry with same clientId', () async {
      await localDataSource.addOfflineDebt(
        testUserId,
        testContactId,
        DebtModel(
          id: 'debt-100',
          transactionType: 'THEY_OWE_ME',
          originalAmount: 50000.0,
          paidAmount: 0.0,
          outstandingAmount: 50000.0,
          progressPercentage: 0.0,
          status: 'pending',
          transactions: [],
        ),
      );

      final txn = TransactionModel(
        id: 'dup-pay-id',
        type: 'payment',
        amount: 20000.0,
        note: 'Bank transfer',
        createdAt: DateTime.now().toIso8601String(),
      );

      // First application
      await localDataSource.addOfflinePayment(testUserId, testContactId, 'debt-100', txn);
      var contact = localDataSource.getContactById(testUserId, testContactId);
      expect(contact!.totalOwedToUser, 30000.0);

      // Second application with SAME transaction ID (replay)
      await localDataSource.addOfflinePayment(testUserId, testContactId, 'debt-100', txn);
      contact = localDataSource.getContactById(testUserId, testContactId);
      // Balance must NOT be subtracted twice
      expect(contact!.totalOwedToUser, 30000.0);
      final debt = contact.debts!.first as DebtEntity;
      expect(debt.transactions.length, 1);
    });

    test('replaces optimistic debt with remoteDebt without double-counting', () async {
      // 1. Optimistic creation
      final optimisticDebt = DebtModel(
        id: 'opt-client-id-99',
        transactionType: 'THEY_OWE_ME',
        originalAmount: 15000.0,
        paidAmount: 0.0,
        outstandingAmount: 15000.0,
        progressPercentage: 0.0,
        status: 'pending_sync',
        transactions: [],
      );
      await localDataSource.addOfflineDebt(testUserId, testContactId, optimisticDebt);
      var contact = localDataSource.getContactById(testUserId, testContactId);
      expect(contact!.totalOwedToUser, 15000.0);

      // 2. Server responds with official server debt
      final serverDebt = DebtModel(
        id: 'server-debt-id-555',
        transactionType: 'THEY_OWE_ME',
        originalAmount: 15000.0,
        paidAmount: 0.0,
        outstandingAmount: 15000.0,
        progressPercentage: 0.0,
        status: 'active',
        transactions: [],
      );
      await localDataSource.addOfflineDebt(testUserId, testContactId, serverDebt, replaceClientId: 'opt-client-id-99');

      contact = localDataSource.getContactById(testUserId, testContactId);
      // Balance remains 15000.0 (not 30000.0)
      expect(contact!.totalOwedToUser, 15000.0);
      // Replaced debt in list
      expect(contact.debts!.length, 1);
      final resolved = contact.debts!.first as DebtEntity;
      expect(resolved.id, 'server-debt-id-555');
    });
  });
}
