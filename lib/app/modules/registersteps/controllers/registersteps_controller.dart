import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../models/user_profile.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/welcome_view.dart';
import '../../bottomnav/views/bottomnav_view.dart';
import '../../messanger/views/messages/components/firestore_service.dart';

class RegisterstepsController extends GetxController {
  final isLoading = false.obs;

  AuthController authController = Get.find();
  final dio = Dio();

  // Text Controllers
  var selectedGender = ''.obs;

  final dataOfBirth = ''.obs;
  final nickNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final profile_image = ''.obs;
  final selected_language = ''.obs;
  void selectGender(String gender) {
    selectedGender.value = gender;
  }

  bool isGenderSelected(String gender) {
    return selectedGender.value == gender;
  }

  Future<void> tryToSignUp() async {
    // basic validation
    if (nickNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill all fields",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return; // stop signup
    }

    final data = {
      'name': nickNameController.text,
      'email': emailController.text,
      'phone': phoneNumberController.text,
      'address': '',
      'password': passwordController.text,
      'gender': selectedGender.value,
      'dateofbirth': dataOfBirth.value,
      'country': selected_language.value,
      'profile_image': '',
    };

    try {
      isLoading.value = true;

      final response = await dio.post(kRegisterUrl, data: data);

      if (response.statusCode == 201) {
        authController.userProfile.value = UserProfile.fromJson(response.data);
        authController.preferences
            .setString('profile', jsonEncode(response.data));

        Get.offAll(() => BottomnavView(), transition: Transition.rightToLeft);

        // Fluttertoast.showToast(
        //   msg: "Register Success",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.green,
        //   textColor: Colors.white,
        //   fontSize: 14.0,
        // );
      } else {
        Fluttertoast.showToast(
          msg: "Your credentials don't match",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Something went wrong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } finally {
      isLoading.value = false;
    }
  }

//----------------------------------login ---------------

  final loginPhone = TextEditingController();
  final loginPassword = TextEditingController();

  var loginPhoneText = ''.obs;
  var loginPasswordText = ''.obs;

  var loginPhoneError = RxnString();
  var loginPasswordError = RxnString();

  void onPhoneChanged(String value) {
    loginPhoneText.value = value;
    loginPhoneError.value = null;
  }

  void onPasswordChanged(String value) {
    loginPasswordText.value = value;
    loginPasswordError.value = null;
  }

  void tryToSignIn() async {
    isLoading.value = true;

    String phone = loginPhone.text.trim();
    String password = loginPassword.text.trim();

    print("Entered Phone: $phone");
    print("Entered Password: $password");

    loginPhoneError.value = null;
    loginPasswordError.value = null;

    if (phone.isEmpty) {
      loginPhoneError.value = "Please enter phone number";
      isLoading.value = false;
      return;
    }

    if (password.isEmpty) {
      loginPasswordError.value = "Please enter password";
      isLoading.value = false;
      return;
    }

    try {
      final data = {
        'phone': phone,
        'password': password,
      };

      final response = await dio.post(kLoginUrl, data: data);
      print("Login API called: $data");

      if (response.statusCode == 200) {
        final responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        final profile = UserProfile.fromJson(responseData);

        authController.userProfile.value = profile;
        authController.userProfile.refresh();

        print('RAW asset_histories => ${responseData['asset_histories']}');
        print('MODEL assetHistories => ${authController.userProfile.value.assetHistories}');
        print('MODEL asset path => ${authController.userProfile.value.assetHistories?.asset?.asset}');
        print('MODEL entryHistories => ${authController.userProfile.value.entryHistories}');

        authController.preferences.setString(
          'profile',
          jsonEncode(responseData),
        );

        createDeviceToken();

        Get.offAll(BottomnavView(), transition: Transition.rightToLeft);
      } else {
        Fluttertoast.showToast(
          msg: "Invalid credentials",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print("Login Error => $e");

      Fluttertoast.showToast(
        msg: "Something went wrong",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // single pick file

  final pickedImage = ''.obs; // single image file pick

  Future<void> singleFilePicker() async {
    //file  ta k sudhu show korar jonno
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    pickedImage.value = result!.files.single.path!; // Store paths
  }

// update or create device token
  void createDeviceToken() async {
    final deviceToken = await FirebaseMessaging.instance.getToken();
    try {
      final response = await dio.get(getAndUpdateDeviceToken(
        userId: authController.userProfile.value.user!.id!.toInt(),
        deviceToken: deviceToken!,
      ));

      if (response.statusCode == 200) {
        print('Device token created');
      } else {
        print('Device token creation failed');
      }
    } catch (e) {
      print(e);
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Optional: You can add your web client ID here for Firebase auth integration
    // clientId: 'your-client-id.apps.googleusercontent.com',
  );

  Future<void> googleSign() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? result = await _googleSignIn.signIn();

      if (result == null) {
        return;
      }

      print(result);

      final data = {
        'name': result.displayName,
        'email': result.email,
        'profile_image': result.photoUrl,
      };

      final response = await dio.post(
        kLoginGoogle, // Endpoint for Google login
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        authController.userProfile.value = UserProfile.fromJson(response.data);
        print(
            'google level image ${authController.userProfile.value.user?.levelImage}');
        authController.preferences
            .setString('profile', jsonEncode(response.data));
        createDeviceToken();
        Get.put(FirestoreService());
        // homeController.showActiveFrame();
        Get.offAll(
              () => const BottomnavView(),
          transition: Transition.rightToLeft,
        );
      } else {
        Get.snackbar(
          'Failed',
          "Google login failed.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      print('Error during Google Sign-In: $error');
      Get.snackbar(
        'Failed',
        "Something went wrong during Google login.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void tryToSignOut() async {
    authController.preferences.clear();
    authController.userProfile.value = UserProfile();
    Get.offAll(WelcomeView(), transition: Transition.leftToRightWithFade);
  }

  Future<void> refreshAuthUserData() async {
    try {
      final response = await dio.get(
        kAuthUser,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final currentProfile = authController.userProfile.value;
        final userJson = response.data['user'];

        final updatedUser = User.fromJson(userJson);

        final assetHistories = userJson['asset_histories'] != null
            ? AssetHistories.fromJson(userJson['asset_histories'])
            : null;

        final entryHistories = userJson['entry_histories'] != null
            ? EntryHistories.fromJson(userJson['entry_histories'])
            : null;

        final vipHistories = userJson['vip_histories'] != null
            ? VipHistories.fromJson(userJson['vip_histories'])
            : null;

        authController.userProfile.value = UserProfile(
          success: currentProfile.success,
          message: currentProfile.message,
          token: currentProfile.token,
          user: updatedUser,
          totalFollowers: userJson['total_followers'],
          totalFollowing: userJson['total_following'],
          assetHistories: assetHistories,
          entryHistories: entryHistories,
          vipHistories: vipHistories,
        );

        authController.userProfile.refresh();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'profile',
          jsonEncode(authController.userProfile.value.toJson()),
        );

        print('User data refreshed successfully');
        print('Refresh Asset Frame => ${authController.userProfile.value.assetHistories?.asset?.asset}');
        print('Refresh Entry => ${authController.userProfile.value.entryHistories?.asset?.asset}');
      } else {
        print('Failed to refresh user data: ${response.data}');
      }
    } catch (e) {
      print('Error refreshing auth user data: $e');
    }
  }
}
