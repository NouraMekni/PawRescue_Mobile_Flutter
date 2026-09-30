import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawrescue_mobile/core/api_client.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';
import 'package:pawrescue_mobile/features/messages/directory_page.dart';
import 'package:pawrescue_mobile/features/messages/messages_api.dart';
import 'package:pawrescue_mobile/features/messages/messages_page.dart';
import 'package:pawrescue_mobile/features/messages/thread_page.dart';

void main() {
  testWidgets('a request can be accepted before replying', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var accepted = false;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/accept/')) {
        accepted = true;
      }
      return http.Response(
        jsonEncode({
          'id': 3,
          'status': accepted ? 'accepted' : 'pending',
          'needs_response': !accepted,
          'refuge_name': 'Refuge Tunis',
          'participant_name': 'Sara',
          'messages': [
            {
              'id': 1,
              'sender': 6,
              'body': 'Bonjour, un chien est blessé.',
              'is_read': false,
              'created_at': '2026-09-30T16:00:00Z',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ThreadPage(
          session: AuthSession(
            accessToken: 'token',
            user: {'id': 2, 'role': 'refuge', 'email': 'refuge@test.tn'},
          ),
          api: MessagesApi(ApiClient(client: client)),
          conversationId: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, un chien est blessé.'), findsOneWidget);
    expect(find.text('Accepter'), findsOneWidget);
    expect(find.text('Bloquer'), findsOneWidget);

    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();

    expect(accepted, isTrue);
    expect(find.text('Accepter'), findsNothing);
    expect(find.text('Votre message'), findsOneWidget);
  });

  testWidgets('a citizen can open a refuge card and contact it', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async {
      expect(request.url.path, '/api/messaging/refuges/');
      return http.Response(
        jsonEncode([
          {
            'id': 7,
            'name': 'Refuge Carthage',
            'phone': '71111222',
            'location': 'La Marsa',
            'photo': '',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DirectoryPage(
          session: AuthSession(
            accessToken: 'token',
            user: {'id': 2, 'role': 'citoyen', 'email': 'sara@test.tn'},
          ),
          authApi: AuthApi(ApiClient(client: client)),
          kind: DirectoryKind.refuge,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Refuge Carthage'), findsOneWidget);
    expect(find.text('71111222'), findsOneWidget);
    expect(find.text('La Marsa'), findsOneWidget);
    await tester.tap(find.text('Contacter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Écrire à Refuge Carthage'), findsOneWidget);
  });

  testWidgets('inbox shows the other profile photo', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'id': 3,
            'status': 'accepted',
            'needs_response': false,
            'refuge_name': 'Refuge Tunis',
            'photo': 'http://127.0.0.1:8000/media/users/photos/refuge.jpg',
            'last_message': {'body': 'Bonjour'},
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MessagesPage(
          session: AuthSession(
            accessToken: 'token',
            user: {'id': 2, 'role': 'citoyen', 'email': 'sara@test.tn'},
          ),
          authApi: AuthApi(ApiClient(client: client)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Refuge Tunis'), findsOneWidget);
    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
