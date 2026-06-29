import 'package:flutter/material.dart';

class Live_Botton_circle extends StatelessWidget {
  final IconData icon;
  final Color background;
  const Live_Botton_circle({
    super.key,
    required this.icon,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
