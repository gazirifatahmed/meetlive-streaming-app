import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/auth/views/privacy_policy_page.dart';
import 'package:meetlivepro/app/modules/auth/views/user_agreement_page.dart';

import '../../../../constants/color_constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CustomButtons.dart';
import '../../../../widgets/setheight.dart';
import '../../../../widgets/small_text_widgets.dart';
import '../../../services/google_auth_service.dart';
import '../../registersteps/controllers/registersteps_controller.dart';
import '../../registersteps/views/select_gender.dart';
import 'login_view.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    RegisterstepsController registerstepsController =
    Get.put(RegisterstepsController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SVGAEasyPlayer(
              assetsName: 'assets/svga/Frame/icon_login_bg1.svga',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    const Color(0xff7b2cff).withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        width: double.infinity,

                        padding: EdgeInsets.symmetric(
                          horizontal: kHeight * 0.018,
                          vertical: kHeight * 0.02,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffDA5FF8).withValues(alpha: 0.15),
                              blurRadius: 35,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: kHeight * 0.11),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xffDA5FF8).withValues(alpha: 0.45),
                                    blurRadius: 35,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.asset(
                                  appLogo,
                                  width: kHeight * 0.09,
                                  height: kHeight * 0.09,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: kHeight * 0.008),
                            Text(
                              'Welcome',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: kHeight * 0.032,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: kHeight * 0.008),

                            Text(
                              'Choose your login method',
                              style: GoogleFonts.lato(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: kHeight * 0.016,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            SetHeight(heightSet: 0.03),

                            Obx(
                                  () => CustomButtons(
                                text: registerstepsController.isLoading.value
                                    ? 'Loading...'
                                    : 'Google',
                                gradient:
                                registerstepsController.isLoading.value
                                    ? const LinearGradient(
                                  colors: [
                                    Color(0xff650256),
                                    Color(0xff020947),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                    : const LinearGradient(
                                  colors: [
                                    Color(0xfffdcdfb),
                                    Color(0xff15bccd),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                backgroundColor:
                                registerstepsController.isLoading.value
                                    ? Colors.grey
                                    : null,
                                image:
                                'assets/video/google-color-svgrepo-com.svg',
                                isLoading:
                                registerstepsController.isLoading.value,
                                onTap: () async {
                                  await GoogleAuthService.signInWithGoogle();
                                },
                              ),
                            ),



                            SetHeight(heightSet: 0.012),

                            CustomButtons(
                              text: 'Phone',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xfff93776),
                                  Color(0xff7f23e8),
                                  Color(0xff218afb),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              image:
                              'assets/video/phone-apple-iphone-symbolic-svgrepo-com.svg',
                              onTap: () {
                                Get.to(
                                  const LoginView(),
                                  transition: Transition.leftToRight,
                                );
                              },
                            ),

                            SetHeight(heightSet: 0.02),

                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: SmallTextStyle(
                                    color: Colors.white,
                                    text: 'or',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),

                            SetHeight(heightSet: 0.02),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.20),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: SmallTextStyle(
                                  color: Colors.white,
                                  text: 'ID',
                                  fontSize: kHeight * 0.021,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SetHeight(heightSet: 0.01),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  onChanged: (value) {},
                                  activeColor: kPrimaryColor,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                Flexible(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Agree to ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'User Agreement',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const UserAgreementPage(),
                                                ),
                                              );
                                            },
                                        ),

                                        const TextSpan(text: ' and '),

                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: const TextStyle(
                                            color: Color(0xff7fd7ff),
                                            decoration: TextDecoration.underline,
                                            decorationColor: Color(0xff7fd7ff),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const PrivacyPolicyPage(),
                                                ),
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SetHeight(heightSet: 0.02),

                            InkWell(
                              onTap: () {
                                Get.to(
                                  const SelectGenderView(),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Text(
                                  'Create Account',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: kHeight * 0.22),
                          ],
                        ),
                      ),
                    ),
                  ),


                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}