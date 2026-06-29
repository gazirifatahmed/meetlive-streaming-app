import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/after/CustomTextFormField.dart';
import '../../../../widgets/setheight.dart';
import '../../registersteps/controllers/registersteps_controller.dart';
import '../controllers/auth_controller.dart';
import 'forget_password.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final RegisterstepsController controller =
    Get.put(RegisterstepsController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        elevation: 0,
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
            ),
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: kHeight * 0.02,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Phone Login',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontSize: Get.height * 0.02,
          ),
        ),
      ),
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/new/rankingbgimage.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.purple.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SetHeight(heightSet: 0.3),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: Get.width,
                          padding: EdgeInsets.symmetric(
                            horizontal: kHeight * 0.018,
                            vertical: kHeight * 0.045,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.38),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.1),
                                blurRadius: 35,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(-4, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              SizedBox(height: kHeight * 0.008),

                              Text(
                                'Login with your phone number',
                                style: GoogleFonts.roboto(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: kHeight * 0.015,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              SizedBox(height: kHeight * 0.04),

                              Obx(
                                    () => CustomTextFormField(
                                  controller: controller.loginPhone,
                                  text: 'Enter phone number',
                                  prefix: Icons.phone,
                                  fillColor: Colors.white.withValues(alpha: 0.22),
                                  errorText:
                                  controller.loginPhoneError.value,
                                  onChanged: controller.onPhoneChanged,
                                ),
                              ),

                              SizedBox(height: Get.height * 0.02),

                              Obx(
                                    () => CustomTextFormField(
                                  controller: controller.loginPassword,
                                  text: 'Enter password',
                                  prefix: Icons.lock,
                                  fillColor: Colors.white.withValues(alpha: 0.22),
                                  obscureText: true,
                                  errorText:
                                  controller.loginPasswordError.value,
                                  onChanged: controller.onPasswordChanged,
                                ),
                              ),

                              SizedBox(height: Get.height * 0.05),

                              Obx(
                                    () => Center(
                                  child: GestureDetector(
                                    onTap: (controller.loginPhoneText.value
                                        .isNotEmpty &&
                                        controller.loginPasswordText.value
                                            .isNotEmpty &&
                                        controller.loginPhoneError.value ==
                                            null &&
                                        controller.loginPasswordError
                                            .value ==
                                            null &&
                                        !controller.isLoading.value)
                                        ? () {
                                      controller.tryToSignIn();
                                    }
                                        : null,
                                    child: Container(
                                      width: Get.width * 0.72,
                                      padding: EdgeInsets.symmetric(
                                        vertical: kHeight * 0.016,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: (controller.loginPhoneText
                                              .value.isNotEmpty &&
                                              controller.loginPasswordText
                                                  .value.isNotEmpty &&
                                              controller.loginPhoneError
                                                  .value ==
                                                  null &&
                                              controller.loginPasswordError
                                                  .value ==
                                                  null)
                                              ? [
                                            const Color(0xffd66cff),
                                            const Color(0xff9458fb),
                                            const Color(0xff5f7cff),
                                          ]
                                              : [
                                            Colors.white
                                                .withValues(alpha: 0.18),
                                            Colors.white
                                                .withValues(alpha: 0.10),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(50),
                                        border: Border.all(
                                          color:
                                          Colors.white.withValues(alpha: 0.30),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xff9458fb)
                                                .withValues(alpha: 0.45),
                                            blurRadius: 25,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: controller.isLoading.value
                                            ? const SizedBox(
                                          height: 25,
                                          width: 25,
                                          child:
                                          CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                            : Text(
                                          'Log in',
                                          style: GoogleFonts.roboto(
                                            fontSize: kHeight * 0.019,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: kHeight * 0.025),

                              InkWell(
                                onTap: () {
                                  Get.to(
                                    ForgetPasswordPage(),
                                    transition: Transition.rightToLeft,
                                  );
                                },
                                child: Castontext(
                                  fontWeight: FontWeight.w600,
                                  textColor: Colors.white.withValues(alpha: 0.90),
                                  fontSize: kHeight * 0.016,
                                  text: 'Forget Password ?',
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}