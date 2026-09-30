import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawrescue_mobile/core/api_client.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';
import 'package:pawrescue_mobile/features/notifications/notifications_page.dart';

void main() {
  testWidgets('an unread message notification can be marked read', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var marked = false;
    final client = MockClient((request) async {
      if (request.method == 'POST' && request.url.path == '/api/notifications/4/read/') {
        marked = true;
        return http.Response(
          jsonEncode({
            'id': 4,
            'type': 'new_message',
            'title': 'Nouveau message',
            'body': 'Un chien est blessé.',
            'data': {},
            'is_read': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode([
          {
            'id': 4,
            'type': 'new_message',
            'title': 'Nouveau message',
            'body': 'Un chien est blessé.',
            'data': {},
            'is_read': false,
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          session: AuthSession(
            accessToken: 'token',
            user: {'id': 2, 'role': 'refuge', 'email': 'refuge@test.tn'},
          ),
          authApi: AuthApi(ApiClient(client: client)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nouveau message'), findsOneWidget);
    expect(find.text('Un chien est blessé.'), findsOneWidget);
    await tester.tap(find.text('Nouveau message'));
    await tester.pumpAndSettle();
    expect(marked, isTrue);
  });
}
