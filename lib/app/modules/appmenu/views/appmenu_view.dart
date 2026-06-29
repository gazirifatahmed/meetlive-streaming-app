import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/appmenu/views/widgets/Flower.dart';
import 'package:meetlivepro/app/modules/appmenu/views/widgets/FlowingList.dart';
import 'package:meetlivepro/app/modules/appmenu/views/widgets/game_test.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/Castom_appmenuCard.dart';
import '../../accountInfornation/views/CoinTopup.dart';
import '../../backpack/views/BackPack.dart';
import '../../home/views/widgets/newcode.dart';

import '../../myprofile/views/myprofile_view.dart';
import '../../rechage/views/Reselar.dart';
import '../../record/views/record_view.dart';
import '../../registersteps/controllers/registersteps_controller.dart';
import '../../reseller/views/reselerView.dart';
import '../../setting/views/setting_view.dart';
import '../../setting/views/widgets/about_page.dart';
import '../../setting/views/widgets/feedback_page.dart';
import '../../store/views/store1_view.dart';
import '../../svip/views/svip_view.dart';
import '../../trading/views/trading_view.dart';
import '../../verified/controllers/verified_controller.dart';
import '../../withdraw/views/lanelpage.dart';
import '../../withdraw/views/withdraw_view.dart';

class AppmenuView extends GetView<RegisterstepsController> {
  const AppmenuView({super.key});

