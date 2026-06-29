
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';


import '../../../../constants/layout_constant.dart';
import '../../../../constants/spinkit.dart';
import '../controllers/ranking_controller.dart';
import 'AgencyManthlyRankingList.dart';
import 'ListVeiw.dart';

class RankingView extends GetView<RankingController> {
  const RankingView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RankingController());

    return DefaultTabController(
      length: 2,
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
                onPressed: () => Get.back(),
              ),
              centerTitle: true,
              title: Text(
                'Rank',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
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
                      width: kWeight * 0.5,
                      margin: EdgeInsets.symmetric(
                          vertical: 10, horizontal: kWeight * 0.07),
                      // width: Get.width * 0.5,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color(0xff8A4CF7)),
                      child: TabBar(
                        indicatorPadding:
                            const EdgeInsets.symmetric(horizontal: -34),
                        labelPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        indicator: BoxDecoration(
                          color: Colors.white, // Active tab background color
                          borderRadius: BorderRadius.circular(
                              20), // Optional: rounded tabs
                        ),
                        indicatorColor: Color(0xFF5cc87d),
                        labelColor: Color(0xff8A4CF7),
                        dividerColor: Color(0xFF5cc87d),
                        unselectedLabelColor: Colors.white,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(
                            text: 'Daily',
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
                          fontSize: 15),
                    ),
                    //-----------------------card design ---------------------
                    SizedBox(
                      height: 40,
                    ),

                    Expanded(
                      child: TabBarView(
                        children: [
                          // Popular Section
                          RankingList(),

                          // Party Section

                          // Live Section
                          AgencyManthlyRankingList(),
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

class CastonRankingcard extends StatelessWidget {
  final Color fastColor;
  final Color secondColor;
  final Color bottomColor;

  final String name;
  final String coin;
  final String profileImage;
  final String rankText;

  final DecorationImage? frame;

  /// ✅ Background image path
  final String backgroundImage;

  final double height;
  final double width;
  final double? pwidth;

  final Color? topBorderColor;
  final Color? sideBorderColor;

  const CastonRankingcard({
    super.key,
    required this.fastColor,
    required this.secondColor,
    required this.bottomColor,
    required this.height,
    required this.width,
    required this.rankText,
    required this.name,
    required this.coin,
    required this.profileImage,
    required this.backgroundImage,
    this.frame,
    this.pwidth,
    this.topBorderColor,
    this.sideBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: frame,
                ),
                child: CircleAvatar(
                  radius: kHeight * 0.035,
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: CachedNetworkImage(
                      imageUrl: profileImage,
                      fit: BoxFit.cover,
                      height: kHeight * 0.045,
                      width: kHeight * 0.045,
                      placeholder: (context, url) => const SizedBox(),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: kHeight * 0.016,
                  ),
                ),
              ),

              Text(
                coin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: kHeight * 0.015,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}