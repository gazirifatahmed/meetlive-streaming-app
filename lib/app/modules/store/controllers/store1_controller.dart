import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../bottomnav/views/bottomnav_view.dart';

class Store1Controller extends GetxController {
  final dio = Dio();
  final isLoading = false.obs;

  final buyData = {}.obs;

  Future buyFream({required int asset_id}) async {
    isLoading.value = true;

    final data = {
      'asset_id': asset_id,
    };

    try {
      print(kFreamPersecs);
      print(authController.userProfile.value.token);
      final response = await dio.post(
        kFreamPersecs,
        data: data,
        options: Options(
          headers: {
            'Authorization':
                'Bearer ${authController.userProfile.value.token}', // Correct Bearer Token usage
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        buyData.value = response.data;
        Get.to(
          BottomnavView(),
          transition: Transition.rightToLeft,
        );

        Fluttertoast.showToast(
          msg: "Frame Buy Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
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
      print(e);
      isLoading.value = false;
      Get.snackbar(
        'Failed',
        "Something went wrong",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  ///-------------------follower list --------------------

// Follower List
  var followerList = [].obs;
  var filteredFollowerList = [].obs; // ✅ Follower search result

// Following List
  var followingList = [].obs;
  var filteredFollowingList = [].obs; // ✅ Following search result

  var isFollowingLoading = false.obs;

// 🔹 Follower List API
  Future showFollowerList() async {
    isLoading.value = true;
    try {
      final data = await dio.get(
        kFollowerList,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      followerList.value = data.data['follow_data'] ?? [];
      filteredFollowerList.value = followerList; // initially same
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

// 🔹 Following List API
  Future showFollowingList() async {
    isFollowingLoading.value = true;
    try {
      final data = await dio.get(
        kFollowingList, // ✅ Your following API endpoint
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      followingList.value = data.data['follow_data'] ?? [];
      filteredFollowingList.value = followingList; // initially same
    } catch (e) {
      print("Error: $e");
    } finally {
      isFollowingLoading.value = false;
    }
  }

// 🔹 Follower Search
  void searchByUserId(String query) {
    if (query.isEmpty) {
      filteredFollowerList.value = followerList;
    } else {
      filteredFollowerList.value = followerList
          .where((f) => f['user']['user_id']
              .toString()
              .toLowerCase()
              .contains(query.trim().toLowerCase()))
          .toList();
    }
  }

// 🔹 Following Search
  void searchByFollowing(String query) {
    if (query.isEmpty) {
      filteredFollowingList.value = followingList;
    } else {
      filteredFollowingList.value = followingList
          .where((f) => f['user']['user_id']
              .toString()
              .toLowerCase()
              .contains(query.trim().toLowerCase()))
          .toList();
    }
  }

  ///-------------------Following  list --------------------
}
