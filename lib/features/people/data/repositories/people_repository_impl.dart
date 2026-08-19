import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/debt_with_contact_entity.dart';
import '../../data/models/debt_model.dart';
import '../../domain/repositories/people_repository.dart';
import '../datasources/people_remote_data_source.dart';
import '../../../../core/services/sync_queue_local_data_source.dart';

class PeopleRepositoryImpl implements PeopleRepository {
  final PeopleRemoteDataSource remoteDataSource;
  final SyncQueueLocalDataSource syncQueue;

  PeopleRepositoryImpl({
    required this.remoteDataSource,
    required this.syncQueue,
  });

  @override
  Future<PeopleDataEntity> getPeopleData() async {
    try {
      final results = await Future.wait([
        remoteDataSource.getFavorites(),
        remoteDataSource.getFrequentlyContacted(),
        remoteDataSource.getAllContacts(),
      ]);

      return PeopleDataEntity(
        favorites: results[0],
        frequentlyContacted: results[1],
        allContacts: results[2],
      );
    } catch (e) {
      throw Exception('Failed to fetch people data: $e');
    }
  }

  @override
  Future<ContactEntity> createContact(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createContact(data);
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  @override
  Future<ContactEntity> getContactDetails(String id) async {
    try {
      return await remoteDataSource.getContact(id);
    } catch (e) {
      throw Exception('Failed to fetch contact details: $e');
    }
  }

  @override
  Future<DebtEntity> createDebt(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createDebt(data);
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

        // Return optimistic model
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
  }) async {
    try {
      await remoteDataSource.recordPayment(
        debtId: debtId,
        amount: amount,
        note: note,
      );
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        await syncQueue.enqueueAction(
          SyncActionItem(
            actionType: 'RECORD_PAYMENT',
            payload: {'debtId': debtId, 'amount': amount, 'note': note},
            clientId: DateTime.now().millisecondsSinceEpoch
                .toString(), // Pseudo-unique
            timestamp: DateTime.now().toIso8601String(),
          ),
        );
        return; // Optimistic success
      }
      throw Exception('Failed to record payment: $e');
    }
  }

  @override
  Future<DebtsWithStatistics> getAllDebtsWithStats({
    String status = 'all',
  }) async {
    try {
      final result = await remoteDataSource.getAllDebtsWithStats(
        status: status,
      );

      // Properly cast the debts list
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

      return DebtsWithStatistics(debts: debts, statistics: statistics);
    } catch (e) {
      throw Exception('Failed to fetch all debts with stats: $e');
    }
  }
}
