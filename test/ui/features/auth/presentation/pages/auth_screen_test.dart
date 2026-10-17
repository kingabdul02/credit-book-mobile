import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:creditbook/features/auth/presentation/pages/auth_screen.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/domain/repositories/auth_repository.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';

class _MockAuthRepository implements AuthRepository {
  @override
  Future<User> getCurrentUser() async => throw UnimplementedError();
  @override
  Future<User?> getCachedUser() async => null;
  @override
  Future<User> login(String phoneNumber, String pin) async => throw UnimplementedError();
  @override
  Future<void> logout() async => throw UnimplementedError();
  @override
  Future<User> register(String name, String phoneNumber, {String? currency}) async => throw UnimplementedError();
  @override
  Future<void> setLoginPin(String pin) async => throw UnimplementedError();
  @override
  Future<User> updateProfile({String? name, String? email, String? defaultCurrency}) async => throw UnimplementedError();
  @override
  Future<User> uploadAvatar(File imageFile) async => throw UnimplementedError();
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

void main() {
  late AuthBloc authBloc;

  setUp(() {
    authBloc = AuthBloc(authRepository: _MockAuthRepository());
  });

  Widget createWidgetUnderTest() {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const MaterialApp(
        home: AuthScreen(),
      ),
    );
  }

  testWidgets('AuthScreen renders correctly and shows Login by default', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back to clarity.'), findsOneWidget);
    expect(find.text('Login'), findsWidgets); // Button and toggle text
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('6-Digit PIN'), findsOneWidget);
    expect(find.text('Full Name'), findsNothing); // Should not show in login

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('AuthScreen toggles to Sign Up when tapped', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Ensure "Create Account" toggle is visible before tapping
    final signUpFinder = find.text('Create Account').last;
    await tester.ensureVisible(signUpFinder);
    await tester.tap(signUpFinder);
    await tester.pumpAndSettle();

    expect(find.text('Financial clarity for your business.'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget); // Should show in sign up
    expect(find.text('Phone Number'), findsOneWidget); // Shared field
    expect(find.text('6-Digit PIN'), findsNothing); // Should hide in sign up
    expect(find.text('Login'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('AuthScreen does not overflow on short screens', (WidgetTester tester) async {
    // Simulate a very short screen
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back to clarity.'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
