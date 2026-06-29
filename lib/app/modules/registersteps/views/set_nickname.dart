import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../constants/constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/setheight.dart';
import '../controllers/registersteps_controller.dart';

class SetNickname extends GetView<RegisterstepsController> {
  const SetNickname({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 👈 Transparent background
      extendBodyBehindAppBar: true, // 👈 Body gradient appbar niche extend hobe
      appBar: CustomAppBar(
        title: 'Enter your current identity',
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffffffff),
              Color(0xffffffff),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SetHeight(heightSet: 0.15),

              // --- Profile Image Picker ---
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Obx(() {
                    return controller.profile_image.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              gradient: const LinearGradient(
                                colors: [Color(0xff2c0375), Color(0xff41026e)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.asset(
                                appLogo,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.file(
                              File(controller.profile_image.value),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                  }),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black,
                    child: IconButton(
                      onPressed: () => controller.singleFilePicker(),
                      icon: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),

              SetHeight(heightSet: 0.025),

              // --- Country Picker ---
              Obx(
                () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
                  child: GestureDetector(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        exclude: <String>['KN', 'MF'],
                        favorite: <String>['SE'],
                        showPhoneCode: true,
                        onSelect: (Country country) {
                          controller.selected_language.value = country.name;
                        },
                        countryListTheme: CountryListThemeData(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40.0),
                            topRight: Radius.circular(40.0),
                          ),
                          inputDecoration: InputDecoration(
                            hintText: ' Search Your Country',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color(0xFF7F7F80),
                              ),
                            ),
                          ),
                          searchTextStyle: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          EdgeInsets.symmetric(horizontal: Get.width * 0.048),
                      height: Get.height * 0.058,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        controller.selected_language.value.isEmpty
                            ? "Select Country"
                            : controller.selected_language.value,
                        style: GoogleFonts.roboto(fontSize: Get.height * 0.017),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: kHeight * 0.01),

              // --- Nickname ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
                child: TextField(
                  controller: controller.nickNameController,
                  decoration: _inputDecoration('Enter Nickname'),
                ),
              ),
              SizedBox(height: kHeight * 0.01),

              // --- Phone ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
                child: TextField(
                  controller: controller.phoneNumberController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Enter Phone Number'),
                ),
              ),
              SizedBox(height: kHeight * 0.01),

              // --- Email ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
                child: TextField(
                  controller: controller.emailController,
                  decoration: _inputDecoration('Enter Email'),
                ),
              ),
              SizedBox(height: kHeight * 0.01),

              // --- Password ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
                child: TextField(
                  controller: controller.passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Enter Password'),
                ),
              ),

              const SizedBox(height: 40),

              // --- Submit Button ---
              Obx(() {
                return StylishButton(
                  fontSize: kHeight * 0.017,
                  height: 50,
                  width: Get.width * 0.7,
                  gradientColors: [
                    Color(0xfffdcdfb),
                    Color(0xff15bccd),
                  ],
                  buttonText: registerstepsController.isLoading.value
                      ? "Loading..."
                      : "Sign Up",
                  onPressed: () {
                    controller.tryToSignUp();
                  },
                  borderColor: Colors.white,
                  textColor: Colors.white,
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    contentPadding:
        EdgeInsets.symmetric(vertical: 8, horizontal: Get.width * 0.045),
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    hintStyle: GoogleFonts.roboto(fontSize: Get.height * 0.017),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xff9f9c9c), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xff9a4ef8), width: 1.5),
    ),
  );
}
