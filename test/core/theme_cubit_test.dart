import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/core/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeCubit', () {
    test('initializes with ThemeMode.light by default when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(sharedPreferences: prefs);

      expect(cubit.state, ThemeMode.light);
    });

    test('loads saved dark theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        ThemeCubit.themeModeKey: 'dark',
      });
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(sharedPreferences: prefs);

      expect(cubit.state, ThemeMode.dark);
    });

    test('loads saved system theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        ThemeCubit.themeModeKey: 'system',
      });
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(sharedPreferences: prefs);

      expect(cubit.state, ThemeMode.system);
    });

    test('setThemeMode updates state and persists dark mode to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(sharedPreferences: prefs);

      await cubit.setThemeMode(ThemeMode.dark);

      expect(cubit.state, ThemeMode.dark);
      expect(prefs.getString(ThemeCubit.themeModeKey), 'dark');
    });

    test('setThemeMode updates state and persists light mode to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        ThemeCubit.themeModeKey: 'dark',
      });
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(sharedPreferences: prefs);

      await cubit.setThemeMode(ThemeMode.light);

      expect(cubit.state, ThemeMode.light);
      expect(prefs.getString(ThemeCubit.themeModeKey), 'light');
    });

    test('toggleTheme toggles between dark and light', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(sharedPreferences: prefs);

      cubit.toggleTheme();
      expect(cubit.state, ThemeMode.dark);

      cubit.toggleTheme();
      expect(cubit.state, ThemeMode.light);
    });
  });
}
