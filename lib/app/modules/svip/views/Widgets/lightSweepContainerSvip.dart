import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';

import '../../../../../widgets/after/CastomText.dart';

class LightSweepContainerSvip extends StatefulWidget {
  final Gradient gradient1;

  const LightSweepContainerSvip({super.key, required this.gradient1});

  @override
  _LightSweepContainerSvipState createState() =>
      _LightSweepContainerSvipState();
}

class _LightSweepContainerSvipState extends State<LightSweepContainerSvip>
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
          child: SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: Get.height * 0.015, horizontal: Get.width * 0.017),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: widget.gradient1,
                  // LinearGradient(
                  //   colors: [
                  //     Color(0xff4b351e),
                  //     Color(0xffb79c85),
                  //     Color(0xff4b351e),
                  //   ],
                  //   begin: Alignment.centerLeft,
                  //   end: Alignment.centerRight,
                  // ),
                  border: Border.all(color: Color(0xffc3b0b0), width: 1.5)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl:
                                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSfQg9Fd9jAf4lb6p1LrhogPk8Uz93HV79zO84OVthjXRVsuUXqPNPH0FQ&s',
                              height: Get.height * 0.04,
                              width: Get.height * 0.04,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(
                            width: Get.width * 0.018,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Castontext(
                                  fontWeight: FontWeight.w400,
                                  textColor: Color(0xffffffff),
                                  fontSize: Get.height * 0.015,
                                  text: 'You don\'t have SVIP'),
                              Row(
                                children: [
                                  Castontext(
                                      fontWeight: FontWeight.w400,
                                      textColor: Color(0xffd3d0d0),
                                      fontSize: Get.height * 0.013,
                                      text: 'This Month points '),
                                  SizedBox(
                                    width: 7,
                                  ),
                                  Image.asset(
                                    'assets/Svip/dollar.png',
                                    height: 17,
                                  ),
                                  Castontext(
                                      fontWeight: FontWeight.w600,
                                      textColor: Color(0xfff4c607),
                                      fontSize: Get.height * 0.017,
                                      text: ' 0'),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: Get.width * 0.35,
                            child: LinearProgressBar(
                              maxSteps: 6,
                              progressType:
                                  LinearProgressBar.progressTypeLinear,
                              minHeight: 5,
                              currentStep: 1,
                              progressColor: Color(0xfff4c607),
                              backgroundColor: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(width: Get.width * 0.02),
                          Text(
                            'Lv.1',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w700,
                              fontSize: Get.height * 0.017,
                              color: Color(0xfff4c607),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Castontext(
                              fontWeight: FontWeight.w400,
                              textColor: Color(0xffd3d0d0),
                              fontSize: Get.height * 0.013,
                              text: '0 points'),
                          SizedBox(
                            width: Get.width * 0.2,
                          ),
                          Castontext(
                              fontWeight: FontWeight.w500,
                              textColor: Color(0xffd3d0d0),
                              fontSize: Get.height * 0.014,
                              text: '1M points')
                        ],
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Castontext(
                          fontWeight: FontWeight.w400,
                          textColor: Color(0xffd3d0d0),
                          fontSize: Get.height * 0.018,
                          text: 'Record > '),
                      SizedBox(
                        height: Get.height * 0.015,
                      ),
                      InkWell(
                        onTap: () {
                          // Get.to(RechargeView(),
                          //     transition: Transition.rightToLeft);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: Get.height * 0.012,
                              horizontal: Get.width * 0.05),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              gradient: LinearGradient(
                                  colors: [
                                    Color(0xffecd5a1),
                                    Color(0xffe0c188)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight)),
                          child: Castontext(
                              fontWeight: FontWeight.w400,
                              textColor: Color(0xff070202),
                              fontSize: Get.height * 0.014,
                              text: 'Recharge'),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
