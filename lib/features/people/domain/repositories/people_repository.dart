import '../entities/contact_entity.dart';
import '../entities/debt_with_contact_entity.dart';
import '../../data/models/debt_model.dart';

class DebtsWithStatistics {
  final List<DebtWithContactEntity> debts;
  final DebtStatistics statistics;

  const DebtsWithStatistics({required this.debts, required this.statistics});
}

abstract class PeopleRepository {
  Future<PeopleDataEntity> getPeopleData();
  Future<void> createContact(Map<String, dynamic> contactData);
  Future<ContactEntity> getContactDetails(String id);
  Future<DebtEntity> createDebt(Map<String, dynamic> data);

  /// Records a payment against a debt (THEY_OWE_ME or I_OWE_THEM).
  /// [debtId] – the debt being settled; [amount] – payment amount; [note] – optional note.
  Future<void> recordPayment({
    required String debtId,
    required double amount,
    String? note,
  });

  /// Fetches all debts with server-calculated statistics
  Future<DebtsWithStatistics> getAllDebtsWithStats({String status = 'all'});
}
