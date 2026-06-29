import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';
import 'package:meetlivepro/app/modules/livestream/controllers/websocket_controller.dart';



import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../services/agora_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../messanger/views/audio_call_view.dart';
import '../../messanger/views/video_call_view.dart';
import '../endLive/endLive.dart';
import '../views/audio_live_view.dart';
import '../views/multi_live_view.dart';
import '../views/popular_live_view.dart';
import 'agoraTokenController.dart';

class LivestreamController extends GetxController {
  RxBool isLocked = false.obs;
  RxBool isShow = false.obs;
  RxBool showProfile = false.obs;
  RxBool showPkRoom = false.obs;
  RxBool showPkView = false.obs;
  RxBool selectSuperMic = false.obs;
  RxBool effectSetting = false.obs;
  RxBool selectedRoom = false.obs;
  RxBool isMuted = false.obs;
  RxBool hidePk = false.obs;
  int selectPaymentIndex = 0;

  final RxBool showMiniScene = false.obs;
  final dio = Dio();
  final AuthController authController = Get.find();
  final isLock = true.obs;
  final audienscMute = false.obs;

  /// ===================== LIVE MUSIC / AUDIO MIXING =====================
  /// Host local gallery music path. Audience only gets status/name by websocket.
  final selectedMusicPath = ''.obs;
  final liveMusicName = ''.obs;
  final liveMusicStatus = 'stopped'.obs; // playing, paused, resumed, stopped, changed
  final musicLoading = false.obs;

  /// ===================== LIVE YOUTUBE CONTROL =====================
  /// YouTube video locally play hobe sob audience app-e.
  /// Host mute/music mute er sathe YouTube sound relation nai.
  final liveYoutubeStatus = 'stopped'.obs; // playing, paused, resumed, stopped, changed
  final liveYoutubeUrl = ''.obs;
  final liveYoutubeVideoId = ''.obs;
  final youtubeLoading = false.obs;


  bool get isLiveMusicPlaying =>
      liveMusicStatus.value == 'playing' ||
          liveMusicStatus.value == 'resumed' ||
          liveMusicStatus.value == 'changed';

  AgoraTokenController agoraTokenController = Get.find();

  // ---------------------- Emoji send -------
  RxBool showEmoji = false.obs;

  List<String> emojiList = ['😄', '😂', '😍', '🔥', '👍', '🥳'];


  /// ===================== LIVE IMOGI / EMOJI =====================
  /// Old emojiList stays unchanged. These states are only for backend imogi.
  final imogiLoading = false.obs;
  final imogiSending = false.obs;
  final selectedImogiCategoryIndex = 0.obs;

  /// Category list format:
  /// [{id,name,image,imogies:[...]}]
  final imogiCategoryList = <Map<String, dynamic>>[].obs;

  /// Flat imogi list fallback.
  final imogiList = <Map<String, dynamic>>[].obs;


  RxInt selectedIndex1 = (-1).obs;
  void selectRoom(int index) {
    selectedIndex1.value = index;
  }

  final durations = ['1 Month', '3 Months', '6 Months', '12 Months'];
  RxInt selectedIndex = 0.obs;

  final mute = false.obs;
  final voice = false.obs;
  final hasJoinedCall = false.obs;

  final List<String> nationalIdentity = [
    'Please set room password',
    'Please set room gift',
  ];
  final selectedType = 'Please set room password'.obs;

  final String appId = "d0015737a05546b6be82f188951f5772";

  //for live stream

  final isBroadcaster = false.obs;
  final isHost = false.obs;
  final streamId = 1.obs;
  final broadcasterId = 0.obs;
  //for live stream start
  //generate token
  final getTokens = {}.obs;
  WebsocketController get websocketController =>
      Get.find<WebsocketController>();

  Timer? _pingTimer;

  /// ===================== PRESENCE / LIVE ROOM HEARTBEAT =====================
  /// Backend API:
  /// POST /api/user/heartbeat
  /// POST /api/user/offline
  /// GET  /api/user/presence/{userId}?livestream_id={streamId}
  ///
  /// Important rules:
  /// - App background/minimize hole offline call korbo na.
  /// - Live leave / seat leave / host end hole offline call hobe.
  /// - Resume hole heartbeat once + full state sync hobe.
  Timer? _presenceHeartbeatTimer;
  int _presenceStreamId = 0;
  String _presenceRole = 'viewer'; // host/viewer/caller
  bool _presenceIsOnSeat = false;
  int? _presenceSeatNo;
  bool _presenceRequestRunning = false;

  Map<String, dynamic> _presenceBody({
    int? userId,
    int? livestreamId,
    String? role,
    bool? isOnSeat,
    int? seatNo,
  }) {
    final int uid = userId ??
        authController.userProfile.value.user?.id?.toInt() ??
        0;

    final int sid = livestreamId ?? _presenceStreamId;
    final String? activeRole = role ?? (sid > 0 ? _presenceRole : null);

    final body = <String, dynamic>{
      'user_id': uid,
    };

    if (sid > 0) {
      body['livestream_id'] = sid;
      body['role'] = activeRole ?? 'viewer';
      body['is_on_seat'] = isOnSeat ?? _presenceIsOnSeat;
      body['seat_no'] = seatNo ?? _presenceSeatNo;
    }

    return body;
  }

