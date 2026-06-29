import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/setting/views/widgets/about_page.dart';
import 'package:meetlivepro/app/modules/setting/views/widgets/acount_security.dart';


import '../../../../constants/layout_constant.dart';
import '../../../../constants/name_constants.dart';
import '../../accountInfornation/views/widget/CastomBtton.dart';
import '../../notification/views/notification_view.dart';
import '../../registersteps/controllers/registersteps_controller.dart';
import 'blockList.dart';

class SettingController extends GetxController {}

class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
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
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Settings',
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
              Color(0xffffffff),
            ], begin: Alignment.topRight, end: Alignment.bottomRight)),
          ),
          ListView(
            children: [
              CustomSettingOption(),
              SizedBox(
                height: kHeight * 0.003,
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    CastomSettingOption(
                      onPressed: () {
                        Get.to(BlockListPage(), transition: Transition.fade);
                      },
                      text: 'Block List',
                    ),
                    CastomSettingOption(
                      onPressed: () {
                        Get.to(NotificationView(),
                            transition: Transition.rightToLeft);
                      },
                      text: 'Notification',
                    ),
                    CastomSettingOption(
                      onPressed: () {
                        Get.to(AboutUsPage(), transition: Transition.rightToLeft);
                      },
                      text: 'About Us',
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: kHeight * 0.0015,
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    CastomSettingOption1(
                      text: 'Clean Cache',
                      secoundText: '100Mb',
                    ),
                    CastomSettingOption1(
                      text: 'Version',
                      secoundText: kAppVersion,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: kHeight * 0.15,
              ),
              Center(
                child: CastomAppButton(
                    onPressed: () {
                      Get.find<RegisterstepsController>().tryToSignOut();
                    },
                    buttonText: 'Log out'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
