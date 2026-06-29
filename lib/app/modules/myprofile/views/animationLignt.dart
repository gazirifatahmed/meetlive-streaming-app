import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../verified/views/varify_page_5.dart';

class LightSweepContainer extends StatefulWidget {
  const LightSweepContainer({
    super.key,
  });

  @override
  _LightSweepContainerState createState() => _LightSweepContainerState();
}

class _LightSweepContainerState extends State<LightSweepContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(period: Duration(seconds: 4)); // Delay between sweeps
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.6),
                Colors.transparent,
              ],
              stops: [
                (_controller.value - 0.2).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.2).clamp(0.0, 1.0),
              ],
              transform: GradientRotation(math.pi / 12), // slight angle
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: kWeight * 0.01, horizontal: kWeight * 0.03),
            margin:
                EdgeInsets.symmetric(horizontal: kWeight * 0.03, vertical: 7),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  kAppColor,
                  Color(0xff9b5ef6).withValues(alpha: .6),
                  kAppColor
                ]),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center, // Stack er majhe sob center
                      children: [
                        // 🔹 Frame Image
                        if (homeController
                                    .activeFrameData['active_asset_ids'] !=
                                null &&
                            homeController.activeFrameData['active_asset_ids']
                                    ['asset'] !=
                                null &&
                            homeController.activeFrameData['active_asset_ids']
                                    ['asset']['asset'] !=
                                null)
                          CachedNetworkImage(
                            imageUrl: ImageHelper.getImageUrl(
                                "${homeController.activeFrameData['active_asset_ids']['asset']['asset']}"),
                            height: kHeight * 0.08,
                            width: kHeight * 0.08,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                                color: Colors.grey.shade300,
                                height: kHeight * 0.10,
                                width: kHeight * 0.10),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.image, size: kHeight * 0.12),
                          ),

                        // 🔹 Profile Image
                        CircleAvatar(
                          radius: kHeight * 0.03,
                          backgroundColor: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: CachedNetworkImage(
                              imageUrl: ImageHelper.getImageUrl(
                                  authController.userProfile.value.user?.profileImage ?? "default.png"),
                              fit: BoxFit.cover,
                              height: kHeight * 0.05,
                              width: kHeight * 0.05,
                              placeholder: (context, url) => Container(
                                  color: Colors.grey.shade300,
                                  height: kHeight * 0.12,
                                  width: kHeight * 0.12),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.person, size: kHeight * 0.12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: kWeight * 0.04,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Castontext(
                            textColor: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: kHeight * 0.019,
                            text:
                                '${authController.userProfile.value.user?.name}'),
                        Castontext(
                            fontWeight: FontWeight.w400,
                            textColor: Colors.white60,
                            fontSize: kHeight * 0.016,
                            text:
                                'ID : ${authController.userProfile.value.user?.userId} '),
                      ],
                    )
                  ],
                ),
                IconButton(
                    style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        backgroundColor: Colors.white),
                    onPressed: () {
                      Get.to(VarifyPage5(
                        verificationData: null,
                      ));
                    },
                    icon: Icon(
                      Icons.arrow_forward_ios_outlined,
                      color: kAppColor,
                      size: kHeight * 0.021,
                    ))
              ],
            ),
          ),
        );
      },
    );
  }
}
