import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/debt_with_contact_entity.dart';
import '../../data/models/debt_model.dart';
import '../../domain/repositories/people_repository.dart';
import '../datasources/people_remote_data_source.dart';
import '../../../../core/services/sync_queue_local_data_source.dart';
import '../../../../core/services/app_cache_manager.dart';

class PeopleRepositoryImpl implements PeopleRepository {
  final PeopleRemoteDataSource remoteDataSource;
  final SyncQueueLocalDataSource syncQueue;
  final AppCacheManager? cacheManager;

  static const String peopleCacheKey = 'people_data';

  PeopleRepositoryImpl({
    required this.remoteDataSource,
    required this.syncQueue,
    this.cacheManager,
  });

  @override
  PeopleDataEntity? getCachedPeopleData() {
    return cacheManager?.get<PeopleDataEntity>(peopleCacheKey);
  }

  @override
  ContactEntity? getCachedContactDetails(String id) {
    return cacheManager?.get<ContactEntity>('contact_$id');
  }

  @override
  DebtsWithStatistics? getCachedAllDebtsWithStats({String status = 'all'}) {
    return cacheManager?.get<DebtsWithStatistics>('all_debts_$status');
  }

  @override
  Future<PeopleDataEntity> getPeopleData({bool forceRefresh = false}) async {
    // 1. Return fresh in-memory cache if available
    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(peopleCacheKey)) {
      final cached = cacheManager!.get<PeopleDataEntity>(peopleCacheKey);
      if (cached != null) return cached;
    }

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

      cacheManager?.put<PeopleDataEntity>(
        peopleCacheKey,
        data,
        ttl: const Duration(minutes: 3),
      );

      return data;
    } catch (e) {
      final stale = cacheManager?.get<PeopleDataEntity>(peopleCacheKey);
      if (stale != null) return stale;
      throw Exception('Failed to fetch people data: $e');
    }
  }

  @override
  Future<ContactEntity> createContact(Map<String, dynamic> data) async {
    try {
      final contact = await remoteDataSource.createContact(data);
      // Invalidate relevant caches on mutation
      _invalidateTransactionCaches(null);
      return contact;
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  @override
  Future<ContactEntity> getContactDetails(String id, {bool forceRefresh = false}) async {
    final cacheKey = 'contact_$id';
    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(cacheKey)) {
      final cached = cacheManager!.get<ContactEntity>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final contact = await remoteDataSource.getContact(id);
      cacheManager?.put<ContactEntity>(
        cacheKey,
        contact,
        ttl: const Duration(minutes: 2),
      );
      return contact;
    } catch (e) {
      final stale = cacheManager?.get<ContactEntity>(cacheKey);
      if (stale != null) return stale;
      throw Exception('Failed to fetch contact details: $e');
    }
  }

  @override
  Future<DebtEntity> createDebt(Map<String, dynamic> data) async {
    try {
      final result = await remoteDataSource.createDebt(data);
      _invalidateTransactionCaches(data['contact_id']?.toString());
      return result;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        final clientId = data['client_id'];
        await syncQueue.enqueueAction(
          SyncActionItem(
            actionType: 'CREATE_DEBT',
            payload: data,
            clientId: clientId,
            timestamp: DateTime.now().toIso8601String(),
          ),
        );

        final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        _invalidateTransactionCaches(data['contact_id']?.toString());

        return DebtModel(
          id: clientId,
          transactionType: data['transaction_type'] ?? 'they_owe_me',
          originalAmount: amount,
          paidAmount: 0.0,
          outstandingAmount: amount,
          progressPercentage: 0.0,
          status: 'pending_sync',
          transactions: const [],
        );
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
  }) async {
    try {
      await remoteDataSource.recordPayment(
        debtId: debtId,
        amount: amount,
        note: note,
      );
      _invalidateTransactionCaches(contactId);
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        await syncQueue.enqueueAction(
          SyncActionItem(
            actionType: 'RECORD_PAYMENT',
            payload: {'debtId': debtId, 'amount': amount, 'note': note},
            clientId: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now().toIso8601String(),
          ),
        );
        _invalidateTransactionCaches(contactId);
        return;
      }
      throw Exception('Failed to record payment: $e');
    }
  }

  void _invalidateTransactionCaches(String? contactId) {
    cacheManager?.invalidate(peopleCacheKey);
    cacheManager?.invalidate('dashboard_data');
    cacheManager?.invalidatePrefix('insights_');
    cacheManager?.invalidatePrefix('all_debts_');
    if (contactId != null) {
      cacheManager?.invalidate('contact_$contactId');
    } else {
      cacheManager?.invalidatePrefix('contact_');
    }
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
      throw Exception('Failed to fetch all debts with stats: $e');
    }
  }
}
