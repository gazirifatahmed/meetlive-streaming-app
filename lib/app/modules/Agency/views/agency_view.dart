import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svga/flutter_svga.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CustomAgencyList.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../../../../widgets/small_text_widgets.dart';
import '../../informationcollection/controllers/informationcollection_controller.dart';
import '../../memberincome/views/memberincome_view.dart';
import '../../ranking/views/ranking_view.dart';
import '../controllers/agency_controller.dart';
import 'ActiveMember.dart';
import 'MemberInvite.dart';
import 'createAgency.dart';

class AgencyView extends GetView<AgencyController> {
  const AgencyView({super.key});
  @override
  Widget build(BuildContext context) {
    Get.put(InformationcollectionController());
    print(verifiedController.agencySingleData);
    informationcollectionController.showRequestAgenctList(
        agencyId: int.parse(
            verifiedController.agencySingleData['agency_id'].toString()));
    return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Color(0xffF6F7FB),
        appBar: CustomAppBar(
          title: 'Agency',
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: Get.height * 0.095),
              // Header Stack Section
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Gradient
                  Container(
                    width: double.infinity,
                    height: Get.height * 0.2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xffb5a7fe), Color(0xffffffff)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // Main White Card
                  Positioned(
                    top: Get.height * 0.12,
                    left: Get.width * 0.02,
                    right: Get.width * 0.02,
                    child: Container(
                      padding: EdgeInsets.all(Get.width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: Get.height * 0.07),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {},
                                child: SmallTextStyle(
                                  color: Colors.black,
                                  text: 'Last week diamonds\n0',
                                  fontSize: 14,
                                ),
                              ),
                              SmallTextStyle(
                                color: Colors.black,
                                text:
                                    'Last month diamonds\n${verifiedController.agencySingleData['blance'] ?? 0}',
                                fontSize: 14,
                              ),
                              SmallTextStyle(
                                color: Colors.black,
                                text: 'Members\n0',
                                fontSize: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Profile Image + Text
                  Positioned(
                    right: Get.width * 0.1,
                    top: Get.height * 0.03,
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
                        SmallTextStyle(
                          color: Colors.black,
                          text:
                              '${verifiedController.agencySingleData['name']}',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        SmallTextStyle(
                          color: Colors.grey[800]!,
                          text:
                              'ID: ${verifiedController.agencySingleData['agency_id'] ?? 0}',
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),

                  // Total Diamond Text
                  Positioned(
                    left: Get.width * 0.07,
                    top: Get.height * 0.16,
                    child: SmallTextStyle(
                      color: Colors.black,
                      text:
                          'Total Diamond: ${verifiedController.agencySingleData['blance'] ?? 0}',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              SizedBox(height: Get.height * 0.08),

              // Bottom White Container with Options
              verifiedController.agencySingleData['status'] == 'pending'
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 50,
                        ),
                        Icon(
                          Icons.hourglass_bottom_rounded,
                          color: Colors.orangeAccent,
                          size: 70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Your Application is Under Review",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please wait while we review your application.\nYou'll be notified once the process is complete.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : verifiedController.agencySingleData['status'] == 'Declined'
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 50),
                            Icon(
                              Icons.cancel_rounded,
                              color: Colors.redAccent,
                              size: 70,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your Application is Rejected',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please review your details and reapply again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Get.to(Createagency());
                              },
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Reapply",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ],
                        )
                      : Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: kWeight * 0.02),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CustomAgencyList(
                                leading: Icons.star_rate,
                                text: 'My Agency Rank',
                                onTap: () => Get.to(RankingView(),
                                    transition: Transition.rightToLeft),
                              ),
                              Divider(color: Colors.grey.withValues(alpha: 0.3)),
                              CustomAgencyList(
                                leading: Icons.attach_money,
                                text: 'Member Income',
                                onTap: () => Get.to(MemberincomeView(),
                                    transition: Transition.rightToLeft),
                              ),
                              Divider(color: Colors.grey.withValues(alpha: 0.3)),
                              CustomAgencyList(
                                badgeCount: informationcollectionController
                                    .newAgencyRequestList.length,
                                leading: Icons.group_add,
                                text: 'Member Request',
                                onTap: () => Get.to(MemberInvite(),
                                    transition: Transition.rightToLeft),
                              ),
                              Divider(color: Colors.grey.withValues(alpha: 0.3)),
                              CustomAgencyList(
                                leading: Icons.calendar_today,
                                text: 'Member Active Days',
                                onTap: () => Get.to(ActiveMember(),
                                    transition: Transition.rightToLeft),
                              ),
                            ],
                          ),
                        ),
              SizedBox(height: 20),
            ],
          ),
        ));
  }
}
