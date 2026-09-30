import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawrescue_mobile/core/api_client.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';
import 'package:pawrescue_mobile/features/shell/profile_tab.dart';

void main() {
  testWidgets('profile save sends phone and address', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late Map<String, dynamic> sent;
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/auth/me/');
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'email': 'sara.mobile@test.tn',
          'first_name': sent['first_name'],
          'last_name': sent['last_name'],
          'phone': sent['phone'],
          'photo': null,
          'profile': sent['profile'],
        }),
        200,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileTab(
          session: AuthSession(
            accessToken: 'token',
            user: {'email': 'sara.mobile@test.tn', 'role': 'citoyen', 'profile': {}},
          ),
          authApi: AuthApi(ApiClient(client: client)),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Prénom'), 'Sara');
    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Ben Ali');
    await tester.enterText(find.widgetWithText(TextField, 'Téléphone'), '+21620000000');
    await tester.enterText(find.widgetWithText(TextField, 'Adresse'), 'Ariana');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(sent['first_name'], 'Sara');
    expect(sent['last_name'], 'Ben Ali');
    expect(sent['phone'], '+21620000000');
    expect(sent['profile'], {'address': 'Ariana'});
    expect(find.text('Profil enregistré.'), findsOneWidget);
  });
}
