import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawrescue_mobile/core/api_client.dart';
import 'package:pawrescue_mobile/core/theme_controller.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';
import 'package:pawrescue_mobile/features/auth/login_page.dart';
import 'package:pawrescue_mobile/main.dart';

void main() {
  testWidgets('animation screen opens login after the animation delay', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final themeController = ThemeController(
      preferences,
      isDark: false,
      locale: const Locale('fr'),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeController,
        child: PawRescueApp(authApi: AuthApi(ApiClient())),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
