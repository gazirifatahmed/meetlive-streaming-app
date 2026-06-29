import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../widgets/call_request_popup.dart';
import '../../../services/agora_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bottomnav/views/bottomnav_view.dart';
import '../../home/controllers/home_controller.dart';
import 'livestream_controller.dart';

class WebsocketController extends GetxController {
  @override
  void onInit() {
    /// ✅ Backend now sends everything through one event:
    /// App\\Events\\LiveStreamEvent / LiveStreamEvent
    /// and payload contains action_type.
    ///
    /// Old separate websocket connect functions are kept below as backup,
    /// but we do not call them here anymore.
    tryToConnectToUnifiedLiveStreamEventWs();

    super.onInit();
  }

  // Home controller instance
  HomeController get homeController => Get.find<HomeController>();
  LivestreamController get livestreamController => Get.find<LivestreamController>();
  AuthController get authController => Get.find<AuthController>();
  // websocket staff
  WebSocketChannel? channel;
  final streamID = 0.obs;
  final activeAudioStreamId = 0.obs;
  final newViewersJoinded = false.obs;
  final newJoinedUserData = {}.obs;

  /// viewer_join / viewer_left animation status
  final newViewerAction = 'join'.obs;

  final dio = Dio();

  // Red packet properties
  final redPacketVisible = false.obs;
  final currentRedPacket = <String, dynamic>{}.obs;
  Timer? redPacketTimer;

  // Gift tracking to prevent duplicates
  final Set<String> processedGiftIds = <String>{};
  final Set<String> processedImogiIds = <String>{};
  final liveImogiAnimations = <Map<String, dynamic>>[].obs;

  /// Keeps last known mic state for every user (host + seat callers).
  /// This prevents host mute icon from being reset by unrelated seat join/leave events.
  /// true = muted, false = unmuted.
  final audioMutedUserMap = <int, bool>{}.obs;

  // Global red packet properties (for all live streams)
  final globalRedPacketVisible = false.obs;
  final globalCurrentRedPacket = <String, dynamic>{}.obs;
  Timer? globalRedPacketTimer;

  // Emoji animation properties
  final emojiAnimations = <Map<String, dynamic>>[].obs;
  final showEmojiAnimation = false.obs;
  Function(Map<String, dynamic> redPacketData)? onRedPacketReceived;

  // Heartbeat and cleanup properties
  Timer? heartbeatTimer;
  Timer? inactivityTimer;
  final isUserActive = true.obs;
  final lastActivityTime = DateTime.now().obs;
  final heartbeatInterval = 30; // seconds
  final inactivityTimeout = 120; // seconds (2 minutes)

  //comments on live stream
  // LivestreamController livestreamController = Get.find();
  final AgoraService _agoraService = AgoraService();
  // for live stream end
  final liveCallList = [].obs; // Stores accepted calls
  final pendingCall = [].obs; // Stores pending calls
  final commentsList = [].obs;

  /// Gift tab data.
  /// All tab = commentsList + giftMessagesList
  /// Message tab = only normal comments
  /// Gift tab = only gift data
  final giftMessagesList = [].obs;

  /// Live music status for audience UI.
  final liveMusicStatus = 'stopped'.obs;
  final liveMusicName = ''.obs;
  final liveMusicHostId = 0.obs;

  /// Live YouTube status for all audience UI.
  final liveYoutubeStatus = 'stopped'.obs;
  final liveYoutubeUrl = ''.obs;
  final liveYoutubeVideoId = ''.obs;
  final liveYoutubeHostId = 0.obs;

  /// Live room realtime edit state.
  /// 0 means no override yet; AudioLiveView will use initial Get.arguments values.
  final liveRoomUpdateStreamId = 0.obs;
  final liveRoomSeatCount = 0.obs;
  final liveRoomLayout = 0.obs;
  final liveRoomTheme = 0.obs;
  final liveRoomBackground = (-1).obs;

  void updateLiveRoomSettings({
    required int livestreamId,
    required int seatCount,
    required int roomLayout,
    required int roomTheme,
    required int roomBackground,
  }) {
    liveRoomUpdateStreamId.value = livestreamId;
    liveRoomSeatCount.value = seatCount;
    liveRoomLayout.value = roomLayout;
    liveRoomTheme.value = roomTheme;
    liveRoomBackground.value = roomBackground;

    print(
      '🎨 Live room settings updated => stream:$livestreamId seats:$seatCount layout:$roomLayout theme:$roomTheme bg:$roomBackground',
    );
  }

  /// seatNo => locked true/false.
  ///
  /// IMPORTANT:
  /// This is the single source of truth for UI seat lock state.
  /// Viewer join / live refresh / available seat response must NOT clear this map
  /// unless backend sends an explicit unlock event or host manual unlock succeeds.
  final RxMap<int, bool> lockedSeatMap = <int, bool>{}.obs;

  bool _seatTruthy(dynamic value) {
    final v = value?.toString().toLowerCase().trim() ?? '';
    return v == '1' ||
        v == 'true' ||
        v == 'yes' ||
        v == 'y' ||
        v == 'locked' ||
        v == 'lock';
  }

  bool _seatFalsey(dynamic value) {
    final v = value?.toString().toLowerCase().trim() ?? '';
    return v == '0' ||
        v == 'false' ||
        v == 'no' ||
        v == 'n' ||
        v == 'unlocked' ||
        v == 'unlock';
  }

  int? _seatToInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  bool isSeatLocked(dynamic seatNoRaw) {
    final seatNo = _seatToInt(seatNoRaw);
    if (seatNo == null) return false;
    return lockedSeatMap[seatNo] == true;
  }


  /// Full room snapshot sync for late audience join/resume.
  /// Host live create korar por lock/mute/gift change hoye gele new audience
  /// realtime old events pabe na. Tai room open/viewer add/resume time-e API/list
  /// response theke current state local controller-e apply korte hobe.
  bool _asMuted(dynamic audioOn, dynamic mutedRaw) {
    final a = audioOn?.toString().toLowerCase().trim() ?? '';
    final m = mutedRaw?.toString().toLowerCase().trim() ?? '';

    /// IMPORTANT for late-join snapshots:
    /// Some backend rows can carry audio_on=1 while is_muted/is_muted_by_host=1.
    /// In that case explicit mute must win, otherwise host looks unmuted to audience.
    if (m == '1' || m == 'true' || m == 'yes' || m == 'y' || m == 'muted' || m == 'mute') return true;
    if (a == '0' || a == 'false' || a == 'off' || a == 'mute' || a == 'muted') return true;

    if (m == '0' || m == 'false' || m == 'no' || m == 'n' || m == 'unmuted' || m == 'unmute') return false;
    if (a == '1' || a == 'true' || a == 'on' || a == 'unmute' || a == 'unmuted') return false;

    return false;
  }

  int _extractUserIdFromAny(Map<String, dynamic> item) {
    final user = item['user'];
    final profile = item['profile'];
    final broadcaster = item['broadcaster'];
    final host = item['host'];

    final bool looksLikeStreamRoot = item.containsKey('livestream_id') ||
        item.containsKey('stream_id') ||
        item.containsKey('seat_count') ||
        item.containsKey('room_layout') ||
        item.containsKey('livestream_callers');

    final bool looksLikeUserObject = item.containsKey('name') ||
        item.containsKey('profile_image') ||
        item.containsKey('avatar') ||
        item.containsKey('level') ||
        item.containsKey('gender') ||
        item.containsKey('email');

    final raw = item['user_id'] ??
        item['host_id'] ??
        item['broadcaster_id'] ??
        item['caller_id'] ??
        item['viewer_id'] ??
        (user is Map ? user['id'] : null) ??
        (profile is Map ? profile['id'] : null) ??
        (broadcaster is Map ? broadcaster['id'] : null) ??
        (host is Map ? host['id'] : null) ??
        (looksLikeStreamRoot && !looksLikeUserObject ? null : item['id']);

    return int.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  void _syncMuteStateFromUserLikeMap(Map<String, dynamic> item, {String source = 'snapshot'}) {
    final uid = _extractUserIdFromAny(item);
    if (uid <= 0) return;

    final user = item['user'];
    final profile = item['profile'];
    final broadcaster = item['broadcaster'];
    final host = item['host'];

    dynamic nestedAudio;
    dynamic nestedMuted;
    if (user is Map) {
      nestedAudio = user['audio_on'] ?? user['is_audio_on'] ?? user['mic_on'];
      nestedMuted = user['is_muted'] ?? user['muted'] ?? user['is_muted_by_host'];
    } else if (profile is Map) {
      nestedAudio = profile['audio_on'] ?? profile['is_audio_on'] ?? profile['mic_on'];
      nestedMuted = profile['is_muted'] ?? profile['muted'] ?? profile['is_muted_by_host'];
    } else if (broadcaster is Map) {
      nestedAudio = broadcaster['audio_on'] ?? broadcaster['is_audio_on'] ?? broadcaster['mic_on'];
      nestedMuted = broadcaster['is_muted'] ?? broadcaster['muted'] ?? broadcaster['is_muted_by_host'];
    } else if (host is Map) {
      nestedAudio = host['audio_on'] ?? host['is_audio_on'] ?? host['mic_on'];
      nestedMuted = host['is_muted'] ?? host['muted'] ?? host['is_muted_by_host'];
    }

    final audioOn = item['audio_on'] ??
        item['is_audio_on'] ??
        item['mic_on'] ??
        item['is_mic_on'] ??
        nestedAudio;

    final mutedRaw = item['is_muted'] ??
        item['muted'] ??
        item['is_muted_by_host'] ??
        item['mute'] ??
        item['mic_muted'] ??
        nestedMuted;

    if (audioOn == null && mutedRaw == null) return;

    final muted = _asMuted(audioOn, mutedRaw);
    audioMutedUserMap[uid] = muted;
    print('🎙️ Snapshot mute synced => user:$uid muted:$muted source:$source');
  }

  void syncRoomSnapshotForLateJoin(Map<String, dynamic>? payload, {String source = 'late_join_snapshot'}) {
    if (payload == null || payload.isEmpty) return;

    try {
      final root = Map<String, dynamic>.from(payload);
      Map<String, dynamic> data = Map<String, dynamic>.from(root);

      for (final key in ['data', 'livestreamdata', 'livestream', 'live_stream', 'stream']) {
        if (root[key] is Map) {
          data = {
            ...data,
            ...Map<String, dynamic>.from(root[key]),
          };
        }
      }

      /// Gift total must be available for late audience immediately.
      syncGiftCoinsFromPayload(data, source: source);
      try { livestreamController.syncLiveGiftCoinsFromPayload(data, source: source); } catch (_) {}

      /// Locked seats from current room snapshot.
      /// If backend sends explicit locked_seats, that list is the source of truth.
      final bool hasExplicitLockedSeatList =
          data['locked_seats'] is List ||
              data['lockedSeats'] is List ||
              data['locked_seat_numbers'] is List ||
              data['lockedSeatNumbers'] is List ||
              data['locks'] is List;

      syncSeatLocksFromAnyPayload(data, allowUnlock: false, source: source);

      /// Host/broadcaster mute state.
      _syncMuteStateFromUserLikeMap(data, source: '$source/root');
      for (final key in ['user', 'host', 'broadcaster', 'livestream_user', 'owner']) {
        if (data[key] is Map) {
          _syncMuteStateFromUserLikeMap(Map<String, dynamic>.from(data[key]), source: '$source/$key');
        }
      }

      /// Seat callers mute + coin + lock state.
      final callers = data['livestream_callers'] ?? data['callers'] ?? data['seats'] ?? data['seat_users'];
      if (callers is List) {
        for (final raw in callers) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          _syncMuteStateFromUserLikeMap(item, source: '$source/caller');

          final seatNo = _seatToInt(item['seat_no'] ?? item['seatNo'] ?? item['seat'] ?? item['seat_number']);
          final rawLocked = item['is_locked'] ?? item['locked'] ?? item['seat_locked'] ?? item['lock_status'];

          /// Do not let stale livestream_callers.is_locked=yes override explicit
          /// locked_seats from backend. This was making unlocked seats appear
          /// locked again in popular/video/audio views.
          if (!hasExplicitLockedSeatList && seatNo != null && _seatTruthy(rawLocked)) {
            updateSeatLockStatus(seatNo: seatNo, isLocked: true, source: '$source/caller_lock');
          }
        }
      }

      audioMutedUserMap.refresh();
      lockedSeatMap.refresh();
      liveCallList.refresh();
      livestreamController.update();
      print('✅ Room snapshot synced for late join => source:$source locks:${lockedSeatMap.keys.toList()} muted:$audioMutedUserMap coins:$totalGiftCoins');
    } catch (e, st) {
      print('❌ syncRoomSnapshotForLateJoin error => $e\n$st payload=$payload');
    }
  }

  void updateSeatLockStatus({
    required int seatNo,
    required bool isLocked,
    String source = 'unknown',
  }) {
    if (seatNo <= 0) return;

    if (isLocked) {
      lockedSeatMap[seatNo] = true;
    } else {
      lockedSeatMap.remove(seatNo);
    }

    /// Do not mutate liveCallList['is_locked'] here.
    /// Backend call object can contain is_locked=yes for an occupied call/seat,
    /// but real room lock state must live only in lockedSeatMap.
    lockedSeatMap.refresh();
    print('🔒 Seat lock status updated => seat:$seatNo locked:$isLocked source:$source locks:${lockedSeatMap.keys.toList()}');
  }

  /// Sync lock state from any live details / available seats / room payload.
  /// allowUnlock=false keeps previously locked seats safe during viewer join/resume.
  /// Only explicit unlock event/API success should call with allowUnlock=true or updateSeatLockStatus(false).
  void syncSeatLocksFromAnyPayload(
      Map<String, dynamic> payload, {
        bool allowUnlock = false,
        String source = 'payload',
      }) {
    try {
      final Map<String, dynamic> data = payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'])
          : Map<String, dynamic>.from(payload);

      void lockSeat(dynamic value, {String src = 'locked_list'}) {
        final seatNo = _seatToInt(value);
        if (seatNo != null && seatNo > 0) {
          updateSeatLockStatus(
            seatNo: seatNo,
            isLocked: true,
            source: '$source/$src',
          );
        }
      }

      void parseLockedList(dynamic list, {String src = 'locked_list'}) {
        if (list is! List) return;
        for (final item in list) {
          if (item is Map) {
            final seatNo = item['seat_no'] ??
                item['seatNo'] ??
                item['seat'] ??
                item['seat_number'] ??
                item['no'] ??
                item['number'];
            final rawLocked = item['is_locked'] ??
                item['locked'] ??
                item['seat_locked'] ??
                item['lock_status'] ??
                item['status'];
            if (seatNo != null && (rawLocked == null || _seatTruthy(rawLocked))) {
              lockSeat(seatNo, src: src);
            } else if (allowUnlock && seatNo != null && _seatFalsey(rawLocked)) {
              final parsedSeat = _seatToInt(seatNo);
              if (parsedSeat != null) {
                updateSeatLockStatus(
                  seatNo: parsedSeat,
                  isLocked: false,
                  source: '$source/$src-explicit-unlock',
                );
              }
            }
          } else {
            lockSeat(item, src: src);
          }
        }
      }

      final bool hasExplicitLockedSeatList =
          data['locked_seats'] is List ||
              data['lockedSeats'] is List ||
              data['locked_seat_numbers'] is List ||
              data['lockedSeatNumbers'] is List ||
              data['locks'] is List;

      parseLockedList(data['locked_seats'], src: 'locked_seats');
      parseLockedList(data['lockedSeats'], src: 'lockedSeats');
      parseLockedList(data['locked_seat_numbers'], src: 'locked_seat_numbers');
      parseLockedList(data['lockedSeatNumbers'], src: 'lockedSeatNumbers');
      parseLockedList(data['locks'], src: 'locks');

      final dynamic callersRaw =
          data['livestream_callers'] ?? data['callers'] ?? data['seats'];
      if (!hasExplicitLockedSeatList && callersRaw is List) {
        for (final item in callersRaw) {
          if (item is! Map) continue;
          final seatNo = _seatToInt(
            item['seat_no'] ?? item['seatNo'] ?? item['seat'] ?? item['seat_number'],
          );
          if (seatNo == null || seatNo <= 0) continue;

          final lockValue = item['is_locked'] ??
              item['locked'] ??
              item['seat_locked'] ??
              item['lock_status'];

          if (_seatTruthy(lockValue)) {
            updateSeatLockStatus(
              seatNo: seatNo,
              isLocked: true,
              source: '$source/caller_lock',
            );
          } else if (allowUnlock && _seatFalsey(lockValue)) {
            updateSeatLockStatus(
              seatNo: seatNo,
              isLocked: false,
              source: '$source/caller_unlock',
            );
          }
        }
      }

      /// Intentionally never unlock from available_seats only.
      /// Some backend responses send available_seats without locked_seats and
      /// that used to make locked seats visually unlock for late viewers.
    } catch (e) {
      print('⚠️ syncSeatLocksFromAnyPayload error => $e payload=$payload');
    }
  }

  final isPkRunning = false.obs;

  Function(Map<String, dynamic> collectionData)? onRedPacketCollected;

  void tryToConnectToLiveListWs() async {
    print('⚡ Trying to connect to Live List WS...');
    if (channel != null) {
      try {
        await channel!.sink.close();
      } catch (_) {}
    }
    if (kWsUrl.isEmpty) {
      print('❌ WebSocket URL is empty.');
      return;
    }
    try {
      channel = WebSocketChannel.connect(Uri.parse(kWsUrl));
      await channel?.ready;
      print('✅ Connected to WebSocket');
    } catch (e) {
      print('❌ Connection failed: $e');
      channel = null;
      return;
    }
    channel!.stream.listen((message) {
      try {
        final decoded1 = json.decode(message);
        // handle ping - check in decoded JSON, not raw string
        if (decoded1 is Map && decoded1["event"] == "pusher:ping") {
          channel?.sink.add(json.encode({"event": "pusher:pong"}));
          return;
        }
        final eventName = decoded1["event"];
        dynamic streamData;

        // 🔹 decode deeply until we reach Map
        dynamic inner = decoded1["data"];
        int safeLimit = 5; // just in case infinite nested
        while (inner is String && safeLimit > 0) {
          inner = json.decode(inner);
          safeLimit--;
        }

        // 🔹 handle nested data
        if (inner is Map) {
          if (inner["data"] is Map && inner["data"]["data"] != null) {
            streamData = inner["data"]["data"];
          } else if (inner["data"] != null) {
            streamData = inner["data"];
          } else {
            streamData = inner;
          }
        }

        if (eventName == "App\\Events\\LiveStreamCreated" ||
            eventName == "live-stream-created") {
          if (streamData != null) {
            final userId = streamData["user_id"];

            // Remove any existing stream from the same user
            homeController.showingLiveStreamList
                .removeWhere((s) => s["user_id"] == userId);

            // Add the new stream
            homeController.showingLiveStreamList.add(streamData);
            homeController.sortLiveStreamList(); // Auto sort after adding
            homeController.showingLiveStreamList.refresh();
          } else {
            print('❌ streamData is NULL after decode.');
          }
        } else if (eventName == "App\\Events\\LiveStreamEnded" ||
            eventName == "live-stream-ended") {
          if (streamData != null) {
            final streamId = streamData["id"];
            homeController.showingLiveStreamList
                .removeWhere((s) => s["id"] == streamId);
            homeController.sortLiveStreamList(); // Auto sort after removing
            homeController.showingLiveStreamList.refresh();
            print('🔚 Live Stream Ended: ${streamData["stream_bte"]}');
          }
        } else {
          print('ℹ️ Other event: $eventName');
        }
      } catch (e, st) {
        print("⚠️ Error decoding message: $e\n$st");
      }
    });

    // subscribe
    try {
      final subscribeData = {
        "event": "pusher:subscribe",
        "data": {"channel": "live-stream-list"}
      };
      channel!.sink.add(json.encode(subscribeData));
      print('📡 Subscribed to "live-stream-list" channel');
    } catch (e) {
      print('❌ Subscription error: $e');
    }
  }

