import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/core/theme/theme_cubit.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_state.dart';
import 'package:creditbook/features/auth/domain/repositories/auth_repository.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';
import 'package:creditbook/features/settings/presentation/pages/settings_screen.dart';

class _MockSettingsAuthRepository implements AuthRepository {
  final User? user;
  _MockSettingsAuthRepository([this.user]);

  @override
  Future<User> getCurrentUser() async => user ?? const User(id: '1', name: 'Test', hasPin: false);

  @override
  Future<User?> getCachedUser() async => user;

  @override
  Future<User> login(String phoneNumber, String pin) => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<User> register(String name, String phoneNumber, {String? currency}) => throw UnimplementedError();

  @override
  Future<void> setLoginPin(String pin) async {}

  @override
  Future<User> updateProfile({String? name, String? email, String? defaultCurrency}) => throw UnimplementedError();

  @override
  Future<User> uploadAvatar(dynamic imageFile) => throw UnimplementedError();

  @override
  Future<User> deleteAvatar() => throw UnimplementedError();

  @override
  Future<bool> refreshToken() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest({
    required AuthBloc authBloc,
    required ThemeCubit themeCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            themeMode: themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: const SettingsScreen(),
          );
        },
      ),
    );
  }

  testWidgets('SettingsScreen displays theme preference toggle and switches mode on tap', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final prefs = await SharedPreferences.getInstance();
    final themeCubit = ThemeCubit(sharedPreferences: prefs);
    final repo = _MockSettingsAuthRepository();
    final authBloc = AuthBloc(authRepository: repo);
    authBloc.emit(const AuthSuccess(User(id: '1', name: 'Test User', hasPin: true)));

    await tester.pumpWidget(createWidgetUnderTest(authBloc: authBloc, themeCubit: themeCubit));
    await tester.pumpAndSettle();

    // Verify Theme Mode row exists
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    // Initial state is light
    expect(themeCubit.state, ThemeMode.light);

    // Scroll into view if needed
    final darkFinder = find.text('Dark');
    final lightFinder = find.text('Light');
    await tester.ensureVisible(darkFinder);
    await tester.pumpAndSettle();

    // Tap 'Dark'
    await tester.tap(darkFinder);
    await tester.pumpAndSettle();

    // Cubit should now be in dark mode and persisted
    expect(themeCubit.state, ThemeMode.dark);
    expect(prefs.getString(ThemeCubit.themeModeKey), 'dark');

    // Tap 'Light'
    await tester.ensureVisible(lightFinder);
    await tester.tap(lightFinder);
    await tester.pumpAndSettle();

    // Cubit should now be in light mode and persisted
    expect(themeCubit.state, ThemeMode.light);
    expect(prefs.getString(ThemeCubit.themeModeKey), 'light');
  });
}
