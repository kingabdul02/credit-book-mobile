import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/legacy_contact_entity.dart';
import '../../domain/entities/legacy_access_request_entity.dart';
import '../../domain/repositories/legacy_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class LegacyEvent {}

class LoadLegacyData extends LegacyEvent {}

class EnableLegacyAccess extends LegacyEvent {}

class DisableLegacyAccess extends LegacyEvent {}

class AddLegacyContact extends LegacyEvent {
  final Map<String, dynamic> data;
  AddLegacyContact(this.data);
}

class UpdateLegacyContact extends LegacyEvent {
  final String id;
  final Map<String, dynamic> data;
  UpdateLegacyContact({required this.id, required this.data});
}

class DeleteLegacyContact extends LegacyEvent {
  final String id;
  DeleteLegacyContact(this.id);
}

class ResendVerification extends LegacyEvent {
  final String id;
  ResendVerification(this.id);
}

class RevokeLegacyContact extends LegacyEvent {
  final String id;
  RevokeLegacyContact(this.id);
}

// ── Access Request Events ────────────────────────────────────────────────────

class LoadAccessRequests extends LegacyEvent {}

class SubmitAccessRequest extends LegacyEvent {
  final Map<String, dynamic> data;
  SubmitAccessRequest(this.data);
}

class ApproveAccessRequest extends LegacyEvent {
  final String requestId;
  ApproveAccessRequest(this.requestId);
}

class DenyAccessRequest extends LegacyEvent {
  final String requestId;
  DenyAccessRequest(this.requestId);
}

class LoadEstateReport extends LegacyEvent {
  final String requestId;
  LoadEstateReport(this.requestId);
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class LegacyState {}

class LegacyInitial extends LegacyState {}

class LegacyLoading extends LegacyState {}

class LegacyLoaded extends LegacyState {
  final LegacySettingsEntity settings;
  final List<LegacyContactEntity> contacts;
  LegacyLoaded({required this.settings, required this.contacts});

  LegacyContactEntity? get primaryContact =>
      contacts.where((c) => c.isPrimary).isNotEmpty
          ? contacts.firstWhere((c) => c.isPrimary)
          : null;

  List<LegacyContactEntity> get secondaryContacts =>
      contacts.where((c) => !c.isPrimary).toList();
}

class LegacyActionLoading extends LegacyState {
  final LegacySettingsEntity settings;
  final List<LegacyContactEntity> contacts;
  final String action; // 'adding' | 'deleting' | 'enabling' | etc.
  LegacyActionLoading({required this.settings, required this.contacts, required this.action});
}

class LegacyEnabled extends LegacyState {
  final String? recoveryCode;
  final LegacySettingsEntity settings;
  final List<LegacyContactEntity> contacts;
  LegacyEnabled({required this.recoveryCode, required this.settings, required this.contacts});
}

class LegacyContactAdded extends LegacyState {
  final LegacyContactEntity contact;
  final LegacySettingsEntity settings;
  final List<LegacyContactEntity> contacts;
  LegacyContactAdded({required this.contact, required this.settings, required this.contacts});
}

class LegacyContactDeleted extends LegacyState {
  final LegacySettingsEntity settings;
  final List<LegacyContactEntity> contacts;
  LegacyContactDeleted({required this.settings, required this.contacts});
}

class LegacyVerificationSent extends LegacyState {
  final LegacySettingsEntity settings;
  final List<LegacyContactEntity> contacts;
  LegacyVerificationSent({required this.settings, required this.contacts});
}

class LegacyError extends LegacyState {
  final String message;
  // Keep the previous data so the UI doesn't blank out on error
  final LegacySettingsEntity? settings;
  final List<LegacyContactEntity> contacts;
  LegacyError(this.message, {this.settings, this.contacts = const []});
}

// ── Access Request States ────────────────────────────────────────────────────

class AccessRequestsLoading extends LegacyState {}

class AccessRequestsLoaded extends LegacyState {
  final List<LegacyAccessRequestEntity> requests;
  AccessRequestsLoaded({required this.requests});

  List<LegacyAccessRequestEntity> get pendingRequests =>
      requests.where((r) => r.isPending).toList();

  List<LegacyAccessRequestEntity> get approvedRequests =>
      requests.where((r) => r.isApproved).toList();

