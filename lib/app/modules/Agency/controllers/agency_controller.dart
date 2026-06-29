import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../apis/api_endpoints.dart';

class AgencyController extends GetxController {
  final dio = Dio();

  final nickNameController = TextEditingController();
  final idController = ''.obs;
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final blanceController = ''.obs;
  final coinController = ''.obs;
  final giftCoinController = ''.obs;
  final addressController = TextEditingController();
  final profile_imageController = ''.obs;
  final coverImageController = ''.obs;
  final agencyData = {}.obs;

  void createAgency() async {
    final data = {
      'hello': phoneNumberController.text,
      'name': nickNameController.text,
      'owner_id': idController.value,
      'email': emailController.text,
      'phone': phoneNumberController.text,
      'blance': blanceController.value,
      'coins': coinController.value,
      'gifts_coins': giftCoinController.value,
      'country': addressController.text,
      'profile_image': profile_imageController.value,
      'cover_images': coverImageController.value,
    };

    try {
      final response = await dio.post(kAgencyUrl, data: data);

      if (response.statusCode == 201) {
        agencyData.value = response.data;

        Get.snackbar(
          'Success',
          "You are Logged In now.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Failed',
          "Your credentials doesn't match.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {}
  }

  // single pick file

  final pickedImage = ''.obs; // Store file path as String

  Future<void> singleFilePicker() async {
    //file  ta k sudhu show korar jonno
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    pickedImage.value = result!.files.single.path!; // Store paths
  }
}
