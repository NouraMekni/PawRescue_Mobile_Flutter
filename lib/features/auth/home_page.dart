import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'auth_api.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.session, required this.authApi});

  final AuthSession session;
  final AuthApi authApi;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Mon profil'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            context
                .tr('E-mail : {value}')
                .replaceAll('{value}', user['email']?.toString() ?? ''),
          ),
          const SizedBox(height: 8),
          Text(
            context
                .tr('Rôle : {value}')
                .replaceAll(
                  '{value}',
                  context.tr(user['role']?.toString() ?? ''),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            context
                .tr('Téléphone : {value}')
                .replaceAll('{value}', user['phone']?.toString() ?? ''),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginPage(authApi: authApi)),
                (_) => false,
              );
            },
            child: Text(context.tr('Se déconnecter')),
          ),
        ],
      ),
    );
  }
}