  // Method to manually refresh live stream list
  Future<void> refreshLiveStreamList() async {
    try {
      final response = await dio.get(
        kLiveStreamListUrl, // You'll need to add this endpoint
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200) {
        homeController.showingLiveStreamList.value =
            response.data['data'] ?? [];
        homeController.sortLiveStreamList(); // Auto sort after refresh
        print("✅ Live stream list refreshed successfully");
      } else {
        print("⚠️ Failed to refresh live stream list: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error refreshing live stream list: $e");
    }
  }

  // Method to sync livestream_callers with current liveCallList
  void syncLivestreamCallers() {
    final streamIndex = homeController.showingLiveStreamList
        .indexWhere((stream) => stream['id'] == streamID.value);

    if (streamIndex != -1) {
      final stream = homeController.showingLiveStreamList[streamIndex];
      if (stream['livestream_callers'] != null) {
        // Update livestream_callers to match current liveCallList
        stream['livestream_callers'] = liveCallList.toList();
        homeController.sortLiveStreamList(); // Auto sort after sync
        homeController.showingLiveStreamList.refresh();
        print('🔄 Synced livestream_callers with liveCallList');
      }
    }
  }

  //------------------------

  bool getUserAudioStatus(int userId) {
    try {
      final user = liveCallList.firstWhere(
            (viewer) {
          final callerId = viewer['caller_id'];
          final profileId = viewer['user']?['id'];
          return callerId.toString() == userId.toString() ||
              profileId.toString() == userId.toString();
        },
        orElse: () => null,
      );

      if (user != null) {
        final audioOnValue = user['audio_on'];

        /// audio_on: 1 = unmute/on, 0 = mute/off.
        final isAudioEnabled =
            audioOnValue == 1 || audioOnValue.toString() == '1';

        return isAudioEnabled;
      } else {
        print('User $userId not found in liveCallList');
        return true;
      }
    } catch (e) {
      print('Error getting user audio status for $userId: $e');
      return true;
    }
  }

  bool getUserVideoStatus(int userId) {
    try {
      final user = liveCallList.firstWhere(
              (viewer) => viewer['caller_id'].toString() == userId.toString(),
          orElse: () => null);

      if (user != null) {
        final videoOnValue = user['video_on'];
        // Convert 1/0 to boolean: 1 = true (enabled), 0 = false (disabled)
        final isVideoEnabled = videoOnValue == 0;
        print(
            'User $userId video status: ${isVideoEnabled ? "enabled" : "disabled"} (value: $videoOnValue)');
        return isVideoEnabled;
      } else {
        print('User $userId not found in liveCallList');
        return true; // Default to true if user not found
      }
    } catch (e) {
      print('Error getting user video status for $userId: $e');
      return true; // Default to true on error
    }
  }

  bool getUserIsOnCall(int userId) {
    try {
      final user = liveCallList.firstWhere(
              (viewer) => viewer['caller_id'].toString() == userId.toString(),
          orElse: () => null);

      if (user != null) {
        print('User $userId is currently on call');
        return true;
      } else {
        print('User $userId is not on call');
        return false; // User not found in liveCallList
      }
    } catch (e) {
      print('Error checking if user $userId is on call: $e');
      return false; // Default to false on error
    }
  }

  Future<void> tryToConnectToViewersListWs() async {
    print('⚡ Trying to connect to Viewer List WS...');
    try {
      if (kWsUrl.isEmpty) {
        print('❌ WebSocket URL is empty, cannot connect to viewers list');
        return;
      }

      final channel = WebSocketChannel.connect(Uri.parse(kWsUrl));
      await channel.ready;

      channel.stream.listen((message) {
        if (message.toString().contains('ping')) {
          try {
            if (channel.closeCode == null) {
              channel.sink.add(json.encode({"event": "pusher:pong"}));
            }
          } catch (e) {
            print('Error sending pong in viewers WS: $e');
          }
          return;
        }
        try {
          final decodedMessage = json.decode(message);
          if (decodedMessage["event"] == "App\\Events\\LiveSteamViewer") {
            // Decode the nested JSON string in the "data" field
            final dataString = decodedMessage["data"];
            final dataMap = json.decode(dataString); // Convert string to Map

            final viewerData = dataMap["data"];

            if (viewerData != null) {
              final action = viewerData["action"];
              final viewerInfo = viewerData["viewer_data"];

              if (action == "viewer_add") {
                // Check if user already exists in the list
                bool userExists = livestreamController.liveViewerList
                    .any((v) => v["id"] == viewerInfo["id"]);

                // Add user only if not already in the list
                print(
                    "Sagor data ${viewerData['viewer_data']['livestream_id']}");
                if (streamID.value.toString() ==
                    viewerData['viewer_data']['livestream_id'].toString()) {
                  newJoinedUserData.value = viewerInfo;
                  newViewersJoinded.value = true;
                  showEntryAnimation();
                  if (!userExists) {
                    livestreamController.liveViewerList.add(viewerInfo);
                    livestreamController.liveViewerList.refresh();
                  }
                }

                // Always show entry animation regardless of whether user was added or already exists
              } else if (action == "viewer_remove") {
                livestreamController.liveViewerList
                    .removeWhere((v) => v["id"] == viewerInfo["id"]);
              }
            }
          }
        } catch (e) {
          print("❌ Error parsing WebSocket message: $e");
        }
      });

      // Subscribe to the live stream viewer channel
      try {
        if (channel.closeCode == null) {
          channel.sink.add(json.encode({
            "event": "pusher:subscribe",
            "data": {"channel": "live-stream-viewer"}
          }));
        }
      } catch (e) {
        print('Error subscribing to live-stream-viewer: $e');
      }
    } catch (e) {
      print('❌ Error connecting to viewers list WebSocket: $e');
    }
  }

  void tryToConnectToCommentsListWs() async {
    try {
      if (kWsUrl.isEmpty) {
        print('❌ WebSocket URL is empty, cannot connect to comments list');
        return;
      }

      final channel = WebSocketChannel.connect(Uri.parse(kWsUrl));
      await channel.ready;
      channel.stream.listen((message) {
        try {
          final decodedMessage = json.decode(message);
          if (decodedMessage['event'] == 'App\\Events\\LiveComment') {
            final data = json.decode(decodedMessage['data']);
            final commentData = {
              'livestream_id': data['data']['livestream_id'],
              'user': data['data']['user'],
              'comment': data['data']['comment'],
              'timestamp': data['data']['timestamp'],
            };

            // Add the comment to the observable list

            if (streamID.value.toString() ==
                commentData['livestream_id'].toString()) {
              commentsList.add(commentData);
            }

            print('comment List $commentsList');
          }

          // Handle emoji sent event
          if (decodedMessage['event'] == 'App\\Events\\EmojiSent') {
            final data = json.decode(decodedMessage['data']);
            final emojiData = {
              'stream_id': data['stream_id'],
              'emoji': data['emoji'],
              'user': data['user'],
              'timestamp': data['timestamp'],
            };

            // Show emoji animation
            handleEmojiAnimation(emojiData);

            print('Emoji received: $emojiData');
          }
        } catch (e) {
          print('Error decoding message: $e');
        }

        // Handle ping messages
        if (message.toString().contains('ping')) {
          try {
            if (channel.closeCode == null) {
              channel.sink.add(json.encode(
                {"event": "pusher:pong"},
              ));
              debugPrint('pong');
            }
          } catch (e) {
            print('Error sending pong to comments channel: $e');
          }
        }
      });

      // Subscribe to the live-comment channel
      try {
        if (channel.closeCode == null) {
          channel.sink.add(json.encode(
            {
              "event": "pusher:subscribe",
              "data": {"channel": "live-comment"}
            },
          ));
        }
      } catch (e) {
        print('Error subscribing to live-comment channel: $e');
      }
    } catch (e) {
      print('❌ Error connecting to comments list WebSocket: $e');
    }
  }

  void tryToConnectToCallListWs() async {
    try {
      if (kWsUrl.isEmpty) {
        print('❌ WebSocket URL is empty, cannot connect to call list');
        return;
      }

      final channel = WebSocketChannel.connect(Uri.parse(kWsUrl));
      await channel.ready;

      channel.stream.listen((message) async {
        try {
          final decodedMessage = json.decode(message);
          if (decodedMessage['event'] == 'App\\Events\\LiveSteamCall') {
            final data = json.decode(decodedMessage['data']);
            final callData = data['data'];

            if (streamID.value == callData['livestream_id']) {
              final int callerId = callData['caller_id'];
              final String callStatus = callData['call_status'];

              if (callStatus == 'accepted') {
                //pk call management
                if (callData['call_type'] == "pk") {
                  print('I am from pk');
                  isPkRunning.value = true;
                  //for video audio call
                  pendingCall
                      .removeWhere((call) => call['caller_id'] == callerId);
                  // ✅ Prevent duplicate addition
                  if (!liveCallList
                      .any((call) => call['caller_id'] == callerId)) {
                    liveCallList.add(callData);
                  }
                  if (authController.userProfile.value.user!.id == callerId) {
                    if (callData['call_type'] == "pk") {
                      await _agoraService.engine!.enableVideo();
                    }
                    await _agoraService.engine!.enableAudio();
                  }

                  // ✅ Also update showingLiveStreamList
                  final streamIndex = homeController.showingLiveStreamList
                      .indexWhere((stream) => stream['id'] == streamID.value);

                  if (streamIndex != -1) {
                    final stream =
                    homeController.showingLiveStreamList[streamIndex];
                    if (stream['livestream_callers'] != null) {
                      final existingCallerIndex =
                      (stream['livestream_callers'] as List).indexWhere(
                              (caller) => caller['caller_id'] == callerId);

                      if (existingCallerIndex == -1) {
                        (stream['livestream_callers'] as List).add(callData);
                        homeController
                            .sortLiveStreamList(); // Auto sort after caller added
                        homeController.showingLiveStreamList.refresh();
                      }
                    }
                  }
                } else {
                  //for video audio call
                  pendingCall
                      .removeWhere((call) => call['caller_id'] == callerId);
                  // ✅ Prevent duplicate addition
                  if (!liveCallList
                      .any((call) => call['caller_id'] == callerId)) {
                    liveCallList.add(callData);
                  }
                  if (authController.userProfile.value.user!.id == callerId) {
                    if (callData['call_type'] == "video") {
                      await _agoraService.engine!.enableVideo();
                    }
                    await _agoraService.engine!.enableAudio();
                  }

                  // ✅ Also update showingLiveStreamList
                  final streamIndex = homeController.showingLiveStreamList
                      .indexWhere((stream) => stream['id'] == streamID.value);

                  if (streamIndex != -1) {
                    final stream =
                    homeController.showingLiveStreamList[streamIndex];
                    if (stream['livestream_callers'] != null) {
                      final existingCallerIndex =
                      (stream['livestream_callers'] as List).indexWhere(
                              (caller) => caller['caller_id'] == callerId);

                      if (existingCallerIndex == -1) {
                        (stream['livestream_callers'] as List).add(callData);
                        homeController
                            .sortLiveStreamList(); // Auto sort after caller added
                        homeController.showingLiveStreamList.refresh();
                      }
                    }
                  }
                }
              } else if (callStatus == 'pending') {
                //pending for pk live
                if (callData['call_type'] == "pk") {
                  pendingCall.assignAll([...pendingCall, callData]);
                  if (authController.userProfile.value.user!.id == callerId) {
                    _showCallRequestPopup(callData, rtcEngine: null);
                  }
                } else {
                  //pending for video live
                  pendingCall.assignAll([...pendingCall, callData]);
                  if (livestreamController.isBroadcaster.value) {
                    _showCallRequestPopup(callData, rtcEngine: null);
                  }
                }
              } else if (callStatus == 'canceled' || callStatus == 'rejected') {
                // Stop audio/video for the removed caller

                pendingCall
                    .removeWhere((call) => call['caller_id'] == callerId);
                liveCallList
                    .removeWhere((call) => call['caller_id'] == callerId);

                if (isPkRunning.value && callData['call_type'] == "pk") {
                  isPkRunning.value = false;
                }
                if (authController.userProfile.value.user!.id == callerId) {
                  await _agoraService.engine!
                      .setClientRole(role: ClientRoleType.clientRoleAudience);
                  await _agoraService.engine!.muteLocalAudioStream(true);
                  await _agoraService.engine!.muteLocalVideoStream(true);
                }

                // Also remove from showingLiveStreamList's livestream_callers
                final streamIndex = homeController.showingLiveStreamList
                    .indexWhere((stream) => stream['id'] == streamID.value);
                if (streamIndex != -1) {
                  final stream =
                  homeController.showingLiveStreamList[streamIndex];
                  if (stream['livestream_callers'] != null) {
                    (stream['livestream_callers'] as List).removeWhere(
                            (caller) => caller['caller_id'] == callerId);
                    homeController
                        .sortLiveStreamList(); // Auto sort after caller removed
                    homeController.showingLiveStreamList.refresh();
                    print(
                        '🗑️ Removed caller $callerId from showingLiveStreamList');
                  }
                }
              }

              liveCallList.refresh(); // Ensure UI updates
              pendingCall.refresh(); // Ensure UI updates
            }
          }
        } catch (e) {
          print('Error decoding message: $e');
        }

        // Handle ping messages
        if (message.toString().contains('ping')) {
          try {
            channel.sink.add(json.encode({"event": "pusher:pong"}));
            debugPrint('pong');
          } catch (e) {
            print('Error sending pong to call list channel: $e');
          }
        }
      });

      // Subscribe to the live-stream-call channel
      try {
        channel.sink.add(json.encode({
          "event": "pusher:subscribe",
          "data": {"channel": "live-stream-call"}
        }));
      } catch (e) {
        print('Error subscribing to live-stream-call channel: $e');
      }
    } catch (e) {
      print('❌ Error connecting to call list WebSocket: $e');
    }
  }

  /// Show call request popup for broadcasters
  void _showCallRequestPopup(
      Map<String, dynamic> callData, {
        required RtcEngine? rtcEngine,
        String? popupKey,
      }) {
    /// Old channel/new unified channel duita thekei popup ashte pare.
    /// Tai popup show-er age user data safe normalize.
    _normalizeUnifiedCallUser(callData, callData);

    if (Get.context == null) {
      if (popupKey != null) _activeCallPopupKeys.remove(popupKey);
      print('⚠️ No context available for showing call request popup');
      return;
    }

    try {
      if (Get.isDialogOpen == true) {
        if (popupKey != null) _activeCallPopupKeys.remove(popupKey);
        print('ℹ️ Dialog already open, call popup skipped');
        return;
      }

      final LivestreamController liveController =
      Get.find<LivestreamController>();

      final callerUser = callData['user'] is Map ? Map<String, dynamic>.from(callData['user']) : <String, dynamic>{};
      final callerName = (callerUser['name'] ??
          callData['name'] ??
          callData['caller_name'] ??
          callData['username'] ??
          'User')
          .toString();
      final callerId = callData['caller_id'] ?? callData['user_id'] ?? callerUser['id'];
      final streamId = callData['livestream_id'] ?? callData['stream_id'] ?? streamID.value;

      showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) => CallRequestPopup(
          callData: callData,
          onAccept: () async {
            Navigator.of(context).pop();

            if (popupKey != null) {
              _activeCallPopupKeys.remove(popupKey);
              _handledCallPopupKeys.add(popupKey);
            }

            await liveController.tryToAcceptCall(
              streamId: streamId,
              userId: callerId,
            );

            /// Accept korar sathe sathe call list refresh. Event late ashleo
            /// broadcaster side-e video/audio card show hobe.
            try {
              final int? sid = int.tryParse(streamId.toString());
              await liveController.tryToGetCallList(streamId: sid ?? streamId);
              liveCallList.refresh();
              pendingCall.refresh();
              syncLivestreamCallers();
            } catch (e) {
              print('❌ Refresh after accept failed: $e');
            }

            Fluttertoast.showToast(
              msg: '$callerName has been added to the live stream',
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          },
          onReject: () async {
            Navigator.of(context).pop();

            if (popupKey != null) {
              _activeCallPopupKeys.remove(popupKey);
              _handledCallPopupKeys.remove(popupKey);
            }

            _clearStaleCallStateForUser(
              callerId: callerId,
              streamId: streamId,
              removeAcceptedCall: false,
              closePopupIfOpen: false,
              reason: 'popup_reject',
            );

            await liveController.tryToRejectCall(
              streamId: streamId,
              userId: callerId,
            );

            pendingCall.removeWhere(
                  (call) => call['caller_id'].toString() == callerId.toString(),
            );
            pendingCall.refresh();

            Fluttertoast.showToast(
              msg: '$callerName\\',
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          },
        ),
      );

      print('✅ Call request popup shown for caller: $callerId');
    } catch (e) {
      if (popupKey != null) _activeCallPopupKeys.remove(popupKey);
      print('❌ Error showing call request popup: $e');
      print('📝 Call request added to pending list without popup');
    }
  }

  //action handled here
  // Monitor livestream moderation events (kick out,audio toggle, Video Toggle etc.)
  void tryToConnectToModerationWs() async {
    try {
      if (kWsUrl.isEmpty) {
        print('❌ WebSocket URL is empty, cannot connect to moderation');
        return;
      }

      final channel = WebSocketChannel.connect(Uri.parse(kWsUrl));
      await channel.ready;

      channel.stream.listen((message) {
        try {
          final decodedMessage = json.decode(message);

          // Handle kick out event
          if (decodedMessage['event'] == 'App\\Events\\LiveSteamModeration') {
            print('🔔 LiveSteamModeration event received');
            final data = json.decode(decodedMessage['data']);
            final moderationData = data['data'] ?? data;

            print('🔔 Moderation action: ${moderationData['action']}');
            print('🔔 Full moderation data: $moderationData');

            switch (moderationData['action']) {
              case 'kickout':
                print('🚫 Processing kickout action...');
                _handleKickOut(moderationData);
                break;

              case 'audio_toggle':
                _handleAudioToggle(moderationData);
                break;
              case 'video_toggle':
                _handleVideoToggle(moderationData);
                break;

              case 'live_stream_ended':
                print(
                    '🛑 Live stream ended for ID: ${moderationData['livestream_id']}');

                homeController.showingLiveStreamList.removeWhere(
                      (stream) => stream['id'] == moderationData['livestream_id'],
                );

                homeController
                    .sortLiveStreamList(); // Auto sort after stream removed
                homeController.showingLiveStreamList
                    .refresh(); // ✅ force UI update
                _handleLiveStreamEnded(moderationData);
                break;

              default:
                print('Unknown moderation action: ${moderationData['action']}');
                break;
            }
          }
        } catch (e) {
          print('Error decoding moderation message: $e');
        }

        // Handle ping messages
        if (message.toString().contains('ping')) {
          channel.sink.add(json.encode({"event": "pusher:pong"}));
          debugPrint('pong');
        }
      });

      // Subscribe to moderation channel
      channel.sink.add(json.encode({
        "event": "pusher:subscribe",
        "data": {"channel": "live-stream-moderation"}
      }));
    } catch (e) {
      print('❌ Error in moderation WebSocket: $e');
    }
  }

  //end action handled here

  // Method to fetch initial gift total from backend
  Future<void> fetchInitialGiftTotal({dynamic streamId}) async {
    try {
      final int sid = int.tryParse((streamId ?? streamID.value).toString()) ?? 0;

      if (sid <= 0) {
        print('Skipping gift total fetch - invalid stream ID: $sid');
        return;
      }

      final response = await dio.get(kGetTotalGiftCoins(sid));
      if (response.statusCode == 200) {
        final data = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};

        final dynamic coinRaw = data['total_gift_coins'] ??
            data['total_coins'] ??
            data['gifts_coins'] ??
            data['gift_amount'] ??
            data['stream_coins'];

        final int coins = _toInt(coinRaw);

        /// Do not let a partial/empty response reset a live that already has coins.
        if (coins > 0 || totalGiftCoins.value <= 0) {
          totalGiftCoins.value = coins;
        }

        // Load user gift counts if available
        if (data['user_gift_counts'] != null) {
          userGiftCounts.value = Map<String, Map<String, dynamic>>.from(
            data['user_gift_counts'].map(
                  (key, value) => MapEntry(
                key.toString(),
                Map<String, dynamic>.from(value),
              ),
            ),
          );
        }

        print('Initial gift total loaded: ${totalGiftCoins.value}');
        print('Initial user gift counts loaded: $userGiftCounts');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        print('Livestream not found for ID: ${streamId ?? streamID.value}');
      } else {
        print('Error fetching initial gift total: $e');
      }
    }
  }

