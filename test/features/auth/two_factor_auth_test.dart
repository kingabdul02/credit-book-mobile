import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';
import 'package:creditbook/features/auth/data/models/user_model.dart';
import 'package:creditbook/features/auth/domain/repositories/auth_repository.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_event.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_state.dart';
import 'package:creditbook/features/auth/presentation/pages/verify_2fa_screen.dart';
import 'package:creditbook/features/settings/presentation/widgets/two_factor_modal.dart';

class _MockTwoFactorAuthRepo implements AuthRepository {
  String? lastVerifyToken;
  String? lastVerifyCode;
  String? lastVerifyMethod;
  String? lastResendToken;
  String? lastSwitchMethod;
  String? lastSetupMethod;
  String? lastEnableCode;
  String? lastEnableMethod;
  String? lastDisablePin;

  User user = const User(
    id: 'user-007',
    name: 'James Bond',
    phoneNumber: '+2348011223344',
    email: 'bond@mi6.gov.uk',
    hasPin: true,
    twoFactorEnabled: false,
    twoFactorMethod: 'authenticator',
  );

  @override
  Future<User> verifyTwoFactor(String twoFactorToken, String code, {String? method}) async {
    lastVerifyToken = twoFactorToken;
    lastVerifyCode = code;
    lastVerifyMethod = method;
    return user.copyWith(twoFactorEnabled: true, twoFactorMethod: method ?? 'authenticator');
  }

  @override
  Future<Map<String, dynamic>> resendTwoFactor(String twoFactorToken, {String? method}) async {
    lastResendToken = twoFactorToken;
    return {
      'method': method ?? 'authenticator',
      'message': 'A new verification code has been sent.',
      'debug_code': '654321',
    };
  }

  @override
  Future<Map<String, dynamic>> switchTwoFactorMethod(String twoFactorToken, String method) async {
    lastSwitchMethod = method;
    return {
      'method': method,
      'message': 'Switched to $method verification.',
      'email': user.email,
      'phone_number': user.phoneNumber,
      'debug_code': '112233',
    };
  }

  @override
  Future<Map<String, dynamic>> sendTwoFactorSetupCode({
    String method = 'authenticator',
    String? email,
    String? phoneNumber,
  }) async {
    lastSetupMethod = method;
    return {
      'method': method,
      'secret': 'JBSWY3DPEHPK3PXP',
      'otpauth_url': 'otpauth://totp/CreditBook?secret=JBSWY3DPEHPK3PXP',
      'qr_code_url': null,
      'message': 'Setup code sent.',
      'email': email ?? user.email,
      'debug_code': '999888',
    };
  }

  @override
  Future<User> enableTwoFactor(String code, {String method = 'authenticator'}) async {
    lastEnableCode = code;
    lastEnableMethod = method;
    user = user.copyWith(twoFactorEnabled: true, twoFactorMethod: method);
    return user;
  }

  @override
  Future<User> disableTwoFactor({String? pin}) async {
    lastDisablePin = pin;
    user = user.copyWith(twoFactorEnabled: false);
    return user;
  }

  @override
  Future<User?> getCachedUser() async => user;
  @override
  Future<User> getCurrentUser() async => user;
  @override
  Future<User> login(String phoneNumber, String pin) async => user;
  @override
  Future<void> logout() async {}
  @override
  Future<User> register(String name, String phoneNumber, {String? currency}) async => user;
  @override
  Future<void> setLoginPin(String pin) async {}
  @override
  Future<User> updateProfile({String? name, String? email, String? defaultCurrency}) async => user;
  @override
  Future<User> uploadAvatar(dynamic imageFile) async => user;
  @override
  Future<User> deleteAvatar() async => user;
  @override
  Future<bool> refreshToken() async => true;
  @override
  Future<Map<String, dynamic>> forgotPin(String phoneNumber) async => {};
  @override
  Future<String> verifyPinResetCode(String phoneNumber, String code) async => 'token';
  @override
  Future<User> resetPin(String phoneNumber, String resetToken, String newPin) async => user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('2FA Entity & Model Tests', () {
    test('UserModel correctly serializes and deserializes twoFactorEnabled and twoFactorMethod', () {
      final json = {
        'id': 'u1',
        'name': 'Test User',
        'phone_number': '+2348000000000',
        'two_factor_enabled': true,
        'two_factor_method': 'authenticator',
      };

      final model = UserModel.fromJson(json);
      expect(model.twoFactorEnabled, isTrue);
      expect(model.twoFactorMethod, 'authenticator');

      final outJson = model.toJson();
      expect(outJson['two_factor_enabled'], isTrue);
      expect(outJson['two_factor_method'], 'authenticator');
    });

    test('User copyWith updates twoFactorMethod accurately', () {
      const user = User(
        id: 'u1',
        name: 'Test',
        phoneNumber: '+2348000000000',
        hasPin: true,
        twoFactorEnabled: true,
        twoFactorMethod: 'authenticator',
      );

      final updated = user.copyWith(twoFactorMethod: 'email');
      expect(updated.twoFactorMethod, 'email');
    });
  });

