import 'package:flutter/material.dart';

import '../../../../constants/layout_constant.dart';


class ReusableIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? assetImage;
  final IconData? icon;
  final double? imageHeight;
  final Color backgroundColor;
  final Color? iconColor;
  final double? iconSize;

  const ReusableIconButton({
    super.key,
    required this.onPressed,
    this.assetImage,
    this.icon,
    this.imageHeight,
    required this.backgroundColor,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: kWeight * 0.03),
      height: kWeight * 0.09,
      width: kWeight * 0.09,
      child: IconButton(
        style: IconButton.styleFrom(backgroundColor: backgroundColor),
        onPressed: onPressed,
        icon: assetImage != null
            ? Image.asset(
          assetImage!,
          color: iconColor ?? Colors.white,
          height: imageHeight,
        )
            : Icon(
          icon!,
          color: iconColor ?? Colors.white,
          size: iconSize ?? 20,
        ),
      ),
    );
  }
}
