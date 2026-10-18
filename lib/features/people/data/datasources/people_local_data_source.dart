import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/contact_entity.dart';
import '../models/debt_model.dart';
import '../models/transaction_model.dart';

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
  ContactEntity? getContactById(String userId, String contactId);
  Future<void> saveContactDetails(String userId, ContactEntity contact);
  Future<void> addOfflineDebt(String userId, String contactId, DebtEntity debt, {String? replaceClientId});
  Future<void> addOfflinePayment(String userId, String contactId, String debtId, TransactionEntity transaction);
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
  ContactEntity? getContactById(String userId, String contactId) {
    if (userId.isEmpty || contactId.isEmpty) return null;
    final data = getPeopleData(userId);
    if (data == null) return null;

    final index = data.allContacts.indexWhere((c) => c.id == contactId);
    if (index >= 0) return data.allContacts[index];

    final favIndex = data.favorites.indexWhere((c) => c.id == contactId);
    if (favIndex >= 0) return data.favorites[favIndex];

    final freqIndex = data.frequentlyContacted.indexWhere((c) => c.id == contactId);
    if (freqIndex >= 0) return data.frequentlyContacted[freqIndex];

    return null;
  }

  @override
  Future<void> saveContactDetails(String userId, ContactEntity contact) async {
    await saveContact(userId, contact);
  }

  @override
  Future<void> addOfflineDebt(String userId, String contactId, DebtEntity debt, {String? replaceClientId}) async {
    final contact = getContactById(userId, contactId);
    if (contact == null) return;

    final currentDebts = List<dynamic>.from(contact.debts ?? []);
    final debtIndex = currentDebts.indexWhere((d) {
      final id = d is DebtEntity ? d.id : (d is Map ? d['id'] : null);
      return id == debt.id || (replaceClientId != null && id == replaceClientId);
    });

    double owedToUser = contact.totalOwedToUser;
    double userOwes = contact.totalUserOwes;

    final type = debt.transactionType.toUpperCase();
    if (debtIndex >= 0) {
      final old = currentDebts[debtIndex];
      final double oldAmount = old is DebtEntity
          ? old.originalAmount
          : ((old is Map ? (old['original_amount'] ?? old['originalAmount']) : 0.0) as num).toDouble();
      final diff = debt.originalAmount - oldAmount;
      if (type == 'THEY_OWE_ME') {
        owedToUser += diff;
      } else {
        userOwes += diff;
      }
      currentDebts[debtIndex] = debt;
    } else {
      currentDebts.insert(0, debt);
      if (type == 'THEY_OWE_ME') {
        owedToUser += debt.originalAmount;
      } else {
        userOwes += debt.originalAmount;
      }
    }

    final updatedContact = contact.copyWith(
      debts: currentDebts,
      totalOwedToUser: owedToUser.clamp(0.0, double.infinity),
      totalUserOwes: userOwes.clamp(0.0, double.infinity),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await saveContact(userId, updatedContact);
  }

  @override
  Future<void> addOfflinePayment(
    String userId,
    String contactId,
    String debtId,
    TransactionEntity transaction,
  ) async {
    final contact = getContactById(userId, contactId);
    if (contact == null) return;

    final currentDebts = List<dynamic>.from(contact.debts ?? []);
    final debtIndex = currentDebts.indexWhere((d) {
      if (d is DebtEntity) return d.id == debtId;
      if (d is Map) return d['id'] == debtId;
      return false;
    });

    if (debtIndex >= 0) {
      final existing = currentDebts[debtIndex];
      final DebtEntity debt = existing is DebtEntity
          ? existing
          : DebtModel.fromJson(existing as Map<String, dynamic>);

      // Check if transaction already recorded (idempotent duplicate prevention)
      final alreadyRecorded = debt.transactions.any((t) => t.id == transaction.id);
      if (alreadyRecorded) {
        return;
      }

      final updatedTransactions = List<TransactionEntity>.from(debt.transactions);
      updatedTransactions.insert(0, transaction);

      final newPaid = debt.paidAmount + transaction.amount;
      final newOutstanding = (debt.originalAmount - newPaid).clamp(0.0, double.infinity);
      final newProgress = debt.originalAmount > 0
          ? ((newPaid / debt.originalAmount) * 100).clamp(0.0, 100.0)
          : 100.0;
      final newStatus = newOutstanding <= 0 ? 'paid' : 'partially_paid';

      final updatedDebt = DebtModel(
        id: debt.id,
        transactionType: debt.transactionType,
        originalAmount: debt.originalAmount,
        paidAmount: newPaid,
        outstandingAmount: newOutstanding,
        progressPercentage: newProgress,
        status: newStatus,
        transactions: updatedTransactions,
      );

      currentDebts[debtIndex] = updatedDebt;

      double owedToUser = contact.totalOwedToUser;
      double userOwes = contact.totalUserOwes;

      final type = debt.transactionType.toUpperCase();
      if (type == 'THEY_OWE_ME') {
        owedToUser = (owedToUser - transaction.amount).clamp(0.0, double.infinity);
      } else {
        userOwes = (userOwes - transaction.amount).clamp(0.0, double.infinity);
      }

      final updatedContact = contact.copyWith(
        debts: currentDebts,
        totalOwedToUser: owedToUser,
        totalUserOwes: userOwes,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await saveContact(userId, updatedContact);
    }
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

