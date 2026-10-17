import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/presentation/pages/primary_nominee_setup_screen.dart';
import 'package:creditbook/features/auth/domain/repositories/auth_repository.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';
import 'package:creditbook/features/legacy/presentation/bloc/legacy_bloc.dart';
import 'package:creditbook/features/legacy/domain/repositories/legacy_repository.dart';
import 'package:creditbook/features/legacy/domain/entities/legacy_contact_entity.dart';
import 'package:creditbook/features/legacy/domain/entities/legacy_access_request_entity.dart';

class _MockAuthRepo implements AuthRepository {
  @override
  Future<User> getCurrentUser() async => const User(id: '1', name: 'John Doe', hasPin: true);
  @override
  Future<User?> getCachedUser() async => const User(id: '1', name: 'John Doe', hasPin: true);
  @override
  Future<User> login(String phoneNumber, String pin) async => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<User> register(String name, String phoneNumber, {String? currency}) async => throw UnimplementedError();
  @override
  Future<void> setLoginPin(String pin) async {}
  @override
  Future<User> updateProfile({String? name, String? email, String? defaultCurrency}) async => throw UnimplementedError();
  @override
  Future<User> uploadAvatar(dynamic imageFile) async => throw UnimplementedError();
  @override
  Future<User> deleteAvatar() async => throw UnimplementedError();
  @override
  Future<bool> refreshToken() async => true;
  @override
  Future<Map<String, dynamic>> forgotPin(String phoneNumber) async => throw UnimplementedError();
  @override
  Future<String> verifyPinResetCode(String phoneNumber, String code) async => throw UnimplementedError();
  @override
  Future<User> resetPin(String phoneNumber, String resetToken, String newPin) async => throw UnimplementedError();
  @override
  Future<User> verifyTwoFactor(String twoFactorToken, String code, {String? method}) async => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> resendTwoFactor(String twoFactorToken, {String? method}) async => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> switchTwoFactorMethod(String twoFactorToken, String method) async => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> sendTwoFactorSetupCode({String method = 'authenticator', String? email, String? phoneNumber}) async => throw UnimplementedError();
  @override
  Future<User> enableTwoFactor(String code, {String method = 'authenticator'}) async => throw UnimplementedError();
  @override
  Future<User> disableTwoFactor({String? pin}) async => throw UnimplementedError();
}

class _MockLegacyRepo implements LegacyRepository {
  Map<String, dynamic>? lastCreatedData;

  @override
  Future<LegacySettingsEntity> getSettings() async {
    return const LegacySettingsEntity(
      legacyAccessEnabled: true,
      legacyWaitingPeriodDays: 30,
      hasRecoveryCode: false,
      contactsCount: 0,
      verifiedContactsCount: 0,
    );
  }

  @override
  Future<String?> enableLegacyAccess() async => 'ABC-123';

  @override
  Future<void> disableLegacyAccess() async {}

  @override
  Future<List<LegacyContactEntity>> getLegacyContacts() async => [];

  @override
  Future<LegacyContactEntity> createLegacyContact(Map<String, dynamic> data) async {
    lastCreatedData = data;
    return LegacyContactEntity(
      id: 'contact_1',
      fullName: data['full_name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      relationship: data['relationship'] as String,
      isPrimary: data['is_primary'] as bool? ?? true,
      verificationStatus: 'PENDING',
    );
  }

  @override
  Future<LegacyContactEntity> updateLegacyContact(String id, Map<String, dynamic> data) async => throw UnimplementedError();
  @override
  Future<void> deleteLegacyContact(String id) async {}
  @override
  Future<void> resendVerification(String id) async {}
  @override
  Future<void> revokeLegacyContact(String id) async {}
  @override
  Future<LegacyAccessRequestEntity> submitAccessRequest(Map<String, dynamic> data) async => throw UnimplementedError();
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
  late AuthBloc authBloc;
  late LegacyBloc legacyBloc;
  late _MockLegacyRepo mockLegacyRepo;

  setUp(() {
    authBloc = AuthBloc(authRepository: _MockAuthRepo());
    mockLegacyRepo = _MockLegacyRepo();
    legacyBloc = LegacyBloc(repository: mockLegacyRepo);
  });

  tearDown(() {
    authBloc.close();
    legacyBloc.close();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/setup-nominee',
      routes: [
        GoRoute(
          path: '/setup-nominee',
          builder: (context, state) => const PrimaryNomineeSetupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<LegacyBloc>.value(value: legacyBloc),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('PrimaryNomineeSetupScreen renders title, badge, fields, and buttons', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('OPTIONAL STEP'), findsOneWidget);
    expect(find.text('Add Primary Nominee'), findsOneWidget);
    expect(find.text('Designated as Primary Nominee'), findsOneWidget);
    expect(find.text('Full Legal Name *'), findsOneWidget);
    expect(find.text('Relationship *'), findsOneWidget);
    expect(find.text('Email Address *'), findsOneWidget);
    expect(find.text('Phone Number *'), findsOneWidget);
    expect(find.text('Save Primary Nominee'), findsOneWidget);
    expect(find.text("I'll add a nominee later"), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Tapping Skip navigates to /home', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets("Tapping I'll add a nominee later navigates to /home", (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("I'll add a nominee later"));
    await tester.tap(find.text("I'll add a nominee later"));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('Submitting empty form displays validation errors', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Primary Nominee'));
    await tester.tap(find.text('Save Primary Nominee'));
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Please select a relationship'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('Valid submission saves primary nominee and navigates to /home', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Fill Name
    await tester.ensureVisible(find.byType(EditableText).at(0));
    await tester.enterText(find.byType(EditableText).at(0), 'Jane Doe');
    await tester.pumpAndSettle();

    // Select Relationship
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spouse').last);
    await tester.pumpAndSettle();

    // Fill Email
    await tester.ensureVisible(find.byType(EditableText).at(1));
    await tester.enterText(find.byType(EditableText).at(1), 'jane@example.com');
    await tester.pumpAndSettle();

    // Fill Phone
    await tester.ensureVisible(find.byType(EditableText).at(2));
    await tester.enterText(find.byType(EditableText).at(2), '8012345678');
    await tester.pumpAndSettle();

    // Submit
    await tester.ensureVisible(find.text('Save Primary Nominee'));
    await tester.tap(find.text('Save Primary Nominee'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(mockLegacyRepo.lastCreatedData, isNotNull);
    expect(mockLegacyRepo.lastCreatedData!['full_name'], equals('Jane Doe'));
    expect(mockLegacyRepo.lastCreatedData!['email'], equals('jane@example.com'));
    expect(mockLegacyRepo.lastCreatedData!['relationship'], equals('Spouse'));
    expect(mockLegacyRepo.lastCreatedData!['is_primary'], isTrue);

    expect(find.text('Home Screen'), findsOneWidget);
  });
}
