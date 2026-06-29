import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../apis/api_endpoints.dart';
import '../../../../../constants/constants.dart';
import '../../appmenu/views/appmenu_view.dart';
import '../withdraw_account-add.dart';

class WithdrawController extends GetxController {
  final dio = Dio();

  final double dollarToTakaRate = 121.5; // ১ ডলার = ১২১.৫ টাকা

  // Tier-based coin to dollar conversion rates (12 tiers)
  double _calculateDollarFromCoins(int coins) {
    if (coins >= 50000000) {
      // 12️⃣ 50M+ coins: $3000 for 50M coins rate
      return (coins / 50000000) * 3000;
    } else if (coins >= 35000000) {
      // 11️⃣ 35M-49.9M coins: $2100 for 35M coins rate
      return (coins / 35000000) * 2100;
    } else if (coins >= 20000000) {
      // 🔟 20M-34.9M coins: $1200 for 20M coins rate
      return (coins / 20000000) * 1200;
    } else if (coins >= 15000000) {
      // 9️⃣ 15M-19.9M coins: $900 for 15M coins rate
      return (coins / 15000000) * 900;
    } else if (coins >= 10000000) {
      // 8️⃣ 10M-14.9M coins: $600 for 10M coins rate
      return (coins / 10000000) * 600;
    } else if (coins >= 8000000) {
      // 7️⃣ 8M-9.9M coins: $480 for 8M coins rate
      return (coins / 8000000) * 480;
    } else if (coins >= 6000000) {
      // 6️⃣ 6M-7.9M coins: $360 for 6M coins rate
      return (coins / 6000000) * 360;
    } else if (coins >= 4000000) {
      // 5️⃣ 4M-5.9M coins: $240 for 4M coins rate
      return (coins / 4000000) * 240;
    } else if (coins >= 2000000) {
      // 4️⃣ 2M-3.9M coins: $120 for 2M coins rate
      return (coins / 2000000) * 120;
    } else if (coins >= 1000000) {
      // 3️⃣ 1M-1.9M coins: $60 for 1M coins rate
      return (coins / 1000000) * 60;
    } else if (coins >= 500000) {
      // 2️⃣ 500K-999.9K coins: $30 for 500K coins rate
      return (coins / 500000) * 30;
    } else if (coins >= 200000) {
      // 1️⃣ 200K-499.9K coins: $10 for 200K coins rate
      return (coins / 200000) * 10;
    } else {
      // Less than 200K coins: proportional to 200K = $10 rate
      return (coins / 200000) * 10;
    }
  }

  String get earnedDollar {
    final coins = int.tryParse(
            authController.userProfile.value.user?.earnedCoins?.toString() ??
                '0') ??
        0;

    final dollar = _calculateDollarFromCoins(coins);
    return '\$${dollar.toStringAsFixed(2)}';
  }

  String get earnedTaka {
    final coins =
        (authController.userProfile.value.user?.earnedCoins ?? 0) as int;
    final dollar = _calculateDollarFromCoins(coins);
    final taka = dollar * dollarToTakaRate;
    return '৳${taka.toStringAsFixed(2)}';
  }

  ///---------------------- withdraw variables create----------------
  final number = TextEditingController();
  final selectMethode = ''.obs;
  final amount = TextEditingController();

  ///---------------------- withdraw to trading variables create----------------
  final tradeAmount = TextEditingController();

  ///---------------------- exchange Amount variables create----------------
  final exchangeAmount = TextEditingController();

  ///--------------------data store -------------
  final withdrawData = {}.obs;
  final withdrawToTradeData = {}.obs;
  final exchangeCoinData = {}.obs;
  //----------loading ----------
  final isLoading = false.obs;

  ///----------------------- validation  variables ------------
  RxBool isFormFilled = false.obs;
  RxBool isTradeFormFilled = false.obs;

  ///----------withdraw validateForm -----------
  void validateForm() {
    isFormFilled.value = number.text.trim().isNotEmpty &&
        selectMethode.value.trim().isNotEmpty &&
        amount.text.trim().isNotEmpty;
  }

