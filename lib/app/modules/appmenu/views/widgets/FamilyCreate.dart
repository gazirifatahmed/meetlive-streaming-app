import 'dart:io';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../constants/layout_constant.dart';
import '../../../../../widgets/after/CastomText.dart';
import '../../../../../widgets/after/castom appbar.dart';
import '../../../registersteps/controllers/registersteps_controller.dart';
import '../../controllers/appmenu_controller.dart';
import 'Contrypicker.dart';
import 'JoinFamily.dart';

class Familycreate extends StatelessWidget {
  const Familycreate({super.key});

  @override
  Widget build(BuildContext context) {
    RegisterstepsController controller = Get.put(RegisterstepsController());
    AppmenuController controller1 = Get.put(AppmenuController());
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create family',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.04,
                vertical: Get.height * 0.001,
              ),
              margin: EdgeInsets.symmetric(
                horizontal: Get.width * 0.05,
                vertical: Get.height * 0.015,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                style: GoogleFonts.lato(
                  fontSize: Get.height * 0.02,
                  color: Colors.black87,
                ),
                onChanged: (val) => controller1.familyName.value = val,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: Get.height * 0.012,
                  ),
                  border: InputBorder.none,
                  hintText: 'Enter family name',
                  hintStyle: GoogleFonts.lato(
                    color: Colors.grey.shade500,
                    fontSize: Get.height * 0.018,
                  ),
                ),
              ),
            ),
            CountryPickerWidget(kHeight: kHeight),
            Castontext(
              text: '      Family avatar',
              fontSize: kHeight * 0.016,
              fontWeight: FontWeight.w600,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Obx(() {
                    return controller1.pickedImage1.isEmpty
                        ? Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: kWeight * 0.042,
                                vertical: kWeight * 0.02),
                            height: kHeight * 0.15,
                            width: kWeight * 0.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(left: 20, top: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(controller1.pickedImage1.value),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                  }),
                  CircleAvatar(
                    radius: kHeight * 0.016,
                    backgroundColor: Colors.black,
                    child: IconButton(
                      onPressed: () {
                        controller1.singleFilePicker1();
                      },
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: kHeight * 0.02,
            ),
            Castontext(
              text: '      Family announcement',
              fontSize: kHeight * 0.016,
              fontWeight: FontWeight.w600,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => controller1.announcement.value = val,
                maxLines: 6,
                style: GoogleFonts.lato(
                  fontSize: kHeight * 0.022,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                  hintText: 'Cannot exceed 500 text',
                  hintStyle: GoogleFonts.lato(
                    color: Colors.grey.shade500,
                    fontSize: kHeight * 0.018,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: kHeight * 0.02,
            ),
            Obx(() {
              final isEnabled = controller1.isFormValid;
              return Center(
                child: SizedBox(
                  width: kWeight * 0.7,
                  height: kHeight * 0.055,
                  child: ElevatedButton(
                    onPressed: isEnabled
                        ? () {
                            Get.to(Joinfamily(),
                                transition: Transition.rightToLeft);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kHeight * 0.08),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isEnabled
                              ? [
                                  Color(0xff8A4CF7),
                                  Color(0xffB460F0),
                                ]
                              : [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.3)
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(kHeight * 0.07),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Submit now',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: kHeight * 0.019,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
