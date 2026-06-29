import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:shimmer/shimmer.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../constants/spinkit.dart';
import '../controllers/store_controller.dart';
import 'backPackGiftsent.dart';

class Backpackstore extends GetView<StoreController> {
  const Backpackstore({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StoreController());
    controller.showBackPackList();
    return Scaffold(
      backgroundColor: Color(0xffF4F5F9),
      body: Obx(() {
        return LoadingOverlay(
          isLoading: controller.isLoading.value,
          progressIndicator: kLoadingIndicator(),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder(
                  future: controller.showBackPackList(),
                  builder: (context, snapshot) {
                    // ------------------ Loading State ------------------
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: 6, // shimmer placeholder items
                        itemBuilder: (context, index) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    // ------------------ Error State ------------------
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Failed to load backpack list ❌",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    // ------------------ Data Loaded ------------------
                    return GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 items per row
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: controller.backpackList.length,
                      itemBuilder: (context, index) {
                        final item = controller.backpackList[index];

                        return Column(
                          children: [
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),

                                  // Main Image
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            const Color(0xffade8f0),
                                            const Color(0xffcdaafc),
                                          ]),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: item['asset']['asset']
                                            .toString()
                                            .endsWith('.svga')
                                        ? SizedBox(
                                            height: kHeight * 0.08,
                                            width: kHeight * 0.08,
                                            child: SVGAEasyPlayer(
                                              resUrl:
                                                  "$kDomainUrl/${item['asset']['asset']}",
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl:
                                                '$kDomainUrl/${item['asset']['asset']}',
                                            height: kHeight * 0.08,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  // Action buttons (your existing code)
                                  Positioned(
                                    bottom: 13,
                                    right: 5,
                                    child: Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xff2fb599),
                                            padding: EdgeInsets.symmetric(
                                              vertical: kHeight * 0.01,
                                              horizontal: kWeight * 0.05,
                                            ),
                                            minimumSize: const Size(0, 28),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            textStyle: TextStyle(
                                                fontSize: kHeight * 0.01),
                                          ),
                                          onPressed: () {
                                            controller.backPackAssetId.value =
                                                controller.backpackList[index]
                                                        ['asset']['id']
                                                    .toString();
                                            Get.bottomSheet(
                                              Container(
                                                height: kHeight * 0.4,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: kHeight * 0.02,
                                                  horizontal: kWeight * 0.04,
                                                ),
                                                width: double.infinity,
                                                decoration: const BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(20),
                                                    topRight:
                                                        Radius.circular(20),
                                                  ),
                                                  color: Colors.white,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // 🟢 Image with Shimmer
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10,
                                                          horizontal: 10),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                            begin: Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                            colors: [
                                                              const Color(0xffade8f0),
                                                              const Color(0xffcdaafc),
                                                            ]),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      child: item['asset']
                                                                  ['asset']
                                                              .toString()
                                                              .endsWith('.svga')
                                                          ? SizedBox(
                                                              height: kHeight *
                                                                  0.08,
                                                              width: kHeight *
                                                                  0.08,
                                                              child:
                                                                  SVGAEasyPlayer(
                                                                resUrl:
                                                                    "$kDomainUrl/${item['asset']['asset']}",
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            )
                                                          : CachedNetworkImage(
                                                              imageUrl:
                                                                  '$kDomainUrl/${item['asset']['asset']}',
                                                              height: kHeight *
                                                                  0.08,
                                                              fit: BoxFit.cover,
                                                            ),
                                                    ),
                                                    const Divider(
                                                        color: Colors.black),

                                                    Text(
                                                      'Amount : ${controller.backpackList[index]['asset']['price']} ',
                                                      style: GoogleFonts.lato(
                                                        fontSize:
                                                            kHeight * 0.013,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        height:
                                                            kHeight * 0.015),

                                                    Text(
                                                      'Select gift object',
                                                      style: GoogleFonts.lato(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        height:
                                                            kHeight * 0.015),

                                                    // 🟢 Send button (unchanged)
                                                    GestureDetector(
                                                      onTap: () {
                                                        Get.to(
                                                            Backpackgiftsent(),
                                                            transition: Transition
                                                                .rightToLeft);
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 7,
                                                          horizontal: 10,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                                  0xff793be6)
                                                              .withValues(alpha: 0.6),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(3),
                                                          border: Border.all(
                                                            color: const Color(
                                                                    0xff793be6)
                                                                .withValues(
                                                                    alpha: 0.6),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Send',
                                                              style: GoogleFonts
                                                                  .lato(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Choose',
                                                              style: GoogleFonts
                                                                  .lato(
                                                                color: const Color(
                                                                    0xff1d5bf4),
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    SizedBox(
                                                        height:
                                                            kHeight * 0.012),

                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Image.asset(
                                                              'assets/images/coin.png',
                                                              width: 20,
                                                              height: 20,
                                                            ),
                                                            Text(
                                                              ' ${authController.userProfile.value.user!.coins}',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color: const Color(
                                                                    0xff793be6),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 20,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 2,
                                                                    horizontal:
                                                                        15),
                                                            minimumSize:
                                                                const Size(
                                                                    0, 25),
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                            backgroundColor:
                                                                const Color(
                                                                    0xff793be6),
                                                          ),
                                                          onPressed: () {},
                                                          child: const Text(
                                                            'Send',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                        height: kHeight * 0.06),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Sending',
                                            style: GoogleFonts.lato(
                                              fontWeight: FontWeight.w600,
                                              fontSize: kHeight * 0.01,
                                              color: const Color(0xffffffff),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: kWeight * 0.02),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xff4700f5),
                                            padding: EdgeInsets.symmetric(
                                              vertical: kHeight * 0.01,
                                              horizontal: kWeight * 0.05,
                                            ),
                                            minimumSize: const Size(0, 28),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            textStyle: TextStyle(
                                                fontSize: kHeight * 0.01),
                                          ),
                                          onPressed: () {
                                            controller.backpackList[index]
                                                        ['status'] ==
                                                    'Active'
                                                ? controller
                                                    .deActiveBackPackPost(
                                                        backPackId: controller
                                                            .backpackList[index]
                                                                ['asset']['id']
                                                            .toString())
                                                : controller.activeBackPackPost(
                                                    backPackId: controller
                                                        .backpackList[index]
                                                            ['asset']['id']
                                                        .toString());
                                          },
                                          child: Obx(() {
                                            return Text(
                                              controller.backpackList[index]
                                                          ['status'] ==
                                                      'Active'
                                                  ? 'Deactivate'
                                                  : 'Active',
                                              style: GoogleFonts.lato(
                                                fontWeight: FontWeight.w600,
                                                fontSize: kHeight * 0.01,
                                                color: const Color(0xffffffff),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}
