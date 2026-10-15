import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/repositories/people_repository.dart';

// Events
abstract class AddPersonEvent {}

class SubmitAddPerson extends AddPersonEvent {
  final String fullName;
  final String nickname;
  final String phoneNumber;
  final bool isFavorite;

  SubmitAddPerson({
    required this.fullName,
    required this.nickname,
    required this.phoneNumber,
    required this.isFavorite,
  });
}

class ImportContactRequested extends AddPersonEvent {}

// States
abstract class AddPersonState {}

class AddPersonInitial extends AddPersonState {}

class AddPersonLoading extends AddPersonState {}

class AddPersonSuccess extends AddPersonState {}

class AddPersonError extends AddPersonState {
  final String message;
  AddPersonError(this.message);
}

class ContactImported extends AddPersonState {
  final String fullName;
  final String phoneNumber;
  ContactImported({required this.fullName, required this.phoneNumber});
}

// Bloc
class AddPersonBloc extends Bloc<AddPersonEvent, AddPersonState> {
  final PeopleRepository repository;
  final _uuid = const Uuid();

  AddPersonBloc({required this.repository}) : super(AddPersonInitial()) {
    on<SubmitAddPerson>(_onSubmitAddPerson);
    on<ImportContactRequested>(_onImportContactRequested);
  }

  Future<void> _onSubmitAddPerson(
    SubmitAddPerson event,
    Emitter<AddPersonState> emit,
  ) async {
    emit(AddPersonLoading());
    try {
      final clientId = _uuid.v4();
      await repository.createContact({
        'full_name': event.fullName,
        'nickname': event.nickname.isNotEmpty ? event.nickname : null,
        'phone_number': event.phoneNumber.isNotEmpty ? event.phoneNumber : null,
        'is_favorite': event.isFavorite,
        'client_id': clientId,
      });
      emit(AddPersonSuccess());
    } catch (e) {
      emit(AddPersonError(ErrorHandler.getFriendlyMessage(e)));
    }
  }

  Future<void> _onImportContactRequested(
    ImportContactRequested event,
    Emitter<AddPersonState> emit,
  ) async {
    try {
      // Request permission first; on Android the contact picker itself also
      // handles its own permission dialog, but we still request explicitly.
      final status = await Permission.contacts.request();

      if (status.isPermanentlyDenied) {
        emit(AddPersonError(
          'Contacts permission permanently denied. Please enable it in Settings.',
        ));
        return;
      }

      // Open the native contact picker (works even without explicit permission
      // on some Android versions because it runs in the Contacts app process).
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.name, ContactProperty.phone},
      );

      if (contact == null) {
        // User dismissed the picker — not an error
        return;
      }

      // Prefer displayName, fall back to joined name parts
      final name = (contact.displayName?.isNotEmpty == true)
          ? contact.displayName!
          : '${contact.name?.first ?? ''} ${contact.name?.last ?? ''}'.trim();

      // Extract and clean the phone number
      String phone = '';
      if (contact.phones.isNotEmpty) {
        // Prefer E.164 normalizedNumber (Android) if available
        final raw = contact.phones.first.normalizedNumber?.isNotEmpty == true
            ? contact.phones.first.normalizedNumber!
            : contact.phones.first.number;

        // Strip all non-digit characters
        final digits = raw.replaceAll(RegExp(r'\D'), '');

        // If the number starts with a country code (10+ digits), strip the
        // leading country code digits so only the subscriber number remains.
        // Nigerian numbers: +234XXXXXXXXXX → keep last 10 digits (no leading 0).
        if (digits.length > 10) {
          phone = digits.substring(digits.length - 10);
        } else if (digits.startsWith('0') && digits.length == 11) {
          // Local format 0XXXXXXXXXX → strip leading 0
          phone = digits.substring(1);
        } else {
          phone = digits;
        }
      }

      emit(ContactImported(fullName: name, phoneNumber: phone));
    } catch (e) {
      emit(AddPersonError('Failed to import contact: $e'));
    }
  }
}
