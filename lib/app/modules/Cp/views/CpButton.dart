import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoveBackButton extends StatefulWidget {
  const LoveBackButton({super.key});

  @override
  State<LoveBackButton> createState() => _LoveBackButtonState();
}

class _LoveBackButtonState extends State<LoveBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.4).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse Glow behind heart
        AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: CustomPaint(
                size: Size(60, 60),
                painter: LoveGlowPainter(),
              ),
            );
          },
        ),

        // Main Heart Button
        GestureDetector(
          onTap: () {
            Get.back();
          },
          child: ClipPath(
            clipper: HeartClipper(),
            child: Container(
              width: 65,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xffed0889), Color(0xffe6106a)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xffe6106a).withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Heart Shape Clipper
class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width / 2, height * 0.9);
    path.cubicTo(-width * 0.2, height * 0.55, width * 0.1, height * 0.1,
        width / 2, height * 0.35);
    path.cubicTo(width * 0.9, height * 0.1, width * 1.2, height * 0.55,
        width / 2, height * 0.9);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Glow Painter Behind Heart
class LoveGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.purpleAccent.withValues(alpha: 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * 0.6));

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.6, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
