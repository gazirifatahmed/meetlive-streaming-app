import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:meetlivepro/app/modules/myprofile/views/profile_contributionList.dart';

import '../../../../constants/spinkit.dart';
import '../../ranking/controllers/ranking_controller.dart';
import '../../ranking/views/ranking_time.dart';

class Profileconribution extends StatelessWidget {
  const Profileconribution({super.key});

  @override
  Widget build(BuildContext context) {
    final RankingController controller = Get.put(RankingController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: false,

        /// ✅ FIXED: Expanded gives finite height
        body: ExpandedBody(controller: controller),
      ),
    );
  }
}

class ExpandedBody extends StatelessWidget {
  final RankingController controller;

  const ExpandedBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return LoadingOverlay(
        isLoading: controller.isLoading.value,
        progressIndicator: kLoadingIndicator(),

        /// ✅ FIXED: Stack gets full screen height
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/new/contributionRank.jfif', fit: BoxFit.cover),

            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 20),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xffff8e0c),
                          const Color(0xffef3206).withValues(alpha: .7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  height: 54,
                  width: Get.width * 0.86,
                  padding: const EdgeInsets.all(3),
                  margin: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: Get.width * 0.07,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xffffdf95),
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xffffd47a).withValues(alpha: 0.18),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffffe6a8),
                          Color(0xffffcf70),
                          Color(0xffffe7aa),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x80ffcc5c),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Color(0x66ffffff),
                          blurRadius: 4,
                          offset: Offset(0, -1),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    indicatorColor: Colors.transparent,
                    labelColor: const Color(0xff34200e),
                    unselectedLabelColor: Colors.white,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: Get.width * 0.040,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: Get.width * 0.040,
                      fontWeight: FontWeight.w500,
                    ),
                    labelPadding: EdgeInsets.zero,
                    tabs: const [
                      Tab(text: 'Daily'),
                      Tab(text: 'Weekly'),
                      Tab(text: 'Monthly'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                CountdownTimerWidget(),

                const SizedBox(height: 20),

                /// ✅ This Expanded now works because parent Column has fixed height
                const Expanded(
                  child: TabBarView(
                    children: [
                      ProfileContributionList(),
                      ProfileContributionList(),
                      ProfileContributionList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
