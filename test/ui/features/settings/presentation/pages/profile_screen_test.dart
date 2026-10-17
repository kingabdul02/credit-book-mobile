import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_state.dart';
import 'package:creditbook/features/auth/domain/repositories/auth_repository.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';
import 'package:creditbook/features/settings/presentation/pages/profile_screen.dart';
import 'package:creditbook/core/widgets/user_avatar.dart';

class _MockProfileAuthRepository implements AuthRepository {
  User? currentUser;

  _MockProfileAuthRepository({this.currentUser});

  @override
  Future<User> getCurrentUser() async {
    if (currentUser != null) return currentUser!;
    throw UnimplementedError();
  }

  @override
  Future<User?> getCachedUser() async => currentUser;

  @override
  Future<User> login(String phoneNumber, String pin) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<User> register(String name, String phoneNumber, {String? currency}) async => throw UnimplementedError();

  @override
  Future<void> setLoginPin(String pin) async {}

  @override
  Future<User> updateProfile({String? name, String? email, String? defaultCurrency}) async {
    final updated = (currentUser ?? const User(id: '1', name: 'User', hasPin: false)).copyWith(
      name: name,
      email: email,
      defaultCurrency: defaultCurrency,
    );
    currentUser = updated;
    return updated;
  }

  @override
  Future<User> uploadAvatar(File imageFile) async {
    final updated = (currentUser ?? const User(id: '1', name: 'User', hasPin: false)).copyWith(
      avatarUrl: 'https://example.com/avatar.jpg',
    );
    currentUser = updated;
    return updated;
  }

  @override
  Future<User> deleteAvatar() async {
    final updated = (currentUser ?? const User(id: '1', name: 'User', hasPin: false)).copyWith(
      clearAvatarUrl: true,
    );
    currentUser = updated;
    return updated;
  }

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

void main() {
  const testUser = User(
    id: 'user-123',
    name: 'Adebayo Johnson',
    phoneNumber: '+2348012345678',
    email: 'adebayo@example.com',
    defaultCurrency: 'NGN',
    hasPin: true,
  );

  Widget createWidgetUnderTest(AuthBloc authBloc) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  testWidgets('ProfileScreen renders user details and default avatar when avatarUrl is null', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = _MockProfileAuthRepository(currentUser: testUser);
    final authBloc = AuthBloc(authRepository: repo);
    authBloc.emit(const AuthSuccess(testUser));

    await tester.pumpWidget(createWidgetUnderTest(authBloc));
    await tester.pumpAndSettle();

    // Verify title and user details
    expect(find.text('Personal Profile'), findsOneWidget);
    expect(find.text('Adebayo Johnson'), findsWidgets);
    expect(find.text('+2348012345678'), findsWidgets);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('adebayo@example.com'), findsOneWidget);
    expect(find.text('Upload Photo'), findsOneWidget);

    // Verify UserAvatar renders default person icon
    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('ProfileScreen renders Change Photo when user has avatarUrl', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    const userWithAvatar = User(
      id: 'user-123',
      name: 'Adebayo Johnson',
      phoneNumber: '+2348012345678',
      email: 'adebayo@example.com',
      avatarUrl: 'https://example.com/avatar.jpg',
      defaultCurrency: 'NGN',
      hasPin: true,
    );

    final repo = _MockProfileAuthRepository(currentUser: userWithAvatar);
    final authBloc = AuthBloc(authRepository: repo);
    authBloc.emit(const AuthSuccess(userWithAvatar));

    await tester.pumpWidget(createWidgetUnderTest(authBloc));
    await tester.pumpAndSettle();

    expect(find.text('Change Photo'), findsOneWidget);
  });

  testWidgets('Tapping photo button opens photo options bottom sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = _MockProfileAuthRepository(currentUser: testUser);
    final authBloc = AuthBloc(authRepository: repo);
    authBloc.emit(const AuthSuccess(testUser));

    await tester.pumpWidget(createWidgetUnderTest(authBloc));
    await tester.pumpAndSettle();

    // Tap photo button
    await tester.tap(find.text('Upload Photo'));
    await tester.pumpAndSettle();

    // Verify bottom sheet appears
    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
  });

  testWidgets('UserAvatar displays default icon when avatarUrl is null and handles tapping', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserAvatar(
            avatarUrl: null,
            radius: 24,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    await tester.tap(find.byType(UserAvatar));
    expect(tapped, isTrue);
  });
}
