import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:creditbook/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:creditbook/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';
import 'package:creditbook/features/auth/domain/repositories/auth_repository.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_event.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_state.dart';
import 'package:creditbook/features/auth/presentation/pages/forgot_pin_screen.dart';
import 'package:creditbook/features/auth/presentation/pages/verify_pin_reset_screen.dart';
import 'package:creditbook/features/auth/presentation/pages/reset_pin_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  String? lastForgotPhone;
  String? lastVerifyCode;
  String? lastResetPin;

  @override
  Future<Map<String, dynamic>> forgotPin(String phoneNumber) async {
    lastForgotPhone = phoneNumber;
    return {
      'message': 'Verification code sent to your registered email address.',
      'phone_number': phoneNumber,
      'has_email': true,
      'debug_code': '123456',
    };
  }

  @override
  Future<String> verifyPinResetCode(String phoneNumber, String code) async {
    lastVerifyCode = code;
    return 'fake-reset-token-xyz';
  }

  @override
  Future<User> resetPin(String phoneNumber, String resetToken, String newPin) async {
    lastResetPin = newPin;
    return const User(
      id: 'user-001',
      name: 'Test User',
      phoneNumber: '+2348012345678',
      hasPin: true,
    );
  }

  @override
  Future<User?> getCachedUser() async => null;
  @override
  Future<User> getCurrentUser() async => throw UnimplementedError();
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.creditbook.test/api/v1');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Forgot PIN - Remote Data Source', () {
    test('forgotPin sends POST request to auth/pin/forgot', () async {
      final prefs = await SharedPreferences.getInstance();
      var called = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/pin/forgot') {
          called = true;
          final body = jsonDecode(request.body);
          expect(body['phone_number'], '+2348012345678');
          return http.Response(
            jsonEncode({
              'message': 'Code sent successfully',
              'phone_number': '+2348012345678',
              'has_email': true,
              'code': '654321',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final res = await dataSource.forgotPin('+2348012345678');
      expect(called, isTrue);
      expect(res['phone_number'], '+2348012345678');
      expect(res['code'], '654321');
      expect(res['has_email'], isTrue);
    });

    test('verifyPinResetCode sends code and returns reset_token', () async {
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/pin/verify-code') {
          final body = jsonDecode(request.body);
          expect(body['phone_number'], '+2348012345678');
          expect(body['code'], '123456');
          return http.Response(
            jsonEncode({
              'message': 'Code verified',
              'reset_token': 'secret-token-abc',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final token = await dataSource.verifyPinResetCode('+2348012345678', '123456');
      expect(token, 'secret-token-abc');
    });

    test('resetPin sends new pin and stores access token and user', () async {
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/pin/reset') {
          final body = jsonDecode(request.body);
          expect(body['phone_number'], '+2348012345678');
          expect(body['reset_token'], 'secret-token-abc');
          expect(body['pin'], '888999');
          return http.Response(
            jsonEncode({
              'message': 'PIN reset successful',
              'token': 'new-auth-token-999',
              'user': {
                'id': 'user-1',
                'name': 'Test User',
                'phone_number': '+2348012345678',
                'has_pin': true,
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final user = await dataSource.resetPin(
        '+2348012345678',
        'secret-token-abc',
        '888999',
      );

      expect(user.id, 'user-1');
      expect(user.hasPin, isTrue);
      expect(prefs.getString(AuthRemoteDataSourceImpl.tokenKey), 'new-auth-token-999');
    });
  });

  group('Forgot PIN - AuthBloc', () {
    test('emits [AuthLoading, ForgotPinCodeSent] on ForgotPinRequested', () async {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        isA<ForgotPinCodeSent>()
            .having((s) => s.phoneNumber, 'phoneNumber', '+2348012345678')
            .having((s) => s.debugCode, 'debugCode', '123456'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const ForgotPinRequested(phoneNumber: '+2348012345678'));
    });

    test('emits [AuthLoading, PinResetCodeVerified] on VerifyPinResetCodeRequested', () async {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        isA<PinResetCodeVerified>()
            .having((s) => s.resetToken, 'resetToken', 'fake-reset-token-xyz'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const VerifyPinResetCodeRequested(phoneNumber: '+2348012345678', code: '123456'));
    });

    test('emits [AuthLoading, PinResetSuccess] on ResetPinRequested', () async {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        isA<PinResetSuccess>().having((s) => s.user.id, 'user.id', 'user-001'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const ResetPinRequested(
        phoneNumber: '+2348012345678',
        resetToken: 'fake-reset-token-xyz',
        newPin: '654321',
      ));
    });
  });

  group('Forgot PIN - UI Screens', () {
    testWidgets('ForgotPinScreen renders phone input and triggers ForgotPinRequested', (tester) async {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);

      final router = GoRouter(
        initialLocation: '/forgot-pin',
        routes: [
          GoRoute(
            path: '/forgot-pin',
            builder: (context, state) => const ForgotPinScreen(initialPhoneNumber: '+2348012345678'),
          ),
          GoRoute(
            path: '/verify-pin-reset',
            builder: (context, state) => const Scaffold(body: Text('Verify Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Forgot Your PIN?'), findsOneWidget);
      expect(find.text('Send Recovery Code'), findsOneWidget);

      await tester.tap(find.text('Send Recovery Code'));
      await tester.pump();

      expect(repo.lastForgotPhone, contains('8012345678'));
    });

    testWidgets('VerifyPinResetScreen renders code input and allows submitting code', (tester) async {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);

      final router = GoRouter(
        initialLocation: '/verify-pin-reset',
        routes: [
          GoRoute(
            path: '/verify-pin-reset',
            builder: (context, state) => const VerifyPinResetScreen(
              phoneNumber: '+2348012345678',
              hasEmail: true,
              debugCode: '654321',
            ),
          ),
          GoRoute(
            path: '/reset-pin',
            builder: (context, state) => const Scaffold(body: Text('Reset Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Verify Code'), findsNWidgets(2)); // Title and button

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Code'));
      await tester.pump();

      expect(repo.lastVerifyCode, '654321');
    });

    testWidgets('ResetPinScreen renders new PIN fields and triggers ResetPinRequested', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const ResetPinScreen(
              phoneNumber: '+2348012345678',
              resetToken: 'valid-reset-token',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create New PIN'), findsOneWidget);
      expect(find.text('Reset PIN & Sign In'), findsOneWidget);

      // Enter 6 digit pin in both fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), '112233');
      await tester.enterText(textFields.at(1), '112233');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reset PIN & Sign In'));
      await tester.tap(find.text('Reset PIN & Sign In'));
      await tester.pump();

      expect(repo.lastResetPin, '112233');
    });
  });
}
