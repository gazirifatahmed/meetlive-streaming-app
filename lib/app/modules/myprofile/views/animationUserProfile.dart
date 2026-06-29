import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../appmenu/views/widgets/host_agency_under_data.dart';

class LightSweepContainer2 extends StatefulWidget {
  const LightSweepContainer2({
    super.key,
  });

  @override
  _LightSweepContainer2State createState() => _LightSweepContainer2State();
}

class _LightSweepContainer2State extends State<LightSweepContainer2>
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
                vertical: kWeight * 0.0, horizontal: kWeight * 0.03),
            margin:
                EdgeInsets.symmetric(horizontal: kWeight * 0.03, vertical: 7),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  kAppColor1,
           kAppColor2.withValues(alpha: .3),
                  kAppColor1,
                ]),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Obx(() {
                      return Stack(
                        alignment:
                            Alignment.center, // Stack er majhe sob center
                        children: [
                          CircleAvatar(
                            radius: kHeight * 0.04,
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: CachedNetworkImage(
                                imageUrl: ImageHelper.getImageUrl(
                                    "${homeController.profileVisitor['user_agency']['profile_image'] ?? "default.png"}"),
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
                          // 🔹 Frame Image
                          if (homeController.profileVisitor['user_agency']
                                  ['agency_id'] !=
                              0)
                            SizedBox(
                              height: kHeight * 0.08,
                              width: kHeight * 0.08,
                              child: SVGAEasyPlayer(
                                assetsName:
                                    'assets/svga/Frame/Agency frame.svga',
                                fit: BoxFit.cover,
                              ),
                            )

                          // 🔹 Profile Image
                        ],
                      );
                    }),
                    SizedBox(
                      width: kWeight * 0.02,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Castontext(
                            textColor: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: kHeight * 0.019,
                            text:
                                '${homeController.profileVisitor['user_agency']['name']}'),
                        Castontext(
                            fontWeight: FontWeight.w400,
                            textColor: Colors.white60,
                            fontSize: kHeight * 0.016,
                            text:
                                'Uid :${homeController.profileVisitor['user_agency']['user_id']} '),
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
                      Get.to(host_under_agency(
                        verificationData:
                            homeController.profileVisitor['user_agency'],
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
