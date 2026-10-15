import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/presentation/pages/profile_photo_setup_screen.dart';
import 'package:creditbook/features/auth/domain/repositories/auth_repository.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';
import 'package:creditbook/core/widgets/user_avatar.dart';

class _MockAuthRepo implements AuthRepository {
  User? user;
  _MockAuthRepo({this.user});

  @override
  Future<User> getCurrentUser() async => user ?? const User(id: '1', name: 'John Doe', hasPin: true);
  @override
  Future<User?> getCachedUser() async => user;
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
  Future<User> uploadAvatar(File imageFile) async {
    final updated = (user ?? const User(id: '1', name: 'John Doe', hasPin: true)).copyWith(
      avatarUrl: 'https://example.com/avatar.jpg',
    );
    user = updated;
    return updated;
  }
  @override
  Future<User> deleteAvatar() async => throw UnimplementedError();
  @override
  Future<bool> refreshToken() async => true;
}

void main() {
  late AuthBloc authBloc;
  late _MockAuthRepo mockRepo;

  setUp(() {
    mockRepo = _MockAuthRepo(user: const User(id: '1', name: 'John Doe', hasPin: true));
    authBloc = AuthBloc(authRepository: mockRepo);
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/setup-photo',
      routes: [
        GoRoute(
          path: '/setup-photo',
          builder: (context, state) => const ProfilePhotoSetupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('ProfilePhotoSetupScreen renders correctly with optional badge, avatar, and buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Add a Profile Photo'), findsOneWidget);
    expect(find.text('OPTIONAL STEP'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Choose Photo'), findsOneWidget);
    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text("I'll do this later"), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
  });

  testWidgets('Tapping Skip navigates to /home', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets("Tapping I'll do this later navigates to /home", (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("I'll do this later"));
    await tester.tap(find.text("I'll do this later"));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('Tapping Choose Photo opens photo options bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
  });
}
