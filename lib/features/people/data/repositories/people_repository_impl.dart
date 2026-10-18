import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/debt_with_contact_entity.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/repositories/people_repository.dart';
import '../datasources/people_remote_data_source.dart';
import '../datasources/people_local_data_source.dart';
import '../../../../core/services/sync_queue_local_data_source.dart';
import '../../../../core/services/app_cache_manager.dart';
import '../../../../core/services/connectivity_manager.dart';
import '../../../../core/error/error_handler.dart';
import '../../../home/domain/entities/dashboard_entities.dart';
import '../../../home/data/models/dashboard_models.dart' show DashboardDataModel;

class PeopleRepositoryImpl implements PeopleRepository {
  final PeopleRemoteDataSource remoteDataSource;
  final PeopleLocalDataSource localDataSource;
  final SyncQueueLocalDataSource syncQueue;
  final SharedPreferences sharedPreferences;
  final AppCacheManager? cacheManager;

  static const String peopleCacheKey = 'people_data';

  PeopleRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncQueue,
    required this.sharedPreferences,
    this.cacheManager,
  });

  String? get currentUserId {
    final userJson = sharedPreferences.getString('cached_user') ?? sharedPreferences.getString('user_profile');
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        final id = decoded['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
      } catch (_) {}
    }
    final direct = sharedPreferences.getString('current_user_id');
    if (direct != null && direct.isNotEmpty) return direct;

    return null;
  }

  @override
  PeopleDataEntity? getCachedPeopleData() {
    final userId = currentUserId;
    if (userId == null) return null;
    final memoryKey = '${peopleCacheKey}_$userId';
    final memory = cacheManager?.get<PeopleDataEntity>(memoryKey);
    if (memory != null) return memory;

    final local = localDataSource.getPeopleData(userId);
    if (local != null) {
      cacheManager?.put<PeopleDataEntity>(memoryKey, local);
      return local;
    }
    return null;
  }

  @override
  DebtsWithStatistics? getCachedAllDebtsWithStats({String status = 'all'}) {
    final cached = cacheManager?.get<DebtsWithStatistics>('all_debts_$status');
    if (cached != null) return cached;
    return _buildDebtsFromLocalStorage(status);
  }

  @override
  ContactEntity? getCachedContactDetails(String id) {
    final memory = cacheManager?.get<ContactEntity>('contact_$id');
    if (memory != null) return memory;
    final userId = currentUserId;
    if (userId != null) {
      final local = localDataSource.getContactById(userId, id);
      if (local != null) {
        cacheManager?.put<ContactEntity>('contact_$id', local);
        return local;
      }
    }
    return null;
  }

  @override
  Future<PeopleDataEntity> getPeopleData({bool forceRefresh = false}) async {
    final userId = currentUserId;
    if (userId == null) {
      return const PeopleDataEntity(favorites: [], frequentlyContacted: [], allContacts: []);
    }

    final memoryKey = '${peopleCacheKey}_$userId';
    final localData = localDataSource.getPeopleData(userId);
    final hasFetched = localDataSource.hasFetchedFromServer(userId);
    final needsSync = localDataSource.needsLoginSync(userId);

    // If contacts already exist in local storage and no forced refresh or login sync is required,
    // LOAD DIRECTLY FROM LOCAL STORAGE WITHOUT CALLING THE SERVER
    if (!forceRefresh && !needsSync && hasFetched && localData != null) {
      cacheManager?.put<PeopleDataEntity>(memoryKey, localData);
      return localData;
    }

    // Fast path: if offline, return local data immediately without waiting for server
    if (!ConnectivityManager.instance.isOnline && localData != null) {
      cacheManager?.put<PeopleDataEntity>(memoryKey, localData);
      return localData;
    }

    // Call server only on login sync, first-time fetch for this user, or manual forceRefresh
    try {
      final results = await Future.wait([
        remoteDataSource.getFavorites(),
        remoteDataSource.getFrequentlyContacted(),
        remoteDataSource.getAllContacts(),
      ]);

      final data = PeopleDataEntity(
        favorites: results[0],
        frequentlyContacted: results[1],
        allContacts: results[2],
      );

      await localDataSource.savePeopleData(userId, data);
      cacheManager?.put<PeopleDataEntity>(memoryKey, data);

      return data;
    } catch (e) {
      if (localData != null) return localData;
      throw Exception('Failed to fetch people data: $e');
    }
  }

  @override
  Future<void> syncContactsOnLogin(String userId) async {
    if (userId.isEmpty) return;
    await localDataSource.setNeedsLoginSync(userId, true);
    try {
      final results = await Future.wait([
        remoteDataSource.getFavorites(),
        remoteDataSource.getFrequentlyContacted(),
        remoteDataSource.getAllContacts(),
      ]);

      final data = PeopleDataEntity(
        favorites: results[0],
        frequentlyContacted: results[1],
        allContacts: results[2],
      );

      await localDataSource.savePeopleData(userId, data);
      cacheManager?.put<PeopleDataEntity>('${peopleCacheKey}_$userId', data);
    } catch (_) {
      // Retain sync flag if network error happens on login sync
    }
  }

  @override
  Future<ContactEntity> createContact(Map<String, dynamic> data) async {
    try {
      final contact = await remoteDataSource.createContact(data);
      final userId = currentUserId;
      if (userId != null) {
        await localDataSource.saveContact(userId, contact);
        final updatedData = localDataSource.getPeopleData(userId);
        if (updatedData != null) {
          cacheManager?.put<PeopleDataEntity>('${peopleCacheKey}_$userId', updatedData);
        }
      }
      // Invalidate relevant caches on mutation
      _invalidateTransactionCaches(null);
      return contact;
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  @override
  Future<ContactEntity> updateContact(String id, Map<String, dynamic> data) async {
    try {
      final contact = await remoteDataSource.updateContact(id, data);
      final userId = currentUserId;
      if (userId != null) {
        await localDataSource.updateContact(userId, contact);
        final updatedData = localDataSource.getPeopleData(userId);
        if (updatedData != null) {
          cacheManager?.put<PeopleDataEntity>('${peopleCacheKey}_$userId', updatedData);
        }
      }
      _invalidateTransactionCaches(id);
      return contact;
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    try {
      await remoteDataSource.deleteContact(id);
      final userId = currentUserId;
      if (userId != null) {
        await localDataSource.deleteContact(userId, id);
        final updatedData = localDataSource.getPeopleData(userId);
        if (updatedData != null) {
          cacheManager?.put<PeopleDataEntity>('${peopleCacheKey}_$userId', updatedData);
        }
      }
      _invalidateTransactionCaches(id);
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  @override
  Future<ContactEntity> getContactDetails(String id, {bool forceRefresh = false}) async {
    final userId = currentUserId;
    final cacheKey = 'contact_$id';

    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(cacheKey)) {
      final cached = cacheManager!.get<ContactEntity>(cacheKey);
      if (cached != null) return cached;
    }

    ContactEntity? localContact;
    if (userId != null) {
      localContact = localDataSource.getContactById(userId, id);
    }

    // Fast path: if offline, return local contact immediately without waiting on network
    if (!ConnectivityManager.instance.isOnline && localContact != null) {
      cacheManager?.put<ContactEntity>(cacheKey, localContact);
      return localContact;
    }

    try {
      final contact = await remoteDataSource.getContact(id);
      if (userId != null) {
        await localDataSource.saveContactDetails(userId, contact);
      }
      cacheManager?.put<ContactEntity>(
        cacheKey,
        contact,
        ttl: const Duration(minutes: 2),
      );
      return contact;
    } catch (e) {
      if (ErrorHandler.isNetworkError(e) && localContact != null) {
        cacheManager?.put<ContactEntity>(cacheKey, localContact);
        return localContact;
      }
      final stale = cacheManager?.get<ContactEntity>(cacheKey);
      if (stale != null) return stale;
      if (localContact != null) return localContact;
      throw Exception('Failed to fetch contact details: $e');
    }
  }

  @override
  Future<DebtEntity> createDebt(Map<String, dynamic> data) async {
    final userId = currentUserId;
    final contactId = data['contact_id']?.toString() ?? '';
    final clientId = data['client_id']?.toString() ?? const Uuid().v4();
    final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final String type = data['transaction_type']?.toString() ?? 'THEY_OWE_ME';
    final String? note = data['note']?.toString();
    final String transactionClientId = data['transaction_client_id']?.toString() ?? '$clientId-initial';

    final initialTxn = TransactionModel(
      id: transactionClientId,
      type: 'debt_issuance',
      amount: amount,
      note: note ?? 'Debt recorded',
      createdAt: DateTime.now().toIso8601String(),
    );

    final localDebt = DebtModel(
      id: clientId,
      transactionType: type,
      originalAmount: amount,
      paidAmount: 0.0,
      outstandingAmount: amount,
      progressPercentage: 0.0,
      status: 'pending_sync',
      transactions: [initialTxn],
    );

    // 1. Apply to local database immediately so UI updates without any delay
    ContactEntity? updatedContact;
    if (userId != null && contactId.isNotEmpty) {
      await localDataSource.addOfflineDebt(userId, contactId, localDebt);
      updatedContact = localDataSource.getContactById(userId, contactId);
      if (updatedContact != null) {
        cacheManager?.put<ContactEntity>('contact_$contactId', updatedContact);
      }
      _updateLocalDashboardWithDebt(localDebt, updatedContact);
    }

    // Fast path: if device is offline, enqueue immediately without waiting for HTTP socket timeout
    if (!ConnectivityManager.instance.isOnline) {
      await syncQueue.enqueueAction(
        SyncActionItem(
          actionType: 'CREATE_DEBT',
          payload: data,
          clientId: clientId,
          timestamp: DateTime.now().toIso8601String(),
          status: SyncItemStatus.pending,
        ),
      );
      _invalidateNonContactCaches();
      return localDebt;
    }

    try {
      final remoteDebt = await remoteDataSource.createDebt(data);
      if (userId != null && contactId.isNotEmpty) {
        await localDataSource.addOfflineDebt(userId, contactId, remoteDebt, replaceClientId: clientId);
        final refreshedContact = localDataSource.getContactById(userId, contactId);
        if (refreshedContact != null) {
          cacheManager?.put<ContactEntity>('contact_$contactId', refreshedContact);
        }
      }
      _invalidateNonContactCaches();
      return remoteDebt;
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        await syncQueue.enqueueAction(
          SyncActionItem(
            actionType: 'CREATE_DEBT',
            payload: data,
            clientId: clientId,
            timestamp: DateTime.now().toIso8601String(),
            status: SyncItemStatus.pending,
          ),
        );
        _invalidateNonContactCaches();
        return localDebt;
      }
      throw Exception('Failed to create debt: $e');
    }
  }

  @override
  Future<void> recordPayment({
    required String debtId,
    required double amount,
    String? note,
    String? contactId,
    String? clientId,
  }) async {
    final userId = currentUserId;
    final paymentClientId = clientId ?? const Uuid().v4();

    final localPaymentTxn = TransactionModel(
      id: paymentClientId,
      type: 'payment',
      amount: amount,
      note: note ?? 'Payment',
      createdAt: DateTime.now().toIso8601String(),
    );

    String resolvedContactId = contactId ?? '';
    if (resolvedContactId.isEmpty && userId != null) {
      final allData = localDataSource.getPeopleData(userId);
      if (allData != null) {
        for (final c in allData.allContacts) {
          if (c.debts != null &&
              c.debts!.any((d) =>
                  (d is DebtEntity && d.id == debtId) ||
                  (d is Map && d['id'] == debtId))) {
            resolvedContactId = c.id;
            break;
          }
        }
      }
    }

    // 1. Apply locally right away
    if (userId != null && resolvedContactId.isNotEmpty) {
      await localDataSource.addOfflinePayment(
        userId,
        resolvedContactId,
        debtId,
        localPaymentTxn,
      );
      final updatedContact = localDataSource.getContactById(userId, resolvedContactId);
      if (updatedContact != null) {
        cacheManager?.put<ContactEntity>('contact_$resolvedContactId', updatedContact);
      }
      _updateLocalDashboardWithPayment(localPaymentTxn, resolvedContactId);
    }

    // Fast path: if device is offline, enqueue immediately without waiting for HTTP socket timeout
    if (!ConnectivityManager.instance.isOnline) {
      await syncQueue.enqueueAction(
        SyncActionItem(
          actionType: 'RECORD_PAYMENT',
          payload: {
            'debtId': debtId,
            'amount': amount,
            'note': note,
            'client_id': paymentClientId,
            'contactId': resolvedContactId,
          },
          clientId: paymentClientId,
          timestamp: DateTime.now().toIso8601String(),
          status: SyncItemStatus.pending,
        ),
      );
      _invalidateNonContactCaches();
      return;
    }

    try {
      await remoteDataSource.recordPayment(
        debtId: debtId,
        amount: amount,
        note: note,
        clientId: paymentClientId,
      );
      _invalidateNonContactCaches();
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        await syncQueue.enqueueAction(
          SyncActionItem(
            actionType: 'RECORD_PAYMENT',
            payload: {
              'debtId': debtId,
              'amount': amount,
              'note': note,
              'client_id': paymentClientId,
              'contactId': resolvedContactId,
            },
            clientId: paymentClientId,
            timestamp: DateTime.now().toIso8601String(),
            status: SyncItemStatus.pending,
          ),
        );
        _invalidateNonContactCaches();
        return;
      }
      throw Exception('Failed to record payment: $e');
    }
  }

  void _invalidateNonContactCaches() {
    final userId = currentUserId;
    if (userId != null) {
      cacheManager?.invalidate('${peopleCacheKey}_$userId');
    }
    cacheManager?.invalidate(peopleCacheKey);
    cacheManager?.invalidatePrefix('insights_');
    cacheManager?.invalidatePrefix('all_debts_');
  }

  void _invalidateTransactionCaches(String? contactId) {
    _invalidateNonContactCaches();
    cacheManager?.invalidate('dashboard_data');
    if (contactId != null) {
      cacheManager?.invalidate('contact_$contactId');
    } else {
      cacheManager?.invalidatePrefix('contact_');
    }
  }

  void _updateLocalDashboardWithDebt(DebtEntity debt, ContactEntity? contact) {
    try {
      final jsonStr = sharedPreferences.getString('cached_dashboard');
      if (jsonStr == null || jsonStr.isEmpty) return;

      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final metrics = decoded['dashboard'] as Map<String, dynamic>? ?? {};

      double totalOwedToMe = double.tryParse(metrics['total_owed_to_me']?.toString() ?? '0') ?? 0.0;
      double totalIOwe = double.tryParse(metrics['total_i_owe']?.toString() ?? '0') ?? 0.0;
      int activeDebts = (metrics['active_debts_count'] as int?) ?? 0;

      if (debt.transactionType.toUpperCase() == 'THEY_OWE_ME') {
        totalOwedToMe += debt.originalAmount;
      } else {
        totalIOwe += debt.originalAmount;
      }
      activeDebts += 1;
      final double netBalance = totalOwedToMe - totalIOwe;

      metrics['total_owed_to_me'] = totalOwedToMe.toStringAsFixed(0);
      metrics['total_i_owe'] = totalIOwe.toStringAsFixed(0);
      metrics['net_balance'] = netBalance.toStringAsFixed(0);
      metrics['active_debts_count'] = activeDebts;
      decoded['dashboard'] = metrics;

      final recent = List<dynamic>.from(decoded['recent_transactions'] ?? []);
      final newTxn = {
        'id': debt.id,
        'debt': {
          'id': debt.id,
          'contact': {
            'id': contact?.id ?? '',
            'full_name': contact?.fullName ?? 'Contact',
            'nickname': contact?.nickname,
          },
          'transaction_type': debt.transactionType,
          'status_label': 'Pending',
        },
        'amount': debt.originalAmount.toStringAsFixed(0),
        'type': 'DEBT',
        'created_at': DateTime.now().toIso8601String(),
      };
      recent.insert(0, newTxn);
      decoded['recent_transactions'] = recent;

      final updatedStr = jsonEncode(decoded);
      sharedPreferences.setString('cached_dashboard', updatedStr);

      final updatedModel = DashboardDataModel.fromJson(decoded);
      cacheManager?.put<DashboardData>('dashboard_data', updatedModel);
    } catch (_) {}
  }

  void _updateLocalDashboardWithPayment(TransactionEntity payment, String contactId) {
    try {
      final jsonStr = sharedPreferences.getString('cached_dashboard');
      if (jsonStr == null || jsonStr.isEmpty) return;

      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final metrics = decoded['dashboard'] as Map<String, dynamic>? ?? {};

      double totalOwedToMe = double.tryParse(metrics['total_owed_to_me']?.toString() ?? '0') ?? 0.0;
      double totalIOwe = double.tryParse(metrics['total_i_owe']?.toString() ?? '0') ?? 0.0;

      final userId = currentUserId;
      ContactEntity? contact;
      if (userId != null) {
        contact = localDataSource.getContactById(userId, contactId);
      }

      if (contact != null && contact.totalUserOwes > contact.totalOwedToUser) {
        totalIOwe = (totalIOwe - payment.amount).clamp(0.0, double.infinity);
      } else {
        totalOwedToMe = (totalOwedToMe - payment.amount).clamp(0.0, double.infinity);
      }
      final double netBalance = totalOwedToMe - totalIOwe;

      metrics['total_owed_to_me'] = totalOwedToMe.toStringAsFixed(0);
      metrics['total_i_owe'] = totalIOwe.toStringAsFixed(0);
      metrics['net_balance'] = netBalance.toStringAsFixed(0);
      decoded['dashboard'] = metrics;

      final recent = List<dynamic>.from(decoded['recent_transactions'] ?? []);
      final newTxn = {
        'id': payment.id,
        'debt': {
          'id': payment.id,
          'contact': {
            'id': contact?.id ?? contactId,
            'full_name': contact?.fullName ?? 'Contact',
            'nickname': contact?.nickname,
          },
          'transaction_type': 'PAYMENT',
          'status_label': 'Payment',
        },
        'amount': payment.amount.toStringAsFixed(0),
        'type': 'PAYMENT',
        'created_at': payment.createdAt,
      };
      recent.insert(0, newTxn);
      decoded['recent_transactions'] = recent;

      final updatedStr = jsonEncode(decoded);
      sharedPreferences.setString('cached_dashboard', updatedStr);

      final updatedModel = DashboardDataModel.fromJson(decoded);
      cacheManager?.put<DashboardData>('dashboard_data', updatedModel);
    } catch (_) {}
  }

  DebtsWithStatistics _buildDebtsFromLocalStorage(String status) {
    final userId = currentUserId;
    if (userId == null) {
      return const DebtsWithStatistics(
        debts: [],
        statistics: DebtStatistics(
          totalDebts: 0,
          pendingCount: 0,
          settledCount: 0,
          totalPending: 0.0,
          totalSettled: 0.0,
          iOwePending: 0.0,
          theyOweMePending: 0.0,
          iOweSettled: 0.0,
          theyOweMeSettled: 0.0,
        ),
      );
    }

    final peopleData = localDataSource.getPeopleData(userId);
    final allContacts = peopleData?.allContacts ?? [];

    List<DebtWithContactEntity> allDebts = [];
    int pendingCount = 0;
    int settledCount = 0;
    double totalPending = 0.0;
    double totalSettled = 0.0;
    double iOwePending = 0.0;
    double theyOweMePending = 0.0;
    double iOweSettled = 0.0;
    double theyOweMeSettled = 0.0;

    for (final contact in allContacts) {
      if (contact.debts == null) continue;
      for (final debtRaw in contact.debts!) {
        final DebtEntity debt = debtRaw is DebtEntity
            ? debtRaw
            : DebtModel.fromJson(debtRaw as Map<String, dynamic>);

        final isSettled = debt.outstandingAmount <= 0;
        final isTheyOweMe = debt.transactionType.toUpperCase() == 'THEY_OWE_ME';

        if (isSettled) {
          settledCount++;
          totalSettled += debt.originalAmount;
          if (isTheyOweMe) {
            theyOweMeSettled += debt.originalAmount;
          } else {
            iOweSettled += debt.originalAmount;
          }
        } else {
          pendingCount++;
          totalPending += debt.outstandingAmount;
          if (isTheyOweMe) {
            theyOweMePending += debt.outstandingAmount;
          } else {
            iOwePending += debt.outstandingAmount;
          }
        }

        allDebts.add(DebtWithContactEntity(
          id: debt.id,
          transactionType: debt.transactionType,
          originalAmount: debt.originalAmount,
          paidAmount: debt.paidAmount,
          outstandingAmount: debt.outstandingAmount,
          progressPercentage: debt.progressPercentage,
          status: isSettled ? 'paid' : 'pending',
          statusLabel: isSettled ? 'Settled' : 'Pending',
          statusColor: isSettled ? '#00A86B' : '#FFA500',
          note: debt.transactions.isNotEmpty ? debt.transactions.first.note : null,
          category: null,
          dueDate: null,
          isOverdue: false,
          createdAt: debt.transactions.isNotEmpty ? debt.transactions.first.createdAt : DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          contact: contact,
        ));
      }
    }

    final stats = DebtStatistics(
      totalDebts: allDebts.length,
      pendingCount: pendingCount,
      settledCount: settledCount,
      totalPending: totalPending,
      totalSettled: totalSettled,
      iOwePending: iOwePending,
      theyOweMePending: theyOweMePending,
      iOweSettled: iOweSettled,
      theyOweMeSettled: theyOweMeSettled,
    );

    return DebtsWithStatistics(debts: allDebts, statistics: stats);
  }

  @override
  Future<DebtsWithStatistics> getAllDebtsWithStats({
    String status = 'all',
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'all_debts_$status';
    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(cacheKey)) {
      final cached = cacheManager!.get<DebtsWithStatistics>(cacheKey);
      if (cached != null) return cached;
    }

    // Fast path: if offline, build from local storage directly
    if (!ConnectivityManager.instance.isOnline) {
      return _buildDebtsFromLocalStorage(status);
    }

    try {
      final result = await remoteDataSource.getAllDebtsWithStats(
        status: status,
      );

      final debtsList = result['debts'] as List;
      final debts = debtsList
          .map((item) => item as DebtWithContactEntity)
          .toList();

      final statsMap = result['statistics'] as Map<String, dynamic>;

      final statistics = DebtStatistics(
        totalDebts: statsMap['total_debts'] ?? 0,
        pendingCount: statsMap['pending_count'] ?? 0,
        settledCount: statsMap['settled_count'] ?? 0,
        totalPending: (statsMap['total_pending'] ?? 0).toDouble(),
        totalSettled: (statsMap['total_settled'] ?? 0).toDouble(),
        iOwePending: (statsMap['i_owe_pending'] ?? 0).toDouble(),
        theyOweMePending: (statsMap['they_owe_me_pending'] ?? 0).toDouble(),
        iOweSettled: (statsMap['i_owe_settled'] ?? 0).toDouble(),
        theyOweMeSettled: (statsMap['they_owe_me_settled'] ?? 0).toDouble(),
      );

      final entity = DebtsWithStatistics(debts: debts, statistics: statistics);
      cacheManager?.put<DebtsWithStatistics>(
        cacheKey,
        entity,
        ttl: const Duration(minutes: 2),
      );

      return entity;
    } catch (e) {
      final stale = cacheManager?.get<DebtsWithStatistics>(cacheKey);
      if (stale != null) return stale;
      final local = _buildDebtsFromLocalStorage(status);
      if (local.debts.isNotEmpty || ErrorHandler.isNetworkError(e)) {
        return local;
      }
      throw Exception('Failed to fetch all debts with stats: $e');
    }
  }
}
