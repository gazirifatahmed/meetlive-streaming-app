import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../bottomnav/views/bottomnav_view.dart';
import '../../verified/controllers/verified_controller.dart';

class InformationcollectionController extends GetxController {
  VerifiedController verifiedController = Get.put(VerifiedController());
  final dio = Dio();
  final agencyData = {}.obs;
  final agencyName = TextEditingController();
  final agencyId = TextEditingController(
      text: authController.userProfile.value.user!.userId.toString());
  final whatsappNumber = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();

  RxBool isFormFilled = false.obs;

  @override
  void onInit() {
    super.onInit();
    agencyName.addListener(validateForm);
    agencyId.addListener(validateForm);
    whatsappNumber.addListener(validateForm);

    address.addListener(validateForm);
  }

  void validateForm() {
    isFormFilled.value = agencyName.text.trim().isNotEmpty &&
        agencyId.text.trim().isNotEmpty &&
        whatsappNumber.text.trim().isNotEmpty &&
        address.text.trim().isNotEmpty &&
        submitNIDCard.value.isNotEmpty &&
        submitNidBackCard.value.isNotEmpty;
  }

  @override
  void dispose() {
    agencyName.dispose();
    agencyId.dispose();
    whatsappNumber.dispose();

    address.dispose();
    super.dispose();
  }

  Future<void> createAgency() async {
    try {
      FormData data = FormData.fromMap({
        'name': agencyName.text,
        'agency_id': agencyId.text,
        'email': email.text,
        'phone': whatsappNumber.text,
        'address': address.text,
        'nid_font': await MultipartFile.fromFile(
          submitNIDCard.value,
          filename: "upload.jpg",
        ),
        'nid_back': await MultipartFile.fromFile(
          submitNidBackCard.value,
          filename: "upload.jpg",
        ),
      });

      // Print all fields
      print('=== FormData Fields ===');
      for (var field in data.fields) {
        print('${field.key}: ${field.value}');
      }

      // Print all files
      print('=== FormData Files ===');
      for (var file in data.files) {
        print('${file.key}: ${file.value.filename}');
      }

      print(
          'Agency token: ${authController.userProfile.value.token}$kAgencyPostUrl');
      print('Agency token: $kAgencyPostUrl');

      final response = await dio.post(
        kAgencyPostUrl,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => status != null && status < 500,
          followRedirects: false,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        agencyData.value = response.data;
        print('=== Response Data ===');
        print(response.data);

        Fluttertoast.showToast(
          msg: "Agency create success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        await verifiedController.showNewAgenctList();
        Get.offAll(BottomnavView(), transition: Transition.rightToLeft);
      } else {
        print('=== Error Response ===');
        print(response.statusCode);
        print(response.data);

        Fluttertoast.showToast(
          msg: "Your credentials doesn't match.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e, stackTrace) {
      print('=== Exception ===');
      print(e);
      print('=== StackTrace ===');
      print(stackTrace);

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

  final submitNIDCard = ''.obs;

  Future<void> kycNidShow() async {
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
                  submitNIDCard.value = photo.path;
                  print("Camera image path: ${photo.path}");
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
                  submitNIDCard.value = photo.path;
                  print("Gallery image path: ${photo.path}");
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xff8A4CF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  final submitNidBackCard = ''.obs;

  Future<void> kycNidBackShow() async {
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
                  submitNidBackCard.value = photo.path;
                  print("Camera image path: ${photo.path}");
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
                  submitNidBackCard.value = photo.path;
                  print("Gallery image path: ${photo.path}");
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xff8A4CF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  ///-----------------------  Agency Request List
  final newAgencyRequestList = [].obs;

  Future<void> showRequestAgenctList({required int agencyId}) async {
    try {
      final response = await dio.get(
        kAgencyRequestListUrl(id: agencyId),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      print('Link 111 ${kAgencyRequestListUrl(id: agencyId)}');
      print(authController.userProfile.value.token);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.data['data']['hostRequests']);
        newAgencyRequestList.value = response.data['data']['hostRequests'];

        print('Agency under Host $newAgencyRequestList');
        Fluttertoast.showToast(
          msg: "show list  success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        // Get.offAll(VerifyPage4(), transition: Transition.rightToLeft);
      } else {
        Fluttertoast.showToast(
          msg: "Your credentials doesn't match.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print(e);

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

  ///----------- Ageency Host List
  final newAgencyhostList = [].obs;
  final newAgencyManthly = [].obs;

  Future<void> showAgencyHostList({required int agencyId}) async {
    try {
      print('link agency ${kAgencyHostListUrl(id: agencyId)}');
      print(authController.userProfile.value.token);
      final response = await dio.get(
        kAgencyHostListUrl(id: agencyId),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        newAgencyhostList.value = response.data['data']['daily_sorted_users'];
        newAgencyManthly.value = response.data['data']['monthly_sorted_users'];
        print('Success Data$newAgencyhostList');

        Fluttertoast.showToast(
          msg: "show list  success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        // Get.offAll(VerifyPage4(), transition: Transition.rightToLeft);
      } else {
        Fluttertoast.showToast(
          msg: "Your credentials doesn't match.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print(e);

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

  ///-------------- host Aceopt -------------
  final agencyAcept = {}.obs;

  void AceptCreate({required int hostId}) async {
    final data = {
      'host_id': hostId,
    };
    try {
      print(kAgencyAceptUrl);
      print(data);
      final response = await dio.post(
        kAgencyAceptUrl,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        agencyAcept.value = response.data;
        print('agency Id ${response.data['Host']['agency_id']}');

        await showRequestAgenctList(
            agencyId: int.parse(response.data['Host']['agency_id']));

        Fluttertoast.showToast(
          msg: "Accept Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 12.0,
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
    } catch (e) {
      print(e);
    }
  }

  ///---------- reject
  final agencyReject = {}.obs;
  void ARejectCreate({required int hostId}) async {
    final data = {
      'host_id': hostId,
    };
    try {
      print(kAgencyAceptUrl);
      print(data);
      final response = await dio.post(
        kAgencyRejectUrl,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        agencyReject.value = response.data;
        print('agency Id ${response.data['Host']['agency_id']}');
        await showRequestAgenctList(
            agencyId: int.parse(response.data['Host']['agency_id']));
        Fluttertoast.showToast(
          msg: "Reject Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 12.0,
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
    } catch (e) {
      print(e);
    }
  }
}
