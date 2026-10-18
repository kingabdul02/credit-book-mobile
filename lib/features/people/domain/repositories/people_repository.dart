import '../entities/contact_entity.dart';
import '../entities/debt_with_contact_entity.dart';
import '../../data/models/debt_model.dart';

class DebtsWithStatistics {
  final List<DebtWithContactEntity> debts;
  final DebtStatistics statistics;

  const DebtsWithStatistics({required this.debts, required this.statistics});
}

abstract class PeopleRepository {
  Future<PeopleDataEntity> getPeopleData({bool forceRefresh = false});
  PeopleDataEntity? getCachedPeopleData();

  Future<ContactEntity> createContact(Map<String, dynamic> contactData);
  Future<ContactEntity> updateContact(String id, Map<String, dynamic> contactData);
  Future<void> deleteContact(String id);

  Future<void> syncContactsOnLogin(String userId);

  Future<ContactEntity> getContactDetails(String id, {bool forceRefresh = false});
  ContactEntity? getCachedContactDetails(String id);

  Future<DebtEntity> createDebt(Map<String, dynamic> data);

  /// Records a payment against a debt (THEY_OWE_ME or I_OWE_THEM).
  /// [debtId] – the debt being settled; [amount] – payment amount; [note] – optional note.
  Future<void> recordPayment({
    required String debtId,
    required double amount,
    String? note,
    String? contactId,
    String? clientId,
  });

  /// Fetches all debts with server-calculated statistics
  Future<DebtsWithStatistics> getAllDebtsWithStats({
    String status = 'all',
    bool forceRefresh = false,
  });
  DebtsWithStatistics? getCachedAllDebtsWithStats({String status = 'all'});
}
