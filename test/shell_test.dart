import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawrescue_mobile/core/api_client.dart';
import 'package:pawrescue_mobile/features/auth/auth_api.dart';
import 'package:pawrescue_mobile/features/shell/citoyen_shell.dart';

void main() {
  testWidgets('citoyen bar opens the map and notifications', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async => http.Response('[]', 200));
    await tester.pumpWidget(
      MaterialApp(
        home: PawShell(
          session: AuthSession(
            accessToken: 'token',
            user: {
              'email': 'sara.mobile@test.tn',
              'role': 'citoyen',
              'first_name': 'Sara',
            },
          ),
          authApi: AuthApi(ApiClient(client: client)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Signaler un animal'), findsOneWidget);
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    expect(
      find.text('La carte montrera l’emplacement de tous les animaux signalés.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Notifs'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune notification.'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter'), findsOneWidget);
  });

  testWidgets('a refuge gets the same menu and its own profile fields', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PawShell(
          session: AuthSession(
            accessToken: 'token',
            user: {'email': 'refuge@test.tn', 'role': 'refuge', 'first_name': 'Sami'},
          ),
          authApi: AuthApi(
            ApiClient(client: MockClient((request) async => http.Response('[]', 200))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carte'), findsOneWidget);
    expect(find.text('Notifs'), findsOneWidget);
    expect(find.text('Complétez votre profil depuis l’onglet Profil.'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Nom du refuge'), findsOneWidget);
    expect(find.text('Capacité'), findsOneWidget);
  });
}
