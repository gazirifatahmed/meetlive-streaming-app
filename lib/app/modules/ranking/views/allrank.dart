import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/layout_constant.dart';
import '../controllers/ranking_controller.dart';
import 'AppRank.dart';
import 'hederRanking/AgencyRankingMainPage.dart';
import 'hederRanking/ReceiverRankingMainPage.dart';

class Allrank extends GetView<RankingController> {
  const Allrank({super.key});

  @override
  Widget build(BuildContext context) {
    final RankingController controller = Get.put(RankingController());

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final TabController tabController = DefaultTabController.of(context);

          return AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              final int currentIndex = tabController.index;

              final List<String> backgroundImages = [
                'assets/new/contributionRank.jfif', // Sending
                'assets/new/ranking2.jfif',    // Receiving
                'assets/new/rank3.jfif',       // Agency
              ];

              return Scaffold(
                backgroundColor: Colors.black,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Image.asset(
                        backgroundImages[currentIndex],
                        key: ValueKey(backgroundImages[currentIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),

                    Container(
                      color: Colors.black.withValues(alpha: 0.18),
                    ),

                    SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Get.width * 0.035,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Get.back(),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: kHeight * 0.024,
                                  ),
                                ),

                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Rich list',
                                      style: GoogleFonts.poppins(
                                        fontSize: kHeight * 0.026,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                Obx(
                                      () => InkWell(
                                    onTap: () {
                                      showCountryPicker(
                                        context: context,
                                        showPhoneCode: false,
                                        onSelect: (Country country) {
                                          controller.selectedCountry.value =
                                              country;
                                        },
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                          Colors.white.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            controller
                                                .selectedCountry.value.flagEmoji,
                                            style: TextStyle(
                                              fontSize: kHeight * 0.018,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            height: 54,
                            width: Get.width * 0.88,
                            padding: const EdgeInsets.all(3),
                            margin: const EdgeInsets.only(top: 8, bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: const Color(0xffffdf95),
                                width: 1.2,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.22),
                                  Colors.black.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: const Color(0xffffd47a)
                                      .withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: TabBar(
                              controller: tabController,
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
                                fontSize: Get.width * 0.037,
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelStyle: GoogleFonts.poppins(
                                fontSize: Get.width * 0.037,
                                fontWeight: FontWeight.w500,
                              ),
                              labelPadding: EdgeInsets.zero,
                              tabs: const [
                                Tab(text: 'Sending'),
                                Tab(text: 'Receiving'),
                                Tab(text: 'Agency'),
                              ],
                            ),
                          ),

                          Expanded(
                            child: TabBarView(
                              controller: tabController,
                              children: const [
                                Apprank(),
                                Receiverrankingmainpage(),
                                Agencyrankingmainpage(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}