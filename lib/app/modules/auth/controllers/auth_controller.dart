import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/name_constants.dart';
import '../../../../models/user_profile.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;

  final registerName = TextEditingController();
  final registerEmail = TextEditingController();
  final registerPhone = TextEditingController();
  final registerAddress = TextEditingController();
  final registerPassword = TextEditingController();
  final registerProfile_Image = TextEditingController();

  final _dio = Dio();
  void tryRegister() async {
    final data = {
      'name': registerName.text,
      'email': registerEmail.text,
      'phone': registerPhone.text,
      'address': registerAddress,
      'password': registerPassword,
      'profile_image': registerProfile_Image,
    };

    try {
      final response = await _dio.post(kRegisterUrl, data: data);

      if (response.statusCode == 200) {
        // Get.snackbar(
        //   'Success',
        //   "You are Logged In now.",
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.BOTTOM,
        // );
      } else {
        Get.snackbar(
          'Failed',
          "Your credentials doesn't match.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Failed',
        "Something went wrong",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  //alamin api work end

  final userProfile = UserProfile().obs;
  late StreamingSharedPreferences preferences;
  void initialize() async {
    preferences = await StreamingSharedPreferences.instance;

    preferences.getString('profile', defaultValue: '').listen((value) {
      if (value.isNotEmpty) {
        userProfile.value = UserProfile.fromJson(jsonDecode(value));
        registerstepsController.refreshAuthUserData();
      }
    });
  }

  void tryToFetchVersion() async {
    print('object $kAppVersionUpdate');
    try {
      final response = await _dio.get(
        kAppVersionUpdate,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        dynamic item;
        if (data is List && data.isNotEmpty) {
          item = data.firstWhere(
            (e) => (e['status']?.toString().toLowerCase() ?? '') == 'active',
            orElse: () => data.last,
          );
          print('aapk downLoad data  $item');
        } else if (data is Map) {
          item = data;
        }
        if (item != null) {
          final serverVer = item['download_url']?.toString() ?? '';

          final builtUrl = serverVer;

          serverVersion.value = item['apkVertions']['apk_vertion'];
          if (serverVer.isNotEmpty &&
              item['apkVertions']['apk_vertion'].trim() != kAppVersion.trim()) {
            forceUpdateUrl.value = builtUrl;
            needsForceUpdate.value = true;
          } else {
            needsForceUpdate.value = false;
          }
        }
      } else {

      }
    } catch (e) {}
  }

  @override
  void onInit() {
    super.onInit();
    tryToFetchVersion();
    initialize();
  }

  final needsForceUpdate = false.obs;
  final forceUpdateUrl = ''.obs;
  final serverVersion = ''.obs;
}
