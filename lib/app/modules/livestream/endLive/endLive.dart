import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/after/castomLiveend.dart';
import '../../bottomnav/views/bottomnav_view.dart';
import '../controllers/livestream_controller.dart';

class Endlive extends StatelessWidget {
  const Endlive({super.key});
  String formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    LivestreamController livestreamController = Get.find();
    final data = Get.arguments;

    print(data['livestream_data']['user']['total_followers']);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // 👈 Transparent
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xff8A4CF7),
                const Color(0xffB460F0).withValues(alpha: .7),
                const Color(0xff8A4CF7),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        centerTitle: true,
        leading: SizedBox(),
        title: Text(
          'End Live',
          style: GoogleFonts.lato(
            fontSize: kHeight * 0.022,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              Color(0xffb5a7fe),
              Color(0xffffffff),
            ], begin: Alignment.topRight, end: Alignment.bottomRight)),
          ),
          Column(
            children: [
              SizedBox(
                height: kHeight * 0.055,
              ),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background Gradient Container with content
                    Container(
                      width: kWeight * 0.9,
                      padding: EdgeInsets.symmetric(vertical: kHeight * 0.05),
                      margin: EdgeInsets.symmetric(
                          vertical: 10, horizontal: kWeight * 0.03),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xff8A4CF7),
                            Color(0xffB460F0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: Offset(0, 6),
                            blurRadius: 12,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                              height: 50), // Space for avatar overlap
                          Castontext(
                            textColor: Colors.white,
                            text:
                                '${data['livestream_data']['user']?['name'] ?? ''}',
                            fontSize: 20,
                          ),
                          Castontext(
                            textColor: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            text: 'Live ended',
                          ),
                          SizedBox(height: kHeight * 0.03),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              CastomLivecatagory(
                                text: 'Receive Coin',
                                text1:
                                    '${data['end_live_data']['gift_amount'] ?? 0}',
                                image: 'assets/images/dollar.png',
                              ),
                              CastomLivecatagory(
                                text: 'New follower',
                                text1: '${data['new_followers'] ?? 0}',
                                image: 'assets/flaticons/user.png',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Positioned Circular Image with border
                    Positioned(
                      top: -40,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: kHeight * 0.12,
                        width: kHeight * 0.12,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // ---------------- PROFILE IMAGE ----------------
                            ClipOval(
                              child: CircleAvatar(
                                radius: kHeight * 0.035,
                                backgroundColor: Colors.white,
                                child: CachedNetworkImage(
                                  imageUrl: ImageHelper.getImageUrl(
                                      data['livestream_data']['user']
                                          ?['profile_image']),
                                  height: kHeight * 0.09,
                                  width: kHeight * 0.09,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.person, size: kHeight * 0.09),
                                  placeholder: (context, url) => SizedBox(
                                    height: kHeight * 0.09,
                                    width: kHeight * 0.09,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ---------------- AGENCY FRAME (if agencyId > 0) ----------------
                            // if (data['user']['0'] > 0)
                            //   SVGAEasyPlayer(
                            //     assetsName:
                            //         'assets/svga/Frame/Agency frame.svga',
                            //     fit: BoxFit.cover,
                            //   )

                            // ---------------- NORMAL FRAME (if no agency frame) --------------
                            if (data['livestream_data']['user']
                                        ['asset_purchase_history'] !=
                                    null &&
                                data['livestream_data']['user']
                                        ['asset_purchase_history']['asset'] !=
                                    null &&
                                data['livestream_data']['user']
                                            ['asset_purchase_history']['asset']
                                        ['asset'] !=
                                    null)
                              // Check if the asset path ends with .svga
                              (data['livestream_data']['user']
                                              ['asset_purchase_history']
                                          ['asset']['asset']
                                      .toString()
                                      .endsWith('.svga'))
                                  ? SizedBox(
                                      height: kHeight * 0.12,
                                      width: kHeight * 0.12,
                                      child: SVGAEasyPlayer(
                                        resUrl:
                                            '$kDomainUrl/${data['livestream_data']['user']['asset_purchase_history']['asset']['asset']}',
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl:
                                          "$kDomainUrl/${data['livestream_data']['user']['asset_purchase_history']['asset']['asset']}",
                                      height: kHeight * 0.12,
                                      width: kHeight * 0.12,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: kHeight * 0.06,
                                        width: kHeight * 0.06,
                                        decoration: BoxDecoration(
                                          color: kAppColor.withValues(alpha: .02),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        height: kHeight * 0.12,
                                        width: kHeight * 0.12,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: kAppColor.withValues(alpha: .2),
                                        ),
                                      ),
                                    )

                            // ---------------- NOTHING (no frame) ----------------
                            else
                              SizedBox(
                                height: kHeight * 0.03,
                                width: kHeight * 0.03,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: kHeight * 0.02,
                  horizontal: kWeight * 0.05,
                ),
                margin: EdgeInsets.symmetric(
                    vertical: 12, horizontal: kWeight * 0.05),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff8A4CF7), Color(0xffB460F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Castontext(
                            text: 'Live Duration',
                            textColor: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: kHeight * 0.015,
                          ),
                          SizedBox(height: kHeight * 0.01),
                          Castontext(
                            text: formatDuration(data['livestream_data']
                                    ['live_duration_seconds'] ??
                                0),
                            textColor: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: kHeight * 0.02,
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: kHeight * 0.15,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                      margin: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
                    ),

                    // Right Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Castontext(
                            text: 'Audiences',
                            textColor: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: kHeight * 0.015,
                          ),
                          SizedBox(height: kHeight * 0.01),
                          Castontext(
                            text: '${data['end_live_data']['audience'] ?? 0}',
                            textColor: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: kHeight * 0.02,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: kHeight * 0.12,
              ),
              SizedBox(
                width: kWeight * 0.85,
                height: kHeight * 0.06,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAll(BottomnavView(),
                        transition: Transition.rightToLeft);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xff8A4CF7),
                          Color(0xffB460F0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      child: Text(
                        'Conform',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: kHeight * 0.017,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
