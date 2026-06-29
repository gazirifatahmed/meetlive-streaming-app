import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';



import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/setheight.dart';
import '../ExchangeCoin.dart';
import '../controllers/withdraw_controller.dart';
import 'CustomOutlinedButton.dart';

class ExchangeCoinView extends GetView<WithdrawController> {
  const ExchangeCoinView({super.key});
  @override
  Widget build(BuildContext context) {
    WithdrawController withdrawController = Get.put(WithdrawController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffade8f0),
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            )),
        centerTitle: true,
        title: Text(
          'Exchange Coin',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: kHeight * 0.17,
            padding:
                EdgeInsets.symmetric(vertical: 10, horizontal: kWeight * 0.05),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xffade8f0), // Light Blue
                      Color(0xffcdaafc),
                ])),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: kHeight * 0.03,
                ),
                Text(
                  'Account Balance',
                  style: GoogleFonts.lato(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: kHeight * 0.01,
                ),
                Row(
                  children: [
                    Text(
                      '${authController.userProfile.value.user!.earnedCoins}',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '  Receive',
                      style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: kWeight * 0.98,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(17.0),
                  child: Text(
                    'Exchange Coins',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff7C45BC),
                        fontSize: 17,
                        letterSpacing: -1.2),
                  ),
                ),
                SetHeight(heightSet: 0.03),
                Center(
                  child: CustomOutlinedButton(
                      text: 'Custom Exchange Amount',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.zero,
                              content: Column(
                                mainAxisSize: MainAxisSize.min, // 👈 important!
                                children: [
                                  Container(
                                    height: kHeight * 0.1, // 👈 set height
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xffade8f0),
                                            Color(0xffcdaafc),
                                          ]),
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Exchanges Coin',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Account Balance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  ExchangeTextField(
                                    controller:
                                        withdrawController.exchangeAmount,
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            side: BorderSide(
                                                color: Color(0xff7C45BC)),
                                          ),
                                        ),
                                        onPressed: () {
                                          withdrawController.exchangeCoin();
                                        },
                                        child: Text('Exchange'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            side: BorderSide(
                                                color: Color(0xff7C45BC)),
                                          ),
                                        ),
                                        onPressed: () {
                                          Get.back();
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                )
              ],
            ),
          ),
          SetHeight(heightSet: 0.01),
        ],
      ),
    );
  }
}
