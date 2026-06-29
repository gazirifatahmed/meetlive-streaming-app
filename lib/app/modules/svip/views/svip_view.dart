import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../controllers/svip_controller.dart';
import 'Widgets/CastomSvipCard.dart';
import 'Widgets/lightSweepContainerSvip.dart';

class SvipView extends StatelessWidget {
  // ১. মেথড ইনভোক করার সুবিধার্থে কনস্ট্রাক্টরের const কিওয়ার্ড তুলে দিয়ে ফিল্ডটি রাখা হলো
  final SvipController svipController = Get.put(SvipController());

  SvipView({super.key}); // const রিমুভ করা হয়েছে

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0c0700),
      body: Stack(
        children: [
          Obx(() => svipTabContent(svipController.selectedTab.value)),

          // Top AppBar
          Positioned(
            top: -Get.height * 0.017,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_outlined,
                          color: Colors.white),
                    ),
                    Castontext(
                      textColor: Colors.white,
                      fontSize: Get.height * 0.021,
                      fontWeight: FontWeight.w600,
                      text: 'VIP',
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(CupertinoIcons.question_circle_fill,
                              color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.settings, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Tab Bar
          Positioned(
            top: Get.height * 0.12,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(left: Get.width * 0.04),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(8, (index) {
                    return Obx(() {
                      bool isSelected =
                          svipController.selectedTab.value == index;
                      return GestureDetector(
                        onTap: () => svipController.changeTab(index),
                        child: Padding(
                          padding: EdgeInsets.only(right: Get.width * 0.06),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                getTabName(index),
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w500,
                                  fontSize: Get.height * 0.017,
                                  color: isSelected
                                      ? Colors.yellow
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 3,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.yellow
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------- Tab Body Switcher ---------------------
  Widget svipTabContent(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return buildSvipTab1();
      case 1:
        return buildSvipTab2();
      default:
        return buildSvipTab1();
    }
  }

  String getTabName(int index) {
    if (index < 7) {
      return 'VIP${index + 1}';
    } else {
      return 'SVIP'; 
    }
  }
}

// ২. মেমোরিতে অলরেডি ইনজেক্টেড কন্ট্রোলারটি পাওয়ার জন্য Get.find() ব্যবহার করা হলো
Widget buildSvipTab1() {
  final SvipController svipController = Get.find<SvipController>();
  return Stack(
    children: [
      SingleChildScrollView(
        controller: svipController.scrollController,
        child: Column(
          children: [
            // ----------- Background section ------------
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Svip/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: Get.height * 0.11),
                  SizedBox(height: Get.height * 0.07),
                  SizedBox(
                    height: Get.height * 0.18,
                    width: Get.height * 0.18,
                    child: const SVGAEasyPlayer(
                      assetsName: 'assets/svga/Frame/Vip frame 1.svga',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: Get.height * 0.08),
                ],
              ),
            ),

            // ---------- Wavy + Content Section ----------
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: Get.height * 0.02,
                  width: double.infinity,
                  child: const SVGAEasyPlayer(
                    assetsName: 'assets/svga/Frame/vip1.2svga',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        // --------------------Identity Title-------------------
                        SizedBox(height: Get.height * 0.04),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('༺༒',
                                style: TextStyle(
                                    color: const Color(0xfff8df96),
                                    fontSize: Get.height * 0.018)),
                            const SizedBox(width: 6),
                            Text('VIP Identity',
                                style: TextStyle(
                                    color: const Color(0xfff8df96),
                                    fontSize: Get.height * 0.018,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Text('༒༻',
                                style: TextStyle(
                                    color: const Color(0xfff8df96),
                                    fontSize: Get.height * 0.018)),
                          ],
                        ),

                        //------------------ Grid View ----------------
                        GridView.builder(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: svipController.gridItems.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 3 / 4,
                          ),
                          itemBuilder: (context, index) {
                            final item = svipController.gridItems[index];
                            return InkWell(
                              onTap: () {
                                Get.dialog(
                                  Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xffcbb06d),
                                            Color(0xff866437),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: Get.height * 0.03),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal:
                                                        Get.width * 0.08),
                                                height: Get.height * 0.23,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  image: const DecorationImage(
                                                    image: AssetImage(
                                                      'assets/audio_live/black-abstract-background-p01mtbhhv71g8642-min.jpg',
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                  height: Get.height * 0.025),
                                              Castontext(
                                                textColor: const Color(0xfff1e5ae),
                                                fontSize: Get.height * 0.023,
                                                fontWeight: FontWeight.w700,
                                                text: 'SVIP Frame',
                                              ),
                                              SizedBox(
                                                  height: Get.height * 0.015),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        Get.width * 0.05),
                                                child: Text(
                                                  'SVIP exclusive frame will change with your SVIP level. The higher the level is, the more luxurious title will be. It will be automatically worn after unlocking SVIP.',
                                                  style: GoogleFonts.roboto(
                                                    color: const Color(0xfff1e5ae),
                                                    fontSize:
                                                        Get.height * 0.018,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  textAlign: TextAlign.justify,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: Get.height * 0.025),
                                              GestureDetector(
                                                onTap: () => Get.back(),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: Get.width * 0.5,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical:
                                                          Get.height * 0.014),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xffedd18b),
                                                        Color(0xfff0c26d),
                                                      ],
                                                      begin:
                                                          Alignment.centerLeft,
                                                      end:
                                                          Alignment.centerRight,
                                                    ),
                                                  ),
                                                  child: Castontext(
                                                    textColor:
                                                        const Color(0xff633609),
                                                    fontSize: Get.height * 0.02,
                                                    fontWeight: FontWeight.w700,
                                                    text: 'OK',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xfffbc7b7), width: 0.1),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff2d2010),
                                      Color(0xff3a2814)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(7)),
                                        child: item['image']!
                                                .toString()
                                                .endsWith('.svga')
                                            ? SizedBox(
                                                height: Get.height * 0.15,
                                                width: Get.height * 0.15,
                                                child: const SVGAEasyPlayer(
                                                  assetsName:
                                                      'assets/svga/Frame/Vip frame 1.svga',
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Image.asset(
                                                item['image']!,
                                                height: Get.height * 0.2,
                                                width: Get.width * 0.2,
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Text(
                                        item['text']!,
                                        style: TextStyle(
                                          color: const Color(0xfff8df96),
                                          fontSize: Get.height * 0.016,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        //----------------------------- Icon Cards----------------------
                        SizedBox(height: Get.height * 0.015),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Castontext(
                                  fontWeight: FontWeight.w400,
                                  fontSize: Get.height * 0.018,
                                  textColor: const Color(0xfff3d16d),
                                  text: '☬'),
                              const SizedBox(width: 20),
                              Castontext(
                                  fontWeight: FontWeight.w400,
                                  fontSize: Get.height * 0.018,
                                  textColor: const Color(0xfff3d16d),
                                  text: 'Exclusive privileges'),
                              const SizedBox(width: 20),
                              Castontext(
                                  fontWeight: FontWeight.w400,
                                  fontSize: Get.height * 0.018,
                                  textColor: const Color(0xfff3d16d),
                                  text: '☬'),
                            ],
                          ),
                        ),
                        SizedBox(height: Get.height * 0.018),

                        GridView.builder(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: svipController.gridItems2.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 3 / 4,
                          ),
                          itemBuilder: (context, index) {
                            final item = svipController.gridItems2[index];
                            return InkWell(
                              onTap: () {
                                // এখানে আপনার Get.bottomSheet এর কাস্টম লজিক থাকবে...
                              },
                              child: SvipOptionCard(
                                image: item['image']!,
                                text: item['text']!,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: Get.height * 0.068),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // ----------- Bottom Card ------------
      Obx(() => AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 10,
            right: 10,
            bottom: svipController.showBottomCard.value ? 20 : -150,
            child: const LightSweepContainerSvip(
              gradient1: LinearGradient(
                colors: [
                  Color(0xff4b351e),
                  Color(0xffb79c85),
                  Color(0xff4b351e),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          )),
    ],
  );
}

///----------------------------------------page 2 ----------------------
Widget buildSvipTab2() {
  final SvipController svipController = Get.find<SvipController>();
  return Stack(
    children: [
      SingleChildScrollView(
        controller: svipController.scrollController,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Svip/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: Get.height * 0.11),
                  SizedBox(height: Get.height * 0.07),
                  SizedBox(
                    height: Get.height * 0.18,
                    width: Get.height * 0.18,
                    child: const SVGAEasyPlayer(
                      assetsName: 'assets/svga/Frame/Vip frame 2.svga',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: Get.height * 0.08),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: Get.height * 0.02,
                  width: double.infinity,
                  child: const SVGAEasyPlayer(
                    assetsName: 'assets/svga/Frame/vip1.2svga',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    color: const Color(0xff21002b),
                    child: const Column(
                      children: [],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}