import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(
    this._preferences, {
    required bool isDark,
    required Locale locale,
  }) : themeMode = isDark ? ThemeMode.dark : ThemeMode.light,
       locale = locale {
    Intl.defaultLocale = locale.toLanguageTag();
  }

  static const _darkModeKey = 'dark_mode_enabled';
  static const _languageKey = 'language_code';

  final SharedPreferences _preferences;
  ThemeMode themeMode;
  Locale locale;

  Future<void> setDarkMode(bool enabled) async {
    final saved = await _preferences.setBool(_darkModeKey, enabled);
    if (!saved) {
      throw StateError('Unable to save the theme preference.');
    }
    themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    if (!{'fr', 'en', 'ar'}.contains(value.languageCode)) {
      throw ArgumentError.value(value, 'value', 'Unsupported language');
    }
    final saved = await _preferences.setString(
      _languageKey,
      value.languageCode,
    );
    if (!saved) {
      throw StateError('Unable to save the language preference.');
    }
    Intl.defaultLocale = value.toLanguageTag();
    locale = value;
    notifyListeners();
  }
}
