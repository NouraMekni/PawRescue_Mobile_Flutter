import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawrescue_mobile/core/api_client.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';
import 'package:pawrescue_mobile/features/reports/citoyen_home_page.dart';
import 'package:pawrescue_mobile/features/reports/reports_api.dart';

void main() {
  test('create report sends the photo, type and position', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/reports/');
      expect(request.headers['authorization'], 'Bearer token');
      final text = request.body;
      expect(text, contains('name="type"'));
      expect(text, contains('stray'));
      expect(text, contains('36.8065'));
      expect(text, contains('name="photos"'));
      expect(text, contains('filename="dog.jpg"'));
      return http.Response(
        jsonEncode({'id': 4, 'type': 'stray', 'status': 'pending'}),
        201,
      );
    });

    final created = await ReportsApi(ApiClient(client: client)).create(
      token: 'token',
      type: 'stray',
      latitude: 36.8065,
      longitude: 10.1815,
      description: 'Chien près du parc',
      photoName: 'dog.jpg',
      photoBytes: [1, 2, 3],
    );

    expect(created['id'], 4);
  });

  testWidgets('citoyen can open the report form', (tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async => http.Response('[]', 200));
    await tester.pumpWidget(
      MaterialApp(
        home: CitoyenHomePage(
          session: AuthSession(
            accessToken: 'token',
            user: {'email': 'sara.mobile@test.tn', 'role': 'citoyen'},
          ),
          authApi: AuthApi(ApiClient(client: client)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun signalement pour le moment.'), findsOneWidget);
    await tester.tap(find.text('Signaler un animal'));
    await tester.pumpAndSettle();

    expect(find.text('Animal errant'), findsOneWidget);
    expect(find.text('Animal blessé'), findsOneWidget);
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();
    expect(find.text('Ajoutez une photo de l\'animal.'), findsOneWidget);
  });
}
