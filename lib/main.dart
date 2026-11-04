import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/ads_service.dart';
import 'core/theme_controller.dart';
import 'animation_screen.dart';
import 'features/auth/auth_api.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final themeController = ThemeController(
    preferences,
    isDark: preferences.getBool('dark_mode_enabled') ?? false,
    locale: Locale(
      const {'fr', 'en', 'ar'}.contains(preferences.getString('language_code'))
          ? preferences.getString('language_code')!
          : 'fr',
    ),
  );
  runApp(PawRescueApp(themeController: themeController));
  unawaited(_initializeAds());
}

Future<void> _initializeAds() async {
  try {
    await AdsService.instance.initialize();
  } catch (error) {
    debugPrint('Google Mobile Ads initialization failed: $error');
  }
}

class PawRescueApp extends StatelessWidget {
  const PawRescueApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: themeController.locale,
      builder: (context, locale, _) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController.themeMode,
        builder: (context, themeMode, _) {
          return ThemeControllerScope(
            controller: themeController,
            child: MaterialApp(
              title: 'PawRescue',
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: themeMode,
              theme: _buildTheme(Brightness.light),
              darkTheme: _buildTheme(Brightness.dark),
              home: AnimationScreen(authApi: AuthApi(ApiClient())),
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: brightness,
      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    );
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F7F4),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F8F8),
      ),
    );
  }
}
