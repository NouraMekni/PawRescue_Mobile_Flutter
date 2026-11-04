import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawrescue_mobile/core/theme_controller.dart';

void main() {
  test('dark mode preference is restored from shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(
      preferences,
      isDark: false,
      locale: const Locale('fr'),
    );

    await controller.setDarkMode(true);

    expect(controller.themeMode.value, ThemeMode.dark);
    expect(preferences.getBool('dark_mode_enabled'), isTrue);

    final restartedController = ThemeController(
      preferences,
      isDark: preferences.getBool('dark_mode_enabled') ?? false,
      locale: const Locale('fr'),
    );
    expect(restartedController.themeMode.value, ThemeMode.dark);
  });

  test('selected language is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(
      preferences,
      isDark: false,
      locale: const Locale('fr'),
    );

    await controller.setLocale(const Locale('ar'));

    expect(controller.locale.value, const Locale('ar'));
    expect(preferences.getString('language_code'), 'ar');
  });
}
