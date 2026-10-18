import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:creditbook/features/people/domain/entities/contact_entity.dart';
import 'package:creditbook/features/people/domain/entities/debt_with_contact_entity.dart';
import 'package:creditbook/features/people/domain/repositories/people_repository.dart';
import 'package:creditbook/features/people/presentation/bloc/people_bloc.dart';
import 'package:creditbook/features/people/presentation/pages/people_screen.dart';
import 'package:creditbook/features/people/data/models/debt_model.dart';

class _MockPeopleRepository implements PeopleRepository {
  PeopleDataEntity? localData;
  int serverFetchCalls = 0;

  _MockPeopleRepository({this.localData});

  @override
  PeopleDataEntity? getCachedPeopleData() => localData;

  @override
  Future<PeopleDataEntity> getPeopleData({bool forceRefresh = false}) async {
    if (!forceRefresh && localData != null) {
      return localData!;
    }
    serverFetchCalls++;
    return localData ?? const PeopleDataEntity(favorites: [], frequentlyContacted: [], allContacts: []);
  }

  @override
  Future<ContactEntity> createContact(Map<String, dynamic> contactData) async {
    final contact = ContactEntity(
      id: 'c-new',
      fullName: contactData['full_name'] ?? 'New Contact',
      isFavorite: contactData['is_favorite'] == true,
      totalOwedToUser: 0,
      totalUserOwes: 0,
      updatedAt: '2026-10-18T10:00:00Z',
    );
    final favs = List<ContactEntity>.from(localData?.favorites ?? []);
    if (contact.isFavorite) favs.add(contact);
    final all = List<ContactEntity>.from(localData?.allContacts ?? [])..insert(0, contact);
    localData = PeopleDataEntity(
      favorites: favs,
      frequentlyContacted: localData?.frequentlyContacted ?? [],
      allContacts: all,
    );
    return contact;
  }

  @override
  Future<ContactEntity> updateContact(String id, Map<String, dynamic> contactData) async => throw UnimplementedError();

  @override
  Future<void> deleteContact(String id) async => throw UnimplementedError();

  @override
  Future<void> syncContactsOnLogin(String userId) async {}

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
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createWidgetUnderTest(PeopleRepository repository) {
    final router = GoRouter(
      initialLocation: '/people',
      routes: [
        GoRoute(
          path: '/people',
          builder: (context, state) => BlocProvider<PeopleBloc>(
            create: (_) => PeopleBloc(repository: repository)..add(LoadPeopleDataRequested()),
            child: const PeopleScreen(),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('PeopleScreen immediately loads and displays contacts from local storage without server fetch', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = _MockPeopleRepository(
      localData: const PeopleDataEntity(
        favorites: [
          ContactEntity(
            id: 'c-1',
            fullName: 'Sarah Connor',
            isFavorite: true,
            totalOwedToUser: 15000,
            totalUserOwes: 0,
            updatedAt: '2026-10-18T10:00:00Z',
          ),
        ],
        frequentlyContacted: [],
        allContacts: [
          ContactEntity(
            id: 'c-1',
            fullName: 'Sarah Connor',
            isFavorite: true,
            totalOwedToUser: 15000,
            totalUserOwes: 0,
            updatedAt: '2026-10-18T10:00:00Z',
          ),
          ContactEntity(
            id: 'c-2',
            fullName: 'John Connor',
            isFavorite: false,
            totalOwedToUser: 0,
            totalUserOwes: 5000,
            updatedAt: '2026-10-18T10:00:00Z',
          ),
        ],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest(mockRepo));
    await tester.pumpAndSettle(); // settle animations

    expect(find.text('People'), findsWidgets);
    expect(find.text('FAVORITES'), findsOneWidget);
    expect(find.text('ALL CONTACTS'), findsOneWidget);
    expect(find.text('Sarah Connor'), findsWidgets);
    expect(find.text('John Connor'), findsOneWidget);

    // Verify 0 server fetch calls were made because data was loaded from local storage
    expect(mockRepo.serverFetchCalls, 0);
  });
}
