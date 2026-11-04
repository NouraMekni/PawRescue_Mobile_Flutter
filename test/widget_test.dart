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

  testWidgets('login shows required field errors without calling the API', (
    tester,
  ) async {
    final client = MockClient((request) async {
      fail('Login API must not be called with empty fields.');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authApi: AuthApi(ApiClient(client: client))),
      ),
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('L’adresse e-mail est obligatoire.'), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);
  });

  testWidgets('login validates email format without calling the API', (
    tester,
  ) async {
    final client = MockClient((request) async {
      fail('Login API must not be called with an invalid email.');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authApi: AuthApi(ApiClient(client: client))),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Email invalide.'), findsOneWidget);
  });

  testWidgets('login requires a password before calling the API', (
    tester,
  ) async {
    final client = MockClient((request) async {
      fail('Login API must not be called with an empty password.');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authApi: AuthApi(ApiClient(client: client))),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);
  });

  testWidgets('register shows the profile returned by the API', (tester) async {
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/reports/') {
        return http.Response('[]', 200);
      }
      expect(request.url.path, '/api/auth/register/');
      return http.Response(
        jsonEncode({
          'user': {
            'email': 'sara.mobile@test.tn',
            'role': 'citoyen',
            'phone': '',
          },
          'access': 'access-token',
          'refresh': 'refresh-token',
        }),
        201,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authApi: AuthApi(ApiClient(client: client))),
      ),
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

  testWidgets('refuge opens the organisation form and not the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(authApi: AuthApi(ApiClient()))),
    );
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Ben Ali');
    await tester.enterText(find.byType(TextField).at(1), 'Nadia');
    await tester.enterText(
      find.byType(TextField).at(2),
      'refuge.mobile@test.tn',
    );
    await tester.enterText(find.byType(TextField).at(3), 'StrongPass123');
    await tester.ensureVisible(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Refuge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refuge'));
    await tester.ensureVisible(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Vérification de l’organisation'), findsOneWidget);
    expect(find.textContaining('Numéro RNE'), findsOneWidget);
    expect(find.text('Signaler un animal'), findsNothing);
  });

  testWidgets('a refuge waiting for approval cannot sign in', (tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'non_field_errors': [
            'Votre compte refuge est en attente de vérification par un administrateur.',
          ],
        }),
        400,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authApi: AuthApi(ApiClient(client: client))),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'refuge@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'StrongPass123');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Votre compte refuge est en attente de vérification par un administrateur.',
      ),
      findsOneWidget,
    );
    expect(find.text('Signaler un animal'), findsNothing);
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
