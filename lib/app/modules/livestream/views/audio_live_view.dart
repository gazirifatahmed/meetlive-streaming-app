import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/live_viewers_list.dart';
import '../../../../widgets/tasksLiveView.dart';
import '../../../services/agora_service.dart';
import '../../moments/controllers/moments_controller.dart';
import '../../ranking/views/allrank.dart';
import '../controllers/livestream_controller.dart';
import '../controllers/websocket_controller.dart';
import '../utils/battery_optimizer.dart';
import '../widgets/LiveProfile_AppBar.dart';
import '../widgets/LiveView_Circle_Container.dart';
import '../widgets/entry_animation.dart';
import '../widgets/gifts_animation.dart';
import '../widgets/live_imogi_animation_overlay.dart';
import '../widgets/live_comments.dart';
import '../widgets/write_comments.dart';

class AudioLiveView extends StatefulWidget {
  final String channelName;
  final bool isBroadcaster;
  final int? seatCount;
  final String token;

  /// Room customization data
  /// roomLayout = selected layout index/id
  /// roomTheme = selected theme id
  /// roomBackground = selected background id (-1 means no background image)
  final int roomLayout;
  final int roomTheme;
  final int roomBackground;

  const AudioLiveView({
    super.key,
    required this.channelName,
    this.seatCount,
    required this.isBroadcaster,
    required this.token,
    this.roomLayout = 0,
    this.roomTheme = 0,
    this.roomBackground = -1,
  });

  @override
  State<AudioLiveView> createState() => _AudioLiveViewState();
}

class _AudioSeatPoint {
  final double x;
  final double y;

  const _AudioSeatPoint(this.x, this.y);
}

class _AudioLiveViewState extends State<AudioLiveView> with WidgetsBindingObserver {
  LivestreamController liveController = Get.find();
  WebsocketController websocketController = Get.put(WebsocketController());

  final AgoraService _agoraService = AgoraService();
  final streamData = Get.arguments;
  String? _currentToken;

  /// Minimize state: true hole dispose e Agora leave / ping stop hobe na.
  bool _isLiveMinimized = false;
  bool _isLiveExiting = false;
  bool _audienceLeaveRequested = false;

  /// Presence lifecycle state. Background/minimize hole offline call hobe na.
  bool _isAppInBackground = false;


  /// Agora speaking wave state.
  /// Backend chara Agora volume indication diye detect hobe ke kotha bolse.
  final Set<int> _speakingUserIds = <int>{};
  final Map<int, Timer> _speakingOffTimers = <int, Timer>{};
  static const int _speakingVolumeThreshold = 18;

  int _normalizeAgoraUid(int uid) {
    /// Agora local user-er jonno kichu case-e uid 0 aste pare.
    /// Tokhon current logged-in user id use korbo.
    if (uid == 0) {
      return authController.userProfile.value.user?.id?.toInt() ?? 0;
    }
    return uid;
  }

  bool _isUserSpeaking(dynamic userId) {
    final id = int.tryParse(userId?.toString() ?? '') ?? 0;
    return id != 0 && _speakingUserIds.contains(id);
  }

