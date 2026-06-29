
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../../../../constants/spinkit.dart';
import '../../controllers/ranking_controller.dart';
import '../ranking_time.dart';
import 'agency_rankinList.dart';

class Agencyrankingmainpage extends GetView<RankingController> {
  const Agencyrankingmainpage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RankingController());
    controller.showRankingList();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Obx(() {
          return LoadingOverlay(
            isLoading: controller.isLoading.value,
            progressIndicator: kLoadingIndicator(),
            child: Stack(
              children: [

                Column(
                  children: [
                    // ---------------------Tabbar design --------------------

                    SizedBox(
                      height: 8,
                    ),
                    Container(
                      height: 54,
                      width: Get.width * 0.92,
                      padding: const EdgeInsets.all(3),
                      margin: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: Get.width * 0.04,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: const Color(0xffffdf95),
                          width: 1.2,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.24),
                            Colors.black.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: const Color(0xffffd47a).withValues(alpha: 0.20),
                            blurRadius: 16,
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
                          boxShadow: const [
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
                          fontSize: Get.width * 0.032,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: Get.width * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                        labelPadding: EdgeInsets.zero,
                        tabs: const [
                          Tab(text: 'Daily'),
                          Tab(text: 'Weekly'),
                          Tab(text: 'Monthly'),
                          Tab(text: 'Over all'),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    CountdownTimerWidget(),

                    //-----------------------card design ---------------------

                    SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Popular Section
                          AgencyRankingList(),
                          // Party Section
                          AgencyRankingList(),
                          AgencyRankingList(),
                          // Live Section
                          AgencyRankingList(),
                          // Explore Section
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
