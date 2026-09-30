import 'package:flutter/material.dart';

class PawLogo extends StatelessWidget {
  const PawLogo({super.key});

  static const green = Color(0xFF1F8A45);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/paw_logo.png',
      width: 112,
      height: 112,
      fit: BoxFit.contain,
    );
  }
}
