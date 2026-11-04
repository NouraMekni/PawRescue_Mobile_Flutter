import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/ads_service.dart';
import 'core/app_routes.dart';
import 'core/theme_controller.dart';
import 'animation_screen.dart';
import 'features/animals/animal_detail_page.dart';
import 'features/animals/animal_form_page.dart';
import 'features/auth/auth_api.dart';
import 'features/auth/login_page.dart';
import 'features/auth/session_home.dart';
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
  final authApi = AuthApi(ApiClient());
  runApp(
    ChangeNotifierProvider.value(
      value: themeController,
      child: PawRescueApp(authApi: authApi),
    ),
  );
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
  const PawRescueApp({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return MaterialApp(
      title: 'PawRescue',
      locale: themeController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeController.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      initialRoute: AppRoutes.animation,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case AppRoutes.animation:
        page = AnimationScreen(authApi: authApi);
        break;
      case AppRoutes.login:
        page = LoginPage(authApi: authApi);
        break;
      case AppRoutes.home:
        final session = settings.arguments;
        if (session is! AuthSession) {
          throw ArgumentError(
            'The ${AppRoutes.home} route requires an AuthSession argument.',
          );
        }
        page = homeForSession(session: session, authApi: authApi);
        break;
      case AppRoutes.animalForm:
        final arguments = settings.arguments;
        if (arguments is! AnimalFormRouteArguments) {
          throw ArgumentError(
            'The ${AppRoutes.animalForm} route requires '
            'AnimalFormRouteArguments.',
          );
        }
        page = AnimalFormPage(
          session: arguments.session,
          authApi: authApi,
          animalApi: arguments.animalApi,
        );
        break;
      case AppRoutes.animalDetail:
        final arguments = settings.arguments;
        if (arguments is! AnimalDetailRouteArguments) {
          throw ArgumentError(
            'The ${AppRoutes.animalDetail} route requires '
            'AnimalDetailRouteArguments.',
          );
        }
        page = AnimalDetailPage(
          animal: arguments.animal,
          session: arguments.session,
          authApi: authApi,
          animalApi: arguments.animalApi,
        );
        break;
      default:
        return null;
    }

    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
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
