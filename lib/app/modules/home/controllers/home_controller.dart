import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../accountInfornation/views/account_infornation_view.dart';
import '../../appmenu/views/widgets/Flower.dart';
import '../../appmenu/views/widgets/FlowingList.dart';
import '../../appmenu/views/widgets/game_test.dart';
import '../../auth/views/profile_view.dart';
import '../../auth/views/userProfileVisit.dart';
import '../../livestream/controllers/livestream_controller.dart';
import '../../verified/views/verified_view.dart';
import '../../verified/views/widgets/pending_status_page.dart';
import '../widgets/manage_popup.dart';

class HomeController extends GetxController {
  //TODO: Implement HomeController
  // Game

  final _dio = Dio();

  LivestreamController get livestreamController =>
      Get.find<LivestreamController>();
  var popularUsers = <Map<String, dynamic>>[
    {
      'name': 'John Doe',
      'profileImage':
      'https://t3.ftcdn.net/jpg/09/14/07/04/360_F_914070451_GXGpScozuh7LKHXRes5lxYEOABQrocbH.jpg',
      'isOnline': true,
      'status': 'Available',
      'country': 'USA',
    },
    {
      'name': 'Jane Smith',
      'status': 'Busy',
      'profileImage':
      'https://images.pexels.com/photos/14653174/pexels-photo-14653174.jpeg',
      'isOnline': false,
      'country': 'Canada',
    },
    // Add more users here...
  ].obs; // Reactive list

  // List of countries
  var countries = ['Global', 'USA', 'UK', 'India', 'Japan'].obs;

  // Selected country
  var selectedCountry = 'Global'.obs;

  // All live streams (dummy data for now)
  var allStreams = [
    {
      'title': 'Stream 1',
      'viewers': 1200,
      'thumbnail': 'https://via.placeholder.com/150',
      'country': 'USA',
    },
    {
      'title': 'Stream 2',
      'viewers': 800,
      'thumbnail': 'https://via.placeholder.com/150',
      'country': 'India',
    },
    {
      'title': 'Stream 3',
      'viewers': 950,
      'thumbnail': 'https://via.placeholder.com/150',
      'country': 'UK',
    },
    {
      'title': 'Stream 4',
      'viewers': 700,
      'thumbnail': 'https://via.placeholder.com/150',
      'country': 'Japan',
    },
    {
      'title': 'Stream 5',
      'viewers': 1500,
      'thumbnail': 'https://via.placeholder.com/150',
      'country': 'Global',
    },
  ].obs;

