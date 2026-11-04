import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController(
    this._preferences, {
    required bool isDark,
    required Locale locale,
  }) : themeMode = ValueNotifier(isDark ? ThemeMode.dark : ThemeMode.light),
       locale = ValueNotifier(locale) {
    Intl.defaultLocale = locale.toLanguageTag();
  }

  static const _darkModeKey = 'dark_mode_enabled';
  static const _languageKey = 'language_code';

  final SharedPreferences _preferences;
  final ValueNotifier<ThemeMode> themeMode;
  final ValueNotifier<Locale> locale;

  Future<void> setDarkMode(bool enabled) async {
    final saved = await _preferences.setBool(_darkModeKey, enabled);
    if (!saved) {
      throw StateError('Unable to save the theme preference.');
    }
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
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
    locale.value = value;
  }
}

class ThemeControllerScope extends InheritedWidget {
  const ThemeControllerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ThemeController controller;

  static ThemeController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>()
        ?.controller;
  }

  static ThemeController of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
      scope != null,
      'ThemeControllerScope is missing from the widget tree.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(ThemeControllerScope oldWidget) =>
      controller != oldWidget.controller;
}