  List<LegacyAccessRequestEntity> get deniedRequests =>
      requests.where((r) => r.isDenied).toList();
}

class AccessRequestSubmitted extends LegacyState {
  final LegacyAccessRequestEntity request;
  AccessRequestSubmitted({required this.request});
}

class AccessRequestActionLoading extends LegacyState {
  final List<LegacyAccessRequestEntity> requests;
  final String action; // 'approving' | 'denying' | 'submitting'
  AccessRequestActionLoading({required this.requests, required this.action});
}

class AccessRequestApproved extends LegacyState {
  final LegacyAccessRequestEntity request;
  final List<LegacyAccessRequestEntity> requests;
  AccessRequestApproved({required this.request, required this.requests});
}

class AccessRequestDenied extends LegacyState {
  final LegacyAccessRequestEntity request;
  final List<LegacyAccessRequestEntity> requests;
  AccessRequestDenied({required this.request, required this.requests});
}

class AccessRequestError extends LegacyState {
  final String message;
  final List<LegacyAccessRequestEntity> requests;
  AccessRequestError(this.message, {this.requests = const []});
}

class EstateReportLoading extends LegacyState {}

class EstateReportLoaded extends LegacyState {
  final EstateReportEntity report;
  EstateReportLoaded({required this.report});
}

class EstateReportError extends LegacyState {
  final String message;
  EstateReportError(this.message);
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class LegacyBloc extends Bloc<LegacyEvent, LegacyState> {
  final LegacyRepository repository;

  // Keep last known good data for error recovery
  LegacySettingsEntity? _settings;
  List<LegacyContactEntity> _contacts = [];
  List<LegacyAccessRequestEntity> _requests = [];

  LegacyBloc({required this.repository}) : super(LegacyInitial()) {
    on<LoadLegacyData>(_onLoad);
    on<EnableLegacyAccess>(_onEnable);
    on<DisableLegacyAccess>(_onDisable);
    on<AddLegacyContact>(_onAdd);
    on<UpdateLegacyContact>(_onUpdate);
    on<DeleteLegacyContact>(_onDelete);
    on<ResendVerification>(_onResend);
    on<RevokeLegacyContact>(_onRevoke);

    // Access request handlers
    on<LoadAccessRequests>(_onLoadRequests);
    on<SubmitAccessRequest>(_onSubmitRequest);
    on<ApproveAccessRequest>(_onApproveRequest);
    on<DenyAccessRequest>(_onDenyRequest);
    on<LoadEstateReport>(_onLoadEstateReport);
  }

  Future<void> _onLoad(LoadLegacyData event, Emitter<LegacyState> emit) async {
    emit(LegacyLoading());
    try {
      final results = await Future.wait([
        repository.getSettings(),
        repository.getLegacyContacts(),
      ]);
      _settings = results[0] as LegacySettingsEntity;
      _contacts = results[1] as List<LegacyContactEntity>;
      emit(LegacyLoaded(settings: _settings!, contacts: _contacts));
    } catch (e) {
      emit(LegacyError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onEnable(EnableLegacyAccess event, Emitter<LegacyState> emit) async {
    emit(LegacyActionLoading(settings: _settings!, contacts: _contacts, action: 'enabling'));
    try {
      final code = await repository.enableLegacyAccess();
      final settings = await repository.getSettings();
      _settings = settings;
      emit(LegacyEnabled(recoveryCode: code, settings: settings, contacts: _contacts));
    } catch (e) {
      emit(LegacyError(e.toString().replaceAll('Exception: ', ''), settings: _settings, contacts: _contacts));
    }
  }

  Future<void> _onDisable(DisableLegacyAccess event, Emitter<LegacyState> emit) async {
    emit(LegacyActionLoading(settings: _settings!, contacts: _contacts, action: 'disabling'));
    try {
      await repository.disableLegacyAccess();
      final settings = await repository.getSettings();
      _settings = settings;
      emit(LegacyLoaded(settings: settings, contacts: _contacts));
    } catch (e) {
      emit(LegacyError(e.toString().replaceAll('Exception: ', ''), settings: _settings, contacts: _contacts));
    }
  }

  LegacySettingsEntity get _currentSettings =>
      _settings ??
      const LegacySettingsEntity(
        legacyAccessEnabled: true,
        legacyWaitingPeriodDays: 30,
        hasRecoveryCode: false,
        contactsCount: 0,
        verifiedContactsCount: 0,
      );

  Future<void> _onAdd(AddLegacyContact event, Emitter<LegacyState> emit) async {
    final settings = _currentSettings;
    emit(LegacyActionLoading(settings: settings, contacts: _contacts, action: 'adding'));
    try {
      final contact = await repository.createLegacyContact(event.data);
      _contacts = [..._contacts, contact];
      _settings = LegacySettingsEntity(
        legacyAccessEnabled: true,
        legacyWaitingPeriodDays: settings.legacyWaitingPeriodDays,
        hasRecoveryCode: settings.hasRecoveryCode,
        contactsCount: _contacts.length,
        verifiedContactsCount: settings.verifiedContactsCount,
      );
      emit(LegacyContactAdded(contact: contact, settings: _settings!, contacts: _contacts));
    } catch (e) {
      emit(LegacyError(e.toString().replaceAll('Exception: ', ''), settings: _settings, contacts: _contacts));
    }
  }

  Future<void> _onUpdate(UpdateLegacyContact event, Emitter<LegacyState> emit) async {
    final settings = _currentSettings;
    emit(LegacyActionLoading(settings: settings, contacts: _contacts, action: 'updating'));
    try {
      final updated = await repository.updateLegacyContact(event.id, event.data);
      _contacts = _contacts.map((c) => c.id == event.id ? updated : c).toList();
      emit(LegacyLoaded(settings: settings, contacts: _contacts));
    } catch (e) {
      emit(LegacyError(e.toString().replaceAll('Exception: ', ''), settings: _settings, contacts: _contacts));
    }
  }

  Future<void> _onDelete(DeleteLegacyContact event, Emitter<LegacyState> emit) async {
    final settings = _currentSettings;
    emit(LegacyActionLoading(settings: settings, contacts: _contacts, action: 'deleting'));
    try {
      await repository.deleteLegacyContact(event.id);
      _contacts = _contacts.where((c) => c.id != event.id).toList();
      emit(LegacyContactDeleted(settings: settings, contacts: _contacts));
    } catch (e) {
      emit(LegacyError(e.toString().replaceAll('Exception: ', ''), settings: _settings, contacts: _contacts));
    }
  }

  Future<void> _onResend(ResendVerification event, Emitter<LegacyState> emit) async {
    emit(LegacyActionLoading(settings: _settings!, contacts: _contacts, action: 'resending'));
    try {
      await repository.resendVerification(event.id);
      emit(LegacyVerificationSent(settings: _settings!, contacts: _contacts));
    } catch (e) {
      emit(LegacyError(e.toString().replaceAll('Exception: ', ''), settings: _settings, contacts: _contacts));
    }
  }

  Future<void> _onRevoke(RevokeLegacyContact event, Emitter<LegacyState> emit) async {
    emit(LegacyActionLoading(settings: _settings!, contacts: _contacts, action: 'revoking'));
    try {
      await repository.revokeLegacyContact(event.id);
      // Reload to get updated status
      final contacts = await repository.getLegacyContacts();
      _contacts = contacts;
      emit(LegacyLoaded(settings: _settings!, contacts: _contacts));
    } catch (e) {
      emit(LegacyError(e.toString().replaceAll('Exception: ', ''), settings: _settings, contacts: _contacts));
    }
  }

  // ── Access Request Handlers ──────────────────────────────────────────────

  Future<void> _onLoadRequests(LoadAccessRequests event, Emitter<LegacyState> emit) async {
    emit(AccessRequestsLoading());
    try {
      _requests = await repository.getAccessRequests();
      emit(AccessRequestsLoaded(requests: _requests));
    } catch (e) {
      emit(AccessRequestError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSubmitRequest(SubmitAccessRequest event, Emitter<LegacyState> emit) async {
    emit(AccessRequestActionLoading(requests: _requests, action: 'submitting'));
    try {
      final request = await repository.submitAccessRequest(event.data);
      emit(AccessRequestSubmitted(request: request));
    } catch (e) {
      emit(AccessRequestError(e.toString().replaceAll('Exception: ', ''), requests: _requests));
    }
  }

  Future<void> _onApproveRequest(ApproveAccessRequest event, Emitter<LegacyState> emit) async {
    emit(AccessRequestActionLoading(requests: _requests, action: 'approving'));
    try {
      final approved = await repository.approveAccessRequest(event.requestId);
      _requests = _requests.map((r) => r.id == event.requestId ? approved : r).toList();
      emit(AccessRequestApproved(request: approved, requests: _requests));
    } catch (e) {
      emit(AccessRequestError(e.toString().replaceAll('Exception: ', ''), requests: _requests));
    }
  }

  Future<void> _onDenyRequest(DenyAccessRequest event, Emitter<LegacyState> emit) async {
    emit(AccessRequestActionLoading(requests: _requests, action: 'denying'));
    try {
      final denied = await repository.denyAccessRequest(event.requestId);
      _requests = _requests.map((r) => r.id == event.requestId ? denied : r).toList();
      emit(AccessRequestDenied(request: denied, requests: _requests));
    } catch (e) {
      emit(AccessRequestError(e.toString().replaceAll('Exception: ', ''), requests: _requests));
    }
  }

  Future<void> _onLoadEstateReport(LoadEstateReport event, Emitter<LegacyState> emit) async {
    emit(EstateReportLoading());
    try {
      final report = await repository.getEstateReport(event.requestId);
      emit(EstateReportLoaded(report: report));
    } catch (e) {
      emit(EstateReportError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
