import 'package:flutter/material.dart';

import '../constants/layout_constant.dart';


class message_bottom extends StatelessWidget {
  final String image;
  final Color color;
  final Color? color2;
  final VoidCallback? onPress;
  const message_bottom({
    super.key,
    required this.image,
    required this.color,
    this.color2,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color,
                color2 ?? color.withValues(alpha: 0.8),
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Image(
              image: AssetImage(
                image,
              ),
              height: kHeight * 0.02,
            ),
          ),
        ],
      ),
    );
  }
}
