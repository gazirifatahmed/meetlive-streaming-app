import 'package:country_picker/country_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../bottomnav/views/bottomnav_view.dart';
import '../views/EditProfile.dart';

class MyprofileController extends GetxController {
  ///---------------------- show profile gift sender list -------------
  final dio = Dio();
  var selectedCountry = Rx<Country>(
    Country(
      countryCode: 'BD',
      phoneCode: '880',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'Bangladesh',
      example: '',
      displayName: 'Bangladesh',
      displayNameNoCountryCode: 'Bangladesh',
      e164Key: '',
    ),
  );

  final profileGiftList = [].obs;

  final isLoading = false.obs;

  Future showProfileGiftList() async {
    isLoading.value = true;
    try {
      final response = await dio.get(
        kProfileGiftList,
        options: Options(
          headers: {
            'Authorization':
                'Bearer ${authController.userProfile.value.token}', // Correct Bearer Token usage
          },
        ),
      );

      if (response.statusCode == 200) {
        profileGiftList.value = response.data['giftsr_data'];
        print('SEnder List Show $profileGiftList');
        isLoading.value = false;
      } else {
        isLoading.value = false;
        Get.snackbar(
          'Failed',
          "Your credentials doesn't match.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Fluttertoast.showToast(
        msg: "Something went wrong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  final profileGiftReceverList = [].obs;

  Future showProfileReciverList() async {
    isLoading.value = true;
    try {

      final response = await dio.get(
        kProfileReceverList,
        options: Options(
          headers: {
            'Authorization':
                'Bearer ${authController.userProfile.value.token}', // Correct Bearer Token usage
          },
        ),
      );

      if (response.statusCode == 200) {
        profileGiftReceverList.value = response.data['giftsr_data'];

        isLoading.value = false;
      } else {
        isLoading.value = false;
        Get.snackbar(
          'Failed',
          "Your credentials doesn't match.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Fluttertoast.showToast(
        msg: "Something went wrong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  ///------------------------  profile combination list ---------------------------
  final profileContributionList = [].obs;

  Future showProfileContributionList() async {
    isLoading.value = true;
    try {
      final response = await dio.get(
        kProfileCombinationList,
        options: Options(
          headers: {
            'Authorization':
                'Bearer ${authController.userProfile.value.token}', // Correct Bearer Token usage
          },
        ),
      );

      if (response.statusCode == 200) {
        profileContributionList.value = response.data['giftsr_data'];
        isLoading.value = false;
      } else {
        isLoading.value = false;
        Get.snackbar(
          'Failed',
          "Your credentials doesn't match.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Fluttertoast.showToast(
        msg: "Something went wrong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  ///---------------- profile update -----------------

  final profileUpdateData = {}.obs;
  final nameController = TextEditingController();
  var profileImage = ''.obs;

  Future<void> profileUpdate({required int id}) async {
    final data = {
      'name': nameController.text.trim(),
    };

    try {
      final response = await dio.post(
        kProfileUpdate(id: id),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        profileUpdateData.value = response.data;

        print('success data $profileUpdateData');
        Get.offAll(
          Editprofile(),
          transition: Transition.rightToLeft,
        );
        Fluttertoast.showToast(
          msg: "Profile updated successfully ✅",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Profile update failed ❌",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        Fluttertoast.showToast(
          msg: "Server error: ${e.response?.statusCode}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Network error: ${e.message}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unexpected error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // upadate profile image
  Future<void> profileImageUpdate({required int id}) async {
    FormData data = FormData.fromMap({
      'profile_image': await MultipartFile.fromFile(
        profileImage.value,
        filename: "upload.jpg",
      ),
    });

    try {
      final response = await dio.post(
        kProfileUpdate(id: id),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        profileUpdateData.value = response.data;
        Get.offAll(
          BottomnavView(),
          transition: Transition.rightToLeft,
        );
        Fluttertoast.showToast(
          msg: "Profile updated successfully ✅",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Profile update failed ❌",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        Fluttertoast.showToast(
          msg: "Server error: ${e.response?.statusCode}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Network error: ${e.message}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unexpected error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  //-------------- profile image update ----------
  final picProfileImage = ''.obs;

  Future<void> updateProfile() async {
    final ImagePicker picker = ImagePicker();

    // Show a bottom sheet with Camera & Gallery options
    await Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Get.back(); // Close the bottom sheet
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                );
                if (photo != null) {
                  picProfileImage.value = photo.path;
                  print("Camera image path: ${photo.path}");

                  // ✅ call update function
                  profileImageUpdate(
                    id: authController.userProfile.value.user!.id!.toInt(),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.white,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Get.back(); // Close the bottom sheet
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50,
                );
                if (photo != null) {
                  profileImage.value = photo.path;
                  print("Gallery image path: ${photo.path}");

                  // ✅ call update function
                  profileImageUpdate(
                    id: authController.userProfile.value.user!.id!.toInt(),
                  );
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xff8A4CF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  final picProfileImageCover = ''.obs;

  Future<void> updateProfileCover() async {
    final ImagePicker picker = ImagePicker();

    // Show a bottom sheet with Camera & Gallery options
    await Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Get.back(); // Close the bottom sheet
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                );
                if (photo != null) {
                  picProfileImageCover.value = photo.path;
                  print("Camera image path: ${photo.path}");

                  // ✅ call update function
                  profileImageCoverUpdate(
                    id: authController.userProfile.value.user!.id!.toInt(),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.white,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Get.back(); // Close the bottom sheet
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50,
                );
                if (photo != null) {
                  picProfileImageCover.value = photo.path;
                  print("Gallery image path: ${photo.path}");

                  // ✅ call update function
                  profileImageCoverUpdate(
                    id: authController.userProfile.value.user!.id!.toInt(),
                  );
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xff8A4CF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Future<void> profileImageCoverUpdate({required int id}) async {
    FormData data = FormData.fromMap({
      'cover_images': await MultipartFile.fromFile(
        picProfileImageCover.value,
        filename: "upload.jpg",
      ),
    });

    try {
      final response = await dio.post(
        kProfileUpdate(id: id),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        profileUpdateData.value = response.data;
        Get.offAll(
          BottomnavView(),
          transition: Transition.rightToLeft,
        );
        Fluttertoast.showToast(
          msg: "Profile updated successfully ✅",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Profile update failed ❌",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        Fluttertoast.showToast(
          msg: "Server error: ${e.response?.statusCode}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Network error: ${e.message}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unexpected error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
