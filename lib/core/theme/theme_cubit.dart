import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences sharedPreferences;
  static const String themeModeKey = 'app_theme_mode';

  ThemeCubit({required this.sharedPreferences})
      : super(_loadInitialTheme(sharedPreferences));

  static ThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final savedMode = prefs.getString(themeModeKey);
    if (savedMode == 'dark') {
      return ThemeMode.dark;
    } else if (savedMode == 'light') {
      return ThemeMode.light;
    } else if (savedMode == 'system') {
      return ThemeMode.system;
    }
    // Default to light mode
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    String modeStr;
    switch (mode) {
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
    }
    await sharedPreferences.setString(themeModeKey, modeStr);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  bool isDarkMode(BuildContext context) {
    if (state == ThemeMode.dark) return true;
    if (state == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}
