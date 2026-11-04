import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController(this._preferences, {required bool isDark})
    : themeMode = ValueNotifier(isDark ? ThemeMode.dark : ThemeMode.light);

  static const _darkModeKey = 'dark_mode_enabled';

  final SharedPreferences _preferences;
  final ValueNotifier<ThemeMode> themeMode;

  Future<void> setDarkMode(bool enabled) async {
    final saved = await _preferences.setBool(_darkModeKey, enabled);
    if (!saved) {
      throw StateError('Unable to save the theme preference.');
    }
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
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
