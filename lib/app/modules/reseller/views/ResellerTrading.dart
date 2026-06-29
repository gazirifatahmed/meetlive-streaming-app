import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';


import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../controllers/reseller_controller.dart';

class Resellertrading extends StatefulWidget {
  const Resellertrading({super.key});

  @override
  State<Resellertrading> createState() => _ResellertradingState();
}

class _ResellertradingState extends State<Resellertrading> {
  ///--------------------------search Trader  Id -------------------
  Map<String, dynamic>? selectedUser;

  void searchUser(String uid) {
    print("Searching UID: $uid");
    print("Total Trader List : ${homeController.traderListData}");
    if (uid.isEmpty) {
      setState(() => selectedUser = null);
      return;
    }

    try {
      final user = homeController.traderListData.firstWhere(
        (u) => u['id'].toString() == uid,
      );

      setState(() {
        selectedUser = user;
      });
    } catch (e) {
      setState(() => selectedUser = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResellerController resellerController = Get.put(ResellerController());
    double cardHeight = selectedUser != null ? 140 : 0;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: kHeight * 0.03,
          ),
          InkWell(
            onTap: () {
              homeController.showAllTraderData();
            },
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Castontext(
                    fontWeight: FontWeight.w600,
                    fontSize: kHeight * 0.016,
                    text: 'You Have',
                  ),
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.black)),
                    child: Image(
                      image: AssetImage('assets/audio_live/diamond.png'),
                      height: kHeight * 0.014,
                    ),
                  ),
                  SizedBox(width: 8),
                  Castontext(
                    textColor: Color(0xff8A4CF7),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    text: '${authController.userProfile.value.user!.balance}',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: kHeight * 0.02,
          ),
          Container(
            width: kWeight * 0.8,
            padding: EdgeInsets.symmetric(horizontal: kHeight * 0.016),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: resellerController.tradingIdController,
              onChanged: (value) {
                searchUser(value.trim());
              },
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey[600]),
                hintText: 'Enter trading id number',
                hintStyle: GoogleFonts.lato(fontSize: kHeight * 0.016),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(
            height: kHeight * 0.007,
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: cardHeight,
            width: kWeight * 0.8,
            child: selectedUser != null
                ? selectedUser == null
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[300],
                          ),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 10),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 150,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 100,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[100],
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 10),
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CachedNetworkImage(
                              imageUrl: ImageHelper.getImageUrl(
                                  "${selectedUser!['sender']['profile_image']}"),
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTD8qrkPg5tffSPQIqlxXcW-czht693ZlfJnHGej1zZUVvStsw638N4108&s',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Castontext(
                                  fontSize: Get.height * 0.016,
                                  fontWeight: FontWeight.w600,
                                  textColor: Colors.black.withValues(alpha: .6),
                                  text: 'ID: ${selectedUser!['id']}',
                                ),
                                const SizedBox(height: 8),
                                Castontext(
                                  fontSize: Get.height * 0.015,
                                  fontWeight: FontWeight.w400,
                                  textColor: Colors.black.withValues(alpha: .6),
                                  text:
                                      'Name: ${selectedUser!['sender']['name'] ?? 'N/A'}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Level: ${selectedUser!['sender']['level'] ?? 'N/A'}",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                : SizedBox(),
          ),
          SizedBox(
            height: kHeight * 0.007,
          ),
          Center(
            child: Container(
              width: kWeight * 0.8,
              padding: EdgeInsets.symmetric(horizontal: kHeight * 0.016),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: resellerController.tradingAmount,
                decoration: InputDecoration(
                  icon: Icon(Icons.currency_bitcoin, color: Colors.grey[600]),
                  hintText: 'Enter Coin amount',
                  hintStyle: GoogleFonts.lato(fontSize: kHeight * 0.016),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: kHeight * 0.02,
          ),
          SizedBox(
            width: kWeight * 0.7,
            height: kHeight * 0.055,
            child: Obx(() {
              return ElevatedButton(
                onPressed: () {
                  if (resellerController.isTradeButton.value) {
                    resellerController.resellerTradingBalanceTransfer();
                  } else {
                    Fluttertoast.showToast(
                      msg: "Please fill User ID and Amount ❌",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 13.0,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kHeight * 0.2),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: resellerController.isTradeButton.value
                        ? LinearGradient(
                            colors: [
                              Color(0xff8A4CF7),
                              Color(0xffB460F0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.withValues(alpha: .8),
                              Colors.grey.withValues(alpha: .8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.circular(kHeight * 0.1),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    // padding: EdgeInsets.symmetric(
                    //     vertical: kHeight * 0.01, horizontal: 24),
                    child: Text(
                      'Submit',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: kHeight * 0.019,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}
