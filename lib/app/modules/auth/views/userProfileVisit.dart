import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/auth/views/profile_view.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomContainer.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../appmenu/views/widgets/Flower.dart';
import '../../appmenu/views/widgets/FlowingList.dart';
import '../../messanger/views/chatpage_view.dart';
import '../../myprofile/controllers/myprofile_controller.dart';
import '../../myprofile/views/EditProfile.dart';
import '../../myprofile/views/ProfileConribution.dart';
import '../../myprofile/views/animationUserProfile.dart';
import '../../myprofile/views/myprofile_view.dart';
import '../../myprofile/views/widgets/fullGiftReceiverPage.dart';

class userProfileVisit extends StatelessWidget {
  const userProfileVisit({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Get.arguments;
    print('cover image ${data['User Data']['cover_images']}');
    MyprofileController myprofileController = Get.put(MyprofileController());
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              //user cover image  show bottom sheet
              Container(
                height: Get.height * 0.3,
                decoration: BoxDecoration(
                  image: (data['User Data']['cover_images'] ==
                      null ||
                      data['User Data']['cover_images'] ==
                          "" ||
                      data['User Data']['cover_images'] ==
                          "No Photo")
                      ? DecorationImage(
                    image: AssetImage('assets/images/profile pic.jpg'),
                    fit: BoxFit.cover,
                  )
                      : DecorationImage(
                    image: NetworkImage(
                      '$kDomainUrl/${data['User Data']['cover_images']}',
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
                      data['User Data']['id']== authController.userProfile.value.user!.id
                          ?
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 25),
                        child: InkWell(
                          onTap: () {
                            Get.to(Editprofile(),
                                transition: Transition.rightToLeft);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: kHeight*0.01,
                              vertical: kHeight*0.01,
                            ),
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
                              child: const Icon(Icons.edit,color: Colors.white,)),

                        ),
                      ):
                      Container(
                        margin: EdgeInsets.only(top: kHeight*0.025, right: 20),
                        padding: EdgeInsets.symmetric(
                          horizontal: kHeight*0.01,
                          vertical: kHeight*0.01,
                        ),
                        decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(7),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xff4ddff3),
                                        Color(0xff9d5bf6).withValues(alpha: .7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),

                        child: Text('Follow'),
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
                    topRight: Radius.circular(30),
                    topLeft: Radius.circular(30),
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
                              '${homeController.profileVisitor['User Data']['name']}',
                              style: GoogleFonts.merriweather(
                                fontSize: kHeight * 0.017,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: kWeight * 0.01,
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
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.leaderboard,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    '${homeController.profileVisitor['User Data']['level']}',
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
                              homeController.profileVisitor['User Data']
                                          ['country'] ==
                                      'Bangladesh'
                                  ? '🇧🇩'
                                  : '',
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
                                'Uid :${homeController.profileVisitor['User Data']['user_id']} '),
                        SizedBox(
                          height: kHeight * 0.015,
                        ),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _statTile(
                                  '${homeController.profileVisitor['User Data']['send_gift_list'].length ?? 0}',
                                  'Sending'),
                              InkWell(
                                onTap: () {
                                  Get.to(FollowinfList(),
                                      transition: Transition.rightToLeft);
                                },
                                child: _statTile(
                                    '${homeController.profileVisitor['User Data']['total_following'] ?? 0}',
                                    'Following'),
                              ),
                              InkWell(
                                onTap: () {
                                  Get.to(Follower(),
                                      transition: Transition.rightToLeft);
                                },
                                child: _statTile(
                                    '${homeController.profileVisitor['User Data']['total_followers'] ?? 0}',
                                    'Followers'),
                              ),
                              // _statTile('0', 'Visitors'),
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
                        SizedBox(height: kHeight * 0.01),
                        userTypeBadges(
                          data['User Data']['user_type'],
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
                                              firstGift['gift']['gift_image'])
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
                                                          height: kHeight * 0.0,
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
                                              firstGift['gift']['gift_image'])
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
                      top: -kHeight * 0.095, // Adjust overlap
                      left: kWeight / 2.3 -
                          (kHeight * 0.06), // Center image (radius 0.06)
                      child: Obx(() {
                        return Stack(
                          alignment:
                              Alignment.center, // Stack er majhe sob center
                          children: [
                            CircleAvatar(
                              radius: kHeight * 0.09,
                              backgroundColor: Colors.transparent,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: CachedNetworkImage(
                                  imageUrl: ImageHelper.getImageUrl(
                                      "${homeController.profileVisitor['User Data']['profile_image'] ?? "default.png"}"),
                                  fit: BoxFit.cover,
                                  height: kHeight * 0.08,
                                  width: kHeight * 0.08,
                                  placeholder: (context, url) => Container(
                                      color: Colors.grey.shade300,
                                      height: kHeight * 0.12,
                                      width: kHeight * 0.12),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.person, size: kHeight * 0.12),
                                ),
                              ),
                            ),
                            // 🔹 Frame Image
                            if (homeController.profileVisitor['User Data']
                                    ['asset_purchase_history'] !=
                                null)
                              CachedNetworkImage(
                                imageUrl: ImageHelper.getImageUrl(
                                    "${homeController.profileVisitor['User Data']['asset_purchase_history']['asset']['asset']}"),
                                height: kHeight * 0.12,
                                width: kHeight * 0.12,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                    color: Colors.grey.shade300,
                                    height: kHeight * 0.12,
                                    width: kHeight * 0.12),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.image, size: kHeight * 0.12),
                              ),

                            // 🔹 Profile Image
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(data),
      ),
    );
  }
}
Widget _buildBottomBar(Map<String, dynamic> data) {
  final userData = data['User Data'];

  final visitorId = userData?['id']?.toString();
  final myId = authController.userProfile.value.user?.id?.toString();

  /// নিজের profile হলে bottom button দেখাবে না
  if (visitorId == null || myId == null || visitorId == myId) {
    return const SizedBox.shrink();
  }

  return SafeArea(
    child: Container(
      height: kHeight * 0.055,
      margin: EdgeInsets.symmetric(
        vertical: kHeight * 0.01,
        horizontal: kWeight * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Get.to(
                      () => ChatPage(
                    receiverId: '${userData['id']}',
                    receiverName: '${userData['name'] ?? ''}',
                    receiverImage: userData['profile_image'] == null
                        ? '$kDomainUrl/${authController.userProfile.value.user?.profileImage ?? ''}'
                        : '$kDomainUrl/${userData['profile_image']}',
                  ),
                  transition: Transition.rightToLeft,
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF4B6E),
                      Color(0xFFFF6B8A),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4B6E).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Hi",
                        style: TextStyle(
                          fontFamily: "Roboto",
                          fontSize: kHeight * 0.01,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF4B6E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Say hello",
                      style: TextStyle(
                        fontFamily: "Roboto",
                        fontSize: kHeight * 0.014,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: InkWell(
              onTap: () {
                Get.bottomSheet(
                  _buildCallingBottomSheet(data),
                  isScrollControlled: true,
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5B6EF5),
                      Color(0xFF7B8FFF),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B6EF5).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Calling",
                      style: TextStyle(
                        fontFamily: "Roboto",
                        fontSize: kHeight * 0.015,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCallingBottomSheet(Map<String, dynamic> data) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: HeaderPainter(),
          child: Container(
            height: kHeight * 0.12,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Guest Living",
                  style: TextStyle(
                    fontFamily: "Roboto",
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "0 Members",
                        style: TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

        SizedBox(height: kHeight * 0.04),

        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Colors.redAccent,
                      Colors.orange,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic,
                  size: kHeight * 0.03,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: kHeight * 0.015),
            Text(
              "Start Living with Host",
              style: TextStyle(
                fontFamily: "Roboto",
                fontSize: kHeight * 0.015,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Choose your preferred mode",
              style: TextStyle(
                fontFamily: "Roboto",
                fontSize: kHeight * 0.013,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),

        SizedBox(height: kHeight * 0.03),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(Get.context!);

                    livestreamController.tryToMakeCall(
                      streamType: 'video',
                      userId: authController.userProfile.value.user!.id!.toInt(),
                      receiverData: data,
                    );
                  },
                  child: Container(
                    height: 54,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF5F6D),
                          Color(0xFFFFC371),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5F6D).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Video",
                          style: TextStyle(
                            fontFamily: "Roboto",
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(Get.context!);

                    livestreamController.tryToMakeCall(
                      streamType: 'audio',
                      userId: authController.userProfile.value.user!.id!.toInt(),
                      receiverData: data,
                    );
                  },
                  child: Container(
                    height: 54,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Voice",
                          style: TextStyle(
                            fontFamily: "Roboto",
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: kHeight * 0.04),
      ],
    ),
  );
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
