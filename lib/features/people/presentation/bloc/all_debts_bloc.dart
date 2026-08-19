import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/debt_with_contact_entity.dart';
import '../../domain/repositories/people_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Events
// ═══════════════════════════════════════════════════════════════════════════

abstract class AllDebtsEvent {}

class LoadAllDebts extends AllDebtsEvent {
  final String statusFilter; // 'all', 'pending', 'settled'
  LoadAllDebts({this.statusFilter = 'all'});
}

class FilterDebts extends AllDebtsEvent {
  final String statusFilter;
  FilterDebts(this.statusFilter);
}

class SearchDebts extends AllDebtsEvent {
  final String query;
  SearchDebts(this.query);
}

class RecordDebtPayment extends AllDebtsEvent {
  final String debtId;
  final double amount;
  final String? note;

  RecordDebtPayment({required this.debtId, required this.amount, this.note});
}

// ═══════════════════════════════════════════════════════════════════════════
// States
// ═══════════════════════════════════════════════════════════════════════════

abstract class AllDebtsState {}

class AllDebtsInitial extends AllDebtsState {}

class AllDebtsLoading extends AllDebtsState {}

class AllDebtsLoaded extends AllDebtsState {
  final List<DebtWithContactEntity> allDebts;
  final List<DebtWithContactEntity> filteredDebts;
  final String currentFilter; // 'all', 'pending', 'settled'
  final String searchQuery;
  final int pendingCount;
  final int settledCount;
  final double totalPending;
  final double totalSettled;
  final double currentFilterIOwe;
  final double currentFilterTheyOweMe;
  final DebtStatistics statistics; // Store the full statistics from API

  AllDebtsLoaded({
    required this.allDebts,
    required this.filteredDebts,
    required this.currentFilter,
    required this.searchQuery,
    required this.pendingCount,
    required this.settledCount,
    required this.totalPending,
    required this.totalSettled,
    required this.currentFilterIOwe,
    required this.currentFilterTheyOweMe,
    required this.statistics,
  });

  AllDebtsLoaded copyWith({
    List<DebtWithContactEntity>? allDebts,
    List<DebtWithContactEntity>? filteredDebts,
    String? currentFilter,
    String? searchQuery,
    int? pendingCount,
    int? settledCount,
    double? totalPending,
    double? totalSettled,
    double? currentFilterIOwe,
    double? currentFilterTheyOweMe,
    DebtStatistics? statistics,
  }) {
    return AllDebtsLoaded(
      allDebts: allDebts ?? this.allDebts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      pendingCount: pendingCount ?? this.pendingCount,
      settledCount: settledCount ?? this.settledCount,
      totalPending: totalPending ?? this.totalPending,
      totalSettled: totalSettled ?? this.totalSettled,
      currentFilterIOwe: currentFilterIOwe ?? this.currentFilterIOwe,
      currentFilterTheyOweMe:
          currentFilterTheyOweMe ?? this.currentFilterTheyOweMe,
      statistics: statistics ?? this.statistics,
    );
  }
}

class AllDebtsError extends AllDebtsState {
  final String message;
  AllDebtsError(this.message);
}

class PaymentRecording extends AllDebtsState {}

class PaymentRecorded extends AllDebtsState {}

class PaymentFailed extends AllDebtsState {
  final String message;
  PaymentFailed(this.message);
}

// ═══════════════════════════════════════════════════════════════════════════
// BLoC
// ═══════════════════════════════════════════════════════════════════════════

class AllDebtsBloc extends Bloc<AllDebtsEvent, AllDebtsState> {
  final PeopleRepository repository;

  AllDebtsBloc({required this.repository}) : super(AllDebtsInitial()) {
    on<LoadAllDebts>(_onLoadAllDebts);
    on<FilterDebts>(_onFilterDebts);
    on<SearchDebts>(_onSearchDebts);
    on<RecordDebtPayment>(_onRecordDebtPayment);
  }