  group('Verify2faScreen Widget Tests', () {
    late _MockTwoFactorAuthRepo mockRepo;
    late AuthBloc authBloc;

    setUp(() {
      mockRepo = _MockTwoFactorAuthRepo();
      authBloc = AuthBloc(authRepository: mockRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('renders Authenticator App verification by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const Verify2faScreen(
              twoFactorToken: 'test-2fa-token-123',
              phoneNumber: '+2348011223344',
              email: 'bond@mi6.gov.uk',
              initialMethod: 'authenticator',
              debugCode: '123456',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Authenticator App'), findsOneWidget);
      expect(find.text('AUTHENTICATOR (DEFAULT)'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.text('Try another verification method'), findsOneWidget);
    });

    testWidgets('tapping "Try another verification method" opens method selector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const Verify2faScreen(
              twoFactorToken: 'test-2fa-token-123',
              phoneNumber: '+2348011223344',
              email: 'bond@mi6.gov.uk',
              initialMethod: 'authenticator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final switchBtn = find.text('Try another verification method');
      await tester.ensureVisible(switchBtn);
      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      expect(find.text('Choose Verification Method'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('SMS / Phone Number'), findsOneWidget);
    });

    testWidgets('submitting valid 6-digit code triggers VerifyTwoFactorRequested with authenticator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const Verify2faScreen(
              twoFactorToken: 'test-2fa-token-123',
              phoneNumber: '+2348011223344',
              email: 'bond@mi6.gov.uk',
              initialMethod: 'authenticator',
              debugCode: '789012',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastVerifyToken, 'test-2fa-token-123');
      expect(mockRepo.lastVerifyCode, '789012');
      expect(mockRepo.lastVerifyMethod, 'authenticator');
    });

    testWidgets('switching method to Email triggers SwitchTwoFactorMethodRequested and updates UI', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const Verify2faScreen(
              twoFactorToken: 'test-2fa-token-123',
              phoneNumber: '+2348011223344',
              email: 'bond@mi6.gov.uk',
              initialMethod: 'authenticator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final switchBtn = find.text('Try another verification method');
      await tester.ensureVisible(switchBtn);
      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      final emailOption = find.text('Email Address');
      await tester.tap(emailOption);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(mockRepo.lastSwitchMethod, 'email');
      expect(find.text('Email Verification'), findsOneWidget);
    });
    testWidgets('switching method to SMS triggers SwitchTwoFactorMethodRequested and updates UI', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const Verify2faScreen(
              twoFactorToken: 'test-2fa-token-123',
              phoneNumber: '+2348011223344',
              email: 'bond@mi6.gov.uk',
              initialMethod: 'authenticator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final switchBtn = find.text('Try another verification method');
      await tester.ensureVisible(switchBtn);
      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      final phoneOption = find.text('SMS / Phone Number');
      await tester.tap(phoneOption);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(mockRepo.lastSwitchMethod, 'phone');
      expect(find.text('SMS Verification'), findsOneWidget);
    });
  });

  group('TwoFactorModal Widget Tests', () {
    late _MockTwoFactorAuthRepo mockRepo;
    late AuthBloc authBloc;

    setUp(() {
      mockRepo = _MockTwoFactorAuthRepo();
      authBloc = AuthBloc(authRepository: mockRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('highlights Authenticator as default when 2FA is disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: authBloc,
              child: TwoFactorModal(
                user: mockRepo.user, // twoFactorEnabled is false
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Two-Factor Authentication'), findsOneWidget);
      expect(find.text('Authenticator App'), findsOneWidget);
      expect(find.text('RECOMMENDED / DEFAULT'), findsOneWidget);
      expect(find.text('Email Verification'), findsOneWidget);
      expect(find.text('SMS / Phone Number'), findsOneWidget);
    });

    testWidgets('sets up Authenticator App 2FA successfully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: authBloc,
              child: TwoFactorModal(
                user: mockRepo.user,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Set Up Authenticator"
      final setupBtn = find.text('Set Up Authenticator');
      await tester.ensureVisible(setupBtn);
      await tester.tap(setupBtn);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(mockRepo.lastSetupMethod, 'authenticator');
      expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);

      // Tap "Next: Enter 6-Digit Code"
      final nextBtn = find.text('Next: Enter 6-Digit Code');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Confirm Verification Code'), findsOneWidget);
      expect(find.text('Key: JBSWY3DPEHPK3PXP'), findsOneWidget);

      // Enter 6-digit code
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));
      await tester.enterText(textFields.at(0), '1');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '3');
      await tester.enterText(textFields.at(3), '4');
      await tester.enterText(textFields.at(4), '5');
      await tester.enterText(textFields.at(5), '6');
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(mockRepo.lastEnableMethod, 'authenticator');
      expect(mockRepo.lastEnableCode, '123456');
    });

    testWidgets('sets up Email 2FA successfully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: authBloc,
              child: TwoFactorModal(
                user: mockRepo.user,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Email Verification option
      final emailOption = find.text('Email Verification');
      await tester.ensureVisible(emailOption);
      await tester.tap(emailOption);
      await tester.pumpAndSettle();

      // Tap Send Verification Code
      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(mockRepo.lastSetupMethod, 'email');
      expect(find.text('Confirm Verification Code'), findsOneWidget);

      // Enter 6 digits
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));
      await tester.enterText(textFields.at(0), '6');
      await tester.enterText(textFields.at(1), '5');
      await tester.enterText(textFields.at(2), '4');
      await tester.enterText(textFields.at(3), '3');
      await tester.enterText(textFields.at(4), '2');
      await tester.enterText(textFields.at(5), '1');
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(mockRepo.lastEnableMethod, 'email');
      expect(mockRepo.lastEnableCode, '654321');
    });

    testWidgets('shows disable button and active method when 2FA is enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: authBloc,
              child: TwoFactorModal(
                user: mockRepo.user.copyWith(
                  twoFactorEnabled: true,
                  twoFactorMethod: 'authenticator',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2FA is Active'), findsOneWidget);
      expect(find.text('Authenticator App (Default)'), findsOneWidget);
      expect(find.text('Disable Two-Factor Authentication'), findsOneWidget);
    });
  });
}
