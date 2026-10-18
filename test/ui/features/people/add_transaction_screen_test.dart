import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/features/people/domain/entities/contact_entity.dart';
import 'package:creditbook/features/people/domain/entities/debt_with_contact_entity.dart';
import 'package:creditbook/features/people/domain/repositories/people_repository.dart';
import 'package:creditbook/features/people/presentation/bloc/add_transaction_bloc.dart';
import 'package:creditbook/features/people/presentation/pages/add_transaction_screen.dart';
import 'package:creditbook/features/settings/presentation/widgets/set_transaction_pin_modal.dart';
import 'package:creditbook/features/people/presentation/widgets/confirm_transaction_pin_modal.dart';
import 'package:creditbook/features/people/data/models/debt_model.dart';

class _FakePeopleRepository implements PeopleRepository {
  final List<ContactEntity> contacts;

  _FakePeopleRepository({this.contacts = const []});

  @override
  PeopleDataEntity? getCachedPeopleData() => null;

  @override
  Future<PeopleDataEntity> getPeopleData({bool forceRefresh = false}) async {
    return PeopleDataEntity(
      favorites: [],
      frequentlyContacted: [],
      allContacts: contacts,
    );
  }

  @override
  Future<ContactEntity> createContact(Map<String, dynamic> contactData) async => throw UnimplementedError();

  @override
  Future<ContactEntity> updateContact(String id, Map<String, dynamic> contactData) async => throw UnimplementedError();

  @override
  Future<void> deleteContact(String id) async => throw UnimplementedError();

  @override
  Future<void> syncContactsOnLogin(String userId) async {}

  @override
  Future<void> clearLocalContacts() async {}

  @override
  Future<dynamic> createTransaction(Map<String, dynamic> transactionData) async => {};

  @override
  Future<ContactEntity> getContactDetails(String id, {bool forceRefresh = false}) async => throw UnimplementedError();

  @override
  ContactEntity? getCachedContactDetails(String id) => null;

  @override
  Future<DebtEntity> createDebt(Map<String, dynamic> data) async => throw UnimplementedError();

  @override
  Future<void> recordPayment({required String debtId, required double amount, String? note, String? clientId, String? contactId}) async {}

  @override
  Future<DebtsWithStatistics> getAllDebtsWithStats({String status = 'all', bool forceRefresh = false}) async => throw UnimplementedError();

  @override
  DebtsWithStatistics? getCachedAllDebtsWithStats({String status = 'all'}) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePeopleRepository fakeRepo;

  const testContact = ContactEntity(
    id: 'c-1',
    fullName: 'Idris Tester',
    isFavorite: false,
    totalOwedToUser: 0,
    totalUserOwes: 0,
    updatedAt: '2026-10-18T10:00:00Z',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeRepo = _FakePeopleRepository(contacts: [testContact]);
  });

  Widget buildTestWidget({GoRouter? router}) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/add-transaction',
          routes: [
            GoRoute(
              path: '/add-transaction',
              builder: (context, state) => BlocProvider<AddTransactionBloc>(
                create: (_) => AddTransactionBloc(repository: fakeRepo),
                child: const AddTransactionScreen(),
              ),
            ),
            GoRoute(
              path: '/settings/face-setup',
              builder: (context, state) => const Scaffold(
                body: Text('Face Setup Screen Target'),
              ),
            ),
          ],
        );

    return MaterialApp.router(
      routerConfig: effectiveRouter,
    );
  }

  Future<void> selectContactAndEnterLargeAmount(WidgetTester tester) async {
    // Select contact from horizontal list
    final contactFinder = find.text('Idris');
    expect(contactFinder, findsOneWidget);
    await tester.tap(contactFinder);
    await tester.pumpAndSettle();

    // Tap numpad keys to enter 100000
    await tester.tap(find.widgetWithText(GestureDetector, '1'));
    await tester.pumpAndSettle();
    for (int i = 0; i < 5; i++) {
      await tester.tap(find.widgetWithText(GestureDetector, '0'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('Large transaction without Face ID shows dialog with Set up Face ID and Use PIN instead', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await selectContactAndEnterLargeAmount(tester);

    final saveButton = find.text('Save Transaction');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Dialog should be visible
    expect(find.text('Action Required'), findsOneWidget);
    expect(
      find.text('Transactions of this size require biometric verification. Please set up your Face ID in Settings.'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Use PIN instead'), findsOneWidget);
    expect(find.text('Set up Face ID'), findsOneWidget);
  });

  testWidgets('Tapping Set up Face ID navigates to biometric setup route', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await selectContactAndEnterLargeAmount(tester);

    final saveButton = find.text('Save Transaction');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Tap "Set up Face ID"
    await tester.tap(find.text('Set up Face ID'));
    await tester.pumpAndSettle();

    // Should navigate to Face Setup Screen Target
    expect(find.text('Face Setup Screen Target'), findsOneWidget);
  });

  testWidgets('Tapping Use PIN instead when no PIN is set triggers PIN setup modal', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await selectContactAndEnterLargeAmount(tester);

    final saveButton = find.text('Save Transaction');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Tap "Use PIN instead"
    await tester.tap(find.text('Use PIN instead'));
    await tester.pumpAndSettle();

    // Should trigger SetTransactionPinModal
    expect(find.byType(SetTransactionPinModal), findsOneWidget);
    expect(find.text('Create a 4-digit PIN'), findsOneWidget);
  });

  testWidgets('Tapping Use PIN instead when PIN is already set triggers ConfirmTransactionPinModal', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Mock existing PIN
    SharedPreferences.setMockInitialValues({'transaction_pin': '1234'});

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await selectContactAndEnterLargeAmount(tester);

    final saveButton = find.text('Save Transaction');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Tap "Use PIN instead"
    await tester.tap(find.text('Use PIN instead'));
    await tester.pumpAndSettle();

    // Should trigger ConfirmTransactionPinModal
    expect(find.byType(ConfirmTransactionPinModal), findsOneWidget);
    expect(find.text('TOTAL AMOUNT'), findsOneWidget);
    expect(find.text('Enter your 4-digit PIN'), findsOneWidget);
  });
}