  @override
  Widget build(BuildContext context) {
    VerifiedController verifiedController = Get.put(VerifiedController());
    return Scaffold(
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await registerstepsController.refreshAuthUserData();
        },
        builder: (BuildContext context, Widget child,
            IndicatorController controller) {
          return Stack(
            children: [
              child, // Your scrollable content
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return SizedBox(
                      height: controller.value * 80, // adjust height as needed
                      child: Center(
                        child: controller.isIdle
                            ? const SizedBox()
                            : Container(
                                decoration: BoxDecoration(
                                    color: kAppColor,
                                    borderRadius: BorderRadius.circular(50)),
                                child: Transform.scale(
                                  scale: controller.value
                                      .clamp(0.0, 1.0), // grow as you pull
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.asset(
                                      appLogo, // your image path
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/new/rankingbgimage.png'),fit: BoxFit.cover)
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xffade8f0).withValues(alpha: 0.7),
                      const Color(0xff7b2cff).withValues(alpha: 0.5),
                      Color(0xffcdaafc).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const PageScrollPhysics(),
              child: Obx(() {
                return Column(

                  children: [
                    SizedBox(
                      height: kHeight*0.13,
                    ),
                    //header card


                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: kWeight*0.04),
                      child: Stack(
                        clipBehavior: Clip.none, // যাতে প্রোফাইল ইমেজ বর্ডারের বাইরে যেতে পারে
                        alignment: Alignment.topCenter,
                        children: [


                          // --- ১. মেইন গ্লাস কার্ড ---
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // প্রিমিয়াম ব্লার
                              child: Container(

                                width: double.infinity,
                                padding: EdgeInsets.only(top: 60, bottom: 20, left: 10, right: 10), // উপরে স্পেস দেয়া হয়েছে ইমেজের জন্য
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15), // গ্লাস ট্রান্সপারেন্সি
                                  borderRadius: BorderRadius.circular(20),
                                  // --- ৩ডি বর্ডার গ্লো ইফেক্ট ---
                                  border: Border.all(
                                    width: 1.5,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ],
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.3), // হালকা সাদা ঝলক
                                      Colors.white.withValues(alpha: 0.02),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ---------------- নাম এবং ভেরিফাইড আইকন ----------------
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          authController.userProfile.value.user?.name ?? "User Name",
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // ---------------- UID সেকশন ----------------
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        LevelFrame(
                                          level: '${authController.userProfile.value.user?.level ?? 0}',
                                        ),
                                        SizedBox(width: 10,),
                                        Text(
                                          'Uid : ${authController.userProfile.value.user?.userId}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        IconButton(
                                          constraints: BoxConstraints(),
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: authController.userProfile.value.user!.userId.toString()));
                                            Fluttertoast.showToast(msg: "User ID copied");
                                          },
                                          icon: Icon(Icons.copy, size: 16, color: Colors.black45),
                                        ),
                                      ],
                                    ),

                                    // ---------------- লেভেল ফ্রেম ----------------



                                    SizedBox(height: 10,),
                                    // ---------------- স্ট্যাটাস (Following/Followers) ----------------
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            '${authController.userProfile.value.user?.totalFollowing ?? 0}',
                                            'Following',
                                                () => Get.to(FollowinfList()),
                                          ),
                                        ),
                                        Container(height: 35, width: 1, color: Colors.black12), // হালকা ডিভাইডার
                                        Expanded(
                                          child: _buildStatItem(
                                            '${authController.userProfile.value.user?.totalFollowers ?? 0}',
                                            'Followers',
                                                () => Get.to(Follower(), transition: Transition.rightToLeft),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // --- ২. প্রোফাইল ইমেজ (টপ বর্ডারের মাঝখানে) ---
                          Positioned(
                            top: -50,
                            child: Obx(() {
                              print('level frame4 ${authController.userProfile.value.user?.levelImage}');
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

                              return InkWell(
                                onTap: () {
                                  Get.to(MyProfileView());
                                },
                                child: Container(
                                  height: 110,
                                  width: 110,
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
                                          height: 110,
                                          width: 110,
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
                                          height: 110,
                                          width: 110,
                                          child: SVGAEasyPlayer(
                                            assetsName: 'assets/svga/Frame/Agency frame.svga',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: kHeight*0.015,
                    ),
                    Container(
                      margin:  EdgeInsets.symmetric( horizontal: kWeight*0.04),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: kHeight * 0.015,
                              vertical: kHeight * 0.007,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),

                              // 🔥 MORE WHITE (premium feel)
                              color: Color(0xffade8f0).withValues(alpha: 0.5),

                              // 🔥 MILKY GLASS GRADIENT
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xff5f13f8),
                                  Color(0xff7713fa),
                                  Color(0xff23e1f8),
                                ],
                              ),

                              // 🔥 STRONGER GLASS BORDER
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 1.5,
                              ),

                              // 🔥 SOFT PREMIUM SHADOW
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xffade8f0).withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),

                            child: Row(
                              children: [
                                const Image(
                                  image: AssetImage('assets/icons/favourites.png'),
                                  height: 22,
                                  width: 22,
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Text(
                                    'VVIP Nobel Privies |',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: kHeight * 0.013,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // 🔥 WHITE GLASS BUTTON
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.9),
                                        Colors.white.withValues(alpha: 0.4),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      Get.to(SvipView(),
                                          transition: Transition.rightToLeft);
                                    },
                                    child: Text(
                                      'Open >',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: kHeight * 0.013,
                                        color: const Color(0xff8A4CF7),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _walletSection(),
                    Padding(
                      padding:  EdgeInsets.symmetric(horizontal: kWeight*0.04),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(

                            padding: EdgeInsets.only(top: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .22),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withValues(alpha: .45), width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: .25),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            height: kHeight * 0.25,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: kWeight * 0.02),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      castomCard(
                                        onPress: () {
                                          Get.to(Store1View(),
                                              transition: Transition.rightToLeft);
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xfffff0d4),
                                        text: 'VIP Store',
                                        image: 'assets/icons/online-shopping.png',
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.001,
                                      ),
                                      castomCard(
                                        onPress: () {
                                          Get.to(InvitePage(),
                                              transition: Transition.rightToLeft);
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xffffe3e0),
                                        text: 'Invite',
                                        image: 'assets/icons/card.png',
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.001,
                                      ),

                                      /// ------------- Agency ---------
                                      castomCard3(
                                        onPress: () {
                                          verifiedController.showNewAgenctList();
                                        },
                                        height: 20,
                                        bacgroundColor: const Color(0xfffff0d4),
                                        text: 'Agency',
                                        image: 'assets/flaticons/government.png',
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.015,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      castomCard(
                                        onPress: () {
                                          Get.to(Backpack(),
                                              transition: Transition.rightToLeft);
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xffffe3e0),
                                        text: 'Back pack',
                                        image: 'assets/frame/travel-bag.png',
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.001,
                                      ),
                                      castomCard(
                                        onPress: () {
                                          Get.to(Reselar(),
                                              transition: Transition.rightToLeft);
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xfffff0d4),
                                        text: 'Recharges',
                                        image: 'assets/frame/retreat.png',
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.001,
                                      ),
                                      castomCard3(
                                        onPress: () {
                                          homeController.showHostStatusList();
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xffd6e9fd),
                                        text: 'Verified',
                                        image: 'assets/icons/verify.png',
                                      ),
                                      // SizedBox(
                                      //   height: kHeight * 0.066,
                                      // ),
                                      SizedBox(
                                        height: kHeight * 0.015,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      castomCard(
                                        onPress: () {
                                          Fluttertoast.showToast(
                                            msg: "Coming Soon",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Colors.green,
                                            textColor: Colors.white,
                                            fontSize: 16.0,
                                          );
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xfffff0d4),
                                        text: 'Love',
                                        image: 'assets/audio_live/love.png',
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.001,
                                      ),
                                      castomCard(
                                        onPress: () {
                                          Get.to(MyLevelPage(),
                                              transition: Transition.rightToLeft);
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xffffe3e0),
                                        text: 'My Level',
                                        image: 'assets/icons/deadline.png',
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.001,
                                      ),
                                      // Host অথবা Agency হলে Reward Transfer দেখাবে
                                      authController.userProfile.value.user!.userType ==
                                                  "host" ||
                                              authController.userProfile.value.user!
                                                      .agencyId !=
                                                  "0"
                                          ? castomCard3(
                                              onPress: () {
                                                Get.to(TradingView(),
                                                    transition: Transition.rightToLeft);
                                              },
                                              height: 20,
                                              bacgroundColor: Color(0xfffff0d4),
                                              text: 'Reward Transfer',
                                              image: 'assets/frame/risk.png',
                                            )
                                          // Reseller হলে Reseller দেখাবে
                                          : authController.userProfile.value.user!
                                                      .userType ==
                                                  "reseller"
                                              ? castomCard(
                                                  onPress: () {
                                                    Get.to(Reselerview(),
                                                        transition:
                                                            Transition.rightToLeft);
                                                  },
                                                  height: 20,
                                                  bacgroundColor: Color(0xfff2e9ff),
                                                  text: 'Reseller',
                                                  image:
                                                      'assets/audio_live/diamond.png',
                                                )
                                              // অন্য কেউ হলে খালি space
                                              : SizedBox(
                                                  height: kHeight * 0.0655,
                                                  width: 20,
                                                ),

                                      SizedBox(
                                        height: kHeight * 0.015,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      castomCard2(
                                        onPress: () {
                                          Get.to(RecordView(),
                                              transition: Transition.rightToLeft);
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xfffff0d4),
                                        text: 'Record',
                                        image: 'assets/icons/podcast.png',
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.001,
                                      ),

                                      /// alamin
                                      // castomCard(
                                      //   onPress: () {
                                      //     Get.to(StylishTabBar(),
                                      //         transition: Transition.rightToLeft);
                                      //   },
                                      //   height: 20,
                                      //   bacgroundColor: Color(0xfff2e9ff),
                                      //   text: 'Noble',
                                      //   image: 'assets/icons/crown.png',
                                      // ),

                                      authController.userProfile.value.user!.userType ==
                                          "host" &&
                                          authController.userProfile.value.user!
                                              .agencyId !=
                                              0
                                          ? castomCard2(
                                        onPress: () {
                                          homeController.showEarningData();
                                        },
                                        height: 20,
                                        bacgroundColor: Color(0xfff2e9ff),
                                        text: 'Earnings',
                                        image: 'assets/icons/money.png',
                                      )
                                          : SizedBox.shrink(),
                                      authController.userProfile.value.user!.userType ==
                                          "host" &&
                                          authController.userProfile.value.user!
                                              .agencyId !=
                                              0
                                          ? SizedBox.shrink()
                                          : SizedBox(
                                        height: kHeight * 0.066,
                                        width: 20,
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.015,
                                      ),
                                      SizedBox(
                                        height: kHeight * 0.073,
                                      ),
                                      // castomCard(
                                      //   onPress: () {
                                      //     Fluttertoast.showToast(
                                      //       msg: "Coming Soon",
                                      //       toastLength: Toast.LENGTH_SHORT,
                                      //       gravity: ToastGravity.BOTTOM,
                                      //       backgroundColor: Colors.green,
                                      //       textColor: Colors.white,
                                      //       fontSize: 16.0,
                                      //     );
                                      //     // Get.to(FamilyView(),
                                      //     //     transition: Transition.rightToLeft);
                                      //   },
                                      //   height: 20,
                                      //   bacgroundColor: Color(0xffd6e9fd),
                                      //   text: 'My Family',
                                      //   image: 'assets/icons/family.png',
                                      // ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: kHeight * 0.01,
                    ),


                    Padding(
                      padding:  EdgeInsets.symmetric(horizontal: kWeight*0.04),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: kHeight*0.01),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .22),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white.withValues(alpha: .45), width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: .25),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                castomCard1(
                                  onPress: () {
                                    Get.to(FeedbackPage(),
                                        transition: Transition.leftToRight);
                                  },
                                  height: 20,
                                  bacgroundColor: Colors.white.withValues(alpha: .7),
                                  text: 'Feedback',
                                  image:
                                      'assets/frame/drafts_24dp_E3E3E3_FILL0_wght200_GRAD0_opsz24.svg',
                                ),
                                SizedBox(
                                  width: kWeight * 0.05,
                                ),
                                // MotionTabBarExample(),
                                castomCard1(
                                  onPress: () {
                                    Get.to(AboutUsPage(),
                                        transition: Transition.rightToLeft);
                                  },
                                  height: 20,
                                  bacgroundColor: Colors.white.withValues(alpha: .7),
                                  text: 'About Us',
                                  image:
                                      'assets/frame/data_info_alert_24dp_E3E3E3_FILL0_wght200_GRAD0_opsz24.svg',
                                ),
                                SizedBox(
                                  width: kWeight * 0.05,
                                ),
                                castomCard1(
                                  onPress: () {
                                    Get.to(SettingView(),
                                        transition: Transition.rightToLeft);
                                  },
                                  height: 20,
                                  bacgroundColor: Colors.white.withValues(alpha: .7),
                                  text: 'Settings',
                                  image:
                                      'assets/frame/settings_24dp_E3E3E3_FILL0_wght200_GRAD0_opsz24.svg',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: kHeight * 0.05,
                    )
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: Get.height * 0.014, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: Get.height * 0.014),
          ),
        ],
      ),
    );
  }

  Widget _walletSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kWeight*0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              addvipcenter(
                text: '${authController.userProfile.value.user!.coins}',
                image: 'assets/icons/coin.png',
                textcolor: Colors.black,
                onPressed: () {},
                fastColor: const Color(0xffcff6fd),
                secondColor: const Color(0xf5ebf5ff),
                secondText: 'My Coins',
                buttonText: 'Top up',
                buttonColor: const Color(0xffa276ff),
                icon: Icons.diamond,
                onTap: () {
                  Get.to(CoinTopUp(), transition: Transition.rightToLeft);
                },
              ),
              const SizedBox(width: 10),
              addvipcenter(
                onTap: () {
                  Get.to(WithdrawView(), transition: Transition.rightToLeft);
                },
                text: '${authController.userProfile.value.user!.earnedCoins}',
                image: 'assets/images/earnings.png',
                textcolor: Colors.black,
                onPressed: () {
                  Get.to(WithdrawView(), transition: Transition.rightToLeft);
                },
                fastColor: const Color(0xffebe3fc),
                secondColor: const Color(0x83cab8f6),
                secondText: 'My Contribution',
                buttonText: 'Reward',
                buttonColor: const Color(0xff2ec7ed),
                icon: Icons.attach_money,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
Widget _topIconButton(IconData icon) {
  return Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.3),
      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
    ),
    child: Icon(icon, size: 20, color: Colors.deepPurple.shade400),
  );
}

Widget _buildStatItem(String count, String label, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Column(
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
      ],
    ),
  );
}



Widget premiumGlassCard({
  required Widget child,
  double radius = 28,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff8A4CF7).withValues(alpha: 0.45),
          blurRadius: 25,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.38),
                const Color(0xffB460F0).withValues(alpha: 0.25),
                const Color(0xff6A4CFF).withValues(alpha: 0.22),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 1.4,
            ),
          ),
          child: child,
        ),
      ),
    ),
  );
}