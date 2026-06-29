import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../../../constants/constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../auth/views/welcome_view.dart';
import '../../auth/views/force_update_view.dart';
import '../../bottomnav/views/bottomnav_view.dart';
import '../../messanger/views/messages/components/firestore_service.dart';
import '../../registersteps/controllers/registersteps_controller.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (authController.needsForceUpdate.value) {
        Get.dialog(const ForceUpdateView(), barrierDismissible: false);
      } else if (authController.userProfile.value.token != null) {
        Get.lazyPut(() => FirestoreService());
        Get.lazyPut(() => RegisterstepsController());
        Get.offAll(() => BottomnavView(), transition: Transition.fadeIn);
      } else {
        Get.offAll(() => const WelcomeView(), transition: Transition.fadeIn);
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image(
                  image: AssetImage(appLogo),
                  height: Get.height * 0.09,
                  width: Get.height * 0.09,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(),
          ],
        ),
      ),
    );
  }
}
