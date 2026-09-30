import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/auth/auth_api.dart';
import 'features/auth/login_page.dart';

void main() {
  runApp(const PawRescueApp());
}

class PawRescueApp extends StatelessWidget {
  const PawRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawRescue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: LoginPage(authApi: AuthApi(ApiClient())),
    );
  }
}
