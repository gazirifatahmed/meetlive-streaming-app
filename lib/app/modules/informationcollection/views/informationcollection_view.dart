import 'dart:io';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/after/CustomInfoTextField.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../../../../widgets/setheight.dart';
import '../../../../widgets/small_text_widgets.dart';
import '../controllers/informationcollection_controller.dart';

class InformationcollectionView
    extends GetView<InformationcollectionController> {
  const InformationcollectionView({super.key});
  @override
  Widget build(BuildContext context) {
    InformationcollectionController controller =
        Get.put(InformationcollectionController());
    return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          title: 'Agency information',
        ),
        body: Stack(
          children: [
            Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
              Color(0xffb5a7fe),
              Color(0xffffffff),
            ], begin: Alignment.topRight, end: Alignment.bottomRight))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: kHeight * 0.13,
                    ),
                    Castontext(
                        fontSize: kHeight * 0.012,
                        text: 'Please provide your real and valid ID card'),
                    SetHeight(heightSet: 0.01),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double itemWidth = Get.width > 600
                                ? Get.width * 0.45
                                : Get.width * 0.4;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  return Container(
                                    width: itemWidth,
                                    margin: const EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        InkWell(
                                          onTap: controller.kycNidShow,
                                          child: controller
                                                  .submitNIDCard.isEmpty
                                              ? Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: Image.asset(
                                                        'assets/logo/179573.png',
                                                        height: kHeight * 0.13,
                                                        width: itemWidth,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 5,
                                                      right: 10,
                                                      child: Container(
                                                        height: kHeight * 0.04,
                                                        width: kHeight * 0.04,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.orange,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.camera_alt,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Column(
                                                  children: [
                                                    SizedBox(
                                                      height: kHeight * 0.003,
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors.white,
                                                            width: 3),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        child: Image.file(
                                                          File(controller
                                                              .submitNIDCard
                                                              .value),
                                                          height:
                                                              Get.height * 0.15,
                                                          width: itemWidth,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: kHeight * 0.006,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                        SizedBox(
                                          height: kHeight * 0.004,
                                        ),
                                        Castontext(
                                          fontSize: kHeight * 0.01,
                                          text:
                                              '    [Upload Front Side Id Card Image]',
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                Obx(() {
                                  return SizedBox(
                                    width: itemWidth,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: kHeight * 0.013,
                                        ),
                                        InkWell(
                                          onTap: controller.kycNidBackShow,
                                          child: controller
                                                  .submitNidBackCard.isEmpty
                                              ? Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: Image.asset(
                                                        'assets/flaticons/id card packpart.jpg',
                                                        height: kHeight * 0.13,
                                                        width: itemWidth,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 5,
                                                      right: 10,
                                                      child: Container(
                                                        height: kHeight * 0.04,
                                                        width: kHeight * 0.04,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.orange,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.camera_alt,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.white,
                                                        width: 3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image.file(
                                                      File(controller
                                                          .submitNidBackCard
                                                          .value),
                                                      height: Get.height * 0.15,
                                                      width: itemWidth,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        SizedBox(
                                          height: kHeight * 0.01,
                                        ),
                                        Castontext(
                                          fontSize: kHeight * 0.01,
                                          text:
                                              '      [Upload Back Side Id Card Image]',
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: kHeight * 0.02,
                    ),
                    CustomInfoTextField(
                      controller: controller.agencyName,
                      text: '* Agency name',
                    ),
                    CustomInfoTextField(
                      controller: controller.agencyId,

                      text: '* Agency ID',
                      readOnly: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: TextFormField(
                        controller: controller.whatsappNumber,
                        cursorColor: Colors.black,
                        style: GoogleFonts.lato(
                            color: Colors.black,
                            fontSize: kHeight * 0.016,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintStyle: GoogleFonts.lato(
                              color: Colors.grey, fontWeight: FontWeight.w600),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: kHeight * 0.012,
                              vertical: kHeight * 0.014),
                          hintText: '* WhatsApp Number',
                          fillColor: Colors.white,
                          filled: true,
                          border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.1))),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.1))),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.1))),
                        ),
                      ),
                    ),
                    CustomInfoTextField(
                      controller: controller.email,
                      text: '*Enter  Email',
                    ),
                    CustomInfoTextField(
                      controller: controller.address,
                      text: '* Enter Address',
                    ),
                    SetHeight(heightSet: 0.02),
                    Obx(() => SizedBox(
                          width: kWeight * 0.7,
                          height: kHeight * 0.06,
                          child: ElevatedButton(
                            onPressed: () {
                              String number =
                                  controller.whatsappNumber.text.trim();
                              controller.createAgency();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: controller.isFormFilled.value
                                      ? [
                                          Color(0xff8A4CF7),
                                          Color(0xffB460F0),
                                        ]
                                      : [
                                          Colors.black.withValues(alpha: 0.4),
                                          Colors.black.withValues(alpha: 0.4)
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  'Submit',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: kHeight * 0.02,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )),
                    SetHeight(heightSet: 0.015),
                    SmallTextStyle(
                        color: Colors.black,
                        text:
                            'The above information will be reviewed manually,please ensure that',
                        fontSize: 10)
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
