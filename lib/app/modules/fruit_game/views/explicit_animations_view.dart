import 'package:flutter/material.dart';

class ExplicitAnimationsView extends StatefulWidget {
  const ExplicitAnimationsView({super.key});

  @override
  State<ExplicitAnimationsView> createState() => _ExplicitAnimationsViewState();
}

class _ExplicitAnimationsViewState extends State<ExplicitAnimationsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final Animation<AlignmentGeometry> _alignAnimation;
  late final Animation<double> _rotationAnimation;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: Duration(seconds: 100), vsync: this)
          ..repeat(reverse: false);

    _alignAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

    _rotationAnimation = Tween<double>(begin: 0, end: 2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 200,
          child: Positioned(
            top: 2,
            child: AlignTransition(
                alignment: _alignAnimation,
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: Container(
                    height: 100,
                    width: 50,
                    color: Colors.red,
                  ),
                )),
          ),
        ),
      ],
    );
  }
}
