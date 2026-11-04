import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'core/app_routes.dart';
import 'features/auth/auth_api.dart';

class AnimationScreen extends StatefulWidget {
  const AnimationScreen({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed<void, void>(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Lottie.asset('assets/animations/Loader_cat.json')),
    );
  }
}