  ///------------withdraw to trading validateTradeForm---------------
  void validateTradeForm() {
    isTradeFormFilled.value = tradeAmount.text.trim().isNotEmpty;
  }

  //---------- onInit call ----------
  @override
  void onInit() {
    super.onInit();
    tradeAmount.addListener(validateForm);
    number.addListener(validateForm);
    amount.addListener(validateForm);
    ever(selectMethode, (_) => validateForm());
    // Trade listeners
    tradeAmount.addListener(validateTradeForm); // Rx string listener
  }

  //---------- dispose call ----------
  @override
  void dispose() {
    number.dispose();
    amount.dispose();
    tradeAmount.dispose();
    super.dispose();
  }

  //--------------withdraw function create ---------------
  //--------------withdraw function create ---------------
  Future<void> withdrawPost() async {
    final data = {
      'method_account': number.text,
      'method_name': selectMethode.value,
    };

    try {
      isLoading.value = true;
      print(data);
      print(kWithdrawUrl);
      print(authController.userProfile.value.token);
      final response = await dio.post(
        kWithdrawUrl,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        isLoading.value = false;
        withdrawData.value = response.data;
        print(response.data);
        await getWithdrawList();
        Fluttertoast.showToast(
          msg: "withdraw Method success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        Get.offAll(WithdrawAccount(), transition: Transition.rightToLeft);
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

  ///---------------- Withdraw list ------------------
  final withDrawList = [].obs;

  Future<void> getWithdrawList() async {
    final data = await dio.get(
      kgetWithdrawList,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        },
      ),
    );
    if (data.statusCode == 200 || data.statusCode == 201) {
      withDrawList.value = data.data['data'];

      print('Withdraw data $withDrawList');
    }
  }

  ///---------------------- withdraw post create -------------
  final WithdrawData = {}.obs;

  Future<void> withdrawSubmit({required int methodId}) async {
    print('🔵 ========== WITHDRAW SUBMIT START ==========');

    // ✅ Check if amount field is empty
    if (amount.text.isEmpty) {
      print('❌ ERROR: Amount field is empty');
      Fluttertoast.showToast(
        msg: "Please enter amount",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // ✅ Parse and validate amount
    final parsedAmount = int.tryParse(amount.text.trim());
    print('🔍 Amount Text: "${amount.text}"');
    print('🔍 Parsed Amount: $parsedAmount');

    if (parsedAmount == null) {
      print('❌ ERROR: Amount is not a valid number');
      Fluttertoast.showToast(
        msg: "Invalid amount format",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // ✅ Check allowed amounts
    final allowedAmounts = [
      200000,
      500000,
      1000000,
      2000000,
      4000000,
      6000000,
      8000000,
      10000000,
      15000000,
      20000000,
      35000000,
      50000000
    ];

    if (!allowedAmounts.contains(parsedAmount)) {
      print('❌ ERROR: Amount $parsedAmount is not in allowed list');

      // ✅ Format amounts with commas for better readability
      String formatAmount(int amt) {
        return amt.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      }

      // ✅ Show beautiful bottom sheet with all allowed amounts
      Get.bottomSheet(
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff8A4CF7), Color(0xffB460F0)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invalid Amount',
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Please select from allowed amounts',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Amounts Grid
              Container(
                constraints: BoxConstraints(maxHeight: Get.height * 0.5),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: allowedAmounts.length,
                  itemBuilder: (context, index) {
                    final amt = allowedAmounts[index];
                    return GestureDetector(
                      onTap: () {
                        amount.text = amt.toString();
                        Get.back();
                        Get.snackbar(
                          'Amount Selected',
                          '৳${formatAmount(amt)} has been set',
                          backgroundColor: Colors.green.shade400,
                          colorText: Colors.white,
                          duration: Duration(seconds: 2),
                          snackPosition: SnackPosition.TOP,
                          margin: EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xff8A4CF7),
                              Color(0xffB460F0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff8A4CF7).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.diamond,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '৳${formatAmount(amt)}',
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
      );

      return;
    }

    final data = {
      'method_id': methodId,
      'amount': parsedAmount, // ✅ Send as integer, not string
    };

    print('📦 Request Data: $data');
    print('🌐 API Endpoint: $kpostWithdraw');
    print('🔑 Method ID: $methodId');
    print('💰 Amount: $parsedAmount');

    // ✅ Check token
    final token = authController.userProfile.value.token;
    print(
        '🔐 Token: ${token?.substring(0, 20)}...'); // Print first 20 chars only

    if (token == null || token.isEmpty) {
      print('❌ ERROR: Token is null or empty');
      Fluttertoast.showToast(
        msg: "Authentication failed. Please login again",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      print('⏳ Loading started...');

      final response = await dio.post(
        kpostWithdraw,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        isLoading.value = false;
        print('✅ SUCCESS: Withdraw request completed');

        WithdrawData.value = response.data;

        Fluttertoast.showToast(
          msg: "Withdraw request success",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // ✅ Clear amount field
        amount.clear();
        Get.back();
        // Get.offAll(WithdrawAccount(), transition: Transition.rightToLeft);
      } else {
        isLoading.value = false;
        print('⚠️ WARNING: Status code is ${response.statusCode}');
        print('📄 Response body: ${response.data}');

        Fluttertoast.showToast(
          msg: "Your credentials don't match.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } on DioException catch (dioError) {
      isLoading.value = false;

      print('❌ DIO ERROR CAUGHT:');
      print('   Type: ${dioError.type}');
      print('   Message: ${dioError.message}');
      print('   Status Code: ${dioError.response?.statusCode}');
      print('   Response Data: ${dioError.response?.data}');
      print('   Request Data: ${dioError.requestOptions.data}');
      print('   Headers: ${dioError.requestOptions.headers}');

      String errorMessage = "Something went wrong";

      switch (dioError.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = "Connection timeout. Check your internet";
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = "Send timeout. Try again";
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = "Receive timeout. Server is slow";
          break;
        case DioExceptionType.badResponse:
          errorMessage = "Server error: ${dioError.response?.statusCode}";
          if (dioError.response?.data != null) {
            print('   Server Response: ${dioError.response?.data}');
            // ✅ Try to get error message from server
            if (dioError.response?.data is Map) {
              final serverMessage = dioError.response?.data['message'] ??
                  dioError.response?.data['error'];
              if (serverMessage != null) {
                errorMessage = serverMessage.toString();
              }
            }
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = "Request cancelled";
          break;
        case DioExceptionType.connectionError:
          errorMessage = "No internet connection";
          break;
        case DioExceptionType.badCertificate:
          errorMessage = "SSL certificate error";
          break;
        case DioExceptionType.unknown:
          errorMessage = "Unknown error: ${dioError.message}";
          break;
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e, stackTrace) {
      isLoading.value = false;

      print('❌ GENERAL ERROR CAUGHT:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');

      Fluttertoast.showToast(
        msg: "Unexpected error: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }

    print('🔵 ========== WITHDRAW SUBMIT END ==========\n');
  }

  //--------------------Withdraw to trading -------------
  Future<void> withdrawToTradePost() async {
    final data = {
      'amount': tradeAmount.text,
    };

    try {
      isLoading.value = true;

      ///------------------print section -------------
      print(data);
      print(kWithdrawUrl);
      print(authController.userProfile.value.token);

      final response = await dio.post(
        kWithdrawToTradeUrl,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        isLoading.value = false;
        withdrawToTradeData.value = response.data;
        print(response.data);

        Fluttertoast.showToast(
          msg: "withdraw to Trade success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Get.offAll(AppmenuView(), transition: Transition.rightToLeft);
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

  ///------------------------Exchange coin ----------------
  Future<void> exchangeCoin() async {
    final data = {
      'amount': exchangeAmount.text,
    };
    try {
      isLoading.value = true;

      ///------------------print section -------------
      print(data);
      print(kExchangeCoinUrl);
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
        exchangeCoinData.value = response.data;
        print(response.data);
        Fluttertoast.showToast(
          msg: "Coin exchange success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Get.offAll(AppmenuView(), transition: Transition.rightToLeft);
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
