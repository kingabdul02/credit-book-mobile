import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/entities/contact_entity.dart';

// --- Events ---
abstract class AddTransactionEvent {}

class NumberPressed extends AddTransactionEvent {
  final String number;
  NumberPressed(this.number);
}

class BackspacePressed extends AddTransactionEvent {}

class DecimalPressed extends AddTransactionEvent {}

class TypeToggled extends AddTransactionEvent {
  final String transactionType; // 'LENT' or 'BORROWED'
  TypeToggled(this.transactionType);
}

class ContactSelected extends AddTransactionEvent {
  final ContactEntity contact;
  ContactSelected(this.contact);
}

class NoteChanged extends AddTransactionEvent {
  final String note;
  NoteChanged(this.note);
}

class SubmitTransaction extends AddTransactionEvent {}

class LoadContacts extends AddTransactionEvent {}

// --- States ---
class AddTransactionState {
  final String amountString;
  final String transactionType;
  final ContactEntity? selectedContact;
  final String note;
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final List<ContactEntity> contacts;

  AddTransactionState({
    this.amountString = '0',
    this.transactionType = 'THEY_OWE_ME', // Default: THEY OWE ME
    this.selectedContact,
    this.note = '',
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.contacts = const [],
  });

  AddTransactionState copyWith({
    String? amountString,
    String? transactionType,
    ContactEntity? selectedContact,
    String? note,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<ContactEntity>? contacts,
  }) {
    return AddTransactionState(
      amountString: amountString ?? this.amountString,
      transactionType: transactionType ?? this.transactionType,
      selectedContact: selectedContact ?? this.selectedContact,
      note: note ?? this.note,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Don't copy over old errors
      isSuccess: isSuccess ?? this.isSuccess,
      contacts: contacts ?? this.contacts,
    );
  }
}

// --- Bloc ---
class AddTransactionBloc extends Bloc<AddTransactionEvent, AddTransactionState> {
  final PeopleRepository repository;
  final _uuid = const Uuid();

  AddTransactionBloc({required this.repository}) : super(AddTransactionState()) {
    on<NumberPressed>(_onNumberPressed);
    on<BackspacePressed>(_onBackspacePressed);
    on<DecimalPressed>(_onDecimalPressed);
    on<TypeToggled>(_onTypeToggled);
    on<ContactSelected>(_onContactSelected);
    on<NoteChanged>(_onNoteChanged);
    on<LoadContacts>(_onLoadContacts);
    on<SubmitTransaction>(_onSubmitTransaction);
  }

  void _onNumberPressed(NumberPressed event, Emitter<AddTransactionState> emit) {
    if (state.amountString == '0') {
      emit(state.copyWith(amountString: event.number));
    } else {
      // Limit to 2 decimal places if a decimal exists
      if (state.amountString.contains('.')) {
        final parts = state.amountString.split('.');
        if (parts.length > 1 && parts[1].length >= 2) {
          return; // Ignore if already 2 decimals
        }
      }
      
      // Max length limit
      if (state.amountString.length >= 10) return;

      emit(state.copyWith(amountString: state.amountString + event.number));
    }
  }

  void _onBackspacePressed(BackspacePressed event, Emitter<AddTransactionState> emit) {
    if (state.amountString.length > 1) {
      emit(state.copyWith(amountString: state.amountString.substring(0, state.amountString.length - 1)));
    } else {
      emit(state.copyWith(amountString: '0'));
    }
  }

  void _onDecimalPressed(DecimalPressed event, Emitter<AddTransactionState> emit) {
    if (!state.amountString.contains('.')) {
      emit(state.copyWith(amountString: '${state.amountString}.'));
    }
  }

  void _onTypeToggled(TypeToggled event, Emitter<AddTransactionState> emit) {
    emit(state.copyWith(transactionType: event.transactionType));
  }

  void _onContactSelected(ContactSelected event, Emitter<AddTransactionState> emit) {
    emit(state.copyWith(selectedContact: event.contact));
  }

  void _onNoteChanged(NoteChanged event, Emitter<AddTransactionState> emit) {
    emit(state.copyWith(note: event.note));
  }

  Future<void> _onLoadContacts(LoadContacts event, Emitter<AddTransactionState> emit) async {
    try {
      final peopleData = await repository.getPeopleData();
      emit(state.copyWith(contacts: peopleData.allContacts));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to load contacts'));
    }
  }

  Future<void> _onSubmitTransaction(SubmitTransaction event, Emitter<AddTransactionState> emit) async {
    if (state.selectedContact == null) {
      emit(state.copyWith(error: 'Please select a contact'));
      return;
    }

    final doubleAmount = double.tryParse(state.amountString) ?? 0.0;
    if (doubleAmount <= 0) {
      emit(state.copyWith(error: 'Please enter a valid amount'));
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final clientId = _uuid.v4();
      final transactionClientId = _uuid.v4();
      
      await repository.createDebt({
        'contact_id': state.selectedContact!.id,
        'transaction_type': state.transactionType,
        'amount': doubleAmount,
        'currency': 'USD', // Defaulting or making configurable
        'note': state.note.isNotEmpty ? state.note : null,
        'client_id': clientId,
        'transaction_client_id': transactionClientId,
      });

      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
