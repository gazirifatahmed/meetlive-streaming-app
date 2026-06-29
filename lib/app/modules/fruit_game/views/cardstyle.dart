import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GameCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    double radius = 12;
    double topCurveHeight = 10; // 🔥 top convex height
    double scallopHeight = 6.0;

    // 👉 Start from left একটু নিচে
    path.moveTo(0, radius);

    // 👉 Top Left Curve
    path.quadraticBezierTo(0, 0, radius, 0);

    // 👉 🔥 TOP CONVEX (Main premium effect)
    path.quadraticBezierTo(
      size.width / 2,
      -topCurveHeight, // 👈 এটা negative দিলে convex হবে
      size.width - radius,
      0,
    );

    // 👉 Top Right Curve
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // 👉 Right side
    path.lineTo(size.width, size.height - scallopHeight * 2);

    // 👉 Bottom scallop (same as before)
    int count = 5;
    double scallopWidth = size.width / count;

    for (int i = 0; i < count; i++) {
      path.arcToPoint(
        Offset(size.width - (scallopWidth * (i + 1)), size.height - scallopHeight * 2),
        radius: Radius.circular(scallopWidth / 2),
        clockwise: false,
      );
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class GameCardShadowPainter extends CustomPainter {
  final Color color;
  GameCardShadowPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    Path path = GameCardClipper().getClip(size);
    canvas.drawShadow(path, color, 8.0, true);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
