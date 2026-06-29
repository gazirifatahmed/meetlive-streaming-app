import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../bottomnav/views/bottomnav_view.dart';

class StoreController extends GetxController {
  final isColor = false.obs;
  final _dio = Dio();

  final isLoading = false.obs;

  final assetList = [].obs;
  Future getAssetList() async {
    isLoading.value = true;
    final data = await _dio.get(
      kAssetListUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        },
      ),
    );

    assetList.value = data.data['assets'];
    isLoading.value = false;
  }

  ///----------------------asset sending ----------------------

  void onTap() {
    print('Select Id ${selectId.value}');
  }

  final sendingData = {}.obs;
  final selectId = ''.obs;
  final selectReceverId = ''.obs;

  Future<void> sendingAsset({required String userId}) async {
    final data = {'asset_id': selectId.value, 'receiver_id': userId};
    try {
      isLoading.value = true;

      ///------------------print section -------------
      final response = await _dio.post(
        kAssetSending,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        isLoading.value = false;
        sendingData.value = response.data;

        Fluttertoast.showToast(
          msg: "sending Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Get.offAll(BottomnavView(), transition: Transition.rightToLeft);
      } else {
        isLoading.value = false;
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

  ///------------------------ freme purchase ----------------------
  final purchaseData = {}.obs;

  Future<void> purchaseAsset({required String purchaseId}) async {
    final data = {'asset_id': purchaseId};
    try {
      isLoading.value = true;

      ///------------------print section -------------
      print(data);
      print(kAssetPurchase);
      print(authController.userProfile.value.token);
      final response = await _dio.post(
        kAssetPurchase,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        isLoading.value = false;
        purchaseData.value = response.data;
        print(response.data);
        Fluttertoast.showToast(
          msg: "Purchase Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Get.offAll(BottomnavView(), transition: Transition.rightToLeft);
      } else {
        isLoading.value = false;
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

  ///------------------- show backpack list ------------------

  final backpackList = <dynamic>[].obs;

  Future showBackPackList() async {
    try {
      print(kBackPackList);
      print(authController.userProfile.value.token);
      final response = await _dio.get(
        kBackPackList,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      final data = response.data;

      // Debug print
      print("API Response: $data");

      if (data != null && data['asset_histories'] != null) {
        if (data['asset_histories'] is List) {
          // Already a List
          backpackList.value = data['asset_histories'];
          print('back pack list $backpackList');
        } else if (data['asset_histories'] is Map) {
          // Convert Map to List
          backpackList.value = (data['asset_histories'] as Map).values.toList();
        }
      } else {
        backpackList.clear();
      }

      print("Backpack list length: ${backpackList.length}");
    } catch (e, s) {
      print("Error fetching backpack list: $e");
      print(s);
    }
  }

  ///---------------backpack sending ---------------------

  final backPackSendData = {}.obs;
  final backPackAssetId = ''.obs;
  final backPackReceverId = ''.obs;

  Future<void> sendingAssetBackPack({required String userId}) async {
    final data = {'asset_id': backPackAssetId.value, 'receiver_id': userId};
    try {
      isLoading.value = true;

      ///------------------print section -------------
      print(data);
      print(kBackPackSending);
      print(authController.userProfile.value.token);
      final response = await _dio.post(
        kBackPackSending,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        isLoading.value = false;
        sendingData.value = response.data;
        print(response.data);
        Fluttertoast.showToast(
          msg: "sending Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Get.offAll(BottomnavView(), transition: Transition.rightToLeft);
      } else {
        isLoading.value = false;
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

  ///------------------------backpack active ----------------------

  final activeBackPackData = {}.obs;

  Future<void> activeBackPackPost({required String backPackId}) async {
    final data = {
      'asset_id': backPackId,
    };
    try {
      isLoading.value = true;

      ///------------------print section -------------
      print(data);
      print(kBackPackActive);
      print(authController.userProfile.value.token);
      final response = await _dio.post(
        kBackPackActive,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        isLoading.value = false;
        activeBackPackData.value = response.data;
        print(response.data);
        Fluttertoast.showToast(
          msg: " Actived Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        homeController.showActiveFrame();
      } else {
        isLoading.value = false;
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

  ///-----------back pack deactiveted--------------------

  final deActiveBackPackData = {}.obs;

  Future<void> deActiveBackPackPost({required String backPackId}) async {
    final data = {
      'asset_id': backPackId,
    };
    try {
      isLoading.value = true;

      ///------------------print section -------------
      print(' alamin data $data');
      print(kBackPackDeActive);
      print(authController.userProfile.value.token);
      final response = await _dio.post(
        kBackPackDeActive,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        isLoading.value = false;
        deActiveBackPackData.value = response.data;
        print(response.data);
        Fluttertoast.showToast(
          msg: "Deactivated Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        homeController.showActiveFrame();
      } else {
        isLoading.value = false;
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
}
