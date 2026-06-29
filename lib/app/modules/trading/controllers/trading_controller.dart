import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';

class TradingController extends GetxController {
  // TradingController er moddhe
  final persentanseData = {}.obs;
  final persentense = 0.0.obs;

  Future<void> coinTradingPersentense() async {
    try {
      print('🔄 API Call Started');
      print('📍 Endpoint: $coinPersentense');

      final response = await dio.get(
        coinPersentense,
      );

      print('✅ Response Status Code: ${response.statusCode}');
      print('📦 Full Response Data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data != null) {
          print('✅ Response data is not null');

          if (response.data.containsKey('coin_trad_persent')) {
            persentanseData.value = response.data;

            // String থেকে double এ convert করা
            var percentValue = response.data['coin_trad_persent'];
            print(
                '🔢 Raw Percent Value: $percentValue (Type: ${percentValue.runtimeType})');

            if (percentValue is String) {
              persentense.value = double.tryParse(percentValue) ?? 0.0;
            } else if (percentValue is int) {
              persentense.value = percentValue.toDouble();
            } else if (percentValue is double) {
              persentense.value = percentValue;
            } else {
              persentense.value = 0.0;
            }

            print('💰 Converted Percentage Value: ${persentense.value}');
            print('✅ Data loaded successfully');
          } else {
            print('❌ Key "coin_trad_persent" not found');
            print('🔑 Available keys: ${response.data.keys}');
          }
        } else {
          print('❌ Response data is null');
        }
      } else {
        print('❌ Bad Status Code: ${response.statusCode}');
        isLoading.value = false;
        Fluttertoast.showToast(
          msg: "Your credentials don't match.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error occurred: $e');
      print('📍 Stack Trace: $stackTrace');

      isLoading.value = false;
    }
  }

  RxString calculatedAmount = '0'.obs;

// Controller এ এই method রাখুন
  void calculatePercentage(String value) {
    if (value.isEmpty) {
      calculatedAmount.value = '';
      return;
    }

    try {
      double inputAmount = double.parse(value);

      // Check if percentage value is valid
      if (persentense.value <= 0 || persentense.value > 100) {
        print('⚠️ Invalid percentage: ${persentense.value}');
        calculatedAmount.value = '';
        return;
      }

      // User যে % পাবে সেটা হলো API থেকে আসা percentage
      double userPercentage = persentense.value; // যেমন 20

      // User এর amount calculate
      double userAmount = inputAmount * (userPercentage / 100);

      calculatedAmount.value = '💎 ${userAmount.toStringAsFixed(0)}';

      // Admin এর amount (optional - যদি দেখাতে চান)
      double adminPercentage = 100 - userPercentage; // 80
      double adminAmount = inputAmount * (adminPercentage / 100);

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📥 Input Amount: $inputAmount');
      print(
          '👤 User gets: $userPercentage% = ${userAmount.toStringAsFixed(0)}');
      print(
          '👨‍💼 Admin gets: $adminPercentage% = ${adminAmount.toStringAsFixed(0)}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      calculatedAmount.value = '';
      print('❌ Calculation error: $e');
    }
  }

  ///---------------------- button Activeted--------------
  final isButtonActive = false.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    searchController.addListener(() {
      chackFeild();
    });
    amount.addListener(() {
      chackFeild();
    });
    coinTradingPersentense();
    super.onInit();
  }

  void chackFeild() {
    if (searchController.text.isNotEmpty && amount.text.isNotEmpty) {
      isButtonActive.value = true;
    } else {
      isButtonActive.value = false;
    }
  }

  final isLoading = false.obs;
  final dio = Dio();
  final searchController = TextEditingController();
  final amount = TextEditingController();
  final coinTradingData = {}.obs;

  ///--------------------post create coin trading --------------------
  Future<void> coinTrading({required String userid}) async {
    try {
      isLoading.value = true;

      print(
          'trading amount ${kCoinTradingPost(userId: userid, amount: amount.text)}');
      print('token 1111 ${authController.userProfile.value.token}');

      final response = await dio.get(
        kCoinTradingPost(userId: userid, amount: amount.text),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        isLoading.value = false;
        coinTradingData.value = response.data;
        print(response.data);
        Fluttertoast.showToast(
          msg: "Coin Trading Success",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        amount.clear();
        Get.back();
      } else {
        isLoading.value = false;
        Fluttertoast.showToast(
          msg: "Your credentials don't match.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('error ddd $e');
      isLoading.value = false;
    }
  }

  ///------------------- tarading history ---------------

  final tradingListData = [].obs;

  Future showTradingList() async {
    final data = await dio.get(
      kCoinTradingGet,
      options: Options(
        headers: {
          'Authorization':
              'Bearer ${authController.userProfile.value.token}', // Correct Bearer Token usage
        },
      ),
    );
    tradingListData.value = data.data['trade_history'];
    print(tradingListData);
  }
}
