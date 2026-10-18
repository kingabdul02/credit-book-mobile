import 'package:creditbook/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:creditbook/features/legacy/domain/entities/legacy_access_request_entity.dart';
import 'package:creditbook/features/legacy/domain/entities/legacy_contact_entity.dart';
import 'package:creditbook/features/legacy/domain/repositories/legacy_repository.dart';
import 'package:creditbook/features/legacy/presentation/bloc/legacy_bloc.dart';
import 'package:creditbook/features/legacy/presentation/pages/next_of_kin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _MockLegacyRepo implements LegacyRepository {
  LegacySettingsEntity settings = const LegacySettingsEntity(
    legacyAccessEnabled: true,
    legacyWaitingPeriodDays: 30,
    hasRecoveryCode: true,
    contactsCount: 1,
    verifiedContactsCount: 1,
  );

  List<LegacyContactEntity> contacts = [
    const LegacyContactEntity(
      id: 'contact-1',
      fullName: 'John Doe',
      email: 'john@example.com',
      phone: '+2348012345678',
      relationship: 'Brother',
      isPrimary: true,
      verificationStatus: 'VERIFIED',
      accessCode: 'ABCD-1234',
    ),
  ];

  @override
  Future<LegacySettingsEntity> getSettings({bool forceRefresh = false}) async => settings;

  @override
  LegacySettingsEntity? getCachedSettings() => null;

  @override
  Future<List<LegacyContactEntity>> getLegacyContacts({bool forceRefresh = false}) async => contacts;

  @override
  List<LegacyContactEntity>? getCachedLegacyContacts() => null;

  @override
  List<LegacyAccessRequestEntity>? getCachedAccessRequests() => null;

  @override
  Future<String> enableLegacyAccess() async => 'RECOVERY-CODE';

  @override
  Future<void> disableLegacyAccess() async {}

  @override
  Future<LegacyContactEntity> createLegacyContact(Map<String, dynamic> data) async => throw UnimplementedError();

  @override
  Future<LegacyContactEntity> updateLegacyContact(String id, Map<String, dynamic> data) async => throw UnimplementedError();

  @override
  Future<void> deleteLegacyContact(String id) async {}

  @override
  Future<void> resendVerification(String id) async {}

  @override
  Future<void> revokeLegacyContact(String id) async {}

  @override
  Future<List<LegacyAccessRequestEntity>> getAccessRequests({bool forceRefresh = false}) async => [];

  @override
  Future<LegacyAccessRequestEntity> submitAccessRequest(Map<String, dynamic> data) async => throw UnimplementedError();

  @override
  Future<LegacyAccessRequestEntity> approveAccessRequest(String id) async => throw UnimplementedError();

  @override
  Future<LegacyAccessRequestEntity> denyAccessRequest(String id) async => throw UnimplementedError();

  @override
  Future<EstateReportEntity> getEstateReport(String requestId) async => throw UnimplementedError();
}

void main() {
  late _MockLegacyRepo mockRepo;
  late LegacyBloc legacyBloc;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    mockRepo = _MockLegacyRepo();
    legacyBloc = LegacyBloc(repository: mockRepo);
  });

  tearDown(() {
    legacyBloc.close();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/next-of-kin',
      routes: [
        GoRoute(
          path: '/next-of-kin',
          builder: (context, state) => const NextOfKinScreen(),
        ),
        GoRoute(
          path: '/access-requests',
          builder: (context, state) => const Scaffold(body: Text('Access Requests Screen')),
        ),
        GoRoute(
          path: '/next-of-kin/add',
          builder: (context, state) => const Scaffold(body: Text('Add Nominee Screen')),
        ),
      ],
    );

    return BlocProvider<LegacyBloc>.value(
      value: legacyBloc,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('NextOfKinScreen loads and renders primary nominee and settings', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    legacyBloc.emit(LegacyLoaded(settings: mockRepo.settings, contacts: mockRepo.contacts));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Next of Kin'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Brother'), findsOneWidget);
    expect(find.text('Access Requests'), findsOneWidget);
  });

  testWidgets('NextOfKinScreen retains cached data and does not blank out on unrelated states', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    legacyBloc.emit(LegacyLoaded(settings: mockRepo.settings, contacts: mockRepo.contacts));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('John Doe'), findsOneWidget);

    // Emit AccessRequestsLoaded to simulate returning or switching to access request state
    legacyBloc.emit(AccessRequestsLoaded(requests: []));
    await tester.pump();

    // Verify John Doe is still rendered and screen has NOT collapsed to empty content
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('No primary nominee added'), findsNothing);
  });

  testWidgets('NextOfKinScreen displays AppErrorView on initial load error without redundant SnackBar', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    legacyBloc.emit(LegacyError('Unable to connect to the server. Please check your internet connection and try again.'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // AppErrorView should be displayed
    expect(find.text('Unable to connect to the server. Please check your internet connection and try again.'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    // No SnackBar should be rendered on initial load error
    expect(find.byType(SnackBar), findsNothing);
  });
}