  int _safeInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? fallback;
  }

  bool _truthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    final text = value.toString().trim().toLowerCase();
    return text == '1' ||
        text == 'true' ||
        text == 'yes' ||
        text == 'muted' ||
        text == 'locked';
  }

  bool _falsey(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value == false;
    if (value is num) return value.toInt() == 0;
    final text = value.toString().trim().toLowerCase();
    return text == '0' ||
        text == 'false' ||
        text == 'no' ||
        text == 'unmuted' ||
        text == 'unlocked';
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  bool _mapSaysMuted(Map<String, dynamic> map) {
    if (map.isEmpty) return false;

    if (_truthy(map['host_is_muted']) ||
        _truthy(map['is_muted']) ||
        _truthy(map['is_muted_by_host']) ||
        _truthy(map['muted'])) {
      return true;
    }

    if (map.containsKey('host_audio_on') && _falsey(map['host_audio_on'])) {
      return true;
    }

    if (map.containsKey('audio_on') && _falsey(map['audio_on'])) {
      return true;
    }

    if (map.containsKey('is_audio_on') && _falsey(map['is_audio_on'])) {
      return true;
    }

    return false;
  }

  int _hostUserIdFromSnapshot() {
    final candidates = [
      streamInfo['host_id'],
      streamInfo['user_id'],
      streamInfo['livestream']?['host_id'],
      streamInfo['livestream']?['user_id'],
      streamData?['host_id'],
      streamData?['user_id'],
      streamData?['livestream']?['host_id'],
      streamData?['livestream']?['user_id'],
      streamData?['livestreamdata']?['host_id'],
      streamData?['livestreamdata']?['user_id'],
      broadcasterData['caller_id'],
      broadcasterData['user_id'],
      broadcasterData['user']?['id'],
    ];

    for (final value in candidates) {
      final id = _safeInt(value);
      if (id > 0) return id;
    }

    return 0;
  }

  bool _trustedSnapshotSaysHostMuted(int userId) {
    final hostId = _hostUserIdFromSnapshot();
    if (hostId <= 0 || hostId != userId) return false;

    final snapshots = <Map<String, dynamic>>[
      _safeMap(streamInfo),
      _safeMap(streamInfo['livestream']),
      _safeMap(streamData),
      _safeMap(streamData?['livestream']),
      _safeMap(streamData?['livestreamdata']),
      _safeMap(broadcasterData),
    ];

    for (final map in snapshots) {
      if (_mapSaysMuted(map)) return true;

      final callers = map['livestream_callers'];
      if (callers is List) {
        for (final rawCaller in callers) {
          final caller = _safeMap(rawCaller);
          final callerId = _safeInt(
            caller['caller_id'] ?? caller['user_id'] ?? caller['user']?['id'],
          );
          final isBroadcaster = _truthy(caller['is_broadcaster']);
          if (callerId == userId || isBroadcaster) {
            if (_mapSaysMuted(caller)) return true;
          }
        }
      }
    }

    return false;
  }

  bool _isUserMuted(dynamic userId) {
    final id = int.tryParse(userId?.toString() ?? '') ?? 0;
    if (id == 0) return false;

    /// Host mute state from addViewer/current snapshot has highest priority.
    /// Later stale live-list/caller data sometimes writes false into audioMutedUserMap.
    if (_trustedSnapshotSaysHostMuted(id)) {
      return true;
    }

    /// Realtime known mic state from websocket.
    if (websocketController.audioMutedUserMap.containsKey(id)) {
      return websocketController.audioMutedUserMap[id] == true;
    }

    /// Current logged in user hole local mute state check.
    final currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (id == currentUserId && liveController.mute.value == true) {
      return true;
    }

    /// Seat/call list theke mute state check.
    final index = websocketController.liveCallList.indexWhere((call) {
      final callerId = call['caller_id'];
      final uid = call['user']?['id'] ?? callerId;
      return uid.toString() == id.toString();
    });

    if (index == -1) return false;

    final call = Map<String, dynamic>.from(websocketController.liveCallList[index]);

    /// audio_on can be int/string/bool from backend.
    return _mapSaysMuted(call);
  }

  String _formatCoins(dynamic raw) {
    final coins = _safeInt(raw);
    if (coins >= 1000000) {
      final value = coins / 1000000;
      return value % 1 == 0 ? '${value.toInt()}M' : '${value.toStringAsFixed(1)}M';
    }
    if (coins >= 1000) {
      final value = coins / 1000;
      return value % 1 == 0 ? '${value.toInt()}k' : '${value.toStringAsFixed(1)}k';
    }
    return coins.toString();
  }

  int _coinFromMap(Map<String, dynamic> map) {
    final keys = [
      'total_gift_coins',
      'received_coins',
      'stream_coins',
      'gifts_coins',
      'gift_amount',
      'total_coins',
    ];

    for (final key in keys) {
      if (map.containsKey(key)) {
        final value = _safeInt(map[key]);
        if (value > 0) return value;
      }
    }

    final nestedLive = _safeMap(map['livestream'] ?? map['livestreamdata'] ?? map['data']);
    if (nestedLive.isNotEmpty) {
      final nestedValue = _coinFromMap(nestedLive);
      if (nestedValue > 0) return nestedValue;
    }

    return 0;
  }

  int _currentRoomReceivedCoins() {
    /// Controller live total is the best source after addViewer/live-list sync.
    final controllerCoins = _safeInt(liveController.totalGiftCoins.value);
    if (controllerCoins > 0) return controllerCoins;

    for (final map in [
      _safeMap(streamInfo),
      _safeMap(streamData),
      _safeMap(streamData?['livestreamdata']),
      _safeMap(broadcasterData),
    ]) {
      final value = _coinFromMap(map);
      if (value > 0) return value;
    }

    if (websocketController.liveCallList.isNotEmpty) {
      final firstCall = _safeMap(websocketController.liveCallList.first);
      final value = _safeInt(firstCall['earn_coins']);
      if (value > 0) return value;
    }

    return 0;
  }

  void _setSpeakingStatus({
    required int uid,
    required bool isSpeaking,
  }) {
    final userId = _normalizeAgoraUid(uid);
    if (userId == 0) return;

    final bool alreadySpeaking = _speakingUserIds.contains(userId);

    /// Muted user kotha bolleo wave show korbe na.
    if (isSpeaking && _isUserMuted(userId)) {
      isSpeaking = false;
    }

    if (isSpeaking) {
      _speakingOffTimers[userId]?.cancel();
      _speakingOffTimers[userId] = Timer(const Duration(milliseconds: 700), () {
        _setSpeakingStatus(uid: userId, isSpeaking: false);
      });

      if (!alreadySpeaking) {
        _speakingUserIds.add(userId);
        _updateLiveCallSpeakingStatus(userId: userId, isSpeaking: true);
        _scheduleUIUpdate();
      }
    } else {
      _speakingOffTimers[userId]?.cancel();
      _speakingOffTimers.remove(userId);

      if (alreadySpeaking) {
        _speakingUserIds.remove(userId);
        _updateLiveCallSpeakingStatus(userId: userId, isSpeaking: false);
        _scheduleUIUpdate();
      }
    }
  }

  void _updateLiveCallSpeakingStatus({
    required int userId,
    required bool isSpeaking,
  }) {
    final index = websocketController.liveCallList.indexWhere((call) {
      final callerId = call['caller_id'];
      final uid = call['user']?['id'] ?? callerId;
      return uid.toString() == userId.toString();
    });

    if (index != -1) {
      websocketController.liveCallList[index]['is_speaking'] = isSpeaking;
      websocketController.liveCallList.refresh();
    }
  }

  int get _currentLiveStreamId {
    final value = streamInfo['id'] ??
        streamData?['livestreamdata']?['id'] ??
        streamData?['livestream_id'] ??
        streamData?['id'];
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  bool get _hasLiveRoomRealtimeUpdate {
    final id = _currentLiveStreamId;
    return id != 0 && websocketController.liveRoomUpdateStreamId.value == id;
  }

  int get liveRoomLayout {
    if (_hasLiveRoomRealtimeUpdate) {
      return websocketController.liveRoomLayout.value;
    }

    final value = streamData?['livestreamdata']?['room_layout'] ??
        streamData?['room_layout'] ??
        widget.roomLayout;
    return int.tryParse(value.toString()) ?? widget.roomLayout;
  }

  int get liveRoomTheme {
    if (_hasLiveRoomRealtimeUpdate) {
      return websocketController.liveRoomTheme.value;
    }

    final value = streamData?['livestreamdata']?['room_theme'] ??
        streamData?['room_theme'] ??
        widget.roomTheme;
    return int.tryParse(value.toString()) ?? widget.roomTheme;
  }

  int get liveRoomBackground {
    if (_hasLiveRoomRealtimeUpdate) {
      return websocketController.liveRoomBackground.value;
    }

    final value = streamData?['livestreamdata']?['room_background'] ??
        streamData?['room_background'] ??
        widget.roomBackground;
    return int.tryParse(value.toString()) ?? widget.roomBackground;
  }

  final streamInfo = {}.obs;
  final broadcasterData = {}.obs;

  OverlayEntry? _miniLiveOverlay;
  Offset _miniBubbleOffset = Offset.zero;
  bool _miniBubbleDragging = false;
  final bool _seatLockSyncScheduled = false;

  Offset _musicPanelOffset = Offset.zero;
  bool _musicPanelDragging = false;

  YoutubePlayerController? _youtubeController;
  String _loadedYoutubeVideoId = '';
  String _lastYoutubeStatus = 'stopped';


  final addComments = TextEditingController();

  // Battery Optimization Variables
  final BatteryOptimizer _batteryOptimizer = BatteryOptimizer();
  PerformanceLevel _currentPerformanceLevel = PerformanceLevel.high;
  Timer? _batteryCheckTimer;
  Timer? _uiUpdateTimer;

  /// Same default theme gradients as GotoAudioLiveView.
  final List<List<Color>> themeGradients = const [
    [Color(0xff7BB9E9), Color(0xff6B72CF), Color(0xff5B2AB5)],
    [Color(0xfff6eee6), Color(0xffd7b98d), Color(0xff7b4a1d)],
    [Color(0xff6b203c), Color(0xff973d8f), Color(0xff2b124c)],
    [Color(0xffa8f5d0), Color(0xff55b97b), Color(0xff135c44)],
  ];

  int get liveSeatCount {
    if (_hasLiveRoomRealtimeUpdate && websocketController.liveRoomSeatCount.value > 0) {
      return websocketController.liveRoomSeatCount.value;
    }

    final value = streamData?['livestreamdata']?['seat_count'] ??
        streamData?['seat_count'] ??
        widget.seatCount ??
        20;
    return int.tryParse(value.toString()) ?? (widget.seatCount ?? 20);
  }

  int get safeLiveLayout {
    if (liveSeatCount == 9) {
      return liveRoomLayout.clamp(0, 3).toInt();
    }
    if (liveSeatCount == 12) {
      return liveRoomLayout.clamp(0, 4).toInt();
    }
    return 0;
  }

  List<Color> get _roomGradient {
    final list = liveController.themeList;

    /// room_theme database ID thakle API list theke oi ID-r index ber kore
    /// local gradient apply kora hobe. API-te color field na thakle eta safest.
    final themeIndex = list.indexWhere((item) {
      if (item is Map && item['id'] != null) {
        return item['id'].toString() == liveRoomTheme.toString();
      }
      return false;
    });

    final index = themeIndex >= 0
        ? themeIndex % themeGradients.length
        : liveRoomTheme.abs() % themeGradients.length;

    return themeGradients[index];
  }

  String? _imageUrlById(List<dynamic> list, int id) {
    if (id == -1) return null;

    final item = list.firstWhere(
          (element) {
        if (element is Map && element['id'] != null) {
          return element['id'].toString() == id.toString();
        }
        return false;
      },
      orElse: () => null,
    );

    if (item is Map && item['image'] != null) {
      return ImageHelper.getImageUrl(item['image'].toString());
    }

    return null;
  }

  String? get _roomBackgroundImageUrl {
    return _imageUrlById(liveController.backgroundList, liveRoomBackground);
  }

  BoxDecoration get _roomDecoration {
    final bgImage = _roomBackgroundImageUrl;

    if (bgImage != null) {
      return BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(bgImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: .18),
            BlendMode.darken,
          ),
        ),
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: _roomGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  void setLiveStreamDataAsBroadcaster() {
    streamInfo.value = streamData['livestreamdata'] ?? {};

    broadcasterData.value = streamData['broadcaster_call_data'] ?? {};
    // liveController.lastPingUpdate(id: streamInfo['id']);
    // Battery Optimization: Use optimized ping interval

    final pingInterval =
    _batteryOptimizer.getOptimizedPingInterval(_currentPerformanceLevel);
    liveController.updatePingInterval(pingInterval);
    liveController.lastPingUpdate(id: streamInfo['id']);

    ///------------- time
    if (!liveController.isLive.value) {
      String? createdAt = streamData['livestreamdata']?['created_at'] ??
          broadcasterData['created_at'];
      if (createdAt != null) {
        liveController.startLive(createdAt);
      } else {
        liveController.startLive(DateTime.now().toIso8601String());
      }
    }
  }

  void setLiveStreamDataAsAudience() {
    // Remove "livestream_callers" from streamInfo for audience
    broadcasterData.value = streamData['livestream_callers'][0];
    streamInfo.value = streamData ?? {};
  }

  Future<void> prepareForLive() async {
    // 🔹 1. Initialize Agora Engine (if not already)
    if (!_agoraService.isInitialized || _agoraService.engine == null) {

      bool initialized = await _agoraService.initializeEngine();
      if (!initialized) {
        print("Failed to initialize Agora engine");
        return;
      }
    }

    final engine = _agoraService.engine;
    if (engine == null) {
      print("Engine is null after initialization");
      return;
    }

    print("🎧 Configuring Agora for low-heat audio live...");

    // 🔹 2. Channel profile (must be LiveBroadcasting)
    await engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);

    // 🔹 3. Enable only audio (no video initialization at all)
    await engine.disableVideo();
    await engine.enableAudio();

    /// Speaking wave detect korar jonno Agora volume indication.
    /// Backend lagbe na, sob audience nijer app theke ke kotha bolse detect korbe.
    await engine.enableAudioVolumeIndication(
      interval: 300,
      smooth: 3,
      reportVad: true,
    );

    await engine.setParameters(
        '{"che.audio.low_power_mode": true}'); // Enable low power mode

    // 🔹 4. Set optimized audio profile based on performance level or battery
    final audioConfig =
    _batteryOptimizer.getOptimizedAudioConfig(_currentPerformanceLevel);

    await engine.setAudioProfile(
      profile:
      audioConfig['profile'] ?? AudioProfileType.audioProfileSpeechStandard,
      scenario: audioConfig['scenario'] ??
          AudioScenarioType.audioScenarioGameStreaming,
    );

    // 🔹 5. Extra optimization for low battery or heat
    if (_currentPerformanceLevel == PerformanceLevel.critical) {
      // Lower quality audio to reduce CPU and heat
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

      // Reduce CPU usage by disabling expensive audio processing
      await engine.setParameters('{"che.audio.enable.agc": false}');
      await engine.setParameters('{"che.audio.enable.aec": false}');
      await engine.setParameters(
          '{"che.audio.enable.ns": true}'); // keep noise suppression
    } else {
      // Normal / balanced mode
      await engine.setParameters('{"che.audio.enable.agc": true}');
      await engine.setParameters('{"che.audio.enable.aec": true}');
      await engine.setParameters('{"che.audio.enable.ns": true}');
    }

    // 🔹 6. Enable hardware acceleration if available
    await engine.setParameters('{"che.audio.hardware_encoding": true}');
    await engine.setParameters('{"che.audio.hardware_decoding": true}');

    // 🔹 7. Set client role (broadcaster vs audience)
    if (widget.isBroadcaster) {
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      /// Host mute korle local audio stream bondho korbo na,
      /// only mic recording volume 0/100 korbo. Tahole music mixing audience pabe.
      await engine.muteLocalAudioStream(false);
      await engine.adjustRecordingSignalVolume(liveController.mute.value ? 0 : 100);
      await engine.adjustAudioMixingVolume(65);
    } else {
      await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      await engine.muteLocalAudioStream(true); // Audience shouldn’t send audio
    }

    // 🔹 8. Register event handlers (optimized with debounced UI updates)
    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
        print("✅ Joined channel successfully");
        _scheduleUIUpdate();

        // Force speaker mode for better clarity
        await engine.setDefaultAudioRouteToSpeakerphone(true);
        await engine.setEnableSpeakerphone(true);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        print("👤 Remote user joined: $remoteUid");
        _scheduleUIUpdate();
        engine.muteRemoteAudioStream(uid: remoteUid, mute: false);
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        final uid = _normalizeAgoraUid(remoteUid);
        print("🚫 Remote user left: $uid");

        /// Agora offline means this user is no longer connected to this room.
        /// Clear wave + seat/call UI immediately, otherwise stale seat remains.
        _clearRemoteUserFromUi(uid);
      },

      /// WhatsApp-er moto speaking wave.
      /// Volume beshi hole oi user-er profile/seat-e wave show hobe.
      onAudioVolumeIndication: (
          RtcConnection connection,
          List<AudioVolumeInfo> speakers,
          int speakerNumber,
          int totalVolume,
          ) {
        for (final speaker in speakers) {
          final int uid = _normalizeAgoraUid(speaker.uid ?? 0);
          final int volume = speaker.volume ?? 0;

          if (uid == 0) continue;

          _setSpeakingStatus(
            uid: uid,
            isSpeaking: volume >= _speakingVolumeThreshold,
          );
        }
      },
      // 🔥 Correct onError handler
      onError: (ErrorCodeType err, String msg) {
        print("⚠️ Agora Error: $err | Message: $msg");
        if (widget.isBroadcaster) {
          livestreamController.agoraTokenGenerateError();
        }
      },
    ));

    // 🔹 9. Join channel
    int userId = authController.userProfile.value.user!.id!.toInt();
    await engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: userId,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: widget.isBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      ),
    );

    // 🔹 10. Debounced UI refresh
    _scheduleUIUpdate();

    print("🚀 Agora audio live ready (low-heat mode active)");
  }


  int _currentStreamIdFromArgs() {
    final value = streamData?['livestreamdata']?['id'] ??
        streamData?['livestream_id'] ??
        streamData?['id'] ??
        streamInfo['id'];
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }


  Map<String, dynamic>? _currentUserCallData() {
    final currentUserId =
        authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (currentUserId == 0) return null;

    for (final rawCall in websocketController.liveCallList) {
      if (rawCall is! Map) continue;

      final call = Map<String, dynamic>.from(rawCall);
      final callerId = call['caller_id'];
      final nestedUserId = call['user'] is Map ? call['user']['id'] : null;

      if (callerId.toString() == currentUserId.toString() ||
          nestedUserId.toString() == currentUserId.toString()) {
        return call;
      }
    }

    return null;
  }

  void _startAudioLivePresenceHeartbeat() {
    final sid = _currentStreamIdFromArgs();
    if (sid == 0) return;

    final currentUserId =
        authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (currentUserId == 0) return;

    final myCall = _currentUserCallData();
    final bool isOnSeat = widget.isBroadcaster || myCall != null;

    final String role = widget.isBroadcaster
        ? 'host'
        : isOnSeat
        ? 'caller'
        : 'viewer';

    int? seatNo;
    if (!widget.isBroadcaster && myCall != null && myCall['seat_no'] != null) {
      seatNo = int.tryParse(myCall['seat_no'].toString());
    }

    liveController.startLivePresenceHeartbeat(
      livestreamId: sid,
      role: role,
      isOnSeat: isOnSeat,
      seatNo: seatNo,
    );
  }

  Future<void> _syncAudioLivePresenceAfterResume() async {
    final sid = _currentStreamIdFromArgs();
    if (sid == 0) return;

    _startAudioLivePresenceHeartbeat();

    try {
      await liveController.sendPresenceHeartbeatOnce(
        livestreamId: sid,
        role: widget.isBroadcaster
            ? 'host'
            : _currentUserCallData() != null
            ? 'caller'
            : 'viewer',
        isOnSeat: widget.isBroadcaster || _currentUserCallData() != null,
        seatNo: _currentUserCallData()?['seat_no'] == null
            ? null
            : int.tryParse(_currentUserCallData()!['seat_no'].toString()),
      );

      await liveController.refreshLiveRoomRealtimeState(streamId: sid);
      await _loadInitialSeatLocks();
      await _loadYoutubeStateFromServer();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Audio live presence resume sync failed safely: $e');
    }
  }

  Future<void> _markAudioLiveOfflineForExplicitExit() async {
    final sid = _currentStreamIdFromArgs();
    final currentUserId =
        authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (sid == 0 || currentUserId == 0) return;

    final myCall = _currentUserCallData();

    await liveController.markUserOffline(
      livestreamId: sid,
      role: widget.isBroadcaster
          ? 'host'
          : myCall != null
          ? 'caller'
          : 'viewer',
      seatNo: myCall == null || myCall['seat_no'] == null
          ? null
          : int.tryParse(myCall['seat_no'].toString()),
    );
  }

  void _seedCurrentRoomCallList() {
    final seeded = <dynamic>[];

    if (widget.isBroadcaster && broadcasterData.isNotEmpty) {
      seeded.add(Map<String, dynamic>.from(broadcasterData));
    } else {
      final callers = streamData?['livestream_callers'];
      if (callers is List) {
        seeded.addAll(callers.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else if (broadcasterData.isNotEmpty) {
        seeded.add(Map<String, dynamic>.from(broadcasterData));
      }
    }

    if (seeded.isNotEmpty) {
      websocketController.liveCallList.assignAll(seeded);

      /// Seed last known mic state from current room data.
      /// Late audience join korle host jodi already mute thake, audience side-e
      /// host mute icon preserve thakbe and seat join/leave event eta reset korbe na.
      for (final raw in seeded) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final rawUserId = item['user'] is Map
            ? item['user']['id']
            : (item['user_id'] ?? item['caller_id'] ?? item['id']);
        final int uid = int.tryParse(rawUserId?.toString() ?? '0') ?? 0;
        if (uid <= 0) continue;

        final audioOn = item['audio_on'] ??
            item['is_audio_on'] ??
            (item['user'] is Map ? item['user']['audio_on'] : null) ??
            (item['user'] is Map ? item['user']['is_audio_on'] : null);
        final muted = item['is_muted'] ??
            item['muted'] ??
            item['is_muted_by_host'] ??
            (item['user'] is Map ? item['user']['is_muted'] : null);

        final a = audioOn?.toString().toLowerCase().trim() ?? '';
        final m = muted?.toString().toLowerCase().trim() ?? '';
        if (a == '0' || a == 'false' || a == 'off' || a == 'mute' || a == 'muted') {
          websocketController.audioMutedUserMap[uid] = true;
        } else if (a == '1' || a == 'true' || a == 'on' || a == 'unmute' || a == 'unmuted') {
          websocketController.audioMutedUserMap[uid] = false;
        } else if (m == '1' || m == 'true' || m == 'yes' || m == 'muted') {
          websocketController.audioMutedUserMap[uid] = true;
        } else if (m == '0' || m == 'false' || m == 'no' || m == 'unmuted') {
          websocketController.audioMutedUserMap[uid] = false;
        }
      }

      websocketController.liveCallList.refresh();
      websocketController.audioMutedUserMap.refresh();
      print('✅ Current room call list seeded: ${seeded.length}');
    }
  }

  void _syncInitialMusicStateFromStream() {
    final musicStatus = streamData?['livestreamdata']?['music_status'] ??
        streamData?['music_status'];
    final musicName = streamData?['livestreamdata']?['music_name'] ??
        streamData?['music_name'];
    final hostId = streamData?['livestreamdata']?['user_id'] ??
        streamData?['user_id'] ??
        broadcasterData['user']?['id'];

    if (musicStatus != null &&
        musicStatus.toString().isNotEmpty &&
        musicStatus.toString() != 'stopped' &&
        musicName != null &&
        musicName.toString().trim().isNotEmpty) {
      websocketController.liveMusicStatus.value = musicStatus.toString();
      websocketController.liveMusicName.value = musicName.toString();
      websocketController.liveMusicHostId.value =
          int.tryParse(hostId?.toString() ?? '0') ?? 0;

      if (!widget.isBroadcaster) {
        print('🎵 Initial live music state synced for audience: $musicName');
      }
    }
  }


  void _syncInitialYoutubeStateFromStream() {
    final youtubeStatus = streamData?['livestreamdata']?['youtube_status'] ??
        streamData?['youtube_status'];
    final youtubeUrl = streamData?['livestreamdata']?['youtube_url'] ??
        streamData?['youtube_url'];
    final youtubeVideoId = streamData?['livestreamdata']?['youtube_video_id'] ??
        streamData?['youtube_video_id'];
    final hostId = streamData?['livestreamdata']?['user_id'] ??
        streamData?['user_id'] ??
        broadcasterData['user']?['id'];

    final status = youtubeStatus?.toString() ?? 'stopped';
    final url = youtubeUrl?.toString() ?? '';
    final videoId = youtubeVideoId?.toString().isNotEmpty == true
        ? youtubeVideoId.toString()
        : liveController.extractYoutubeVideoId(url);

    if (status != 'stopped' && videoId.isNotEmpty) {
      websocketController.liveYoutubeStatus.value = status;
      websocketController.liveYoutubeUrl.value = url;
      websocketController.liveYoutubeVideoId.value = videoId;
      websocketController.liveYoutubeHostId.value =
          int.tryParse(hostId?.toString() ?? '0') ?? 0;

      if (!widget.isBroadcaster) {
        print('▶️ Initial YouTube state synced for audience: $videoId');
      }
    }
  }

  Future<void> _loadYoutubeStateFromServer() async {
    final sid = _currentStreamIdFromArgs();
    if (sid == 0) return;

    final data = await liveController.fetchYoutubeState(sid);
    if (data == null) {
      websocketController.liveYoutubeStatus.value = 'stopped';
      websocketController.liveYoutubeUrl.value = '';
      websocketController.liveYoutubeVideoId.value = '';
      _disposeYoutubeController();
      return;
    }

    final status = (data['youtube_status'] ?? 'stopped').toString().toLowerCase();
    final url = (data['youtube_url'] ?? '').toString();
    final videoId = (data['youtube_video_id'] ?? liveController.extractYoutubeVideoId(url)).toString();

    if (status != 'stopped' && videoId.isNotEmpty) {
      websocketController.liveYoutubeStatus.value = status;
      websocketController.liveYoutubeUrl.value = url;
      websocketController.liveYoutubeVideoId.value = videoId;
      websocketController.liveYoutubeHostId.value =
          int.tryParse((data['host_id'] ?? 0).toString()) ?? 0;
    } else {
      websocketController.liveYoutubeStatus.value = 'stopped';
      websocketController.liveYoutubeUrl.value = '';
      websocketController.liveYoutubeVideoId.value = '';
      _disposeYoutubeController();
      print('▶️ YouTube state stopped/empty, local player cleared');
    }
  }

  bool get _isYoutubeActiveForSeatLayout {
    final status = widget.isBroadcaster
        ? liveController.liveYoutubeStatus.value
        : websocketController.liveYoutubeStatus.value;
    final videoId = widget.isBroadcaster
        ? liveController.liveYoutubeVideoId.value
        : websocketController.liveYoutubeVideoId.value;

    return (liveSeatCount == 9 || liveSeatCount == 12) &&
        status != 'stopped' &&
        videoId.trim().isNotEmpty;
  }

  YoutubePlayerController? _ensureYoutubeController({
    required String videoId,
    required String status,
  }) {
    if (videoId.trim().isEmpty || status == 'stopped') {
      _disposeYoutubeController();
      return null;
    }

    final normalizedStatus = status.toLowerCase().trim();
    final shouldPlay = normalizedStatus == 'playing' ||
        normalizedStatus == 'resumed' ||
        normalizedStatus == 'changed';

    if (_youtubeController == null || _loadedYoutubeVideoId != videoId) {
      _disposeYoutubeController();
      _loadedYoutubeVideoId = videoId;

      /// youtube_player_flutter Android WebView Errors[152] int/String crash fix.
      /// iframe package use korle video play smooth hoy and crash kom hoy.
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: shouldPlay,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: false,
          strictRelatedVideos: true,
          playsInline: true,
        ),
      );

      _lastYoutubeStatus = '';
    }

    final controller = _youtubeController;
    if (controller == null) return null;

    if (_lastYoutubeStatus != normalizedStatus) {
      _lastYoutubeStatus = normalizedStatus;
      _applyYoutubeStatusSafely(
        controller: controller,
        status: normalizedStatus,
      );
    }

    return controller;
  }

  void _applyYoutubeStatusSafely({
    required YoutubePlayerController controller,
    required String status,
  }) {
    final shouldPlay = status == 'playing' ||
        status == 'resumed' ||
        status == 'changed';

    void apply() {
      if (!mounted || _youtubeController != controller) return;

      try {
        controller.unMute();
        if (shouldPlay) {
          controller.playVideo();
        } else if (status == 'paused') {
          controller.pauseVideo();
        }
      } catch (e) {
        print('⚠️ YouTube apply status ignored: $e');
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    Future.delayed(const Duration(milliseconds: 450), apply);
    Future.delayed(const Duration(milliseconds: 1100), apply);
    Future.delayed(const Duration(milliseconds: 1800), apply);
  }

  void _disposeYoutubeController() {
    try {
      _youtubeController?.close();
    } catch (_) {}
    _youtubeController = null;
    _loadedYoutubeVideoId = '';
    _lastYoutubeStatus = 'stopped';
  }


  bool _snapshotHasFreshRoomState(Map<String, dynamic> map) {
    bool hasAnyKey(Map<String, dynamic> source, List<String> keys) {
      for (final key in keys) {
        if (source.containsKey(key) && source[key] != null) return true;
      }
      return false;
    }

    const trustedKeys = [
      'locked_seats',
      'lockedSeats',
      'locked_seat_numbers',
      'lockedSeatNumbers',
      'host_audio_on',
      'host_is_muted',
      'audio_on',
      'is_muted',
      'total_gift_coins',
      'received_coins',
      'stream_coins',
      'gifts_coins',
      'livestream_callers',
    ];

    if (hasAnyKey(map, trustedKeys)) return true;

    final nestedLive = map['livestream'] ?? map['livestreamdata'] ?? map['data'];
    if (nestedLive is Map) {
      return hasAnyKey(Map<String, dynamic>.from(nestedLive), trustedKeys);
    }

    return false;
  }

  void _syncRoomSnapshotIfFresh(
      dynamic raw, {
        required String source,
      }) {
    if (raw is! Map || raw.isEmpty) return;

    final map = Map<String, dynamic>.from(raw);

    /// Old navigation args often contain stale broadcaster/caller data.
    /// They were overwriting the fresh addViewer/live-list snapshot:
    /// - locked_seats [4,8] became fake seat [1]
    /// - host muted true became false
    /// - gift coin total disappeared/zero
    /// So init/broadcaster snapshots are applied only when they carry trusted
    /// root-level room state.
    final bool isOldInitSource = source.startsWith('audio_init_args_') ||
        source.startsWith('audio_stream_info_') ||
        source.startsWith('audio_broadcaster_data_');

    if (isOldInitSource && !_snapshotHasFreshRoomState(map)) {
      print('⏭️ Stale room snapshot skipped => $source');
      return;
    }

    websocketController.syncRoomSnapshotForLateJoin(
      map,
      source: source,
    );
  }

  Future<void> _syncLateJoinFullRoomState({String reason = 'manual'}) async {
    try {
      final int sid = _currentStreamIdFromArgs();
      if (sid <= 0) return;

      websocketController.streamID.value = sid;
      websocketController.activeAudioStreamId.value = sid;

      /// 1) Apply only trusted/fresh navigation response.
      /// Stale init args must not override addViewer/current backend snapshot.
      _syncRoomSnapshotIfFresh(
        streamData,
        source: 'audio_init_args_$reason',
      );

      _syncRoomSnapshotIfFresh(
        streamInfo,
        source: 'audio_stream_info_$reason',
      );

      _syncRoomSnapshotIfFresh(
        broadcasterData,
        source: 'audio_broadcaster_data_$reason',
      );

      /// 2) Force load authoritative lock + gift total from backend.
      await _loadInitialSeatLocks();
      await websocketController.fetchInitialGiftTotal(streamId: sid);

      /// 3) Tell backend this viewer joined/resumed so backend can broadcast current state.
      await liveController.refreshLiveRoomRealtimeState(
        streamId: sid,
        role: widget.isBroadcaster ? 'host' : 'viewer',
        isOnSeat: widget.isBroadcaster || _currentUserCallData() != null,
        seatNo: _currentUserCallData()?['seat_no'] == null
            ? null
            : int.tryParse(_currentUserCallData()?['seat_no'].toString() ?? ''),
      );

      print('✅ Late join full room state sync done => $reason stream:$sid');
    } catch (e) {
      print('❌ Late join full room state sync failed => $reason $e');
    }
  }

  @override
  void initState() {
    // Enable wake lock to keep screen on during live streaming
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
    _currentToken = widget.token;

    /// New live/open room start hole old room-er locked seats clear kore dibo.
    /// Nahole previous broad-er locked seat new broad-eo show korto.
    websocketController.lockedSeatMap.clear();
    websocketController.lockedSeatMap.refresh();

    print(
      '🎨 AudioLiveView Room Data => '
          'seatCount: $liveSeatCount, layout: $liveRoomLayout, '
          'theme: $liveRoomTheme, background: $liveRoomBackground',
    );

    /// Theme/background API list load kore ID match korbe.
    liveController.showTheme();
    liveController.showBackground();

    // Initialize battery monitoring
    _initializeBatteryMonitoring();

    prepareForLive();

    // Initialize mute state to false (unmuted)
    liveController.mute.value = false;

    if (widget.isBroadcaster) {
      liveController.isBroadcaster.value = true;
      setLiveStreamDataAsBroadcaster();
    } else {
      setLiveStreamDataAsAudience();
    }

    /// New room hole old room-er entry/comment/gift/seat/call data clear.
    /// Same room minimize theke back korle clear hobe na.
    final int currentStreamId = _currentStreamIdFromArgs();
    websocketController.resetAudioRoomStateForStream(newStreamId: currentStreamId);

    /// Reset-er por current room-er broadcaster/caller seats abar seed.
    _seedCurrentRoomCallList();

    /// Late audience join korle DB theke current music/youtube status show.
    _syncInitialMusicStateFromStream();

    /// Initial values also seed websocket room edit state so host edit sheet and UI stay synced.
    final initialStreamId = _currentLiveStreamId;
    if (initialStreamId != 0) {
      websocketController.updateLiveRoomSettings(
        livestreamId: initialStreamId,
        seatCount: liveSeatCount,
        roomLayout: liveRoomLayout,
        roomTheme: liveRoomTheme,
        roomBackground: liveRoomBackground,
      );
      print('🎨 Initial live room realtime values synced');
    }
    _syncInitialYoutubeStateFromStream();

    /// Late join/viewer der jonno current room full state sync.
    /// Lock/mute/gift coin old websocket event notun audience pabe na, tai open hole snapshot load must.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLateJoinFullRoomState(reason: 'post_frame');
      _loadYoutubeStateFromServer();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      _syncLateJoinFullRoomState(reason: 'delay_700ms');
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      _syncLateJoinFullRoomState(reason: 'delay_1600ms');
    });
    // Broadcaster ke viewer hisebe add korbo na. Audience join korle only viewer add hobe.
    // Ete host-er nijer profile viewer list-e dhukbe na, ar broadcaster side-e list clean thakbe.
    final int sidForViewer = _currentStreamIdFromArgs();
    final int currentUidForViewer =
        authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (!widget.isBroadcaster && sidForViewer > 0 && currentUidForViewer > 0) {
      liveController.tryToAddViewer(
        streamId: sidForViewer,
        viewerId: currentUidForViewer,
      ).then((_) {
        _syncLateJoinFullRoomState(reason: 'after_viewer_add');
      });
    } else if (widget.isBroadcaster && sidForViewer > 0) {
      // Host live create/open korar sathe sathe latest viewer/caller/list/gift/lock sync.
      _syncLateJoinFullRoomState(reason: 'host_open');
    }

    /// Start presence heartbeat after current room + initial call list seed.
    /// API fail hole crash korbe na; controller internally catches errors.
    _startAudioLivePresenceHeartbeat();

    // TODO: implement initState
    super.initState();
  }

  void getActiveBroadcasterAudio({required List<dynamic> listActive}) async {
    if (_agoraService.engine != null) {
      for (var activeCallData in listActive) {
        if (activeCallData is! Map) continue;
        final dynamic uidRaw = activeCallData['user'] is Map
            ? activeCallData['user']['id']
            : (activeCallData['caller_id'] ?? activeCallData['user_id'] ?? activeCallData['id']);
        final int uid = int.tryParse(uidRaw?.toString() ?? '') ?? 0;
        if (uid != 0 && uid == authController.userProfile.value.user!.id!) {
          await _agoraService.engine!
              .setClientRole(role: ClientRoleType.clientRoleBroadcaster);
          // Do not auto-enable audio here to avoid background activation.
          // Respect user control for mic on/off.
        }
      }
    }
  }

  void removeBroadcaster() async {
    await _agoraService.engine!
        .setClientRole(role: ClientRoleType.clientRoleAudience);
    await _agoraService.engine!.muteLocalAudioStream(true);
  }

  void _clearRemoteUserFromUi(int userId) {
    if (userId == 0) return;

    _setSpeakingStatus(uid: userId, isSpeaking: false);

    // Agora onUserOffline minimize/network switch/call change-er somoy temporary fire korte pare.
    // Tai ekhane seat/caller data clear korbo na. Real seat leave/remove event or API sync
    // liveCallList update korbe. Eta fix kore: minimize kore back ashle seated audience vanish hobe na.
    if (mounted) {
      _scheduleUIUpdate();
    }

    print('ℹ️ Remote user Agora offline only, seat kept until backend/event confirms: $userId');
  }

  Future<void> _leaveAudienceRoomAndSeat({bool navigateBack = false}) async {
    if (_audienceLeaveRequested) return;
    _audienceLeaveRequested = true;

    final userId = authController.userProfile.value.user?.id?.toInt() ?? 0;
    final streamIdValue = int.tryParse(streamInfo['id']?.toString() ?? '') ?? 0;

    if (userId == 0 || streamIdValue == 0) {
      print('⚠️ audience leave skipped: userId=$userId streamId=$streamIdValue');
      return;
    }

    /// Clear local UI immediately, so seat/wave disappears without waiting API/ws.
    websocketController.clearSpecificUserStreamData(
      userId: userId.toString(),
      rejectCallIfInCallList: false,
    );

    /// If user was sitting in a seat, remove call/seat from backend first.
    /// This prevents old seat staying visible when user joins again.
    final wasInSeat = websocketController.liveCallList.any((call) {
      if (call is! Map) return false;
      final callerId = call['caller_id'];
      final nestedUserId = call['user'] is Map ? call['user']['id'] : null;
      return callerId.toString() == userId.toString() ||
          nestedUserId.toString() == userId.toString();
    });

    if (wasInSeat) {
      try {
        await liveController.tryToRejectCall(
          streamId: streamIdValue,
          userId: userId,
        );
        print('✅ Audience seat/call cleared before viewer remove: $userId');
      } catch (e) {
        print('⚠️ Audience seat/call clear failed/ignored: $e');
      }
    }

    try {
      await liveController.tryToRemoveViewer(
        streamId: streamIdValue,
        viewerId: userId,
      );
    } catch (e) {
      print('⚠️ Audience viewer remove failed/ignored: $e');
    }

    try {
      await _agoraService.engine?.leaveChannel();
    } catch (e) {
      print('⚠️ Agora leave audience ignored: $e');
    }

    if (navigateBack && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('📱 AudioLiveView lifecycle changed: $state');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isAppInBackground = true;

      /// Important: background/minimize hole offline call, list clear,
      /// Agora leave konotai hobe na. Backend heartbeat timeout handle korbe.
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _isAppInBackground = false;
      _recoverLiveRoomAfterResume();
      _syncAudioLivePresenceAfterResume();
    }
  }

  Future<void> _recoverLiveRoomAfterResume() async {
    if (_isLiveExiting) return;

    try {
      print('🔄 Recovering audio live room after app resume / network back');

      websocketController.tryToConnectToUnifiedLiveStreamEventWs(force: false);

      final int sid = int.tryParse(streamInfo['id']?.toString() ?? '') ??
          liveController.streamId.value;

      if (sid != 0) {
        await liveController.tryToGetCallList(streamId: sid);
        await liveController.showLiveViewerListList(streamId: sid);
        await liveController.getAvailableSeats(sid);
        await liveController.fetchYoutubeState(sid);
        await _loadInitialSeatLocks();
        await _loadYoutubeStateFromServer();
      }

      final engine = _agoraService.engine;
      if (engine != null) {
        await engine.setChannelProfile(
          ChannelProfileType.channelProfileLiveBroadcasting,
        );

        if (widget.isBroadcaster) {
          await engine.setClientRole(
            role: ClientRoleType.clientRoleBroadcaster,
          );
        } else {
          await engine.setClientRole(
            role: ClientRoleType.clientRoleAudience,
          );
        }

        /// Host mute korleo audio track open thakbe, mic volume 0/100 diye control.
        await engine.muteLocalAudioStream(false);
        await engine.adjustRecordingSignalVolume(liveController.mute.value ? 0 : 100);

        if (liveController.isLiveMusicPlaying) {
          await engine.adjustAudioMixingVolume(80);
          await engine.adjustAudioMixingPlayoutVolume(80);
          await engine.adjustAudioMixingPublishVolume(80);
        }
      } else {
        print('⚠️ Agora engine null on resume, preparing live again...');
        await prepareForLive();
      }

      if (mounted) setState(() {});
      print('✅ Audio live room recovered after resume');
    } catch (e, st) {
      print('❌ Audio live room recover failed: $e\n$st');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Battery Optimization: Cancel timers
    _batteryCheckTimer?.cancel();
    _uiUpdateTimer?.cancel();

    for (final timer in _speakingOffTimers.values) {
      timer.cancel();
    }
    _speakingOffTimers.clear();
    _speakingUserIds.clear();

    // Disable wake lock to restore normal screen behavior
    WakelockPlus.disable();

    /// Minimize korle live active thakbe.
    /// Tai ping stop, viewer remove, Agora leave korbo na.
    if (_isLiveExiting) {
      _miniLiveOverlay?.remove();
      _miniLiveOverlay = null;
      liveController.isBroadcaster.value = false;
      liveController.stopPingUpdate();
      liveController.stopLivePresenceHeartbeat();

      /// Explicit exit only: backend offline/remove/end korte parbe.
      _markAudioLiveOfflineForExplicitExit();

      if (!widget.isBroadcaster) {
        /// Fire-and-forget because dispose cannot await.
        _leaveAudienceRoomAndSeat();
      } else {
        _agoraService.engine?.leaveChannel();
      }
    } else {
      /// Background/minimize/unexpected dispose: live session keep.
      /// Offline API call, viewer remove, list clear, Agora leave korbo na.
      print('✅ Audio live dispose without explicit exit/background: keeping live session');
    }

    _disposeYoutubeController();

    super.dispose();
  }

  Future<void> _minimizeLiveRoom() async {
    _isLiveMinimized = true;

    _showMiniLiveBubble();

    if (mounted) {
      Navigator.of(context).pop();
    }

    Fluttertoast.showToast(
      msg: 'Live minimized',
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  Future<void> _exitLiveRoomNow() async {
    if (_isLiveExiting) return;

    _isLiveExiting = true;
    _isLiveMinimized = false;

    try {
      _miniLiveOverlay?.remove();
      _miniLiveOverlay = null;

      /// Local cleanup first. Duplicate leaveChannel ignored.
      try {
        await _agoraService.engine?.leaveChannel();
      } catch (e) {
        print('⚠️ leaveChannel ignored: $e');
      }

      liveController.isBroadcaster.value = false;
      liveController.stopPingUpdate();
      liveController.stopLivePresenceHeartbeat();
      await _markAudioLiveOfflineForExplicitExit();

      if (widget.isBroadcaster) {
        await liveController.stopLiveMusic(rtcEngine: _agoraService.engine);
        await liveController.stopYoutube();

        /// tryToRemoveLivestream already navigates to /Endlive in your app.
        /// Do NOT Navigator.pop() after this, otherwise Navigator history empty crash happens.
        await liveController.tryToRemoveLivestream(
          streamId: streamInfo['id'],
        );
      } else {
        await _leaveAudienceRoomAndSeat(navigateBack: true);
      }
    } catch (e) {
      print('❌ Exit live error: $e');
      Fluttertoast.showToast(msg: 'Exit failed');
    } finally {
      /// Keep true for this frame because controller may be removing route now.
      Future.delayed(const Duration(milliseconds: 700), () {
        _isLiveExiting = false;
      });
    }
  }

  /// Mini bubble: bottom-er upor choto profile + close.
  /// Drag/drop kore user jekhane khushi sorate parbe.
  /// Profile click korle abar audio live room open hobe.
  void _showMiniLiveBubble() {
    _miniLiveOverlay?.remove();
    _miniLiveOverlay = null;

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    if (_miniBubbleOffset == Offset.zero) {
      _miniBubbleOffset = Offset(
        screenSize.width - 88,
        screenSize.height - 170,
      );
    }

    final user = broadcasterData['user'] is Map ? broadcasterData['user'] : {};
    final profile = ImageHelper.getImageUrl('${user['profile_image'] ?? ''}');

    _miniLiveOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: _miniBubbleOffset.dx,
          top: _miniBubbleOffset.dy,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onPanStart: (_) {
                    _miniBubbleDragging = true;
                  },
                  onPanUpdate: (details) {
                    final maxX = MediaQuery.of(context).size.width - 76;
                    final maxY = MediaQuery.of(context).size.height - 130;

                    _miniBubbleOffset = Offset(
                      (_miniBubbleOffset.dx + details.delta.dx)
                          .clamp(8.0, maxX),
                      (_miniBubbleOffset.dy + details.delta.dy)
                          .clamp(70.0, maxY),
                    );

                    _miniLiveOverlay?.markNeedsBuild();
                  },
                  onPanEnd: (_) {
                    Future.delayed(const Duration(milliseconds: 90), () {
                      _miniBubbleDragging = false;
                    });
                  },
                  onTap: () {
                    if (_miniBubbleDragging) return;

                    _miniLiveOverlay?.remove();
                    _miniLiveOverlay = null;

                    Get.to(
                          () => AudioLiveView(
                        channelName: widget.channelName,
                        isBroadcaster: widget.isBroadcaster,
                        token: widget.token,
                        seatCount: widget.seatCount,
                        roomLayout: widget.roomLayout,
                        roomTheme: widget.roomTheme,
                        roomBackground: widget.roomBackground,
                      ),
                      arguments: streamData,
                      transition: Transition.rightToLeft,
                    );
                  },
                  child: Container(
                    height: 62,
                    width: 62,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffff6dc8),
                          Color(0xff7b35f2),
                          Color(0xff35d4ff),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profile,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          color: Colors.white,
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),

                /// Mini close button => live end/leave.
                Positioned(
                  right: -5,
                  top: -5,
                  child: GestureDetector(
                    onTap: () async {
                      _miniLiveOverlay?.remove();
                      _miniLiveOverlay = null;
                      await _exitLiveRoomNow();
                    },
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .18),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    height: 18,
                    width: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xff7BD55A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_miniLiveOverlay!);
  }

  void _closeCurrentSheetSafely() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  void _showLiveMinimizeExitPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: kHeight * 0.26,
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: kWeight * 0.04,
              vertical: kHeight * 0.018,
            ),
            decoration: const BoxDecoration(
              color: Color(0xfff7f7f7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                SizedBox(height: kHeight * 0.018),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _liveControlButton(
                      title: 'Minimize',
                      icon: Icons.open_in_full_rounded,
                      bg: const Color(0xffefe7ff),
                      iconColor: const Color(0xff7B35F2),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _minimizeLiveRoom();
                      },
                    ),
                    SizedBox(width: kWeight * 0.06),
                    _liveControlButton(
                      title: 'Exit',
                      icon: Icons.exit_to_app_rounded,
                      bg: const Color(0xffffe8e8),
                      iconColor: const Color(0xffff3b30),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();

                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('End Live'),
                            content: Text(
                              widget.isBroadcaster
                                  ? 'Are you sure you want to end this live?'
                                  : 'Are you sure you want to leave this live?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: const Text(
                                  'Exit',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (ok == true) {
                          await _exitLiveRoomNow();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _liveControlButton({
    required String title,
    required IconData icon,
    required Color bg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: kHeight * 0.055,
            width: kHeight * 0.055,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: iconColor.withValues(alpha: .15)),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: kHeight * 0.025,
            ),
          ),
          SizedBox(height: kHeight * 0.006),
          Text(
            title,
            style: GoogleFonts.roboto(
              color: iconColor,
              fontSize: kHeight * 0.011,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  //for live stream end
  @override
  Widget build(BuildContext context) {
    String fullName = broadcasterData['user']['name'];

    String shortName;

    List parts = fullName.split(' ');

    if (parts.length > 1) {
      // প্রথম অংশ (emoji + নাম)
      shortName = parts[0] + '..';
    } else {
      shortName = fullName;
    }
    // ✅ KEEP SYSTEM UI: Keep bottom navigation visible, UI starts above it
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Get.put(MomentsController());
    return WillPopScope(
      onWillPop: () async {
        final bool? exitLive = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              widget.isBroadcaster ? "End Live" : "Leave Live",
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              widget.isBroadcaster
                  ? "Are you sure you want to end this live?"
                  : "Are you sure you want to leave this live?",
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  "No",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  "Yes",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        );

        if (exitLive == true) {
          await _exitLiveRoomNow();
        }

        /// Navigation manually handle kora hocche.
        /// true return korle system route pop kore Navigator history empty crash dite pare.
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xffa19597),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: true,
          child: Obx(() {
            return Container(
              decoration: _roomDecoration,
              child: Stack(
                children: [
                  Positioned(
                    top: kHeight * 0.08,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Obx(() {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            // -------------------- Receive   coin ---------------
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Get.to(Allrank(),
                                              transition:
                                              Transition.rightToLeft);
                                        },
                                        child: TaskLiveProfile(
                                          text: _formatCoins(_currentRoomReceivedCoins()),
                                          seccondtext: 'Receive : ',
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          // Get.to(RankingView(),
                                          //     transition: Transition.rightToLeft);
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(
                                              right: kWeight * 0.04),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: kAppColor.withValues(alpha: 0.8),
                                            borderRadius:
                                            BorderRadius.circular(15),
                                            border: Border.all(
                                                color: Colors.white, width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Current:',
                                                style: GoogleFonts.roboto(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: kHeight * 0.012),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                _formatCoins(_currentRoomReceivedCoins()),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: kHeight * 0.014,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: kHeight * 0.012,
                                  ),
                                  broadcasterData['user']['id'] ==
                                      authController
                                          .userProfile.value.user!.id
                                      ? Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: kWeight * 0.03,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(10),
                                      color:
                                      Colors.black.withValues(alpha: 0.2),
                                    ),
                                    child: Obx(
                                          () => Castontext(
                                        fontSize: kHeight * 0.015,
                                        textColor: liveController
                                            .isLive.value
                                            ? const Color(
                                            0xff00ff00) // Live active = green
                                            : const Color(
                                            0xff808080), // Inactive = gray
                                        text:
                                        liveController.formattedTime,
                                      ),
                                    ),
                                  )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: kHeight * 0.02,
                            ),

                            ///---------------------------- YouTube + Audio set Section -----------------
                            _liveYoutubePlayerSection(),
                            SizedBox(height: _isYoutubeActiveForSeatLayout ? kHeight * 0.006 : 0),
                            getAudioBroadcaster(),

                            // // live view container end
                          ],
                        ),
                      );
                    }),
                  ),

                  ///--------------------------- Audio live creator --------
                  // Positioned(
                  //   top: kHeight * 0.074,
                  //   left: 0,
                  //   right: 0,
                  //   child: Row(
                  //     spacing: kWeight * 0.1,
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       Column(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           SizedBox(
                  //             height: kHeight * 0.065,
                  //             width: kHeight * 0.065,
                  //             child: Stack(
                  //               alignment: Alignment.center,
                  //               children: [
                  //                 // ---------------- PROFILE IMAGE ----------------
                  //                 InkWell(
                  //                   onTap: () {
                  //                     if (websocketController
                  //                         .liveCallList.isNotEmpty) {
                  //                       homeController.liveVisitProfile(
                  //                           userId:
                  //                           '${broadcasterData['user']['id']}',
                  //                           seatData: websocketController
                  //                               .liveCallList[0]);
                  //                     }
                  //                   },
                  //                   child: Container(
                  //                     height: Get.height * 0.055,
                  //                     width: Get.height * 0.055,
                  //                     decoration: const BoxDecoration(
                  //                       shape: BoxShape.circle,
                  //                     ),
                  //                     child: ClipRRect(
                  //                       borderRadius:
                  //                       BorderRadius.circular(100),
                  //                       child: CachedNetworkImage(
                  //                         fit: BoxFit.cover,
                  //                         imageUrl: ImageHelper.getImageUrl(
                  //                             '${broadcasterData['user']['profile_image']}'),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //
                  //                 // ---------------- AGENCY FRAME (if agencyId > 0) ----------------
                  //                 // if (data['user']['0'] > 0)
                  //                 //   SVGAEasyPlayer(
                  //                 //     assetsName:
                  //                 //         'assets/svga/Frame/Agency frame.svga',
                  //                 //     fit: BoxFit.cover,
                  //                 //   )
                  //
                  //                 // ---------------- NORMAL FRAME (if no agency frame) --------------
                  //                 if (broadcasterData['user']
                  //                 ['asset_purchase_history'] !=
                  //                     null &&
                  //                     broadcasterData['user']
                  //                     ['asset_purchase_history']
                  //                     ['asset'] !=
                  //                         null &&
                  //                     broadcasterData['user']
                  //                     ['asset_purchase_history']
                  //                     ['asset']['asset'] !=
                  //                         null)
                  //                 // Check if the asset path ends with .svga
                  //                   (broadcasterData['user']
                  //                   ['asset_purchase_history']
                  //                   ['asset']['asset']
                  //                       .toString()
                  //                       .endsWith('.svga'))
                  //                       ? SizedBox(
                  //                     height: kHeight * 0.08,
                  //                     width: kHeight * 0.08,
                  //                     child: SVGAEasyPlayer(
                  //                       resUrl:
                  //                       '$kDomainUrl/${broadcasterData['user']['asset_purchase_history']['asset']['asset']}',
                  //                       fit: BoxFit.cover,
                  //                     ),
                  //                   )
                  //                       : CachedNetworkImage(
                  //                     imageUrl:
                  //                     "$kDomainUrl/${broadcasterData['user']['asset_purchase_history']['asset']['asset']}",
                  //                     height: kHeight * 0.12,
                  //                     width: kHeight * 0.12,
                  //                     fit: BoxFit.cover,
                  //                     placeholder: (context, url) =>
                  //                         Container(
                  //                           height: kHeight * 0.06,
                  //                           width: kHeight * 0.06,
                  //                           decoration: BoxDecoration(
                  //                             color:
                  //                             kAppColor.withOpacity(.02),
                  //                             borderRadius:
                  //                             BorderRadius.circular(12),
                  //                           ),
                  //                         ),
                  //                     errorWidget:
                  //                         (context, url, error) =>
                  //                         Container(
                  //                           height: kHeight * 0.12,
                  //                           width: kHeight * 0.12,
                  //                           decoration: BoxDecoration(
                  //                             color: Colors.transparent,
                  //                             borderRadius:
                  //                             BorderRadius.circular(12),
                  //                           ),
                  //                           child: Icon(
                  //                             Icons.broken_image,
                  //                             size: 40,
                  //                             color:
                  //                             kAppColor.withOpacity(.2),
                  //                           ),
                  //                         ),
                  //                   )
                  //
                  //                 // ---------------- NOTHING (no frame) ----------------
                  //                 else
                  //                   SizedBox(
                  //                     height: kHeight * 0.03,
                  //                     width: kHeight * 0.03,
                  //                   ),
                  //               ],
                  //             ),
                  //           ),
                  //           const SizedBox(height: 0),
                  //           Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Text(
                  //                 broadcasterData['user']['name'].length > 3
                  //                     ? broadcasterData['user']['name']
                  //                     .substring(0, 3) +
                  //                     '..'
                  //                     : broadcasterData['user']['name'],
                  //                 style: TextStyle(
                  //                   color: Colors.white,
                  //                   fontSize: kHeight * 0.01,
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 0),
                  //               Row(
                  //                 mainAxisAlignment: MainAxisAlignment.center,
                  //                 children: [
                  //                   Padding(
                  //                     padding: const EdgeInsets.only(
                  //                       left: 3.0,
                  //                       right: 3,
                  //                     ),
                  //                     child: Row(
                  //                       mainAxisAlignment:
                  //                       MainAxisAlignment.spaceBetween,
                  //                       children: [
                  //                         Image.asset(
                  //                           'assets/images/diamond-removebg-preview.png',
                  //                           height: kHeight * 0.016,
                  //                           width: kHeight * 0.014,
                  //                         ),
                  //                         SizedBox(
                  //                           width: 4,
                  //                         ),
                  //                         Text(
                  //                               () {
                  //                             if (websocketController
                  //                                 .liveCallList.isEmpty) {
                  //                               return '0';
                  //                             }
                  //                             final coins = int.tryParse(
                  //                                 websocketController
                  //                                     .liveCallList[0]
                  //                                 ['earn_coins']
                  //                                     .toString()) ??
                  //                                 0;
                  //
                  //                             if (coins >= 1000000) {
                  //                               return "${(coins / 1000000).toStringAsFixed(1)}M";
                  //                             } else if (coins >= 1000) {
                  //                               return "${(coins / 1000).toStringAsFixed(1)}K";
                  //                             } else {
                  //                               return coins.toString();
                  //                             }
                  //                           }(),
                  //                           style: GoogleFonts.roboto(
                  //                             fontSize: kHeight * 0.012,
                  //                             color: Colors.white,
                  //                             fontWeight: FontWeight.w700,
                  //                           ),
                  //                         ),
                  //                       ],
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //       //SVIP section
                  //       Column(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Container(
                  //             height: kHeight * 0.05,
                  //             width: kHeight * 0.05,
                  //             decoration: const BoxDecoration(
                  //               color: Colors.black26,
                  //               shape: BoxShape.circle,
                  //             ),
                  //             child: ClipRRect(
                  //               borderRadius: BorderRadius.circular(30.0),
                  //               child: Image.asset(
                  //                 'assets/audio_live/360_F_560275613_OIx4JnQhuNV1wtXavYZZXKi38hrTXuwW-removebg-preview.png',
                  //                 width: kHeight * 0.042,
                  //                 height: kHeight * 0.042,
                  //                 fit: BoxFit.cover,
                  //               ),
                  //             ),
                  //           ),
                  //           const SizedBox(height: 3),
                  //           Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Text(
                  //                 'SVIP',
                  //                 style: TextStyle(
                  //                   color: Colors.white,
                  //                   fontSize: kHeight * 0.01,
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 0),
                  //               Row(
                  //                 mainAxisAlignment: MainAxisAlignment.center,
                  //                 children: [
                  //                   Padding(
                  //                     padding: const EdgeInsets.only(
                  //                       left: 3.0,
                  //                       right: 3,
                  //                     ),
                  //                     child: Row(
                  //                       mainAxisAlignment:
                  //                       MainAxisAlignment.spaceBetween,
                  //                       children: [
                  //                         Image.asset(
                  //                           'assets/images/diamond-removebg-preview.png',
                  //                           height: kHeight * 0.014,
                  //                           width: kHeight * 0.014,
                  //                         ),
                  //                         Text(
                  //                           " 0",
                  //                           style: TextStyle(
                  //                             fontWeight: FontWeight.bold,
                  //                             fontSize: kHeight * 0.012,
                  //                             color: Colors.white,
                  //                           ),
                  //                         ),
                  //                       ],
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       )
                  //     ],
                  //   ),
                  // ),

                  Column(
                    children: [
                      //Live view Part one start
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            //fast row start
                            Padding(
                              padding: EdgeInsets.only(
                                  left: 3, top: kHeight * 0.015),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  /// ------------------- Profile Section Audio Live --------------
                                  Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Main Container (Background + Info + Follow Button)
                                          Container(
                                            padding: EdgeInsets.only(
                                                right: Get.width * 0.015),
                                            margin: EdgeInsets.only(
                                                left: Get.width * 0.02),
                                            // left gap profile এর জন্য
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(25),
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.2),
                                              color: const Color(0x47381b1b),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                    width: Get.width *
                                                        0.085), // profile এর জায়গা
                                                Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      broadcasterData['user']
                                                      ['name']
                                                          .length >
                                                          5
                                                          ? broadcasterData[
                                                      'user']
                                                      ['name']
                                                          .substring(
                                                          0, 5) +
                                                          '..'
                                                          : broadcasterData[
                                                      'user']['name'],
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize:
                                                        kHeight * 0.01,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Uid : ${broadcasterData['user']['user_id']}',
                                                      style:
                                                      GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: (Get.height *
                                                            0.01)
                                                            .clamp(9.0, 14.0),
                                                        fontWeight:
                                                        FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    width: Get.width * 0.015),
                                                Obx(() {
                                                  if (broadcasterData['user']
                                                  ?['id'] ==
                                                      authController.userProfile
                                                          .value.user?.id) {
                                                    return const SizedBox();
                                                  }

                                                  return AnimatedSwitcher(
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    child:
                                                    momentsController
                                                        .isFollowing1
                                                        .value
                                                        ? Container()
                                                        : InkWell(
                                                      key: const ValueKey(
                                                          'follow'),
                                                      onTap: () {
                                                        momentsController
                                                            .followCreate(
                                                          userId:
                                                          '${broadcasterData['user']?['id']}',
                                                        );
                                                      },
                                                      child:
                                                      Container(
                                                        padding:
                                                        EdgeInsets
                                                            .symmetric(
                                                          vertical:
                                                          Get.height *
                                                              0.007,
                                                          horizontal:
                                                          Get.width *
                                                              0.03,
                                                        ),
                                                        decoration:
                                                        BoxDecoration(
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                          gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(
                                                                  0xff8A4CF7),
                                                              Color(
                                                                  0xffB460F0),
                                                            ],
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Follow',
                                                          style:
                                                          GoogleFonts
                                                              .lato(
                                                            fontWeight:
                                                            FontWeight
                                                                .w600,
                                                            fontSize: (Get.height *
                                                                0.008)
                                                                .clamp(
                                                                9.0,
                                                                14.0),
                                                            color: Colors
                                                                .white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                })
                                              ],
                                            ),
                                          ),

                                          // Profile + Fame Overlay
                                          Positioned(
                                            left: -kWeight * 0.06,
                                            top: -kHeight * 0.035,
                                            child: GestureDetector(
                                              onTap: () {
                                                if (websocketController
                                                    .liveCallList.isNotEmpty) {
                                                  homeController.liveVisitProfile(
                                                      userId:
                                                      '${broadcasterData['user']['id']}',
                                                      seatData:
                                                      websocketController
                                                          .liveCallList[0]);
                                                }
                                              },
                                              child: Obx(() {
                                                double size =
                                                    Get.height * 0.055;
                                                final user =
                                                broadcasterData['user'];
                                                final frameData = user[
                                                'asset_purchase_history'];
                                                print('image url $frameData');
                                                final profileImage =
                                                    authController
                                                        .userProfile
                                                        .value
                                                        .user
                                                        ?.profileImage;

                                                // Safe convert
                                                final agencyIdRaw =
                                                user['agencyId'];
                                                final int agencyId =
                                                    int.tryParse(agencyIdRaw
                                                        ?.toString() ??
                                                        '0') ??
                                                        0;

                                                return SizedBox(
                                                  height: kHeight * 0.1,
                                                  width: kHeight * 0.1,
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      // ---------------- PROFILE IMAGE ----------------
                                                      ClipOval(
                                                        child:
                                                        CachedNetworkImage(
                                                          imageUrl: ImageHelper
                                                              .getImageUrl(
                                                              "${user['profile_image']}"),
                                                          fit: BoxFit.cover,
                                                          height: size * 0.7,
                                                          width: size * 0.7,
                                                        ),
                                                      ),

                                                      // ---------------- AGENCY FRAME (if agencyId > 0) ----------------
                                                      if (agencyId > 0)
                                                        SVGAEasyPlayer(
                                                          assetsName:
                                                          'assets/svga/Frame/Agency frame.svga',
                                                          fit: BoxFit.cover,
                                                        )

                                                      // ---------------- NORMAL FRAME (if no agency frame) --------------
                                                      else if (frameData !=
                                                          null &&
                                                          frameData['asset'] !=
                                                              null &&
                                                          frameData['asset']
                                                          ['asset'] !=
                                                              null)
                                                      // Check if the asset path ends with .svga
                                                        (frameData['asset']
                                                        ['asset']
                                                            .toString()
                                                            .endsWith(
                                                            '.svga'))
                                                            ? SizedBox(
                                                          height:
                                                          kHeight *
                                                              0.048,
                                                          width: kHeight *
                                                              0.048,
                                                          child:
                                                          SVGAEasyPlayer(
                                                            resUrl:
                                                            '$kDomainUrl/${frameData['asset']['asset']}',
                                                            fit: BoxFit
                                                                .cover,
                                                          ),
                                                        )
                                                            : CachedNetworkImage(
                                                          imageUrl:
                                                          "$kDomainUrl/${frameData['asset']['asset']}",
                                                          height:
                                                          kHeight *
                                                              0.048,
                                                          width: kHeight *
                                                              0.048,
                                                          fit: BoxFit
                                                              .cover,
                                                          placeholder:
                                                              (context,
                                                              url) =>
                                                              Container(
                                                                height:
                                                                kHeight *
                                                                    0.12,
                                                                width:
                                                                kHeight *
                                                                    0.12,
                                                                decoration:
                                                                BoxDecoration(
                                                                  color: kAppColor
                                                                      .withValues(
                                                                      alpha: .02),
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                      12),
                                                                ),
                                                              ),
                                                          errorWidget: (context,
                                                              url,
                                                              error) =>
                                                              Container(
                                                                height:
                                                                kHeight *
                                                                    0.12,
                                                                width:
                                                                kHeight *
                                                                    0.12,
                                                                decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .transparent,
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                      12),
                                                                ),
                                                                child: Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  size: 40,
                                                                  color: kAppColor
                                                                      .withValues(
                                                                      alpha: .2),
                                                                ),
                                                              ),
                                                        )

                                                      // ---------------- NOTHING (no frame) ----------------
                                                      else
                                                        SizedBox(
                                                          height:
                                                          kHeight * 0.03,
                                                          width: kHeight * 0.03,
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  ///------------------------------ audio live Viewer List show ----------------
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      //viewers list here
                                      SizedBox(
                                        width: Get.width * 0.3,
                                        height: Get.height * 0.04,
                                        child: Obx(() {
                                          print(
                                              'Live viewer list: ${livestreamController.liveViewerList.length}');
                                          dynamic getViewerId(dynamic viewer) {
                                            if (viewer is! Map) return null;
                                            return viewer['user'] is Map
                                                ? viewer['user']['id']
                                                : (viewer['viewer_id'] ??
                                                viewer['user_id'] ??
                                                viewer['caller_id'] ??
                                                viewer['id']);
                                          }

                                          final broadcasterUserId =
                                          broadcasterData['user'] is Map
                                              ? broadcasterData['user']['id']
                                              : (broadcasterData['user_id'] ??
                                              broadcasterData['id']);

                                          // Filter list safely; viewer['user'] may be null for late join events.
                                          final filteredList = livestreamController.liveViewerList.where((viewer) {
                                            final viewerId = getViewerId(viewer);
                                            if (viewerId == null) return false;
                                            if (broadcasterUserId == null) return true;
                                            return viewerId.toString() != broadcasterUserId.toString();
                                          }).toList();

                                          if (filteredList.isEmpty) {
                                            return const SizedBox(); // কিছু না দেখানোর জন্য (empty state)
                                          }

                                          return ListView.builder(
                                            padding: EdgeInsets.zero,
                                            scrollDirection: Axis.horizontal,
                                            itemCount: filteredList.length,
                                            itemBuilder: (context, index) {
                                              final data = filteredList[index];
                                              final userId = data is Map
                                                  ? (data['user'] is Map
                                                  ? data['user']['id']
                                                  : (data['viewer_id'] ??
                                                  data['user_id'] ??
                                                  data['caller_id'] ??
                                                  data['id']))
                                                  : index;
                                              return LiveProfile(
                                                key: ValueKey('live_profile_${userId ?? index}'),
                                                data: data,
                                              );
                                            },
                                          );
                                        }),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              /// *********** All Viewer List Bottom sheet ***********
                                              final filteredList =
                                              livestreamController
                                                  .liveViewerList
                                                  .where((viewer) =>
                                              viewer['user']
                                              ['id'] !=
                                                  broadcasterData[
                                                  'user']['id'])
                                                  .toList();

                                              Get.bottomSheet(
                                                Container(
                                                  height: kHeight * 0.6,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                    const BorderRadius
                                                        .vertical(
                                                        top:
                                                        Radius.circular(
                                                            20)),
                                                    color: Colors.white,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                          height:
                                                          kHeight * 0.01),
                                                      Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                            horizontal:
                                                            kWeight *
                                                                0.02),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                          children: [
                                                            Center(
                                                              child: Castontext(
                                                                fontSize:
                                                                kHeight *
                                                                    0.023,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                                textColor: Colors
                                                                    .black
                                                                    .withValues(
                                                                    alpha: .7),
                                                                text:
                                                                'All Viewer List',
                                                              ),
                                                            ),
                                                            IconButton(
                                                              style: IconButton
                                                                  .styleFrom(
                                                                backgroundColor:
                                                                Colors.grey[
                                                                100],
                                                                padding:
                                                                const EdgeInsets
                                                                    .all(4),
                                                                minimumSize:
                                                                const Size(
                                                                    28, 28),
                                                              ),
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              icon: Icon(
                                                                  Icons.close,
                                                                  color:
                                                                  kAppColor,
                                                                  size: 18),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          height:
                                                          kHeight * 0.004),

                                                      /// 🔹 যদি Viewer না থাকে, তাহলে Center করে Empty Message দেখাও
                                                      Expanded(
                                                        child: filteredList
                                                            .isEmpty
                                                            ? Center(
                                                          child: Text(
                                                            'No viewers yet 👀',
                                                            style:
                                                            GoogleFonts
                                                                .roboto(
                                                              fontSize:
                                                              kHeight *
                                                                  0.016,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w400,
                                                              color: Colors
                                                                  .grey[
                                                              600],
                                                            ),
                                                          ),
                                                        )
                                                            : LiveViewersList(
                                                          viewerList:
                                                          filteredList,
                                                          isBroadcaster:
                                                          widget
                                                              .isBroadcaster,
                                                          onKickUser:
                                                              (userId) {
                                                            livestreamController
                                                                .kickOutUser(
                                                                userId);
                                                          },
                                                          isFromPk: false,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                isScrollControlled: true,
                                              );
                                            },
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                  left: Get.width * 0.01),
                                              child: ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(100),
                                                child: Container(
                                                  height: Get.height * 0.035,
                                                  width: Get.height * 0.035,
                                                  decoration: BoxDecoration(
                                                    color: kAppColor
                                                        .withValues(alpha: .6),
                                                  ),
                                                  child: Center(
                                                    child: Obx(() {
                                                      dynamic getViewerId(dynamic viewer) {
                                                        if (viewer is! Map) return null;
                                                        return viewer['user'] is Map
                                                            ? viewer['user']['id']
                                                            : (viewer['viewer_id'] ??
                                                            viewer['user_id'] ??
                                                            viewer['caller_id'] ??
                                                            viewer['id']);
                                                      }

                                                      final broadcasterUserId =
                                                      broadcasterData['user'] is Map
                                                          ? broadcasterData['user']['id']
                                                          : (broadcasterData['user_id'] ??
                                                          broadcasterData['id']);

                                                      final filteredCount =
                                                          livestreamController.liveViewerList.where((viewer) {
                                                            final viewerId = getViewerId(viewer);
                                                            if (viewerId == null) return false;
                                                            if (broadcasterUserId == null) return true;
                                                            return viewerId.toString() !=
                                                                broadcasterUserId.toString();
                                                          }).length;

                                                      return Text(
                                                        '$filteredCount+',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                          FontWeight.w500,
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Total gift count display

                                          IconButton(
                                            onPressed: _showLiveMinimizeExitPanel,
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ///live Comment
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 9,
                          ),
                          child: Row(
                            children: [
                              LiveCommentsSection(
                                broadcasterData: broadcasterData,
                                streamType: 'audio',
                              ),
                              ////container  text end
                              SizedBox(
                                width: kWeight * 0.06,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: kHeight * 0.055,
                      ),
                      //Live view Part 2 end
                    ],
                  ),

                  _liveMusicMiniPlayer(),

                  ///Entry Animation
                  Obx(
                        () => websocketController.newViewersJoinded.value
                        ? Positioned(
                      left: 10,
                      top: Get.height * 0.5,
                      child: SizedBox(
                        width: Get.width * 0.9,
                        child: EntryAnimation(
                          data:
                          websocketController.newJoinedUserData,
                        ),
                      ),
                    )
                        : Container(),
                  ),


                  Obx(
                        () => websocketController.isGiftAnimationShowing.value
                        ? Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
                        child: GiftAnimationWidget(
                          giftData: websocketController.giftsData,
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                  /// Live Imogi animation overlay.
                  /// action_type: imogi_sent ashlei sobar screen-e show hobe.
                  const Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: LiveImogiAnimationOverlay(),
                    ),
                  ),
                  _agoraService.engine == null
                      ? const Center(
                      child: CircularProgressIndicator()) // Show loading
                      : Container(),

                  ///Live view bottom part end
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _agoraService.engine != null
                        ? Container(
                      color:
                      Colors.transparent, // 🔹 Background color red
                      child: WriteCommentSection(
                        rtcEngine: _agoraService.engine!,
                        streamType: 'audio',
                        broadcasterData: broadcasterData,
                      ),
                    )
                        : Container(
                      color: Colors
                          .transparent, // Optional: blank red bar if engine null
                      height: 60, // adjust height if needed
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }





  Widget _liveYoutubePlayerSection() {
    return Obx(() {
      final String status = widget.isBroadcaster
          ? liveController.liveYoutubeStatus.value
          : websocketController.liveYoutubeStatus.value;
      final String videoId = widget.isBroadcaster
          ? liveController.liveYoutubeVideoId.value
          : websocketController.liveYoutubeVideoId.value;

      final bool visible = _isYoutubeActiveForSeatLayout;
      if (!visible) return const SizedBox.shrink();

      final controller = _ensureYoutubeController(
        videoId: videoId,
        status: status,
      );

      if (controller == null) return const SizedBox.shrink();

      final double playerHeight = liveSeatCount == 12
          ? kHeight * 0.255
          : kHeight * 0.265;

      return Container(
        width: double.infinity,
        height: playerHeight,
        margin: EdgeInsets.only(
          left: kWeight * 0.03,
          right: kWeight * 0.03,
          bottom: kHeight * 0.006,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: YoutubePlayer(
                controller: controller,
                aspectRatio: 16 / 9,
              ),
            ),

            /// Host control overlay. Audience only dekhe + shune.
            if (widget.isBroadcaster)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: _youtubeHostControlBar(status),
              ),
          ],
        ),
      );
    });
  }

  Widget _youtubeHostControlBar(String status) {
    final bool paused = status == 'paused';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _youtubeSmallButton(
            icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            onTap: () async {
              if (paused) {
                await liveController.resumeYoutube();
              } else {
                await liveController.pauseYoutube();
              }
            },
          ),
          _youtubeSmallButton(
            icon: Icons.link_rounded,
            onTap: _showYoutubeLinkDialog,
          ),
          _youtubeSmallButton(
            icon: Icons.close_rounded,
            color: Colors.redAccent,
            onTap: () async {
              await liveController.stopYoutube();
              _disposeYoutubeController();
            },
          ),
        ],
      ),
    );
  }

  Widget _youtubeSmallButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 28,
        width: 32,
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }

  void _showYoutubeLinkDialog() {
    final controller = TextEditingController(text: liveController.liveYoutubeUrl.value);

    Get.dialog(
      AlertDialog(
        title: const Text('Play YouTube'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste YouTube link here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isEmpty) return;
              Get.back();
              await liveController.playOrChangeYoutube(url);
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  Widget _liveMusicMiniPlayer() {
    return Obx(() {
      final String status = widget.isBroadcaster
          ? liveController.liveMusicStatus.value
          : websocketController.liveMusicStatus.value;
      final String name = widget.isBroadcaster
          ? liveController.liveMusicName.value
          : websocketController.liveMusicName.value;

      final bool visible = status != 'stopped' && name.trim().isNotEmpty;
      if (!visible) return const SizedBox.shrink();

      final screen = MediaQuery.of(context).size;

      if (_musicPanelOffset == Offset.zero) {
        _musicPanelOffset = Offset(
          screen.width - (kWeight * 0.36),
          kHeight * 0.018,
        );
      }

      final bool paused = status == 'paused';
      final String shortName = name.length > 16 ? '${name.substring(0, 16)}..' : name;

      return Positioned(
        left: _musicPanelOffset.dx,
        top: _musicPanelOffset.dy,
        child: GestureDetector(
          onPanStart: (_) {
            _musicPanelDragging = true;
          },
          onPanUpdate: (details) {
            final maxX = MediaQuery.of(context).size.width - (kWeight * 0.33);
            final maxY = MediaQuery.of(context).size.height - (kHeight * 0.17);

            _musicPanelOffset = Offset(
              (_musicPanelOffset.dx + details.delta.dx).clamp(8.0, maxX),
              (_musicPanelOffset.dy + details.delta.dy).clamp(8.0, maxY),
            );

            if (mounted) setState(() {});
          },
          onPanEnd: (_) {
            Future.delayed(const Duration(milliseconds: 80), () {
              _musicPanelDragging = false;
            });
          },
          child: Container(
            width: kWeight * 0.31,
            padding: EdgeInsets.symmetric(
              horizontal: kWeight * 0.014,
              vertical: kHeight * 0.006,
            ),
            decoration: BoxDecoration(
              color: const Color(0xff8794b8).withValues(alpha: .90),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: kHeight * 0.045,
                  width: kHeight * 0.045,
                  decoration: BoxDecoration(
                    color: const Color(0xff16E7FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                SizedBox(width: kWeight * 0.012),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isBroadcaster)
                            _musicIconButton(
                              icon: paused ? Icons.play_arrow : Icons.pause,
                              onTap: () async {
                                if (_musicPanelDragging) return;
                                if (paused) {
                                  await liveController.resumeLiveMusic(
                                    rtcEngine: _agoraService.engine,
                                  );
                                } else {
                                  await liveController.pauseLiveMusic(
                                    rtcEngine: _agoraService.engine,
                                  );
                                }
                              },
                            ),
                          if (widget.isBroadcaster)
                            _musicIconButton(
                              icon: Icons.skip_next,
                              onTap: () async {
                                if (_musicPanelDragging) return;
                                await liveController.pickAndPlayLiveMusic(
                                  rtcEngine: _agoraService.engine,
                                );
                              },
                            ),
                          const Icon(Icons.volume_up, color: Colors.black, size: 13),
                          if (widget.isBroadcaster)
                            _musicIconButton(
                              icon: Icons.power_settings_new,
                              color: Colors.red,
                              onTap: () async {
                                if (_musicPanelDragging) return;
                                await liveController.stopLiveMusic(
                                  rtcEngine: _agoraService.engine,
                                );
                              },
                            ),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: paused ? .45 : null,
                          minHeight: 4,
                          backgroundColor: Colors.black.withValues(alpha: .18),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff00e5ff)),
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              shortName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                color: Colors.black87,
                                fontSize: kHeight * 0.0085,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            paused ? 'Paused' : 'Playing',
                            style: GoogleFonts.roboto(
                              color: Colors.black87,
                              fontSize: kHeight * 0.0078,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _musicIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          icon,
          color: color,
          size: 14,
        ),
      ),
    );
  }

  Widget getAudioBroadcaster() {
    getActiveBroadcasterAudio(listActive: websocketController.liveCallList);

    final totalSeats = liveSeatCount;
    final layout = safeLiveLayout;
    final bool youtubeCompact = _isYoutubeActiveForSeatLayout;

    final seatSize = youtubeCompact
        ? (totalSeats == 9 ? kHeight * 0.043 : kHeight * 0.038)
        : totalSeats == 9
        ? kHeight * 0.055
        : totalSeats == 12
        ? kHeight * 0.050
        : totalSeats == 15
        ? kHeight * 0.045
        : kHeight * 0.042;

    final positions = _seatPositions(count: totalSeats, layout: layout);
    final areaHeight = youtubeCompact
        ? (totalSeats == 9 ? kHeight * 0.215 : kHeight * 0.225)
        : totalSeats == 9
        ? kHeight * 0.345
        : totalSeats == 12
        ? kHeight * 0.360
        : totalSeats == 15
        ? kHeight * 0.340
        : kHeight * 0.365;

    return SizedBox(
      height: youtubeCompact
          ? (totalSeats == 9 ? kHeight * 0.235 : kHeight * 0.245)
          : totalSeats == 20 ? kHeight * 0.390 : kHeight * 0.370,
      width: double.infinity,
      child: Padding(
        /// Same responsive left/right width for 9/12/15/20 seats.
        padding: EdgeInsets.symmetric(horizontal: kWeight * 0.020),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SizedBox(
            key: ValueKey('$totalSeats-$layout'),
            height: areaHeight,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(positions.length, (index) {
                    final point = positions[index];

                    /// First position is always the owner/broadcaster profile.
                    /// Other seats are audience seats, seat_no starts from 2.
                    final isOwnerSeat = index == 0;
                    final seatNo = index + 1;

                    /// Same slot for owner and audience.
                    /// This keeps owner profile top aligned with nearby seats.
                    final slotWidth = seatSize * 2.12;
                    final slotHeight = seatSize * 2.18;

                    final ownerVisualSize = kHeight * 0.055;

                    return Positioned(
                      left: (constraints.maxWidth * point.x) - slotWidth / 2,
                      top: (constraints.maxHeight * point.y) - slotHeight / 2,
                      child: SizedBox(
                        height: slotHeight,
                        width: slotWidth,
                        child: Center(
                          child: isOwnerSeat
                              ? _broadcasterLayoutProfile(ownerVisualSize)
                              : LiveViewCircle_container(
                            data: userData(seatNo: seatNo),
                            seatNo: seatNo,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _emojiMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  dynamic _emojiPickFirst(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty && value.toString() != 'null') {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic> _normalizeHostImogiPayload(dynamic rawItem) {
    Map<String, dynamic> map = _emojiMap(rawItem);

    final innerData = _emojiMap(map['data']);
    if (innerData.isNotEmpty &&
        (innerData['action_type'] != null ||
            innerData['sender'] != null ||
            innerData['imogi'] != null ||
            innerData['emoji'] != null)) {
      map = innerData;
    }

    final innerPayload = _emojiMap(map['payload']);
    if (innerPayload.isNotEmpty &&
        (innerPayload['action_type'] != null ||
            innerPayload['sender'] != null ||
            innerPayload['imogi'] != null ||
            innerPayload['emoji'] != null)) {
      map = innerPayload;
    }

    return map;
  }

  Map<String, dynamic>? _activeHostImogiForUser(dynamic rawUserId) {
    final userId = rawUserId?.toString() ?? '';
    if (userId.isEmpty || userId == 'null') return null;

    for (final rawItem in websocketController.liveImogiAnimations.reversed) {
      final map = _normalizeHostImogiPayload(rawItem);

      final sender = _emojiMap(map['sender']);
      final user = _emojiMap(map['user']);

      final senderId = _emojiPickFirst(sender, ['id', 'user_id', 'caller_id']) ??
          _emojiPickFirst(user, ['id', 'user_id', 'caller_id']) ??
          _emojiPickFirst(map, [
            'sender_id',
            'user_id',
            'caller_id',
            'senderId',
            'userId',
            'id',
          ]);

      if (senderId.toString() == userId) {
        return map;
      }
    }

    return null;
  }

  String _safeHostImogiImage(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'null' || raw == 'file:///') return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return ImageHelper.getImageUrl(raw);
  }

  Widget _hostImogiOverlay(dynamic rawUserId, double size) {
    return Obx(() {
      final item = _activeHostImogiForUser(rawUserId);
      if (item == null) return const SizedBox.shrink();

      final imogi = _emojiMap(item['imogi']);
      final emoji = _emojiMap(item['emoji']);
      final giftLike = _emojiMap(item['gift']);

      final image = _safeHostImogiImage(
        _emojiPickFirst(imogi, [
          'image',
          'icon',
          'imogi_image',
          'emoji_image',
          'show_image',
          'url',
          'file',
        ]) ??
            _emojiPickFirst(emoji, [
              'image',
              'icon',
              'imogi_image',
              'emoji_image',
              'show_image',
              'url',
              'file',
            ]) ??
            _emojiPickFirst(giftLike, [
              'image',
              'icon',
              'imogi_image',
              'emoji_image',
              'show_image',
              'url',
              'file',
            ]) ??
            _emojiPickFirst(item, [
              'image',
              'icon',
              'imogi_image',
              'emoji_image',
              'show_image',
              'url',
              'file',
            ]),
      );

      if (image.isEmpty) return const SizedBox.shrink();

      /// Host emoji audience seat emoji-r moto profile-er center-e show korbe.
      /// Age top-e chole jacchilo, tai Positioned.fill + Center use kora holo.
      return Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(item['event_id']?.toString() ??
                  item['timestamp']?.toString() ??
                  image),
              tween: Tween<double>(begin: .45, end: 1.0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    height: size * 0.62,
                    width: size * 0.62,
                    padding: EdgeInsets.all(size * 0.035),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: .14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .25),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _broadcasterLayoutProfile(double size) {
    final user = broadcasterData['user'];

    if (user == null || user is! Map) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white.withValues(alpha: .35),
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    }

    final profileImage = ImageHelper.getImageUrl('${user['profile_image'] ?? ''}');
    final frameData = user['asset_purchase_history'];
    final agencyId = int.tryParse(
      user['agencyId']?.toString() ??
          user['agency_id']?.toString() ??
          '0',
    ) ??
        0;

    final displayName = (user['name'] ?? 'Host').toString();
    final userType = (user['user_type'] ?? 'Host').toString();
    final coins = user['earned_coins'] ??
        user['earn_coins'] ??
        (websocketController.liveCallList.isNotEmpty
            ? websocketController.liveCallList[0]['earn_coins']
            : 0);

    return GestureDetector(
      onTap: () {
        if (websocketController.liveCallList.isNotEmpty) {
          homeController.liveVisitProfile(
            userId: '${user['id']}',
            seatData: websocketController.liveCallList[0],
          );
        }
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: size * 1.18,
              width: size * 1.18,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (_isUserSpeaking(user['id']) && !_isUserMuted(user['id']))
                    SpeakingWave(
                      size: size * 1.28,
                    ),

                  Container(
                    height: size * 1.02,
                    width: size * 1.02,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .55),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(size * 0.055),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profileImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white.withValues(alpha: .20),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: size * 0.45,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white.withValues(alpha: .20),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: size * 0.45,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (agencyId > 0)
                    SizedBox(
                      height: size * 1.32,
                      width: size * 1.32,
                      child: const SVGAEasyPlayer(
                        assetsName: 'assets/svga/Frame/Agency frame.svga',
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (frameData is Map &&
                      frameData['asset'] != null &&
                      frameData['asset']['asset'] != null)
                    frameData['asset']['asset'].toString().endsWith('.svga')
                        ? SizedBox(
                      height: size * 1.32,
                      width: size * 1.32,
                      child: SVGAEasyPlayer(
                        resUrl: '$kDomainUrl/${frameData['asset']['asset']}',
                        fit: BoxFit.cover,
                      ),
                    )
                        : CachedNetworkImage(
                      imageUrl: '$kDomainUrl/${frameData['asset']['asset']}',
                      height: size * 1.32,
                      width: size * 1.32,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                      const SizedBox.shrink(),
                    ),

                  Positioned(
                    bottom: -size * 0.02,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size * 0.13,
                        vertical: size * 0.025,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xff41E6A1), Color(0xff16A6FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .20),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        userType.isEmpty
                            ? 'Host'
                            : '${userType[0].toUpperCase()}${userType.substring(1)}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: (size * 0.16).clamp(7.5, 10.0),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),

                  /// Host emoji must stay on top of host profile image, exactly center.
                  /// Placed after profile image/frame so it is visible, not hidden behind avatar.
                  _hostImogiOverlay(user['id'], size),

                  if (_isUserMuted(user['id']))
                    Positioned(
                      right: -size * 0.08,
                      bottom: size * 0.02,
                      child: Container(
                        height: size * 0.34,
                        width: size * 0.34,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: .95),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: .8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .25),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mic_off,
                          color: Colors.white,
                          size: size * 0.19,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: size * 0.035),

            SizedBox(
              width: size * 1.75,
              child: Text(
                displayName.length > 10
                    ? '${displayName.substring(0, 10)}..'
                    : displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: .95),
                  fontSize: (size * 0.20).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: .45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: size * 0.055),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.16,
                vertical: size * 0.030,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/diamond-removebg-preview.png',
                    height: size * 0.19,
                  ),
                  SizedBox(width: size * 0.05),
                  Text(
                    formatNumber(coins),
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: (size * 0.16).clamp(7.5, 10.5),
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AudioSeatPoint> _seatPositions({
    required int count,
    required int layout,
  }) {
    /// ================= 9 SEAT LAYOUTS =================
    /// Default: top 1, below 4 + 4.
    if (count == 9 && layout == 0) {
      return const [
        _AudioSeatPoint(.50, .075),
        _AudioSeatPoint(.11, .51),
        _AudioSeatPoint(.37, .51),
        _AudioSeatPoint(.63, .51),
        _AudioSeatPoint(.89, .51),
        _AudioSeatPoint(.11, .82),
        _AudioSeatPoint(.37, .82),
        _AudioSeatPoint(.63, .82),
        _AudioSeatPoint(.89, .82),
      ];
    }

    /// 9 layout 2: first line 5, second line 4.
    if (count == 9 && layout == 1) {
      return const [
        _AudioSeatPoint(.14, .22),
        _AudioSeatPoint(.37, .22),
        _AudioSeatPoint(.54, .22),
        _AudioSeatPoint(.71, .22),
        _AudioSeatPoint(.90, .22),
        _AudioSeatPoint(.18, .60),
        _AudioSeatPoint(.40, .60),
        _AudioSeatPoint(.62, .60),
        _AudioSeatPoint(.84, .60),
      ];
    }

    /// 9 layout 3: left/right 3 + 3, bottom 2, middle 1.
    if (count == 9 && layout == 2) {
      return const [
        _AudioSeatPoint(.50, .34),
        _AudioSeatPoint(.10, .15),
        _AudioSeatPoint(.10, .40),
        _AudioSeatPoint(.10, .68),
        _AudioSeatPoint(.90, .15),
        _AudioSeatPoint(.90, .40),
        _AudioSeatPoint(.90, .68),
        _AudioSeatPoint(.34, .68),
        _AudioSeatPoint(.66, .68),
      ];
    }

    /// 9 layout 4: round.
    if (count == 9 && layout == 3) {
      return const [
        _AudioSeatPoint(.50, .46),
        _AudioSeatPoint(.50, .12),
        _AudioSeatPoint(.79, .24),
        _AudioSeatPoint(.93, .50),
        _AudioSeatPoint(.79, .78),
        _AudioSeatPoint(.50, .90),
        _AudioSeatPoint(.21, .78),
        _AudioSeatPoint(.07, .50),
        _AudioSeatPoint(.21, .24),
      ];
    }

    /// ================= 12 SEAT LAYOUTS =================
    /// 12 layout 1: top 1, then 6, then 5.
    if (count == 12 && layout == 0) {
      return const [
        _AudioSeatPoint(.50, .085),
        _AudioSeatPoint(.08, .46),
        _AudioSeatPoint(.245, .46),
        _AudioSeatPoint(.415, .46),
        _AudioSeatPoint(.585, .46),
        _AudioSeatPoint(.755, .46),
        _AudioSeatPoint(.92, .46),
        _AudioSeatPoint(.12, .76),
        _AudioSeatPoint(.31, .76),
        _AudioSeatPoint(.50, .76),
        _AudioSeatPoint(.69, .76),
        _AudioSeatPoint(.88, .76),
      ];
    }

    /// 12 layout 2: 6 + 6.
    if (count == 12 && layout == 1) {
      return const [
        _AudioSeatPoint(.10, .25),
        _AudioSeatPoint(.27, .25),
        _AudioSeatPoint(.44, .25),
        _AudioSeatPoint(.61, .25),
        _AudioSeatPoint(.78, .25),
        _AudioSeatPoint(.94, .25),
        _AudioSeatPoint(.07, .60),
        _AudioSeatPoint(.24, .60),
        _AudioSeatPoint(.41, .60),
        _AudioSeatPoint(.59, .60),
        _AudioSeatPoint(.76, .60),
        _AudioSeatPoint(.93, .60),
      ];
    }

    /// 12 layout 3: owner center + left/right 4 + 4 + bottom 3.
    /// Bottom 3 seat left/right column-er last seat-er maj borabor aligned.
    if (count == 12 && layout == 2) {
      return const [
        /// Owner / host profile center
        _AudioSeatPoint(.50, .48),

        /// Left side 4 seats, equal gap
        _AudioSeatPoint(.10, .14),
        _AudioSeatPoint(.10, .34),
        _AudioSeatPoint(.10, .54),
        _AudioSeatPoint(.10, .78),

        /// Right side 4 seats, equal gap
        _AudioSeatPoint(.90, .14),
        _AudioSeatPoint(.90, .34),
        _AudioSeatPoint(.90, .54),
        _AudioSeatPoint(.90, .78),

        /// Bottom 3 seats: same y as side last seats, equal width/gap
        _AudioSeatPoint(.28, .78),
        _AudioSeatPoint(.50, .78),
        _AudioSeatPoint(.72, .78),
      ];
    }

    /// 12 layout 4: round with 2 middle.
    if (count == 12 && layout == 3) {
      return const [
        /// 12 round layout: 9-seat style perfect circle.
        /// 2 center seats + 10 outer seats with equal distance/gap.
        _AudioSeatPoint(.40, .52),
        _AudioSeatPoint(.60, .52),

        _AudioSeatPoint(.50, .14),
        _AudioSeatPoint(.73, .22),
        _AudioSeatPoint(.88, .40),
        _AudioSeatPoint(.88, .64),
        _AudioSeatPoint(.73, .82),
        _AudioSeatPoint(.50, .90),
        _AudioSeatPoint(.27, .82),
        _AudioSeatPoint(.12, .64),
        _AudioSeatPoint(.12, .40),
        _AudioSeatPoint(.27, .22),
      ];
    }

    /// 12 layout 5 / default: top 2, then 5, then 5.
    if (count == 12 && layout == 4) {
      return const [
        _AudioSeatPoint(.34, .105),
        _AudioSeatPoint(.66, .105),
        _AudioSeatPoint(.10, .46),
        _AudioSeatPoint(.30, .46),
        _AudioSeatPoint(.50, .46),
        _AudioSeatPoint(.70, .46),
        _AudioSeatPoint(.90, .46),
        _AudioSeatPoint(.10, .76),
        _AudioSeatPoint(.30, .76),
        _AudioSeatPoint(.50, .76),
        _AudioSeatPoint(.70, .76),
        _AudioSeatPoint(.90, .76),
      ];
    }

    /// ================= 15 SEAT DEFAULT =================
    /// 3 rows, 5 seats per row. Same size, equal horizontal gap.
    if (count == 15) {
      return const [
        _AudioSeatPoint(.10, .14),
        _AudioSeatPoint(.30, .14),
        _AudioSeatPoint(.50, .14),
        _AudioSeatPoint(.70, .14),
        _AudioSeatPoint(.90, .14),

        _AudioSeatPoint(.10, .49),
        _AudioSeatPoint(.30, .49),
        _AudioSeatPoint(.50, .49),
        _AudioSeatPoint(.70, .49),
        _AudioSeatPoint(.90, .49),

        _AudioSeatPoint(.10, .84),
        _AudioSeatPoint(.30, .84),
        _AudioSeatPoint(.50, .84),
        _AudioSeatPoint(.70, .84),
        _AudioSeatPoint(.90, .84),
      ];
    }

    /// ================= 20 SEAT DEFAULT =================
    /// 4 rows, 5 seats per row. Same size, equal horizontal/vertical gap.
    if (count == 20) {
      return const [
        _AudioSeatPoint(.10, .10),
        _AudioSeatPoint(.30, .10),
        _AudioSeatPoint(.50, .10),
        _AudioSeatPoint(.70, .10),
        _AudioSeatPoint(.90, .10),

        _AudioSeatPoint(.10, .36),
        _AudioSeatPoint(.30, .36),
        _AudioSeatPoint(.50, .36),
        _AudioSeatPoint(.70, .36),
        _AudioSeatPoint(.90, .36),

        _AudioSeatPoint(.10, .62),
        _AudioSeatPoint(.30, .62),
        _AudioSeatPoint(.50, .62),
        _AudioSeatPoint(.70, .62),
        _AudioSeatPoint(.90, .62),

        _AudioSeatPoint(.10, .88),
        _AudioSeatPoint(.30, .88),
        _AudioSeatPoint(.50, .88),
        _AudioSeatPoint(.70, .88),
        _AudioSeatPoint(.90, .88),
      ];
    }

    return const [];
  }

  bool _asBoolLocked(dynamic raw) {
    return raw == true ||
        raw == 1 ||
        raw.toString() == '1' ||
        raw.toString().toLowerCase() == 'yes' ||
        raw.toString().toLowerCase() == 'locked' ||
        raw.toString().toLowerCase() == 'true';
  }

  Future<void> _loadInitialSeatLocks() async {
    try {
      final streamId = int.tryParse(streamInfo['id']?.toString() ?? '') ?? 0;
      if (streamId == 0) {
        print('⚠️ _loadInitialSeatLocks skipped: stream id missing');
        return;
      }

      final data = await liveController.getAvailableSeats(streamId);
      if (data == null) return;

      final Map<int, bool> locks = {};

      void addSeat(dynamic value, {bool locked = true}) {
        final seatNo = int.tryParse(value?.toString() ?? '') ?? 0;
        if (seatNo > 0) locks[seatNo] = locked;
      }

      void parseList(dynamic list) {
        if (list is! List) return;

        for (final item in list) {
          if (item is Map) {
            final seatNo = item['seat_no'] ??
                item['seatNo'] ??
                item['seat'] ??
                item['no'] ??
                item['number'];

            final rawLocked = item['is_locked'] ??
                item['locked'] ??
                item['lock'] ??
                item['status'];

            if (seatNo != null && _asBoolLocked(rawLocked)) {
              addSeat(seatNo);
            }
          } else {
            addSeat(item);
          }
        }
      }

      /// Supported backend keys.
      /// Best: locked_seats: [2, 5] or locked_seats: [{seat_no:2,is_locked:true}]
      parseList(data['locked_seats']);
      parseList(data['lockedSeats']);
      parseList(data['locked_seat_numbers']);
      parseList(data['lockedSeatNumbers']);
      parseList(data['locks']);

      /// If backend returns all seats with status/is_locked.
      parseList(data['seats']);
      parseList(data['data']);

      final bool hasAuthoritativeLockKey =
          (
              data.containsKey('locked_seats') ||
                  data.containsKey('lockedSeats') ||
                  data.containsKey('locked_seat_numbers') ||
                  data.containsKey('lockedSeatNumbers') ||
                  data.containsKey('locks')
          );

      if (hasAuthoritativeLockKey) {
        /// Server available-seats response is authoritative.
        /// Replace lock map instead of merging, otherwise old/fake locks like
        /// seat 1 remain and later hide/override the correct [4,8] locks.
        final oldLockKeys = websocketController.lockedSeatMap.keys
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();

        for (final seatNo in oldLockKeys) {
          websocketController.updateSeatLockStatus(
            seatNo: seatNo,
            isLocked: false,
            source: 'audio_initial_available_seats_replace_clear',
          );
        }

        locks.forEach((seatNo, locked) {
          websocketController.updateSeatLockStatus(
            seatNo: seatNo,
            isLocked: locked,
            source: 'audio_initial_available_seats',
          );
        });

        print('🔐 Initial locked seats REPLACED => ${locks.keys.toList()}');
      } else if (locks.isNotEmpty) {
        locks.forEach((seatNo, locked) {
          websocketController.updateSeatLockStatus(
            seatNo: seatNo,
            isLocked: locked,
            source: 'audio_initial_available_seats',
          );
        });

        print('🔐 Initial locked seats synced => ${locks.keys.toList()}');
      } else {
        /// Response has no trusted lock key. Do not clear current state.
        try {
          websocketController.syncSeatLocksFromAnyPayload(
            Map<String, dynamic>.from(data),
            allowUnlock: false,
            source: 'audio_available_seats_empty',
          );
        } catch (_) {}
        print(
            'ℹ️ No authoritative locked seats found; keeping lock map: ${websocketController.lockedSeatMap.keys.toList()}');
      }
    } catch (e) {
      print('❌ Initial seat lock sync failed: $e');
    }
  }

  void _syncSeatLocksFromCallList() {
    /// Do NOT read `is_locked` from liveCallList.
    /// Backend call objects often return is_locked=yes for occupied seats,
    /// which made a user's old seat look locked after they left.
    /// Seat lock state must come only from:
    /// 1) lockedSeatMap realtime `seat_lock_toggle`
    /// 2) _loadInitialSeatLocks() available-seats response.
    return;
  }

  Map userData({required int seatNo}) {
    _syncSeatLocksFromCallList();

    var result = websocketController.liveCallList.firstWhere(
          (item) {
        if (item is! Map) return false;
        final itemSeat = item['seat_no'] ?? item['seat'] ?? item['seat_number'];
        final bool sameSeat = itemSeat.toString() == seatNo.toString();

        final user = item['user'];
        final hasUser = user is Map && (user['id'] != null || user['name'] != null);
        final hasCallerId = item['caller_id'] != null || item['user_id'] != null;
        final status = (item['call_status'] ?? item['status'] ?? 'accepted')
            .toString()
            .toLowerCase();

        return sameSeat &&
            (hasUser || hasCallerId) &&
            status != 'left' &&
            status != 'rejected' &&
            status != 'canceled' &&
            status != 'cancelled';
      },
      orElse: () {
        return {};
      },
    );

    return result is Map ? result : {};
  }

  // Battery Optimization Methods
  void _initializeBatteryMonitoring() {
    // Start battery monitoring
    _batteryCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkBatteryLevel();
    });

    // Initial battery check
    _checkBatteryLevel();
  }

  Future<void> _checkBatteryLevel() async {
    try {
      final batteryLevel = await _batteryOptimizer.getCurrentBatteryLevel();
      final newPerformanceLevel =
      _batteryOptimizer.getPerformanceLevel(batteryLevel);

      if (newPerformanceLevel != _currentPerformanceLevel) {
        _currentPerformanceLevel = newPerformanceLevel;
        await _applyPerformanceOptimizations();
        _scheduleUIUpdate();

        // Show battery warning if needed
        if (batteryLevel < 30) {
          _showBatteryWarning(batteryLevel);
        }
      }
    } catch (e) {
      print('Error checking battery level: $e');
    }
  }

  Future<void> _applyPerformanceOptimizations() async {
    if (_agoraService.engine == null) return;

    final engine = _agoraService.engine!;
    final audioConfig =
    _batteryOptimizer.getOptimizedAudioConfig(_currentPerformanceLevel);

    try {
      // Apply audio optimizations
      await engine.setAudioProfile(
        profile: audioConfig['profile'] ??
            AudioProfileType.audioProfileSpeechStandard,
        scenario: audioConfig['scenario'] ??
            AudioScenarioType.audioScenarioGameStreaming,
      );

      // Update ping interval based on performance level
      final pingInterval =
      _batteryOptimizer.getOptimizedPingInterval(_currentPerformanceLevel);
      liveController.updatePingInterval(pingInterval);

      print(
          '🔋 Applied performance optimizations for level: $_currentPerformanceLevel');
    } catch (e) {
      print('Error applying performance optimizations: $e');
    }
  }

  void _scheduleUIUpdate() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showBatteryWarning(int batteryLevel) {
    String message;
    if (batteryLevel < 15) {
      message = "🔴 Critical battery! Maximum power saving enabled";
    } else if (batteryLevel < 30) {
      message = "⚠️ Low battery! Switching to power saving mode";
    } else {
      return;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }
}


class SpeakingWave extends StatefulWidget {
  final double size;

  const SpeakingWave({
    super.key,
    required this.size,
  });

  @override
  State<SpeakingWave> createState() => _SpeakingWaveState();
}

class _SpeakingWaveState extends State<SpeakingWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;


  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: .88, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacity = Tween<double>(begin: .85, end: .25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: widget.size,
              width: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: _opacity.value),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: _opacity.value * .45),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


String formatNumber(dynamic number) {
  int value = int.tryParse(number.toString()) ?? 0;

  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  } else {
    return value.toString();
  }
}
