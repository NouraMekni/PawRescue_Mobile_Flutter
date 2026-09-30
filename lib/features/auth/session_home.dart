import 'package:flutter/material.dart';

import '../shell/citoyen_shell.dart';
import 'auth_api.dart';

Widget homeForSession({
  required AuthSession session,
  required AuthApi authApi,
}) {
  return PawShell(session: session, authApi: authApi);
}
