import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../constants/layout_constant.dart';
import '../small_text_widgets.dart';

class CustomButtons extends StatelessWidget {
  final String text;
  final String image;
  final Color? backgroundColor;
  final Gradient? gradient; // Gradient support
  final VoidCallback? onTap; // Nullable করা হয়েছে
  final double? height;
  final bool isLoading; // Loading state

  const CustomButtons({
    super.key,
    required this.text,
    this.backgroundColor,
    this.gradient,
    required this.image,
    required this.onTap,
    this.height,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kHeight * 0.03, vertical: 5),
      child: InkWell(
        onTap: isLoading ? null : onTap, // Loading হলে tap disable
        child: Container(
          width: double.infinity,
          height: height ?? Get.height * 0.05,
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: gradient, // Gradient support
            borderRadius: BorderRadius.circular(50),
          ),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Side - Image or Loading
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: isLoading
                      ? SizedBox(
                          height: kHeight * 0.03,
                          width: kHeight * 0.03,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : SvgPicture.asset(
                          image,
                          height: kHeight * 0.03,
                        ),
                ),

                // Center - Text
                SmallTextStyle(
                  color: Colors.white,
                  text: text,
                  fontSize: Get.height * 0.018,
                  fontWeight: FontWeight.bold,
                ),

                // Right Side - Spacer
                SizedBox(width: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
