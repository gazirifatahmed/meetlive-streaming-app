import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../../widgets/after/castom appbar.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/setheight.dart';
import '../../../../widgets/small_text_widgets.dart';
import '../controllers/withdraw_controller.dart';
import '../withdraw_account-add.dart';
import 'exchange_coin_view.dart';

class WithdrawView extends GetView<WithdrawController> {
  const WithdrawView({super.key});

  @override
  Widget build(BuildContext context) {
    WithdrawController withdrawController = Get.put(WithdrawController());
    return Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          title: 'Income',
        ),
        body: Column(
          children: [
            SizedBox(
              height: kHeight * 0.13,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
              padding: EdgeInsets.symmetric(vertical: kHeight * 0.07),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [ Color(0xffade8f0), // Light Blue
                    Color(0xffcdaafc),],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SmallTextStyle(
                        color: Color(0xff0e0e0e), // deeper text contrast
                        text: 'Receive',
                        fontSize: 15,
                      ),
                      SizedBox(height: 6),
                      SmallTextStyle(
                        color: Color(0xff0e0e0e),
                        text:
                            '${authController.userProfile.value.user!.earnedCoins}',
                        fontSize: 18,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SmallTextStyle(
                        color: Color(0xff0e0e0e),
                        text: 'Coin Bag available (\$)',
                        fontSize: 15,
                      ),
                      const SizedBox(height: 6),
                      Obx(() {
                        return SmallTextStyle(
                          color: const Color(0xff0e0e0e),
                          text: withdrawController
                              .earnedDollar, // দেখাবে: $570.84
                          fontSize: 18,
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            SetHeight(heightSet: 0.05),
            gradientButton(
              text: 'Reward',
              onPressed: () {
                Get.to(WithdrawAccount(), transition: Transition.rightToLeft);
              },
            ),
            // SetHeight(heightSet: 0.02),
            // gradientButton(
            //   text: 'Withdraw to Trading',
            //   onPressed: () {
            //     Get.to(Withdrawtotrading(),
            //         transition: Transition.rightToLeft);
            //   },
            // ),
            SetHeight(heightSet: 0.02),
            gradientButton(
              text: "Exchange",
              onPressed: () {
                Get.to(ExchangeCoinView(),
                    transition: Transition.rightToLeft);
              },
            ),
            SetHeight(heightSet: 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Withdrawal Instructions Anchor withdrawal instructions Background modification',
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ));
  }
}

Widget gradientButton({
  required String text,
  required VoidCallback onPressed,
  double borderRadius = 12,
}) {
  return SizedBox(
    width: kWeight * 0.8,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffade8f0),
              Color(0xffcdaafc),],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Color(0xffade8f0).withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
