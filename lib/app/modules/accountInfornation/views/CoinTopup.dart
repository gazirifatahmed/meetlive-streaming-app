import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/accountInfornation/views/widget/CastomBtton.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../rechage/views/Reselar.dart';
import '../controllers/account_infornation_controller.dart';

class CoinTopUp extends StatefulWidget {
  const CoinTopUp({super.key});

  @override
  State<CoinTopUp> createState() => _CoinTopUpState();
}

bool isVerified = false;
bool _isChecked = false;

class _CoinTopUpState extends State<CoinTopUp> {
  @override
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    AccountInfornationController controller =
        Get.put(AccountInfornationController());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 140, // এখানে height control করো
        flexibleSpace: Container(

          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/new/Screenshot 2026-05-01 114109.png"), // তোমার image path
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Padding(
          padding:  EdgeInsets.only(top:kHeight*0.03,left: kWeight*0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/frame/diamonds.png',
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Coins',
                    style: TextStyle(
                      fontSize: kHeight * 0.02,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  '${authController.userProfile.value.user!.coins}',
                  style: TextStyle(
                    fontSize: kHeight * 0.02,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
        backgroundColor: Colors.transparent, // image দেখানোর জন্য transparent
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            SizedBox(
              height: Get.height * 0.006,
            ),
            Text(
              '   Please Select the payment amount',
              style: GoogleFonts.lato(
                  color: Colors.black, fontSize: kHeight * 0.016),
            ),
            SizedBox(
              height: Get.height * 0.015,
            ),

            Padding(
              padding: EdgeInsets.zero,
              child: FutureBuilder(
                future: controller.showCoinTopUpList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.65,
                      ),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.coinTopUpListData.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.65,
                    ),
                    itemBuilder: (context, index) {
                      final item = controller.coinTopUpListData[index];

                      return Obx(() {
                        final bool isSelected =
                            controller.selectId.value == item['id'].toString();

                        return GestureDetector(
                          onTap: () {
                            controller.selectId.value = item['id'].toString();
                            controller.selectId.refresh(); // instant refresh
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xffc65cff)
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.4 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/frame/diamonds.png',
                                            height: 14,
                                            width: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item['amount']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '\$${item['price']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (isSelected)
                                  Positioned(
                                    right: -1,
                                    bottom: -1,
                                    child: Container(
                                      width: 20,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Color(0xffd65cff),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  );
                },
              ),
            ),


            SizedBox(height: Get.height * 0.03),


            Text(
              '   Please Select the payment method',
              style: GoogleFonts.lato(
                  color: Colors.black, fontSize: kHeight * 0.015),
            ),

            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: kWeight * 0.015, vertical: 8),
              leading: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: kAppColor,
                    size: kHeight * 0.016,
                  ),
                ),
              ),
              title: Text(
                'Google Pay',
                style: GoogleFonts.lato(
                  fontSize: kHeight * 0.016,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: isVerified
                  ? const Icon(
                      Icons.verified,
                      color: Colors.green,
                    )
                  : null,
              // শুরুতে null
              onTap: () {
                setState(() {
                  isVerified = true; // click করলে true হবে
                });
              },
            ),

            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: kWeight * 0.015, vertical: 8),
              leading: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: kAppColor,
                    size: kHeight * 0.016,
                  ),
                ),
              ),
              title: Text(
                'Stripe',
                style: GoogleFonts.lato(
                  fontSize: kHeight * 0.016,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: isVerified
                  ? const Icon(
                      Icons.verified,
                      color: Colors.green,
                    )
                  : null,
              // শুরুতে null
              onTap: () {
                setState(() {
                  isVerified = true; // click করলে true হবে
                });
              },
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (value) {
                    setState(() {
                      _isChecked = value!;
                    });
                  },
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: kHeight * 0.014, color: Colors.black),
                    children: [
                      TextSpan(text: 'agree  '),
                      TextSpan(
                        text: 'User Recherge Disclaimer Agreement',
                        style: TextStyle(
                          fontSize: kHeight * 0.014,
                          fontWeight: FontWeight.w500,
                          color: Color(0xffa549ac),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Handle tap on "Login"
                          },
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),

            Center(
              child: CastomAppButton(
                onPressed: () {
                  showTopUpComingDialog(context);
                },
                buttonText: 'Pay immediately',
              ),
            ),
            // Center(
            //   child: CastomAppButton(
            //     onPressed: () {
            //       controller.coinTopUpPost();
            //     },
            //     buttonText: 'Pay immediately',
            //   ),
            // ),
            SizedBox(
              height: kHeight * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}
void showTopUpComingDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "TopUp",
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// 🔥 Icon
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xfff3e8ff),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wallet,
                    color: Color(0xffa259ff),
                    size: 28,
                  ),
                ),

                SizedBox(height: 16),

                /// ✅ Title
                Text(
                  "Coin Top-up",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6),

                /// ✅ Subtitle
                Text(
                  "This feature is coming soon.\nYou can recharge using reseller for now.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: 20),

                /// 🔥 Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      /// 👉 Navigate to reseller page
                      Get.to(Reselar(),transition: Transition.rightToLeft); // change route if needed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffa259ff),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Recharge Another Way",
                      style: TextStyle(fontSize: 14,color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },

    /// ✨ Smooth animation
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: Opacity(
          opacity: anim1.value,
          child: child,
        ),
      );
    },
  );
}