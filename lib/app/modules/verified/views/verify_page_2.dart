import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/verified/views/verify_page_3.dart';


import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../controllers/verified_controller.dart';

class VerifyPage2 extends StatelessWidget {
  const VerifyPage2({super.key});

  @override
  Widget build(BuildContext context) {
    VerifiedController controller = Get.put(VerifiedController());
    final agencydata = Get.arguments;
    print('back agency data $agencydata');
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // 👈 Transparent
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(15), // 👈 Rounded corners
            ),
            gradient: LinearGradient(
              colors: [
                const Color(0xff8A4CF7),
                const Color(0xffB460F0).withValues(alpha: .7),
                const Color(0xff8A4CF7),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Host Verify',
          style: GoogleFonts.lato(
            fontSize: kHeight * 0.022,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Get.to(VerifyPage3(), transition: Transition.rightToLeft);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    agencydata?['name'] == null
                        ? Text(
                            'Agency',
                            style: GoogleFonts.lato(
                                fontSize: 16, color: Colors.black),
                          )
                        : Text(
                            '${agencydata['name']}',
                            style: GoogleFonts.lato(
                                fontSize: 16, color: Colors.black),
                          ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 17,
                    )
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Divider(
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.01,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller.whatsappNumber,
                  keyboardType: TextInputType.phone,

                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: kHeight * 0.01, vertical: 16),
                    hintText: 'Enter WhatsApp number',
                    prefixIcon:
                        Icon(Icons.phone_rounded, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Castontext(
                fontSize: kHeight * 0.016,
                text: 'Host type',
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.012,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.13,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _chatBox(context, 'Chat', controller),
                          _chatBox(context, 'Stream', controller),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _chatBox(context, 'Sing', controller),
                          _chatBox(context, 'Dance', controller),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _chatBox(context, 'Beauty', controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Castontext(
                  fontSize: kHeight * 0.017,
                  fontWeight: FontWeight.w500,
                  text: 'Description'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.012,
              ),
              Castontext(
                  fontSize: kHeight * 0.01,
                  fontWeight: FontWeight.w500,
                  textColor: Colors.black,
                  text:
                      '* Please be sure to fill in the real contact information so that you can be contacted easily,'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Castontext(
                  fontSize: kHeight * 0.01,
                  fontWeight: FontWeight.w500,
                  textColor: Colors.black,
                  text:
                      '* After submitting the certification, the agency will automatically withdraw if it is not processed within 2 days;'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Castontext(
                  fontSize: kHeight * 0.01,
                  fontWeight: FontWeight.w500,
                  textColor: Colors.black,
                  text:
                      '* After submitting the personal certification, the authentication cannot be repeated until there is no result (personal anchor, guild anchor);'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Castontext(
                  fontSize: kHeight * 0.01,
                  fontWeight: FontWeight.w500,
                  textColor: Colors.black,
                  text:
                      '* After successfully certifying the host, you will get the permission to start living:'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Castontext(
                  fontSize: kHeight * 0.01,
                  fontWeight: FontWeight.w500,
                  textColor: Colors.black,
                  text:
                      '* After successfully certifying the host, All withdraw will be issued from the agency Please keep contact with the agency.'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Castontext(
                  fontSize: kHeight * 0.01,
                  fontWeight: FontWeight.w500,
                  textColor: Colors.black,
                  text:
                      '* Change from official anchor certification to agency host certification, After passing the certification, it will be postponed to the next week to complete the change (change at 24 o clock on Sunday)'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              Obx(() => Center(
                    child: SizedBox(
                      width: kWeight * 0.7,
                      height: kHeight * 0.055,
                      child: ElevatedButton(
                        onPressed: () {
                          String number = controller.whatsappNumber.text.trim();


                            controller.hostVerifyPost(
                                agencyId: agencydata?['agency_id']);

                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kHeight * 0.1),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: controller.isValid.value
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
                            borderRadius: BorderRadius.circular(kHeight * 0.1),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Submit now',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: kHeight * 0.017,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}

Widget _chatBox(
    BuildContext context, String text, VerifiedController controller) {
  return Obx(() {
    final isSelected = controller.selectedHostType.value == text;
    return InkWell(
      onTap: () => controller.selectHostType(text),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.01,
          horizontal: MediaQuery.of(context).size.width * 0.08,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Castontext(
          fontSize: kHeight * 0.015,
          text: text,
          textColor: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  });
}
