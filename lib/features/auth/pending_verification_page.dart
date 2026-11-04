import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'auth_api.dart';
import 'login_page.dart';
import 'paw_logo.dart';

class PendingVerificationPage extends StatelessWidget {
  const PendingVerificationPage({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, size: 64, color: PawLogo.green),
            const SizedBox(height: 16),
            const Text(
              'Compte en attente de vérification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un administrateur doit valider votre dossier avant que vous puissiez vous connecter.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(authApi: authApi),
                  ),
                  (_) => false,
                );
              },
              style: FilledButton.styleFrom(backgroundColor: PawLogo.green),
              child: Text(context.tr('Retour à la connexion')),
            ),
          ],
        ),
      ),
    );
  }
}
