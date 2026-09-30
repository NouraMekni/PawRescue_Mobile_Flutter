import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('E-mail : ${user['email'] ?? ''}'),
          const SizedBox(height: 8),
          Text('Rôle : ${user['role'] ?? ''}'),
          const SizedBox(height: 8),
          Text('Téléphone : ${user['phone'] ?? ''}'),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => LoginPage(authApi: authApi),
                ),
                (_) => false,
              );
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
