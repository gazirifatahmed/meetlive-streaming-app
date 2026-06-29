import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/myprofile/views/widgets/fullGiftReceiverPage.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomContainer.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/buildIconbutton.dart';
import '../../appmenu/views/widgets/Flower.dart';
import '../../appmenu/views/widgets/FlowingList.dart';
import '../../appmenu/views/widgets/game_test.dart';
import '../controllers/myprofile_controller.dart';
import 'EditProfile.dart';
import 'ProfileConribution.dart';
import 'animationUserProfile.dart';

class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    String name = authController.userProfile.value.user!.name ?? '';
    String shortName = name.length > 14 ? '${name.substring(0, 14)}...' : name;
    print(
        'User Profile Data ${authController.userProfile.value.user!.userType}');
    MyprofileController myprofileController = Get.put(MyprofileController());
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              //user cover image  show bottom sheet
              Container(
                height: Get.height * 0.4,
                decoration: BoxDecoration(
                  image: (authController.userProfile.value.user?.coverImages ==
                              null ||
                          authController.userProfile.value.user?.coverImages ==
                              "" ||
                          authController.userProfile.value.user?.coverImages ==
                              "No Photo")
                      ? DecorationImage(
                          image: AssetImage('assets/images/profile pic.jpg'),
                          fit: BoxFit.cover,
                        )
                      : DecorationImage(
                          image: NetworkImage(
                            '$kDomainUrl/${authController.userProfile.value.user!.coverImages}',
                          ),
                          fit: BoxFit.cover,
                        ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                                Color(0xff4ddff3),
                                Color(0xff9d5bf6).withValues(alpha: .7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child:  Icon(
                            Icons.arrow_back_ios_new_outlined,
                            color: Colors.white,
                            size: kHeight*0.02,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 25),
                        child: topIconbutton(
                          onPressed: () {
                            Get.to(Editprofile(),
                                transition: Transition.rightToLeft);
                          },
                          icon: const Icon(Icons.edit),
                          colour: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              //----------------profile -------------------
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(40),
                    topLeft: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: kHeight * 0.045,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              shortName,
                              style: GoogleFonts.merriweather(
                                fontSize: kHeight * 0.017,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: kWeight * 0.04,
                            ),
                            LevelFrame(
                              level:
                                  '${authController.userProfile.value.user!.level}',
                            ),
                            SizedBox(
                              width: kWeight * 0.04,
                            ),
                            Container(
                              height: 15,
                              width: 35,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50),
                                ),
                                color: Color(0xff843af4),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.male,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    '22',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: kWeight * 0.01,
                            ),
                            Text(
                              '🇧🇩',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: kHeight * 0.01,
                        ),
                        Castontext(
                            fontSize: kHeight * 0.016,
                            fontWeight: FontWeight.w600,
                            textColor: Colors.black.withValues(alpha: .7),
                            text:
                                'Uid :${authController.userProfile.value.user!.userId} '),
                        SizedBox(
                          height: kHeight * 0.015,
                        ),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _statTile(
                                  '${myprofileController.profileGiftList.length ?? 0}',
                                  'Sending'),
                              InkWell(
                                onTap: () {
                                  Get.to(FollowinfList(),
                                      transition: Transition.rightToLeft);
                                },
                                child: _statTile(
                                    '${authController.userProfile.value.user?.totalFollowing ?? 0}',
                                    'Following'),
                              ),
                              InkWell(
                                onTap: () {
                                  Get.to(Follower(),
                                      transition: Transition.rightToLeft);
                                },
                                child: _statTile(
                                    '${authController.userProfile.value.user?.totalFollowers ?? 0}',
                                    'Followers'),
                              ),
                              _statTile('0', 'Visitors'),
                            ],
                          ),
                        ),
                        SizedBox(height: kHeight * 0.02),
                        // ---------------------level identity -------------------
                        Row(
                          children: [
                            SizedBox(width: 12),
                            Text(
                              'Identity',
                              style: GoogleFonts.roboto(
                                fontSize: kHeight * 0.019,
                                color: Colors.black.withValues(alpha: .8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        userTypeBadges(
                          authController.userProfile.value.user?.userType,
                          kHeight,
                        ),

                        SizedBox(height: kHeight * 0.00),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Get.width *
                                0.03, // responsive horizontal padding
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ==== Left Title ====
                              Text(
                                'Top Contribution List',
                                style: GoogleFonts.roboto(
                                  fontSize: kHeight * 0.019,
                                  color: Colors.black.withValues(alpha: .8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              // ==== Right Side (Profile List + Arrow) ====
                              Row(
                                children: [
                                  // horizontal scrollable profile images
                                  SizedBox(
                                    height:
                                        Get.height * 0.05, // responsive height
                                    width: Get.width *
                                        0.35, // fixed responsive width
                                    child: FutureBuilder(
                                        future: myprofileController
                                            .showProfileContributionList(),
                                        builder: (context, snapshot) {
                                          return ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: myprofileController
                                                    .profileContributionList
                                                    .length ??
                                                0,
                                            itemBuilder: (BuildContext context,
                                                int sendIndex) {
                                                    return Padding(
                                                padding: EdgeInsets.only(
                                                    right: Get.width * 0.015),
                                                child: CastomCardProfileImage(
                                                  onPressed: () {
                                                    Get.to(Profileconribution(),
                                                        transition: Transition
                                                            .rightToLeft);
                                                  },
                                                  frame: myprofileController
                                                                          .profileContributionList[
                                                                      sendIndex]
                                                                  ['sender'][
                                                              'asset_purchase_history'] ==
                                                          null
                                                      ? null
                                                      : DecorationImage(
                                                          image: NetworkImage(
                                                              ImageHelper
                                                                  .getImageUrl(
                                                                      '${myprofileController.profileContributionList[sendIndex]['sender']['asset_purchase_history']['asset']['asset']}')),
                                                          fit: BoxFit.cover),
                                                  image: ImageHelper.getImageUrl(
                                                      '${myprofileController.profileContributionList[sendIndex]['sender']['profile_image']}'),
                                                ),
                                              );
                                            },
                                          );
                                        }),
                                  ),

                                  // arrow button
                                  IconButton(
                                    onPressed: () {
                                      Get.to(Profileconribution(),
                                          transition: Transition
                                              .rightToLeft);
                                    },
                                    icon: Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey,
                                      size: Get.height *
                                          0.022, // responsive icon size
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),

                        homeController.profileVisitor['user_agency'] == null
                            ? SizedBox.shrink()
                            : LightSweepContainer2(),

                        SizedBox(height: kHeight * 0.01),

                        Row(
                          children: [
                            SizedBox(width: 12),
                            Text(
                              'Gifts - Received',
                              style: GoogleFonts.roboto(
                                fontSize: kHeight * 0.019,
                                color: Colors.black.withValues(alpha: .8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: kHeight * 0.01),
                        FutureBuilder(
                          future: myprofileController.showProfileReciverList(),
                          builder: (context, snapshot) {
                            final list =
                                myprofileController.profileGiftReceverList;
                            final showList =
                                list.length > 4 ? list.take(4).toList() : list;

                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: kWeight * 0.022),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      mainAxisExtent: kHeight * 0.11,
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.7,
                                    ),
                                    itemCount: showList.length,
                                    itemBuilder: (context, index) {
                                      final item = showList[index];

                                      // প্রথম gift নিরাপদভাবে নেওয়া
                                      final firstGift = item['gifts'] != null &&
                                              item['gifts'].isNotEmpty
                                          ? item['gifts'][0]
                                          : null;
                                      print('svga sound $firstGift');
                                      // প্রথম gift এর image (index 0 ব্যবহার করা হয়েছে, grid index নয়)
                                      final firstGiftImage = firstGift !=
                                                  null &&
                                              firstGift['gift'] != null
                                          ? ImageHelper.getImageUrl(
                                              firstGift['gift']['show_image'])
                                          : null;

                                      // Total gift count
                                      final giftCount = item['gifts'] != null
                                          ? item['gifts'].length
                                          : 0;

                                      print(
                                          'sent gift count: $firstGiftImage, total gifts: $giftCount');

                                      return GestureDetector(
                                        onTap: () {
                                          homeController.visitProfile(
                                              userId:
                                                  '${item['sender']['id']}');
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0x85d9c0f8),
                                                Color(0xca8c6af0)
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: const Color(0x85461dd6),
                                              width: 2,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                left: kWeight * 0.075,
                                                bottom: 3,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.0),
                                                  child: AutoSizeText(
                                                    'х $giftCount',
                                                    style: GoogleFonts.roboto(
                                                        color: Colors.black
                                                            .withValues(alpha: .5),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize:
                                                            kHeight * 0.022),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              // FIRST GIFT IMAGE SHOW
                                              if (firstGiftImage != null)
                                                firstGiftImage
                                                        .toString()
                                                        .endsWith('.svga')
                                                    ? Positioned(
                                                        top: kHeight * 0.01,
                                                        left: 0,
                                                        right: 0,
                                                        child: SizedBox(
                                                          height:
                                                              kHeight * 0.05,
                                                          width: kHeight * 0.05,
                                                          child: SVGAEasyPlayer(
                                                            resUrl:
                                                                firstGiftImage,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      )
                                                    : Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(2.0),
                                                          child: SizedBox(
                                                            height:
                                                                kHeight * 0.05,
                                                            width:
                                                                kHeight * 0.05,
                                                            child:
                                                                CachedNetworkImage(
                                                              imageUrl:
                                                                  firstGiftImage,
                                                              height: kHeight *
                                                                  0.08,
                                                              fit: BoxFit.cover,
                                                              errorWidget: (context,
                                                                      url,
                                                                      error) =>
                                                                  Icon(
                                                                      Icons
                                                                          .error,
                                                                      size: kHeight *
                                                                          0.05),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                              else
                                                Icon(
                                                  Icons.card_giftcard,
                                                  size: kHeight * 0.05,
                                                  color: Colors.white54,
                                                ),

                                              // GIFT COUNT SHOW
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (list.length > 4)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Get.to(() => FullGiftReceiverPage(
                                              list: showList));
                                        },
                                        child: Text(
                                          'View All',
                                          style: GoogleFonts.roboto(
                                            color: Color(0xff8A4CF7),
                                            fontSize: kHeight * 0.016,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: 0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Text(
                                'Gifts - Sent',
                                style: GoogleFonts.roboto(
                                  fontSize: kHeight * 0.019,
                                  color: Colors.black.withValues(alpha: .8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        SizedBox(height: kHeight * 0.0),

                        ///------------------  Gift sent -----------

                        FutureBuilder(
                          future: myprofileController.showProfileGiftList(),
                          builder: (context, snapshot) {
                            final list = myprofileController.profileGiftList;
                            final showList =
                                list.length > 4 ? list.take(4).toList() : list;

                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: kWeight * 0.022),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      mainAxisExtent: kHeight * 0.11,
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.7,
                                    ),
                                    itemCount: showList.length,
                                    itemBuilder: (context, index) {
                                      final item = showList[index];

                                      // gifts_merged theke data newa (aapnar data te gifts_merged ache)
                                      final giftsList =
                                          item['gifts_merged'] ?? [];

                                      // Prothom gift safely newa
                                      final firstGift = giftsList.isNotEmpty
                                          ? giftsList[0]
                                          : null;

                                      // Prothom gift er image
                                      final firstGiftImage = firstGift !=
                                                  null &&
                                              firstGift['gift'] != null
                                          ? ImageHelper.getImageUrl(
                                              firstGift['gift']['show_image'])
                                          : null;

                                      // Total gift count (gift_send_count use kora better)
                                      final giftCount =
                                          item['gift_send_count'] ??
                                              giftsList.length;

                                      print(
                                          'Receiver: ${item['receiver']['name']}, Gift count: $giftCount, Image: $firstGiftImage');

                                      return GestureDetector(
                                        onTap: () {
                                          // receiver id use korte hobe
                                          homeController.visitProfile(
                                              userId:
                                                  '${item['receiver']['id']}');
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0x85d9c0f8),
                                                Color(0xca8c6af0)
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: const Color(0x85461dd6),
                                              width: 2,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              // GIFT COUNT TEXT
                                              Positioned(
                                                left: kWeight * 0.075,
                                                bottom: 3,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.0),
                                                  child: AutoSizeText(
                                                    'х $giftCount',
                                                    style: GoogleFonts.roboto(
                                                      color: Colors.black
                                                          .withValues(alpha: .5),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: kHeight * 0.022,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),

                                              // FIRST GIFT IMAGE
                                              if (firstGiftImage != null)
                                                firstGiftImage
                                                        .toString()
                                                        .endsWith('.svga')
                                                    ? Positioned(
                                                        top: kHeight * 0.01,
                                                        left: 0,
                                                        right: 0,
                                                        child: SizedBox(
                                                          height:
                                                              kHeight * 0.05,
                                                          width: kHeight * 0.05,
                                                          child: SVGAEasyPlayer(
                                                            resUrl:
                                                                firstGiftImage,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      )
                                                    : Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: SizedBox(
                                                            height:
                                                                kHeight * 0.05,
                                                            width:
                                                                kHeight * 0.03,
                                                            child:
                                                                CachedNetworkImage(
                                                              imageUrl:
                                                                  firstGiftImage,
                                                              height: kHeight *
                                                                  0.08,
                                                              fit: BoxFit.cover,
                                                              errorWidget:
                                                                  (context, url,
                                                                          error) =>
                                                                      Icon(
                                                                Icons.error,
                                                                size: kHeight *
                                                                    0.05,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                              else
                                                Positioned(
                                                  top: kHeight * 0.02,
                                                  left: 0,
                                                  right: 0,
                                                  child: Icon(
                                                    Icons.card_giftcard,
                                                    size: kHeight * 0.05,
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // VIEW ALL BUTTON
                                if (list.length > 4)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Get.to(() =>
                                              FullGiftReceiverPage(list: list));
                                        },
                                        child: Text(
                                          'View All',
                                          style: GoogleFonts.roboto(
                                            color: Color(0xff8A4CF7),
                                            fontSize: kHeight * 0.016,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: 15),
                      ], //fast row end
                    ),
                    Positioned(
                      top: -kHeight * 0.07, // Adjust overlap
                      left: kWeight / 2 -
                          (kHeight * 0.06),
                      child: Obx(() {
                        final userProfile = authController.userProfile.value;
                        final user = userProfile.user;

                        final profileImage = user?.profileImage ?? '';

                        // Only asset_histories frame, entry_histories never use here
                        final framePath =
                            userProfile.assetHistories?.asset?.asset?.toString() ?? '';

                        final agencyId =
                            int.tryParse(user?.agencyId?.toString() ?? '0') ?? 0;

                        final bool hasUserFrame =
                            userProfile.assetHistories != null &&
                                framePath.isNotEmpty &&
                                userProfile.assetHistories?.asset?.type == 'Frame';

                        final bool hasAgencyFrame = !hasUserFrame && agencyId > 0;

                        final baseUrl = kDomainUrl.replaceAll(RegExp(r'/+$'), '');
                        final frameUrl = '$baseUrl/$framePath';

                        print('Asset Histories => ${userProfile.assetHistories}');
                        print('Entry Histories => ${userProfile.entryHistories}');
                        print('Frame Path => $framePath');
                        print('Frame Url => $frameUrl');
                        print('Has User Frame => $hasUserFrame');

                        return Container(
                          height: kHeight * 0.1,
                          width: kHeight * 0.11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: CachedNetworkImage(
                                    imageUrl: ImageHelper.getImageUrl(profileImage),
                                    fit: BoxFit.cover,
                                    height: 80,
                                    width: 80,
                                    placeholder: (c, u) =>
                                    const CircularProgressIndicator(strokeWidth: 2),
                                    errorWidget: (c, u, e) =>
                                    const Icon(Icons.person, size: 50),
                                  ),
                                ),
                              ),

                              if (hasUserFrame)
                                SizedBox(
                                  height: kHeight * 0.1,
                                  width: kHeight * 0.11,
                                  child: framePath.toLowerCase().endsWith('.svga')
                                      ? SVGAEasyPlayer(
                                    resUrl: frameUrl,
                                    fit: BoxFit.cover,
                                  )
                                      : CachedNetworkImage(
                                    imageUrl: frameUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (hasAgencyFrame)
                                SizedBox(
                                  height: kHeight * 0.1,
                                  width: kHeight * 0.11,
                                  child: SVGAEasyPlayer(
                                    assetsName: 'assets/svga/Frame/Agency frame.svga',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: kHeight * 0.05,
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget _statTile(String value, String label) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: kHeight * 0.015),
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.roboto(
              fontSize: kHeight * 0.019, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style:
              TextStyle(color: Colors.grey.shade600, fontSize: kHeight * 0.015),
        ),
      ],
    ),
  );
}
Widget userTypeBadges(String? userType, double kHeight) {
  final roles = (userType ?? '')
      .toLowerCase()
      .split(RegExp(r'[,| ]+'))
      .where((e) => e.trim().isNotEmpty)
      .toList();

  final Map<String, String> roleImages = {
    'host': 'assets/Pk/Host__1_-removebg-preview.png',
    'reseller': 'assets/Pk/reseller__1_-removebg-preview.png',
    'agent': 'assets/Pk/agent__2___1_-removebg-preview.png',
  };

  final badges = roles
      .where((role) => roleImages.containsKey(role))
      .map((role) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.45),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Image.asset(
        roleImages[role]!,
        height: kHeight * 0.045,
      ),
    );
  }).toList();

  if (badges.isEmpty) return const SizedBox.shrink();

  return Align(
    alignment: Alignment.topLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: badges,
    ),
  );
}