  Future<void> _onLoadAllDebts(
    LoadAllDebts event,
    Emitter<AllDebtsState> emit,
  ) async {
    emit(AllDebtsLoading());
    try {
      final result = await repository.getAllDebtsWithStats(status: 'all');
      final debts = result.debts;
      final stats = result.statistics;

      // Apply initial filter
      final filtered = _applyFilter(debts, event.statusFilter, '');

      // Use API-provided statistics directly - NO client-side calculation
      double currentFilterIOwe = 0.0;
      double currentFilterTheyOweMe = 0.0;

      if (event.statusFilter == 'pending') {
        currentFilterIOwe = stats.iOwePending;
        currentFilterTheyOweMe = stats.theyOweMePending;
      } else if (event.statusFilter == 'settled') {
        currentFilterIOwe = stats.iOweSettled;
        currentFilterTheyOweMe = stats.theyOweMeSettled;
      } else {
        // For 'all' tab, show pending totals
        currentFilterIOwe = stats.iOwePending;
        currentFilterTheyOweMe = stats.theyOweMePending;
      }

      emit(
        AllDebtsLoaded(
          allDebts: debts,
          filteredDebts: filtered,
          currentFilter: event.statusFilter,
          searchQuery: '',
          pendingCount: stats.pendingCount,
          settledCount: stats.settledCount,
          totalPending: stats.totalPending,
          totalSettled: stats.totalSettled,
          currentFilterIOwe: currentFilterIOwe,
          currentFilterTheyOweMe: currentFilterTheyOweMe,
          statistics: stats, // Store the full statistics
        ),
      );
    } catch (e) {
      emit(AllDebtsError(e.toString()));
    }
  }

  void _onFilterDebts(FilterDebts event, Emitter<AllDebtsState> emit) {
    if (state is AllDebtsLoaded) {
      final current = state as AllDebtsLoaded;
      final filtered = _applyFilter(
        current.allDebts,
        event.statusFilter,
        current.searchQuery,
      );

      // Use API-provided statistics directly - NO client-side calculation
      final stats = current.statistics;
      double currentFilterIOwe = 0.0;
      double currentFilterTheyOweMe = 0.0;

      if (event.statusFilter == 'pending') {
        currentFilterIOwe = stats.iOwePending;
        currentFilterTheyOweMe = stats.theyOweMePending;
      } else if (event.statusFilter == 'settled') {
        currentFilterIOwe = stats.iOweSettled;
        currentFilterTheyOweMe = stats.theyOweMeSettled;
      } else {
        // For 'all' tab, show pending totals
        currentFilterIOwe = stats.iOwePending;
        currentFilterTheyOweMe = stats.theyOweMePending;
      }

      emit(
        current.copyWith(
          currentFilter: event.statusFilter,
          filteredDebts: filtered,
          currentFilterIOwe: currentFilterIOwe,
          currentFilterTheyOweMe: currentFilterTheyOweMe,
        ),
      );
    }
  }

  void _onSearchDebts(SearchDebts event, Emitter<AllDebtsState> emit) {
    if (state is AllDebtsLoaded) {
      final current = state as AllDebtsLoaded;
      final filtered = _applyFilter(
        current.allDebts,
        current.currentFilter,
        event.query,
      );

      // When searching, keep using API statistics
      // The statistics show totals for ALL debts, not just search results
      // This is intentional - we want to show overall statistics, not filtered ones
      emit(current.copyWith(searchQuery: event.query, filteredDebts: filtered));
    }
  }

  List<DebtWithContactEntity> _applyFilter(
    List<DebtWithContactEntity> debts,
    String statusFilter,
    String searchQuery,
  ) {
    var result = debts;

    // Apply status filter
    if (statusFilter == 'pending') {
      result = result.where((d) => d.isPending).toList();
    } else if (statusFilter == 'settled') {
      result = result.where((d) => d.isSettled).toList();
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((debt) {
        final contactName = debt.contact?.fullName.toLowerCase() ?? '';
        final note = debt.note?.toLowerCase() ?? '';
        final category = debt.category?.toLowerCase() ?? '';
        return contactName.contains(query) ||
            note.contains(query) ||
            category.contains(query);
      }).toList();
    }

    // Sort by date (most recent first) - use updatedAt for settled debts
    result.sort((a, b) {
      try {
        final dateA = a.isSettled
            ? DateTime.parse(a.updatedAt)
            : DateTime.parse(a.createdAt);
        final dateB = b.isSettled
            ? DateTime.parse(b.updatedAt)
            : DateTime.parse(b.createdAt);
        return dateB.compareTo(dateA); // Most recent first
      } catch (e) {
        // Fallback to comparing strings if parsing fails
        return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return result;
  }

  Future<void> _onRecordDebtPayment(
    RecordDebtPayment event,
    Emitter<AllDebtsState> emit,
  ) async {
    emit(PaymentRecording());
    try {
      await repository.recordPayment(
        debtId: event.debtId,
        amount: event.amount,
        note: event.note,
      );
      emit(PaymentRecorded());

      // Reload debts to reflect the payment
      add(LoadAllDebts());
    } catch (e) {
      emit(PaymentFailed(e.toString()));
    }
  }
}
