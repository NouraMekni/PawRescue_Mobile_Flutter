import 'package:flutter/material.dart';

class PawPattern extends StatelessWidget {
  const PawPattern({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Colors.white)),
        const Positioned.fill(child: CustomPaint(painter: _PawPatternPainter())),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _PawPatternPainter extends CustomPainter {
  const _PawPatternPainter();

  static const _paws = <(double, double, double, double)>[
    (0.16, 0.05, 36, -0.45),
    (0.74, 0.03, 78, 0.28),
    (0.90, 0.15, 28, 0.7),
    (0.06, 0.20, 54, 0.18),
    (0.46, 0.16, 24, -0.3),
    (0.28, 0.32, 42, 0.55),
    (0.84, 0.34, 66, -0.35),
    (0.10, 0.46, 30, 0.12),
    (0.52, 0.44, 22, -0.6),
    (0.72, 0.54, 48, 0.4),
    (0.20, 0.62, 74, -0.15),
    (0.92, 0.66, 26, 0.25),
    (0.42, 0.72, 38, 0.5),
    (0.08, 0.80, 50, -0.32),
    (0.64, 0.84, 82, 0.16),
    (0.86, 0.90, 32, -0.5),
    (0.30, 0.93, 24, 0.1),
  ];

  static const _color = Color(0xFFC5D9A8);

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, pawSize, turns) in _paws) {
      final mark = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.pets.codePoint),
          style: TextStyle(
            fontSize: pawSize,
            fontFamily: Icons.pets.fontFamily,
            package: Icons.pets.fontPackage,
            color: _color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(turns);
      mark.paint(canvas, Offset(-mark.width / 2, -mark.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
