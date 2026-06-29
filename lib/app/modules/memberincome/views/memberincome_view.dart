import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/setheight.dart';
import '../../../../widgets/small_text_widgets.dart';
import '../../informationcollection/views/informationcollection_view.dart';

class MemberincomeView extends StatefulWidget {
  const MemberincomeView({super.key});

  @override
  State<MemberincomeView> createState() => _MemberincomeViewState();
}

class _MemberincomeViewState extends State<MemberincomeView> {
  @override
  Widget build(BuildContext context) {
    informationcollectionController.showAgencyHostList(
      agencyId: int.parse(
          verifiedController.agencySingleData['agency_id'].toString()),
    );
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff1C1244),
          leading: InkWell(
            onTap: () {
              Get.back();
            },
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            'Member Income',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  Get.to(InformationcollectionView(),
                      transition: Transition.leftToRight);
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(0xff169BD4),
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    child: SmallTextStyle(
                        color: Colors.white, text: 'Export', fontSize: 17),
                  ),
                ),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: Get.height * .21,
                    decoration: BoxDecoration(
                      color: Color(0xff1C1244),
                    ),
                  ),
                  Positioned(
                    left: 130,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Profile Image
                            Container(
                              padding: EdgeInsets.all(3), // frame width
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // gradient border
                              ),
                              child: CircleAvatar(
                                radius: kHeight * 0.0355,
                                backgroundColor: Colors.transparent,
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: ImageHelper.getImageUrl(
                                      authController
                                          .userProfile.value.user!.profileImage,
                                    ),
                                    fit: BoxFit.cover,
                                    width: kHeight * 0.1, // diameter
                                    height: kHeight * 0.1,
                                  ),
                                ),
                              ),
                            ),

                            // Frame overlay - Agency or Custom
                            if (authController
                                        .userProfile.value.user?.agencyId !=
                                    null &&
                                authController
                                        .userProfile.value.user?.agencyId !=
                                    0)
                              // Agency member - show Agency frame
                              SizedBox(
                                height: kHeight * 0.11,
                                width: kHeight * 0.11,
                                child: SVGAEasyPlayer(
                                  assetsName: agencyFrame,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (homeController
                                        .activeFrameData['active_asset_ids'] !=
                                    null &&
                                homeController
                                            .activeFrameData['active_asset_ids']
                                        ['asset'] !=
                                    null &&
                                homeController
                                            .activeFrameData['active_asset_ids']
                                        ['asset']['asset'] !=
                                    null)
                              // Non-agency user - show custom frame
                              CachedNetworkImage(
                                imageUrl:
                                    "$kDomainUrl/${homeController.activeFrameData['active_asset_ids']['asset']['asset']}",
                                height: kHeight * 0.12,
                                width: kHeight * 0.12,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: kHeight * 0.12,
                                  width: kHeight * 0.12,
                                  decoration: BoxDecoration(
                                    color: kAppColor.withValues(alpha: .02),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: kHeight * 0.12,
                                  width: kHeight * 0.12,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: kAppColor.withValues(alpha: .02),
                                  ),
                                ),
                              )
                            else
                              // Fallback when no frame data available
                              SizedBox(
                                height: kHeight * 0.12,
                                width: kHeight * 0.12,
                              ),
                          ],
                        ),
                        SetHeight(heightSet: 0.001),
                        SmallTextStyle(
                          color: Colors.white,
                          text: verifiedController.agencySingleData['name'],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        SmallTextStyle(
                            color: Colors.white,
                            text:
                                'ID: ${verifiedController.agencySingleData['user_id']}',
                            fontSize: 12),
                      ],
                    ),
                  ),
                ],
              ),
              SetHeight(heightSet: 0.05),
              Container(
                width: Get.width * 0.95,
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey,
                          offset: Offset(1, 1),
                          blurRadius: 5),
                    ],
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // 🔹 Header Row
                      Row(
                        children: [
                          Expanded(
                            flex:
                                4, // Host column বড় হবে (name + profile image থাকে)
                            child: SmallTextStyle(
                              color: Colors.blue,
                              text: 'Host',
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: SmallTextStyle(
                              color: Colors.blue,
                              text: 'Total\nDiamonds',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: SmallTextStyle(
                              color: Colors.blue,
                              text: 'Day',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: SmallTextStyle(
                              color: Colors.blue,
                              text: 'Time',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

// 🔹 List Section
                      Obx(() {
                        return SizedBox(
                          height: Get.height * 0.7,
                          child: ListView.builder(
                            itemCount: informationcollectionController
                                .newAgencyhostList.length,
                            itemBuilder: (context, index) {
                              final hostdata = informationcollectionController
                                  .newAgencyhostList[index];
                              return Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 70,
                                  child: Row(
                                    children: [
                                      // Host Column
                                      Expanded(
                                        flex: 4,
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                image: hostdata[
                                                            'asset_purchase_history'] ==
                                                        null
                                                    ? null
                                                    : DecorationImage(
                                                        image: NetworkImage(
                                                          ImageHelper
                                                              .getImageUrl(
                                                            hostdata['asset_purchase_history']
                                                                    ['asset']
                                                                ['asset'],
                                                          ),
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 25,
                                                backgroundColor:
                                                    Colors.grey[300],
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                  child: CachedNetworkImage(
                                                    imageUrl: ImageHelper
                                                        .getImageUrl(hostdata[
                                                            'profile_image']),
                                                    fit: BoxFit.cover,
                                                    width: 50,
                                                    height: 50,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SmallTextStyle(
                                                  color: Colors.black,
                                                  text: hostdata['name'],
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                SmallTextStyle(
                                                  color: Colors.black,
                                                  text:
                                                      'ID: ${hostdata['user_id'] ?? 0}',
                                                  fontSize: 12,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Total Diamonds
                                      Expanded(
                                        flex: 3,
                                        child: SmallTextStyle(
                                          color: Colors.black,
                                          text: hostdata['earned_coins'],
                                          fontSize: 16,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      // Day
                                      Expanded(
                                        flex: 2,
                                        child: SmallTextStyle(
                                          color: Colors.black,
                                          text: '0',
                                          fontSize: 16,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      // Time
                                      Expanded(
                                        flex: 2,
                                        child: SmallTextStyle(
                                          color: Colors.black,
                                          text: '0h0m',
                                          fontSize: 16,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      })
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
