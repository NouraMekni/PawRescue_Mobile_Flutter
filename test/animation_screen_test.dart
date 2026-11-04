import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawrescue_mobile/core/api_client.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';
import 'package:pawrescue_mobile/features/auth/login_page.dart';
import 'package:pawrescue_mobile/animation_screen.dart';

void main() {
  testWidgets('animation screen opens login after the animation delay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AnimationScreen(authApi: AuthApi(ApiClient()))),
    );

    expect(find.byType(AnimationScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
