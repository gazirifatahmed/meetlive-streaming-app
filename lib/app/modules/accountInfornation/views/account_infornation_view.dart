import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../../../constants/color_constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../../record/controllers/record_controller.dart';

class AccountInformationView extends StatelessWidget {
  const AccountInformationView({super.key});

  Widget glassCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: kWeight * 0.04,
              vertical: kHeight * 0.025,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: kHeight * 0.017,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget glassBox(String title, String value, {IconData? icon}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.26),
                    Colors.white.withValues(alpha: 0.09),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Icon(
                      icon,
                      size: kHeight * 0.018,
                      color: Colors.amberAccent,
                    ),
                  if (icon != null) const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: kHeight * 0.011,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: kHeight * 0.012,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget backgroundImage() {
    return Positioned.fill(
      child: Image.asset(
        'assets/new/rankingbgimage.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget darkOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.55),
              const Color(0xff2E1065).withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordController = Get.put(RecordController());
    final record = recordController.sessionWiseLiveRecord;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(title: 'Earning'),
      body: Stack(
        children: [
          backgroundImage(),
          darkOverlay(),

          SafeArea(
            child: Obx(() {
              return LoadingOverlay(
                isLoading: recordController.isLoading.value,
                progressIndicator: SpinKitChasingDots(
                  size: 30,
                  color: kPrimaryColor,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  child: Column(
                    children: [
                      glassCard("Today", [
                        Row(
                          children: [
                            glassBox(
                              "Live Duration",
                              "${record['today']?['totalLiveTime'] ?? 0} min",
                            ),
                            glassBox(
                              "Coin Income",
                              "${record['today']?['totalGiftAmount'] ?? 0}",
                              icon: Icons.monetization_on,
                            ),
                          ],
                        ),
                      ]),

                      glassCard("1st to 15th Days", [
                        Row(
                          children: [
                            glassBox(
                              "Live Duration",
                              "${record['firstTO7Days']?['totalLiveTime'] ?? 0} min",
                            ),
                            glassBox(
                              "Coin Income",
                              "${record['firstTO7Days']?['totalGiftAmount'] ?? 0}",
                              icon: Icons.monetization_on,
                            ),
                          ],
                        ),
                      ]),

                      glassCard("16th to 30th Days", [
                        Row(
                          children: [
                            glassBox(
                              "Live Duration",
                              "${record['sixteenthT21Days']?['totalLiveTime'] ?? 0} min",
                            ),
                            glassBox(
                              "Coin Income",
                              "${record['sixteenthT21Days']?['totalGiftAmount'] ?? 0}",
                              icon: Icons.monetization_on,
                            ),
                          ],
                        ),
                      ]),

                      glassCard("Monthly Total", [
                        Row(
                          children: [
                            glassBox(
                              "Total Live Time",
                              "${record['totalMontly']?['totalMontlyTime'] ?? 0} min",
                            ),
                            glassBox(
                              "Total Coins",
                              "${record['totalMontly']?['totalMontlyAmount'] ?? 0}",
                              icon: Icons.monetization_on,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            glassBox(
                              "Total Time + Gift",
                              "${record['totalMontly']?['totalTimeAndGiftAmount'] ?? 0}",
                            ),
                          ],
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}