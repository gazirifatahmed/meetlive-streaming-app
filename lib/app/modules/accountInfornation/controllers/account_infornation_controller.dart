import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../bottomnav/views/bottomnav_view.dart';

class AccountInfornationController extends GetxController {
  final dio = Dio();
  final List<String> nationalIdentity = [
    'Nagad Payment',
    'Bkash Payment',
  ];

  RxList<int> selectedProfileIndices = <int>[].obs;
  void toggleProfileSelection(int index) {
    if (selectedProfileIndices.contains(index)) {
      selectedProfileIndices.remove(index);
    } else {
      selectedProfileIndices.add(index);
    }
  }

  ///---------------------------Earning income --------------------

  final coinTopUpListData = [].obs;
  final selectIndex = 0.obs;

  RxString selectId = ''.obs;

  Future showCoinTopUpList() async {
    try {
      print(kTopUpCoinList);
      final data = await dio.get(
        kTopUpCoinList,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      coinTopUpListData.value = data.data['data'] ?? [];
      print(coinTopUpListData);
    } catch (e) {
      print("Error in showFollowerList: $e");
      Get.snackbar("Error", e.toString());
    }
  }

  ///------------------------- topUp post Create ------------------------
  final isLoading = false.obs;
  final selectMethod = ''.obs;
  // store data ====
  final coinTopUpData = {}.obs;
  Future<void> coinTopUpPost() async {
    final data = {
      'coins_store_id': selectId.value,
      'tnx_method': selectMethod.value
    };
    try {
      isLoading.value = true;

      ///------------------print section -------------
      print(data);
      print(kTopUpCoinPost);
      print(authController.userProfile.value.token);
      final response = await dio.post(
        kExchangeCoinUrl,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        isLoading.value = false;
        coinTopUpData.value = response.data;
        Fluttertoast.showToast(
          msg: "Coin topUp success",
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
}
