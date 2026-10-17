import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/core/theme/theme_cubit.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/presentation/pages/theme_setup_screen.dart';
import 'package:creditbook/features/auth/domain/repositories/auth_repository.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';

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

void main() {
  late AuthBloc authBloc;
  late ThemeCubit themeCubit;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    themeCubit = ThemeCubit(sharedPreferences: prefs);
    authBloc = AuthBloc(authRepository: _MockAuthRepo());
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/setup-theme',
      routes: [
        GoRoute(
          path: '/setup-theme',
          builder: (context, state) => const ThemeSetupScreen(),
        ),
        GoRoute(
          path: '/setup-nominee',
          builder: (context, state) => const Scaffold(body: Text('Nominee Screen')),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('ThemeSetupScreen renders title, badge, 3 theme options, and buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('OPTIONAL STEP'), findsOneWidget);
    expect(find.text('Choose Your Theme'), findsOneWidget);
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('System Default'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text("I'll customize this later"), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Tapping Dark Mode selects dark theme mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(themeCubit.state, equals(ThemeMode.light));

    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();

    expect(themeCubit.state, equals(ThemeMode.dark));
    expect(prefs.getString(ThemeCubit.themeModeKey), equals('dark'));
  });

  testWidgets('Tapping Light Mode after dark selects light theme mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await themeCubit.setThemeMode(ThemeMode.dark);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(themeCubit.state, equals(ThemeMode.dark));

    await tester.tap(find.text('Light Mode'));
    await tester.pumpAndSettle();

    expect(themeCubit.state, equals(ThemeMode.light));
    expect(prefs.getString(ThemeCubit.themeModeKey), equals('light'));
  });

  testWidgets('Tapping System Default selects system theme mode', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('System Default'));
    await tester.tap(find.text('System Default'));
    await tester.pumpAndSettle();

    expect(themeCubit.state, equals(ThemeMode.system));
    expect(prefs.getString(ThemeCubit.themeModeKey), equals('system'));
  });

  testWidgets('Tapping Continue navigates to /setup-nominee', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Nominee Screen'), findsOneWidget);
  });

  testWidgets('Tapping Skip navigates to /setup-nominee', (tester) async {
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

    expect(find.text('Nominee Screen'), findsOneWidget);
  });

  testWidgets("Tapping I'll customize this later navigates to /setup-nominee", (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("I'll customize this later"));
    await tester.tap(find.text("I'll customize this later"));
    await tester.pumpAndSettle();

    expect(find.text('Nominee Screen'), findsOneWidget);
  });
}
