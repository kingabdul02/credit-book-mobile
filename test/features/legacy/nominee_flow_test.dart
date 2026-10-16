import 'dart:convert';
import 'package:creditbook/features/legacy/data/datasources/legacy_remote_data_source.dart';
import 'package:creditbook/features/legacy/domain/entities/legacy_access_request_entity.dart';
import 'package:creditbook/features/legacy/domain/entities/legacy_contact_entity.dart';
import 'package:creditbook/features/legacy/domain/repositories/legacy_repository.dart';
import 'package:creditbook/features/legacy/presentation/bloc/legacy_bloc.dart';
import 'package:creditbook/features/legacy/presentation/pages/submit_access_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLegacyRepo implements LegacyRepository {
  bool submitCalled = false;
  Map<String, dynamic>? lastSubmittedData;
  LegacyAccessRequestEntity? requestToReturn;

  @override
  Future<LegacyAccessRequestEntity> submitAccessRequest(Map<String, dynamic> data) async {
    submitCalled = true;
    lastSubmittedData = data;
    return requestToReturn ??
        const LegacyAccessRequestEntity(
          id: 'test-req-123',
          reason: 'medical_emergency',
          recoveryCodeProvided: false,
          status: 'PENDING',
          grantsAccess: false,
          waitingPeriodDays: 30,
        );
  }

  @override
  Future<LegacySettingsEntity> getSettings() async => const LegacySettingsEntity(
        legacyAccessEnabled: true,
        legacyWaitingPeriodDays: 30,
        hasRecoveryCode: false,
        contactsCount: 1,
        verifiedContactsCount: 1,
      );

  @override
  Future<String?> enableLegacyAccess() async => 'ABCD-1234-EFGH';

  @override
  Future<void> disableLegacyAccess() async {}

  @override
  Future<List<LegacyContactEntity>> getLegacyContacts() async => [];

  @override
  Future<LegacyContactEntity> createLegacyContact(Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<LegacyContactEntity> updateLegacyContact(String id, Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteLegacyContact(String id) async {}

  @override
  Future<void> resendVerification(String id) async {}

  @override
  Future<void> revokeLegacyContact(String id) async {}

  @override
  Future<List<LegacyAccessRequestEntity>> getAccessRequests() async => [];

  @override
  Future<LegacyAccessRequestEntity> approveAccessRequest(String id) async => throw UnimplementedError();

  @override
  Future<LegacyAccessRequestEntity> denyAccessRequest(String id) async => throw UnimplementedError();

  @override
  Future<EstateReportEntity> getEstateReport(String requestId) async => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.creditbook.test/api/v1');
  });

  group('LegacyRemoteDataSourceImpl - Resilience & Auto-Enable Retry', () {
    test('automatically enables legacy access and retries when server returns 422 legacy access error', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'mock-auth-token'});
      final prefs = await SharedPreferences.getInstance();

      int postContactsCalls = 0;
      bool enableCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/legacy-contacts') {
          postContactsCalls++;
          if (postContactsCalls == 1) {
            // First attempt rejected because legacy access was not enabled
            return http.Response(
              jsonEncode({'message': 'Legacy access must be enabled before adding a contact.'}),
              422,
            );
          } else {
            // Second attempt after auto-enabling succeeds
            return http.Response(
              jsonEncode({
                'contact': {
                  'id': 'contact-uuid-999',
                  'full_name': 'Sarah Connor',
                  'email': 'sarah@example.com',
                  'phone': '+2348011223344',
                  'relationship': 'Spouse',
                  'is_primary': true,
                  'verification_status': 'VERIFIED',
                  'access_code': 'ABC2XYZ9',
                }
              }),
              201,
            );
          }
        } else if (request.url.path == '/api/v1/legacy/enable') {
          enableCalled = true;
          return http.Response(jsonEncode({'recovery_code': 'ABCD-1234-EFGH'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = LegacyRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final contact = await dataSource.createLegacyContact({
        'full_name': 'Sarah Connor',
        'email': 'sarah@example.com',
        'phone': '+2348011223344',
        'relationship': 'Spouse',
        'is_primary': true,
      });

      expect(postContactsCalls, 2);
      expect(enableCalled, isTrue);
      expect(contact.fullName, 'Sarah Connor');
      expect(contact.accessCode, 'ABC2XYZ9');
    });
  });

  group('SubmitAccessRequestScreen Widget Tests', () {
    late _FakeLegacyRepo fakeRepo;

    setUp(() {
      fakeRepo = _FakeLegacyRepo();
    });

    testWidgets('renders Nominee Access Portal and inputs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LegacyBloc>(
            create: (_) => LegacyBloc(repository: fakeRepo),
            child: const SubmitAccessRequestScreen(),
          ),
        ),
      );

      expect(find.text('Nominee Access Portal'), findsOneWidget);
      expect(find.text('Your Access Code *'), findsOneWidget);
      expect(find.text('Medical Emergency'), findsOneWidget);
    });

    testWidgets('submits access request and shows View Financial Ledger when approved', (tester) async {
      fakeRepo.requestToReturn = const LegacyAccessRequestEntity(
        id: 'approved-req-001',
        reason: 'medical_emergency',
        recoveryCodeProvided: false,
        status: 'APPROVED',
        statusLabel: 'Approved',
        grantsAccess: true,
        waitingPeriodDays: 30,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LegacyBloc>(
            create: (_) => LegacyBloc(repository: fakeRepo),
            child: const SubmitAccessRequestScreen(),
          ),
        ),
      );

      // Enter 8 character access code
      await tester.enterText(find.byType(TextFormField).first, 'ABC2XYZ9');
      await tester.pumpAndSettle();

      // Ensure visible and submit
      final submitFinder = find.text('Submit Access Request');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(fakeRepo.submitCalled, isTrue);
      expect(find.text('Access Authorized'), findsOneWidget);
      expect(find.text('View Financial Ledger'), findsOneWidget);
    });
  });
}
