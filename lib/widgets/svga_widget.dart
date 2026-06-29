import 'package:flutter/material.dart';

class SVGAWidget extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? child;
  final bool autoPlay;
  final bool loop;

  const SVGAWidget({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.child,
    this.autoPlay = true,
    this.loop = true,
  });

  @override
  State<SVGAWidget> createState() => _SVGAWidgetState();
}

class _SVGAWidgetState extends State<SVGAWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    if (widget.autoPlay) {
      if (widget.loop) {
        _animationController.repeat();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create a beautiful animated fallback for SVGA files
    Widget fallbackWidget = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.8),
                Colors.purple.withValues(alpha: 0.8),
                Colors.pink.withValues(alpha: 0.8),
              ],
              stops: [
                0.0,
                _animationController.value,
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Animated background pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AnimatedPatternPainter(_animationController.value),
                  ),
                ),
                // Content overlay
                if (widget.child != null) widget.child!,
              ],
            ),
          ),
        );
      },
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: fallbackWidget,
    );
  }
}

class _AnimatedPatternPainter extends CustomPainter {
  final double animationValue;

  _AnimatedPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw animated circles
    for (int i = 0; i < 5; i++) {
      final radius = (size.width * 0.1) * (1 + animationValue);
      final offset = Offset(
        size.width * (0.2 + i * 0.15),
        size.height * 0.5 + (animationValue * 10 * (i % 2 == 0 ? 1 : -1)),
      );
      canvas.drawCircle(offset, radius, paint);
    }

    // Draw animated lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final startY = size.height * (0.2 + i * 0.3);
      final endY = startY + (animationValue * 20);
      canvas.drawLine(
        Offset(0, startY),
        Offset(size.width * animationValue, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}