  // Filtered streams
  var filteredStreams = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    showBannerList();
    showAllUserData();
    loadActiveFrame();
    getLivestreamList();
    filteredStreams.assignAll(allStreams); // Initialize with all streams
  }

  ///---------------------Active frame -----------------------

  final box = GetStorage();
  final activeFrameData = <String, dynamic>{}.obs;

  Future<void> loadActiveFrame() async {
    // 👉 আগে Local Storage check করবো
    if (box.hasData("activeFrameData")) {
      activeFrameData.value = box.read("activeFrameData");
      print("✅ Loaded frame from local storage: $activeFrameData");
    } else {
      // 👉 যদি Local এ না থাকে তখনই API call হবে
      await showActiveFrame();
    }
  }

  Future<void> showActiveFrame() async {
    try {
      final response = await Dio().get(
        kFrameActive,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
          responseType: ResponseType.plain,
        ),
      );

      Map<String, dynamic> frameMap = {};

      final responseString = response.data.toString().trim();

      if (responseString.startsWith('{') || responseString.startsWith('[')) {
        // decode JSON
        final decoded = json.decode(responseString);

        if (decoded is Map) {
          // 🔹 normalize active_asset_ids
          final activeAsset = decoded['active_asset_ids'];
          if (activeAsset == null || activeAsset is String) {
            decoded['active_asset_ids'] = {};
          }
          frameMap = Map<String, dynamic>.from(decoded);
        }
      } else {}

      if (frameMap.isNotEmpty) {
        activeFrameData.value = frameMap;
        box.write('activeFrameData', frameMap);
      } else if (box.hasData('activeFrameData')) {
        // 🔹 fallback: normalize active_asset_ids
        final stored = Map<String, dynamic>.from(box.read('activeFrameData'));
        if (stored['active_asset_ids'] == null ||
            stored['active_asset_ids'] is String) {
          stored['active_asset_ids'] = {};
        }
        activeFrameData.value = stored;
      }
    } catch (e) {
      if (box.hasData('activeFrameData')) {
        final stored = Map<String, dynamic>.from(box.read('activeFrameData'));
        if (stored['active_asset_ids'] == null ||
            stored['active_asset_ids'] is String) {
          stored['active_asset_ids'] = {};
        }
        activeFrameData.value = stored;
      }
    }
  }

  // 👉 যদি user নতুন frame active করে
  void updateActiveFrame(Map<String, dynamic> newFrame) {
    activeFrameData.value = newFrame;
    box.write("activeFrameData", newFrame); // save locally
  }

  void clearActiveFrame() {
    activeFrameData.value = {};
    box.remove("activeFrameData");
  }

  ///------------------Earniing data ------------------------
  final dio = Dio();

  final earningData = {}.obs;

  Future showEarningData() async {
    final data = await dio.get(
      kEarningPost,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
          // Correct Bearer Token usage
        },
      ),
    );
    earningData.value = data.data;
    Get.to(AccountInformationView(), transition: Transition.rightToLeft);
  }

  ///----------------------------------- user List Data ------------------------
  final allUserData = [].obs;
  final searchController = TextEditingController();

  Future showAllUserData() async {
    final data = await dio.get(kAllUserList);
    allUserData.value = data.data['data'];

  }

  final traderListData = [].obs;

  Future showAllTraderData() async {
    final data = await dio.get(
      kCoinTradingGet,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
          // Correct Bearer Token usage
        },
      ),
    );
    traderListData.value = data.data['trade_history'];
    print(traderListData);
  }

  // Filter by country
  void filterByCountry(String country) {
    selectedCountry.value = country;
    if (country == 'Global') {
      filteredStreams.assignAll(allStreams);
    } else {
      filteredStreams.assignAll(
        allStreams.where((stream) => stream['country'] == country).toList(),
      );
    }
  }

  //---------------------- Showing live stream list

  final isLoading = false.obs;
  final showingLiveStreamList = [].obs;

  Future getLivestreamList() async {
    isLoading.value = true;
    try {
      final response = await _dio.get(getLiveStreamList);

      if (response.statusCode == 200) {
        showingLiveStreamList.value = response.data;
        _sortLiveStreamList(); // Auto sort after getting data

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

  // Auto sorting method for livestream list
  void _sortLiveStreamList() {
    if (showingLiveStreamList.isEmpty) return;

    final List<dynamic> originalList = List.from(showingLiveStreamList);

    // PK room item থেকে sender/receiver normal live card-এর মধ্যে PK meta merge করবো.
    // All live list-এ PK room আলাদা card হবে না; Host A and Host B দুইজনই card থাকবে.
    final Map<String, Map<String, dynamic>> pkMetaByLiveId = {};

    for (final raw in originalList) {
      if (raw is! Map) continue;

      final item = Map<String, dynamic>.from(raw);

      final bool isPkRoom = item['is_pk_room'] == true ||
          item['stream_type']?.toString().toLowerCase() == 'pk';

      if (!isPkRoom) continue;

      final String senderId = '${item['sender_livestream_id'] ?? ''}';
      final String receiverId = '${item['receiver_livestream_id'] ?? ''}';

      final Map<String, dynamic> meta = {
        'is_pk': 1,
        'is_pk_room': false,
        'pk_id': item['pk_id'],
        'pk_status': item['pk_status'],
        'pk_channel': item['pk_channel'] ?? item['pk_channel_name'],
        'pk_channel_name': item['pk_channel_name'] ?? item['pk_channel'],
        'pk_start_time': item['pk_start_time'],
        'duration_seconds': item['duration_seconds'],
        'remaining_seconds': item['remaining_seconds'],
        'remaining_time': item['remaining_time'],

        'sender_livestream_id': item['sender_livestream_id'],
        'receiver_livestream_id': item['receiver_livestream_id'],
        'pk_sender_livestream_id': item['sender_livestream_id'],
        'pk_receiver_livestream_id': item['receiver_livestream_id'],

        'sender_host_id': item['sender_host_id'],
        'receiver_host_id': item['receiver_host_id'],
        'sender_host': item['sender_host'],
        'receiver_host': item['receiver_host'],
        'sender_livestream': item['sender_livestream'],
        'receiver_livestream': item['receiver_livestream'],

        'sender_score': item['sender_score'] ?? 0,
        'receiver_score': item['receiver_score'] ?? 0,
        'total_score': item['total_score'] ?? 0,
        'sender_score_percent': item['sender_score_percent'] ?? 50,
        'receiver_score_percent': item['receiver_score_percent'] ?? 50,

        'pk_room_data': item,
      };

      if (senderId.isNotEmpty && senderId != 'null' && senderId != '0') {
        pkMetaByLiveId[senderId] = meta;
      }

      if (receiverId.isNotEmpty && receiverId != 'null' && receiverId != '0') {
        pkMetaByLiveId[receiverId] = meta;
      }
    }

    final Set<String> seenLiveIds = {};
    final List<dynamic> sortedList = [];

    for (final raw in originalList) {
      if (raw is! Map) continue;

      final item = Map<String, dynamic>.from(raw);

      final bool isPkRoom = item['is_pk_room'] == true ||
          item['stream_type']?.toString().toLowerCase() == 'pk';

      // All list এ separate PK room card hide থাকবে.
      // Host A/Host B normal live card থাকবে, কিন্তু তাদের মধ্যে PK meta থাকবে.
      if (isPkRoom) continue;

      final String liveId =
          '${item['id'] ?? item['livestream_id'] ?? item['stream_id'] ?? ''}';

      if (liveId.isEmpty || liveId == '0' || liveId == 'null') continue;
      if (seenLiveIds.contains(liveId)) continue;

      seenLiveIds.add(liveId);

      final pkMeta = pkMetaByLiveId[liveId];

      if (pkMeta != null) {
        sortedList.add({
          ...item,
          ...pkMeta,
          'original_stream_type': item['stream_type'],
          'stream_type': item['stream_type'],
          'pk_status': pkMeta['pk_status'] ?? 'running',
        });
      } else {
        sortedList.add({
          ...item,
          'is_pk': 0,
        });
      }
    }

    sortedList.sort((a, b) {
      bool aIsOfficial = (a['stream_bte'] ?? '')
          .toString()
          .toLowerCase()
          .contains('official room');
      bool bIsOfficial = (b['stream_bte'] ?? '')
          .toString()
          .toLowerCase()
          .contains('official room');

      if (aIsOfficial && !bIsOfficial) return -1;
      if (!aIsOfficial && bIsOfficial) return 1;

      String streamTypeA = a['stream_type']?.toString().toLowerCase() ?? '';
      String streamTypeB = b['stream_type']?.toString().toLowerCase() ?? '';

      final bool aIsPk = (a['pk_id'] != null && '${a['pk_id']}' != '0') ||
          a['pk_status']?.toString().toLowerCase() == 'running';
      final bool bIsPk = (b['pk_id'] != null && '${b['pk_id']}' != '0') ||
          b['pk_status']?.toString().toLowerCase() == 'running';

      int priorityA = aIsPk ? 0 : _getStreamTypePriority(streamTypeA);
      int priorityB = bIsPk ? 0 : _getStreamTypePriority(streamTypeB);

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      int giftsCoinsA = _parseGiftsCoins(a['gifts_coins'] ?? a['total_score']);
      int giftsCoinsB = _parseGiftsCoins(b['gifts_coins'] ?? b['total_score']);

      return giftsCoinsB.compareTo(giftsCoinsA);
    });

    showingLiveStreamList.assignAll(sortedList);
  }

  // Get priority for stream types (lower number = higher priority)
  int _getStreamTypePriority(String streamType) {
    switch (streamType) {
      case 'pk':
        return 0; // PK Battle সবার আগে
      case 'popular':
        return 1;
      case 'audio':
        return 3;
      default:
        return 2;
    }
  }
  // Parse gifts_coins value safely



  int _parseGiftsCoins(dynamic giftsCoins) {
    if (giftsCoins == null) return 0;

    if (giftsCoins is int) return giftsCoins;
    if (giftsCoins is double) return giftsCoins.toInt();
    if (giftsCoins is String) {
      return int.tryParse(giftsCoins) ?? 0;
    }

    return 0;
  }

  // Method to add new stream and auto sort
  void addLiveStream(dynamic streamData) {
    showingLiveStreamList.add(streamData);
    _sortLiveStreamList();
  }

  // Method to remove stream and auto sort
  void removeLiveStream(dynamic streamData) {
    showingLiveStreamList.remove(streamData);
    _sortLiveStreamList();
  }

  // Method to update stream data and auto sort
  void updateLiveStream(int index, dynamic streamData) {
    if (index >= 0 && index < showingLiveStreamList.length) {
      showingLiveStreamList[index] = streamData;
      _sortLiveStreamList();
    }
  }

  // Method to manually trigger sorting
  void sortLiveStreamList() {
    _sortLiveStreamList();
  }

  //alamin code popular here

  final popularList = [].obs;

  Future getPopularList() async {
    isLoading.value = true;
    final data = await _dio.get(kPopularUrl);
    popularList.value = data.data;
    isLoading.value = false;
  }

  // live stream post create

  final streamController = ''.obs;
  final discriptionController = TextEditingController();
  final rtcTokenController = ''.obs;
  final streamCoinController = ''.obs;
  final streamTypeController = ''.obs;
  final giftsCoinController = ''.obs;
  final streamPurposeController = ''.obs;
  final streamImageController = ''.obs;

  //notification ----------------

  ///----------------------- comment data show  ---------------------
  final agencyList = [].obs;

  Future showingAgencyList() async {
    print(kAgencyListUrl);
    isLoading.value = true;
    try {
      final response = await _dio.get(
        kAgencyListUrl,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        agencyList.value = response.data['data'];
        isLoading.value = false;
      } else {
        isLoading.value = false;
        print('❌ Unexpected status code: ${response.statusCode}');
        Get.snackbar(
          'Failed',
          "Server returned status: ${response.statusCode}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on DioException catch (e) {
      isLoading.value = false;
      if (e.response != null) {
        Fluttertoast.showToast(
          msg: "Error ${e.response!.statusCode}: ${e.response!.statusMessage}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        print('   - No response received (network/connection issue)');
        Fluttertoast.showToast(
          msg: "Network error: ${e.message}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      isLoading.value = false;
      print('❌ Unexpected error: $e');
      Fluttertoast.showToast(
        msg: "Unexpected error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  final isGuardianData = {}.obs;

  //is guardian ki nah
  Future isGuardianBoll({required int StreamId, required int userId}) async {
    print(kisGuardian(streamId: StreamId, userId: userId));
    isLoading.value = true;
    try {
      final response = await _dio.get(
        kisGuardian(streamId: StreamId, userId: userId),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        isGuardianData.value = response.data;
        isLoading.value = false;
      } else {
        isLoading.value = false;
        print('❌ Unexpected status code: ${response.statusCode}');
        Get.snackbar(
          'Failed',
          "Server returned status: ${response.statusCode}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on DioException catch (e) {
      isLoading.value = false;
      if (e.response != null) {
        Fluttertoast.showToast(
          msg: "Error ${e.response!.statusCode}: ${e.response!.statusMessage}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        print('   - No response received (network/connection issue)');
        Fluttertoast.showToast(
          msg: "Network error: ${e.message}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      isLoading.value = false;
      print('❌ Unexpected error: $e');
      Fluttertoast.showToast(
        msg: "Unexpected error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  ///--------------------------------- Agency List Data ---------------------
  final agencyListData = {}.obs;

  // Future<void> showAgencyListData() async {
  //   try {
  //     final response = await _dio.get(
  //       kAgencyStatusListUrl,
  //       options: Options(
  //         headers: {
  //           'Authorization':
  //               'Bearer ${authController.userProfile.value.token}', // Correct Bearer Token usage
  //         },
  //       ),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       agencyListData.value = response.data;
  //       print("Agency Data Loaded: $agencyListData");
  //     } else {
  //       print("Failed to load data: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("Error fetching agency list: $e");
  //   }
  // }

  ///-------------------------------- profile visite api-------------

  final profileVisitor = {}.obs;

  void visitProfile({required String userId}) async {
    final data = {
      'user_id': userId,
    };
    try {
      print(kProfileVisitor);
      print(data);
      print(authController.userProfile.value.token);
      final response = await dio.post(
        kProfileVisitor,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        profileVisitor.value = response.data;
        print('proile data $profileVisitor');

        Get.to(userProfileVisit(),
            arguments: response.data, transition: Transition.rightToLeft);
        Fluttertoast.showToast(
          msg: "Profile visit Success",
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
      Get.snackbar(
        'Failed',
        "Something went wrong",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  final liveProfileVisitor = {}.obs;

  // Method to check if current user is the broadcaster
  bool get isBroadcaster {
    if (liveProfileVisitor.isEmpty ||
        authController.userProfile.value.user == null) {
      return false;
    }

    // Check if liveProfileVisitor and user data exist (API returns 'User Data' key)
    if (liveProfileVisitor['User Data'] == null ||
        liveProfileVisitor['User Data']['id'] == null) {
      return false;
    }

    final currentUserId = authController.userProfile.value.user!.id.toString();
    final profileUserId = liveProfileVisitor['User Data']['id'].toString();

    return currentUserId == profileUserId;
  }

  // Method to show manage popup for broadcasters
  void showManagePopup({required userDataPopup}) {
    if (liveProfileVisitor.isEmpty) return;

    final userData = userDataPopup['User Data'] ?? {};
    final userName = userData['name'] ?? 'Unknown User';
    final userAvatar = userData['avatar'] ?? '';
    final userId = userData['id'].toString();

    Get.bottomSheet(
      ManagePopup(
        userAllData: userDataPopup,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        onSendGifts: () {
          Get.back();
        },
        onViewProfile: () {
          Get.back();
          Get.to(ProfileView(),
              arguments: liveProfileVisitor.value,
              transition: Transition.rightToLeft);
        },
        onLeaveMic: () async {
          Get.back();

          try {
            // Get current user ID and stream ID
            final userId = liveProfileVisitor.value['User Data']['id'];
            final streamId = livestreamController.streamId.value;

            if (userId == null || streamId == 0) {
              Get.snackbar('Error', 'Invalid user or stream data');
              return;
            }

            // Show confirmation dialog
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                title: Text('Leave Mic'),
                content: Text('Are you sure you want to leave the mic?'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      livestreamController.tryToRejectCall(
                        streamId: streamId,
                        userId: userId,
                      );
                      Get.back(result: true);
                    },
                    child: Text('Leave', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {}
          } catch (e) {
            print('Error leaving mic: $e');
            Get.snackbar(
              'Error',
              'An error occurred while leaving mic',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        onMuteMic: () async {
          Get.back();
          final targetUserId = liveProfileVisitor.value['User Data']['id'];

          try {
            livestreamController.toggleSpecificUserAudio(targetUserId);
          } catch (e) {
            Get.snackbar(
              'Error',
              'An error occurred: $e',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        onCameraOnOff: () async {
          Get.back();
          final targetUserId = liveProfileVisitor.value['User Data']['id'];

          try {
            livestreamController.toggleSpecificUserVideo(targetUserId);
          } catch (e) {
            Get.snackbar(
              'Error',
              'An error occurred: $e',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        onKickOut: () async {
          Get.back();
          final targetUserId = liveProfileVisitor.value['User Data']['id'];

          // Show confirmation dialog
          final confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: Text('Kick Out User'),
              content: Text(
                  'Are you sure you want to kick out this user? They will be unable to rejoin for 15 minutes.'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: Text('Kick Out', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            try {
              final success =
              await livestreamController.kickOutUser(targetUserId);

              if (success) {
                Get.snackbar(
                  'Success',
                  'User has been kicked out successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to kick out user',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            } catch (e) {
              Get.snackbar(
                'Error',
                'An error occurred: $e',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          }
        },
        onSetAdministrator: () async {
          try {
            // Get current user ID and stream ID
            final userId = liveProfileVisitor.value['User Data']['user_id'];
            final onlyUserId = liveProfileVisitor.value['User Data']['id'];
            final streamId = livestreamController.streamId.value;

            if (userId == null || streamId == 0) {
              Get.snackbar('Error', 'Invalid user or stream data');
              return;
            }

            // Show confirmation dialog
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                title: Text('Set Administrator'),
                content: Text(
                    'Are you sure you want to make this user an administrator? They will have moderation privileges in this room.'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (isGuardianData['is_guardian'] == true) {
                        livestreamController.removeGuardian(
                          StreanId: streamId,
                          UserId: onlyUserId,
                        );
                      } else {
                        livestreamController.setGuardian(
                          StreanId: streamId,
                          UserId: onlyUserId,
                        );
                      }
                    },
                    child: Text('Set Administrator',
                        style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              final result =
              await livestreamController.makeGuardian(streamId, userId);

              if (result != null && result['success'] == true) {
                Get.snackbar(
                  'Success',
                  'User has been made an administrator successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  result?['message'] ?? 'Failed to set administrator',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            }
          } catch (e) {
            print('Error setting administrator: $e');
            Get.snackbar(
              'Error',
              'An error occurred while setting administrator',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        onAddToRoomBlacklist: () async {
          Get.back();

          try {
            // Get current user ID and stream ID
            final userId = liveProfileVisitor.value['User Data']['user_id'];
            final streamId = livestreamController.streamId.value;

            if (userId == null || streamId == 0) {
              Get.snackbar('Error', 'Invalid user or stream data');
              return;
            }

            // Show confirmation dialog
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                title: Text('Add to Room Blacklist'),
                content: Text(
                    'Are you sure you want to add this user to the room blacklist? They will be banned from this room.'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: Text('Add to Blacklist',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              final result = await livestreamController.addToRoomBlacklist(
                  streamId, userId,
                  reason: 'room_blacklist');

              if (result != null && result['success'] == true) {
                Get.snackbar(
                  'Success',
                  'User added to room blacklist successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  result?['message'] ?? 'Failed to add user to room blacklist',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            }
          } catch (e) {
            print('Error adding to room blacklist: $e');
            Get.snackbar(
              'Error',
              'An error occurred while adding to room blacklist',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        onAddToPersonalBlacklist: () async {
          Get.back();

          try {
            // Get current user ID
            final userId = liveProfileVisitor.value['User Data']['user_id'];

            if (userId == null) {
              Get.snackbar('Error', 'Invalid user data');
              return;
            }

            // Show confirmation dialog
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                title: Text('Add to Personal Blacklist'),
                content: Text(
                    'Are you sure you want to block this user? You will not see their messages or interactions.'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child:
                    Text('Block User', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              final response = await _dio.post(
                '$kMainUrl/user_block',
                data: {
                  'user_id': userId,
                },
                options: Options(headers: {
                  'Content-Type': 'application/json',
                  'Authorization':
                  'Bearer ${authController.userProfile.value.token}',
                }),
              );

              if (response.statusCode == 200 &&
                  response.data['status'] == true) {
                Get.snackbar(
                  'Success',
                  'User blocked successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  response.data['message'] ?? 'Failed to block user',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            }
          } catch (e) {
            print('Error blocking user: $e');
            Get.snackbar(
              'Error',
              'An error occurred while blocking user',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        guardianList: () async {
          final streamId = livestreamController.streamId.value;
          livestreamController.GuardianList(StreanId: streamId);
          Get.bottomSheet(
            Container(
              height: Get.height * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // 🔹 Drag Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Text(
                    "Guardian List",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Obx(() {
                    return Expanded(
                      child: livestreamController.guardianListData.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/no_guardians.png',
                              // এখানে তোমার empty image path
                              height: 100,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "No Guardians",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        itemCount:
                        livestreamController.guardianListData.length,
                        itemBuilder: (context, index) {
                          final guardian = livestreamController
                              .guardianListData[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade100,
                            ),
                            child: Row(
                              children: [
                                // Profile Image
                                ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: ImageHelper.getImageUrl(
                                      guardian['user']['profile_image'],
                                    ),
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Name & Level
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      guardian['user']['name'] ??
                                          'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Level: ${guardian['user']['level'] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  })
                ],
              ),
            ),
            isScrollControlled: true,
          );
        },
      ),
    );
  }

  void liveVisitProfile(
      {required String userId, required dynamic seatData}) async {
    try {
      final data = {
        'user_id': userId,
      };

      print("sagor test ${authController.userProfile.value.token}");
      final response = await dio.post(
        kProfileVisitor,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        liveProfileVisitor.value = response.data;
        print('live profele data $liveProfileVisitor');
        Get.dialog(
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // ✅ content অনুযায়ী size নেবে
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                // Check if user is visiting their own profile
                                bool isOwnProfile = liveProfileVisitor['User Data']
                                ?['id'] ==
                                    authController.userProfile.value.user!.id;

                                // Check if the profile user is in a call
                                bool profileUserInCall = websocketController
                                    .liveCallList
                                    .where((call) =>
                                call['caller_id'] ==
                                    liveProfileVisitor['User Data']?['id'])
                                    .isNotEmpty;

                                // If user visits their own profile, do nothing
                                if (isOwnProfile && !profileUserInCall) {
                                  return;
                                }
                                if (isOwnProfile &&
                                    livestreamController.isBroadcaster.value) {
                                  return;
                                }

                                // If broadcaster visiting others' profiles OR profile user is in call, show manage popup
                                if (livestreamController.isBroadcaster.value &&
                                    !isOwnProfile) {
                                  showManagePopup(userDataPopup: liveProfileVisitor);
                                }

                                if (isOwnProfile && profileUserInCall) {
                                  showManagePopup(userDataPopup: liveProfileVisitor);
                                }

                                // For non-broadcaster visiting others' profiles, we could add report functionality here
                                // Currently no report popup function exists, so we'll leave this empty for now
                              },
                              child: Castontext(
                                  fontSize: kHeight * 0.017,
                                  fontWeight: FontWeight.w500,
                                  textColor: Colors.black.withValues(alpha: .7),
                                  text: () {
                                    // Check if user is visiting their own profile
                                    bool isOwnProfile =
                                        liveProfileVisitor['User Data']?['id'] ==
                                            authController.userProfile.value.user!.id;

                                    // Check if the profile user is in a call
                                    bool profileUserInCall = websocketController
                                        .liveCallList
                                        .where((call) =>
                                    call['caller_id'] ==
                                        liveProfileVisitor['User Data']?['id'])
                                        .isNotEmpty;

                                    // If user visits their own profile, do nothing
                                    if (isOwnProfile && !profileUserInCall) {
                                      return '';
                                    }
                                    if (isOwnProfile &&
                                        livestreamController.isBroadcaster.value) {
                                      return '';
                                    }

                                    // If broadcaster visiting others' profiles OR profile user is in call, show manage popup
                                    if (livestreamController.isBroadcaster.value &&
                                        !isOwnProfile) {
                                      return 'Manage';
                                    }

                                    if (isOwnProfile && profileUserInCall) {
                                      return 'Manage';
                                    }
                                    // For non-broadcaster visiting others' profiles, show Report
                                    return 'Report';
                                  }()),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 5,
                            left: -kWeight * 0.2,
                            child: GestureDetector(
                              onTap: () {
                                final broadcasterData = {}.obs;

                                // Get.to(ProfileView(),
                                //     arguments: response.data,
                                //     transition: Transition.rightToLeft);
                              },
                              child: Obx(() {
                                final sender = liveProfileVisitor['User Data']
                                ['my_top_gifter']?['sender'];
                                final double size = Get.height * 0.07;

                                // যদি sender null হয় (কেউ না থাকে), তাহলে fallback দেখাও
                                if (sender == null) {
                                  return CircleAvatar(
                                    radius: Get.height * 0.025,
                                    backgroundImage:
                                    AssetImage('assets/images/support_user.png'),
                                  );
                                }

                                return SizedBox(
                                  height: size,
                                  width: size,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 🟢 Profile Image (with fallback)
                                      ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: ImageHelper.getImageUrl(
                                              "${sender['profile_image']}"),
                                          fit: BoxFit.cover,
                                          height: size * 0.75,
                                          width: size * 0.75,
                                          errorWidget: (context, url, error) =>
                                              Image.asset(
                                                'assets/images/support_user.png',
                                                fit: BoxFit.cover,
                                              ),
                                        ),
                                      ),

                                      // 🔴 Agency Frame (agency_id ≠ 0)
                                      // if (sender['agency_id'] != 0)
                                      //   Positioned.fill(
                                      //     child: SVGAEasyPlayer(
                                      //       assetsName:
                                      //           'assets/svga/Frame/Agency frame.svga',
                                      //       fit: BoxFit.cover,
                                      //     ),
                                      //   )

                                      // 🟡 Asset Frame (agency_id == 0 && asset_purchase_history ≠ null)
                                      if (sender['asset_purchase_history'] != null)
                                        (sender['asset_purchase_history']['asset']
                                        ['asset']
                                            .toString()
                                            .endsWith('.svga'))
                                            ? SizedBox(
                                          height: kHeight * 0.08,
                                          width: kHeight * 0.08,
                                          child: SVGAEasyPlayer(
                                            resUrl:
                                            '$kDomainUrl/${sender['asset_purchase_history']['asset']['asset']}',
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                            : Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  ImageHelper.getImageUrl(
                                                    '${sender['asset_purchase_history']['asset']['asset']}',
                                                  ),
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          GestureDetector(

                            onTap: () {
                              visitProfile(userId: '${liveProfileVisitor['User Data']['id']}');
                            },
                            child: Obx(() {
                              final user = liveProfileVisitor['User Data'];
                              final double size = Get.height * 0.08;

                              return SizedBox(
                                height: size,
                                width: size,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 🟢 Profile Image (with fallback)
                                    ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: ImageHelper.getImageUrl(
                                            "${user['profile_image']}"),
                                        fit: BoxFit.cover,
                                        height: size * 0.75,
                                        width: size * 0.75,
                                        errorWidget: (context, url, error) =>
                                            Image.asset(
                                              'assets/images/support_user.png',
                                              fit: BoxFit.cover,
                                            ),
                                      ),
                                    ),

                                    // 🔴 Agency Frame (show if agency_id != 0)
                                    // if (user['agency_id'] != 0)
                                    //   Positioned.fill(
                                    //     child: SVGAEasyPlayer(
                                    //       assetsName: agencyFrame,
                                    //       fit: BoxFit.cover,
                                    //     ),
                                    //   )

                                    // 🟡 Asset Frame (show if agency_id == 0 && asset_purchase_history != null)
                                    if (user['asset_purchase_history'] != null)
                                      (user['asset_purchase_history']['asset']
                                      ['asset']
                                          .toString()
                                          .endsWith('.svga'))
                                          ? SizedBox(
                                        height: kHeight * 0.08,
                                        width: kHeight * 0.08,
                                        child: SVGAEasyPlayer(
                                          resUrl:
                                          '$kDomainUrl/${user['asset_purchase_history']['asset']['asset']}',
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                          : Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                ImageHelper.getImageUrl(
                                                  '${user['asset_purchase_history']['asset']['asset']}',
                                                ),
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: kHeight * 0.015,
                      ),
                      //name part
                      Text(
                        '${liveProfileVisitor['User Data']['name']}',
                        style: GoogleFonts.merriweather(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 🔹 User ID Text
                          Text(
                            'UID ${liveProfileVisitor['User Data']['user_id']}',
                            style: GoogleFonts.roboto(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),

                          // 🔹 Copy Icon
                          GestureDetector(
                            onTap: () {
                              final id =
                                  "${liveProfileVisitor['User Data']['user_id']}";
                              Clipboard.setData(ClipboardData(text: id));

                              // Feedback message
                              Fluttertoast.showToast(
                                msg: "User ID copied to clipboard",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.black87,
                                textColor: Colors.white,
                                fontSize: 16.0,
                              );
                            },
                            child: Icon(
                              Icons.copy,
                              size: 20,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),

                      //name part
                      SizedBox(
                        height: 10,
                      ),
                      //part bangladesh male lv  start
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {},
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                height: 25,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                  color: Colors.black.withValues(alpha: .1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: const Image(
                                        image: AssetImage(
                                          'assets/icons/icons8-bangladesh-48.png',
                                        ),
                                        height: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${liveProfileVisitor['User Data']['country']}' ??
                                          "",
                                      style: TextStyle(
                                        color: Colors.black26,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            InkWell(
                              onTap: () {},
                              child: Container(
                                padding:
                                EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                  color: Color(0xffea7e04),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.male,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '25 ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            LevelFrame(
                              level: '${liveProfileVisitor['User Data']['level']}',
                            ),
                            SizedBox(
                              width: 5,
                            ),
                          ],
                        ),
                      ),
                      //bangladesh lv male end

                      //call audio call  video call and gift part start
                      SizedBox(
                        height: kHeight * 0.025,
                      ),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.to(FollowinfList(),
                                    transition: Transition.rightToLeft);
                              },
                              child: _statTile(
                                  '${liveProfileVisitor['User Data']['total_following'] ?? 0}',
                                  'Following'),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Get.to(FollowinfList(),
                                //     transition: Transition.rightToLeft);
                              },
                              child: _statTile(
                                  '${liveProfileVisitor['User Data']['earned_coins']}',
                                  'Receive'),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Get.to(FollowinfList(),
                                //     transition: Transition.rightToLeft);
                              },
                              child: _statTile(
                                  '${liveProfileVisitor['User Data']['gifts_coins'] ?? 0}',
                                  'Send'),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.to(Follower(),
                                    transition: Transition.rightToLeft);
                              },
                              child: _statTile(
                                  '${liveProfileVisitor['User Data']['total_followers'] ?? 0}',
                                  'Followers'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: kHeight * 0.02,
                      ),

                      liveProfileVisitor['User Data']['id'] ==
                          authController.userProfile.value.user!.id
                          ? Container() // যদি নিজের প্রোফাইল হয়, তাহলে ফলো/আনফলো বাটন দেখাবেন না
                          :  Divider(
                        color: Colors.grey[100],
                      ),
                      liveProfileVisitor['User Data']['id'] ==
                          authController.userProfile.value.user!.id
                          ? Container() // যদি নিজের প্রোফাইল হয়, তাহলে ফলো/আনফলো বাটন দেখাবেন না
                          :  SizedBox(
                        height: kHeight * 0.01,
                      ),
                      liveProfileVisitor['User Data']['id'] ==
                          authController.userProfile.value.user!.id
                          ? Container() // যদি নিজের প্রোফাইল হয়, তাহলে ফলো/আনফলো বাটন দেখাবেন না
                          :
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Obx(() => TextButton(
                            onPressed: () {

                              liveProfileVisitor['User Data']['follow_status'] ==
                                  'yes'
                                  ? momentsController.unFollowCreate(
                                  id: liveProfileVisitor['User Data']['id'])
                                  : momentsController.followCreate(
                                  userId:
                                  '${liveProfileVisitor['User Data']['id']}');
                            },
                            child: Castontext(
                                fontSize: kHeight * 0.013,
                                fontWeight: FontWeight.w500,
                                textColor: Colors.black.withValues(alpha: .7),
                                text: liveProfileVisitor['User Data']
                                ['follow_status'] ==
                                    'yes'
                                // isBroadcaster
                                //     ? 'Manage'
                                //     : (liveProfileVisitor['is_following'] ?? false
                                    ? 'Unfollow'
                                    : 'Follow'),
                          )),
                          TextButton(
                            onPressed: () {},
                            child: Castontext(
                                fontSize: kHeight * 0.013,
                                fontWeight: FontWeight.w500,
                                textColor: Colors.black.withValues(alpha: .7),
                                text: 'Message'),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Castontext(
                                fontSize: kHeight * 0.013,
                                fontWeight: FontWeight.w500,
                                textColor: Colors.black.withValues(alpha: .7),
                                text: 'Reply'),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Castontext(
                                fontSize: kHeight * 0.013,
                                fontWeight: FontWeight.w500,
                                textColor: Colors.black.withValues(alpha: .7),
                                text: 'Home'),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: kHeight * 0.02,
                      ),
                    ],
                  ),
                ),
              ),
            ));
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
      Get.snackbar(
        'Failed',
        "Something went wrong",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  ///----------------------- show banner ---------------------

  var bannerLstData = <dynamic>[].obs;

  Future<void> showBannerList() async {
    try {
      final response = await _dio.get(kBannerList);

      if (response.statusCode == 200) {
        // Filter out banners with invalid or empty image paths
        final List<dynamic> validBanners = (response.data['data'] as List)
            .where((banner) =>
        banner['image'] != null &&
            banner['image'].toString().isNotEmpty &&
            !banner['image'].toString().startsWith('file:///'))
            .toList();

        bannerLstData.value = validBanners;
        print("Banner list loaded: ${validBanners.length} valid banners");

        // Log any invalid banners for debugging
        final List<dynamic> invalidBanners = (response.data['data'] as List)
            .where((banner) =>
        banner['image'] == null ||
            banner['image'].toString().isEmpty ||
            banner['image'].toString().startsWith('file:///'))
            .toList();

        if (invalidBanners.isNotEmpty) {
          print(
              "Found ${invalidBanners.length} invalid banners: $invalidBanners");
        }
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching banner list: $e");
      bannerLstData.value = []; // Set empty list on error
    }
  }

  var hostStatusData = {}.obs;

  Future<void> showHostStatusList() async {
    print(kHostStatus);
    try {
      final response = await _dio.get(
        kHostStatus,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data['Host Request'] == null ||
            response.data['Host Request'] == Null) {
          Get.to(VerifiedView(), transition: Transition.rightToLeft);
        } else {
          hostStatusData.value = response.data['Host Request'];
          Get.to(
              HostCertificationPage(
                verificationData: hostStatusData,
              ),
              transition: Transition.rightToLeft);
        }
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching banner list: $e");
      bannerLstData.value = []; // Set empty list on error
    }
  }

  //----------------- refresh
  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        showEarningData(),
        showAllUserData(),
        showAllTraderData(),
        showActiveFrame(),
        getLivestreamList(),
        showingAgencyList(),
      ]);
    } catch (e) {
      print("Error refreshing data: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

Widget _statTile(String value, String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Text(
          formatNumber(value), // value jeta hobe seta pass korun
          style:
          TextStyle(fontSize: kHeight * 0.02, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style:
          TextStyle(color: Colors.grey.shade600, fontSize: kHeight * 0.013),
        ),
      ],
    ),
  );

  /// ----------------- Status -------------
}

String formatNumber(dynamic value) {
  // Convert to number if it's a string
  double number =
  value is String ? double.tryParse(value) ?? 0 : value.toDouble();

  if (number >= 1000000) {
    // For millions
    double millions = number / 1000000;
    return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
  } else if (number >= 1000) {
    // For thousands
    double thousands = number / 1000;
    return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
  } else {
    // For numbers less than 1000
    return number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 1);
  }
}