  bool _looksLikeViewerOnlyPayloadForCoin(
      Map<String, dynamic> payload,
      Map<String, dynamic> data,
      ) {
    /// viewer/user join payload may contain user.balance/coins/gifts_coins = 0.
    /// That is NOT the live received gift total, so never sync live total from it.
    final action = (payload['action_type'] ?? payload['action'] ?? '').toString().toLowerCase();

    if (action.contains('viewer') ||
        action.contains('join_live') ||
        action.contains('user_joined')) {
      return true;
    }

    if ((payload.containsKey('viewer') || payload.containsKey('viewer_data')) &&
        !payload.containsKey('livestream') &&
        !payload.containsKey('live_stream')) {
      return true;
    }

    if ((data.containsKey('viewer_id') || data.containsKey('is_active')) &&
        !data.containsKey('total_gift_coins') &&
        !data.containsKey('gift_amount') &&
        !data.containsKey('stream_coins')) {
      return true;
    }

    return false;
  }

  void syncGiftCoinsFromPayload(Map<String, dynamic> payload, {String source = 'payload'}) {
    try {
      final Map<String, dynamic> data = payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'])
          : payload['livestream'] is Map
          ? Map<String, dynamic>.from(payload['livestream'])
          : payload['live_stream'] is Map
          ? Map<String, dynamic>.from(payload['live_stream'])
          : Map<String, dynamic>.from(payload);

      if (_looksLikeViewerOnlyPayloadForCoin(payload, data)) {
        print('🪙 Gift coin sync skipped viewer-only payload from $source');
        return;
      }

      final bool hasLiveCoinKey = data.containsKey('total_gift_coins') ||
          data.containsKey('total_coins') ||
          data.containsKey('gift_amount') ||
          data.containsKey('stream_coins') ||
          data.containsKey('received_coins');

      /// Do NOT treat data['gifts_coins'] alone as live total when it comes
      /// from viewer/user object. User.gifts_coins is often 0 for late viewers.
      final bool hasOnlyUserGiftCoins =
          data.containsKey('gifts_coins') && !hasLiveCoinKey &&
              (data.containsKey('id') || data.containsKey('user_id') || data.containsKey('profile_image'));

      if (!hasLiveCoinKey && hasOnlyUserGiftCoins) {
        print('🪙 Gift coin sync skipped user.gifts_coins from $source');
        return;
      }

      final dynamic coinRaw = data['total_gift_coins'] ??
          data['total_coins'] ??
          data['gift_amount'] ??
          data['stream_coins'] ??
          data['received_coins'] ??
          data['gifts_coins'];

      if (coinRaw == null) return;

      final int coins = _toInt(coinRaw);

      /// Partial/late response must not reset old total to 0.
      if (coins == 0 && totalGiftCoins.value > 0) {
        print('🪙 Gift coins zero reset ignored from $source, keep=${totalGiftCoins.value}');
        return;
      }

      if (coins > 0 || totalGiftCoins.value <= 0) {
        totalGiftCoins.value = coins;
        print('🪙 Gift coins synced from $source => $coins');
      }
    } catch (e) {
      print('⚠️ syncGiftCoinsFromPayload error => $e');
    }
  }

  final isGiftAnimationShowing = false.obs;

  final giftsData = {}.obs; // Observable to store received gifts

  // Gift tracking variables
  final totalGiftCoins = 0.obs; // Total coins from all gifts
  final userGiftCounts =
      <String, Map<String, dynamic>>{}.obs; // Individual user gift counts

  // Broadcaster status monitoring
  final isBroadcasterOnline = true.obs;
  final isStreamEnded = false.obs;
  final streamEndReason = ''.obs;
  // show animation when user joined the stream

