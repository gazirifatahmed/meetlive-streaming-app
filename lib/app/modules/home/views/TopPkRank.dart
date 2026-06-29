import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:meetlivepro/app/modules/home/views/widgets/topPkHostRanking.dart';
import 'package:meetlivepro/app/modules/home/views/widgets/topPkhostMonthlyRanking.dart';
import 'package:meetlivepro/app/modules/home/views/widgets/topPkhostWeekly.dart';


import '../../../../constants/layout_constant.dart';
import '../../../../constants/spinkit.dart';
import '../../ranking/controllers/ranking_controller.dart';
import '../../ranking/views/ranking_view.dart';

class Toppkrank extends GetView<RankingController> {
  const Toppkrank({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RankingController());
    controller.getRankingList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff8A4CF7),
                  Color(0xffB460F0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              centerTitle: true,
              title: Text(
                'PK Rank',
                style: GoogleFonts.poppins(
                  fontSize: kHeight * 0.016,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              actions: [
                Obx(() => TextButton.icon(
                      onPressed: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: false,
                          onSelect: (Country country) {
                            controller.selectedCountry.value = country;
                          },
                        );
                      },
                      icon: Text(
                        controller.selectedCountry.value.flagEmoji,
                        style: TextStyle(fontSize: kHeight * 0.016),
                      ),
                      label: Text(
                        controller.selectedCountry.value.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: kHeight * 0.016,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        body: Obx(() {
          return LoadingOverlay(
            isLoading: controller.isLoading.value,
            progressIndicator: kLoadingIndicator(),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xffb5a7fe), Color(0xffffffff)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Column(
                  children: [
                    // ---------------------Tabbar design --------------------
                    Container(
                      margin: EdgeInsets.symmetric(
                          vertical: 5, horizontal: kWeight * 0.02),
                      // width: Get.width * 0.5,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Color(0xff030305).withValues(alpha: 0.2)),
                      child: TabBar(
                        indicatorPadding:
                            const EdgeInsets.symmetric(horizontal: -30),
                        labelPadding: const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 0),
                        indicator: BoxDecoration(
                          color:
                              Color(0xff8741fd), // Active tab background color
                          borderRadius: BorderRadius.circular(
                              50), // Optional: rounded tabs
                        ),
                        indicatorColor: Color(0xFF5cc87d),
                        labelColor: Color(0xfffdfdff),
                        dividerColor: Colors.transparent,
                        unselectedLabelColor: Colors.white,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: kHeight * 0.015,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(
                            text: 'Daily',
                          ),
                          Tab(
                            text: 'Weekly',
                          ),
                          Tab(text: 'Monthly'),
                        ],
                      ),
                    ),
                    Text(
                      'Countdown : 00 D 22 H 30 M 49 S ',
                      style: GoogleFonts.lato(
                        color: Color(0xff8A4CF7),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: const [
                          Toppkhostranking(),
                          ToppkhostrankingWeekly(),
                          ToppkhostrankingMonthly(),
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

  Widget buildRankingCard(
    String rankText,
    Color fastColor,
    Color secondColor,
    Color bottomColor,
    double pwidth,
    double width,
    double height,
  ) {
    return Column(
      children: [
        CastonRankingcard(
          coin: '',
          profileImage: '',
          pwidth: Get.width * pwidth,
          fastColor: fastColor,
          secondColor: secondColor,
          height: Get.height * height,
          width: Get.width * width,
          bottomColor: bottomColor,
          rankText: rankText,
          name: '', backgroundImage: 'assets/new/rankfastcard.png',
        ),
        SizedBox(height: kHeight * 0.032),
        Obx(
          () => InkWell(
            onTap: () {
              controller.isFollow.value = !controller.isFollow.value;
            },
            child: Container(
              alignment: Alignment.center,
              padding:
                  EdgeInsets.symmetric(vertical: 4, horizontal: kWeight * 0.03),
              decoration: BoxDecoration(
                color: Color(0xff8A4CF7),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Color(0xff8A4CF7)),
              ),
              child: Text(
                controller.isFollow.value ? '+ Follow ' : 'Following',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
