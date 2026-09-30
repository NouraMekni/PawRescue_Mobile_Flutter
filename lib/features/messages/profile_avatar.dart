import 'package:flutter/material.dart';

import '../auth/paw_logo.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.photo, this.radius = 26});

  final String photo;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    if (photo.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE7F5EC),
        child: Icon(Icons.person, color: PawLogo.green, size: radius),
      );
    }
    return ClipOval(
      child: Image.network(
        photo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFFE7F5EC),
            child: Icon(Icons.person, color: PawLogo.green, size: radius),
          );
        },
      ),
    );
  }
}