  void showEntryAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      newViewersJoinded.value = false;
      newJoinedUserData.value = {};
      newViewerAction.value = 'join';
    });
  }

  void showGiftsAnimation() {
    Future.delayed(Duration(seconds: 5), () {
      isGiftAnimationShowing.value = false;
      giftsData.value = {};
    });
  }

  // Show gift animation
  void showGiftAnimation(Map<String, dynamic> giftData) {
    try {
      // You can implement gift animation logic here
      // For now, just print the gift data
      final giftName = giftData["gift"]["name"] ?? "Unknown Gift";
      final senderName = giftData["sender"]["name"] ?? "Anonymous";
      final coins = giftData["gift"]["coins"] ?? 0;

      print('🎁 Gift Animation: $senderName sent $giftName ($coins coins)');

      // You could show a toast, overlay animation, or update UI here
      Get.snackbar(
        '🎁 Gift Received!',
        '$senderName sent $giftName ($coins coins)',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.purple.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      print("❌ Error showing gift animation: $e");
    }
  }

  // Red Packet Methods
  void hideRedPacket() {
    redPacketVisible.value = false;
    currentRedPacket.value = {};
    _cancelRedPacketTimer();
  }

  // Global Red Packet Methods
  void hideGlobalRedPacket() {
    globalRedPacketVisible.value = false;
    globalCurrentRedPacket.value = {};
    _cancelGlobalRedPacketTimer();
  }

  void _startRedPacketTimer(String redPacketId, int durationMinutes) {
    // Cancel any existing timer
    _cancelRedPacketTimer();

    // Start timer for auto-refund using dynamic duration
    redPacketTimer = Timer(Duration(minutes: durationMinutes), () {
      _autoRefundRedPacket(redPacketId);
    });
  }

  void _cancelRedPacketTimer() {
    redPacketTimer?.cancel();
    redPacketTimer = null;
  }

  void _startGlobalRedPacketTimer(String redPacketId, int durationMinutes) {
    // Cancel any existing global timer
    _cancelGlobalRedPacketTimer();

    // Start timer for auto-hide using dynamic duration
    globalRedPacketTimer = Timer(Duration(minutes: durationMinutes), () {
      hideGlobalRedPacket();
      print('🧧 Global Red Packet auto-hidden after $durationMinutes minutes');
    });
  }

  void _cancelGlobalRedPacketTimer() {
    globalRedPacketTimer?.cancel();
    globalRedPacketTimer = null;
  }

  Future<void> _autoRefundRedPacket(String redPacketId) async {
    try {
      final dio = Dio();
      final authController = Get.find<AuthController>();

      final response = await dio.post(
        '$kDomainUrl/api/red-packets/refund/$redPacketId',
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${authController.userProfile.value.token}",
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Red packet auto-refunded successfully");
        hideRedPacket();

        // Show refund notification
        Get.snackbar(
          "🧧 Red Packet Expired",
          "Red packet has been refunded to sender",
          backgroundColor: Colors.orange.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      print("❌ Error auto-refunding red packet: $e");
    }
  }

  void setRedPacketCallbacks({
    Function(Map<String, dynamic>)? onReceived,
    Function(Map<String, dynamic>)? onCollected,
  }) {
    onRedPacketReceived = onReceived;
    onRedPacketCollected = onCollected;
  }

  // Global Red Packet Collection Method
  Future<bool> collectGlobalRedPacket() async {
    try {
      if (globalCurrentRedPacket.value.isEmpty) {
        print("❌ No global red packet available to collect");
        return false;
      }

      final redPacketId = globalCurrentRedPacket.value['id'].toString();
      final dio = Dio();
      final authController = Get.find<AuthController>();

      final response = await dio.post(
        '$kDomainUrl/api/red-packets/collect/$redPacketId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        hideGlobalRedPacket();

        // Show success message
        Get.snackbar(
          "🧧 Red Packet Collected!",
          "You have successfully collected the red packet",
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );

        return true;
      } else {
        print("⚠️ Failed to collect global red packet: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error collecting global red packet: $e");

      // Show error message
      Get.snackbar(
        "❌ Collection Failed",
        "Failed to collect red packet. Please try again.",
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );

      return false;
    }
  }

  void clearRedPacketCallbacks() {
    onRedPacketReceived = null;

    onRedPacketCollected = null;
    _cancelRedPacketTimer();
  }

  // Emoji Animation Methods
  void handleEmojiAnimation(Map<String, dynamic> emojiData) {
    try {
      // Add emoji to animation list
      emojiAnimations.add({
        'emoji': emojiData['emoji'],
        'user': emojiData['user'],
        'timestamp': emojiData['timestamp'],
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      // Show animation
      showEmojiAnimation.value = true;

      // Remove emoji after 5 seconds
      Timer(Duration(seconds: 5), () {
        if (emojiAnimations.isNotEmpty) {
          emojiAnimations.removeAt(0);
        }
        if (emojiAnimations.isEmpty) {
          showEmojiAnimation.value = false;
        }
      });

      print('✅ Emoji animation started: ${emojiData['emoji']}');
    } catch (e) {
      print('❌ Error showing emoji animation: $e');
    }
  }


  /// New audio room open hole old room-er comments/entry/gift/seat data clear.
  /// Same stream/minimize return hole clear korbe na.
  void resetAudioRoomStateForStream({
    required int newStreamId,
    bool force = false,
  }) {
    if (newStreamId == 0) return;

    if (!force && activeAudioStreamId.value == newStreamId) {
      print('ℹ️ Same audio stream, room state not reset: $newStreamId');
      return;
    }

    print('🧹 Reset audio room state => old:${activeAudioStreamId.value} new:$newStreamId');

    activeAudioStreamId.value = newStreamId;
    streamID.value = newStreamId;

    newViewersJoinded.value = false;
    newJoinedUserData.value = {};
    newViewerAction.value = 'join';

    commentsList.clear();
    giftMessagesList.clear();
    processedGiftIds.clear();
    processedImogiIds.clear();
    liveImogiAnimations.clear();
    audioMutedUserMap.clear();

    giftsData.value = {};
    isGiftAnimationShowing.value = false;

    liveCallList.clear();
    pendingCall.clear();

    lockedSeatMap.clear();

    liveMusicStatus.value = 'stopped';
    liveMusicName.value = '';
    liveMusicHostId.value = 0;

    liveYoutubeStatus.value = 'stopped';
    liveYoutubeUrl.value = '';
    liveYoutubeVideoId.value = '';
    liveYoutubeHostId.value = 0;

    try {
      livestreamController.liveViewerList.clear();
    } catch (_) {}

    commentsList.refresh();
    giftMessagesList.refresh();
    liveCallList.refresh();
    pendingCall.refresh();
    lockedSeatMap.refresh();
    audioMutedUserMap.refresh();
  }

  /// clear user data after remove/out from the stream.
  /// This clears UI only. Seat lock map is NOT changed here.
  Future<void> clearSpecificUserStreamData({
    required String userId,
    bool rejectCallIfInCallList = true,
  }) async {
    print('🧹 clearSpecificUserStreamData userId=$userId rejectCallIfInCallList=$rejectCallIfInCallList');

    final userIdInt = int.tryParse(userId) ?? 0;

    bool sameCall(dynamic call) {
      if (call is! Map) return false;
      final callerId = call['caller_id'];
      final nestedUserId = call['user'] is Map ? call['user']['id'] : null;
      final userIdField = call['user_id'];

      return callerId.toString() == userId ||
          nestedUserId.toString() == userId ||
          userIdField.toString() == userId ||
          callerId == userIdInt ||
          nestedUserId == userIdInt ||
          userIdField == userIdInt;
    }

    bool sameViewer(dynamic viewer) {
      if (viewer is! Map) return false;
      final nestedUserId = viewer['user'] is Map ? viewer['user']['id'] : null;
      final viewerId = viewer['viewer_id'];
      final directId = viewer['id'];
      final userIdField = viewer['user_id'];

      return nestedUserId.toString() == userId ||
          viewerId.toString() == userId ||
          userIdField.toString() == userId ||
          directId.toString() == userId ||
          nestedUserId == userIdInt ||
          viewerId == userIdInt ||
          userIdField == userIdInt ||
          directId == userIdInt;
    }

    final leavingCalls = liveCallList.where(sameCall).whereType<Map>().toList();
    final userWasInCallList = leavingCalls.isNotEmpty;

    /// Do NOT clear lockedSeatMap here.
    /// If a user leaves an occupied seat, only liveCallList/pendingCall should be cleared.

    if (authController.userProfile.value.user?.id == userIdInt) {
      try {
        final agoraService = AgoraService();
        livestreamController.mute.value = false;
        if (agoraService.engine != null) {
          await agoraService.engine!.enableAudio();
          await agoraService.engine!.enableLocalAudio(true);
          await agoraService.engine!.muteLocalAudioStream(true);
          await agoraService.engine!.muteLocalVideoStream(true);
          try {
            await agoraService.engine!.updateChannelMediaOptions(
              const ChannelMediaOptions(
                clientRoleType: ClientRoleType.clientRoleAudience,
                publishMicrophoneTrack: false,
                autoSubscribeAudio: true,
              ),
            );
          } catch (e) {
            print('⚠️ media option update skipped while clearing current user: $e');
          }
          await agoraService.engine!.setClientRole(
            role: ClientRoleType.clientRoleAudience,
          );
          print('🔇 Current user cleared from seat; local media muted and old mute state reset: $userIdInt');
        }
      } catch (e) {
        print('⚠️ Error muting local media for user $userIdInt: $e');
      }
    }

    liveCallList.removeWhere(sameCall);
    liveCallList.refresh();

    pendingCall.removeWhere(sameCall);
    pendingCall.refresh();

    livestreamController.liveViewerList.removeWhere(sameViewer);
    livestreamController.liveViewerList.refresh();

    newViewersJoinded.value = false;
    newJoinedUserData.value = {};

    if (rejectCallIfInCallList && userWasInCallList && streamID.value != 0) {
      try {
        await livestreamController.tryToRejectCall(
          streamId: streamID.value,
          userId: userIdInt,
        );
      } catch (e) {
        print('⚠️ Reject call skipped/failed: $e');
      }
    }

    print('✅ User cleared from live local state => user:$userId callsWas:$userWasInCallList');
  }

  // Handle kick out moderation action
  void _handleKickOut(Map<String, dynamic> moderationData) {
    try {
      final kickedUserId = moderationData['user_id'];
      final livestreamId = moderationData['livestream_id'];
      final remainingMinutes = moderationData['remaining_minutes'] ?? 15;

      // Check if current user is the one being kicked
      final currentUserId =
      Get.find<AuthController>().userProfile.value.user?.id.toString();

      if (currentUserId == kickedUserId &&
          streamID.value.toString() == livestreamId) {
        // Current user is being kicked outda

        Get.offAll(BottomnavView());

        // Show kick out dialog
        Get.dialog(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red),
                SizedBox(width: 8),
                Text('Kicked Out'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('You have been removed from this live stream.'),
                SizedBox(height: 8),
                Text(
                  'You cannot rejoin for $remainingMinutes minutes.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                },
                child:
                Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          barrierDismissible: false,
        );
        clearSpecificUserStreamData(userId: kickedUserId);
      } else {
        // Another user is being kicked out, remove from lists
        print('🚫 User $kickedUserId kicked out from livestream $livestreamId');
        clearSpecificUserStreamData(userId: kickedUserId);
      }
    } catch (e) {
      print('❌ Error handling kick out: $e');
    }
  }

  // Handle audio toggle moderation action
  bool _audioOffValue(dynamic value) {
    final v = value?.toString().toLowerCase().trim() ?? '';
    return v == '0' ||
        v == 'false' ||
        v == 'no' ||
        v == 'off' ||
        v == 'mute' ||
        v == 'muted';
  }

  bool _audioOnValue(dynamic value) {
    final v = value?.toString().toLowerCase().trim() ?? '';
    return v == '1' ||
        v == 'true' ||
        v == 'yes' ||
        v == 'on' ||
        v == 'unmute' ||
        v == 'unmuted';
  }

  int _normalizeAudioOn(Map<String, dynamic> data) {
    final mutedRaw = data['is_muted'] ??
        data['muted'] ??
        data['is_muted_by_host'] ??
        data['mute_status'];
    final audioRaw = data['audio_on'] ??
        data['is_audio_on'] ??
        data['mic_on'] ??
        data['microphone_on'] ??
        data['status'] ??
        data['action'];

    if (_audioOffValue(mutedRaw) == false &&
        (mutedRaw == true || mutedRaw == 1 || _audioOnValue(mutedRaw))) {
      return 0;
    }

    if (_audioOffValue(audioRaw)) return 0;
    if (_audioOnValue(audioRaw)) return 1;

    /// If no audio state exists in event, keep old state instead of forcing unmute.
    return -1;
  }

  Future<void> _handleAudioToggle(Map<String, dynamic> moderationData) async {
    try {
      final data = moderationData['data'] is Map
          ? Map<String, dynamic>.from(moderationData['data'])
          : Map<String, dynamic>.from(moderationData);

      final userId = int.tryParse(
        (data['user_id'] ??
            data['caller_id'] ??
            data['id'] ??
            data['uid'] ??
            '')
            .toString(),
      ) ??
          0;

      if (userId == 0) {
        print('⚠️ audio toggle user id missing: $moderationData');
        return;
      }

      final int normalizedAudioOn = _normalizeAudioOn(data);

      final callIndex = liveCallList.indexWhere((call) {
        if (call is! Map) return false;
        final callerId = call['caller_id'];
        final profileId = call['user'] is Map ? call['user']['id'] : null;
        final userIdField = call['user_id'];
        return callerId.toString() == userId.toString() ||
            profileId.toString() == userId.toString() ||
            userIdField.toString() == userId.toString();
      });

      if (callIndex != -1) {
        final old = liveCallList[callIndex] is Map
            ? Map<String, dynamic>.from(liveCallList[callIndex])
            : <String, dynamic>{};

        final int oldAudioOn = _normalizeAudioOn(old) == -1
            ? (old['audio_on']?.toString() == '0' ? 0 : 1)
            : _normalizeAudioOn(old);

        final int audioOn = normalizedAudioOn == -1 ? oldAudioOn : normalizedAudioOn;

        old['audio_on'] = audioOn;
        old['is_audio_on'] = audioOn;
        old['is_muted'] = audioOn == 1 ? 0 : 1;
        old['is_muted_by_host'] = audioOn == 1 ? 0 : 1;

        liveCallList[callIndex] = old;
        liveCallList.refresh();

        print('✅ Unified audio toggle updated => user:$userId audio_on:$audioOn');

        final currentUserId =
            authController.userProfile.value.user?.id?.toInt() ?? 0;

        if (userId == currentUserId && _agoraService.engine != null) {
          await _agoraService.engine!.muteLocalAudioStream(audioOn == 0);
          print('🎙️ Local mic ${audioOn == 1 ? "unmuted" : "muted"}');
        }
      } else {
        /// Late audience may receive audio state before seat list is hydrated.
        /// If the event has no explicit audio value, do not create a fake unmuted row.
        if (normalizedAudioOn == -1) {
          print('ℹ️ Audio toggle ignored for missing row because audio state is partial => user:$userId');
          return;
        }

        final int audioOn = normalizedAudioOn;
        liveCallList.add({
          'caller_id': userId,
          'user_id': userId,
          'audio_on': audioOn,
          'is_audio_on': audioOn,
          'is_muted': audioOn == 1 ? 0 : 1,
          'is_muted_by_host': audioOn == 1 ? 0 : 1,
          'call_status': 'accepted',
          'user': data['user'] is Map
              ? Map<String, dynamic>.from(data['user'])
              : {
            'id': userId,
            'user_id': userId,
            'name': data['name'] ?? data['user_name'] ?? 'User $userId',
            'profile_image': data['profile_image'] ?? '',
            'level': data['level'] ?? 0,
          },
        });
        liveCallList.refresh();
        print('ℹ️ Audio toggle inserted missing call row => user:$userId audio_on:$audioOn');
      }
    } catch (e) {
      print('❌ Error handling audio toggle: $e');
    }
  }

  // Handle video toggle moderation action
  Future<void> _handleVideoToggle(Map<String, dynamic> moderationData) async {
    try {
      final userId = int.parse(moderationData['user_id']);
      final videoOnValue = moderationData['video_on'] ?? 0;

      // Update live call list - Convert both to string for comparison
      final callIndex = liveCallList.indexWhere(
            (call) => call['caller_id'].toString() == userId.toString(),
      );

      if (callIndex != -1) {
        final isVideoOn = websocketController.getUserVideoStatus(userId);

        // Toggle the video state (if currently on, turn off; if off, turn on)
        final newVideoState = !isVideoOn;
        // If it's current user, also update local Agora engine
        final currentUserId =
            authController.userProfile.value.user?.id?.toInt() ?? 0;
        if (userId == currentUserId && _agoraService.engine != null) {
          await _agoraService.engine!.enableLocalVideo(!newVideoState);
          print(
              '📹 Local Agora video ${newVideoState ? "enabled" : "disabled"}');
        }

        liveCallList[callIndex]['video_on'] =
        videoOnValue ? 1 : 0; // Store as 1/0
        liveCallList.refresh();
      } else {
        print('⚠️ User $userId not found in live call list');
      }
    } catch (e) {
      print('❌ Error handling video toggle: $e');
    }
  }

  // Handle live stream ended moderation action
  void _handleLiveStreamEnded(Map<String, dynamic> moderationData) {
    try {
      final livestreamId = moderationData['livestream_id'];
      final joinedUsers = moderationData['joined_users'] ?? [];
      final message = moderationData['message'] ?? 'Live stream has ended';

      // Check if current user is in the joined users list
      final currentUserId =
          Get.find<AuthController>().userProfile.value.user?.id;

      // Check if current user was in this livestream
      final livestreamIdInt = int.tryParse(livestreamId.toString()) ?? 0;
      final isUserInList = joinedUsers.contains(currentUserId);
      final isCorrectStream = streamID.value == livestreamIdInt;

      if (!livestreamController.isBroadcaster.value &&
          isUserInList &&
          isCorrectStream) {
        // Reset stream-related data
        isStreamEnded.value = true;
        isBroadcasterOnline.value = false;

        // Show a more professional live ended dialog
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.live_tv, color: Colors.red, size: 32),
                ),
                SizedBox(width: 12),
                Text(
                  'Live Stream Ended',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Icon(Icons.home, color: Colors.blueAccent, size: 40),
                SizedBox(height: 12),
                Text(
                  'You will be redirected to the home page.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Get.back(); // Close dialog
                    _redirectToBottomNav();
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );

        // Auto-redirect after 3 seconds if user doesn't click OK
        Future.delayed(Duration(seconds: 3), () {
          if (Get.isDialogOpen == true) {
            Get.back(); // Close dialog
            _redirectToBottomNav();
          }
        });
      } else if (livestreamController.isBroadcaster.value && isCorrectStream) {
        // Host nijer live end korle popup show korbo na. Smoothly end page/home route-e jabe.
        isStreamEnded.value = true;
        isBroadcasterOnline.value = false;
        try {
          _agoraService.engine?.leaveChannel();
        } catch (_) {}
        _redirectToBottomNav();
        return;

        // Show a more professional live ended dialog
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.live_tv, color: Colors.red, size: 32),
                ),
                SizedBox(width: 12),
                Text(
                  'Stream Removed',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Icon(Icons.home, color: Colors.blueAccent, size: 40),
                SizedBox(height: 12),
                Text(
                  'Your stream has been removed by admin.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Get.back(); // Close dialog
                    _redirectToBottomNav();
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );

        // Auto-redirect after 3 seconds if user doesn't click OK
        Future.delayed(Duration(seconds: 3), () {
          if (Get.isDialogOpen == true) {
            Get.back(); // Close dialog
            _redirectToBottomNav();
          }
        });
      } else {
        // Current user was not in this livestream, just log
        print(
            'ℹ️ Live stream $livestreamId ended, but current user was not affected');
      }
    } catch (e) {
      print('❌ Error handling live stream ended: $e');
    }
  }

  // Redirect to bottom navigation (home page)
  void _redirectToBottomNav() {
    try {
      // Close any open dialogs
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.offAll(BottomnavView(),
          transition: Transition.cupertino,
          duration: Duration(milliseconds: 400));

      // Reset stream data
      streamID.value = 1;
      livestreamController.liveViewerList.clear();
      liveCallList.clear();
      pendingCall.clear();
    } catch (e) {
      print('❌ Error redirecting to bottom nav: $e');
      // Fallback - just go back
      Get.back();
    }
  }

// brodecaster controller
  final broadcasterWebsocket = WebSocketChannel.connect(Uri.parse(kWsUrl));
  void tryToConnectToBroadcasterWs() async {
    try {
      if (kWsUrl.isEmpty) {
        print('❌ WebSocket URL is empty, cannot connect to comments list');
        return;
      }

      await broadcasterWebsocket.ready;

      // Subscribe to the live-comment channel
      try {
        if (broadcasterWebsocket.closeCode == null) {
          broadcasterWebsocket.sink.add(json.encode(
            {
              "event": "pusher:subscribe",
              "data": {"channel": "livestream-$streamID"}
            },
          ));

          // ✅ Print after successful subscription attempt
          print(
              '✅ Connected and subscribed to livestream-$streamID WebSocket channel');
        }
      } catch (e) {
        print('❌ Error subscribing to live-comment channel: $e');
      }
    } catch (e) {
      print('❌ Error connecting to comments list WebSocket: $e');
    }
  }


  // ========================================================================
  // ✅ NEW SINGLE EVENT WEBSOCKET SYSTEM
  // Backend event: LiveStreamEvent
  // Payload key: action_type
  // ========================================================================

  WebSocketChannel? liveStreamEventChannel;
  Timer? _unifiedReconnectTimer;
  bool _isConnectingUnifiedWs = false;

  /// Prevent duplicate call popup for same caller/stream/call type.
  /// Pending event duplicate ashle accept korar por abar popup show hobe na.
  final Set<String> _activeCallPopupKeys = <String>{};
  final Set<String> _handledCallPopupKeys = <String>{};

  /// Local leave + viewer join memory for video live.
  /// Keeps stale pending call/live-ended events from affecting a user after they left.
  final Set<int> _locallyLeftStreamIds = <int>{};
  final Map<int, int> _viewerJoinedAtMs = <int, int>{};

  String _callPopupKey({
    required dynamic streamId,
    required dynamic callerId,
    required dynamic callType,
  }) {
    return '${streamId ?? streamID.value}_${callerId}_$callType';
  }

  int _eventTimeMs(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value > 9999999999 ? value : value * 1000;
    final s = value.toString().trim();
    final asInt = int.tryParse(s);
    if (asInt != null) return asInt > 9999999999 ? asInt : asInt * 1000;
    try {
      return DateTime.parse(s).millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  void markUserDisconnectedFromLivestream({
    required dynamic streamId,
    required dynamic userId,
    String reason = 'left_live',
  }) {
    final int sid = _toInt(streamId);
    final int uid = _toInt(userId);

    if (sid > 0) {
      _locallyLeftStreamIds.add(sid);
      if (streamID.value == sid) {
        streamID.value = 0;
      }
    }

    if (uid > 0) {
      _viewerJoinedAtMs.remove(uid);
      _clearStaleCallStateForUser(
        callerId: uid,
        streamId: sid > 0 ? sid : null,
        removeAcceptedCall: true,
        closePopupIfOpen: true,
        reason: reason,
      );
      audioMutedUserMap.remove(uid);
      audioMutedUserMap.refresh();
    }

    pendingCall.refresh();
    liveCallList.refresh();
    print('🚪 Marked user disconnected from livestream => stream:$sid user:$uid reason:$reason');
  }

  bool _isUserInCurrentViewerList(dynamic userId) {
    final uid = userId?.toString();
    if (uid == null || uid == 'null' || uid.isEmpty || uid == '0') return false;

    for (final item in livestreamController.liveViewerList) {
      if (item is! Map) continue;
      final nestedUserId = item['user'] is Map ? item['user']['id'] : null;
      final viewerId = item['viewer_id'];
      final directId = item['id'];
      final userIdField = item['user_id'];

      if (nestedUserId?.toString() == uid ||
          viewerId?.toString() == uid ||
          directId?.toString() == uid ||
          userIdField?.toString() == uid) {
        return true;
      }
    }

    return false;
  }

  void _ensureViewerRowFromCall(Map<String, dynamic> callData) {
    final user = callData['user'];
    final int uid = _toInt(callData['caller_id'] ?? (user is Map ? user['id'] : null));
    if (uid <= 0 || user is! Map) return;

    final exists = _isUserInCurrentViewerList(uid);
    if (exists) return;

    final stream = callData['livestream_id'] ?? callData['stream_id'] ?? streamID.value;
    livestreamController.liveViewerList.add({
      'id': uid,
      'viewer_id': uid,
      'livestream_id': stream,
      'user': Map<String, dynamic>.from(user),
      'is_active': 1,
    });
    livestreamController.liveViewerList.refresh();
    print('✅ Viewer row hydrated from call payload => user:$uid');
  }

  /// Clears stale call request/cache for a viewer/caller.
  ///
  /// Video live problem fix:
  /// If a viewer leaves the broadcast while a call request is pending, the host
  /// could keep seeing the old "call request" popup after that viewer enters the
  /// live again. We clear only that caller's stale call rows/keys without touching
  /// PK state or other callers.
  void _clearStaleCallStateForUser({
    required dynamic callerId,
    dynamic streamId,
    bool removeAcceptedCall = false,
    bool closePopupIfOpen = false,
    String reason = 'unknown',
  }) {
    final int cid = _toInt(callerId);
    if (cid == 0) return;

    bool sameCaller(dynamic call) {
      if (call is! Map) return false;
      final dynamic id = call['caller_id'] ??
          call['user_id'] ??
          (call['user'] is Map ? call['user']['id'] : null) ??
          (call['caller_data'] is Map ? call['caller_data']['caller_id'] : null) ??
          (call['caller_data'] is Map && call['caller_data']['user'] is Map
              ? call['caller_data']['user']['id']
              : null);
      return id != null && id.toString() == cid.toString();
    }

    final int beforePending = pendingCall.length;
    final int beforeLive = liveCallList.length;

    pendingCall.removeWhere(sameCaller);

    if (removeAcceptedCall) {
      liveCallList.removeWhere(sameCaller);
    }

    bool keyBelongsToCaller(String key) {
      final sid = streamId ?? streamID.value;
      final containsCaller = key.contains('_${cid}_');
      if (!containsCaller) return false;
      if (sid == null || sid.toString().isEmpty || sid.toString() == '0') {
        return true;
      }
      return key.startsWith('${sid}_');
    }

    final bool hadActivePopup = _activeCallPopupKeys.any(keyBelongsToCaller);
    _activeCallPopupKeys.removeWhere(keyBelongsToCaller);

    /// Do not keep handled keys forever. Otherwise the same viewer cannot call
    /// again after leaving/re-entering the broadcast.
    _handledCallPopupKeys.removeWhere(keyBelongsToCaller);

    if (closePopupIfOpen && hadActivePopup && Get.isDialogOpen == true) {
      try {
        Get.back();
      } catch (_) {}
    }

    pendingCall.refresh();
    liveCallList.refresh();

    print(
      '🧹 Stale call state cleared => caller:$cid reason:$reason '
          'pending:$beforePending->${pendingCall.length} '
          'live:$beforeLive->${liveCallList.length}',
    );
  }


  /// Backend channel name. If backend developer uses a different channel,
  /// only change this string.
  final String liveStreamEventChannelName = 'live-stream-event';

  Future<void> tryToConnectToUnifiedLiveStreamEventWs({bool force = false}) async {
    if (_isConnectingUnifiedWs) {
      print('ℹ️ Unified LiveStreamEvent WS already connecting...');
      return;
    }

    if (!force &&
        liveStreamEventChannel != null &&
        liveStreamEventChannel!.closeCode == null) {
      print('ℹ️ Unified LiveStreamEvent WS already connected/open');
      return;
    }

    print('⚡ Trying to connect to unified LiveStreamEvent WS... force=$force url=$kWsUrl');

    if (kWsUrl.isEmpty) {
      print('❌ WebSocket URL is empty, cannot connect to LiveStreamEvent');
      return;
    }

    _isConnectingUnifiedWs = true;
    _unifiedReconnectTimer?.cancel();
    _unifiedReconnectTimer = null;

    try {
      await liveStreamEventChannel?.sink.close();
    } catch (_) {}

    try {
      liveStreamEventChannel = WebSocketChannel.connect(Uri.parse(kWsUrl));
      await liveStreamEventChannel?.ready;

      print('✅ Connected to unified LiveStreamEvent WebSocket');

      liveStreamEventChannel!.stream.listen(
            (message) async {
          print('📩 RAW LiveStreamEvent WS MESSAGE => $message');
          await _handleUnifiedLiveStreamMessage(message);
        },
        onError: (error) {
          print('❌ Unified LiveStreamEvent WS error: $error');
          _scheduleUnifiedWsReconnect(reason: 'onError');
        },
        onDone: () {
          print('⚠️ Unified LiveStreamEvent WS closed');
          _scheduleUnifiedWsReconnect(reason: 'onDone');
        },
        cancelOnError: true,
      );

      liveStreamEventChannel!.sink.add(json.encode({
        "event": "pusher:subscribe",
        "data": {"channel": liveStreamEventChannelName}
      }));

      print('📡 Subscribed to "$liveStreamEventChannelName" channel');
    } catch (e) {
      print('❌ Unified LiveStreamEvent connection failed: $e');
      liveStreamEventChannel = null;
      _scheduleUnifiedWsReconnect(reason: 'catch');
    } finally {
      _isConnectingUnifiedWs = false;
    }
  }

  void _scheduleUnifiedWsReconnect({required String reason}) {
    _unifiedReconnectTimer?.cancel();
    _unifiedReconnectTimer = Timer(const Duration(seconds: 2), () {
      print('🔄 Reconnecting unified LiveStreamEvent WS after $reason...');
      tryToConnectToUnifiedLiveStreamEventWs(force: true);
    });
  }

  Future<void> _handleUnifiedLiveStreamMessage(dynamic message) async {
    try {
      /// Full raw print, so edit event backend theke ashe kina clear bojha jabe.
      print('📩 LiveStreamEvent RAW => $message');

      final decodedMessage = _safeJsonDecode(message);
      print('🧩 LiveStreamEvent decoded => $decodedMessage');

      if (decodedMessage is! Map) {
        print('⚠️ Unified message is not Map: $decodedMessage');
        return;
      }

      final eventName = decodedMessage['event']?.toString() ?? '';
      print('🏷️ LiveStreamEvent eventName => $eventName');

      /// Pusher system events. These are normal, not app events.
      if (eventName == "pusher:ping") {
        _sendUnifiedPong();
        return;
      }

      if (eventName == "pusher:connection_established" ||
          eventName == "pusher_internal:subscription_succeeded" ||
          eventName.startsWith("pusher_internal:")) {
        print('ℹ️ Pusher system event ignored: $eventName');
        return;
      }

      final payload = _extractUnifiedPayload(decodedMessage);
      print('📦 LiveStreamEvent payload => $payload');

      if (payload.isEmpty) {
        print('⚠️ Unified payload empty. event=$eventName message=$decodedMessage');
        return;
      }

      String actionType = (payload['action_type'] ??
          payload['action_type'.toString()] ??
          payload['action'] ??
          payload['type'] ??
          '')
          .toString()
          .trim();

      /// Some backend events come with event name only, without action_type in data.
      /// Example: event="live-stream-updated" or "App\\Events\\LiveStreamUpdated".
      /// In that case map eventName to our unified action_type.
      if (actionType.isEmpty) {
        actionType = _actionTypeFromEventName(eventName);
      }

      if (actionType.isEmpty) {
        print('ℹ️ Non LiveStreamEvent ignored. event=$eventName payload=$payload');
        return;
      }

      /// Put inferred action_type back into payload so handlers can debug/parse same way.
      payload['action_type'] ??= actionType;

      actionType = actionType.toLowerCase().trim();
      payload['action_type'] = actionType;

      print('✅ LiveStreamEvent action_type: $actionType');

      await _dispatchLiveStreamAction(actionType, payload);
    } catch (e, st) {
      print('❌ Error handling unified LiveStreamEvent: $e\n$st');
    }
  }

  String _actionTypeFromEventName(String eventName) {
    final e = eventName.toLowerCase().replaceAll('\\\\', '\\');

    if (e.contains('livestreamupdated') ||
        e.contains('live_stream_updated') ||
        e.contains('live-stream-updated') ||
        e.contains('livestream-updated')) {
      return 'live_stream_updated';
    }

    if (e.contains('livestreamcreated') ||
        e.contains('live_stream_created') ||
        e.contains('live-stream-created')) {
      return 'live_stream_created';
    }

    if (e.contains('livestreamended') ||
        e.contains('live_stream_ended') ||
        e.contains('live-stream-ended')) {
      return 'live_stream_ended';
    }

    if (e.contains('livemusic') || e.contains('live_music')) {
      return 'live_music';
    }

    if (e.contains('liveyoutube') || e.contains('live_youtube')) {
      return 'live_youtube';
    }

    if (e.contains('seatlock') || e.contains('seat_lock_toggle')) {
      return 'seat_lock_toggle';
    }

    if (e.contains('seatswitched') ||
        e.contains('seat_switched') ||
        e.contains('seat-switched')) {
      return 'seat_switched';
    }

    return '';
  }

  void _sendUnifiedPong() {
    try {
      if (liveStreamEventChannel != null &&
          liveStreamEventChannel!.closeCode == null) {
        liveStreamEventChannel!.sink.add(json.encode({"event": "pusher:pong"}));
      }
    } catch (e) {
      print('❌ Unified pong error: $e');
    }
  }

  dynamic _safeJsonDecode(dynamic value) {
    dynamic result = value;

    for (int i = 0; i < 6; i++) {
      if (result is String) {
        result = json.decode(result);
      } else {
        break;
      }
    }

    return result;
  }

  Map<String, dynamic> _extractUnifiedPayload(Map decodedMessage) {
    dynamic rawData = decodedMessage['data'];
    dynamic data = _tryDecodeDeep(rawData);

    print('🧪 EXTRACT input data => $data');

    /// New flat backend format after broadcastWith() returns $this->data:
    /// {"action_type":"live_stream_updated", "data": {...}}
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);

      if (dataMap['action_type'] != null ||
          dataMap['action'] != null ||
          dataMap['type'] != null) {
        print('🧪 EXTRACT returned direct dataMap with action_type => $dataMap');
        return dataMap;
      }

      /// Old Laravel LiveStreamEvent format:
      /// {"data": {"action_type":"moderation", ...}}
      if (dataMap['data'] is Map) {
        final inner = Map<String, dynamic>.from(dataMap['data']);

        if (inner['action_type'] != null ||
            inner['action'] != null ||
            inner['type'] != null) {
          print('🧪 EXTRACT returned inner with action_type => $inner');
          return inner;
        }

        if (inner['data'] is Map) {
          final deep = Map<String, dynamic>.from(inner['data']);

          if (deep['action_type'] != null ||
              deep['action'] != null ||
              deep['type'] != null) {
            print('🧪 EXTRACT returned deep with action_type => $deep');
            return deep;
          }

          print('🧪 EXTRACT returned deep data without action_type => $deep');
          return deep;
        }

        print('🧪 EXTRACT returned inner without action_type => $inner');
        return inner;
      }

      print('🧪 EXTRACT returned dataMap without action_type => $dataMap');
      return dataMap;
    }

    /// Rare case: action_type is directly on decodedMessage.
    if (decodedMessage['action_type'] != null ||
        decodedMessage['action'] != null ||
        decodedMessage['type'] != null) {
      final direct = Map<String, dynamic>.from(decodedMessage);
      print('🧪 EXTRACT returned decodedMessage direct => $direct');
      return direct;
    }

    print('⚠️ EXTRACT failed, no payload map found. rawData=$rawData');
    return {};
  }

  dynamic _tryDecodeDeep(dynamic value) {
    dynamic result = value;

    for (int i = 0; i < 6; i++) {
      if (result is String) {
        try {
          result = json.decode(result);
        } catch (_) {
          break;
        }
      } else {
        break;
      }
    }

    return result;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _isCurrentStream(dynamic livestreamId) {
    return streamID.value.toString() == livestreamId.toString();
  }

  /// ===================== SEAT SWITCH REALTIME =====================
  /// Used by both local API response and websocket action_type: seat_switched.
  void applySeatSwitch({
    required int userId,
    required int fromSeatNo,
    required int toSeatNo,
    required Map<String, dynamic> callData,
  }) {
    try {
      final index = liveCallList.indexWhere((call) {
        final callerId = call['caller_id'];
        final callUserId = call['user']?['id'] ?? call['User']?['id'];
        return callerId.toString() == userId.toString() ||
            callUserId.toString() == userId.toString();
      });

      final normalizedCall = <String, dynamic>{
        ...callData,
        'caller_id': callData['caller_id'] ?? userId,
        'seat_no': toSeatNo,
        'call_status': callData['call_status'] ?? 'accepted',
      };

      if (index != -1) {
        final old = liveCallList[index];
        if (old is Map) {
          normalizedCall['user'] ??= old['user'];
          normalizedCall['audio_on'] ??= old['audio_on'];
          normalizedCall['video_on'] ??= old['video_on'];
          normalizedCall['is_muted'] ??= old['is_muted'];
          normalizedCall['is_muted_by_host'] ??= old['is_muted_by_host'];
        }
        liveCallList[index] = normalizedCall;
      } else {
        liveCallList.add(normalizedCall);
      }

      final seen = <String>{};
      liveCallList.removeWhere((call) {
        final seatNo = call['seat_no']?.toString() ?? '';
        final callerId = call['caller_id']?.toString() ??
            call['user']?['id']?.toString() ??
            '';
        final key = '$seatNo-$callerId';

        if (seen.contains(key)) return true;
        seen.add(key);
        return false;
      });

      liveCallList.refresh();

      print(
        '✅ Seat switched applied => user:$userId from:$fromSeatNo to:$toSeatNo',
      );
    } catch (e) {
      print('❌ applySeatSwitch error: $e');
    }
  }

  void _handleUnifiedSeatSwitched(Map<String, dynamic> payload) {
    final userId = int.tryParse(
      (payload['user_id'] ?? payload['caller_id'] ?? payload['sender_id'] ?? 0)
          .toString(),
    ) ??
        0;
    final fromSeatNo =
        int.tryParse((payload['from_seat_no'] ?? 0).toString()) ?? 0;
    final toSeatNo = int.tryParse(
      (payload['to_seat_no'] ?? payload['seat_no'] ?? 0).toString(),
    ) ??
        0;

    final callDataRaw = payload['call_data'] ?? payload['caller'] ?? payload['data'];
    final callData = callDataRaw is Map
        ? Map<String, dynamic>.from(callDataRaw)
        : <String, dynamic>{
      'livestream_id': payload['livestream_id'],
      'caller_id': userId,
      'seat_no': toSeatNo,
      'call_status': 'accepted',
    };

    if (userId == 0 || toSeatNo == 0) {
      print('⚠️ seat_switched ignored: invalid payload => $payload');
      return;
    }

    applySeatSwitch(
      userId: userId,
      fromSeatNo: fromSeatNo,
      toSeatNo: toSeatNo,
      callData: callData,
    );
  }

  void _handleUnifiedSeatLockToggle(Map<String, dynamic> payload) {
    final Map<String, dynamic> data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'])
        : payload['seat'] is Map
        ? Map<String, dynamic>.from(payload['seat'])
        : Map<String, dynamic>.from(payload);

    final livestreamId = payload['livestream_id'] ??
        payload['stream_id'] ??
        data['livestream_id'] ??
        data['stream_id'];

    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      return;
    }

    /// Sync full locked_seats list first. Important: allowUnlock=false keeps
    /// already locked seats safe during viewer join / resume / partial refresh.
    try {
      syncSeatLocksFromAnyPayload(
        {
          ...payload,
          ...data,
        },
        allowUnlock: false,
        source: 'seat_lock_toggle_payload',
      );
    } catch (e) {
      print('⚠️ seat lock list sync failed => $e');
    }

    final int seatNo = _seatToInt(
      data['seat_no'] ??
          data['seatNo'] ??
          data['seat'] ??
          data['seat_number'] ??
          payload['seat_no'] ??
          payload['seatNo'] ??
          payload['seat_number'],
    ) ??
        0;

    if (seatNo == 0) {
      print('⚠️ seat_lock_toggle missing seat_no: $payload');
      return;
    }

    final rawLocked = data['is_locked'] ??
        data['locked'] ??
        data['lock'] ??
        data['seat_locked'] ??
        data['lock_status'] ??
        data['status'] ??
        data['action'] ??
        payload['is_locked'] ??
        payload['locked'] ??
        payload['status'] ??
        payload['action'];

    final text = rawLocked?.toString().toLowerCase().trim() ?? '';

    final bool explicitUnlock = _seatFalsey(rawLocked) || text.contains('unlock');
    final bool explicitLock =
        _seatTruthy(rawLocked) || (text.contains('lock') && !text.contains('unlock'));

    if (explicitUnlock) {
      updateSeatLockStatus(
        seatNo: seatNo,
        isLocked: false,
        source: 'seat_lock_toggle_unlock',
      );
    } else if (explicitLock) {
      updateSeatLockStatus(
        seatNo: seatNo,
        isLocked: true,
        source: 'seat_lock_toggle_lock',
      );
    } else {
      /// Do not unlock on empty/partial seat payload.
      /// Viewer join/live refresh sometimes sends seat data without lock keys,
      /// and that must not clear a previously locked seat.
      print('ℹ️ seat_lock_toggle ignored: no explicit lock/unlock value => seat:$seatNo raw:$rawLocked');
      return;
    }

    print('✅ Unified seat lock toggle handled => seat:$seatNo locked:${isSeatLocked(seatNo)} raw:$rawLocked');
  }
  Future<void> _dispatchLiveStreamAction(
      String actionType,
      Map<String, dynamic> payload,
      ) async {
    switch (actionType) {
      case 'live_stream_created':
        _handleUnifiedLiveStreamCreated(payload);
        try {
          livestreamController.syncLiveGiftCoinsFromPayload(payload, source: 'live_stream_created');
        } catch (_) {}
        break;

      case 'live_stream_ended':
      case 'live_ended':
      case 'broadcaster_disconnected':
        _handleUnifiedLiveStreamEnded(payload);
        break;

      case 'live_stream_list':
        _handleUnifiedLiveStreamList(payload);
        try {
          livestreamController.syncLiveGiftCoinsFromPayload(payload, source: 'live_stream_list');
        } catch (_) {}
        break;

      case 'viewer_add':
      case 'viewer_added':
      case 'viewer_joined':
      case 'user_joined':
      case 'join_live':
      case 'live_joined':
      case 'viewer_remove':
      case 'viewer_removed':
      case 'viewer_left':
      case 'user_left':
      case 'user_leave':
      case 'leave_live':
        _handleUnifiedViewer(payload, actionType);
        break;

      case 'live_comment':
      case 'multi_live_comment':
      case 'pk_comment':
      case 'pk_live_comment':
        _handleUnifiedComment(payload);
        break;

      case 'gift_sent':
      case 'multi_live_gift_sent':
      case 'pk_gift_sent':
      case 'pk_gift_received':
        _handleUnifiedGift(payload);
        syncGiftCoinsFromPayload(payload, source: 'dispatch_gift_$actionType');
        try {
          livestreamController.syncLiveGiftCoinsFromPayload(payload, source: 'dispatch_gift_$actionType');
        } catch (e) {
          print('⚠️ controller gift coin sync failed => $e');
        }
        try {
          livestreamController.handlePkScoreUpdated(payload);
        } catch (_) {}
        break;

      case 'lucky_gift_result':
      case 'lucky_gift_back_coin':
        _handleLuckyGiftResult(payload);
        try {
          livestreamController.syncLiveGiftCoinsFromPayload(payload, source: 'lucky_gift_result');
        } catch (_) {}
        break;

      case 'imogi_sent':
      case 'emoji_sent':
        _handleUnifiedImogiSent(payload);
        break;

      case 'live_stream_call':
      case 'multi_live_seat_joined':
      case 'multi_live_seat_left':
        await _handleUnifiedLiveCall(payload);
        break;

      case 'moderation':
        await _handleUnifiedModeration(payload);
        break;

      case 'multi_live_audio_toggle':
      case 'audio_toggle':
        await _handleUnifiedAudioToggle(payload);
        break;

      case 'multi_live_video_toggle':
      case 'video_toggle':
        await _handleUnifiedVideoToggle(payload);
        break;

      case 'seat_lock_toggle':
      case 'seat_locked':
      case 'seat_unlocked':
        _handleUnifiedSeatLockToggle(payload);
        break;

      case 'seat_switched':
        _handleUnifiedSeatSwitched(payload);
        break;

      case 'live_music':
        _handleUnifiedLiveMusic(payload);
        break;

      case 'live_youtube':
        _handleUnifiedLiveYoutube(payload);
        break;

      case 'live_stream_updated':
        _handleUnifiedLiveStreamUpdated(payload);
        try {
          livestreamController.syncLiveGiftCoinsFromPayload(payload, source: 'live_stream_updated');
        } catch (_) {}
        break;

      case 'multi_live_speaking':
        _handleUnifiedSpeaking(payload);
        break;

      case 'red_packet_collected':
        _handleUnifiedRedPacketCollected(payload);
        break;

      case 'greedy_winner_announced':
      case 'greedy_game_timer':
      case 'greedy_game_started':
      case 'greedy_game_ended':
      case 'greedy_bet_placed':
      case 'fruit_game_winner':
      case 'fruit_game_user_left':
      case 'fruit_game_user_joined':
      case 'fruit_game_timer':
      case 'fruit_game_bet_total':
        _handleUnifiedGameAction(actionType, payload);
        break;

      case 'pk_request_received':
      case 'pk_invite_received':
        _handlePkRequestReceived(payload);
        break;

      case 'pk_request_sent':
      case 'pk_invite_sent':
        livestreamController.handlePkRequestSent(payload);
        _showPkWaitingToast(payload);
        break;

      case 'pk_started':
      case 'pk_accepted':
      case 'pk_request_accepted':
        livestreamController.handlePkStarted(payload);
        break;

      case 'pk_score_updated':
        livestreamController.handlePkScoreUpdated(payload);
        break;

      case 'pk_result_preview':
        livestreamController.handlePkResultPreview(payload);
        break;

      case 'pk_rejected':
      case 'pk_request_rejected':
        livestreamController.handlePkRejected(payload);
        break;

      case 'pk_ended':
      case 'pk_cancelled':
      case 'pk_canceled':
        livestreamController.handlePkEnded(payload);
        break;

      default:
        print('ℹ️ Unknown LiveStreamEvent action_type: $actionType');
        print('Payload: $payload');
        break;
    }
  }

  void _handleUnifiedLiveStreamUpdated(Map<String, dynamic> payload) {
    print('🎨 LIVE ROOM UPDATED RAW PAYLOAD => $payload');

    /// Supports all formats:
    /// A) {action_type, livestream_id, seat_count, room_layout...}
    /// B) {action_type, livestream_id, data:{id, seat_count, room_layout...}}
    /// C) {action_type, livestreamdata:{id, seat_count, room_layout...}}
    Map<String, dynamic> room = Map<String, dynamic>.from(payload);

    if (payload['data'] is Map) {
      room = {
        ...room,
        ...Map<String, dynamic>.from(payload['data']),
      };
    }

    if (payload['livestreamdata'] is Map) {
      room = {
        ...room,
        ...Map<String, dynamic>.from(payload['livestreamdata']),
      };
    }

    if (payload['livestream'] is Map) {
      room = {
        ...room,
        ...Map<String, dynamic>.from(payload['livestream']),
      };
    }

    if (payload['live_stream'] is Map) {
      room = {
        ...room,
        ...Map<String, dynamic>.from(payload['live_stream']),
      };
    }

    final livestreamId = payload['livestream_id'] ??
        payload['stream_id'] ??
        room['livestream_id'] ??
        room['stream_id'] ??
        room['id'];

    if (livestreamId == null) {
      print('⚠️ live_stream_updated missing livestream id. payload=$payload');
      return;
    }

    if (!_isCurrentStream(livestreamId)) {
      print('⛔ live_stream_updated ignored: not current stream => $livestreamId current=${streamID.value}');
      return;
    }

    final int streamId = int.tryParse(livestreamId.toString()) ?? streamID.value;

    final int seatCount = int.tryParse(
      (room['seat_count'] ?? payload['seat_count'] ?? liveRoomSeatCount.value)
          .toString(),
    ) ??
        liveRoomSeatCount.value;

    final int roomLayout = int.tryParse(
      (room['room_layout'] ?? payload['room_layout'] ?? liveRoomLayout.value)
          .toString(),
    ) ??
        liveRoomLayout.value;

    final int roomTheme = int.tryParse(
      (room['room_theme'] ?? payload['room_theme'] ?? liveRoomTheme.value)
          .toString(),
    ) ??
        liveRoomTheme.value;

    final int roomBackground = int.tryParse(
      (room['room_background'] ??
          payload['room_background'] ??
          liveRoomBackground.value)
          .toString(),
    ) ??
        liveRoomBackground.value;

    updateLiveRoomSettings(
      livestreamId: streamId,
      seatCount: seatCount,
      roomLayout: roomLayout,
      roomTheme: roomTheme,
      roomBackground: roomBackground,
    );

    syncRoomSnapshotForLateJoin(room, source: 'live_stream_updated');

    print(
      '✅ live_stream_updated applied => stream:$streamId seats:$seatCount layout:$roomLayout theme:$roomTheme bg:$roomBackground',
    );
  }

  void _handleUnifiedLiveMusic(Map<String, dynamic> payload) {
    print('🎵 LIVE MUSIC RAW PAYLOAD => $payload');

    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'])
        : payload;

    final livestreamId = data['livestream_id'] ?? payload['livestream_id'];
    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      print('⛔ live_music ignored: not current stream => $livestreamId');
      return;
    }

    final status = (data['music_status'] ?? data['status'] ?? 'stopped')
        .toString()
        .toLowerCase();
    final name = (data['music_name'] ?? data['name'] ?? '').toString();
    final hostId = int.tryParse((data['host_id'] ?? 0).toString()) ?? 0;

    liveMusicStatus.value = status;
    liveMusicName.value = status == 'stopped' ? '' : name;
    liveMusicHostId.value = hostId;

    print('✅ Live music updated => status:$status name:$name host:$hostId');
  }


  void _handleUnifiedLiveYoutube(Map<String, dynamic> payload) {
    print('▶️ LIVE YOUTUBE RAW PAYLOAD => $payload');

    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'])
        : payload;

    final livestreamId = data['livestream_id'] ?? payload['livestream_id'];
    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      print('⛔ live_youtube ignored: not current stream => $livestreamId');
      return;
    }

    final status = (data['youtube_status'] ?? data['status'] ?? 'stopped')
        .toString()
        .toLowerCase();
    final url = (data['youtube_url'] ?? data['url'] ?? '').toString();
    final videoId = (data['youtube_video_id'] ?? _extractYoutubeVideoId(url)).toString();
    final hostId = int.tryParse((data['host_id'] ?? 0).toString()) ?? 0;

    if (status == 'stopped' || videoId.isEmpty) {
      liveYoutubeStatus.value = 'stopped';
      liveYoutubeUrl.value = '';
      liveYoutubeVideoId.value = '';
      liveYoutubeHostId.value = hostId;
    } else {
      liveYoutubeStatus.value = status;
      liveYoutubeUrl.value = url;
      liveYoutubeVideoId.value = videoId;
      liveYoutubeHostId.value = hostId;
    }

    print('✅ Live YouTube updated => status:$status video:${liveYoutubeVideoId.value} host:$hostId');
  }

  String _extractYoutubeVideoId(String url) {
    final raw = url.trim();
    if (raw.isEmpty) return '';

    final patterns = <RegExp>[
      RegExp(r'(?:v=)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      if (match != null) return match.group(1) ?? '';
    }

    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(raw)) return raw;
    return '';
  }

  void _handleUnifiedLiveStreamCreated(Map<String, dynamic> payload) {
    final streamDataRaw = payload['livestream'] ??
        payload['live_stream'] ??
        payload['stream'] ??
        payload['data'] ??
        payload;

    if (streamDataRaw is! Map) {
      print('⚠️ live_stream_created invalid payload: $payload');
      return;
    }

    final streamData = Map<String, dynamic>.from(streamDataRaw);

    final streamId = streamData['id'] ?? streamData['livestream_id'];
    final userId = streamData['user_id'] ?? streamData['room_id'];

    if (streamId == null && userId == null) {
      print('⚠️ live_stream_created missing stream id/user id: $payload');
      return;
    }

    homeController.showingLiveStreamList.removeWhere((stream) {
      final oldId = stream['id'] ?? stream['livestream_id'];
      final oldUserId = stream['user_id'] ?? stream['room_id'];
      return (streamId != null && oldId.toString() == streamId.toString()) ||
          (userId != null && oldUserId.toString() == userId.toString());
    });

    homeController.showingLiveStreamList.insert(0, streamData);
    homeController.sortLiveStreamList();
    homeController.showingLiveStreamList.refresh();

    _activeCallPopupKeys.clear();
    _handledCallPopupKeys.clear();
    _locallyLeftStreamIds.clear();
    _viewerJoinedAtMs.clear();
    pendingCall.clear();
    liveCallList.clear();
    pendingCall.refresh();
    liveCallList.refresh();

    syncSeatLocksFromAnyPayload(streamData, allowUnlock: false, source: 'live_stream_created');
    syncGiftCoinsFromPayload(streamData, source: 'live_stream_created');
    try { livestreamController.syncLiveGiftCoinsFromPayload(streamData, source: 'live_stream_created'); } catch (_) {}

    final int createdStreamId = int.tryParse((streamData['id'] ?? streamData['livestream_id'] ?? 0).toString()) ?? 0;
    if (createdStreamId > 0) {
      fetchInitialGiftTotal(streamId: createdStreamId);
    }

    print('✅ Unified live stream created/list updated: ${streamData['id']}');
  }

  void _handleUnifiedLiveStreamEnded(Map<String, dynamic> payload) {
    final livestreamId =
        payload['livestream_id'] ?? payload['stream_id'] ?? payload['id'];
    final userId = payload['user_id'] ?? payload['room_id'];

    if (livestreamId == null && userId == null) {
      print('⚠️ live_stream_ended missing livestream_id/user_id: $payload');
      return;
    }

    homeController.showingLiveStreamList.removeWhere((stream) {
      final oldId = stream['id'] ?? stream['livestream_id'];
      final oldUserId = stream['user_id'] ?? stream['room_id'];

      return (livestreamId != null && oldId.toString() == livestreamId.toString()) ||
          (userId != null && oldUserId.toString() == userId.toString());
    });

    homeController.sortLiveStreamList();
    homeController.showingLiveStreamList.refresh();

    final int endedStreamId = _toInt(livestreamId);
    if (endedStreamId > 0 && _locallyLeftStreamIds.contains(endedStreamId)) {
      print('ℹ️ Live end ignored because this device already left stream:$endedStreamId');
      return;
    }

    if (livestreamId != null && _isCurrentStream(livestreamId)) {
      _handleLiveStreamEnded({
        ...payload,
        'livestream_id': livestreamId,
        'joined_users': payload['joined_users'] ?? [],
        'message': payload['message'] ?? 'Live stream has ended',
      });
    }

    print('✅ Unified live stream ended/list removed: $livestreamId');
  }

  void _handleUnifiedLiveStreamList(Map<String, dynamic> payload) {
    final list = payload['data'] ??
        payload['streams'] ??
        payload['live_streams'] ??
        payload['livestreams'];

    if (list is List) {
      homeController.showingLiveStreamList.assignAll(list);
      homeController.sortLiveStreamList();
      homeController.showingLiveStreamList.refresh();
      print('✅ Unified live stream list updated: ${list.length}');
    } else {
      print('⚠️ live_stream_list does not contain list: $payload');
    }
  }

  void _addSystemViewerComment({
    required dynamic livestreamId,
    required Map<String, dynamic> user,
    required String comment,
    required String systemType,
  }) {
    final userId = user['id'] ?? user['user_id'] ?? user['viewer_id'];

    if (userId == null ||
        user['name'] == null ||
        user['name'].toString().trim().isEmpty ||
        user['name'].toString().toLowerCase() == 'null') {
      print('⚠️ System viewer comment skipped, bad user => $user');
      return;
    }

    /// duplicate stop: same user same join/left comment already recent thakle add korbo na.
    final exists = commentsList.reversed.take(10).any((item) {
      if (item is! Map) return false;

      final itemUser = item['user'];
      final itemUserId = itemUser is Map
          ? (itemUser['id'] ?? itemUser['user_id'] ?? itemUser['viewer_id'])
          : null;

      return item['comment'].toString() == comment &&
          itemUserId.toString() == userId.toString();
    });

    if (exists) {
      print('ℹ️ Duplicate system viewer comment skipped: $comment user=$userId');
      return;
    }

    final systemComment = {
      'type': systemType,
      'livestream_id': livestreamId,
      'user': user,
      'comment': comment,
      'timestamp': DateTime.now().toIso8601String(),
      'system_type': systemType,
    };

    print('🟨 SYSTEM VIEWER COMMENT ADDED => $systemComment');

    commentsList.add(systemComment);
    commentsList.refresh();
  }

  void _handleUnifiedViewer(Map<String, dynamic> payload, String actionType) {
    print('🟧 VIEWER RAW PAYLOAD => action=$actionType payload=$payload');

    final viewerInfoRaw = payload['viewer_data'] ??
        payload['viewer'] ??
        payload['user'] ??
        payload['data'] ??
        payload;

    if (viewerInfoRaw is! Map) {
      print('⚠️ viewer payload invalid: $payload');
      return;
    }

    final viewerInfo = Map<String, dynamic>.from(viewerInfoRaw);
    final Map<String, dynamic> userMap = viewerInfo['user'] is Map
        ? Map<String, dynamic>.from(viewerInfo['user'])
        : Map<String, dynamic>.from(viewerInfo);

    final livestreamId = payload['livestream_id'] ??
        payload['stream_id'] ??
        viewerInfo['livestream_id'] ??
        viewerInfo['stream_id'];

    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      print('⛔ VIEWER ignored: not current stream => $livestreamId');
      return;
    }

    final userId = userMap['id'] ??
        viewerInfo['viewer_id'] ??
        viewerInfo['user_id'] ??
        payload['user_id'] ??
        payload['viewer_id'];

    if (userId == null) {
      print('⚠️ viewer user id missing: $payload');
      return;
    }

    final currentUserId = authController.userProfile.value.user?.id?.toString();
    final action = (payload['action'] ??
        payload['viewer_action'] ??
        payload['action_type'] ??
        actionType)
        .toString()
        .toLowerCase();

    /// Backend can send action_type=viewer_add with action=viewer_remove.
    final isLeft = action.contains('remove') ||
        action.contains('left') ||
        action.contains('leave') ||
        action == 'viewer_out';

    final isSelf = currentUserId != null && userId.toString() == currentUserId;

    print('🟩 VIEWER NORMALIZED => userId=$userId isLeft=$isLeft isSelf=$isSelf user=$userMap');

    /// ✅ Video live stale call popup fix:
    /// Viewer live theke ber hole ba abar join korle tar previous pending
    /// call request/cache clear kore dite hobe. Noyto host side-e old
    /// "call request" popup/list abar dekhay.
    if (isLeft) {
      if (isSelf) {
        final sid = _toInt(livestreamId);
        if (sid > 0) {
          _locallyLeftStreamIds.add(sid);
          if (streamID.value == sid) streamID.value = 0;
        }
      }

      _viewerJoinedAtMs.remove(_toInt(userId));

      _clearStaleCallStateForUser(
        callerId: userId,
        streamId: livestreamId,
        removeAcceptedCall: true,
        closePopupIfOpen: true,
        reason: 'viewer_left',
      );

      /// Backend pending/accepted call also must be cleared when viewer leaves.
      /// Fire-and-forget keeps websocket handler fast and prevents stale call on rejoin.
      final int sid = _toInt(livestreamId);
      final int uid = _toInt(userId);
      if (sid > 0 && uid > 0) {
        Future.microtask(() async {
          try {
            await livestreamController.tryToRejectCall(streamId: sid, userId: uid);
          } catch (e) {
            print('⚠️ reject stale call on viewer_left skipped => $e');
          }
        });
      }
    } else {
      final sid = _toInt(livestreamId);
      if (isSelf && sid > 0) {
        _locallyLeftStreamIds.remove(sid);
        streamID.value = sid;
      }

      _viewerJoinedAtMs[_toInt(userId)] = DateTime.now().millisecondsSinceEpoch;

      _clearStaleCallStateForUser(
        callerId: userId,
        streamId: livestreamId,
        removeAcceptedCall: false,
        closePopupIfOpen: false,
        reason: 'viewer_join_reset_old_pending',
      );
    }

    bool sameViewer(dynamic viewer) {
      if (viewer is! Map) return false;
      final nestedUserId = viewer['user'] is Map ? viewer['user']['id'] : null;
      final viewerId = viewer['viewer_id'];
      final directId = viewer['id'];
      final userIdField = viewer['user_id'];

      return nestedUserId.toString() == userId.toString() ||
          viewerId.toString() == userId.toString() ||
          userIdField.toString() == userId.toString() ||
          directId.toString() == userId.toString();
    }

    if (!isLeft) {
      // Viewer join payload jodi current room snapshot niye ase, late audience/host side
      // immediately lock/mute/gift coin current state sync kore nebo.
      syncRoomSnapshotForLateJoin(payload, source: 'viewer_add_payload');

      final exists = livestreamController.liveViewerList.any(sameViewer);

      if (!exists) {
        livestreamController.liveViewerList.add(viewerInfo);
        livestreamController.liveViewerList.refresh();
      }

      if (!isSelf && !exists) {
        newJoinedUserData.value = viewerInfo;
        newViewerAction.value = 'join';
        newViewersJoinded.value = true;
        showEntryAnimation();

        _addSystemViewerComment(
          livestreamId: livestreamId,
          user: userMap,
          comment: 'has joined the stream',
          systemType: 'viewer_join',
        );
      }

      print('✅ Unified viewer added: $userId exists=$exists');
    } else {
      clearSpecificUserStreamData(
        userId: userId.toString(),
        rejectCallIfInCallList: false,
      );

      if (!isSelf) {
        _addSystemViewerComment(
          livestreamId: livestreamId,
          user: userMap,
          comment: 'left the room',
          systemType: 'viewer_left',
        );
      }

      print('✅ Unified viewer removed and local state cleared: $userId');
    }
  }

  void _handleUnifiedComment(Map<String, dynamic> payload) {
    print('🟦 COMMENT RAW PAYLOAD => $payload');

    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'])
        : payload;

    final livestreamId = data['livestream_id'] ??
        data['stream_id'] ??
        payload['livestream_id'] ??
        payload['stream_id'];

    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      print('⛔ COMMENT ignored: not current stream => $livestreamId');
      return;
    }

    final user = data['user'] ?? payload['user'];

    final commentData = {
      'type': 'message',
      'livestream_id': livestreamId,
      'user': user,
      'comment': data['comment'] ??
          data['message'] ??
          payload['comment'] ??
          payload['message'] ??
          '',
      'timestamp': data['timestamp'] ??
          payload['timestamp'] ??
          DateTime.now().toIso8601String(),
    };

    print('🟩 COMMENT NORMALIZED => $commentData');

    commentsList.add(commentData);
    commentsList.refresh();

    print('✅ Unified comment added | commentsList=${commentsList.length}');
  }


  void handleLocalImogiSent(Map<String, dynamic> payload) {
    _handleUnifiedImogiSent(payload, isLocal: true);
  }

  /// Public helper for local preview if needed.
  /// Existing backend websocket event still controls realtime display for everyone.
  void showLocalImogiAnimation(Map<String, dynamic> payload) {
    _handleUnifiedImogiSent(payload, isLocal: true);
  }

  void _handleUnifiedImogiSent(
      Map<String, dynamic> payload, {
        bool isLocal = false,
      }) {
    print('🤖 IMOGI RAW PAYLOAD => $payload');

    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'])
        : Map<String, dynamic>.from(payload);

    final livestreamId = data['livestream_id'] ??
        data['stream_id'] ??
        data['streamId'] ??
        payload['livestream_id'] ??
        payload['stream_id'];

    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      print('⛔ IMOGI ignored: not current stream => $livestreamId');
      return;
    }

    final imogi = data['imogi'] is Map
        ? Map<String, dynamic>.from(data['imogi'])
        : data['emoji'] is Map
        ? Map<String, dynamic>.from(data['emoji'])
        : data['imogi_data'] is Map
        ? Map<String, dynamic>.from(data['imogi_data'])
        : <String, dynamic>{
      'id': data['imogi_id'] ?? data['emoji_id'],
      'name': data['imogi_name'] ?? data['emoji_name'] ?? 'Imogi',
      'image': data['imogi_image'] ?? data['emoji_image'] ?? data['image'],
      'category': data['category'],
    };

    final sender = data['sender'] is Map
        ? Map<String, dynamic>.from(data['sender'])
        : data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : <String, dynamic>{
      'id': data['sender_id'] ?? data['user_id'],
      'name': data['sender_name'] ?? data['user_name'] ?? 'User',
      'level': data['sender_level'] ?? data['level'] ?? 0,
      'profile_image': data['sender_profile_image'] ??
          data['profile_image'] ??
          data['avatar'],
    };

    final senderId = sender['id'] ?? data['sender_id'] ?? data['user_id'] ?? '';
    final imogiId = imogi['id'] ?? data['imogi_id'] ?? data['emoji_id'] ?? '';
    final eventId = (data['id'] ??
        data['event_id'] ??
        '${livestreamId}_${senderId}_${imogiId}_${data['timestamp'] ?? data['created_at'] ?? DateTime.now().millisecondsSinceEpoch}')
        .toString();

    if (!isLocal && processedImogiIds.contains(eventId)) {
      print('ℹ️ Duplicate imogi ignored => $eventId');
      return;
    }

    processedImogiIds.add(eventId);
    if (processedImogiIds.length > 120) {
      processedImogiIds.remove(processedImogiIds.first);
    }

    final animationData = <String, dynamic>{
      'event_id': eventId,
      'livestream_id': livestreamId,
      'sender': sender,
      'imogi': imogi,
      'image': imogi['image'],
      'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
    };

    liveImogiAnimations.add(animationData);
    liveImogiAnimations.refresh();

    print('✅ Imogi animation shown => sender:$senderId imogi:$imogiId');

    Timer(const Duration(milliseconds: 3600), () {
      liveImogiAnimations.removeWhere((item) {
        return item['event_id'].toString() == eventId;
      });
      liveImogiAnimations.refresh();
    });
  }

  void _handleLuckyGiftResult(Map<String, dynamic> payload) {
    print('🍀 LUCKY GIFT RESULT RAW => $payload');

    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'])
        : Map<String, dynamic>.from(payload);

    final livestreamId = data['livestream_id'] ?? data['stream_id'];
    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      print('⛔ Lucky gift ignored: not current stream => $livestreamId');
      return;
    }

    final sender = data['sender'] is Map
        ? Map<String, dynamic>.from(data['sender'])
        : data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : <String, dynamic>{
      'id': data['sender_id'] ?? data['user_id'],
      'name': data['sender_name'] ?? 'User',
      'profile_image': data['profile_image'],
      'level': data['level'] ?? 0,
    };

    final gift = data['gift'] is Map
        ? Map<String, dynamic>.from(data['gift'])
        : <String, dynamic>{
      'id': data['gift_id'],
      'name': data['gift_name'] ?? 'Lucky Gift',
      'coin': data['gift_coin'],
      'gift_image': data['gift_image'],
      'show_image': data['show_image'],
      'category': 'Lucky',
    };

    final bool isWin = data['is_win'] == true || data['is_win'].toString() == '1';
    final winAmount = data['win_amount'] ?? 0;
    final multiplier = data['multiplier'] ?? 0;
    final winType = (data['win_type'] ?? (isWin ? 'small_win' : 'loss')).toString();

    final eventId = (data['id'] ??
        data['event_id'] ??
        '${livestreamId}_${sender['id']}_${gift['id']}_${data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch}')
        .toString();

    if (processedGiftIds.contains(eventId)) {
      print('ℹ️ Duplicate lucky gift result skipped: $eventId');
      return;
    }
    processedGiftIds.add(eventId);

    final luckyMessage = {
      'type': 'lucky_gift',
      'event_id': eventId,
      'livestream_id': livestreamId,
      'user': sender,
      'sender': sender,
      'gift': gift,
      'comment': isWin
          ? 'Lucky win $winAmount coins x$multiplier'
          : 'Lucky gift sent. Better luck next time',
      'is_lucky_gift': true,
      'is_win': isWin,
      'win_amount': winAmount,
      'multiplier': multiplier,
      'win_type': winType,
      'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
    };

    giftMessagesList.add(luckyMessage);
    giftMessagesList.refresh();

    commentsList.add(luckyMessage);
    commentsList.refresh();

    try {
      final livestreamController = Get.find<LivestreamController>();
      livestreamController.showLuckyGiftResult(data);
    } catch (_) {}

    print('✅ Lucky gift result shown => win:$isWin amount:$winAmount multiplier:$multiplier');
  }


  void _handleUnifiedGift(Map<String, dynamic> payload) {
    print('🟪 GIFT RAW PAYLOAD => $payload');

    final giftData = Map<String, dynamic>.from(
      payload['gift_data'] ?? payload['data'] ?? payload,
    );

    final livestreamId = giftData['livestream_id'] ??
        giftData['stream_id'] ??
        payload['livestream_id'] ??
        payload['stream_id'];

    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      print('⛔ GIFT ignored: not current stream => $livestreamId');
      return;
    }

    final senderId = giftData['sender']?['id'] ?? giftData['sender_id'] ?? '';
    final receiverId =
        giftData['receiver']?['id'] ?? giftData['receiver_id'] ?? '';
    final giftId = giftData['gift']?['id'] ?? giftData['gift_id'] ?? '';

    final eventId = giftData['id'] ??
        giftData['event_id'] ??
        '${senderId}_${receiverId}_${giftId}_${giftData['created_at'] ?? giftData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch}';

    if (processedGiftIds.contains(eventId.toString())) {
      print('ℹ️ Duplicate gift ignored => $eventId');
      return;
    }

    processedGiftIds.add(eventId.toString());

    if (processedGiftIds.length > 100) {
      processedGiftIds.remove(processedGiftIds.first);
    }

    final sender = giftData['sender'] is Map
        ? Map<String, dynamic>.from(giftData['sender'])
        : <String, dynamic>{
      'id': senderId,
      'name': giftData['sender_name'] ?? 'User',
      'level': giftData['sender_level'] ?? 0,
      'profile_image': giftData['sender_profile_image'],
    };

    final receiver = giftData['receiver'] is Map
        ? Map<String, dynamic>.from(giftData['receiver'])
        : <String, dynamic>{
      'id': receiverId,
      'name': giftData['receiver_name'] ?? 'User',
      'level': giftData['receiver_level'] ?? 0,
      'profile_image': giftData['receiver_profile_image'],
    };

    final gift = giftData['gift'] is Map
        ? Map<String, dynamic>.from(giftData['gift'])
        : <String, dynamic>{
      'id': giftId,
      'name': giftData['gift_name'] ?? 'Gift',
      'image': giftData['gift_image'],
      'gift_image': giftData['gift_image'],
      'coin': giftData['gift_coin'] ?? giftData['coin'] ?? giftData['coins'],
    };

    giftsData.value = {
      "sender": sender,
      "receiver": receiver,
      "gift": gift,
    };

    final giftMessage = {
      'type': 'gift',
      'livestream_id': livestreamId,
      'event_id': eventId.toString(),
      'user': sender,
      'sender': sender,
      'receiver': receiver,
      'gift': gift,
      'comment':
      '${sender['name'] ?? 'User'} sent ${gift['name'] ?? 'Gift'} to ${receiver['name'] ?? 'User'}',
      'timestamp': giftData['timestamp'] ??
          giftData['created_at'] ??
          DateTime.now().toIso8601String(),
    };

    print('🟨 GIFT NORMALIZED => $giftMessage');

    final existsGift = giftMessagesList.any((item) =>
    item is Map && item['event_id'].toString() == eventId.toString());

    if (!existsGift) {
      giftMessagesList.add(giftMessage);
      giftMessagesList.refresh();
    }

    print('🎁 Gift list length => ${giftMessagesList.length}');

    final coinValue = _toInt(
      gift['coin'] ??
          gift['coins'] ??
          giftData['coin'] ??
          giftData['coins'],
    );

    if (coinValue > 0) {
      totalGiftCoins.value += coinValue;
      print('🪙 Gift total increased locally => +$coinValue total=${totalGiftCoins.value}');
    }

    /// If backend includes final total in the event, sync it safely.
    /// Missing/zero values will not reset an existing total.
    syncGiftCoinsFromPayload(giftData, source: 'gift_event');
    try { livestreamController.syncLiveGiftCoinsFromPayload(giftData, source: 'gift_event'); } catch (_) {}

    for (var call in liveCallList) {
      final callUserId = call['caller_id'] ?? call['user']?['id'];
      if (callUserId.toString() == receiverId.toString()) {
        final currentCoins = _toInt(call['earn_coins']);
        call['earn_coins'] = currentCoins + coinValue;

        final currentUserCoins = _toInt(call['user']?['earned_coins']);
        if (call['user'] is Map) {
          call['user']['earned_coins'] =
              (currentUserCoins + coinValue).toString();
        }
      }
    }

    liveCallList.refresh();

    try {
      final live = Get.find<LivestreamController>();
      live.fetchGiftHistory();
      live.fetchTotalGiftCoins();
    } catch (e) {
      print('⚠️ gift total refresh skipped: $e');
    }

    /// Do not use Get.dialog here. AudioLiveView Stack will show GiftAnimationWidget.
    /// This keeps comment typing available and avoids navigator crash.
    isGiftAnimationShowing.value = true;

    Future.delayed(const Duration(seconds: 5), () {
      isGiftAnimationShowing.value = false;
    });

    print('✅ Unified gift handled');
  }

  Map<String, dynamic>? _extractCallerUserFromPayload(
      Map<String, dynamic> payload,
      Map<String, dynamic> callData,
      ) {
    bool looksLikeUser(Map data) {
      return data['name'] != null ||
          data['profile_image'] != null ||
          data['level'] != null ||
          data['user_id'] != null;
    }

    Map<String, dynamic>? asUser(dynamic value) {
      if (value is! Map) return null;

      final map = Map<String, dynamic>.from(value);

      if (map['user'] is Map) {
        return Map<String, dynamic>.from(map['user']);
      }

      if (map['caller_user'] is Map) {
        return Map<String, dynamic>.from(map['caller_user']);
      }

      if (map['caller_info'] is Map) {
        return Map<String, dynamic>.from(map['caller_info']);
      }

      if (map['sender'] is Map) {
        return Map<String, dynamic>.from(map['sender']);
      }

      if (map['from_user'] is Map) {
        return Map<String, dynamic>.from(map['from_user']);
      }

      if (looksLikeUser(map)) {
        return map;
      }

      return null;
    }

    final candidates = [
      callData['user'],
      callData['caller_user'],
      callData['caller_info'],
      callData['caller'],
      payload['user'],
      payload['caller_user'],
      payload['caller_info'],
      payload['caller'],
      payload['sender'],
      payload['from_user'],
      payload['data'],
      payload['call_data'],
      payload['livestream_call'],
      payload['live_call'],
      payload['call'],
    ];

    for (final candidate in candidates) {
      final user = asUser(candidate);
      if (user != null) return user;
    }

    return null;
  }

  void _normalizeUnifiedCallUser(
      Map<String, dynamic> payload,
      Map<String, dynamic> callData,
      ) {
    final user = _extractCallerUserFromPayload(payload, callData);

    if (user != null) {
      callData['user'] = user;

      /// caller_id missing hole user id diye fill.
      callData['caller_id'] = callData['caller_id'] ??
          callData['user_id'] ??
          user['id'];

      /// User-er id missing hole caller_id diye fill.
      if (callData['user'] is Map && callData['user']['id'] == null) {
        callData['user']['id'] = callData['caller_id'];
      }
    } else {
      /// Backend jodi user object na pathay, at least popup e Unknown/null
      /// na dekhiye caller id show korbe.
      final fallbackId = callData['caller_id'] ??
          callData['user_id'] ??
          payload['caller_id'] ??
          payload['user_id'];

      callData['user'] = {
        'id': fallbackId,
        'user_id': fallbackId,
        'name': fallbackId == null ? 'Unknown User' : 'User $fallbackId',
        'level': 0,
        'profile_image': '',
      };
    }
  }

  bool _hasRealCallerUser(Map<String, dynamic> callData) {
    final user = callData['user'];
    if (user is! Map) return false;

    final name = user['name']?.toString() ?? '';
    final image = user['profile_image']?.toString() ?? '';

    /// fallback User 100363 ke real user dhora jabe na.
    return name.isNotEmpty &&
        !name.startsWith('User ') &&
        name != 'Unknown User' &&
        (user['level'] != null || image.isNotEmpty);
  }

  Future<void> _hydrateCallDataFromServer(
      Map<String, dynamic> callData,
      dynamic livestreamId,
      dynamic callerId,
      ) async {
    try {
      if (_hasRealCallerUser(callData)) return;
      if (livestreamId == null || callerId == null) return;

      /// API theke latest call list niye caller-er full user data merge korbo.
      /// streamId sometimes String ashe, API function int expect kore.
      final int? sid = int.tryParse(livestreamId.toString());
      await livestreamController.tryToGetCallList(
        streamId: sid ?? livestreamId,
      );

      Map? matched;

      for (final call in pendingCall) {
        if (call is Map &&
            call['caller_id'].toString() == callerId.toString()) {
          matched = call;
          break;
        }
      }

      matched ??= liveCallList.firstWhereOrNull((call) {
        return call is Map &&
            call['caller_id'].toString() == callerId.toString();
      });

      if (matched != null) {
        final full = Map<String, dynamic>.from(matched);
        callData.addAll(full);

        if (full['user'] is Map) {
          callData['user'] = Map<String, dynamic>.from(full['user']);
        }

        print('✅ Caller user data hydrated from API for caller: $callerId');
      } else {
        print('⚠️ Caller not found in call list while hydrating: $callerId');
      }
    } catch (e) {
      print('❌ Caller user hydrate failed: $e');
    }
  }


  void _applyNormalSeatAudioState(Map<String, dynamic> callData) {
    /// Fresh seat join must start NORMAL/UNMUTED unless backend explicitly
    /// sends audio_on=0/is_muted=1. This prevents old mute state from sticking
    /// after user was removed from mic and sits again.
    final int normalized = _normalizeAudioOn(callData);
    final int audioOn = normalized == -1 ? 1 : normalized;

    callData['audio_on'] = audioOn;
    callData['is_audio_on'] = audioOn;
    callData['is_muted'] = audioOn == 1 ? 0 : 1;
    callData['is_muted_by_host'] = audioOn == 1 ? 0 : 1;
    callData['is_speaking'] = false;

    if (callData['user'] is Map) {
      final user = Map<String, dynamic>.from(callData['user']);
      user['audio_on'] = audioOn;
      user['is_audio_on'] = audioOn;
      user['is_muted'] = audioOn == 1 ? 0 : 1;
      callData['user'] = user;
    }
  }

  Future<void> _forceRepublishMySeatMic({required String reason}) async {
    /// Agora sometimes stays silent after seat leave/rejoin unless the mic
    /// is re-published with ChannelMediaOptions again.
    final engine = _agoraService.engine;
    if (engine == null) return;

    try {
      await engine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );
      await engine.enableAudio();
      await engine.enableLocalAudio(true);

      try {
        await engine.updateChannelMediaOptions(
          const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
          ),
        );
      } catch (e) {
        print('⚠️ republish updateChannelMediaOptions skipped => $e');
      }

      await engine.muteLocalAudioStream(false);

      try {
        await engine.adjustRecordingSignalVolume(100);
      } catch (_) {}

      try {
        await engine.enableAudioVolumeIndication(
          interval: 200,
          smooth: 3,
          reportVad: true,
        );
      } catch (_) {}

      livestreamController.mute.value = false;
      print('✅ Seat mic republished for current user => $reason');
    } catch (e) {
      print('❌ Seat mic republish failed => $reason error=$e');
    }
  }

  Future<void> _handleUnifiedLiveCall(Map<String, dynamic> payload) async {
    /// Backend-er unified event-e call data sometimes different key-te ase:
    /// call_data / caller / livestream_call / data / direct payload.
    final dynamic rawCallData = payload['call_data'] ??
        payload['caller'] ??
        payload['livestream_call'] ??
        payload['live_call'] ??
        payload['call'] ??
        payload['data'] ??
        payload;

    if (rawCallData is! Map) {
      print('⚠️ live_stream_call invalid payload: $payload');
      return;
    }

    final callData = Map<String, dynamic>.from(rawCallData);

    /// Popup-er name/profile/level null issue fix:
    /// backend payload-er jekhanei user data thakuk, ekhane normalize kore
    /// callData['user'] e boshiye dicchi.
    _normalizeUnifiedCallUser(payload, callData);

    /// ✅ Video call request is not a real locked seat.
    /// Backend may send seat_no=100 and is_locked=yes for video call request.
    /// That old value must not pollute seat/call UI.
    final String incomingCallType = (callData['call_type'] ?? payload['call_type'] ?? '').toString().toLowerCase();
    final int incomingSeatNo = _toInt(callData['seat_no'] ?? payload['seat_no']);
    if ((incomingCallType == 'video' || incomingCallType == 'popular') && incomingSeatNo >= 100) {
      callData['is_locked'] = 'no';
      callData['seat_locked'] = 0;
      callData['lock_status'] = 'unlocked';
    }

    final livestreamId = callData['livestream_id'] ??
        callData['stream_id'] ??
        payload['livestream_id'] ??
        payload['stream_id'];

    /// streamID empty/null thakle current room set kore nebo, nahole popup block hoy.
    if ((streamID.value.toString().isEmpty) &&
        livestreamId != null) {
      streamID.value = livestreamId;
    }

    if (livestreamId != null && !_isCurrentStream(livestreamId)) {
      print(
          'ℹ️ live_stream_call ignored. event stream=$livestreamId current=${streamID.value}');
      return;
    }

    final callerId = _toInt(
      callData['caller_id'] ??
          callData['user_id'] ??
          callData['user']?['id'] ??
          callData['user']?['user_id'] ??
          payload['caller_id'] ??
          payload['user_id'],
    );

    if (callerId == 0) {
      print('⚠️ live_stream_call caller_id missing: $payload');
      return;
    }

    /// Pending event-e backend sometimes only caller_id dey.
    /// Popup show-er age API call list theke full name/profile/level merge kori.
    await _hydrateCallDataFromServer(callData, livestreamId, callerId);
    _normalizeUnifiedCallUser(payload, callData);

    final String callTypeAfterHydrate = (callData['call_type'] ?? payload['call_type'] ?? '').toString().toLowerCase();
    final int seatAfterHydrate = _toInt(callData['seat_no'] ?? payload['seat_no']);
    if ((callTypeAfterHydrate == 'video' || callTypeAfterHydrate == 'popular') && seatAfterHydrate >= 100) {
      callData['is_locked'] = 'no';
      callData['seat_locked'] = 0;
      callData['lock_status'] = 'unlocked';
    }

    /// Normalize status from many possible backend keys.
    String callStatus = (callData['call_status'] ??
        callData['status'] ??
        payload['call_status'] ??
        payload['status'] ??
        '')
        .toString()
        .toLowerCase()
        .trim();

    final action = (callData['action'] ??
        callData['call_action'] ??
        payload['action'] ??
        payload['call_action'] ??
        '')
        .toString()
        .toLowerCase()
        .trim();

    final actionType =
    (payload['action_type'] ?? payload['type'] ?? '').toString();

    if (callStatus.isEmpty) {
      if (action == 'call_request' ||
          action == 'request' ||
          action == 'pending' ||
          actionType == 'live_stream_call') {
        callStatus = 'pending';
      } else if (action == 'call_accept' ||
          action == 'call_accepted' ||
          action == 'accepted') {
        callStatus = 'accepted';
      } else if (action == 'call_reject' ||
          action == 'call_rejected' ||
          action == 'rejected') {
        callStatus = 'rejected';
      } else if (action == 'call_cancel' ||
          action == 'call_canceled' ||
          action == 'canceled') {
        callStatus = 'canceled';
      } else if (actionType == 'multi_live_seat_joined') {
        callStatus = 'joined';
      } else if (actionType == 'multi_live_seat_left') {
        callStatus = 'left';
      }
    }

    /// Backend jodi call_status empty dei but caller data ase, eta normally
    /// broadcaster-er jonno incoming request. Tai pending hisebe handle.
    if (callStatus.isEmpty) {
      callStatus = 'pending';
    }

    final currentUserId = authController.userProfile.value.user?.id;
    final isMeCaller = currentUserId.toString() == callerId.toString();

    final popupKey = _callPopupKey(
      streamId: livestreamId ?? streamID.value,
      callerId: callerId,
      callType: callData['call_type'] ?? 'audio',
    );

    /// Jodi ei caller already liveCallList e accepted thake, late pending event ignore.
    final alreadyAccepted = liveCallList.any((call) {
      return call['caller_id'].toString() == callerId.toString() &&
          (call['call_status']?.toString().toLowerCase() == 'accepted' ||
              call['call_status']?.toString().toLowerCase() == 'joined');
    });

    if (callStatus == 'pending' &&
        (_handledCallPopupKeys.contains(popupKey) || alreadyAccepted)) {
      pendingCall.removeWhere(
            (call) => call['caller_id'].toString() == callerId.toString(),
      );
      pendingCall.refresh();
      print('ℹ️ Duplicate/late pending call ignored: $popupKey');
      return;
    }

    if (callStatus == 'accepted' || callStatus == 'joined') {
      _activeCallPopupKeys.remove(popupKey);
      _handledCallPopupKeys.add(popupKey);

      pendingCall.removeWhere(
              (call) => call['caller_id'].toString() == callerId.toString());

      if (!liveCallList.any((call) {
        if (call is! Map) return false;
        final oldCallerId = call['caller_id'] ?? call['user_id'] ?? (call['user'] is Map ? call['user']['id'] : null);
        return oldCallerId.toString() == callerId.toString();
      })) {
        _applyNormalSeatAudioState(callData);
        liveCallList.add(callData);
        print('✅ Fresh seat join added with normal audio state => caller:$callerId audio_on:${callData['audio_on']}');
      } else {
        final index = liveCallList.indexWhere((call) {
          if (call is! Map) return false;
          final oldCallerId = call['caller_id'] ?? call['user_id'] ?? (call['user'] is Map ? call['user']['id'] : null);
          return oldCallerId.toString() == callerId.toString();
        });
        if (index != -1) {
          final old = liveCallList[index] is Map
              ? Map<String, dynamic>.from(liveCallList[index])
              : <String, dynamic>{};

          /// Preserve full profile/name/frame + mute/video state if late refresh event has null/minimal data.
          final merged = <String, dynamic>{
            ...old,
            ...callData,
          };

          final oldUser = old['user'] is Map ? Map<String, dynamic>.from(old['user']) : <String, dynamic>{};
          final newUser = callData['user'] is Map ? Map<String, dynamic>.from(callData['user']) : <String, dynamic>{};

          final newName = newUser['name']?.toString() ?? '';
          final oldName = oldUser['name']?.toString() ?? '';
          final newLooksFallback = newName.isEmpty ||
              newName == 'Unknown User' ||
              newName.startsWith('User ');

          if (oldUser.isNotEmpty && (newUser.isEmpty || newLooksFallback) && oldName.isNotEmpty) {
            merged['user'] = oldUser;
          } else {
            merged['user'] = {
              ...oldUser,
              ...newUser,
            };
          }

          /// Preserve mute state if the new event is partial/missing audio keys.
          final int newAudio = _normalizeAudioOn(callData);
          final int oldAudio = _normalizeAudioOn(old);

          /// ✅ Seat re-join fix:
          /// If a user left while host-muted, old muted state should NOT stick
          /// when he sits again. For a fresh seat_joined event, missing audio key
          /// means default NORMAL/UNMUTED.
          final bool isSeatJoinedEvent = actionType == 'multi_live_seat_joined' ||
              callStatus == 'joined' ||
              callStatus == 'accepted';

          /// Fresh seat join/accept means old host-muted state should NOT carry.
          /// Backend sometimes returns stale audio_on=0 after remove; force normal.
          final int mergedAudio = isSeatJoinedEvent
              ? 1
              : (newAudio == -1
              ? (oldAudio == -1
              ? (old['audio_on']?.toString() == '0' ? 0 : 1)
              : oldAudio)
              : newAudio);

          merged['audio_on'] = mergedAudio;
          merged['is_audio_on'] = mergedAudio;
          merged['is_muted'] = mergedAudio == 1 ? 0 : 1;
          merged['is_muted_by_host'] = mergedAudio == 1 ? 0 : 1;

          if (isSeatJoinedEvent) {
            final int joinedUserId = int.tryParse(
              (merged['user'] is Map
                  ? merged['user']['id']
                  : (merged['user_id'] ?? merged['caller_id'] ?? callerId))
                  ?.toString() ??
                  '0',
            ) ??
                0;
            if (joinedUserId > 0) {
              audioMutedUserMap[joinedUserId] = false;
              audioMutedUserMap.refresh();
              print('✅ Seat join cleared old mute state => user:$joinedUserId');
            }
          }

          /// Preserve seat/user earned coin when late refresh sends empty/zero values.
          final int oldEarnCoins = _toInt(old['earn_coins'] ?? old['gift_coins'] ?? old['received_coins']);
          final int newEarnCoins = _toInt(callData['earn_coins'] ?? callData['gift_coins'] ?? callData['received_coins']);
          if (newEarnCoins == 0 && oldEarnCoins > 0) {
            merged['earn_coins'] = oldEarnCoins;
          } else if (newEarnCoins > 0) {
            merged['earn_coins'] = newEarnCoins;
          }

          if (merged['user'] is Map) {
            final userMap = Map<String, dynamic>.from(merged['user']);
            final int oldUserEarn = _toInt(oldUser['earned_coins'] ?? oldUser['gifts_coins'] ?? oldUser['coins']);
            final int newUserEarn = _toInt(newUser['earned_coins'] ?? newUser['gifts_coins'] ?? newUser['coins']);
            if (newUserEarn == 0 && oldUserEarn > 0) {
              userMap['earned_coins'] = oldUserEarn;
            }
            merged['user'] = userMap;
          }

          merged['video_on'] = callData['video_on'] ?? old['video_on'];
          merged['seat_no'] = callData['seat_no'] ?? old['seat_no'];
          merged['call_status'] = callData['call_status'] ?? old['call_status'] ?? 'accepted';

          liveCallList[index] = merged;
        }
      }

      if (isMeCaller) {
        if (callData['call_type'] == "video" || callData['call_type'] == "pk") {
          await _agoraService.engine?.enableVideo();
          await _agoraService.engine?.enableLocalVideo(true);
          await _agoraService.engine?.muteLocalVideoStream(false);
        }

        await _forceRepublishMySeatMic(reason: 'seat_join_or_accept caller=$callerId');

        print('✅ Caller media published after accept/join: ${callData['call_type']}');
      }

      syncLivestreamCallers();
    } else if (callStatus == 'pending') {
      /// New pending request must be able to show again after old request was cleared.
      _handledCallPopupKeys.remove(popupKey);

      if (!pendingCall
          .any((call) => call['caller_id'].toString() == callerId.toString())) {
        pendingCall.add(callData);
      } else {
        final index = pendingCall.indexWhere(
              (call) => call['caller_id'].toString() == callerId.toString(),
        );
        if (index != -1) {
          pendingCall[index] = callData;
        }
      }

      /// Broadcaster-er app-e incoming video/audio call popup show korbe.
      /// Caller nijer app-e popup show korbe na.
      if (livestreamController.isBroadcaster.value && !isMeCaller) {
        if (_activeCallPopupKeys.contains(popupKey) ||
            _handledCallPopupKeys.contains(popupKey)) {
          print('ℹ️ Duplicate call popup skipped: $popupKey');
        } else {
          _activeCallPopupKeys.add(popupKey);
          _showCallRequestPopup(
            callData,
            rtcEngine: _agoraService.engine,
            popupKey: popupKey,
          );
        }
      }

      print(
          '📞 Unified incoming call request => caller=$callerId type=${callData['call_type']} status=$callStatus');
    } else if (callStatus == 'canceled' ||
        callStatus == 'cancelled' ||
        callStatus == 'rejected' ||
        callStatus == 'left') {
      _activeCallPopupKeys.remove(popupKey);
      _handledCallPopupKeys.remove(popupKey);

      _clearStaleCallStateForUser(
        callerId: callerId,
        streamId: livestreamId,
        removeAcceptedCall: true,
        closePopupIfOpen: true,
        reason: 'call_$callStatus',
      );

      final int leavingUserId = int.tryParse(callerId.toString() ?? '0') ?? 0;
      if (leavingUserId > 0) {
        audioMutedUserMap.remove(leavingUserId);
        audioMutedUserMap.refresh();
        print('✅ Seat leave cleared cached mute state => user:$leavingUserId');
      }

      /// ✅ Seat/mic leave fix:
      /// Leaving/removing from mic must clear old mute state. Otherwise host side
      /// can keep showing muted and next seat join may inherit muted state.
      /// Do not force any row to unmuted before removing.
      /// Seat leave/remove event can contain actor/host ids in some payloads;
      /// pre-setting audio_on=1 caused host mute icon to wrongly show unmuted
      /// on audience devices. Fresh rejoin is normalized separately.
      liveCallList.removeWhere((call) {
        if (call is! Map) return false;
        final oldCallerId = call['caller_id'] ??
            call['user_id'] ??
            (call['user'] is Map ? call['user']['id'] : null);
        return oldCallerId.toString() == callerId.toString();
      });

      if (isMeCaller) {
        /// User mic theke namle local state normal kore dei.
        /// Audience role-e jawar por stream publish off thakbe, but old
        /// host-mute/self-mute state future seat join-e carry hobe na.
        livestreamController.mute.value = false;
        await _agoraService.engine?.enableAudio();
        await _agoraService.engine?.enableLocalAudio(true);
        await _agoraService.engine?.muteLocalAudioStream(true);
        await _agoraService.engine?.muteLocalVideoStream(true);
        try {
          await _agoraService.engine?.updateChannelMediaOptions(
            const ChannelMediaOptions(
              clientRoleType: ClientRoleType.clientRoleAudience,
              publishMicrophoneTrack: false,
              autoSubscribeAudio: true,
            ),
          );
        } catch (e) {
          print('⚠️ audience media option update skipped after seat leave => $e');
        }
        await _agoraService.engine
            ?.setClientRole(role: ClientRoleType.clientRoleAudience);
        print('✅ Current user removed from seat; old mute state reset for next join');
      }

      syncLivestreamCallers();
    }

    liveCallList.refresh();
    pendingCall.refresh();

    print('✅ Unified live call handled: $callStatus');
  }

  Future<void> _handleUnifiedModeration(Map<String, dynamic> payload) async {
    try {
      final moderationData = Map<String, dynamic>.from(
        payload['moderation_data'] ?? payload['data'] ?? payload,
      );

      final action = (moderationData['action'] ??
          moderationData['moderation_action'] ??
          moderationData['type'] ??
          moderationData['action_type'] ??
          '')
          .toString()
          .toLowerCase();

      print('🔔 Unified moderation action => $action payload=$moderationData');

      switch (action) {
        case 'kickout':
        case 'kick_out':
          _handleKickOut(moderationData);
          break;

        case 'audio_toggle':
        case 'multi_live_audio_toggle':
        case 'mute':
        case 'unmute':
          await _handleUnifiedAudioToggle(moderationData);
          break;

        case 'video_toggle':
        case 'multi_live_video_toggle':
          await _handleUnifiedVideoToggle(moderationData);
          break;

        case 'live_stream_ended':
        case 'live_ended':
        case 'broadcaster_disconnected':
          _handleUnifiedLiveStreamEnded(moderationData);
          break;

        default:
          print('ℹ️ Unknown moderation action: $action');
          print('Payload: $moderationData');
          break;
      }
    } catch (e, st) {
      print('❌ _handleUnifiedModeration error => $e\n$st');
    }
  }

  Future<void> _handleUnifiedAudioToggle(Map<String, dynamic> payload) async {
    try {
      print('🎙️ AUDIO TOGGLE RAW => $payload');

      final Map<String, dynamic> data = payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'])
          : Map<String, dynamic>.from(payload);

      final dynamic livestreamId =
          data['livestream_id'] ?? data['stream_id'] ?? payload['livestream_id'];

      // if (livestreamId != null && !_isCurrentOrPkStream(livestreamId, logPrefix: 'AUDIO_TOGGLE')) {
      //   print('⛔ AUDIO_TOGGLE ignored: other stream => $livestreamId');
      //   return;
      // }

      /// Target user id can come with different keys depending on backend/API.
      /// IMPORTANT: host mute must be applied on the TARGET audience/caller device,
      /// not only update the UI icon on broadcaster side.
      final dynamic seatNo = data['seat_no'] ??
          data['seat'] ??
          data['seat_number'] ??
          data['seatNo'];

      final bool hasExplicitTargetUser =
          data['target_user_id'] != null ||
              data['receiver_id'] != null ||
              data['to_user_id'] != null ||
              data['caller_id'] != null ||
              data['user_id'] != null ||
              data['uid'] != null;

      dynamic userId = data['target_user_id'] ??
          data['receiver_id'] ??
          data['to_user_id'] ??
          data['caller_id'] ??
          data['user_id'] ??
          data['uid'];

      /// Host-er nijer mute/unmute event-e kichu backend only host_id/broadcaster_id
      /// pathay. Seat remove/join event-e host_id actor hote pare, tai only
      /// audio_toggle handler-e explicit target na thakle ebong seatNo na thakle
      /// host_id ke host mute target dhorbo.
      if (!hasExplicitTargetUser && seatNo == null) {
        userId = data['host_id'] ??
            data['broadcaster_id'] ??
            data['broadcaster_user_id'] ??
            payload['host_id'] ??
            payload['broadcaster_id'];
      }

      final dynamic audioRaw = data['audio_on'] ??
          data['is_audio_on'] ??
          data['mic_on'] ??
          data['microphone_on'];

      final dynamic mutedRaw = data['is_muted'] ??
          data['muted'] ??
          data['is_muted_by_host'] ??
          data['mute_status'];

      bool audioFalse(dynamic v) {
        final s = v?.toString().toLowerCase().trim() ?? '';
        return s == '0' ||
            s == 'false' ||
            s == 'no' ||
            s == 'off' ||
            s == 'mute' ||
            s == 'muted';
      }

      bool audioTrue(dynamic v) {
        final s = v?.toString().toLowerCase().trim() ?? '';
        return s == '1' ||
            s == 'true' ||
            s == 'yes' ||
            s == 'on' ||
            s == 'unmute' ||
            s == 'unmuted';
      }

      bool? muted;

      if (audioFalse(audioRaw)) muted = true;
      if (audioTrue(audioRaw)) muted = false;

      /// is_muted true means muted, is_muted false means unmuted.
      if (audioTrue(mutedRaw)) muted = true;
      if (audioFalse(mutedRaw)) muted = false;

      /// No audio/mute key means this is a partial payload. Never reset old state.
      if (muted == null) {
        print('🎙️ AUDIO_TOGGLE skipped: no clear audio/mute state');
        return;
      }

      final int currentUserId =
          authController.userProfile.value.user?.id?.toInt() ?? 0;

      final int targetUserIdForMuteMap = int.tryParse(userId?.toString() ?? '0') ?? 0;
      if (targetUserIdForMuteMap > 0) {
        audioMutedUserMap[targetUserIdForMuteMap] = muted;
        audioMutedUserMap.refresh();
        print('✅ Known audio state saved => user:$targetUserIdForMuteMap muted:$muted');
      }

      bool updated = false;
      bool eventTargetsCurrentUser = false;

      for (int i = 0; i < liveCallList.length; i++) {
        final item = liveCallList[i];
        if (item is! Map) continue;

        final Map<String, dynamic> call = Map<String, dynamic>.from(item);

        final dynamic itemUserId = call['user'] is Map
            ? call['user']['id']
            : (call['user_id'] ?? call['caller_id'] ?? call['id']);

        final dynamic itemSeatNo =
            call['seat_no'] ?? call['seat'] ?? call['seat_number'] ?? call['seatNo'];

        final bool sameUser = userId != null &&
            itemUserId != null &&
            userId.toString() == itemUserId.toString();

        final bool sameSeat = seatNo != null &&
            itemSeatNo != null &&
            seatNo.toString() == itemSeatNo.toString();

        if (sameUser || sameSeat) {
          final dynamic rowUserId = call['user'] is Map
              ? call['user']['id']
              : (call['user_id'] ?? call['caller_id'] ?? call['id']);

          final bool rowIsCurrentUser = currentUserId > 0 &&
              rowUserId != null &&
              rowUserId.toString() == currentUserId.toString();

          if (rowIsCurrentUser) {
            eventTargetsCurrentUser = true;
          }

          final int rowUserInt = int.tryParse(rowUserId?.toString() ?? '0') ?? 0;
          if (rowUserInt > 0) {
            audioMutedUserMap[rowUserInt] = muted;
          }

          call['audio_on'] = muted ? 0 : 1;
          call['is_muted'] = muted ? 1 : 0;
          call['is_muted_by_host'] = muted ? 1 : 0;

          if (call['user'] is Map) {
            final user = Map<String, dynamic>.from(call['user']);
            user['audio_on'] = muted ? 0 : 1;
            user['is_muted'] = muted ? 1 : 0;
            call['user'] = user;
          }

          liveCallList[i] = call;
          updated = true;
        }
      }

      /// If backend sends only user_id (without hydrated liveCallList row yet),
      /// still apply the real Agora mic state when this event is for me.
      if (currentUserId > 0 &&
          userId != null &&
          userId.toString() == currentUserId.toString()) {
        eventTargetsCurrentUser = true;
      }

      if (updated) {
        liveCallList.refresh();
        audioMutedUserMap.refresh();
        livestreamController.update();
        print('✅ AUDIO_TOGGLE applied => user=$userId seat=$seatNo muted=$muted');
      } else {
        print('⚠️ AUDIO_TOGGLE no matching liveCallList row => user=$userId seat=$seatNo muted=$muted');
      }

      /// ✅ CRITICAL FIX v3:
      /// Host/admin mute/unmute must control the TARGET user's real Agora
      /// microphone publishing state. UI icon update alone is not enough.
      ///
      /// Important:
      /// - Never keep enableLocalAudio(false) after host-unmute.
      /// - On unmute, force caller role back to broadcaster and explicitly
      ///   publish microphone track again. Otherwise UI can show unmuted but
      ///   the host will not hear audio until the user taps his own mic button.
      if (eventTargetsCurrentUser && _agoraService.engine != null) {
        final engine = _agoraService.engine!;

        // Keep controller self mute flag in sync with host/admin mute state.
        // write_comments.dart uses livestreamController.mute as fallback.
        livestreamController.mute.value = muted;

        if (muted) {
          await engine.enableAudio();
          await engine.setClientRole(
            role: ClientRoleType.clientRoleBroadcaster,
          );
          await engine.enableLocalAudio(true);
          await engine.muteLocalAudioStream(true);

          // Extra safety: stop volume/wave from this local user while muted.
          try {
            await engine.adjustRecordingSignalVolume(0);
          } catch (_) {}

          print('✅ AUDIO_TOGGLE local Agora MIC MUTED by host => muted=true');
        } else {
          // Force full microphone re-publish when host unmute kore.
          // Order matters for Agora: role -> audio engine -> local audio -> unmute.
          await engine.setClientRole(
            role: ClientRoleType.clientRoleBroadcaster,
          );
          await engine.enableAudio();
          await engine.enableLocalAudio(true);

          // Agora 6.x: make sure microphone publishing is turned back on.
          // Some devices keep publishMicrophoneTrack=false after admin mute/role switch.
          try {
            await engine.updateChannelMediaOptions(
              const ChannelMediaOptions(
                clientRoleType: ClientRoleType.clientRoleBroadcaster,
                publishMicrophoneTrack: true,
                autoSubscribeAudio: true,
              ),
            );
          } catch (e) {
            print('⚠️ updateChannelMediaOptions audio republish skipped => $e');
          }

          await engine.muteLocalAudioStream(false);

          // Restore recording volume. Without this, wave/audio can stay silent
          // after previous forced mute.
          try {
            await engine.adjustRecordingSignalVolume(100);
          } catch (_) {}

          try {
            await engine.enableAudioVolumeIndication(
              interval: 200,
              smooth: 3,
              reportVad: true,
            );
          } catch (_) {}

          print('✅ AUDIO_TOGGLE local Agora MIC UNMUTED + REPUBLISHED by host => muted=false');
        }
      }
    } catch (e, st) {
      print('❌ _handleUnifiedAudioToggle error => $e\n$st');
    }
  }

  Future<void> _handleUnifiedVideoToggle(Map<String, dynamic> payload) async {
    await _handleVideoToggle({
      ...payload,
      'user_id': payload['user_id'] ?? payload['caller_id'],
      'video_on': payload['video_on'] ?? payload['is_video_on'] ?? 0,
    });
  }

  void _handleUnifiedSpeaking(Map<String, dynamic> payload) {
    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'])
        : Map<String, dynamic>.from(payload);

    final userId = data['user_id'] ??
        data['target_user_id'] ??
        data['receiver_id'] ??
        data['caller_id'] ??
        data['uid'];
    final isSpeaking = data['is_speaking'] ?? data['speaking'] ?? false;

    final index = liveCallList.indexWhere((call) {
      if (call is! Map) return false;
      final dynamic rowUserId = call['user'] is Map
          ? call['user']['id']
          : (call['caller_id'] ?? call['user_id'] ?? call['id']);
      return rowUserId.toString() == userId.toString();
    });

    if (index != -1) {
      final item = liveCallList[index];
      if (item is Map) {
        final call = Map<String, dynamic>.from(item);
        final bool muted = call['audio_on']?.toString() == '0' ||
            call['is_muted']?.toString() == '1' ||
            call['is_muted_by_host']?.toString() == '1';

        /// Muted seat/user should not show voice wave even if a late speaking
        /// event arrives from Agora/backend.
        call['is_speaking'] = muted ? false : isSpeaking;
        liveCallList[index] = call;
      } else {
        liveCallList[index]['is_speaking'] = isSpeaking;
      }
      liveCallList.refresh();
    }
  }

  void _handleUnifiedRedPacketCollected(Map<String, dynamic> payload) {
    _cancelRedPacketTimer();
    _cancelGlobalRedPacketTimer();
    hideRedPacket();
    hideGlobalRedPacket();

    if (onRedPacketCollected != null) {
      onRedPacketCollected!(payload);
    }

    print('✅ Unified red packet collected');
  }

  void _handleUnifiedGameAction(
      String actionType,
      Map<String, dynamic> payload,
      ) {
    /// Keep game-specific UI/controller update here.
    /// Example:
    /// greedyController.handleEvent(actionType, payload);
    /// fruitGameController.handleEvent(actionType, payload);
    print('🎮 Game event received: $actionType => $payload');
  }


  // ===========================================================================
  // VIDEO PK SYSTEM - websocket handlers
  // ===========================================================================

  int _pkToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Map<String, dynamic> _pkAsMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  void _handlePkRequestReceived(Map<String, dynamic> payload) {
    final data = _pkAsMap(payload['data']);
    final source = data.isNotEmpty ? {...payload, ...data} : payload;
    final pkId = _pkToInt(source['pk_id'] ?? source['id']);
    final receiverHostId = _pkToInt(source['to_host_id'] ?? source['receiver_host_id']);
    final fromHostId = _pkToInt(source['from_host_id'] ?? source['sender_host_id']);
    final fromLivestreamId = _pkToInt(source['from_livestream_id'] ?? source['sender_livestream_id']);

    final currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (receiverHostId != 0 && currentUserId != 0 && receiverHostId != currentUserId) {
      return;
    }

    if (pkId <= 0) return;

    if (Get.isDialogOpen == true) {
      Get.back();
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Colors.pinkAccent),
            SizedBox(width: 8),
            Text('PK Request'),
          ],
        ),
        content: Text(
          payload['message']?.toString() ??
              'Host $fromHostId wants to start PK with you.\nLive ID: $fromLivestreamId',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (Get.isDialogOpen == true) Get.back();
              await livestreamController.respondPkRequest(
                pkId: pkId,
                receiverHostId: receiverHostId == 0 ? currentUserId : receiverHostId,
                responseText: 'rejected',
              );
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (Get.isDialogOpen == true) Get.back();
              await livestreamController.respondPkRequest(
                pkId: pkId,
                receiverHostId: receiverHostId == 0 ? currentUserId : receiverHostId,
                responseText: 'accepted',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPkWaitingToast(Map<String, dynamic> payload) {
    Fluttertoast.showToast(
      msg: payload['message']?.toString() ?? 'Waiting for host to accept PK request...',
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }


  @override
  void onClose() {
    _unifiedReconnectTimer?.cancel();
    _unifiedReconnectTimer = null;
    try {
      liveStreamEventChannel?.sink.close();
    } catch (_) {}

    _activeCallPopupKeys.clear();
    _handledCallPopupKeys.clear();
    _locallyLeftStreamIds.clear();
    _viewerJoinedAtMs.clear();

    lockedSeatMap.clear();

    liveCallList.clear();
    pendingCall.clear();
    livestreamController.liveViewerList.clear();
    super.onClose();
  }
}