  Future<void> sendPresenceHeartbeatOnce({
    int? livestreamId,
    String? role,
    bool? isOnSeat,
    int? seatNo,
  }) async {
    final int uid = authController.userProfile.value.user?.id?.toInt() ?? 0;

    debugPrint('================ PRESENCE HEARTBEAT START ================');
    debugPrint('👤 uid => $uid');
    debugPrint('📌 input livestreamId => $livestreamId');
    debugPrint('📌 input role => $role');
    debugPrint('📌 input isOnSeat => $isOnSeat');
    debugPrint('📌 input seatNo => $seatNo');
    debugPrint('🔐 token => ${authController.userProfile.value.token}');

    if (uid == 0) {
      debugPrint('❌ Presence heartbeat stopped: uid is 0');
      debugPrint('================ PRESENCE HEARTBEAT END ==================');
      return;
    }

    final int sid = livestreamId ?? _presenceStreamId;

    if (sid > 0) {
      _presenceStreamId = sid;
      _presenceRole = role ?? _presenceRole;
      _presenceIsOnSeat = isOnSeat ?? _presenceIsOnSeat;
      _presenceSeatNo = seatNo;
    } else if (role != null) {
      _presenceRole = role;
      _presenceIsOnSeat = isOnSeat ?? _presenceIsOnSeat;
      _presenceSeatNo = seatNo;
    }

    debugPrint('✅ final sid => $sid');
    debugPrint('✅ _presenceStreamId => $_presenceStreamId');
    debugPrint('✅ _presenceRole => $_presenceRole');
    debugPrint('✅ _presenceIsOnSeat => $_presenceIsOnSeat');
    debugPrint('✅ _presenceSeatNo => $_presenceSeatNo');
    debugPrint('✅ _presenceRequestRunning => $_presenceRequestRunning');

    if (_presenceRequestRunning) {
      debugPrint('⚠️ Presence heartbeat skipped: request already running');
      debugPrint('================ PRESENCE HEARTBEAT END ==================');
      return;
    }

    _presenceRequestRunning = true;

    final Map<String, dynamic> body = _presenceBody(
      userId: uid,
      livestreamId: sid > 0 ? sid : null,
      role: sid > 0 ? _presenceRole : null,
      isOnSeat: _presenceIsOnSeat,
      seatNo: _presenceSeatNo,
    );

    debugPrint('📤 API URL => $kMainUrl/user/heartbeat');
    debugPrint('📤 Request Body => $body');

    try {
      final response = await dio.post(
        '$kMainUrl/user/heartbeat',
        data: body,

      );

      debugPrint('📥 Response statusCode => ${response.statusCode}');
      debugPrint('📥 Response data => ${response.data}');
      debugPrint('📥 Response headers => ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Presence heartbeat ok => stream=$sid role=$_presenceRole');
      } else {
        debugPrint('⚠️ Presence heartbeat failed: ${response.statusCode}');
      }
    } catch (e, s) {
      debugPrint('❌ Presence heartbeat error => $e');
      debugPrint('❌ StackTrace => $s');
    } finally {
      _presenceRequestRunning = false;
      debugPrint('✅ _presenceRequestRunning reset => $_presenceRequestRunning');
      debugPrint('================ PRESENCE HEARTBEAT END ==================');
    }
  }

  /// ===================== NORMAL / PK AGORA SESSION =====================
  /// PK start hole normal live channel/token save kore rakha hobe.
  /// PK end hole abar normal live channel e fire jawa jabe.
  String _normalAgoraChannelName = '';
  String _normalAgoraToken = '';
  bool _normalAgoraWasBroadcaster = false;

  final RxString pkChannelName = ''.obs;
  final RxString pkSenderRoomId = ''.obs;
  final RxString pkReceiverRoomId = ''.obs;
  final RxBool pkAgoraJoining = false.obs;

  String get normalAgoraChannelName => _normalAgoraChannelName;
  String get normalAgoraToken => _normalAgoraToken;
  bool get normalAgoraWasBroadcaster => _normalAgoraWasBroadcaster;

  void saveNormalLiveAgoraSession({
    required String channelName,
    required String token,
    required bool isBroadcaster,
  }) {
    if (channelName.trim().isEmpty) return;

    _normalAgoraChannelName = channelName;
    _normalAgoraToken = token;
    _normalAgoraWasBroadcaster = isBroadcaster;

    debugPrint(
      '✅ Normal Agora session saved => channel=$channelName broadcaster=$isBroadcaster',
    );
  }

  void clearPkAgoraSession() {
    pkChannelName.value = '';
    pkSenderRoomId.value = '';
    pkReceiverRoomId.value = '';
    pkAgoraJoining.value = false;
  }

  void startLivePresenceHeartbeat({
    required int livestreamId,
    required String role,
    bool isOnSeat = false,
    int? seatNo,
    Duration interval = const Duration(seconds: 30),
  }) {
    if (livestreamId <= 0) return;

    _presenceStreamId = livestreamId;
    _presenceRole = role;
    _presenceIsOnSeat = isOnSeat;
    _presenceSeatNo = seatNo;

    _presenceHeartbeatTimer?.cancel();
    _pkTimer?.cancel();
    _presenceHeartbeatTimer = null;

    sendPresenceHeartbeatOnce(
      livestreamId: livestreamId,
      role: role,
      isOnSeat: isOnSeat,
      seatNo: seatNo,
    );

    _presenceHeartbeatTimer = Timer.periodic(interval, (_) {
      sendPresenceHeartbeatOnce(
        livestreamId: _presenceStreamId,
        role: _presenceRole,
        isOnSeat: _presenceIsOnSeat,
        seatNo: _presenceSeatNo,
      );
    });

    debugPrint('✅ Live presence started => stream=$livestreamId role=$role seat=$seatNo');
  }

  void updateLivePresenceRole({
    required String role,
    bool? isOnSeat,
    int? seatNo,
  }) {
    _presenceRole = role;
    _presenceIsOnSeat = isOnSeat ?? _presenceIsOnSeat;
    _presenceSeatNo = seatNo;

    sendPresenceHeartbeatOnce(
      livestreamId: _presenceStreamId,
      role: _presenceRole,
      isOnSeat: _presenceIsOnSeat,
      seatNo: _presenceSeatNo,
    );
  }

  void stopLivePresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
  }

  Future<void> markUserOffline({
    int? livestreamId,
    String? role,
    int? seatNo,
  }) async {
    final int uid = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (uid == 0) return;

    final int sid = livestreamId ?? _presenceStreamId;

    try {
      await dio.post(
        '$kMainUrl/user/offline',
        data: _presenceBody(
          userId: uid,
          livestreamId: sid > 0 ? sid : null,
          role: sid > 0 ? (role ?? _presenceRole) : null,
          isOnSeat: (role ?? _presenceRole) == 'caller' || (role ?? _presenceRole) == 'host',
          seatNo: seatNo ?? _presenceSeatNo,
        ),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );
      debugPrint('✅ User offline sent => stream=$sid role=${role ?? _presenceRole}');
    } catch (e) {
      debugPrint('⚠️ User offline failed safely: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchPresenceWithLiveState({
    int? livestreamId,
  }) async {
    final int uid = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (uid == 0) return null;

    final int sid = livestreamId ?? _presenceStreamId;
    final String url = sid > 0
        ? '$kMainUrl/user/presence/$uid?livestream_id=$sid'
        : '$kMainUrl/user/presence/$uid';

    try {
      final response = await dio.get(
        url,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Presence/live state fetch failed safely: $e');
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    if (value == null) return [];
    return [value];
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int? _seatNoFromCall(dynamic raw) {
    final call = _asMap(raw);
    final seat = call['seat_no'] ?? call['seat'] ?? call['seat_number'];
    final parsed = int.tryParse(seat?.toString() ?? '');
    return parsed == 0 ? null : parsed;
  }

  bool _isAcceptedCaller(Map<String, dynamic> call) {
    final status = (call['call_status'] ?? call['status'] ?? 'accepted')
        .toString()
        .toLowerCase()
        .trim();

    return status == 'accepted' ||
        status == 'joined' ||
        status == 'active' ||
        status == 'live';
  }

  Future<void> applyLivestreamState(dynamic rawState) async {
    final state = _asMap(rawState);
    if (state.isEmpty) return;

    /// Backend may return live state in different shapes:
    /// - {viewers, callers, locked_seats, livestream}
    /// - addViewer response: {viewer, livestream_callers, locked_seats, ...}
    /// - {livestream: {livestream_callers, locked_seats, ...}}
    final livestream = _asMap(state['livestream']);

    final viewers = _asList(
      state['viewers'] ??
          state['livestream_viewers'] ??
          livestream['viewers'] ??
          livestream['livestream_viewers'],
    );

    final callersRaw = _asList(
      state['callers'] ??
          state['livestream_callers'] ??
          livestream['callers'] ??
          livestream['livestream_callers'],
    );

    final lockedSeats = _asList(
      state['locked_seats'] ??
          livestream['locked_seats'] ??
          state['lockedSeats'] ??
          livestream['lockedSeats'],
    );

    if (viewers.isNotEmpty) {
      liveViewerList.assignAll(viewers);
      liveViewerList.refresh();
    } else {
      final singleViewer = state['viewer'] ?? state['viewer_data'];
      if (singleViewer is Map) {
        final viewerId = singleViewer['viewer_id'] ??
            singleViewer['user_id'] ??
            (singleViewer['user'] is Map ? singleViewer['user']['id'] : null);
        final exists = liveViewerList.any((v) {
          if (v is! Map) return false;
          final id = v['viewer_id'] ??
              v['user_id'] ??
              (v['user'] is Map ? v['user']['id'] : null);
          return id != null && viewerId != null && id.toString() == viewerId.toString();
        });
        if (!exists) {
          liveViewerList.add(Map<String, dynamic>.from(singleViewer));
          liveViewerList.refresh();
        }
      }
    }

    final callers = callersRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where(_isAcceptedCaller)
        .toList();

    if (callers.isNotEmpty) {
      websocketController.liveCallList.assignAll(callers);
      websocketController.liveCallList.refresh();
    }

    /// locked_seats is a full snapshot. Replace, do not merge.
    if (lockedSeats.isNotEmpty) {
      websocketController.lockedSeatMap.clear();
      for (final item in lockedSeats) {
        final seatNo = item is Map ? _toInt(item['seat_no'] ?? item['seat']) : _toInt(item);
        if (seatNo > 0) websocketController.lockedSeatMap[seatNo] = true;
      }
      websocketController.lockedSeatMap.refresh();
    }

    /// Let websocket controller sync mute/gift/host state using its central parser.
    try {
      websocketController.syncRoomSnapshotForLateJoin(
        Map<String, dynamic>.from(state),
        source: 'livestream_controller_apply_state',
      );
    } catch (e) {
      debugPrint('⚠️ syncRoomSnapshotForLateJoin skipped from applyLivestreamState: $e');
    }

    if (livestream.isNotEmpty) {
      final sid = _toInt(livestream['id'] ?? livestream['livestream_id']);
      if (sid > 0) {
        streamId.value = sid;
        websocketController.streamID.value = sid;
      }
    } else {
      final sid = _toInt(state['livestream_id'] ?? state['stream_id'] ?? state['id']);
      if (sid > 0) {
        streamId.value = sid;
        websocketController.streamID.value = sid;
      }
    }

    debugPrint(
      '✅ Live state applied => viewers=${viewers.length} callers=${callers.length} locks=${lockedSeats.length}',
    );
  }

  Future<void> refreshLiveRoomRealtimeState({
    required int streamId,
    String? role,
    bool? isOnSeat,
    int? seatNo,
  }) async {
    if (streamId <= 0) return;

    await sendPresenceHeartbeatOnce(
      livestreamId: streamId,
      role: role ?? _presenceRole,
      isOnSeat: isOnSeat ?? _presenceIsOnSeat,
      seatNo: seatNo ?? _presenceSeatNo,
    );

    final response = await fetchPresenceWithLiveState(livestreamId: streamId);
    final data = _asMap(response?['data']);
    final liveState = data['livestream_state'];

    if (liveState != null) {
      await applyLivestreamState(liveState);
      return;
    }

    /// Fallback for old backend response / temporary API issue.
    await Future.wait([
      showLiveViewerListList(streamId: streamId),
      tryToGetCallList(streamId: streamId),
      getAvailableSeats(streamId),
    ]);
  }

  void lastPingUpdate({required int id}) {
    if (id <= 0) {
      debugPrint('⚠️ Ping skipped: invalid stream id $id');
      return;
    }

    streamId.value = id;
    _pingTimer?.cancel();
    _pingTimer = null;

    lastPingOnce(id: id);

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await lastPingOnce(id: id);
    });
  }

  Future<void> lastPingOnce({required int id}) async {
    if (id <= 0) return;

    try {
      final response = await dio.get(
        lastPingUpdateUrl(id),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Legacy lastPing ok => stream=$id');
      } else {
        debugPrint('⚠️ Legacy lastPing failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Legacy lastPing ignored safely: $e');
    }
  }

  // Method to stop the ping timer
  void stopPingUpdate() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // ✅ BATTERY OPTIMIZATION: Method to update ping interval based on battery level
  void updatePingInterval(Duration newInterval) {
    if (_pingTimer == null) return;

    final sid = streamId.value;
    if (sid <= 0) return;

    _pingTimer?.cancel();
    _pingTimer = null;

    _pingTimer = Timer.periodic(newInterval, (_) async {
      await lastPingOnce(id: sid);
    });

    debugPrint('🔋 Legacy ping interval updated => ${newInterval.inSeconds}s');
  }

  Future<void> tryToGenerateToken({
    required roleId,
    required int userId,
    required String channelName,
  }) async {
    // ✅ uid আর channel_name আলাদা — uid = নিজের ID, channel = caller এর channel
    final data = {
      "channel_name": channelName, // caller এর channel (100290)
      "uid": userId, // নিজের uid (100534)
      "role": roleId
    };

    try {
      print('🔑 Token request - channel: $channelName, uid: $userId');
      final response = await dio.post(
        kAgoraTokenGenerateUrl,
        data: data,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        getTokens.value = response.data;
        print("✅ Token generated: ${response.data}");
      } else {
        print("⚠️ Token failed: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }

  ///--------------------------  show Viewer  list ----------------------
  final liveViewerList = [].obs;
  Future<void> showLiveViewerListList({required int streamId}) async {
    try {
      print(kLiveViewersList);
      final response = await dio.get(kLiveViewersList(streamId));

      if (response.statusCode == 200) {
        liveViewerList.value = response.data['viewers'];
        print("gift receiver List : ${liveViewerList.length}");
        liveViewerList.refresh();
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching banner list: $e");
    }
  }

  ///--------------------------  show gitSent list ----------------------
  var seatCount = 5.obs;

  ///--------------------------  Red Packet API Methods ----------------------

  /// Send red packet to livestream
  Future<bool> sendRedPacket({
    required double amount,
    int? durationMinutes,
    bool? isGlobal,
    String? message,
  }) async {
    try {
      final data = {
        "livestream_id": streamId.value,
        "amount": amount,
        "quantity": 1, // Default quantity
        "duration_minutes": durationMinutes ?? 2, // Default 2 minutes
        "is_global": isGlobal ?? false, // Default to current stream only
        "message": message ??
            "Red packet from ${authController.userProfile.value.user?.name}",
      };

      final response = await dio.post(
        kSendRedPacketUrl,
        data: data,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${authController.userProfile.value.token}",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Red packet sent successfully: ${response.data}");
        return true;
      } else {
        print("⚠️ Failed to send red packet: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error sending red packet: $e");
      return false;
    }
  }

  /// Collect red packet
  Future<bool> collectRedPacket(String redPacketId) async {
    try {
      final response = await dio.post(
        '$kDomainUrl/api/red-packets/collect/$redPacketId',
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${authController.userProfile.value.token}",
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print("✅ Red packet collected successfully: $data");

        // Update user balance if provided
        if (data['new_balance'] != null) {
          authController.userProfile.value.user?.balance = data['new_balance'];
          authController.userProfile.refresh();
        }

        return true;
      } else {
        print("⚠️ Failed to collect red packet: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error collecting red packet: $e");
      return false;
    }
  }

  //create live stream
  final createStreamData = {}.obs;

  Future<void> tryToCreateLivestream({
    required String streamTitle,
    required String streamType,
    required int userId,

    /// New room customize data
    int? seatCountValue,
    int roomLayout = 0,
    int roomTheme = 0,
    int roomBackground = -1,
  }) async {
    final selectedSeatCount = seatCountValue ?? seatCount.value;

    final data = {
      "stream_bte": streamTitle,
      "stream_coins": 0,
      "stream_type": streamType,
      "seat_count": selectedSeatCount,
      "gifts_coins": 0,

      /// New keys for live room layout/theme/background
      "room_layout": roomLayout.toString(),
      "room_theme": roomTheme.toString(),
      "room_background": roomBackground.toString(),
    };

    try {
      final response = await dio.post(
        createLiveStream(userId),
        data: data,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        createStreamData.value = response.data;
        isHost.value = true; // Set as host when creating stream

        /// New live create hole previous room music/youtube local status clear.
        selectedMusicPath.value = '';
        liveMusicName.value = '';
        liveMusicStatus.value = 'stopped';
        liveYoutubeStatus.value = 'stopped';
        liveYoutubeUrl.value = '';
        liveYoutubeVideoId.value = '';
        websocketController.liveCallList.clear();
        websocketController.liveCallList
            .add(createStreamData['broadcaster_call_data']);
        if (createStreamData['livestreamdata'] != null) {
          final livestream = createStreamData['livestreamdata'];
          final int id = livestream['id'] ?? 0; // Null safe
          streamId.value = id;
          websocketController.streamID.value = id;

          final String? createdAtStr = livestream['created_at'];
          final DateTime startTime = createdAtStr != null
              ? DateTime.parse(createdAtStr)
              : DateTime.now(); // fallback if null

          liveTimeCase(
            streamId: id,
            startTime: startTime,
          );
        }
        await agoraTokenController.tryToGenerateBroadcasterToken(
          isBroadcaster: true,
          userId: userId,
          channelName: '$userId',
          streamId: streamId.value.toString(),
        );
        if (agoraTokenController.agoraToken.isNotEmpty) {
          websocketController.streamID.value = streamId.value;
          //---------------- start point ----------
          switch (streamType) {
            case 'audio':
              Get.to(
                AudioLiveView(
                  channelName: '$userId',
                  isBroadcaster: true,
                  token: agoraTokenController.agoraToken['token'],
                  seatCount: selectedSeatCount,

                  /// Pass these to AudioLiveView if your AudioLiveView constructor has these fields.
                  /// If not added yet, add nullable/int fields there first.
                  roomLayout: roomLayout,
                  roomTheme: roomTheme,
                  roomBackground: roomBackground,
                ),
                arguments: response.data,
              );
              break;
            case 'popular':
              Get.to(
                PopularLiveView(
                  channelName: '$userId',
                  isBroadcaster: true,
                  token: agoraTokenController.agoraToken['token'],
                ),
                arguments: response.data,
              );
              break;
            case 'audiocall':
              Get.to(
                    () => AudioCallView(
                  channelName: '$userId',
                  isBroadcaster: true,
                  token: getTokens['token'],
                  profile: null,
                ),
                arguments: response.data,
              );

              break;

            case 'videocall':
              Get.to(
                VideoCallView(
                  channelName: '$userId',
                  isBroadcaster: true,
                  token: getTokens['token'],
                  profile: null,
                ),
                arguments: response.data,
              );
              break;
            case 'multi':
            // Get user profile data for frame, level, and agency
              final userProfile = authController.userProfile.value;
              final userId = userProfile.user?.id?.toInt() ?? 0;
              Get.to(
                MultiLiveView(
                  channelName: '$userId',
                  isBroadcaster: true,
                  token: agoraTokenController.agoraToken['token'],
                  seatCount: selectedSeatCount,
                ),
                arguments: response.data,
              );
              break;
            default:
          }
        }
      } else {
        print(
            "⚠️ Failed to create live stream: ${response.statusCode} - ${response.data}");

        // Check if it's agency validation error
        if (response.statusCode == 403 && response.data != null) {
          final errorMessage = response.data['message'] ?? 'Unknown error';
          if (errorMessage.contains('agency')) {
            Get.snackbar(
              'Agency Required',
              'You must join an agency before creating a live stream',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: Duration(seconds: 3),
            );
            return;
          }
        }

        // Show generic error for other cases
        Get.snackbar(
          'Error',
          'Failed to create live stream. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");

        // Check if it's agency validation error
        if (e.response!.statusCode == 403 && e.response!.data != null) {
          final errorMessage = e.response!.data['message'] ?? 'Unknown error';
          if (errorMessage.contains('agency')) {
            Get.snackbar(
              'Agency Required',
              'You must join an agency before creating a live stream',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: Duration(seconds: 3),
            );
            return;
          }
        }

        // Show generic error for other server errors
        Get.snackbar(
          'Server Error',
          'Server error occurred. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      } else {
        print("❌ Network Error: ${e.message}");
        Get.snackbar(
          'Network Error',
          'Please check your internet connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> acceptIncomingCall({
    required String streamType,
    required int myUserId, // receiver এর নিজের ID
    required int callerUserId, // caller এর ID (channel name)
    required dynamic callerData,
  }) async {
    // ⚠️ Receiver কে caller এর channel এ join করতে হবে
    // Channel name = caller এর userId
    await tryToGenerateToken(
      roleId: 2, // 2 = audience/subscriber
      userId: myUserId,
      channelName: '$callerUserId', // caller এর channel
    );

    switch (streamType) {
      case 'audio':
        Get.to(
              () => AudioCallView(
            channelName: '$callerUserId', // ⚠️ caller এর channel
            isBroadcaster: false, // ⚠️ receiver = false
            token: getTokens['token'],
            profile: null,
          ),
          arguments: callerData,
        );
        break;
      case 'video':
        Get.to(
              () => VideoCallView(
            channelName: '$callerUserId', // ⚠️ caller এর channel
            isBroadcaster: false,
            token: getTokens['token'],
            profile: null,
          ),
          arguments: callerData,
        );
        break;
    }
  }

  Future<void> tryToMakeCall({
    required String streamType,
    required int userId,
    required dynamic receiverData,
  }) async {
    // ✅ AgoraTokenController use করো — livestream এর মতোই
    final agoraTokenController = Get.find<AgoraTokenController>();

    await agoraTokenController.tryToGenerateBroadcasterToken(
      isBroadcaster: true,
      userId: userId,
      channelName: '$userId',
      streamId: '$userId',
    );

    final token = agoraTokenController.agoraToken['token'];

    if (token == null || token.toString().isEmpty) {
      print('❌ Token empty, cannot make call');
      return;
    }

    final receiverId = receiverData['User Data']['id'];

    try {
      print('amar Iad $userId');
      print('receiver Iad $receiverId');
      print('receiver Iad $receiverData');

      final response = await dio.get(
        callSpecificUser(
          callerId: userId,
          receiverId: receiverId,
          type: streamType,
        ),
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        switch (streamType) {
          case 'video':
            Get.to(
                  () => VideoCallView(
                channelName: '$userId',
                isBroadcaster: true,
                token: token, // ✅ agoraTokenController থেকে নেওয়া token
                profile: null,
              ),
              arguments: receiverData,
            );
            break;
          case 'audio':
            Get.to(
                  () => AudioCallView(
                channelName: '$userId',
                isBroadcaster: true,
                token: token, // ✅ agoraTokenController থেকে নেওয়া token
                profile: null,
              ),
              arguments: receiverData,
            );
            break;
        }
      } else {
        print("⚠️ Failed: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }

  // remove livestream
  final isLoading = false.obs;
  Future<void> tryToRemoveLivestream({
    required int streamId,
  }) async {
    try {
      isLoading.value = true;
      print('live stream removed');

      final response = await dio.post(
        removeLiveStream(streamId),
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Live stream removed successfully: ${response.data}");

        // ✅ Timer বন্ধ করুন
        stopLive();

        isLoading.value = false;

        // ✅ GetX warning fix - () => widget format use করুন
        Get.offAll(
              () => Endlive(),
          arguments: response.data,
          transition: Transition.cupertino,
          duration: Duration(milliseconds: 400),
        );
      } else {
        isLoading.value = false;
        print(
            "⚠️ Failed to create live stream: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      isLoading.value = false;
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        isLoading.value = false;
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      isLoading.value = false;
      print("❌ Unexpected Error: $e");
    }
  }

  // add viewer
// Add viewer
  final createData = {}.obs;
  Future<Map<String, dynamic>?> tryToAddViewer({
    required int streamId,
    required int viewerId,
  }) async {
    try {
      print("sagor viewer $streamId,$viewerId");
      final response = await dio.get(
        addViewer(streamId, viewerId),
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Viewer added successfully: ${response.data}");

        isHost.value = false; // Set as audience when joining stream
        createData.value = response.data;
        print('create time ${createData['viewer']['created_at']}');
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
      } else {
        print(
            "⚠️ Failed to add viewer: ${response.statusCode} - ${response.data}");
        return null;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
      return null;
    } catch (e) {
      print("❌ Unexpected Error: $e");
      return null;
    }
  }

//------------------------- live time ------------------
  var elapsed = 0.obs;
  var isLive = false.obs;
  Timer? _timer;
  DateTime? _startTime;

// 🟢 Live শুরু
  void startLive(String createdAt) {
    // ✅ সবার আগে timer বন্ধ করুন এবং reset করুন
    _timer?.cancel();
    _timer = null;
    elapsed.value = 0;

    // ✅ CURRENT TIME থেকে শুরু করুন, createdAt ignore করুন
    _startTime = DateTime.now();
    isLive.value = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isLive.value || _startTime == null) {
        _timer?.cancel();
        return;
      }
      final diff = DateTime.now().difference(_startTime!);
      elapsed.value = diff.inSeconds;
    });

    print('Live started at: $_startTime');
  }

// 🔴 Live End
  void stopLive() {
    print('Stop Live time');
    isLive.value = false;
    _timer?.cancel();
    _timer = null;
    elapsed.value = 0;
    _startTime = null;
    print('Live stopped and reset to 00:00');
  }

// 🔁 Reset
  void resetLive() {
    print('Reset Live time');
    isLive.value = false;
    _timer?.cancel();
    _timer = null;
    elapsed.value = 0;
    _startTime = null;
  }

// ⏱️ Formatted time getter
  String get formattedTime {
    final seconds = elapsed.value % 60;
    final minutes = (elapsed.value ~/ 60) % 60;
    final hours = elapsed.value ~/ 3600;

    return hours > 0
        ? "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}"
        : "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void onClose() {
    _timer?.cancel();
    _pingTimer?.cancel();
    _presenceHeartbeatTimer?.cancel();
    _pkTimer?.cancel();

    selectedMusicPath.value = '';
    liveMusicName.value = '';
    liveMusicStatus.value = 'stopped';

    liveYoutubeStatus.value = 'stopped';
    liveYoutubeUrl.value = '';
    liveYoutubeVideoId.value = '';

    super.onClose();
  }
  //------------------------- live time ------------------

  final removeData = {}.obs;
  // remove viewer
  Future<void> tryToRemoveViewer({
    required int streamId,
    required int viewerId,
  }) async {
    try {
      print('📤 tryToRemoveViewer request => streamId=$streamId viewerId=$viewerId');

      final response = await dio.get(
        removeViewer(streamId, viewerId),
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Viewer removed successfully: ${response.data}");
        removeData.value = response.data;

        /// Backend response-er removed_viewer theke real user id nibo.
        /// viewer row id diye clear korle wrong match/404 dite pare.
        final removedViewer = response.data['removed_viewer'];
        final realUserId = removedViewer is Map
            ? (removedViewer['user']?['id'] ??
            removedViewer['viewer_id'] ??
            removedViewer['user_id'] ??
            viewerId)
            : viewerId;

        print("✅ Viewer removed stream: ${removedViewer is Map ? removedViewer['livestream_id'] : streamId}");
        print("🧹 Clear local viewer data for realUserId=$realUserId");

        websocketController.clearSpecificUserStreamData(
          userId: realUserId.toString(),
          rejectCallIfInCallList: false,
        );
      } else {
        print(
            "⚠️ Failed to remove viewer: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      /// 404 can happen if backend already removed viewer by websocket/another call.
      /// Treat it as already removed, not fatal.
      if (e.response?.statusCode == 404) {
        print("ℹ️ Viewer already removed / not found: ${e.response?.data}");
        websocketController.clearSpecificUserStreamData(
          userId: viewerId.toString(),
          rejectCallIfInCallList: false,
        );
        return;
      }

      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }

  // get viewer list
  final viewerList = [].obs;

  Future<void> tryToGetViewerList({
    required int streamId,
  }) async {
    try {
      final response = await dio.get(
        getViewerList(streamId),
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        viewerList.value = response.data;
        print("✅ Viewer list fetched successfully: ${response.data}");
      } else {
        print(
            "⚠️ Failed to fetch viewer list: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }

  // call live stream
  final callersData = {}.obs;

  Future<void> tryToCallLivestream({
    required int streamId,
    int? seatNO,
    required int callerId,
    required String callType,
  }) async {
    print("📌 Starting tryToCallLivestream");
    print(
        "StreamID: $streamId, CallerID: $callerId, CallType: $callType, SeatNO: ${seatNO ?? 100}");

    // 1️⃣ Check if can join
    final canJoinResult = await checkCanJoinLivestream(streamId, callerId);
    print("✅ checkCanJoinLivestream result: $canJoinResult");
    if (!canJoinResult['can_join']) {
      Fluttertoast.showToast(
        msg: canJoinResult['message'],
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // 2️⃣ Prepare data
    final data = {
      "livestream_id": streamId,
      "caller_id": callerId,
      "call_type": callType,
      "seat_no": seatNO ?? 100
    };
    print("📤 Request data: $data");

    try {
      // 3️⃣ Send POST request
      final response = await dio.post(
        callLiveStream,
        data: data,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      print("📨 Response status code: ${response.statusCode}");
      print("📨 Response data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        callersData.value = response.data;
        print("✅ Call made successfully: ${response.data}");
      } else {
        print(
            "⚠️ Failed to make call: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      print("❌ DioException caught");
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
    print("📌 tryToCallLivestream ended");
  }



  // get call list
  final callList = [].obs;
  final selectIndex = 0.obs;
  Future<void> tryToGetCallList({
    required int streamId,
  }) async {
    if (streamId <= 0) return;

    try {
      final response = await dio.get(
        getCallList(streamId),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        final list = raw is List
            ? raw
            : raw is Map && raw['data'] is List
            ? raw['data'] as List
            : raw is Map && raw['callers'] is List
            ? raw['callers'] as List
            : <dynamic>[];

        callList.assignAll(list);

        /// Seat/call UI only accepted/joined/active user show korbe.
        /// Pending/request user never seat e uthbe na.
        final filteredCallList = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where(_isAcceptedCaller)
            .toList();

        websocketController.liveCallList.assignAll(filteredCallList);
        websocketController.liveCallList.refresh();

        debugPrint('✅ Call list synced => accepted=${filteredCallList.length} raw=${list.length}');
      } else {
        debugPrint('⚠️ Failed to fetch call list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Call list fetch failed safely: $e');
    }
  }

  // accept call
  Future<void> tryToAcceptCall({
    required int streamId,
    required int userId,
  }) async {
    if (streamId <= 0 || userId <= 0) return;

    try {
      final response = await dio.get(
        acceptCall(streamId, userId),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Call accepted => stream=$streamId user=$userId');

        websocketController.pendingCall.removeWhere((call) {
          final callerId = call['caller_id']?.toString();
          final callUserId = call['user']?['id']?.toString();
          return callerId == userId.toString() || callUserId == userId.toString();
        });
        websocketController.pendingCall.refresh();

        await tryToGetCallList(streamId: streamId);

        final currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
        if (currentUserId == userId) {
          dynamic currentCall;
          for (final item in websocketController.liveCallList) {
            if (item is! Map) continue;
            final callerId = item['caller_id']?.toString();
            final callUserId = item['user']?['id']?.toString();
            if (callerId == userId.toString() || callUserId == userId.toString()) {
              currentCall = item;
              break;
            }
          }

          updateLivePresenceRole(
            role: 'caller',
            isOnSeat: true,
            seatNo: _seatNoFromCall(currentCall),
          );
        }
      } else {
        debugPrint('⚠️ Failed to accept call: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Accept call failed safely: $e');
    }
  }

  // reject call / leave seat
  Future<void> tryToRejectCall({
    required int streamId,
    required int userId,
  }) async {
    if (streamId <= 0 || userId <= 0) return;

    try {
      final response = await dio.get(
        rejectCall(streamId, userId),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Call rejected/left => stream=$streamId user=$userId');
      } else {
        debugPrint('⚠️ Reject call status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        debugPrint('⚠️ Reject call Dio ignored safely: ${e.response?.statusCode ?? e.message}');
      }
    } catch (e) {
      debugPrint('⚠️ Reject call failed safely: $e');
    } finally {
      websocketController.pendingCall.removeWhere((call) {
        final callerId = call['caller_id']?.toString();
        final callUserId = call['user']?['id']?.toString();
        return callerId == userId.toString() || callUserId == userId.toString();
      });
      websocketController.liveCallList.removeWhere((call) {
        final callerId = call['caller_id']?.toString();
        final callUserId = call['user']?['id']?.toString();
        return callerId == userId.toString() || callUserId == userId.toString();
      });
      websocketController.pendingCall.refresh();
      websocketController.liveCallList.refresh();

      final currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
      if (currentUserId == userId) {
        updateLivePresenceRole(role: 'viewer', isOnSeat: false, seatNo: null);
        await markUserOffline(
          livestreamId: streamId,
          role: 'caller',
        );
        await sendPresenceHeartbeatOnce(
          livestreamId: streamId,
          role: 'viewer',
          isOnSeat: false,
          seatNo: null,
        );
      }

      await refreshLiveRoomRealtimeState(streamId: streamId);
    }
  }

  // live comments
  Future<void> tryToAddComment({
    required String comment,
  }) async {
    try {
      final userId = authController.userProfile.value.user?.id?.toInt() ?? 0;

      final url = addComment(streamId.value, userId);

      // ✅ DEBUG PRINTS
      print('📌 URL: $url');
      print('📌 User ID: $userId');
      print('📌 Stream ID: ${streamId.value}');
      print('📌 Comment Data: {"comment": $comment}');

      final response = await dio.post(
        url,
        data: {
          'comment': comment,
        },
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Comment added successfully");
        print("📥 Response Data: ${response.data}");
      } else {
        print("⚠️ Failed: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print("❌ Server Error: ${e.response!.statusCode}");
        print("📥 Error Data: ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }

  final giftReceiverID = 0.obs;
  final selectedSeatNo = 0.obs;

  bool get isPkCommentGiftActive {
    final int pkId = currentPkId.value;
    final int senderStream = pkSenderLivestreamId.value;
    final int receiverStream = pkReceiverLivestreamId.value;

    return pkId > 0 &&
        (pkModeActive.value == true || senderStream > 0 || receiverStream > 0);
  }

  int get currentPkOpponentLivestreamId {
    final int myStream = streamId.value;
    final int senderStream = pkSenderLivestreamId.value;
    final int receiverStream = pkReceiverLivestreamId.value;

    if (myStream > 0 && myStream == senderStream && receiverStream > 0) {
      return receiverStream;
    }

    if (myStream > 0 && myStream == receiverStream && senderStream > 0) {
      return senderStream;
    }

    if (receiverStream > 0 && receiverStream != myStream) return receiverStream;
    if (senderStream > 0 && senderStream != myStream) return senderStream;

    return 0;
  }

  Map<String, dynamic> pkCommentGiftMetaBody() {
    if (!isPkCommentGiftActive) return <String, dynamic>{};

    final int myStream = streamId.value;
    final int opponentStream = currentPkOpponentLivestreamId;

    return <String, dynamic>{
      'is_pk': 1,
      'pk_id': currentPkId.value,
      'pk_channel_name': pkChannelName.value,
      'pk_channel': pkChannelName.value,
      'sender_livestream_id': myStream,
      'receiver_livestream_id': opponentStream,
      'opponent_livestream_id': opponentStream,
      'pk_sender_livestream_id': pkSenderLivestreamId.value,
      'pk_receiver_livestream_id': pkReceiverLivestreamId.value,
      'pk_sender_host_id': pkSenderHostId.value,
      'pk_receiver_host_id': pkReceiverHostId.value,
    };
  }

// Controller এ list রাখুন
  final selectedReceiverIds = <int>[].obs;

// onTap এ ID add/remove করুন
  void toggleProfileSelection(int index, int userId) {
    if (selectedProfileIndices.contains(index)) {
      selectedProfileIndices.remove(index);
      selectedReceiverIds.remove(userId); // ✅ ID remove
    } else {
      selectedProfileIndices.add(index);
      selectedReceiverIds.add(userId); // ✅ ID add
    }
  }

// Send gift to live stream
  Future<Map<String, dynamic>?> tryToSendGift({
    required int receiverId,
    required int giftId,
    required int giftPrice,
  }) async {
    try {
      final user = authController.userProfile.value.user;
      final userId = user?.id?.toInt() ?? 0;
      final userCoins = int.tryParse(user?.coins.toString() ?? '0') ?? 0;

      if (userId == 0) {
        Fluttertoast.showToast(msg: "User not found");
        return null;
      }

      // 🧾 Local check before API call (extra layer)
      if (userCoins < giftPrice) {
        Fluttertoast.showToast(
          msg: "Insufficient balance. Please recharge!",
          backgroundColor: Colors.white,
          textColor: Colors.red,
          gravity: ToastGravity.BOTTOM,
        );
        return null;
      }

      /// If bottom sheet selected no receiver, send to tapped/default receiver.
      /// This also allows self gift when receiverId is current user's id.
      final receivers = selectedReceiverIds.isNotEmpty
          ? selectedReceiverIds.toList()
          : <int>[receiverId];

      final data = {
        "sender_id": userId,
        "receiver_ids": receivers,
        "gift_id": giftId,
        "stream_id": streamId.value,
        if (selectedSeatNo.value > 0) "seat_no": selectedSeatNo.value,
        ...pkCommentGiftMetaBody(),
      };

      selectedGiftSendingId.value = giftId;

      print('🎁 GIFT SEND BODY => $data');

      final response = await dio.post(
        kSentGift,
        data: data,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData["success"] == true || responseData["action_type"] == "lucky_gift_result") {
          /// Normal gift response has sender coins.
          /// Lucky response may include sender coins or win_amount. Only update if backend sends coins.
          if (responseData['sender'] is Map && responseData['sender']['coins'] != null) {
            authController.userProfile.value.user!.coins =
                responseData['sender']['coins'].toString();
            authController.userProfile.refresh();
          }

          /// Lucky gift result can come directly in send response.
          /// WebSocket should also broadcast action_type lucky_gift_result for all users.
          if (responseData['action_type'] == 'lucky_gift_result' ||
              responseData['is_lucky_gift'] == true) {
            showLuckyGiftResult(responseData);

            final isWin = responseData['is_win'] == true;
            final winAmount = responseData['win_amount'] ?? 0;
            final multiplier = responseData['multiplier'] ?? 0;

            Fluttertoast.showToast(
              msg: isWin
                  ? 'Lucky win! +$winAmount coins x$multiplier'
                  : 'Better luck next time',
              backgroundColor: isWin ? Colors.green : Colors.black87,
              textColor: Colors.white,
              gravity: ToastGravity.CENTER,
            );
          }

          print('✅ Gift sent successfully: $responseData');
          return responseData;
        } else {
          final msg = responseData["message"] ?? "Gift sending failed!";
          Fluttertoast.showToast(
            msg: msg,
            backgroundColor: Colors.redAccent,
            textColor: Colors.white,
            gravity: ToastGravity.CENTER,
          );
          print("⚠️ Server Response: $msg");
        }
      } else {
        print(
            "⚠️ Failed to send gift: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response!.data is Map<String, dynamic>
            ? e.response!.data["message"] ?? "Server Error"
            : "Server Error";
        Fluttertoast.showToast(
          msg: msg,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          gravity: ToastGravity.BOTTOM,
        );
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        Fluttertoast.showToast(
          msg: "Network error. Please check your connection.",
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          gravity: ToastGravity.CENTER,
        );
        print("❌ Network Error: ${e.error ?? e.toString()}");
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unexpected Error: $e",
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        gravity: ToastGravity.CENTER,
      );
      print("❌ Unexpected Error: $e");
    } finally {
      selectedGiftSendingId.value = 0;
    }

    return null;
  }

  final giftList = <Map<String, dynamic>>[].obs;
  final giftHistory = <Map<String, dynamic>>[].obs;
  final totalGiftCoins = 0.obs;

  /// Gift category / lucky gift UI state.
  final selectedGiftCategoryIndex = 0.obs;
  final selectedGiftSendingId = 0.obs;
  final luckyGiftResult = <String, dynamic>{}.obs;
  final luckyGiftResultVisible = false.obs;

  String giftCategoryOf(Map<String, dynamic> gift) {
    return (gift['category'] ??
        gift['gift_category'] ??
        gift['type'] ??
        'Popular')
        .toString()
        .trim();
  }

  bool isLuckyGift(Map<String, dynamic> gift) {
    final category = giftCategoryOf(gift).toLowerCase();
    final backCoin = gift['back_coin'];
    return category == 'lucky' ||
        category.contains('lucky') ||
        backCoin != null && backCoin.toString() != 'null' && backCoin.toString().isNotEmpty;
  }

  List<String> get giftCategories {
    final set = <String>{};
    for (final gift in giftList) {
      final category = giftCategoryOf(Map<String, dynamic>.from(gift));
      if (category.isNotEmpty) set.add(category);
    }

    final list = set.toList();

    list.sort((a, b) {
      final al = a.toLowerCase();
      final bl = b.toLowerCase();

      if (al == 'popular' && bl != 'popular') return -1;
      if (al != 'popular' && bl == 'popular') return 1;

      final aVip = al.contains('vip') || al.contains('svip') || al.contains('premium');
      final bVip = bl.contains('vip') || bl.contains('svip') || bl.contains('premium');
      if (aVip != bVip) return aVip ? 1 : -1;

      return a.compareTo(b);
    });

    return list;
  }

  List<Map<String, dynamic>> giftsByCategoryIndex(int index) {
    final categories = giftCategories;
    if (categories.isEmpty) return giftList.map((e) => Map<String, dynamic>.from(e)).toList();

    final safeIndex = index.clamp(0, categories.length - 1).toInt();
    final category = categories[safeIndex].toLowerCase();

    return giftList
        .map((e) => Map<String, dynamic>.from(e))
        .where((gift) => giftCategoryOf(gift).toLowerCase() == category)
        .toList();
  }

  void showLuckyGiftResult(Map<String, dynamic> data) {
    luckyGiftResult.value = data;
    luckyGiftResultVisible.value = true;

    Future.delayed(const Duration(seconds: 4), () {
      luckyGiftResultVisible.value = false;
    });
  }




  Future<void> fetchGiftList() async {
    try {
      final response = await dio.get(
        kGiftList,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData != null && responseData["success"] == true) {
          giftList
              .assignAll(List<Map<String, dynamic>>.from(responseData["data"]));
          print("✅ Gift list updated successfully.");
        } else {
          print("⚠️ No data found.");
        }
      } else {
        print(
            "⚠️ Failed to fetch gifts: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }

  // Fetch gift history for current livestream
  Future<void> fetchGiftHistory() async {
    try {
      final response = await dio.get(
        '$kMainUrl/livestream/${streamId.value}/gift-history',
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData != null && responseData["success"] == true) {
          giftHistory.assignAll(
              List<Map<String, dynamic>>.from(responseData["gift_history"]));
          print("✅ Gift history updated successfully.");
        } else {
          print("⚠️ No gift history found.");
        }
      } else {
        print(
            "⚠️ Failed to fetch gift history: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }

  int _safeCoinInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  void syncLiveGiftCoinsFromPayload(Map<String, dynamic> payload, {String source = 'payload'}) {
    try {
      final Map<String, dynamic> data = payload['livestream'] is Map
          ? Map<String, dynamic>.from(payload['livestream'])
          : payload['live_stream'] is Map
          ? Map<String, dynamic>.from(payload['live_stream'])
          : payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'])
          : Map<String, dynamic>.from(payload);

      final String action =
      (payload['action_type'] ?? payload['action'] ?? '').toString().toLowerCase();

      final bool viewerPayload = action.contains('viewer') ||
          action.contains('join') ||
          payload.containsKey('viewer') ||
          payload.containsKey('viewer_data') ||
          data.containsKey('viewer_id');

      final bool hasLiveCoinKey = data.containsKey('total_gift_coins') ||
          data.containsKey('total_coins') ||
          data.containsKey('gift_amount') ||
          data.containsKey('stream_coins') ||
          data.containsKey('received_coins');

      /// viewer.user.gifts_coins is user history, not live received total.
      if (viewerPayload && !hasLiveCoinKey) {
        print('🪙 Live gift coin sync skipped viewer payload from $source');
        return;
      }

      final dynamic raw = data['total_gift_coins'] ??
          data['total_coins'] ??
          data['gift_amount'] ??
          data['stream_coins'] ??
          data['received_coins'] ??
          data['gifts_coins'];

      if (raw == null) return;

      final int newCoins = _safeCoinInt(raw);
      final int oldCoins = _safeCoinInt(totalGiftCoins.value);

      if (newCoins == 0 && oldCoins > 0) {
        print('🪙 Live gift coin zero reset ignored from $source, keep=$oldCoins');
        return;
      }

      if (newCoins > 0 || oldCoins <= 0) {
        totalGiftCoins.value = newCoins;
        update();
        print('🪙 Live gift coins synced from $source => $newCoins');
      }
    } catch (e) {
      print('⚠️ syncLiveGiftCoinsFromPayload error => $e');
    }
  }

  // Fetch total gift coins for current livestream
  Future<void> fetchTotalGiftCoins() async {
    try {
      final int sid = int.tryParse(streamId.value.toString()) ?? 0;

      if (sid <= 0) {
        print("⚠️ fetchTotalGiftCoins skipped: invalid streamId=$sid");
        return;
      }

      final response = await dio.get(
        '$kMainUrl/livestream/$sid/total-gift-coins',
        options: Options(headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};

        if (responseData["success"] == true || responseData.containsKey("total_gift_coins")) {
          final dynamic raw = responseData["total_gift_coins"] ??
              responseData["total_coins"] ??
              responseData["gifts_coins"] ??
              responseData["gift_amount"] ??
              responseData["stream_coins"];

          final int newCoins = _safeCoinInt(raw);
          final int oldCoins = _safeCoinInt(totalGiftCoins.value);

          /// Backend partial/old response 0 must not reset an already non-zero balance.
          if (newCoins == 0 && oldCoins > 0) {
            print("🪙 fetchTotalGiftCoins ignored zero reset, keep=$oldCoins response=$responseData");
            return;
          }

          if (newCoins > 0 || oldCoins <= 0) {
            totalGiftCoins.value = newCoins;
            print("✅ Total gift coins safely updated: ${totalGiftCoins.value}");
          }
        } else {
          print("⚠️ No gift coins data found.");
        }
      } else {
        print(
            "⚠️ Failed to fetch gift coins: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
            "❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }



  @override
  void onInit() {
    // TODO: implement onInit
    fetchGiftList();

    super.onInit();
  }


  void removeBroadcaster({required RtcEngine engine}) async {
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
  }

  final selectedGiftId = 0.obs;

  //Video live image pick
  final videoImage = ''.obs;

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
                final XFile? image =
                await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  audioImage.value = image.path;
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
                final XFile? image =
                await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  audioImage.value = image.path;
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[800],
    );
  }

  ///----------------- audio theme --------------------
  final themeList = [].obs;
  Future<void> showTheme() async {
    try {
      final response = await dio.get(kAudioThemeList);

      if (response.statusCode == 200) {
        themeList.value = response.data['data'];
        print(" show theme list   : $themeList");
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching banner list: $e");
    }
  }


  final backgroundList = [].obs;
  Future<void> showBackground() async {
    try {
      final response = await dio.get(kAudioBackgroundList);

      if (response.statusCode == 200) {
        backgroundList.value = response.data['data'];
        print(" show theme list   : $backgroundList");
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching banner list: $e");
    }
  }

  //-------------- theme set create ---------------
  final audioThemeSet = {}.obs;

  void createTheme({required String userId, required int themeID}) async {
    final data = {'user_id': userId, 'theme_id': themeID};
    try {
      print(kAudioThemeSet);
      print(data);
      final response = await dio.post(
        kAudioThemeSet,
        data: data,
      );
      if (response.statusCode == 200) {
        audioThemeSet.value = response.data;
        // showTheme();
        Get.back();
        Fluttertoast.showToast(
          msg: "Theme set Success",
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

  //---------------- audio theme show ----------

  Future<void> liveEndTimeCase(
      {required int streamId, required DateTime startTime}) async {
    final data = {
      'stream_id': streamId,
      'end_time': startTime.toIso8601String()
    };
    try {
      print('end data $data');
      final response = await dio.post(kLivestreamEndTime, data: data);

      if (response.statusCode == 200) {
        Get.to(
              () => Endlive(),
          arguments: endLiveTime,
          transition: Transition.fade,
          duration: const Duration(milliseconds: 500),
        );
        endLiveTime.value = response.data;
        print(" show end time: $endLiveTime");
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching banner list: $e");
    }
  }

  //-----------------------for live stream actions------------------------------------

  RxBool isAudioEnabled = true.obs;
  final AgoraService _agoraService = AgoraService();
  RxBool isVideoEnabled = true.obs;

  /// ===================== BROAD SPEAKER / REMOTE AUDIO MUTE =====================
  /// Eta local device only: mic mute hobe na, sudhu onno sobar voice ei device-e off/on hobe.
  final RxBool isBroadSpeakerMuted = false.obs;

  Future<void> applyBroadSpeakerMute({
    RtcEngine? rtcEngine,
    bool? muted,
  }) async {
    final bool shouldMute = muted ?? isBroadSpeakerMuted.value;
    final engine = rtcEngine ?? _agoraService.engine;

    if (engine == null) {
      debugPrint('⚠️ Broad speaker mute skipped: Agora engine null');
      return;
    }

    try {
      /// 1) Main reliable local playback volume control.
      /// 0 = ei device-e remote users voice shona jabe na.
      /// 100 = normal remote users voice shona jabe.
      await engine.adjustPlaybackSignalVolume(shouldMute ? 0 : 100);

      /// 2) Extra safe: remote streams local subscribe mute/unmute.
      await engine.muteAllRemoteAudioStreams(shouldMute);

      /// 3) Speaker route restore when unmuted.
      /// Note: speaker off means local output route off/earpiece, but playback volume 0 handles full mute.
      await engine.setEnableSpeakerphone(!shouldMute);

      debugPrint('🔇 Broad speaker local mute applied => $shouldMute');
    } catch (e) {
      debugPrint('❌ Broad speaker mute apply failed: $e');
      try {
        await engine.adjustPlaybackSignalVolume(shouldMute ? 0 : 100);
      } catch (_) {}
    }
  }

  Future<void> toggleBroadSpeakerMute({RtcEngine? rtcEngine}) async {
    isBroadSpeakerMuted.value = !isBroadSpeakerMuted.value;
    await applyBroadSpeakerMute(
      rtcEngine: rtcEngine,
      muted: isBroadSpeakerMuted.value,
    );
  }


  /// Host mute korleo gallery music audience-er kache publish thakbe.
  /// Important: host-er jonno muteLocalAudioStream(true) use korbo na,
  /// karon eta audio mixing-o audience-er kache bondho kore dite pare.
  Future<void> _keepMusicPublishingWhenMicMuted(
      RtcEngine engine, {
        required bool micMuted,
      }) async {
    try {
      /// Host-er audio track publish active thakbe, kintu mic signal 0 kore dibo.
      /// muteLocalAudioStream(true) dile Agora music mixing publish-o bondho hoye jete pare.
      await engine.muteLocalAudioStream(false);
      await engine.adjustRecordingSignalVolume(micMuted ? 0 : 100);

      /// Local playout + audience publish volume stable rakha.
      await engine.adjustAudioMixingVolume(80);
      await engine.adjustAudioMixingPlayoutVolume(80);
      await engine.adjustAudioMixingPublishVolume(80);

      print('🎙️ Mic muted=$micMuted, music still publishing to audience');
    } catch (e) {
      print('⚠️ keepMusicPublishingWhenMicMuted failed: $e');
    }
  }

  // Send audio toggle to backend via API
  /// isAudioOn meaning:
  /// true  => audio_on = 1 => mic unmute/on
  /// false => audio_on = 0 => mic mute/off
  Future<void> _sendAudioToggleToBackend(
      bool isAudioOn, {
        int? targetUserId,
        RtcEngine? rtcEngine,
      }) async {
    try {
      final userId = targetUserId ??
          authController.userProfile.value.user?.id?.toInt() ??
          0;

      if (userId == 0) {
        Fluttertoast.showToast(msg: 'User not found');
        return;
      }

      final int audioOn = isAudioOn ? 1 : 0;

      /// 1) Local UI instant update.
      _updateAudioStateInLiveCallList(
        userId: userId,
        audioOn: audioOn,
      );

      /// 2) Current user-er mic locally apply.
      final currentUserId =
          authController.userProfile.value.user?.id?.toInt() ?? 0;

      if (userId == currentUserId) {
        mute.value = audioOn == 0;

        final engine = rtcEngine ?? _agoraService.engine;
        if (engine != null) {
          await _keepMusicPublishingWhenMicMuted(
            engine,
            micMuted: audioOn == 0,
          );
        }
      }

      /// 3) Backend update. Backend broadcast korbe jate sobai mute icon dekhe.
      final response = await dio.post(
        kAudioToggleUrl(streamId.value, userId),
        data: {
          'livestream_id': streamId.value,
          'user_id': userId,
          'audio_on': audioOn,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200) {
        print(
          '✅ Audio toggle sent to backend successfully => user:$userId audio_on:$audioOn',
        );
      } else {
        print(
          '⚠️ Failed to send audio toggle: ${response.statusCode} ${response.data}',
        );
      }
    } catch (e) {
      print('❌ Error sending audio toggle: $e');
      Fluttertoast.showToast(msg: 'Audio toggle failed');
    }
  }

  void _updateAudioStateInLiveCallList({
    required int userId,
    required int audioOn,
  }) {
    try {
      final index = websocketController.liveCallList.indexWhere((call) {
        final callerId = call['caller_id'];
        final callUserId = call['user']?['id'];
        return callerId.toString() == userId.toString() ||
            callUserId.toString() == userId.toString();
      });

      if (index != -1) {
        websocketController.liveCallList[index]['audio_on'] = audioOn;
        websocketController.liveCallList[index]['is_muted'] =
        audioOn == 0 ? 1 : 0;
        websocketController.liveCallList[index]['is_muted_by_host'] =
        audioOn == 0 ? 1 : 0;
        websocketController.liveCallList.refresh();

        print('✅ Local liveCallList audio updated => user:$userId audio_on:$audioOn');
      } else {
        print('⚠️ User $userId not found in liveCallList for local audio update');
      }
    } catch (e) {
      print('❌ Local audio state update failed: $e');
    }
  }

  void _updateVideoStateInLiveCallList({
    required int userId,
    required int videoOn,
  }) {
    try {
      final index = websocketController.liveCallList.indexWhere((call) {
        final callerId = call['caller_id'];
        final callUserId = call['user']?['id'];
        return callerId.toString() == userId.toString() ||
            callUserId.toString() == userId.toString();
      });

      if (index != -1) {
        websocketController.liveCallList[index]['video_on'] = videoOn;
        websocketController.liveCallList.refresh();
        debugPrint('✅ Local video updated => user:$userId video_on:$videoOn');
      }
    } catch (e) {
      debugPrint('⚠️ Local video update failed safely: $e');
    }
  }

  // Send video toggle to backend via API
  /// isVideoOn meaning:
  /// true  => video_on = 1 => camera on
  /// false => video_on = 0 => camera off
  Future<void> _sendVideoToggleToBackend(
      bool isVideoOn, {
        int? targetUserId,
        RtcEngine? rtcEngine,
      }) async {
    try {
      final userId = targetUserId ??
          authController.userProfile.value.user?.id?.toInt() ??
          0;

      if (userId == 0) {
        Fluttertoast.showToast(msg: 'User not found');
        return;
      }

      final int videoOn = isVideoOn ? 1 : 0;

      /// Local UI instant update.
      _updateVideoStateInLiveCallList(userId: userId, videoOn: videoOn);

      /// Current user camera locally apply.
      final currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
      final engine = rtcEngine ?? _agoraService.engine;
      if (userId == currentUserId && engine != null) {
        await engine.enableLocalVideo(isVideoOn);
        await engine.muteLocalVideoStream(!isVideoOn);
      }

      final response = await dio.post(
        kVideoToggleUrl(streamId.value, userId),
        data: {
          'livestream_id': streamId.value,
          'user_id': userId,
          'video_on': videoOn,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Video toggle backend ok => user:$userId video_on:$videoOn');
      } else {
        debugPrint('⚠️ Video toggle failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Video toggle failed safely: $e');
      Fluttertoast.showToast(msg: 'Video toggle failed');
    }
  }

  // Toggle specific user's audio (for moderation / broadcaster / current user)
  Future<void> toggleSpecificUserAudio(
      int targetUserId, {
        RtcEngine? rtcEngine,
      }) async {
    final isAudioOn = websocketController.getUserAudioStatus(targetUserId);
    final bool newAudioOn = !isAudioOn;

    await _sendAudioToggleToBackend(
      newAudioOn,
      targetUserId: targetUserId,
      rtcEngine: rtcEngine,
    );
  }

  /// Use this from any UI button: bottomSheet, writeComment, toolbar, etc.
  Future<void> toggleMyAudioFromAnyButton({
    RtcEngine? rtcEngine,
  }) async {
    final userId = authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (userId == 0) {
      Fluttertoast.showToast(msg: 'User not found');
      return;
    }

    await toggleSpecificUserAudio(
      userId,
      rtcEngine: rtcEngine,
    );
  }

  // Toggle specific user's video (for moderation)
  Future<void> toggleSpecificUserVideo(
      int targetUserId, {
        RtcEngine? rtcEngine,
      }) async {
    final isVideoOn = websocketController.getUserVideoStatus(targetUserId);
    final bool newVideoState = !isVideoOn;

    await _sendVideoToggleToBackend(
      newVideoState,
      targetUserId: targetUserId,
      rtcEngine: rtcEngine,
    );
  }

// -----------------------End for live stream actions------------------------------------

  ///------------------- live stream end time ----------------
  final endLiveTime = {}.obs;

  // Add user to room blacklist
  Future<Map<String, dynamic>?> addToRoomBlacklist(int livestreamId, int userId,
      {String reason = 'room_blacklist'}) async {
    try {
      final response = await dio.post(
        '$kMainUrl/livestream/$livestreamId/room-blacklist',
        data: {
          'user_id': userId,
          'reason': reason,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Successfully added user to room blacklist: ${response.data}");
        return response.data;
      } else {
        print(
            "⚠️ Failed to add user to room blacklist: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("❌ Error adding user to room blacklist: $e");
      return null;
    }
  }

  // Kick out user from livestream
  Future<bool> kickOutUser(int userId) async {
    try {
      final url = kKickOutUrl(streamId.value, userId);
      final token = authController.userProfile.value.token;
      final response = await dio.post(
        url,
        data: {
          'user_id': userId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          // এইটা দিলে 403 তেও catch করবে instead of throw
          validateStatus: (status) => true,
        ),
      );

      print("📌 Status Code: ${response.statusCode}");
      print("📌 Response Data: ${response.data}");

      if (response.statusCode == 200) {
        print('✅ User kicked out successfully');
        Get.snackbar(
          'Success',
          'User has been kicked out from the livestream',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else if (response.statusCode == 403) {
        print('❌ Forbidden: You don\'t have permission or token expired.');
        Get.snackbar(
          'Permission Denied',
          'Only livestream creator or admin can kick users',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      } else if (response.statusCode == 404) {
        print('❌ Livestream not found');
        Get.snackbar(
          'Error',
          'Livestream not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      } else {
        print('❌ Failed to kick out user: ${response.statusCode}');
        Get.snackbar(
          'Error',
          'Failed to kick out user. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('⚠️ Error kicking out user: $e');
      return false;
    }
  }

  // Get available seats for livestream
  final availableSeatsData = {}.obs;
  Future<Map<String, dynamic>?> getAvailableSeats(int livestreamId) async {
    Future<Response> request(String url) {
      return dio.get(
        url,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );
    }

    try {
      /// New backend route.
      final primaryUrl = '$kMainUrl/livestream/$livestreamId/available-seats';

      /// Old route fallback, jodi server-e old endpoint thake.
      final fallbackUrl = '$kMainUrl/availableseats/$livestreamId';

      Response response;

      try {
        response = await request(primaryUrl);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          print('ℹ️ New available seats route not found, trying old route...');
          response = await request(fallbackUrl);
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        availableSeatsData.value = response.data;
        print("✅ Available seats fetched: ${response.data}");
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
      } else {
        print(
            "⚠️ Failed to fetch available seats: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching available seats: $e");
      return null;
    }
  }

  Future<void> sendMusicEvent({
    required int livestreamId,
    required int hostId,
    required String status,
    String? musicName,
  }) async {
    try {
      final response = await dio.post(
        '$kMainUrl/livestream/$livestreamId/music-control',
        data: {
          'host_id': hostId,
          'music_status': status,
          'music_name': musicName,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Music event sent: ${response.data}');
      } else {
        print('⚠️ Music event failed: ${response.statusCode} ${response.data}');
      }
    } catch (e) {
      print('❌ Music event error: $e');
    }
  }

  Future<void> pickAndPlayLiveMusic({required RtcEngine? rtcEngine}) async {
    if (rtcEngine == null) {
      Fluttertoast.showToast(msg: 'Audio engine not ready');
      return;
    }

    try {
      musicLoading.value = true;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final path = file.path;

      if (path == null || path.trim().isEmpty) {
        Fluttertoast.showToast(msg: 'Music path not found');
        return;
      }

      final name = file.name.isNotEmpty ? file.name : 'Music';

      await startLiveMusic(
        rtcEngine: rtcEngine,
        path: path,
        name: name,
        status: liveMusicStatus.value == 'stopped' ? 'playing' : 'changed',
      );
    } catch (e) {
      print('❌ Pick/play music error: $e');
      Fluttertoast.showToast(msg: 'Music play failed');
    } finally {
      musicLoading.value = false;
    }
  }

  Future<void> startLiveMusic({
    required RtcEngine rtcEngine,
    required String path,
    required String name,
    String status = 'playing',
  }) async {
    try {
      /// Music start/change korle stale YouTube state stop kore dibo.
      if (liveYoutubeStatus.value != 'stopped') {
        await stopYoutube();
      }

      await rtcEngine.stopAudioMixing();

      /// loopback false = audience shunte parbe.
      /// cycle -1 = repeat.
      await rtcEngine.startAudioMixing(
        filePath: path,
        loopback: false,
        cycle: -1,
        startPos: 0,
      );

      /// Mic mute thakleo music publish cholbe.
      await _keepMusicPublishingWhenMicMuted(
        rtcEngine,
        micMuted: mute.value,
      );

      selectedMusicPath.value = path;
      liveMusicName.value = name;
      liveMusicStatus.value = status == 'changed' ? 'changed' : 'playing';

      final sid = streamId.value;
      final hostId = authController.userProfile.value.user?.id?.toInt() ?? 0;

      if (sid != 0 && hostId != 0) {
        await sendMusicEvent(
          livestreamId: sid,
          hostId: hostId,
          status: status,
          musicName: name,
        );
      }

      Fluttertoast.showToast(msg: 'Music started');
    } catch (e) {
      print('❌ startLiveMusic error: $e');
      Fluttertoast.showToast(msg: 'Music start failed');
    }
  }

  Future<void> pauseLiveMusic({required RtcEngine? rtcEngine}) async {
    if (rtcEngine == null) return;

    try {
      await rtcEngine.pauseAudioMixing();
      liveMusicStatus.value = 'paused';

      await sendMusicEvent(
        livestreamId: streamId.value,
        hostId: authController.userProfile.value.user?.id?.toInt() ?? 0,
        status: 'paused',
        musicName: liveMusicName.value,
      );
    } catch (e) {
      print('❌ pauseLiveMusic error: $e');
    }
  }

  Future<void> resumeLiveMusic({required RtcEngine? rtcEngine}) async {
    if (rtcEngine == null) return;

    try {
      await rtcEngine.resumeAudioMixing();
      await _keepMusicPublishingWhenMicMuted(
        rtcEngine,
        micMuted: mute.value,
      );
      liveMusicStatus.value = 'resumed';

      await sendMusicEvent(
        livestreamId: streamId.value,
        hostId: authController.userProfile.value.user?.id?.toInt() ?? 0,
        status: 'resumed',
        musicName: liveMusicName.value,
      );
    } catch (e) {
      print('❌ resumeLiveMusic error: $e');
    }
  }

  Future<void> stopLiveMusic({required RtcEngine? rtcEngine}) async {
    try {
      await rtcEngine?.stopAudioMixing();

      selectedMusicPath.value = '';
      liveMusicName.value = '';
      liveMusicStatus.value = 'stopped';

      await sendMusicEvent(
        livestreamId: streamId.value,
        hostId: authController.userProfile.value.user?.id?.toInt() ?? 0,
        status: 'stopped',
        musicName: null,
      );
    } catch (e) {
      print('❌ stopLiveMusic error: $e');
    }
  }

  /// ===================== LIVE YOUTUBE APIs =====================
  String extractYoutubeVideoId(String url) {
    final raw = url.trim();
    if (raw.isEmpty) return '';

    final regExpList = <RegExp>[
      RegExp(r'(?:v=)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    ];

    for (final reg in regExpList) {
      final match = reg.firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? '';
      }
    }

    /// If user pastes only video id.
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(raw)) {
      return raw;
    }

    return '';
  }

  Future<void> sendYoutubeControl({
    required int livestreamId,
    required int hostId,
    required String status,
    String? youtubeUrl,
  }) async {
    if (livestreamId == 0 || hostId == 0) {
      Fluttertoast.showToast(msg: 'Live room not ready');
      return;
    }

    try {
      youtubeLoading.value = true;

      final response = await dio.post(
        '$kMainUrl/livestream/$livestreamId/youtube-control',
        data: {
          'host_id': hostId,
          'youtube_status': status,
          'youtube_url': ?youtubeUrl,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        final videoId = (data['youtube_video_id'] ??
            (youtubeUrl == null ? '' : extractYoutubeVideoId(youtubeUrl)))
            .toString();
        final url = (data['youtube_url'] ?? youtubeUrl ?? liveYoutubeUrl.value)
            .toString();

        liveYoutubeStatus.value = status;
        liveYoutubeUrl.value = status == 'stopped' ? '' : url;
        liveYoutubeVideoId.value = status == 'stopped' ? '' : videoId;

        print('✅ YouTube control sent: ${response.data}');
      } else {
        print('⚠️ YouTube control failed: ${response.statusCode} ${response.data}');
        Fluttertoast.showToast(msg: 'YouTube control failed');
      }
    } catch (e) {
      print('❌ YouTube control error: $e');
      Fluttertoast.showToast(msg: 'YouTube control failed');
    } finally {
      youtubeLoading.value = false;
    }
  }

  Future<void> playOrChangeYoutube(String url) async {
    final videoId = extractYoutubeVideoId(url);
    if (videoId.isEmpty) {
      Fluttertoast.showToast(msg: 'Invalid YouTube link');
      return;
    }

    final status = liveYoutubeStatus.value == 'stopped' ? 'playing' : 'changed';
    await sendYoutubeControl(
      livestreamId: streamId.value,
      hostId: authController.userProfile.value.user?.id?.toInt() ?? 0,
      status: status,
      youtubeUrl: url,
    );
  }

  Future<void> pauseYoutube() async {
    await sendYoutubeControl(
      livestreamId: streamId.value,
      hostId: authController.userProfile.value.user?.id?.toInt() ?? 0,
      status: 'paused',
      youtubeUrl: liveYoutubeUrl.value,
    );
  }

  Future<void> resumeYoutube() async {
    await sendYoutubeControl(
      livestreamId: streamId.value,
      hostId: authController.userProfile.value.user?.id?.toInt() ?? 0,
      status: 'resumed',
      youtubeUrl: liveYoutubeUrl.value,
    );
  }

  Future<void> stopYoutube() async {
    liveYoutubeStatus.value = 'stopped';
    liveYoutubeUrl.value = '';
    liveYoutubeVideoId.value = '';

    await sendYoutubeControl(
      livestreamId: streamId.value,
      hostId: authController.userProfile.value.user?.id?.toInt() ?? 0,
      status: 'stopped',
      youtubeUrl: null,
    );
  }

  Future<Map<String, dynamic>?> fetchYoutubeState(int livestreamId) async {
    if (livestreamId == 0) return null;

    try {
      final response = await dio.get(
        '$kMainUrl/livestream/$livestreamId/youtube-state',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          final status = (data['youtube_status'] ?? 'stopped').toString().toLowerCase();
          final url = (data['youtube_url'] ?? '').toString();
          final videoId = (data['youtube_video_id'] ?? extractYoutubeVideoId(url)).toString();

          liveYoutubeStatus.value = status;
          liveYoutubeUrl.value = status == 'stopped' ? '' : url;
          liveYoutubeVideoId.value = status == 'stopped' ? '' : videoId;

          print('✅ YouTube state fetched: $data');
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      print('❌ YouTube state fetch error: $e');
    }

    liveYoutubeStatus.value = 'stopped';
    liveYoutubeUrl.value = '';
    liveYoutubeVideoId.value = '';
    return null;
  }


  /// YouTube player error 152/150/101/unavailable hole host side theke call korben.
  /// Eta backend-e stopped event pathabe, audience UI clear hobe.
  Future<void> stopYoutubeBecauseUnavailable() async {
    liveYoutubeStatus.value = 'stopped';
    liveYoutubeUrl.value = '';
    liveYoutubeVideoId.value = '';

    final sid = streamId.value;
    final hostId = authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (sid != 0 && hostId != 0) {
      await sendYoutubeControl(
        livestreamId: sid,
        hostId: hostId,
        status: 'stopped',
        youtubeUrl: null,
      );
    }

    Fluttertoast.showToast(
      msg: 'This YouTube video cannot be played inside the app. Try another link.',
    );
  }

  /// ===================== LIVE ROOM REALTIME EDIT =====================
  /// Backend route:
  /// POST /livestream/{id}/edit/{userId}
  /// Expected event: action_type = live_stream_updated
  final roomEditLoading = false.obs;

  Future<Map<String, dynamic>?> editLiveStreamRoom({
    required int livestreamId,
    required int userId,
    required int seatCount,
    required int roomLayout,
    required int roomTheme,
    required int roomBackground,
  }) async {
    if (livestreamId == 0 || userId == 0) {
      Fluttertoast.showToast(msg: 'Live room not ready');
      return null;
    }

    try {
      roomEditLoading.value = true;

      /// Backend edit API create live-er moto sob key must chay.
      /// Existing value na pele safe default pathabo, nullable pathabo na.
      final currentLive = createStreamData['livestreamdata'] is Map
          ? Map<String, dynamic>.from(createStreamData['livestreamdata'])
          : createStreamData['livestream'] is Map
          ? Map<String, dynamic>.from(createStreamData['livestream'])
          : <String, dynamic>{};

      final String streamTitle =
      (currentLive['stream_bte'] ?? currentLive['title'] ?? 'Live')
          .toString();

      final int streamCoins = int.tryParse(
        (currentLive['stream_coins'] ?? 0).toString(),
      ) ??
          0;

      final int giftsCoins = int.tryParse(
        (currentLive['gifts_coins'] ?? 0).toString(),
      ) ??
          0;

      final String streamType =
      (currentLive['stream_type'] ?? 'audio').toString().trim().isEmpty
          ? 'audio'
          : (currentLive['stream_type'] ?? 'audio').toString();

      final data = <String, dynamic>{
        'seat_count': seatCount,
        'stream_bte': streamTitle,
        'stream_coins': streamCoins,
        'gifts_coins': giftsCoins,
        'room_layout': roomLayout.toString(),
        'stream_type': streamType,
        'room_theme': roomTheme.toString(),
        'room_background': roomBackground.toString(),
      };

      final url = '$kMainUrl/livestream/$livestreamId/edit/$userId';
      print('📤 LIVE ROOM EDIT URL => $url');
      print('📤 LIVE ROOM EDIT BODY => $data');

      final response = await dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
          /// 422 response-o print korbo, DioException-e hide hobe na.
          validateStatus: (status) => true,
        ),
      );

      print('📥 LIVE ROOM EDIT STATUS => ${response.statusCode}');
      print('📥 LIVE ROOM EDIT RESPONSE => ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};

        final liveData = body['livestreamdata'] is Map
            ? Map<String, dynamic>.from(body['livestreamdata'])
            : body['livestream'] is Map
            ? Map<String, dynamic>.from(body['livestream'])
            : <String, dynamic>{};

        if (liveData.isNotEmpty) {
          createStreamData['livestreamdata'] = liveData;
        } else {
          /// Response-e livestreamdata na thakleo local value sync thakbe.
          createStreamData['livestreamdata'] = {
            ...currentLive,
            ...data,
            'id': livestreamId,
          };
        }
        createStreamData.refresh();

        /// Host-er screen-e instantly update. Audience websocket event pabe.
        websocketController.updateLiveRoomSettings(
          livestreamId: livestreamId,
          seatCount: seatCount,
          roomLayout: roomLayout,
          roomTheme: roomTheme,
          roomBackground: roomBackground,
        );

        print(
          '✅ Live room edited locally => seats:$seatCount layout:$roomLayout theme:$roomTheme bg:$roomBackground',
        );
        Fluttertoast.showToast(msg: 'Room updated');
        return body;
      }

      print('⚠️ Live room edit failed: ${response.statusCode} ${response.data}');
      Fluttertoast.showToast(
        msg: response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Room update failed',
      );
      return null;
    } catch (e) {
      print('❌ Live room edit error: $e');
      Fluttertoast.showToast(msg: 'Room update failed');
      return null;
    } finally {
      roomEditLoading.value = false;
    }
  }


  /// ===================== SEAT SWITCH API =====================
  /// Audience/host already on a mic seat can move directly to another empty seat.
  /// Backend route:
  /// POST /livestream/{streamId}/seat/switch
  /// Body: {user_id, from_seat_no, to_seat_no}
  ///
  /// Backend will broadcast:
  /// action_type: seat_switched
  final seatSwitchLoading = false.obs;

  int currentUserSeatNo() {
    final currentUserId =
        authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (currentUserId == 0) return 0;

    for (final call in websocketController.liveCallList) {
      final map = call is Map ? Map<String, dynamic>.from(call) : {};
      if (map.isEmpty) continue;

      final callerId = map['caller_id'];
      final userId = map['user'] is Map ? map['user']['id'] : map['user_id'];
      final seatNo = int.tryParse(map['seat_no']?.toString() ?? '') ?? 0;

      final status = (map['call_status'] ?? '').toString().toLowerCase();
      final accepted = status.isEmpty ||
          status == 'accepted' ||
          status == 'active' ||
          status == 'joined';

      if (accepted &&
          seatNo > 0 &&
          (callerId.toString() == currentUserId.toString() ||
              userId.toString() == currentUserId.toString())) {
        return seatNo;
      }
    }

    return 0;
  }

  bool isSeatOccupied(int seatNo) {
    return websocketController.liveCallList.any((call) {
      final map = call is Map ? Map<String, dynamic>.from(call) : {};
      if (map.isEmpty) return false;

      final currentSeat = int.tryParse(map['seat_no']?.toString() ?? '') ?? 0;
      final status = (map['call_status'] ?? '').toString().toLowerCase();

      final accepted = status.isEmpty ||
          status == 'accepted' ||
          status == 'active' ||
          status == 'joined';

      return accepted && currentSeat == seatNo;
    });
  }

  Future<Map<String, dynamic>?> switchAudioSeat({
    required int livestreamId,
    required int toSeatNo,
    int? fromSeatNo,
  }) async {
    if (seatSwitchLoading.value) return null;

    final currentUserId =
        authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (currentUserId == 0) {
      Fluttertoast.showToast(msg: 'User not found');
      return null;
    }

    final oldSeatNo = fromSeatNo ?? currentUserSeatNo();

    if (oldSeatNo == 0) {
      Fluttertoast.showToast(msg: 'Please join a seat first');
      return null;
    }

    if (oldSeatNo == toSeatNo) {
      Fluttertoast.showToast(msg: 'You are already on this seat');
      return null;
    }

    try {
      final ws = Get.find<WebsocketController>();

      /// Do not switch to locked seat.
      if (ws.isSeatLocked(toSeatNo)) {
        Fluttertoast.showToast(msg: 'This seat is locked');
        return null;
      }

      /// Do not switch to occupied seat.
      final occupiedByOther = websocketController.liveCallList.any((call) {
        final map = call is Map ? Map<String, dynamic>.from(call) : {};
        if (map.isEmpty) return false;

        final seatNo = int.tryParse(map['seat_no']?.toString() ?? '') ?? 0;
        final callerId = map['caller_id'];
        final userId = map['user'] is Map ? map['user']['id'] : map['user_id'];

        final status = (map['call_status'] ?? '').toString().toLowerCase();
        final accepted = status.isEmpty ||
            status == 'accepted' ||
            status == 'active' ||
            status == 'joined';

        return accepted &&
            seatNo == toSeatNo &&
            callerId.toString() != currentUserId.toString() &&
            userId.toString() != currentUserId.toString();
      });

      if (occupiedByOther) {
        Fluttertoast.showToast(msg: 'Seat already occupied');
        return null;
      }

      seatSwitchLoading.value = true;

      final body = {
        'user_id': currentUserId,
        'from_seat_no': oldSeatNo,
        'to_seat_no': toSeatNo,
      };

      final url = '$kMainUrl/livestream/$livestreamId/seat/switch';

      print('📤 SEAT SWITCH URL => $url');
      print('📤 SEAT SWITCH BODY => $body');

      final response = await dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      print('📥 SEAT SWITCH STATUS => ${response.statusCode}');
      print('📥 SEAT SWITCH RESPONSE => ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};

        final callDataRaw = data['call_data'] ?? data['data'] ?? data['caller'];
        final callData = callDataRaw is Map
            ? Map<String, dynamic>.from(callDataRaw)
            : <String, dynamic>{
          'livestream_id': livestreamId,
          'caller_id': currentUserId,
          'seat_no': toSeatNo,
          'call_status': 'accepted',
        };

        /// Local instant update. Backend websocket `seat_switched` will sync again.
        try {
          Get.find<WebsocketController>().applySeatSwitch(
            userId: currentUserId,
            fromSeatNo: oldSeatNo,
            toSeatNo: toSeatNo,
            callData: callData,
          );
        } catch (e) {
          print('⚠️ Local applySeatSwitch skipped: $e');
        }

        return data;
      }

      final message = response.data is Map && response.data['message'] != null
          ? response.data['message'].toString()
          : 'Seat switch failed';

      Fluttertoast.showToast(msg: message);
      return null;
    } catch (e) {
      print('❌ switchAudioSeat error: $e');
      Fluttertoast.showToast(msg: 'Seat switch failed');
      return null;
    } finally {
      seatSwitchLoading.value = false;
    }
  }


  /// ===================== SEAT LOCK APIs =====================
  /// Only broadcaster should call these from UI.
  /// Backend will broadcast action_type: seat_lock_toggle.
  final seatLockLoading = false.obs;

  Future<Map<String, dynamic>?> toggleSeatLock({
    required int livestreamId,
    required int seatNo,
  }) async {
    if (seatLockLoading.value) return null;

    try {
      seatLockLoading.value = true;

      final response = await dio.post(
        '$kMainUrl/livestream/$livestreamId/seat/$seatNo/lock-toggle',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Seat lock toggle success: ${response.data}');

        /// Local instant update, websocket event ashlei abar sync hobe.
        final WebsocketController ws = Get.find();
        final data = response.data is Map ? response.data as Map : {};
        final lockedValue = data['is_locked'] ??
            data['locked'] ??
            data['seat']?['is_locked'] ??
            data['data']?['is_locked'];

        if (lockedValue != null) {
          ws.updateSeatLockStatus(
            seatNo: seatNo,
            isLocked: lockedValue == true ||
                lockedValue == 1 ||
                lockedValue.toString() == '1' ||
                lockedValue.toString().toLowerCase() == 'yes' ||
                lockedValue.toString().toLowerCase() == 'locked' ||
                lockedValue.toString().toLowerCase() == 'true',
          );
        } else {
          /// If backend does not return new state, toggle local state.
          ws.updateSeatLockStatus(
            seatNo: seatNo,
            isLocked: !ws.isSeatLocked(seatNo),
          );
        }

        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
      } else {
        print('⚠️ Seat lock toggle failed: ${response.statusCode} ${response.data}');
        Fluttertoast.showToast(msg: 'Seat lock failed');
        return null;
      }
    } catch (e) {
      print('❌ Seat lock toggle error: $e');
      Fluttertoast.showToast(msg: 'Seat lock failed');
      return null;
    } finally {
      seatLockLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> lockSeat({
    required int livestreamId,
    required int seatNo,
  }) async {
    try {
      final response = await dio.post(
        '$kMainUrl/livestream/$livestreamId/seat/$seatNo/lock',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200) {
        Get.find<WebsocketController>().updateSeatLockStatus(
          seatNo: seatNo,
          isLocked: true,
        );
        print('✅ Seat locked: $seatNo');
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      print('❌ lockSeat error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> unlockSeat({
    required int livestreamId,
    required int seatNo,
  }) async {
    try {
      final response = await dio.post(
        '$kMainUrl/livestream/$livestreamId/seat/$seatNo/unlock',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200) {
        Get.find<WebsocketController>().updateSeatLockStatus(
          seatNo: seatNo,
          isLocked: false,
        );
        print('✅ Seat unlocked: $seatNo');
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      print('❌ unlockSeat error: $e');
    }
    return null;
  }


  // Toggle user audio (mute/unmute)
  Future<Map<String, dynamic>?> toggleUserAudio(
      int streamId, int userId) async {
    try {
      final response = await dio.post(
        kAudioToggleUrl(streamId, userId),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error toggling user audio: $e');
      return null;
    }
  }

  // Toggle user video (mute/unmute)
  Future<Map<String, dynamic>?> toggleUserVideo(
      int streamId, int userId) async {
    try {
      final response = await dio.post(
        kVideoToggleUrl(streamId, userId),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error toggling user video: $e');
      return null;
    }
  }

  RxList<int> selectedProfileIndices = <int>[].obs;

// Select all items in the list
  void selectAll({required int totalItems}) {
    selectedProfileIndices.clear();
    for (int i = 0; i < totalItems; i++) {
      selectedProfileIndices.add(i);
    }
  }

  //Audio live image pick
  final audioImage = ''.obs;

  Future<void> audioimagePicker() async {
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
                  audioImage.value = photo.path;
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
                  audioImage.value = photo.path;
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

  // Missing methods from backup
  final startLiveTime = {}.obs;

  Future<void> liveTimeCase({
    required int streamId,
    required DateTime startTime,
  }) async {
    final data = {
      'stream_id': streamId,
      'start_time': startTime.toIso8601String(), // ✅ convert DateTime
    };

    try {
      final response = await dio.post(kLivestreamStartTime, data: data);

      print("start time data $data");

      if (response.statusCode == 200) {
        startLiveTime.value = response.data;
        print("Show Start time: ${response.data}");
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching live time: $e");
    }
  }

  Future<Map<String, dynamic>> checkCanJoinLivestream(
      int streamId, int userId) async {
    try {
      final response = await dio.get(
        kCheckCanJoinUrl(streamId, userId),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authController.userProfile.value.token}',
        }),
      );

      if (response.statusCode == 200) {
        return {
          'can_join': true,
          'message': response.data['message'] ?? 'Can join livestream'
        };
      } else {
        return {
          'can_join': false,
          'message': response.data['message'] ?? 'Cannot join livestream'
        };
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          return {
            'can_join': false,
            'message': e.response?.data['message'] ??
                'You are temporarily banned from this livestream',
            'remaining_minutes': e.response?.data['remaining_minutes'] ?? 0
          };
        } else if (e.response?.statusCode == 500) {
          print('Server Error (500): ${e.response?.data}');
          return {
            'can_join':
            true, // Allow join on server error to avoid blocking users
            'message': 'Server temporarily unavailable, proceeding with join'
          };
        } else {
          print('HTTP Error ${e.response?.statusCode}: ${e.response?.data}');
          return {
            'can_join': true, // Allow join on other HTTP errors
            'message': 'Unable to verify join status, proceeding with join'
          };
        }
      }
      print('Error checking join status: $e');
      return {
        'can_join': true, // Allow join on network/other errors
        'message': 'Unable to verify join status, proceeding with join'
      };
    }
  }

  // Room Extension Method
  Future<void> extendRoom(String livestreamId, int newSeatCount) async {
    try {
      final response = await dio.post(
        '$kDomainUrl/api/multi-live/$livestreamId/extend-room',
        data: {
          'new_seat_count': newSeatCount,
          'user_id': authController.userProfile.value.user?.id,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        print("✅ Room extended successfully: ${response.data}");
      } else {
        throw Exception('Failed to extend room: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response!.data['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Handle room extension WebSocket event

  // Make user guardian/administrator
  Future<Map<String, dynamic>?> makeGuardian(
      int livestreamId, int userId) async {
    try {
      print('Making user $userId guardian for livestream $livestreamId');

      final response = await dio.post(
        '$kMainUrl/livestream/$livestreamId/guardian/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      print('Make guardian response: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Failed to make guardian: ${response.statusCode}');
        return {'success': false, 'message': 'Failed to make guardian'};
      }
    } on DioException catch (e) {
      print('Error making guardian: $e');
      return {'success': false, 'message': 'Network error occurred'};
    } catch (e) {
      print('Unexpected error making guardian: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }


  /// ===================== LIVE IMOGI / EMOJI API =====================
  /// Backend:
  /// GET  api/api/imogi_list
  /// POST /livestream/imogi/send
  ///
  /// This block is added without removing/changing any old function.
  String _imogiString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  int _imogiInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  List<Map<String, dynamic>> _extractImogiItemsFromCategory(
      Map<String, dynamic> category,
      ) {
    final rawItems = category['imogies'] ??
        category['imogi'] ??
        category['emojis'] ??
        category['emoji'] ??
        category['items'] ??
        category['data'] ??
        category['list'] ??
        <dynamic>[];

    final items = _asList(rawItems);

    return items.map((item) {
      final map = _asMap(item);
      return <String, dynamic>{
        ...map,
        'id': map['id'] ?? map['imogi_id'] ?? map['emoji_id'],
        'name': map['name'] ?? map['title'] ?? map['imogi_name'] ?? 'Imogi',
        'image': map['image'] ??
            map['icon'] ??
            map['imogi_image'] ??
            map['emoji_image'] ??
            map['url'] ??
            map['file'],
        'category_id': map['category_id'] ?? category['id'],
        'category_name': map['category_name'] ?? category['name'],
      };
    }).where((item) => item['id'] != null).toList();
  }

  void _normalizeAndSetImogiData(dynamic rawResponse) {
    final root = _asMap(rawResponse);
    dynamic source = root['data'] ??
        root['categories'] ??
        root['category'] ??
        root['imogies'] ??
        root['emojis'] ??
        root['items'] ??
        rawResponse;

    final sourceList = _asList(source);

    final categories = <Map<String, dynamic>>[];
    final flatImogies = <Map<String, dynamic>>[];

    for (final item in sourceList) {
      final map = _asMap(item);

      final itemList = _extractImogiItemsFromCategory(map);
      final bool looksLikeCategory = itemList.isNotEmpty ||
          map.containsKey('imogies') ||
          map.containsKey('emojis') ||
          map.containsKey('items') ||
          map.containsKey('list');

      if (looksLikeCategory) {
        final category = <String, dynamic>{
          ...map,
          'id': map['id'] ?? map['category_id'] ?? categories.length,
          'name': map['name'] ?? map['title'] ?? map['category_name'] ?? 'Imogi',
          'image': map['image'] ?? map['icon'] ?? map['category_image'],
          'imogies': itemList,
        };

        categories.add(category);
        flatImogies.addAll(itemList);
      } else {
        flatImogies.add(<String, dynamic>{
          ...map,
          'id': map['id'] ?? map['imogi_id'] ?? map['emoji_id'],
          'name': map['name'] ?? map['title'] ?? map['imogi_name'] ?? 'Imogi',
          'image': map['image'] ??
              map['icon'] ??
              map['imogi_image'] ??
              map['emoji_image'] ??
              map['url'] ??
              map['file'],
          'category_id': map['category_id'] ?? 0,
          'category_name': map['category_name'] ?? map['category'] ?? 'All',
        });
      }
    }

    if (categories.isEmpty && flatImogies.isNotEmpty) {
      final grouped = <String, List<Map<String, dynamic>>>{};

      for (final imogi in flatImogies) {
        final key = _imogiString(
          imogi['category_id'] ?? imogi['category_name'],
          fallback: '0',
        );
        grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(imogi);
      }

      grouped.forEach((key, value) {
        final first = value.first;
        categories.add({
          'id': first['category_id'] ?? key,
          'name': first['category_name'] ?? 'Imogi',
          'image': first['category_image'] ?? first['image'],
          'imogies': value,
        });
      });
    }

    imogiCategoryList.assignAll(categories);
    imogiList.assignAll(flatImogies);
    if (selectedImogiCategoryIndex.value >= imogiCategoryList.length) {
      selectedImogiCategoryIndex.value = 0;
    }

    print(
      '✅ Imogi normalized => categories:${imogiCategoryList.length} imogies:${imogiList.length}',
    );
  }

  Future<void> fetchImogiList() async {
    if (imogiLoading.value) return;

    try {
      imogiLoading.value = true;

      /// kMainUrl usually already contains /api.
      /// User backend route is api/api/imogi_list, so primary URL is /api/imogi_list.
      final urls = <String>[
        '$kMainUrl/api/imogi_list',
        '$kMainUrl/imogi_list',
        '$kBaseUrl/api/imogi_list',
        '$kBaseUrl/imogi_list',
      ];

      Response? response;

      for (final url in urls) {
        try {
          print('📤 IMOGI LIST URL => $url');
          response = await dio.get(
            url,
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer ${authController.userProfile.value.token}',
              },
              validateStatus: (status) => true,
            ),
          );

          print('📥 IMOGI LIST STATUS => ${response.statusCode}');
          print('📥 IMOGI LIST RESPONSE => ${response.data}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            break;
          }
        } catch (e) {
          print('⚠️ Imogi list URL failed: $url => $e');
        }
      }

      if (response == null ||
          !(response.statusCode == 200 || response.statusCode == 201)) {
        Fluttertoast.showToast(msg: 'Imogi list load failed');
        return;
      }

      _normalizeAndSetImogiData(response.data);
    } catch (e) {
      print('❌ fetchImogiList error: $e');
      Fluttertoast.showToast(msg: 'Imogi list load failed');
    } finally {
      imogiLoading.value = false;
    }
  }

  List<Map<String, dynamic>> getImogiesByCategoryIndex(int index) {
    if (imogiCategoryList.isEmpty) return imogiList;

    final safeIndex = index.clamp(0, imogiCategoryList.length - 1).toInt();
    final category = imogiCategoryList[safeIndex];

    final list = category['imogies'];
    if (list is List) {
      return list.map((e) => _asMap(e)).toList();
    }

    return <Map<String, dynamic>>[];
  }

  bool isCurrentUserOnMicSeat() {
    final currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (currentUserId == 0) return false;

    final index = websocketController.liveCallList.indexWhere((call) {
      final seatNo = _imogiInt(call['seat_no']);
      final status = _imogiString(call['call_status']).toLowerCase();
      final callerId = call['caller_id'];
      final userId = call['user']?['id'] ?? call['User']?['id'];

      final bool accepted = status.isEmpty ||
          status == 'accepted' ||
          status == 'active' ||
          status == 'joined';

      return accepted &&
          seatNo >= 1 &&
          seatNo <= 20 &&
          (callerId.toString() == currentUserId.toString() ||
              userId.toString() == currentUserId.toString());
    });

    return index != -1;
  }

  Future<bool> sendLiveImogi({
    required int streamId,
    required int imogiId,
  }) async {
    if (imogiSending.value) return false;

    final senderId = authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (senderId == 0 || streamId == 0 || imogiId == 0) {
      Fluttertoast.showToast(msg: 'Imogi data missing');
      return false;
    }

    /// User must be on a mic/seat. Host seat_no 1 also allowed.
    if (!isCurrentUserOnMicSeat()) {
      Fluttertoast.showToast(msg: 'Please join a seat first');
      return false;
    }

    try {
      imogiSending.value = true;

      final data = {
        'sender_id': senderId,
        'imogi_id': imogiId,
        'stream_id': streamId,
      };

      final url = '$kMainUrl/livestream/imogi/send';

      print('📤 IMOGI SEND URL => $url');
      print('📤 IMOGI SEND BODY => $data');

      final response = await dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      print('📥 IMOGI SEND STATUS => ${response.statusCode}');
      print('📥 IMOGI SEND RESPONSE => ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      Fluttertoast.showToast(
        msg: response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Imogi send failed',
      );
      return false;
    } catch (e) {
      print('❌ sendLiveImogi error: $e');
      Fluttertoast.showToast(msg: 'Imogi send failed');
      return false;
    } finally {
      imogiSending.value = false;
    }
  }

  // Send emoji to livestream
  Future<void> sendEmoji(String emoji) async {
    try {
      final data = {
        "stream_id": streamId.value,
        "emoji": emoji,
        "user_id": authController.userProfile.value.user?.id,
      };

      final response = await dio.post(
        "${kBaseUrl}multi-live/send-emoji",
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer ${authController.userProfile.value.token}",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Emoji sent successfully: ${response.data}");
        // Hide emoji list after sending
        showEmoji.value = false;
      } else {
        print(
            "⚠️ Failed to send emoji: ${response.statusCode} - ${response.data}");
        Fluttertoast.showToast(msg: "Failed to send emoji");
      }
    } on DioException catch (e) {
      print("❌ Error sending emoji: $e");
      Fluttertoast.showToast(msg: "Error sending emoji");
    }
  }

  ///--------------------------- Guardian assigned -----------
  Future<void> setGuardian({required int StreanId, required int UserId}) async {
    try {
      final response = await dio.post(
        kSetGuardian(streamId: StreanId, userId: UserId),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer ${authController.userProfile.value.token}",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Set Guardian successfully: ${response.data}");
        await homeController.isGuardianBoll(StreamId: StreanId, userId: UserId);
        Get.back();
        // Hide emoji list after sending
      } else {
        print(
            "⚠️ Failed to send emoji: ${response.statusCode} - ${response.data}");
        Fluttertoast.showToast(msg: "Failed to send emoji");
      }
    } on DioException catch (e) {
      print("❌ Error sending emoji: $e");
      Fluttertoast.showToast(msg: "Error sending emoji");
    }
  }

  //remove admin ba guardian -----
  Future<void> removeGuardian(
      {required int StreanId, required int UserId}) async {
    try {
      print(kRemoveGuardian(streamId: StreanId, userId: UserId));
      final response = await dio.delete(
        kRemoveGuardian(streamId: StreanId, userId: UserId),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer ${authController.userProfile.value.token}",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Remove Guardian successfully: ${response.data}");
        await homeController.isGuardianBoll(StreamId: StreanId, userId: UserId);
        Get.back();
        // Hide emoji list after sending
      } else {
        print(
            "⚠️ Failed to send emoji: ${response.statusCode} - ${response.data}");
        Fluttertoast.showToast(msg: "Failed to send emoji");
      }
    } on DioException catch (e) {
      print("❌ Error sending emoji: $e");
      Fluttertoast.showToast(msg: "Error sending emoji");
    }
  }

  //- guaerdian LIst
  final guardianListData = [].obs;
  Future<void> GuardianList({required int StreanId}) async {
    try {
      final response = await dio.post(
        kGuardianList(
          streamId: StreanId,
        ),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer ${authController.userProfile.value.token}",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        guardianListData.value = response.data['guardians'];
        print("✅ Show Guardian List successfully: ${response.data}");

        // Hide emoji list after sending
      } else {
        print(
            "⚠️ Failed to send emoji: ${response.statusCode} - ${response.data}");
        Fluttertoast.showToast(msg: "Failed to send emoji");
      }
    } on DioException catch (e) {
      print("❌ Error sending emoji: $e");
      Fluttertoast.showToast(msg: "Error sending emoji");
    }
  }

  Future<void> agoraTokenGenerateError() async {
    try {
      final response = await dio.post(
        kAgoraTokenGenerateErrorApi(
          applicationId: agoraTokenController.agoraToken['application_form_id'],
        ),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer ${authController.userProfile.value.token}",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // guardianListData.value = response.data['guardians'];
        print("✅ Show Guardian List successfully: ${response.data}");

        // Hide emoji list after sending
      } else {
        print(
            "⚠️ Failed to send emoji: ${response.statusCode} - ${response.data}");
        Fluttertoast.showToast(msg: "Failed to send emoji");
      }
    } on DioException catch (e) {
      print("❌ Error sending emoji: $e");
      Fluttertoast.showToast(msg: "Error sending emoji");
    }
  }

  /// ===================== VIDEO PK SYSTEM =====================
  /// Added safely for Video PK without removing old live/gift/seat/comment code.
  final RxBool pkModeActive = false.obs;
  final RxBool pkRequestLoading = false.obs;
  final RxBool pkWaitingForResponse = false.obs;
  final RxBool pkRequestPopupVisible = false.obs;
  final RxBool pkResultVisible = false.obs;
  final RxString pkResultText = ''.obs;

  /// PK premium UI states.
  final RxBool pkStartIntroVisible = false.obs;
  final RxString pkStartIntroText = 'PK START'.obs;
  final RxBool pkEndingCountdownVisible = false.obs;
  final RxString pkEndingCountdownText = ''.obs;

  final RxMap<String, dynamic> currentPkData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> incomingPkRequest = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> pkResultData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _pkSenderLiveData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _pkReceiverLiveData = <String, dynamic>{}.obs;

  final RxInt currentPkId = 0.obs;
  final RxInt pkSenderLivestreamId = 0.obs;
  final RxInt pkReceiverLivestreamId = 0.obs;
  final RxInt pkSenderHostId = 0.obs;
  final RxInt pkReceiverHostId = 0.obs;
  final RxInt pkSenderScore = 0.obs;
  final RxInt pkReceiverScore = 0.obs;
  final RxInt pkSenderViewerCount = 0.obs;
  final RxInt pkReceiverViewerCount = 0.obs;
  final RxInt pkDurationSeconds = 300.obs;
  final RxInt pkRemainingSeconds = 0.obs;



  Timer? _pkTimer;

  /// Compatibility getter for PK widgets.
  RxBool get pkIsRunning => pkModeActive;

  /// Compatibility getter for PK widgets.
  Map<String, dynamic> get pkSenderLiveData => _pkSenderLiveData;

  /// Compatibility getter for PK widgets.
  Map<String, dynamic> get pkReceiverLiveData => _pkReceiverLiveData;

  String get pkFormattedRemainingTime {
    final int total = pkRemainingSeconds.value < 0 ? 0 : pkRemainingSeconds.value;
    final int minutes = total ~/ 60;
    final int seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get pkSenderProgress {
    final int sender = pkSenderScore.value;
    final int receiver = pkReceiverScore.value;
    final int total = sender + receiver;
    if (total <= 0) return 0.5;
    return sender / total;
  }

  bool get isCurrentUserPkSender {
    final int uid = authController.userProfile.value.user?.id?.toInt() ?? 0;
    return uid > 0 && uid == pkSenderHostId.value;
  }

  bool get isCurrentUserPkReceiver {
    final int uid = authController.userProfile.value.user?.id?.toInt() ?? 0;
    return uid > 0 && uid == pkReceiverHostId.value;
  }

  bool get isCurrentUserInPk => isCurrentUserPkSender || isCurrentUserPkReceiver;

  void _startPkTimer({required int durationSeconds}) {
    _pkTimer?.cancel();

    pkDurationSeconds.value = durationSeconds <= 0 ? 300 : durationSeconds;
    pkRemainingSeconds.value = pkDurationSeconds.value;

    _pkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!pkModeActive.value) {
        timer.cancel();
        return;
      }

      if (pkRemainingSeconds.value <= 0) {
        pkEndingCountdownVisible.value = false;
        pkEndingCountdownText.value = '';
        timer.cancel();
        if (isCurrentUserInPk && currentPkId.value > 0) {
          endPk(pkId: currentPkId.value);
        }
        return;
      }

      pkRemainingSeconds.value--;

      if (pkRemainingSeconds.value > 0 && pkRemainingSeconds.value <= 3) {
        pkEndingCountdownVisible.value = true;
        pkEndingCountdownText.value = pkRemainingSeconds.value.toString();
      } else {
        pkEndingCountdownVisible.value = false;
        pkEndingCountdownText.value = '';
      }
    });
  }

  void stopPkTimer() {
    _pkTimer?.cancel();
    _pkTimer = null;
  }

  void resetPkState({bool clearResult = true}) {
    stopPkTimer();

    pkModeActive.value = false;
    pkWaitingForResponse.value = false;
    pkRequestPopupVisible.value = false;

    currentPkData.clear();
    currentPkData.refresh();

    incomingPkRequest.clear();
    incomingPkRequest.refresh();

    _pkSenderLiveData.clear();
    _pkReceiverLiveData.clear();

    currentPkId.value = 0;
    pkSenderLivestreamId.value = 0;
    pkReceiverLivestreamId.value = 0;
    pkSenderHostId.value = 0;
    pkReceiverHostId.value = 0;

    pkSenderScore.value = 0;
    pkReceiverScore.value = 0;
    pkSenderViewerCount.value = 0;
    pkReceiverViewerCount.value = 0;

    pkDurationSeconds.value = 300;
    pkRemainingSeconds.value = 0;

    pkStartIntroVisible.value = false;
    pkEndingCountdownVisible.value = false;
    pkEndingCountdownText.value = '';

    pkChannelName.value = '';
    pkSenderRoomId.value = '';
    pkReceiverRoomId.value = '';

    if (clearResult) {
      pkResultVisible.value = false;
      pkResultText.value = '';
      pkResultData.clear();
      pkResultData.refresh();
    }

    update();
  }

  Future<bool> sendPkRequest({
    required int senderLivestreamId,
    required int receiverLivestreamId,
    required int senderHostId,
    required int receiverHostId,
    Map<String, dynamic>? receiverLiveData,
  }) async {
    if (pkRequestLoading.value) return false;

    if (senderLivestreamId <= 0 ||
        receiverLivestreamId <= 0 ||
        senderHostId <= 0 ||
        receiverHostId <= 0) {
      Fluttertoast.showToast(msg: 'PK data missing');
      return false;
    }

    try {
      pkRequestLoading.value = true;

      if (receiverLiveData != null) {
        _pkReceiverLiveData.value = Map<String, dynamic>.from(receiverLiveData);
      }

      final body = {
        'sender_livestream_id': senderLivestreamId,
        'receiver_livestream_id': receiverLivestreamId,
        'sender_host_id': senderHostId,
        'receiver_host_id': receiverHostId,
      };

      debugPrint('📤 PK REQUEST BODY => $body');

      final response = await dio.post(
        '$kMainUrl/pk/request',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      debugPrint('📥 PK REQUEST STATUS => ${response.statusCode}');
      debugPrint('📥 PK REQUEST RESPONSE => ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        pkWaitingForResponse.value = true;

        final data = _asMap(response.data is Map ? response.data['data'] : null);
        if (data.isNotEmpty) {
          currentPkId.value = _toInt(data['id']);
          pkSenderLivestreamId.value = _toInt(data['sender_livestream_id']);
          pkReceiverLivestreamId.value = _toInt(data['receiver_livestream_id']);
          pkSenderHostId.value = _toInt(data['sender_host_id']);
          pkReceiverHostId.value = _toInt(data['receiver_host_id']);
          pkChannelName.value = (data['pk_channel_name'] ?? '').toString();
          currentPkData.value = data;
        }

        Fluttertoast.showToast(msg: 'PK request sent');
        return true;
      }

      final message = response.data is Map && response.data['message'] != null
          ? response.data['message'].toString()
          : 'PK request failed';
      Fluttertoast.showToast(msg: message);
      return false;
    } catch (e) {
      debugPrint('❌ sendPkRequest error: $e');
      Fluttertoast.showToast(msg: 'PK request failed');
      return false;
    } finally {
      pkRequestLoading.value = false;
    }
  }

  Future<bool> respondPkRequest({
    required int pkId,
    required int receiverHostId,
    required String responseText,
  }) async {
    debugPrint('================ PK RESPOND START ================');
    debugPrint('📌 pkId => $pkId');
    debugPrint('📌 receiverHostId => $receiverHostId');
    debugPrint('📌 responseText => $responseText');
    debugPrint('📌 API URL => $kMainUrl/pk/respond');
    debugPrint('📌 User Token => ${authController.userProfile.value.token}');
    debugPrint('📌 User ID => ${authController.userProfile.value.user?.id}');
    debugPrint('📌 User Name => ${authController.userProfile.value.user?.name}');
    debugPrint('==================================================');

    if (pkId <= 0 || receiverHostId <= 0) {
      debugPrint('❌ PK request data missing');
      debugPrint('❌ Invalid pkId => $pkId');
      debugPrint('❌ Invalid receiverHostId => $receiverHostId');

      Fluttertoast.showToast(msg: 'PK request data missing');
      return false;
    }

    final Map<String, dynamic> requestBody = {
      'pk_id': pkId,
      'receiver_host_id': receiverHostId,
      'response': responseText,
    };

    final Map<String, dynamic> requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${authController.userProfile.value.token}',
    };

    try {
      debugPrint('🚀 PK RESPOND REQUEST URL => $kMainUrl/pk/respond');
      debugPrint('🚀 PK RESPOND REQUEST BODY => $requestBody');
      debugPrint('🚀 PK RESPOND REQUEST HEADERS => $requestHeaders');

      final response = await dio.post(
        '$kMainUrl/pk/respond',
        data: requestBody,
        options: Options(
          headers: requestHeaders,
          validateStatus: (status) => true,
        ),
      );

      debugPrint('================ PK RESPOND RESPONSE ================');
      debugPrint('📥 STATUS CODE => ${response.statusCode}');
      debugPrint('📥 STATUS MESSAGE => ${response.statusMessage}');
      debugPrint('📥 RESPONSE DATA => ${response.data}');
      debugPrint('📥 RESPONSE HEADERS => ${response.headers}');
      debugPrint('📥 REAL URI => ${response.realUri}');
      debugPrint('📥 REQUEST OPTIONS METHOD => ${response.requestOptions.method}');
      debugPrint('📥 REQUEST OPTIONS PATH => ${response.requestOptions.path}');
      debugPrint('📥 REQUEST OPTIONS DATA => ${response.requestOptions.data}');
      debugPrint('📥 REQUEST OPTIONS HEADERS => ${response.requestOptions.headers}');
      debugPrint('=====================================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ PK RESPOND SUCCESS');
        debugPrint('✅ Popup hide kortesi');
        debugPrint('✅ incomingPkRequest clear kortesi');

        pkRequestPopupVisible.value = false;
        incomingPkRequest.clear();

        debugPrint('================ PK RESPOND END SUCCESS ================');
        return true;
      }

      final message = response.data is Map && response.data['message'] != null
          ? response.data['message'].toString()
          : 'PK response failed';

      debugPrint('❌ PK RESPOND FAILED');
      debugPrint('❌ Error Message => $message');
      debugPrint('❌ Full Error Response => ${response.data}');
      debugPrint('================ PK RESPOND END FAILED ================');

      Fluttertoast.showToast(msg: message);
      return false;
    } catch (e, stackTrace) {
      debugPrint('================ PK RESPOND EXCEPTION ================');
      debugPrint('❌ respondPkRequest error => $e');
      debugPrint('❌ StackTrace => $stackTrace');
      debugPrint('❌ Request URL => $kMainUrl/pk/respond');
      debugPrint('❌ Request Body => $requestBody');
      debugPrint('❌ Request Headers => $requestHeaders');
      debugPrint('=====================================================');

      Fluttertoast.showToast(msg: 'PK response failed');
      return false;
    }
  }
  Future<bool> endPk({int? pkId}) async {
    final int targetPkId = pkId ?? currentPkId.value;
    if (targetPkId <= 0) return false;

    try {
      final response = await dio.post(
        '$kMainUrl/pk/end/$targetPkId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      debugPrint('📥 PK END STATUS => ${response.statusCode}');
      debugPrint('📥 PK END RESPONSE => ${response.data}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ endPk error: $e');
      return false;
    }
  }

  void handlePkRequestReceived(Map<String, dynamic> payload) {
    incomingPkRequest.value = Map<String, dynamic>.from(payload);
    currentPkId.value = _toInt(payload['pk_id'] ?? payload['data']?['id']);
    pkSenderLivestreamId.value =
        _toInt(payload['from_livestream_id'] ?? payload['sender_livestream_id'] ?? payload['data']?['sender_livestream_id']);
    pkReceiverLivestreamId.value =
        _toInt(payload['livestream_id'] ?? payload['receiver_livestream_id'] ?? payload['data']?['receiver_livestream_id']);
    pkSenderHostId.value =
        _toInt(payload['from_host_id'] ?? payload['sender_host_id'] ?? payload['data']?['sender_host_id']);
    pkReceiverHostId.value =
        _toInt(payload['to_host_id'] ?? payload['receiver_host_id'] ?? payload['data']?['receiver_host_id']);
    pkRequestPopupVisible.value = true;
  }

  void handlePkRequestSent(Map<String, dynamic> payload) {
    currentPkId.value = _toInt(payload['pk_id'] ?? payload['data']?['id']);
    pkSenderLivestreamId.value =
        _toInt(payload['livestream_id'] ?? payload['sender_livestream_id'] ?? payload['data']?['sender_livestream_id']);
    pkReceiverLivestreamId.value =
        _toInt(payload['to_livestream_id'] ?? payload['receiver_livestream_id'] ?? payload['data']?['receiver_livestream_id']);
    pkSenderHostId.value =
        _toInt(payload['from_host_id'] ?? payload['sender_host_id'] ?? payload['data']?['sender_host_id']);
    pkReceiverHostId.value =
        _toInt(payload['to_host_id'] ?? payload['receiver_host_id'] ?? payload['data']?['receiver_host_id']);
    pkWaitingForResponse.value = true;
  }

  void handlePkStarted(Map<String, dynamic> payload) {
    final nestedData = _asMap(payload['data']);
    final data = nestedData.isNotEmpty ? nestedData : payload;
    final mergedPayload = <String, dynamic>{
      ...nestedData,
      ...payload,
    };

    currentPkId.value = _toInt(payload['pk_id'] ?? data['id']);
    pkSenderLivestreamId.value = _toInt(payload['sender_livestream_id'] ?? data['sender_livestream_id']);
    pkReceiverLivestreamId.value = _toInt(payload['receiver_livestream_id'] ?? data['receiver_livestream_id']);
    pkSenderHostId.value = _toInt(payload['sender_host_id'] ?? data['sender_host_id']);
    pkReceiverHostId.value = _toInt(payload['receiver_host_id'] ?? data['receiver_host_id']);

    pkSenderScore.value = _toInt(payload['sender_score'] ?? data['sender_score']);
    pkReceiverScore.value = _toInt(payload['receiver_score'] ?? data['receiver_score']);

    pkChannelName.value = (payload['pk_channel_name'] ?? data['pk_channel_name'] ?? '').toString();
    pkSenderRoomId.value = (payload['sender_room_id'] ?? data['sender_room_id'] ?? '').toString();
    pkReceiverRoomId.value = (payload['receiver_room_id'] ?? data['receiver_room_id'] ?? '').toString();

    final senderLive = _asMap(data['sender_livestream'] ?? payload['sender_livestream']);
    final receiverLive = _asMap(data['receiver_livestream'] ?? payload['receiver_livestream']);
    if (senderLive.isNotEmpty) _pkSenderLiveData.value = senderLive;
    if (receiverLive.isNotEmpty) _pkReceiverLiveData.value = receiverLive;

    currentPkData.value = Map<String, dynamic>.from(mergedPayload);

    pkWaitingForResponse.value = false;
    pkRequestPopupVisible.value = false;
    pkResultVisible.value = false;
    pkModeActive.value = true;

    pkStartIntroVisible.value = true;
    pkStartIntroText.value = 'PK START';
    Future.delayed(const Duration(seconds: 2), () {
      pkStartIntroVisible.value = false;
    });

    final int duration = _toInt(payload['duration_seconds'] ?? data['duration_seconds']);
    _startPkTimer(durationSeconds: duration > 0 ? duration : 300);

    debugPrint('⚔️ PK started => pk=${currentPkId.value} sender=${pkSenderHostId.value} receiver=${pkReceiverHostId.value} channel=${pkChannelName.value}');
  }

  void handlePkScoreUpdated(Map<String, dynamic> payload) {
    final data = _asMap(payload['data']).isNotEmpty ? _asMap(payload['data']) : payload;

    final int senderScore = _toInt(data['sender_score'] ?? payload['sender_score'] ?? pkSenderScore.value);
    final int receiverScore = _toInt(data['receiver_score'] ?? payload['receiver_score'] ?? pkReceiverScore.value);

    pkSenderScore.value = senderScore;
    pkReceiverScore.value = receiverScore;

    // Backend jodi percent na pathay, UI getter score thekei percent calculate korbe.
    if (data['pk_id'] != null && currentPkId.value == 0) {
      currentPkId.value = _toInt(data['pk_id']);
    }

    debugPrint('📊 PK SCORE UPDATED => sender=$senderScore receiver=$receiverScore payload=$payload');
  }


  void updatePkViewerCountFromEvent(Map<String, dynamic> payload) {
    final data = _asMap(payload['data']).isNotEmpty ? _asMap(payload['data']) : payload;

    final int eventStreamId = _toInt(
      data['livestream_id'] ??
          data['stream_id'] ??
          data['live_stream_id'] ??
          data['room_id'],
    );

    if (eventStreamId <= 0) return;

    int count = _toInt(
      data['viewer_count'] ??
          data['livestream_viewers_count'] ??
          data['total_viewers'] ??
          data['count'],
    );

    if (count <= 0) {
      // Fallback: local list size for current stream when backend does not send count.
      if (eventStreamId == streamId.value) {
        count = liveViewerList.length;
      }
    }

    if (count < 0) return;

    if (pkSenderLivestreamId.value > 0 && eventStreamId == pkSenderLivestreamId.value) {
      pkSenderViewerCount.value = count;
    }

    if (pkReceiverLivestreamId.value > 0 && eventStreamId == pkReceiverLivestreamId.value) {
      pkReceiverViewerCount.value = count;
    }

    update();
    debugPrint('👀 PK VIEWER COUNT UPDATED => stream=$eventStreamId count=$count sender=${pkSenderViewerCount.value} receiver=${pkReceiverViewerCount.value}');
  }

  void handlePkRejected(Map<String, dynamic> payload) {
    pkWaitingForResponse.value = false;
    pkRequestPopupVisible.value = false;
    incomingPkRequest.clear();

    Fluttertoast.showToast(
      msg: payload['message']?.toString() ?? 'PK request rejected',
    );
  }

  int _resolvePkWinnerLivestreamId(Map<String, dynamic> data) {
    int winnerStreamId = _toInt(
      data['winner_livestream_id'] ??
          data['winner_stream_id'] ??
          data['winner_live_id'] ??
          data['winner_id'],
    );

    final String result = (data['result'] ?? data['winner'] ?? '').toString().toLowerCase();

    if (winnerStreamId == 0) {
      if (result.contains('sender') || result.contains('left')) {
        winnerStreamId = _toInt(data['sender_livestream_id'] ?? pkSenderLivestreamId.value);
      } else if (result.contains('receiver') || result.contains('right')) {
        winnerStreamId = _toInt(data['receiver_livestream_id'] ?? pkReceiverLivestreamId.value);
      }
    }

    final int senderScore = _toInt(data['sender_score'] ?? pkSenderScore.value);
    final int receiverScore = _toInt(data['receiver_score'] ?? pkReceiverScore.value);

    if (winnerStreamId == 0 && senderScore != receiverScore) {
      winnerStreamId = senderScore > receiverScore
          ? _toInt(data['sender_livestream_id'] ?? pkSenderLivestreamId.value)
          : _toInt(data['receiver_livestream_id'] ?? pkReceiverLivestreamId.value);
    }

    return winnerStreamId;
  }

  bool _isPkResultDraw(Map<String, dynamic> data) {
    final String result = (data['result'] ?? '').toString().toLowerCase();
    final int senderScore = _toInt(data['sender_score'] ?? pkSenderScore.value);
    final int receiverScore = _toInt(data['receiver_score'] ?? pkReceiverScore.value);

    return data['is_draw'] == true ||
        data['is_draw']?.toString() == '1' ||
        result == 'draw' ||
        result.contains('draw') ||
        (_resolvePkWinnerLivestreamId(data) == 0 && senderScore == receiverScore);
  }

  void _applyPkResult(
      Map<String, dynamic> payload, {
        String source = 'preview',
      }) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse('${value ?? 0}') ?? 0;
    }

    final nestedData = _asMap(payload['data']);

    dynamic pick(String key) {
      return payload[key] ?? nestedData[key];
    }

    final int myStreamId = toInt(streamId.value);

    final int senderStreamId = toInt(pick('sender_livestream_id'));
    final int receiverStreamId = toInt(pick('receiver_livestream_id'));

    final int senderScore = toInt(pick('sender_score'));
    final int receiverScore = toInt(pick('receiver_score'));

    int winnerStreamId = toInt(pick('winner_livestream_id'));
    int loserStreamId = toInt(pick('loser_livestream_id'));

    final String result = '${pick('result') ?? ''}'.toLowerCase();

    bool isDraw = pick('is_draw') == true ||
        pick('is_draw')?.toString() == '1' ||
        result == 'draw';

    // ✅ winner_livestream_id না থাকলে score/result দিয়ে winner বের করবো
    if (!isDraw && winnerStreamId == 0) {
      if (result == 'sender_win') {
        winnerStreamId = senderStreamId;
        loserStreamId = receiverStreamId;
      } else if (result == 'receiver_win') {
        winnerStreamId = receiverStreamId;
        loserStreamId = senderStreamId;
      } else if (senderScore > receiverScore) {
        winnerStreamId = senderStreamId;
        loserStreamId = receiverStreamId;
      } else if (receiverScore > senderScore) {
        winnerStreamId = receiverStreamId;
        loserStreamId = senderStreamId;
      } else {
        isDraw = true;
      }
    }

    String resultText;

    if (isDraw) {
      resultText = 'DRAW';
      print(
        '🤝 PK DRAW [$source] => my=$myStreamId sender=$senderScore receiver=$receiverScore',
      );
    } else if (winnerStreamId > 0 && winnerStreamId == myStreamId) {
      resultText = 'WIN';
      print(
        '🏆 PK WIN [$source] => my=$myStreamId winner=$winnerStreamId sender=$senderScore receiver=$receiverScore',
      );
    } else {
      resultText = 'LOSS';
      print(
        '💔 PK LOSS [$source] => my=$myStreamId winner=$winnerStreamId sender=$senderScore receiver=$receiverScore',
      );
    }

    pkResultText.value = resultText;
    pkResultVisible.value = true;

    pkResultData.assignAll({
      ...payload,
      'sender_livestream_id': senderStreamId,
      'receiver_livestream_id': receiverStreamId,
      'sender_score': senderScore,
      'receiver_score': receiverScore,
      'winner_livestream_id': winnerStreamId,
      'loser_livestream_id': loserStreamId,
      'is_draw': isDraw ? 1 : 0,
      'result_text': resultText,
      'source': source,
    });

    update();
  }

  void handlePkResultPreview(
      Map<String, dynamic> payload, {
        bool isEnded = false,
      }) {
    final nestedData = _asMap(payload['data']);

    // ✅ Top-level payload + nested data merge করলাম
    // Top-level priority বেশি, কারণ winner_livestream_id/result সাধারণত top-level এ থাকে
    final merged = <String, dynamic>{
      ...nestedData,
      ...payload,
    };

    _applyPkResult(merged, source: isEnded ? 'ended' : 'preview');

    Future.delayed(Duration(seconds: isEnded ? 5 : 4), () {
      pkResultVisible.value = false;
    });
  }

  void handlePkEnded(Map<String, dynamic> payload) {
    stopPkTimer();

    final nestedData = _asMap(payload['data']);
    final data = <String, dynamic>{
      ...nestedData,
      ...payload,
    };

    // ✅ আগে result calculate/show হবে
    _applyPkResult(Map<String, dynamic>.from(data), source: 'ended');

    // ✅ IMPORTANT:
    // PK card/camera overlay যেন ended হওয়ার পর camera এর উপর না থাকে,
    // তাই running PK data সাথে সাথে clear করবো।
    pkModeActive.value = false;
    pkStartIntroVisible.value = false;
    pkEndingCountdownVisible.value = false;
    pkEndingCountdownText.value = '';
    pkWaitingForResponse.value = false;
    pkRequestPopupVisible.value = false;

    currentPkData.clear();
    currentPkData.refresh();

    incomingPkRequest.clear();
    incomingPkRequest.refresh();

    _pkSenderLiveData.clear();
    _pkReceiverLiveData.clear();

    currentPkId.value = 0;
    pkSenderLivestreamId.value = 0;
    pkReceiverLivestreamId.value = 0;
    pkSenderHostId.value = 0;
    pkReceiverHostId.value = 0;

    pkSenderScore.value = 0;
    pkReceiverScore.value = 0;
    pkSenderViewerCount.value = 0;
    pkReceiverViewerCount.value = 0;

    pkDurationSeconds.value = 300;
    pkRemainingSeconds.value = 0;
    pkChannelName.value = '';
    pkSenderRoomId.value = '';
    pkReceiverRoomId.value = '';

    update();

    // ✅ শুধু result overlay 5 sec থাকবে, PK card/data আর থাকবে না
    Future.delayed(const Duration(seconds: 5), () {
      pkResultVisible.value = false;
      pkResultText.value = '';
      pkResultData.clear();
      update();
    });
  }

}
