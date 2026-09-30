import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawrescue_mobile/core/api_client.dart';
import 'package:pawrescue_mobile/features/auth/login_page.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';

void main() {
  testWidgets('login page shows email and password fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(authApi: AuthApi(ApiClient()))),
    );

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
  });

  testWidgets('register shows the profile returned by the API', (tester) async {
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/reports/') {
        return http.Response('[]', 200);
      }
      expect(request.url.path, '/api/auth/register/');
      return http.Response(
        jsonEncode({
          'user': {'email': 'sara.mobile@test.tn', 'role': 'citoyen', 'phone': ''},
          'access': 'access-token',
          'refresh': 'refresh-token',
        }),
        201,
      );
    });

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(authApi: AuthApi(ApiClient(client: client)))),
    );
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.text('PawRescue AI'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Hkiri');
    await tester.enterText(find.byType(TextField).at(1), 'Oussama');
    await tester.enterText(find.byType(TextField).at(2), 'sara.mobile@test.tn');
    await tester.enterText(find.byType(TextField).at(3), 'StrongPass123');
    await tester.ensureVisible(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Comment souhaitez-vous\naider ?'), findsOneWidget);
    expect(find.text('Refuge'), findsOneWidget);
    await tester.tap(find.text('Continuer').last);
    await tester.pumpAndSettle();

    expect(find.text('Signaler un animal'), findsOneWidget);
    expect(find.text('sara.mobile@test.tn'), findsOneWidget);
  });

  testWidgets('veterinaire opens the professional form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(authApi: AuthApi(ApiClient()))),
    );
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Hkiri');
    await tester.enterText(find.byType(TextField).at(1), 'Oussama');
    await tester.enterText(find.byType(TextField).at(2), 'vet.mobile@test.tn');
    await tester.enterText(find.byType(TextField).at(3), 'StrongPass123');
    await tester.ensureVisible(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vétérinaire'));
    await tester.ensureVisible(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Informations professionnelles'), findsOneWidget);
  });

  test('api error message reads field errors', () {
    expect(
      readApiError({
        'email': ['Un compte existe déjà avec cet e-mail.'],
      }),
      'Un compte existe déjà avec cet e-mail.',
    );
  });
}
