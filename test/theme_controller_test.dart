import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawrescue_mobile/core/theme_controller.dart';

void main() {
  test('dark mode preference is restored from shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(preferences, isDark: false);

    await controller.setDarkMode(true);

    expect(controller.themeMode.value, ThemeMode.dark);
    expect(preferences.getBool('dark_mode_enabled'), isTrue);

    final restartedController = ThemeController(
      preferences,
      isDark: preferences.getBool('dark_mode_enabled') ?? false,
    );
    expect(restartedController.themeMode.value, ThemeMode.dark);
  });
}
