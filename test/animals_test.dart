import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawrescue_mobile/features/animals/animal_api.dart';
import 'package:pawrescue_mobile/features/animals/animal_form_page.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';
import 'package:pawrescue_mobile/core/api_client.dart';

void main() {
  testWidgets(
    'citizen form registers an animal and optionally requests refuge care',
    (tester) async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/api/messaging/refuges/') {
          return http.Response(
            jsonEncode([
              {'id': 7, 'name': 'Refuge Tunis'},
            ]),
            200,
          );
        }
        fail('Unexpected request: ${request.method} ${request.url}');
      });
      final authApi = AuthApi(ApiClient(client: client));
      final animalApi = AnimalApi(
        baseUrl: 'http://localhost/api',
        token: 'token',
        client: client,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AnimalFormPage(
            session: AuthSession(
              accessToken: 'token',
              user: {'id': 3, 'role': 'citoyen'},
            ),
            authApi: authApi,
            animalApi: animalApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Espèce'), findsNothing);
      expect(find.text('Race'), findsOneWidget);
      expect(find.textContaining('sans refuge.'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      expect(find.text('Refuge Tunis'), findsOneWidget);
    },
  );

  test(
    'animal photo upload uses the backend photo endpoint and multipart field',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/animals/12/photos/');
        expect(request.headers['authorization'], startsWith('Bearer '));
        final body = request.body;
        expect(body, contains('name="image"'));
        expect(body, contains('filename="milo.jpg"'));
        expect(body, contains('name="is_primary"'));
        return http.Response(
          jsonEncode({'id': 1, 'image': '/media/animals/photos/milo.jpg'}),
          201,
        );
      });
      final api = AnimalApi(
        baseUrl: 'http://localhost/api',
        token: 'token',
        client: client,
      );

      await api.uploadPhoto(
        animalId: 12,
        filename: 'milo.jpg',
        bytes: [1, 2, 3],
      );
    },
  );

  test('citizen refuge-care requests use the intake endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/animals/intake-requests/');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['animal'], 12);
      expect(body['refuge'], 7);
      return http.Response(
        jsonEncode({
          'id': 4,
          'animal': 12,
          'animal_name': 'Luna',
          'animal_breed': 'Labrador',
          'refuge': 7,
          'refuge_name': 'Refuge Tunis',
          'status': 'pending',
        }),
        201,
      );
    });
    final api = AnimalApi(
      baseUrl: 'http://localhost/api',
      token: 'token',
      client: client,
    );

    final request = await api.createIntakeRequest(animalId: 12, refugeId: 7);

    expect(request.status, 'pending');
    expect(request.refugeName, 'Refuge Tunis');
  });

  test('citizen animal creation sends an optional intake refuge, not an owner refuge', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/animals/');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['intake_refuge'], 7);
      expect(body.containsKey('refuge'), isFalse);
      expect(body['breed'], 'Labrador');
      expect(body['is_adoptable'], isFalse);
      return http.Response(
        jsonEncode({
          'id': 12,
          'name': 'Luna',
          'refuge': null,
          'refuge_name': null,
          'breed': 'Labrador',
          'sex': 'unknown',
          'status': 'owned',
          'is_adoptable': false,
          'photos': [],
        }),
        201,
      );
    });
    final api = AnimalApi(
      baseUrl: 'http://localhost/api',
      token: 'token',
      client: client,
    );

    final animal = await api.createAnimal(
      name: 'Luna',
      intakeRefugeId: 7,
      breed: 'Labrador',
    );

    expect(animal.id, 12);
    expect(animal.breed, 'Labrador');
    expect(animal.refugeId, isNull);
  });
}
