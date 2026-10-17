import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/entities/contact_entity.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/entities/ledger_transaction_entity.dart';
import '../../domain/repositories/people_repository.dart';
import 'package:intl/intl.dart';

// Events
abstract class LedgerEvent {}

class LoadLedger extends LedgerEvent {
  final String contactId;
  final bool forceRefresh;
  LoadLedger(this.contactId, {this.forceRefresh = false});
}

class RecordPayment extends LedgerEvent {
  final String debtId;
  final double amount;
  final String? note;
  final String contactId; // to reload ledger after success
  RecordPayment({required this.debtId, required this.amount, this.note, required this.contactId});
}

// States
abstract class LedgerState {}

class LedgerInitial extends LedgerState {}

class LedgerLoading extends LedgerState {}

class LedgerLoaded extends LedgerState {
  final ContactEntity contact;
  final double netBalance;
  final double totalOwedToUser;
  final double totalUserOwes;
  final double repaymentProgress;
  final List<LedgerTransactionEntity> history;

  LedgerLoaded({
    required this.contact,
    required this.netBalance,
    required this.totalOwedToUser,
    required this.totalUserOwes,
    required this.repaymentProgress,
    required this.history,
  });
}

class LedgerError extends LedgerState {
  final String message;
  LedgerError(this.message);
}

class PaymentRecording extends LedgerState {}

class PaymentRecorded extends LedgerState {}

class PaymentFailed extends LedgerState {
  final String message;
  PaymentFailed(this.message);
}

// Bloc
class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  final PeopleRepository repository;

  LedgerBloc({required this.repository}) : super(LedgerInitial()) {
    on<LoadLedger>(_onLoadLedger);
    on<RecordPayment>(_onRecordPayment);
  }

  Future<void> _onLoadLedger(LoadLedger event, Emitter<LedgerState> emit) async {
    // 1. Check for cached contact details
    final cached = repository.getCachedContactDetails(event.contactId);
    final hasData = state is LedgerLoaded || cached != null;

    if (cached != null && state is! LedgerLoaded) {
      emit(_buildLedgerLoaded(cached));
    } else if (!hasData) {
      emit(LedgerLoading());
    }

    try {
      final contact = await repository.getContactDetails(
        event.contactId,
        forceRefresh: event.forceRefresh,
      );
      emit(_buildLedgerLoaded(contact));
    } catch (e) {
      if (!hasData) {
        emit(LedgerError(ErrorHandler.getFriendlyMessage(e)));
      }
    }
  }

  LedgerLoaded _buildLedgerLoaded(ContactEntity contact) {
    double theyOweMeOriginal = 0.0;
    double theyOweMePaid = 0.0;
    double iOweThemOriginal = 0.0;
    double iOweThemPaid = 0.0;
    List<LedgerTransactionEntity> history = [];

    if (contact.debts != null) {
      for (var debt in contact.debts!) {
        final debtEntity = debt as DebtEntity;
        if (debtEntity.transactionType == 'THEY_OWE_ME') {
          theyOweMeOriginal += debtEntity.originalAmount;
          theyOweMePaid += debtEntity.paidAmount;
        } else {
          iOweThemOriginal += debtEntity.originalAmount;
          iOweThemPaid += debtEntity.paidAmount;
        }
      }
    }

    List<TransactionEntity> allTxns = [];
    Map<String, DebtEntity> txnToDebtMap = {};
    if (contact.debts != null) {
      for (var debt in contact.debts!) {
        final debtEntity = debt as DebtEntity;
        for (var txn in debtEntity.transactions) {
          allTxns.add(txn);
          txnToDebtMap[txn.id] = debtEntity;
        }
      }
    }

    allTxns.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

    history = allTxns.map((txn) {
      final dateObj = DateTime.parse(txn.createdAt).toLocal();
      final debtEntity = txnToDebtMap[txn.id]!;
      return LedgerTransactionEntity(
        title: _getTitle(txn.type, debtEntity.transactionType),
        subtitle: txn.note ?? (txn.type == 'payment' ? 'Payment' : 'Debt Issuance'),
        amount: txn.amount,
        isPositive: _isPositive(txn.type, debtEntity.transactionType),
        date: _formatDate(dateObj),
        time: DateFormat('hh:mm a').format(dateObj),
        type: txn.type,
        transactionType: debtEntity.transactionType,
      );
    }).toList();

    final netBalance = contact.totalOwedToUser - contact.totalUserOwes;

    double repaymentProgress = 0.0;
    if (netBalance >= 0 && theyOweMeOriginal > 0) {
      repaymentProgress = (theyOweMePaid / theyOweMeOriginal) * 100;
    } else if (netBalance < 0 && iOweThemOriginal > 0) {
      repaymentProgress = (iOweThemPaid / iOweThemOriginal) * 100;
    }

    return LedgerLoaded(
      contact: contact,
      netBalance: netBalance,
      totalOwedToUser: contact.totalOwedToUser,
      totalUserOwes: contact.totalUserOwes,
      repaymentProgress: repaymentProgress,
      history: history,
    );
  }

  String _getTitle(String txnType, String debtType) {
    final type = txnType.toUpperCase();
    if (type == 'PAYMENT') return 'Payment';
    if (type == 'ADDITIONAL') return 'Additional';
    return 'Initial debt';
  }

  bool _isPositive(String txnType, String debtType) {
    final type = txnType.toUpperCase();
    if (type == 'PAYMENT') return false;
    return true;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final aDate = DateTime(date.year, date.month, date.day);

    if (aDate == today) return 'Today';
    if (aDate == yesterday) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _onRecordPayment(RecordPayment event, Emitter<LedgerState> emit) async {
    emit(PaymentRecording());
    try {
      await repository.recordPayment(
        debtId: event.debtId,
        amount: event.amount,
        note: event.note,
      );
      emit(PaymentRecorded());
      // Reload ledger with forceRefresh so the UI reflects the new payment
      add(LoadLedger(event.contactId, forceRefresh: true));
    } catch (e) {
      emit(PaymentFailed(ErrorHandler.getFriendlyMessage(e)));
    }
  }
}
