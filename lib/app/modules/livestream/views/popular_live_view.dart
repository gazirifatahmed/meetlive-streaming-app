import 'dart:async';
import 'dart:ui';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/tasksLiveView.dart';
import '../../../services/agora_service.dart';
import '../../myprofile/views/ProfileConribution.dart';
import '../controllers/livestream_action_controller.dart';
import '../controllers/livestream_controller.dart';
import '../controllers/websocket_controller.dart';
import '../widgets/AnimatedProgressBar.dart';
import '../widgets/CustomPartyRoom.dart';
import '../widgets/LiveProfile_AppBar.dart';
import '../widgets/Live_view _imageCard.dart';
import '../widgets/entry_animation.dart';
import '../widgets/gifts_animation.dart';
import '../widgets/live_comments.dart';
import '../widgets/live_viewer_list.dart';
import '../widgets/pk_live_widgets.dart';
import '../widgets/red_packet_animation.dart';
import '../widgets/towVsTowPk.dart';
import '../widgets/write_comments.dart';

class PopularLiveView extends StatefulWidget {
  final String channelName;
  final bool isBroadcaster;
  final String token;

  const PopularLiveView({
    super.key,
    required this.channelName,
    required this.isBroadcaster,
    required this.token,
  });

  @override
  State<PopularLiveView> createState() => _PopularLiveViewState();
}

class _PopularLiveViewState extends State<PopularLiveView> {
  LivestreamController liveController = Get.find();
  LiveStreamActionController actionController = Get.put(
    LiveStreamActionController(),
  );
  WebsocketController websocketController = Get.put(WebsocketController());
  AnimatedProgressBarController animatedProgressBarController = Get.put(
    AnimatedProgressBarController(),
  );
  final AgoraService _agoraService = AgoraService();

  final streamData = Get.arguments;

  final streamInfo = {}.obs;
  final broadcasterData = {}.obs;
  String? _currentToken;
  String _lastSyncedPkChannel = '';
  bool _pkSyncScheduled = false;
  /// Agora speaking wave state.
  /// Backend chara Agora volume indication diye detect hobe ke kotha bolse.
  final Set<int> _speakingUserIds = <int>{};
  final Map<int, Timer> _speakingOffTimers = <int, Timer>{};
  static const int _speakingVolumeThreshold = 18;


  /// PK Agora channel state. Keeps old normal live safe and prevents repeated join.
  final RxSet<int> _pkRemoteUids = <int>{}.obs;
  String _activeAgoraChannel = '';
  String _lastPkJoinKey = '';
  bool _pkJoinInProgress = false;
  bool _normalReturnInProgress = false;
  bool _wasInPkChannel = false;

  /// Force Agora native video views to rebuild after leave/join channel.
  /// Without this, old disconnected SurfaceView can remain black in PK.
  int _pkVideoRenderVersion = 0;

  int _normalizeAgoraUid(int uid) {
    /// Agora local user-er jonno kichu case-e uid 0 aste pare.
    /// Tokhon current logged-in user id use korbo.
    if (uid == 0) {
      return authController.userProfile.value.user?.id?.toInt() ?? 0;
    }
    return uid;
  }


  /// PK remote video render helper.
  /// Backend/App sometimes uses host id directly (100448), and sometimes old host id
  /// gets mapped to Agora uid by adding 100000. This function keeps both safe.
  int _pkAgoraRenderUidFromHostId(int hostId) {
    if (hostId <= 0) return 0;

    // Already Agora-style uid, like 100448.
    if (hostId >= 100000) return hostId;

    // If Agora callback already gave this exact uid, use it.
    if (_pkRemoteUids.contains(hostId)) return hostId;

    final int mappedUid = 100000 + hostId;
    if (_pkRemoteUids.contains(mappedUid)) return mappedUid;

    // Token logs show PK UID as 100xxx, so fallback to mapped uid.
    return mappedUid;
  }

  /// Current logged-in user and PK host can be stored as different but equivalent
  /// ids, for example 448 vs 100448. This keeps local-host detection correct.
  bool _isSamePkHost({
    required int currentUid,
    required int hostId,
  }) {
    if (currentUid <= 0 || hostId <= 0) return false;
    if (currentUid == hostId) return true;

    if (currentUid >= 100000 && currentUid - 100000 == hostId) return true;
    if (hostId >= 100000 && hostId - 100000 == currentUid) return true;

    final int mappedCurrent = currentUid >= 100000 ? currentUid : currentUid + 100000;
    final int mappedHost = hostId >= 100000 ? hostId : hostId + 100000;
    return mappedCurrent == mappedHost;
  }

  /// Remote host online check for PK waiting overlay.
  /// Local host should be treated as online immediately.
  bool _isPkRemoteHostOnline(int hostId) {
    if (hostId <= 0) return false;

    final int currentUid = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (_isSamePkHost(currentUid: currentUid, hostId: hostId)) return true;

    if (_pkRemoteUids.contains(hostId)) return true;

    final int renderUid = _pkAgoraRenderUidFromHostId(hostId);
    if (renderUid > 0 && _pkRemoteUids.contains(renderUid)) return true;

    // Reverse mapping support just in case callback returns old uid.
    if (hostId >= 100000 && _pkRemoteUids.contains(hostId - 100000)) return true;
    if (hostId < 100000 && _pkRemoteUids.contains(hostId + 100000)) return true;

    return false;
  }

  bool _isUserSpeaking(dynamic userId) {
    final id = int.tryParse(userId?.toString() ?? '') ?? 0;
    return id != 0 && _speakingUserIds.contains(id);
  }

  bool _isCallMuted(dynamic call) {
    if (call is! Map) return false;

    return call['audio_on'] == 0 ||
        call['is_muted'] == true ||
        call['is_muted_by_host'] == true ||
        call['muted'] == true;
  }

  bool _isUserMuted(dynamic userId) {
    final id = int.tryParse(userId?.toString() ?? '') ?? 0;
    if (id == 0) return false;

    final currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (id == currentUserId && liveController.mute.value == true) {
      return true;
    }

    final index = websocketController.liveCallList.indexWhere((call) {
      final callerId = call['caller_id'];
      final uid = call['user']?['id'] ?? callerId;
      return uid.toString() == id.toString();
    });

    if (index == -1) return false;

    return _isCallMuted(websocketController.liveCallList[index]);
  }

  void _setSpeakingStatus({
    required int uid,
    required bool isSpeaking,
  }) {
    final userId = _normalizeAgoraUid(uid);
    if (userId == 0) return;

    /// Muted user kotha bolleo wave show korbe na.
    if (isSpeaking && _isUserMuted(userId)) {
      isSpeaking = false;
    }

    final bool alreadySpeaking = _speakingUserIds.contains(userId);

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

  final addComments = TextEditingController();

  // ✅ BATTERY OPTIMIZATION: Debounce setState calls to reduce UI updates
  Timer? _uiUpdateTimer;
  bool _needsUIUpdate = false;
  //sawip
  double _uiOffset = 0.0; // UI-র বর্তমান পজিশন
  bool _isUIVisible = true; // UI কি দেখা যাচ্ছে কি না
  void _handleDragUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      _uiOffset += details.delta.dx;
      _uiOffset = _uiOffset.clamp(0.0, screenWidth);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.velocity.pixelsPerSecond.dx;

    setState(() {
      // left swipe করলে show হবে
      if (velocity < -300 || _uiOffset < screenWidth * 0.7) {
        _uiOffset = 0;
        _isUIVisible = true;
      }
      // right swipe করলে hide হবে
      else {
        _uiOffset = screenWidth;
        _isUIVisible = false;
      }
    });
  }

  void _scheduleUIUpdate() {
    if (_uiUpdateTimer?.isActive == true) return;

    _needsUIUpdate = true;
    _uiUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      if (_needsUIUpdate && mounted) {
        setState(() {});
        _needsUIUpdate = false;
      }
    });
  }

  void setLiveStreamDataAsBroadcaster() {
    if (streamData != null) {
      streamInfo.value = streamData['livestreamdata'] ?? {};
      broadcasterData.value = streamData['broadcaster_call_data'] ?? {};

      if (broadcasterData.value.isNotEmpty &&
          broadcasterData.value['user'] != null) {
        liveController.broadcasterId.value = _safeUserId(broadcasterData);
        print('broadcaster id ${liveController.broadcasterId}');
      }
      // Battery Optimization: Use optimized ping interval
      liveController.lastPingUpdate(id: streamInfo['id']);

      // Timer start করি broadcaster এর জন্য
      if (!liveController.isLive.value) {
        String? createdAt =
            streamData['livestreamdata']?['created_at'] ??
                broadcasterData['created_at'];
        if (createdAt != null) {
          liveController.startLive(createdAt);
        } else {
          liveController.startLive(DateTime.now().toIso8601String());
        }
      }
    } else {
      streamInfo.value = {};
      broadcasterData.value = {};
      print('Warning: streamData is null in setLiveStreamDataAsBroadcaster');
    }
  }

  void setLiveStreamDataAsAudience() async {
    // print('stream data $streamData');
    // // Ensure call list is populated for first-time audience members
    await liveController.tryToGetCallList(streamId: streamData['id']);
    // Check if livestream_callers exists and is not empty
    if (streamData != null &&
        streamData['livestream_callers'] != null &&
        streamData['livestream_callers'].isNotEmpty) {
      broadcasterData.value = streamData['livestream_callers'][0];
      liveController.broadcasterId.value = _safeUserId(broadcasterData);
      print(
        'this is broadcaster data ${_safeUserName(broadcasterData)}',
      );
    } else {
      // Fallback: try to get broadcaster data from other sources
      broadcasterData.value = streamData['broadcaster_call_data'] ?? {};
      if (broadcasterData.value.isNotEmpty &&
          broadcasterData.value['user'] != null) {
        liveController.broadcasterId.value = _safeUserId(broadcasterData);
      }
      print('Using fallback broadcaster data');
    }

    // Set streamInfo with proper fallback
    if (streamData != null) {
      streamInfo.value = streamData;
    } else {
      streamInfo.value = {};
      print('Warning: streamData is null in setLiveStreamDataAsAudience');
    }

    // Set the stream ID in WebSocket controller and fetch initial gift total
    if (streamData != null && streamData['id'] != null) {
      websocketController.streamID.value = streamData['id'];
      websocketController.fetchInitialGiftTotal();
    }

    // Timer start করি audience এর জন্য
    if (!liveController.isLive.value) {
      String? createdAt =
          streamData['created_at'] ?? broadcasterData['created_at'];
      if (createdAt != null) {
        liveController.startLive(createdAt);
      } else {
        liveController.startLive(DateTime.now().toIso8601String());
      }
    }
  }

  Future<void> prepareForLive() async {
    // 🔹 Ensure Agora service is initialized
    if (!_agoraService.isInitialized || _agoraService.engine == null) {
      print("AgoraService not ready, attempting to initialize...");
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

    print("⚙️ Configuring Agora for low-heat performance...");

    // 🔹 1. Set channel profile
    await engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );

    // 🔹 2. Enable video/audio (with hardware acceleration if available)
    await engine.enableVideo();
    await engine.enableAudio();

    /// Speaking wave detect korar jonno Agora volume indication.
    /// Backend lagbe na, sob audience nijer app theke ke kotha bolse detect korbe.
    await engine.enableAudioVolumeIndication(
      interval: 300,
      smooth: 3,
      reportVad: true,
    );

    await engine.setParameters('{"che.video.hardware_encoding": true}');

    await engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 848, height: 480), // 480p
        frameRate: 20, // Moderate FPS
        bitrate: 900, // Moderate bitrate
        orientationMode: OrientationMode.orientationModeAdaptive,
      ),
    );

    // 🔹 4. Dynamic bitrate and frame rate for thermal management
    await engine.setParameters('{"che.video.enableAdaptiveBitrate": true}');
    await engine.setParameters('{"rtc.video.dynamic_switch": true}');

    // 🔹 5. Battery optimizer custom config (if any)
    try {} catch (e) {
      print("⚠️ Battery optimizer not available: $e");
    }

    // 🔹 6. Enable low latency mode for less processing
    await engine.setParameters('{"rtc.low_latency_mode": true}');

    // 🔹 7. Set role-specific configurations
    if (widget.isBroadcaster) {
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.enableLocalVideo(true);
      await engine.muteLocalAudioStream(false);
    } else {
      await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      await engine.enableLocalVideo(false);
      await engine.muteLocalAudioStream(true);
    }

    // 🔹 8. Event handlers (optimized with debounced UI updates)
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _activeAgoraChannel = connection.channelId ?? _activeAgoraChannel;
          print("🎉 Joined channel successfully => ${connection.channelId}");
          _scheduleUIUpdate();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print("👤 Remote user joined: $remoteUid channel=${connection.channelId}");
          _pkRemoteUids.add(remoteUid);
          _scheduleUIUpdate();
        },
        onUserOffline:
            (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
            ) {
          print("🚫 Remote user left: $remoteUid channel=${connection.channelId}");
          _pkRemoteUids.remove(remoteUid);
          _setSpeakingStatus(uid: remoteUid, isSpeaking: false);
          _scheduleUIUpdate();
        },

        /// WhatsApp-er moto speaking wave.
        /// Volume beshi hole oi user-er profile/card-e wave show hobe.
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
      ),
    );

    // 🔹 9. Join the channel
    final userId = authController.userProfile.value.user!.id!.toInt();
    _activeAgoraChannel = widget.channelName;
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

    // 🔹 10. Schedule a UI update
    _scheduleUIUpdate();

    // 🔹 11. (Extra) Lower device heating by disabling unused video renderers
    await engine.setParameters('{"che.video.disable_render": false}');
    print("✅ Agora ready with low-heat optimizations");
  }

  // ------------------------- timer ---------------

  @override
  void initState() {
    // Enable wake lock to keep screen on during live streaming
    WakelockPlus.enable();
    _currentToken = widget.token;
    liveController.saveNormalLiveAgoraSession(
      channelName: widget.channelName,
      token: widget.token,
      isBroadcaster: widget.isBroadcaster,
    );
    String? createdAt;

    // প্রথমে createData থেকে check করি
    createdAt = liveController.createData['viewer']?['created_at'];

    // যদি createData থেকে না পাই, তাহলে arguments থেকে check করি
    if (createdAt == null && Get.arguments != null) {
      createdAt = Get.arguments['created_at'];
    }

    // যদি এখনো না পাই, তাহলে current time use করি
    if (createdAt != null) {
      liveController.startLive(createdAt);
    } else {
      // Fallback: current time দিয়ে timer start করি
      liveController.startLive(DateTime.now().toIso8601String());
    }

    prepareForLive();
    if (widget.isBroadcaster) {
      liveController.isBroadcaster.value = true;
      setLiveStreamDataAsBroadcaster();
      websocketController.tryToConnectToBroadcasterWs();
    } else {
      setLiveStreamDataAsAudience();
    }

    /// Initial call list refresh. Accept event late holeo UI sync thakbe.
    Future.delayed(const Duration(milliseconds: 600), () async {
      try {
        final streamId = streamInfo['id'] ?? streamData?['id'];
        if (streamId != null) {
          await liveController.tryToGetCallList(streamId: streamId);
          websocketController.liveCallList.refresh();
          if (mounted) _scheduleUIUpdate();
        }
      } catch (e) {
        print('❌ Popular call list initial refresh failed: $e');
      }
    });
    // Setup red packet callbacks
    _setupRedPacketCallbacks();

    super.initState();
  }

  @override
  void dispose() {
    // ✅ BATTERY OPTIMIZATION: Cancel UI update timer to prevent memory leaks
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;

    for (final timer in _speakingOffTimers.values) {
      timer.cancel();
    }
    _speakingOffTimers.clear();
    _speakingUserIds.clear();
    _pkRemoteUids.clear();

    // Disable wake lock to restore normal screen behavior
    WakelockPlus.disable();
    websocketController.liveCallList.clear();
    websocketController.pendingCall.clear();
    liveController.liveViewerList.clear();
    liveController.stopPingUpdate();
    liveController.isBroadcaster.value = false;
    if (!widget.isBroadcaster) {
      liveController.tryToRemoveViewer(
        streamId: streamInfo['id'],
        viewerId: authController.userProfile.value.user!.id!.toInt(),
      );
    }
    if (widget.isBroadcaster) {
      websocketController.broadcasterWebsocket.sink.close();
    }
    // Clear red packet callbacks
    websocketController.clearRedPacketCallbacks();

    liveController.hasJoinedCall.value =
    false; // Set join status to false when leaving
    _agoraService.engine?.leaveChannel();

    super.dispose();
  }

  void _setupRedPacketCallbacks() {
    websocketController.setRedPacketCallbacks(
      onReceived: (redPacketData) {
        print('🧧 Red packet received in PopularLiveView: $redPacketData');
        // Red packet animation will be shown automatically via Obx
      },
      onCollected: (collectionData) {
        print('🧧 Red packet collected in PopularLiveView: $collectionData');
        // Update balance or show success message
        Get.snackbar(
          '🧧 Red Packet Collected!',
          'You received ${collectionData["amount"]} coins',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      },
    );
  }

  //for live stream end
  @override
  Widget build(BuildContext context) {
    // ✅ KEEP SYSTEM UI: Keep bottom navigation visible, UI starts above it
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return WillPopScope(
      onWillPop: () async {
        if (widget.isBroadcaster) {
          // Broadcaster হলে popup দেখাবো
          bool exitApp = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // corner radius
              ),
              title: Text(
                "End Live",
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                "Are you sure you want to exit?",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // stay
                  child: Text(
                    "No",
                    style: GoogleFonts.roboto(fontSize: 14, color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (widget.isBroadcaster) {
                      await liveController.tryToRemoveLivestream(
                        streamId: streamInfo['id'],
                      );
                    }
                    await _agoraService.engine?.leaveChannel(); // Dialog close
                  },
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

          return exitApp; // true/false based on popup
        } else {
          // Broadcaster না হলে normal back behavior
          return true;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: true,
          child: broadcasterData.isEmpty
              ? Stack(
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: CachedNetworkImage(
                  imageUrl: ImageHelper.getImageUrl(
                    "${_safeUserMap(broadcasterData)['profile_image']}",
                  ),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/audio_live/1136.jpg',
                    fit: BoxFit.cover,
                    height: kHeight,
                    width: kWeight,
                  ),
                ),
              )
              // Image.asset(
              //   'assets/audio_live/1136.jpg',
              //   fit: BoxFit.cover,
              //   height: kHeight,
              //   width: kWeight,
              // ),
              // SpinKitChasingDots(size: 40, color: kPrimaryColor),
            ],
          )
              : Container(
            child: Stack(
              children: [
                // ✅ Broadcaster profile image blurred background
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: CachedNetworkImage(
                      imageUrl: ImageHelper.getImageUrl(
                        "${_safeUserMap(broadcasterData)['profile_image']}",
                      ),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/audio_live/1136.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // ✅ PK running হলে background camera hide করে premium gradient দেখাবো.
                // ✅ Normal popular live হলে old camera/background exactly same থাকবে.
                Obx(() {
                  if (!liveController.pkIsRunning.value) {
                    return const SizedBox.shrink();
                  }
                  return _premiumPkGradientBackground();
                }),

                Obx(() {
                  if (liveController.pkIsRunning.value) {
                    return const SizedBox.shrink();
                  }
                  return _broadcastView();
                }),

                Obx(() {
                  if (liveController.pkIsRunning.value) {
                    return const SizedBox.shrink();
                  }
                  // ✅ Normal popular/video live camera must stay clear.
                  // আগে এখানে black opacity 0.4 ছিল, তাই camera halka black/dark দেখাচ্ছিল।
                  // PK overlay untouched আছে; শুধু normal camera overlay remove করা হলো।
                  return const SizedBox.shrink();
                }),

                _pkAgoraSyncWatcher(),

                /// ✅ Video PK request button + real Agora PK split overlay.
                if (widget.isBroadcaster)
                  Positioned(
                    top: kHeight * 0.14,
                    right: 12,
                    child: Obx(() {
                      if (liveController.pkIsRunning.value) return const SizedBox.shrink();
                      return PkRequestButton(
                        currentLivestreamId: _safeStreamId(),
                        currentHostId: authController.userProfile.value.user?.id?.toInt() ?? 0,
                      );
                    }),
                  ),

                Positioned(
                  top: kHeight * 0.12,
                  left: 0,
                  right: 0,
                  child: Obx(() {
                    if (!liveController.pkIsRunning.value) return const SizedBox.shrink();
                    return _buildRealPkVideoOverlay();
                  }),
                ),

                _buildPkStartIntroOverlay(),
                _buildPkBigCountdownOverlay(),
                _buildPkResultPreviewOverlay(),

                /// ✅ Full screen gift animation for normal live + PK live.
                /// WebsocketController sets giftsData/isGiftAnimationShowing from gift_sent/pk_gift_sent.
                Obx(() {
                  if (!websocketController.isGiftAnimationShowing.value ||
                      websocketController.giftsData.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final giftData = Map<String, dynamic>.from(websocketController.giftsData);
                  final keyValue = giftData['event_id'] ??
                      giftData['id'] ??
                      giftData['timestamp'] ??
                      DateTime.now().microsecondsSinceEpoch;

                  return GiftAnimationWidget(
                    key: ValueKey('full_screen_gift_$keyValue'),
                    giftData: giftData,
                  );
                }),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  left: _uiOffset,
                  right: -_uiOffset,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: _handleDragUpdate,
                    onHorizontalDragEnd: _handleDragEnd,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: kHeight * 0.018),
                            //Live view Part one start
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  //fast row start
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      // ==== Left fixed Stack ====
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Main Container (Background + Info + Follow Button)
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: Get.width * 0.02,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(
                                                20,
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xffe85c7d),
                                                  Color(0xfffdcdfb),
                                                  Color(0xff15bccd),
                                                ],
                                              ),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                right: Get.width * 0.02,
                                              ),
                                              margin: EdgeInsets.all(
                                                Get.width * 0.005,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                  15,
                                                ),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xff650256),
                                                    Color(0xff020947),
                                                  ],
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width:
                                                    Get.width * 0.11,
                                                  ), // profile এর জায়গা
                                                  Column(
                                                    spacing: 2,
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      _safeUserMap(broadcasterData).isNotEmpty
                                                          ? Text(
                                                        (() {
                                                          final name =
                                                              _safeUserMap(broadcasterData)['name'] ??
                                                                  '';
                                                          // ৬ অক্ষরের বেশি হলে শেষে ... দেখাবে
                                                          return name.length >
                                                              8
                                                              ? '${name.substring(0, 8)}...'
                                                              : name;
                                                        })(),
                                                        style: GoogleFonts.poppins(
                                                          color: Colors
                                                              .white,
                                                          fontSize:
                                                          (Get.height *
                                                              0.013)
                                                              .clamp(
                                                            9.0,
                                                            13.0,
                                                          ),
                                                          fontWeight:
                                                          FontWeight
                                                              .w500,
                                                        ),
                                                      )
                                                          : const SizedBox(),
                                                      (_safeUserMap(broadcasterData)['user_id'] != null)
                                                          ? Text(
                                                        'Uid : ${_safeUserMap(broadcasterData)['user_id']}',
                                                        style: GoogleFonts.poppins(
                                                          color: Colors
                                                              .white,
                                                          fontSize:
                                                          (Get.height *
                                                              0.012)
                                                              .clamp(
                                                            9.0,
                                                            14.0,
                                                          ),
                                                          fontWeight:
                                                          FontWeight
                                                              .w500,
                                                        ),
                                                      )
                                                          : const SizedBox(),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width:
                                                    Get.width * 0.015,
                                                  ),

                                                  Obx(() {
                                                    if (_safeUserId(broadcasterData) ==
                                                        authController
                                                            .userProfile
                                                            .value
                                                            .user
                                                            ?.id) {
                                                      return const SizedBox();
                                                    }

                                                    return AnimatedSwitcher(
                                                      duration:
                                                      const Duration(
                                                        milliseconds:
                                                        300,
                                                      ),
                                                      child:
                                                      momentsController
                                                          .isFollowing1
                                                          .value
                                                          ? Container()
                                                          : InkWell(
                                                        key: const ValueKey(
                                                          'follow',
                                                        ),
                                                        onTap: () {
                                                          momentsController.followCreate(
                                                            userId:
                                                            '${_safeUserId(broadcasterData)}',
                                                          );
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(
                                                            vertical:
                                                            Get.height *
                                                                0.007,
                                                            horizontal:
                                                            Get.width *
                                                                0.03,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                            gradient: const LinearGradient(
                                                              colors: [
                                                                Color(0xfffdcdfb),
                                                                Color(0xff15bccd),
                                                              ],
                                                              begin:
                                                              Alignment.topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Follow',
                                                            style: GoogleFonts.lato(
                                                              fontWeight:
                                                              FontWeight.w600,
                                                              fontSize:
                                                              (Get.height *
                                                                  0.006)
                                                                  .clamp(
                                                                9.0,
                                                                14.0,
                                                              ),
                                                              color:
                                                              Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Profile + Fame Overlay
                                          Positioned(
                                            left: -kWeight * 0.048,
                                            top: -Get.height * 0.03,
                                            child: GestureDetector(
                                              onTap: () {
                                                homeController.liveVisitProfile(
                                                  userId:
                                                  '${_safeUserId(broadcasterData)}',
                                                  seatData:
                                                  websocketController.liveCallList.isNotEmpty
                                                      ? websocketController.liveCallList.first
                                                      : broadcasterData,
                                                );
                                              },
                                              child: Obx(() {
                                                double size =
                                                    Get.height * 0.055;
                                                final user = _safeUserMap(broadcasterData);
                                                final frameData =
                                                user['asset_purchase_history'];
                                                print(
                                                  'image url $frameData',
                                                );
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
                                                    int.tryParse(
                                                      agencyIdRaw
                                                          ?.toString() ??
                                                          '0',
                                                    ) ??
                                                        0;

                                                return SizedBox(
                                                  height: kHeight * 0.1,
                                                  width: kHeight * 0.11,
                                                  child: Stack(
                                                    alignment:
                                                    Alignment.center,
                                                    children: [
                                                      if (_isUserSpeaking(user['id']) && !_isUserMuted(user['id']))
                                                        SpeakingWave(size: size * 0.92),

                                                      // ---------------- PROFILE IMAGE ----------------
                                                      ClipOval(
                                                        child: CachedNetworkImage(
                                                          imageUrl:
                                                          ImageHelper.getImageUrl(
                                                            "${user['profile_image']}",
                                                          ),
                                                          fit: BoxFit
                                                              .cover,
                                                          height:
                                                          size * 0.7,
                                                          width:
                                                          size * 0.7,
                                                        ),
                                                      ),

                                                      // ---------------- AGENCY FRAME (if agencyId > 0) ----------------
                                                      if (agencyId > 0)
                                                        SVGAEasyPlayer(
                                                          assetsName:
                                                          'assets/svga/Frame/Agency frame.svga',
                                                          fit: BoxFit
                                                              .cover,
                                                        )
                                                      // ---------------- NORMAL FRAME (if no agency frame) --------------
                                                      else if (frameData !=
                                                          null &&
                                                          frameData['asset'] !=
                                                              null &&
                                                          frameData['asset']['asset'] !=
                                                              null)
                                                      // Check if the asset path ends with .svga
                                                        (frameData['asset']['asset']
                                                            .toString()
                                                            .endsWith(
                                                          '.svga',
                                                        ))
                                                            ? SizedBox(
                                                          height:
                                                          kHeight *
                                                              0.055,
                                                          width:
                                                          kHeight *
                                                              0.055,
                                                          child: SVGAEasyPlayer(
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
                                                              0.055,
                                                          width:
                                                          kHeight *
                                                              0.055,
                                                          fit: BoxFit
                                                              .cover,
                                                          placeholder:
                                                              (
                                                              context,
                                                              url,
                                                              ) => Container(
                                                            height:
                                                            kHeight *
                                                                0.12,
                                                            width:
                                                            kHeight *
                                                                0.12,
                                                            decoration: BoxDecoration(
                                                              color: kAppColor.withValues(
                                                                alpha: .02,
                                                              ),
                                                              borderRadius: BorderRadius.circular(
                                                                12,
                                                              ),
                                                            ),
                                                          ),
                                                          errorWidget:
                                                              (
                                                              context,
                                                              url,
                                                              error,
                                                              ) => Container(
                                                            height:
                                                            kHeight *
                                                                0.12,
                                                            width:
                                                            kHeight *
                                                                0.12,
                                                            decoration: BoxDecoration(
                                                              color: Colors.transparent,
                                                              borderRadius: BorderRadius.circular(
                                                                12,
                                                              ),
                                                            ),
                                                            child: Icon(
                                                              Icons.broken_image,
                                                              size: 40,
                                                              color: kAppColor.withValues(
                                                                alpha: .2,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      // ---------------- NOTHING (no frame) ----------------
                                                      else
                                                        SizedBox(
                                                          height:
                                                          kHeight *
                                                              0.03,
                                                          width:
                                                          kHeight *
                                                              0.03,
                                                        ),

                                                      if (_isUserMuted(user['id']))
                                                        Positioned(
                                                          right: kHeight * 0.018,
                                                          bottom: kHeight * 0.020,
                                                          child: _SmallMuteBadge(
                                                            fontSize: kHeight * 0.007,
                                                            iconSize: kHeight * 0.008,
                                                            compact: true,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // SizedBox(
                                      //   width: kWeight * 0.004,
                                      // ),
                                      // InkWell(
                                      //   onTap: () {
                                      //     final coming = true;
                                      //     if (coming) {
                                      //       Fluttertoast.showToast(
                                      //         msg: "Coming Soon!",
                                      //         toastLength:
                                      //         Toast.LENGTH_SHORT,
                                      //         // or LENGTH_LONG
                                      //         gravity: ToastGravity.BOTTOM,
                                      //         // where the toast will appear
                                      //         backgroundColor: kAppColor,
                                      //         textColor: Colors.white,
                                      //         fontSize: 16.0,
                                      //       );
                                      //     }
                                      //   },
                                      //   child: SizedBox(
                                      //     height: kHeight * 0.045,
                                      //     width: kHeight * 0.045,
                                      //     child: Stack(
                                      //       alignment: Alignment.center,
                                      //       children: [
                                      //         // ---------------- PROFILE IMAGE ----------------
                                      //         ClipRRect(
                                      //           borderRadius:
                                      //           BorderRadius.circular(
                                      //               100),
                                      //           child: Image.asset(
                                      //             'assets/flaticons/boy.png',
                                      //             height: kHeight * 0.03,
                                      //             width: kHeight * 0.03,
                                      //             fit: BoxFit.cover,
                                      //           ),
                                      //         ),
                                      //
                                      //         Image.asset(
                                      //           "assets/audio_live/gradian.png",
                                      //           height: kHeight * 0.06,
                                      //           width: kHeight * 0.06,
                                      //           fit: BoxFit.cover,
                                      //         ),
                                      //
                                      //         // ---------------- NOTHING (no frame) ----------------
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),
                                      SizedBox(width: kWeight * 0.004),
                                      // ==== Right viewers + close ==== (Flexible so it won’t overflow)
                                      Flexible(
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: Get.width * 0.22,
                                              height: Get.height * 0.04,
                                              child: Obx(() {
                                                // Filter list একবারেই বের করো
                                                final filteredList =
                                                livestreamController
                                                    .liveViewerList
                                                    .where(
                                                      (viewer) =>
                                                  _safeUserId(viewer) !=
                                                      _safeUserId(broadcasterData),
                                                )
                                                    .toList();

                                                if (filteredList
                                                    .isEmpty) {
                                                  return const SizedBox(); // কিছু না দেখানোর জন্য (empty state)
                                                }

                                                return ListView.builder(
                                                  scrollDirection:
                                                  Axis.horizontal,
                                                  itemCount:
                                                  filteredList.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final data =
                                                    filteredList[index];
                                                    return LiveProfile(
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
                                                        .where(
                                                          (viewer) =>
                                                      _safeUserId(viewer) !=
                                                          _safeUserId(broadcasterData),
                                                    )
                                                        .toList();

                                                    Get.bottomSheet(
                                                      LiveViewerList(
                                                        filteredList:
                                                        filteredList,
                                                      ),
                                                      isScrollControlled:
                                                      true,
                                                    );
                                                  },
                                                  child: Container(
                                                    margin:
                                                    EdgeInsets.only(
                                                      right:
                                                      Get.width *
                                                          0.01,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        20,
                                                      ),
                                                      gradient:
                                                      LinearGradient(
                                                        colors: [
                                                          Color(
                                                            0xffe85c7d,
                                                          ),
                                                          Color(
                                                            0xfffdcdfb,
                                                          ),
                                                          Color(
                                                            0xff15bccd,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    child: Container(
                                                      margin:
                                                      EdgeInsets.all(
                                                        1,
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                        BorderRadius.circular(
                                                          100,
                                                        ),
                                                        child: Container(
                                                          height:
                                                          Get.height *
                                                              0.035,
                                                          width:
                                                          Get.height *
                                                              0.035,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xff650256,
                                                                ),
                                                                Color(
                                                                  0xff020947,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          child: Center(
                                                            child: Obx(() {
                                                              final filteredCount = livestreamController
                                                                  .liveViewerList
                                                                  .where(
                                                                    (
                                                                    viewer,
                                                                    ) =>
                                                                _safeUserId(viewer) !=
                                                                    _safeUserId(broadcasterData),
                                                              )
                                                                  .length;
                                                              return Text(
                                                                '$filteredCount+',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
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
                                                ),
                                                (widget
                                                        .isBroadcaster)
                                                    ? GestureDetector(
                                                  onTap: () async {
                                                    // Show confirmation dialog for broadcaster
                                                    final shouldEnd = await Get.dialog<bool>(
                                                      AlertDialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                            0,
                                                          ), // ✅ কম border radius
                                                        ),
                                                        backgroundColor:
                                                        Colors
                                                            .white,
                                                        title: Text(
                                                          'End Live Stream',
                                                          style: GoogleFonts.roboto(
                                                            fontSize:
                                                            18,
                                                            fontWeight:
                                                            FontWeight.w600,
                                                            color: Colors
                                                                .black87,
                                                          ),
                                                        ),
                                                        content: Text(
                                                          'Are you sure you want to end this live stream? All viewers will be disconnected.',
                                                          style: GoogleFonts.roboto(
                                                            fontSize:
                                                            14,
                                                            color: Colors
                                                                .black54,
                                                          ),
                                                        ),
                                                        actionsPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                          12,
                                                          vertical:
                                                          8,
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            style: TextButton.styleFrom(
                                                              backgroundColor: Colors
                                                                  .grey
                                                                  .shade200,
                                                              // ✅ Cancel এর ব্যাকগ্রাউন্ড
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(
                                                                  8,
                                                                ),
                                                              ),
                                                            ),
                                                            onPressed: () => Get.back(
                                                              result:
                                                              false,
                                                            ),
                                                            child: Text(
                                                              'Cancel',
                                                              style: GoogleFonts.roboto(
                                                                fontWeight:
                                                                FontWeight.w500,
                                                                color:
                                                                Colors.black87,
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            style: TextButton.styleFrom(
                                                              backgroundColor:
                                                              Colors.redAccent,
                                                              // ✅ End Stream এর রঙ
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(
                                                                  8,
                                                                ),
                                                              ),
                                                            ),
                                                            onPressed: () async {
                                                              if (widget
                                                                  .isBroadcaster) {
                                                                await liveController.tryToRemoveLivestream(
                                                                  streamId: streamInfo['id'],
                                                                );
                                                              }
                                                              await _agoraService
                                                                  .engine
                                                                  ?.leaveChannel(); // Dialog close
                                                            },
                                                            child: Text(
                                                              'End Stream',
                                                              style: GoogleFonts.roboto(
                                                                fontWeight:
                                                                FontWeight.w600,
                                                                color:
                                                                Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (shouldEnd ==
                                                        true) {
                                                      // created_at থেকে startTime নেওয়া, null হলে এখনকার সময় ব্যবহার
                                                      final DateTime
                                                      startDateTime =
                                                      broadcasterData['created_at'] !=
                                                          null
                                                          ? DateTime.parse(
                                                        broadcasterData['created_at'],
                                                      )
                                                          : DateTime.now();

                                                      print(
                                                        'stream data $streamInfo',
                                                      );

                                                      // End the stream properly
                                                      await livestreamController.liveEndTimeCase(
                                                        streamId:
                                                        broadcasterData['livestream_id'],
                                                        startTime:
                                                        startDateTime,
                                                      );

                                                      await _agoraService
                                                          .engine
                                                          ?.leaveChannel();
                                                    }
                                                  },
                                                  child: Container(
                                                    margin:
                                                    EdgeInsets.only(
                                                      right: 2,
                                                      left: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        20,
                                                      ),
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Color(
                                                            0xffe85c7d,
                                                          ),
                                                          Color(
                                                            0xfffdcdfb,
                                                          ),
                                                          Color(
                                                            0xff15bccd,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    child: Container(
                                                      margin:
                                                      EdgeInsets.all(
                                                        1,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Color(
                                                              0xff650256,
                                                            ),
                                                            Color(
                                                              0xff020947,
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      height:
                                                      Get.height *
                                                          0.035,
                                                      width:
                                                      Get.height *
                                                          0.035,
                                                      child: Icon(
                                                        Icons
                                                            .close_rounded,
                                                        color: Colors
                                                            .white,
                                                        size:
                                                        Get.height *
                                                            0.02,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                    : IconButton(
                                                  style: IconButton.styleFrom(
                                                    backgroundColor:
                                                    Colors
                                                        .grey[100],
                                                    padding:
                                                    EdgeInsets.all(
                                                      4,
                                                    ),
                                                    // ভিতরের space ছোট করা
                                                    minimumSize: Size(
                                                      28,
                                                      28,
                                                    ), // button এর overall size ছোট করা
                                                  ),
                                                  onPressed: () {
                                                    Get.back();
                                                  },
                                                  icon: Icon(
                                                    Icons.close,
                                                    color:
                                                    kAppColor,
                                                    size:
                                                    18, // icon টার সাইজ ছোট
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: kWeight * 0.01,
                                                ),
                                              ],
                                            ),

                                            ///------------- viewer list show

                                            // Nothing will be shown if broadcasterData is null
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: kHeight * 0.006),

                                  ///---------- timer -------------
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      top: 5,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Get.to(
                                              Profileconribution(),
                                              transition:
                                              Transition.rightToLeft,
                                            );
                                          },
                                          child: Obx(() {
                                            return TaskLiveProfile(
                                              text: (() {
                                                final int coins = _safeCurrentGiftCoins();
                                                return _formatShortCoins(coins);
                                              })(),
                                              seccondtext: 'Receive: ',
                                            );
                                          }),
                                        ),
                                        _safeUserId(broadcasterData) ==
                                            authController
                                                .userProfile
                                                .value
                                                .user!
                                                .id
                                            ? Container(
                                          padding:
                                          EdgeInsets.symmetric(
                                            horizontal:
                                            kWeight * 0.03,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(
                                              15,
                                            ),
                                            gradient:
                                            LinearGradient(
                                              colors: [
                                                Color(
                                                  0xff650256,
                                                ),
                                                Color(
                                                  0xff020947,
                                                ),
                                              ],
                                            ),
                                          ),
                                          child: Obx(
                                                () => Castontext(
                                              fontSize:
                                              kHeight * 0.015,
                                              textColor:
                                              liveController
                                                  .isLive
                                                  .value
                                                  ? const Color(
                                                0xffffffff,
                                              ) // Live active = green
                                                  : const Color(
                                                0xff808080,
                                              ), // Inactive = gray
                                              text: liveController.pkIsRunning.value
                                                  ? liveController.pkFormattedRemainingTime
                                                  : liveController.formattedTime,
                                            ),
                                          ),
                                        )
                                            : const SizedBox.shrink(),
                                        GestureDetector(
                                          onTap: () {
                                            // Get.to(RankingView(),
                                            //     transition: Transition.rightToLeft);
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              left: 5,
                                              right: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(
                                                20,
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xffe85c7d),
                                                  Color(0xfffdcdfb),
                                                  Color(0xff15bccd),
                                                ],
                                              ),
                                            ),
                                            child: Container(
                                              margin: EdgeInsets.all(1),
                                              padding:
                                              EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                  15,
                                                ),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xff650256),
                                                    Color(0xff020947),
                                                  ],
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Current:',
                                                    style:
                                                    GoogleFonts.roboto(
                                                      color: Colors
                                                          .white,
                                                      fontWeight:
                                                      FontWeight
                                                          .w400,
                                                      fontSize:
                                                      kHeight *
                                                          0.012,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Obx(() {
                                                    final int coins = _safeCurrentGiftCoins();
                                                    final String displayText = _formatShortCoins(coins);

                                                    // 🔹 UI return
                                                    return Text(
                                                      displayText,
                                                      style: TextStyle(
                                                        color:
                                                        Colors.white,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold,
                                                        fontSize:
                                                        kHeight *
                                                            0.014,
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ///----- noble part ----------
                                  // InkWell(
                                  //   onTap: () {},
                                  //   child: Container(
                                  //       width: kWeight * 0.25,
                                  //       margin: EdgeInsets.symmetric(
                                  //           vertical: 10, horizontal: 10),
                                  //       padding: EdgeInsets.symmetric(
                                  //           vertical: 3, horizontal: 8),
                                  //       decoration: BoxDecoration(
                                  //         borderRadius:
                                  //         BorderRadius.circular(30),
                                  //         gradient: LinearGradient(colors: [
                                  //           Color(0xff8c61e1),
                                  //           Color(0xff5815dc)
                                  //         ]),
                                  //       ),
                                  //       child: Row(
                                  //         children: [
                                  //           Image(
                                  //             image: AssetImage(
                                  //                 'assets/flaticons/crown.png'),
                                  //             height: kHeight * 0.03,
                                  //           ),
                                  //           Text(
                                  //             ' Noble',
                                  //             style: GoogleFonts.poppins(
                                  //                 fontWeight:
                                  //                 FontWeight.w600,
                                  //                 color: Colors.white,
                                  //                 fontSize:
                                  //                 kWeight * 0.029),
                                  //           ),
                                  //         ],
                                  //       )),
                                  // ),
                                ],
                              ),
                            ),

                            ///---------------- Call part ----------
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
                                    ),

                                    //container  text end
                                    SizedBox(width: 5),
                                    Expanded(
                                      flex: 2,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: kHeight * 0.32,
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: kWeight * 0.03,
                                              ),
                                              child:
                                              _safeUserId(broadcasterData) ==
                                                  authController
                                                      .userProfile
                                                      .value
                                                      .user!
                                                      .id
                                                  ? Container()
                                                  : Align(
                                                alignment: Alignment
                                                    .bottomRight,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    final bool pkRunningForAudienceCall =
                                                        liveController.pkIsRunning.value ||
                                                            liveController.currentPkId.value > 0;
                                                    if (pkRunningForAudienceCall && !widget.isBroadcaster) {
                                                      Fluttertoast.showToast(
                                                        msg: 'PK is running. Call option is disabled during PK.',
                                                        toastLength: Toast.LENGTH_SHORT,
                                                        gravity: ToastGravity.BOTTOM,
                                                        backgroundColor: Colors.black87,
                                                        textColor: Colors.white,
                                                        fontSize: 13.0,
                                                      );
                                                      return;
                                                    }

                                                    websocketController
                                                        .tryToConnectToCallListWs();
                                                    if (livestreamController
                                                        .isBroadcaster
                                                        .value) {
                                                      // ✅ Broadcaster হলে BottomSheet

                                                    } else {
                                                      Get.bottomSheet(
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            borderRadius: const BorderRadius.only(
                                                              topLeft: Radius.circular(32),
                                                              topRight: Radius.circular(32),
                                                            ),
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [
                                                                Colors.white.withValues(alpha: 0.18),
                                                                Colors.white.withValues(alpha: 0.08),
                                                              ],
                                                            ),

                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius: const BorderRadius.only(
                                                              topLeft: Radius.circular(32),
                                                              topRight: Radius.circular(32),
                                                            ),
                                                            child: BackdropFilter(
                                                              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                                              child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const SizedBox(height: 16),

                                                                  // Handle bar
                                                                  Container(
                                                                    width: 40,
                                                                    height: 4,
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.white.withValues(alpha: 0.3),
                                                                      borderRadius: BorderRadius.circular(2),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 20),

                                                                  // Premium badge
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.white.withValues(alpha: 0.12),
                                                                      borderRadius: BorderRadius.circular(20),
                                                                      border: Border.all(
                                                                        color: Colors.white.withValues(alpha: 0.2),
                                                                        width: 1,
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 13),
                                                                        const SizedBox(width: 5),
                                                                        Text(
                                                                          "Premium Live Call",
                                                                          style: GoogleFonts.poppins(
                                                                            fontSize: 11,
                                                                            color: Colors.white.withValues(alpha: 0.8),
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 14),

                                                                  // Title
                                                                  Text(
                                                                    "Join Live Stream",
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: Colors.white.withValues(alpha: 0.95),
                                                                      letterSpacing: 0.3,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 4),

                                                                  // Subtitle
                                                                  Text(
                                                                    "Choose your preferred call type",
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize: 12,
                                                                      color: Colors.white.withValues(alpha: 0.5),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 20),

                                                                  // Divider
                                                                  Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 0.5, height: 1),
                                                                  const SizedBox(height: 24),

                                                                  // Buttons
                                                                  Padding(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                                                    child: Row(
                                                                      children: [
                                                                        // Video Call Button
                                                                        Expanded(
                                                                          child: _GlassCallButton(
                                                                            label: "Video Call",
                                                                            icon: Icons.videocam_rounded,
                                                                            gradientColors: const [
                                                                              Color(0xFFFF5F6D),
                                                                              Color(0xFFFF8C42),
                                                                              Color(0xFFFFC371),
                                                                            ],
                                                                            shadowColor: const Color(0xFFFF5F6D),
                                                                            onTap: () {
                                                                              livestreamController.tryToCallLivestream(
                                                                                streamId: livestreamController.streamId.value,
                                                                                callerId: authController.userProfile.value.user!.id!.toInt(),
                                                                                callType: 'video',
                                                                              );
                                                                              Get.back();
                                                                            },
                                                                          ),
                                                                        ),
                                                                        const SizedBox(width: 12),

                                                                        // Voice Call Button
                                                                        Expanded(
                                                                          child: _GlassCallButton(
                                                                            label: "Voice Call",
                                                                            icon: Icons.mic_rounded,
                                                                            gradientColors: const [
                                                                              Color(0xFF667EEA),
                                                                              Color(0xFF7F5FC5),
                                                                              Color(0xFF764BA2),
                                                                            ],
                                                                            shadowColor: const Color(0xFF667EEA),
                                                                            onTap: () {
                                                                              livestreamController.tryToCallLivestream(
                                                                                streamId: livestreamController.streamId.value,
                                                                                callerId: authController.userProfile.value.user!.id!.toInt(),
                                                                                callType: 'audio',
                                                                              );
                                                                              Get.back();
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  SizedBox(height: kHeight * 0.05),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        backgroundColor: Colors.transparent,
                                                        isScrollControlled: true,
                                                      );
                                                    }
                                                  },
                                                  child: LiveViewsecond_Image(
                                                    image:
                                                    'assets/flaticons/link (1).png',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: kHeight * 0.06),
                          ],
                        ),

                        //Pk
                        Obx(() {
                          if (!livestreamController.showPkView.value) {
                            return const SizedBox();
                          }
                          return Positioned(
                            top: Get.height * 0.15,
                            left: 0,
                            right: 0,
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        // 🔵 Left side (Player A)
                                        Container(
                                          width: Get.width * 0.5,
                                          height: Get.height * 0.15,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            const BorderRadius.only(
                                              topLeft:
                                              Radius.circular(20),
                                            ),
                                            gradient:
                                            const LinearGradient(
                                              begin:
                                              Alignment.topLeft,
                                              end: Alignment
                                                  .bottomRight,
                                              colors: [
                                                Color(0xff2196F3),
                                                Color(0xff673AB7),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 10,
                                                offset: const Offset(
                                                  0,
                                                  5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: Get.height * 0.04,
                                              ),
                                              // Player avatar
                                              Container(
                                                padding:
                                                const EdgeInsets.all(
                                                  3,
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 3,
                                                  ),
                                                  gradient:
                                                  const LinearGradient(
                                                    colors: [
                                                      Colors
                                                          .blueAccent,
                                                      Colors
                                                          .purpleAccent,
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                        alpha: 0.2,
                                                      ),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                child: ClipOval(
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSrVN9H11wCam0PY3Wp44gEjVOWihP2BNyltg&s',
                                                    height:
                                                    Get.height * 0.05,
                                                    width:
                                                    Get.height * 0.05,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "Md Abdul",
                                                style:
                                                GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                  fontSize:
                                                  Get.height *
                                                      0.014,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 🔴 Right side (Player B)
                                        Container(
                                          width: Get.width * 0.5,
                                          height: Get.height * 0.15,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            const BorderRadius.only(
                                              topRight:
                                              Radius.circular(20),
                                            ),
                                            gradient:
                                            const LinearGradient(
                                              begin:
                                              Alignment.topLeft,
                                              end: Alignment
                                                  .bottomRight,
                                              colors: [
                                                Color(0xffE91E63),
                                                Color(0xff6A1B9A),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 10,
                                                offset: const Offset(
                                                  0,
                                                  5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: Get.height * 0.04,
                                              ),
                                              // Player avatar
                                              Container(
                                                padding:
                                                const EdgeInsets.all(
                                                  3,
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 3,
                                                  ),
                                                  gradient:
                                                  const LinearGradient(
                                                    colors: [
                                                      Colors
                                                          .blueAccent,
                                                      Colors
                                                          .purpleAccent,
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                        alpha: 0.2,
                                                      ),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                child: ClipOval(
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSrVN9H11wCam0PY3Wp44gEjVOWihP2BNyltg&s',
                                                    height:
                                                    Get.height * 0.05,
                                                    width:
                                                    Get.height * 0.05,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "Md Abdul",
                                                style:
                                                GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                  fontSize:
                                                  Get.height *
                                                      0.014,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    AnimatedProgressBar(
                                      controller:
                                      animatedProgressBarController,
                                    ),
                                  ],
                                ),

                                // 🆚 VS text overlay
                                Positioned(
                                  top: 40,
                                  left: 215,
                                  right: 0,
                                  child: Text(
                                    "VS",
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: Get.height * 0.08,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),

                                // 📊 Bottom bar

                                // ⏱ Timer + Exit
                                Positioned(
                                  top: 5,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(width: 40),
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              "PK ",
                                              style: GoogleFonts.poppins(
                                                color:
                                                Colors.yellowAccent,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "05:00",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight:
                                                FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.exit_to_app,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          Get.defaultDialog(
                                            title: "Exit",
                                            middleText:
                                            "Are you sure you want to exit?",
                                            textCancel: "No",
                                            textConfirm: "Yes",
                                            confirmTextColor:
                                            Colors.white,
                                            onConfirm: () {
                                              Get.back();
                                              livestreamController
                                                  .hidePk();
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Obx(() {
                          if (!livestreamController.showPkView.value) {
                            return const SizedBox();
                          }
                          return Positioned(
                            top: Get.height * 0.155,
                            left: 0,
                            right: 0,
                            child: towVsTowPk(
                              animatedProgressBarController:
                              animatedProgressBarController,
                              livestreamController: livestreamController,
                            ),
                          );
                        }),
                        Obx(() {
                          if (!livestreamController.showPkRoom.value) {
                            return SizedBox();
                          }
                          return Positioned(
                            top: Get.height * 0.155,
                            left: 0,
                            right: 0,
                            child: CustomPartyRoom(
                              livestreamController: livestreamController,
                              animatedProgressBarController:
                              animatedProgressBarController,
                            ),
                          );
                        }),
                        Obx(() {
                          final newUser = websocketController.newJoinedUserData;

                          if (websocketController.newViewersJoinded.value) {
                            final hasEntry =
                                newUser['user']?['entry_histories']?['asset']?['asset'] != null;

                            if (hasEntry) {
                              // ✅ SVGA আছে → onFinished callback দিয়ে hide হবে
                              return Positioned.fill(
                                child: EntryAnimation(
                                  data: newUser,
                                  // onFinished: () {
                                  //   websocketController.newViewersJoinded.value = false;
                                  // },
                                ),
                              );
                            }

                            // ✅ SVGA নেই → slide animation → 3s পরে hide
                            Future.delayed(const Duration(seconds: 3), () {
                              if (websocketController.newViewersJoinded.value) {
                                websocketController.newViewersJoinded.value = false;
                              }
                            });

                            return Positioned(
                              left: 12,
                              top: Get.height * 0.5,
                              child: SizedBox(
                                width: Get.width * 0.9,
                                child: EntryAnimation(
                                  data: newUser,
                                  // onFinished: () {
                                  //   websocketController.newViewersJoinded.value = false;
                                  // },
                                ),
                              ),
                            );
                          }

                          return const SizedBox();
                        }),
                        // Red Packet Animation
                        Obx(
                              () =>
                          websocketController
                              .redPacketVisible
                              .value &&
                              websocketController
                                  .currentRedPacket
                                  .value
                                  .isNotEmpty
                              ? Positioned.fill(
                            child: RedPacketAnimation(
                              isVisible: websocketController
                                  .redPacketVisible
                                  .value,
                              onTap: () async {
                                // Collect red packet
                                final redPacket =
                                    websocketController
                                        .currentRedPacket
                                        .value;
                                if (redPacket.isNotEmpty) {
                                  await liveController
                                      .collectRedPacket(
                                    redPacket['id'],
                                  );
                                  websocketController
                                      .hideRedPacket();
                                }
                              },
                            ),
                          )
                              : Container(),
                        ),
                        Obx(
                              () => livestreamController.showMiniScene.value
                              ? Positioned(
                            top: 60,
                            right: 10,
                            child: AnimatedOpacity(
                              opacity:
                              livestreamController
                                  .showMiniScene
                                  .value
                                  ? 1
                                  : 0,
                              duration: const Duration(
                                milliseconds: 300,
                              ),
                              child: Container(
                                width: Get.width * 0.5,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: 0.95,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "🎁 Mini Scene",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "This is a small overlay above live.",
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        livestreamController
                                            .showMiniScene
                                            .value =
                                        false;
                                      },
                                      child: const Text("Close"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_isUIVisible)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 60,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: _handleDragUpdate,
                      onHorizontalDragEnd: _handleDragEnd,
                      onTap: () {
                        setState(() {
                          _uiOffset = 0;
                          _isUIVisible = true;
                        });
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                ///------------- bottom part -------
                _agoraService.engine != null
                    ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: kWeight * 0.0,
                    ),
                    child: Row(
                      children: [
                        // WriteCommentSection takes most of the space
                        Expanded(
                          child: WriteCommentSection(
                            rtcEngine: _agoraService.engine!,
                            streamType: 'popular',
                            broadcasterData: broadcasterData,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Container(
                  color: Colors
                      .transparent, // Optional: blank red bar if engine null
                  height: 60, // adjust height if needed
                ),
                _agoraService.engine == null
                    ? const Center(
                  child: CircularProgressIndicator(),
                ) // Show loading
                    : Container(),

                //Live view bottom part end
              ],
            ),
          ),
        ),

        // body parameter শেষ
      ),
    );
  }

  bool muted = false, videoDisabled = false, loudSpeaker = false;

  Widget _miniNamePill(dynamic broadcaster) {
    final name = _safeUserName(broadcaster, fallback: '');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name.length > 10
            ? '${name.substring(0, 10)}...'
            : name,
        style: TextStyle(
          color: Colors.white,
          fontSize: kHeight * 0.011,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _safeProfileImage(dynamic image) {
    final raw = image?.toString().trim() ?? '';

    if (raw.isEmpty || raw == 'null') {
      return 'https://ui-avatars.com/api/?name=User&background=8A4CF7&color=fff';
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final url = ImageHelper.getImageUrl(raw);
    if (url.trim().isEmpty || url == 'file:///') {
      return 'https://ui-avatars.com/api/?name=User&background=8A4CF7&color=fff';
    }

    return url;
  }


  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _safeUserMap(dynamic value) {
    final map = _safeMap(value);

    final directUser = map['user'] ?? map['User'];
    if (directUser is Map) {
      return Map<String, dynamic>.from(directUser);
    }

    final callerData = map['caller_data'] ?? map['call_data'] ?? map['accepted_caller'];
    if (callerData is Map) {
      final nestedUser = callerData['user'] ?? callerData['User'];
      if (nestedUser is Map) return Map<String, dynamic>.from(nestedUser);
    }

    final viewerData = map['viewer_data'] ?? map['viewer'];
    if (viewerData is Map) {
      final nestedUser = viewerData['user'] ?? viewerData['User'];
      if (nestedUser is Map) return Map<String, dynamic>.from(nestedUser);
    }

    return <String, dynamic>{};
  }

  int _safeInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'null') return fallback;
    return int.tryParse(raw) ?? double.tryParse(raw)?.toInt() ?? fallback;
  }

  int _safeUserId(dynamic value) {
    final map = _safeMap(value);
    final user = _safeUserMap(value);

    return _safeInt(
      user['id'] ??
          user['user_id'] ??
          map['user_id'] ??
          map['caller_id'] ??
          map['viewer_id'] ??
          map['host_id'] ??
          map['uid'],
    );
  }

  String _safeUserName(dynamic value, {String fallback = 'User'}) {
    final map = _safeMap(value);
    final user = _safeUserMap(value);
    final raw = (user['name'] ??
        user['full_name'] ??
        map['name'] ??
        map['caller_name'] ??
        map['display_name'] ??
        fallback)
        .toString()
        .trim();
    return raw.isEmpty || raw == 'null' ? fallback : raw;
  }

  String _safeUserProfile(dynamic value) {
    final map = _safeMap(value);
    final user = _safeUserMap(value);
    return _safeProfileImage(
      user['profile_image'] ??
          user['avatar'] ??
          map['profile_image'] ??
          map['caller_image'] ??
          map['image'],
    );
  }

  bool _hasValidUser(dynamic value) {
    return _safeUserId(value) > 0 || _safeUserMap(value).isNotEmpty;
  }

  int _safeCurrentGiftCoins() {
    final fromWs = _safeInt(websocketController.totalGiftCoins.value);
    if (fromWs > 0) return fromWs;

    final callList = websocketController.liveCallList;
    if (callList.isNotEmpty) {
      final first = _safeMap(callList.first);
      return _safeInt(
        first['earn_coins'] ??
            first['earned_coins'] ??
            first['total_gift_coins'] ??
            first['received_coins'] ??
            first['stream_coins'] ??
            first['gifts_coins'],
      );
    }

    return _safeInt(
      streamInfo['total_gift_coins'] ??
          streamInfo['received_coins'] ??
          streamInfo['stream_coins'] ??
          streamInfo['gifts_coins'],
    );
  }

  String _formatShortCoins(int coins) {
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

  Widget _broadcastView() {
    if (_agoraService.engine == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Obx(() {
      final views = _getRenderViews(
        listActive: websocketController.liveCallList,
      );

      if (views.isEmpty) {
        if (widget.isBroadcaster && _agoraService.engine != null) {
          return AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _agoraService.engine!,
              canvas: const VideoCanvas(uid: 0),
            ),
          );
        }
        return const Center(child: Text("Waiting for remote user..."));
      }

      final mainView = views[0];

      final smallBroadcasters = websocketController.liveCallList
          .asMap()
          .entries
          .where((e) => e.key > 0 && e.key <= 4 && e.key < views.length && _hasValidUser(e.value))
          .map((e) {
        final index = e.key;
        final broadcaster = e.value;
        final userId = _safeUserId(broadcaster);
        final bool isMuted = _isCallMuted(broadcaster);
        final bool isSpeaking = _isUserSpeaking(userId) && !isMuted;
        final bool isAudioOnly =
            broadcaster['video_on'] == 0 || broadcaster['call_type'] == 'audio';

        return GestureDetector(
          onTap: () {
            homeController.liveVisitProfile(
              userId: '${_safeUserId(broadcaster)}',
              seatData: broadcaster,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSpeaking)
                Positioned.fill(
                  child: SpeakingCardWave(
                    borderRadius: 10,
                  ),
                ),
              Container(
                margin: EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: isSpeaking
                        ? const [
                      Color(0xff38ffb3),
                      Color(0xff15bccd),
                      Color(0xff38ffb3),
                    ]
                        : const [
                      Color(0xffe85c7d),
                      Color(0xfffdcdfb),
                      Color(0xff15bccd),
                    ],
                  ),
                  boxShadow: isSpeaking
                      ? [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: .42),
                      blurRadius: 16,
                      spreadRadius: 1.5,
                    ),
                  ]
                      : null,
                ),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  width: Get.width * 0.27,
                  height: Get.height * 0.15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isAudioOnly
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _safeUserMap(broadcaster)['profile_image'] != null &&
                            _safeUserMap(broadcaster)['profile_image']
                                .toString()
                                .isNotEmpty
                            ? ImageFiltered(
                          imageFilter:
                          ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: CachedNetworkImage(
                            imageUrl: _safeUserProfile(broadcaster),
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(
                                  color: Colors.grey.shade800,
                                ),
                            errorWidget: (context, url, error) =>
                                Container(
                                  color: Colors.grey.shade800,
                                ),
                          ),
                        )
                            : Container(color: Colors.grey.shade800),

                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: kHeight * 0.018),
                              SizedBox(
                                height: Get.height * 0.080,
                                width: Get.height * 0.080,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isSpeaking)
                                      SpeakingWave(
                                        size: Get.height * 0.080,
                                      ),
                                    ClipOval(
                                      child: _safeUserProfile(broadcaster).isNotEmpty
                                          ? CachedNetworkImage(
                                        imageUrl:
                                        _safeUserProfile(broadcaster),
                                        height: Get.height * 0.064,
                                        width: Get.height * 0.064,
                                        fit: BoxFit.cover,
                                        filterQuality:
                                        FilterQuality.high,
                                        placeholder:
                                            (context, url) =>
                                            Container(
                                              height:
                                              Get.height * 0.064,
                                              width:
                                              Get.height * 0.064,
                                              color: Colors
                                                  .grey.shade600,
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              ),
                                            ),
                                        errorWidget: (context, url,
                                            error) =>
                                            Container(
                                              height:
                                              Get.height * 0.064,
                                              width:
                                              Get.height * 0.064,
                                              color: Colors
                                                  .grey.shade600,
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              ),
                                            ),
                                      )
                                          : Container(
                                        height: Get.height * 0.064,
                                        width: Get.height * 0.064,
                                        color: Colors.grey.shade600,
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (isMuted)
                                      Positioned(
                                        right: 4,
                                        bottom: 6,
                                        child: _SmallMuteBadge(
                                          fontSize: kHeight * 0.007,
                                          iconSize: kHeight * 0.009,
                                          compact: true,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: kHeight * 0.010),
                              _miniNamePill(broadcaster),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(child: views[index]),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (() {
                                      final name = _safeUserName(broadcaster, fallback: '');
                                      return name.length > 10 ? '${name.substring(0, 10)}...' : name;
                                    })(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: kHeight * 0.011,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isMuted)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: _SmallMuteBadge(
                              fontSize: kHeight * 0.0075,
                              iconSize: kHeight * 0.010,
                              compact: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      })
          .toList();

      return Stack(
        children: [
          // 🎥 Main broadcaster view
          mainView,

          // 👥 ছোট broadcaster preview গুলো bottom-right এ floating style এ
          if (smallBroadcasters.isNotEmpty)
            Positioned(
              bottom: kHeight * 0.15, // স্ক্রিনের নিচ থেকে 10px
              right: 10, // ডান দিক থেকে 10px
              child: Column(
                mainAxisSize: MainAxisSize.min,
                verticalDirection:
                VerticalDirection.up, // নিচ থেকে উপরে সাজাবে
                children: smallBroadcasters,
              ),
            ),
        ],
      );
    });
  }

  Widget _pkAgoraSyncWatcher() {
    return Obx(() {
      final bool pkRunning = liveController.pkIsRunning.value;
      final String pkChannel = liveController.pkChannelName.value.trim();
      final bool pkJoining = liveController.pkAgoraJoining.value;

      if (!pkRunning) {
        if (_wasInPkChannel && !_normalReturnInProgress) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await _returnToNormalAgoraChannelIfNeeded();
          });
        }
        _lastSyncedPkChannel = '';
        _pkSyncScheduled = false;
        return const SizedBox.shrink();
      }

      if (pkChannel.isEmpty) {
        _lastSyncedPkChannel = '';
        _pkSyncScheduled = false;
        return const SizedBox.shrink();
      }

      if (!pkJoining &&
          !_pkSyncScheduled &&
          _lastSyncedPkChannel != pkChannel) {
        _pkSyncScheduled = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          await _syncPkAgoraChannelState();

          _lastSyncedPkChannel = pkChannel;
          _pkSyncScheduled = false;
        });
      }

      return const SizedBox.shrink();
    });
  }
  Future<void> _syncPkAgoraChannelState() async {
    if (!mounted) return;

    final pkRunning = liveController.pkIsRunning.value;
    final pkChannel = liveController.pkChannelName.value.trim();

    if (pkRunning && pkChannel.isNotEmpty) {
      await _joinPkAgoraChannelIfNeeded(pkChannel);
      return;
    }

    if (!pkRunning && _wasInPkChannel) {
      await _returnToNormalAgoraChannelIfNeeded();
    }
  }

  Future<String> _generateAgoraTokenForChannel({
    required String channelName,
    required int uid,
    required bool isBroadcaster,
  }) async {
    try {
      final int pkId = liveController.currentPkId.value;

      await liveController.agoraTokenController.tryToGenerateBroadcasterToken(
        isBroadcaster: isBroadcaster,
        userId: uid,
        channelName: channelName,
        streamId: _safeStreamId().toString(),
        pkId: pkId > 0 ? pkId : null,
      );

      final String token = liveController.agoraTokenController.getTokenString();
      final String appId = liveController.agoraTokenController.getAppIdString();
      final String tokenChannel =
      liveController.agoraTokenController.getChannelNameString();

      debugPrint(
        '✅ PK token generated => appId=$appId channel=$tokenChannel pkId=$pkId uid=$uid',
      );

      if (token.isEmpty) {
        debugPrint('❌ PK token empty');
        return '';
      }

      return token;
    } catch (e) {
      debugPrint('⚠️ PK token generate failed => $e');
      return '';
    }
  }

  Future<void> _joinPkAgoraChannelIfNeeded(String pkChannel) async {
    final String safePkChannel = pkChannel.trim();

    if (safePkChannel.isEmpty) {
      debugPrint('❌ PK Agora join failed: pkChannel empty');
      return;
    }

    final engine = _agoraService.engine;
    if (engine == null) {
      debugPrint('❌ PK Agora join failed: engine null');
      return;
    }

    final int currentUserId =
        authController.userProfile.value.user?.id?.toInt() ?? 0;

    if (currentUserId == 0) {
      debugPrint('❌ PK Agora join failed: currentUserId 0');
      return;
    }

    final bool isPkHost =
        currentUserId == liveController.pkSenderHostId.value ||
            currentUserId == liveController.pkReceiverHostId.value;

    final String joinKey = '$safePkChannel-$currentUserId-$isPkHost';

    /// Already same PK channel e thakle abar join korbo na
    if (_activeAgoraChannel == safePkChannel && _lastPkJoinKey == joinKey) {
      debugPrint('⚠️ PK Agora join skipped: already joined => $joinKey');
      return;
    }

    /// Join already running hole skip
    if (_pkJoinInProgress || liveController.pkAgoraJoining.value) {
      debugPrint('⚠️ PK Agora join skipped: join already running');
      return;
    }

    _pkJoinInProgress = true;
    liveController.pkAgoraJoining.value = true;

    try {
      debugPrint(
        '🚀 PK Agora join start => channel=$safePkChannel uid=$currentUserId host=$isPkHost pkId=${liveController.currentPkId.value}',
      );

      /// 1. PK channel er token generate.
      /// Important: _generateAgoraTokenForChannel() er vitore pkId pathate hobe.
      final String pkToken = await _generateAgoraTokenForChannel(
        channelName: safePkChannel,
        uid: currentUserId,
        isBroadcaster: isPkHost,
      );

      if (pkToken.trim().isEmpty) {
        debugPrint('❌ PK Agora join stopped: token empty');
        return;
      }

      final String tokenAppId =
      liveController.agoraTokenController.getAppIdString();
      final String tokenChannel =
      liveController.agoraTokenController.getChannelNameString();

      debugPrint('✅ PK token appId => $tokenAppId');
      debugPrint('✅ PK token channel => $tokenChannel');

      /// Optional warning. App ID mismatch hole remote ashbe na.
      /// Ei App ID ta AgoraService er appId er sathe same hote hobe.
      if (tokenChannel.isNotEmpty && tokenChannel != safePkChannel) {
        debugPrint(
          '❌ PK token channel mismatch => token=$tokenChannel expected=$safePkChannel',
        );
        return;
      }

      /// 2. Old channel leave
      try {
        await engine.leaveChannel();
        _pkVideoRenderVersion++;
        debugPrint('✅ Old Agora channel left before PK join');
      } catch (e) {
        debugPrint('⚠️ leaveChannel before PK join ignored => $e');
      }

      _pkRemoteUids.clear();
      _setAllSpeakingOff();

      /// Camera/audio release korte small delay helpful
      await Future.delayed(const Duration(milliseconds: 350));

      /// 3. Agora config
      await engine.setChannelProfile(
        ChannelProfileType.channelProfileLiveBroadcasting,
      );

      await engine.enableAudio();
      await engine.enableVideo();

      await engine.enableAudioVolumeIndication(
        interval: 300,
        smooth: 3,
        reportVad: true,
      );

      await engine.setClientRole(
        role: isPkHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );

      if (isPkHost) {
        await engine.enableLocalVideo(true);
        await engine.muteLocalVideoStream(false);
        await engine.muteLocalAudioStream(false);

        /// Host hole preview start korte hobe
        try {
          await engine.startPreview();
        } catch (e) {
          debugPrint('⚠️ startPreview ignored => $e');
        }
      } else {
        await engine.enableLocalVideo(false);
        await engine.muteLocalVideoStream(true);
        await engine.muteLocalAudioStream(true);
      }

      /// 4. Speaker on
      try {
        await engine.setEnableSpeakerphone(true);
      } catch (e) {
        debugPrint('⚠️ setEnableSpeakerphone ignored => $e');
      }

      /// 5. Join PK channel
      await engine.joinChannel(
        token: pkToken,
        channelId: safePkChannel,
        uid: currentUserId,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: isPkHost
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          publishCameraTrack: isPkHost,
          publishMicrophoneTrack: isPkHost,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      /// joinChannel call success hole state set
      _activeAgoraChannel = safePkChannel;
      _lastPkJoinKey = joinKey;
      _wasInPkChannel = true;
      _pkVideoRenderVersion++;

      debugPrint(
        '✅ PK Agora join called => channel=$safePkChannel uid=$currentUserId host=$isPkHost',
      );
    } catch (e) {
      debugPrint('❌ PK Agora join error => $e');

      /// Error hole state reset, jate next time abar try korte pare
      if (_activeAgoraChannel == safePkChannel) {
        _activeAgoraChannel = '';
      }
      if (_lastPkJoinKey == joinKey) {
        _lastPkJoinKey = '';
      }
    } finally {
      _pkJoinInProgress = false;
      liveController.pkAgoraJoining.value = false;
      _scheduleUIUpdate();
    }
  }



  Future<void> _returnToNormalAgoraChannelIfNeeded() async {
    final engine = _agoraService.engine;
    if (engine == null || _normalReturnInProgress) return;

    final normalChannel = liveController.normalAgoraChannelName.trim().isNotEmpty
        ? liveController.normalAgoraChannelName.trim()
        : widget.channelName;

    final currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (normalChannel.isEmpty || currentUserId == 0) return;

    _normalReturnInProgress = true;
    try {
      debugPrint('↩️ Returning to normal Agora channel => $normalChannel');

      String normalToken = '';

      /// Always generate a fresh normal-live token after PK ends.
      /// This avoids using the PK token for normal channel and fixes audience
      /// not seeing/hearing host after PK end.
      try {
        await liveController.agoraTokenController.tryToGenerateBroadcasterToken(
          isBroadcaster: widget.isBroadcaster,
          userId: currentUserId,
          channelName: normalChannel,
          streamId: _safeStreamId().toString(),
          pkId: null,
        );

        normalToken = liveController.agoraTokenController.getTokenString();
      } catch (e) {
        debugPrint('⚠️ Normal token refresh failed => $e');
      }

      if (normalToken.trim().isEmpty) {
        normalToken = liveController.normalAgoraToken.isNotEmpty
            ? liveController.normalAgoraToken
            : widget.token;
      }

      await engine.leaveChannel();
      _pkVideoRenderVersion++;
      _pkRemoteUids.clear();
      _setAllSpeakingOff();

      await Future.delayed(const Duration(milliseconds: 550));

      await engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
      await engine.enableAudio();
      await engine.enableVideo();
      await engine.setClientRole(
        role: widget.isBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );

      if (widget.isBroadcaster) {
        await engine.enableLocalVideo(true);
        await engine.enableLocalAudio(true);
        await engine.muteLocalVideoStream(false);
        await engine.muteLocalAudioStream(false);
        await engine.startPreview();
      } else {
        await engine.enableLocalVideo(false);
        await engine.muteLocalVideoStream(true);
        await engine.muteLocalAudioStream(true);
      }

      await engine.joinChannel(
        token: normalToken,
        channelId: normalChannel,
        uid: currentUserId,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: widget.isBroadcaster
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          publishCameraTrack: widget.isBroadcaster,
          publishMicrophoneTrack: widget.isBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      _activeAgoraChannel = normalChannel;
      _lastPkJoinKey = '';
      _wasInPkChannel = false;
      _lastSyncedPkChannel = '';
      _pkSyncScheduled = false;
      _pkVideoRenderVersion++;
      debugPrint('✅ Returned to normal Agora channel => $normalChannel');
    } catch (e) {
      debugPrint('❌ Return normal Agora error => $e');
    } finally {
      _normalReturnInProgress = false;
      _scheduleUIUpdate();
    }
  }

  void _setAllSpeakingOff() {
    for (final timer in _speakingOffTimers.values) {
      timer.cancel();
    }
    _speakingOffTimers.clear();
    _speakingUserIds.clear();
  }

  /// Helper function to get list of native views

  List<Widget> _getRenderViews({required List<dynamic> listActive}) {
    final List<StatefulWidget> list = [];
    final List activeCallersData = [];

    for (var activeCallData in listActive) {
      if (activeCallData == null || activeCallData is! Map) {
        continue;
      }

      final Map<String, dynamic> activeMap = _safeMap(activeCallData);
      int uid = _safeUserId(activeMap);
      if (uid <= 0) {
        uid = _safeInt(activeMap['uid'] ?? activeMap['caller_id'] ?? activeMap['user_id']);
      }
      if (uid <= 0) {
        debugPrint('⚠️ Render view skipped: missing uid/user => $activeMap');
        continue;
      }

      if (uid.toString() == widget.channelName) {
        if (widget.isBroadcaster) {
          activeCallersData.insert(0, activeCallData);
          list.insert(
            0,
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _agoraService.engine!,
                canvas: VideoCanvas(uid: 0), // Local broadcaster always uid: 0
              ),
            ),
          );
        } else {
          activeCallersData.insert(0, activeCallData);
          list.insert(
            0,
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _agoraService.engine!,
                canvas: VideoCanvas(uid: uid),
                connection: RtcConnection(channelId: _activeAgoraChannelForVideo()),
              ),
            ),
          );
        }
      } else {
        if (uid == authController.userProfile.value.user!.id!) {
          _agoraService.engine!.setClientRole(
            role: ClientRoleType.clientRoleBroadcaster,
          );

          /// Accepted call hole local user-ke audio/video publish korte hobe.
          /// Eta na thakle broadcaster accept korleo caller-er camera/kotha jabe na.
          final callStatus =
              activeMap['call_status']?.toString().toLowerCase() ?? '';
          final isAcceptedCall =
              callStatus == 'accepted' || callStatus == 'joined';

          if (isAcceptedCall) {
            _agoraService.engine!.enableAudio();
            _agoraService.engine!.muteLocalAudioStream(false);

            if (activeMap['call_type'] == 'video' ||
                activeMap['video_on'] == 1 ||
                activeMap['video_on'].toString() == '1') {
              _agoraService.engine!.enableVideo();
              _agoraService.engine!.enableLocalVideo(true);
              _agoraService.engine!.muteLocalVideoStream(false);
              _agoraService.engine!.startPreview();
            }

            print(
              '✅ Local caller media enabled => type: ${activeMap['call_type']}, video_on: ${activeMap['video_on']}, audio_on: ${activeMap['audio_on']}',
            );
          }

          activeCallersData.add(activeCallData);
          list.add(
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _agoraService.engine!,
                canvas: VideoCanvas(uid: 0),
              ),
            ),
          );
        } else {
          activeCallersData.add(activeCallData);
          list.add(
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _agoraService.engine!,
                canvas: VideoCanvas(uid: uid),
                connection: RtcConnection(channelId: _activeAgoraChannelForVideo()),
              ),
            ),
          );
        }
      }
    }

    return list;
  }

  int _safeStreamId() {
    final direct = int.tryParse((streamInfo['id'] ?? liveController.streamId.value).toString()) ?? 0;
    if (direct > 0) return direct;
    final arg = Get.arguments;
    if (arg is Map) {
      final live = arg['livestreamdata'] ?? arg['livestream'] ?? arg['data'];
      if (live is Map) {
        return int.tryParse((live['id'] ?? live['livestream_id'] ?? 0).toString()) ?? 0;
      }
      return int.tryParse((arg['id'] ?? arg['livestream_id'] ?? 0).toString()) ?? 0;
    }
    return liveController.streamId.value;
  }

  String _activeAgoraChannelForVideo() {
    return liveController.pkIsRunning.value && liveController.pkChannelName.value.trim().isNotEmpty
        ? liveController.pkChannelName.value.trim()
        : (_activeAgoraChannel.isNotEmpty ? _activeAgoraChannel : widget.channelName);
  }

  Widget _premiumPkGradientBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xff850038),
              Color(0xff46106f),
              Color(0xff1231a0),
              Color(0xff006eea),
            ],
            stops: [0.0, .35, .68, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-.95, -.75),
                    radius: 1.05,
                    colors: [
                      const Color(0xffff2d75).withValues(alpha: .55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(.95, -.65),
                    radius: 1.15,
                    colors: [
                      const Color(0xff00c8ff).withValues(alpha: .48),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: .10,
                child: CustomPaint(
                  painter: _PkGridPatternPainter(),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: .08)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pkSpeakingBars(bool active, {bool leftSide = true}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: active ? 1 : .38,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) {
          final double height = active ? (8 + (index.isEven ? 7 : 13)).toDouble() : 6;
          return AnimatedContainer(
            duration: Duration(milliseconds: 170 + (index * 45)),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.symmetric(horizontal: 1.6),
            width: 3.2,
            height: height,
            decoration: BoxDecoration(
              color: active
                  ? (leftSide ? const Color(0xffffe66d) : const Color(0xff7dfffb))
                  : Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? [
                BoxShadow(
                  color: (leftSide ? const Color(0xffffe66d) : const Color(0xff7dfffb)).withValues(alpha: .55),
                  blurRadius: 8,
                ),
              ]
                  : null,
            ),
          );
        }),
      ),
    );
  }


  int _pkToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse('${value ?? 0}') ?? 0;
  }

  Map<String, dynamic> _pkAsMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _pkAsList(dynamic value) {
    if (value is List) return value;
    return const <dynamic>[];
  }

  Map<String, dynamic> _pkUserFromLiveData(Map<String, dynamic> liveData) {
    final callers = _pkAsList(liveData['livestream_callers']);
    if (callers.isNotEmpty) {
      final first = _pkAsMap(callers.first);
      final user = _pkAsMap(first['user']);
      if (user.isNotEmpty) return user;
    }

    final user = _pkAsMap(liveData['user']);
    if (user.isNotEmpty) return user;

    return <String, dynamic>{};
  }

  Map<String, dynamic> _pkSenderUser() {
    final data = _pkAsMap(liveController.currentPkData);
    final nested = _pkAsMap(data['data']);

    final direct = _pkAsMap(data['sender_host']);
    if (direct.isNotEmpty) return direct;

    final nestedDirect = _pkAsMap(nested['sender_host']);
    if (nestedDirect.isNotEmpty) return nestedDirect;

    final live = _pkAsMap(data['sender_livestream']).isNotEmpty
        ? _pkAsMap(data['sender_livestream'])
        : (_pkAsMap(nested['sender_livestream']).isNotEmpty
        ? _pkAsMap(nested['sender_livestream'])
        : _pkAsMap(liveController.pkSenderLiveData));
    final fromLive = _pkUserFromLiveData(live);
    if (fromLive.isNotEmpty) return fromLive;

    final broadcasterUser = _pkAsMap(broadcasterData['user']);
    if (_pkToInt(broadcasterUser['id']) == liveController.pkSenderHostId.value) {
      return broadcasterUser;
    }

    final int hostId = liveController.pkSenderHostId.value > 0
        ? liveController.pkSenderHostId.value
        : _pkToInt(data['sender_host_id'] ?? nested['sender_host_id']);

    return <String, dynamic>{
      'id': hostId,
      'user_id': hostId,
      'name': hostId > 0 ? 'Host $hostId' : 'Host',
      'profile_image': null,
    };
  }

  Map<String, dynamic> _pkReceiverUser() {
    final data = _pkAsMap(liveController.currentPkData);
    final nested = _pkAsMap(data['data']);

    final direct = _pkAsMap(data['receiver_host']);
    if (direct.isNotEmpty) return direct;

    final nestedDirect = _pkAsMap(nested['receiver_host']);
    if (nestedDirect.isNotEmpty) return nestedDirect;

    final live = _pkAsMap(data['receiver_livestream']).isNotEmpty
        ? _pkAsMap(data['receiver_livestream'])
        : (_pkAsMap(nested['receiver_livestream']).isNotEmpty
        ? _pkAsMap(nested['receiver_livestream'])
        : _pkAsMap(liveController.pkReceiverLiveData));
    final fromLive = _pkUserFromLiveData(live);
    if (fromLive.isNotEmpty) return fromLive;

    final broadcasterUser = _pkAsMap(broadcasterData['user']);
    if (_pkToInt(broadcasterUser['id']) == liveController.pkReceiverHostId.value) {
      return broadcasterUser;
    }

    final int hostId = liveController.pkReceiverHostId.value > 0
        ? liveController.pkReceiverHostId.value
        : _pkToInt(data['receiver_host_id'] ?? nested['receiver_host_id']);

    return <String, dynamic>{
      'id': hostId,
      'user_id': hostId,
      'name': hostId > 0 ? 'Host $hostId' : 'Opponent',
      'profile_image': null,
    };
  }

  bool _joinedStreamIsSenderSide() {
    final int joinedStreamId = _safeStreamId();
    final int senderStreamId = liveController.pkSenderLivestreamId.value;
    final int receiverStreamId = liveController.pkReceiverLivestreamId.value;

    if (joinedStreamId > 0 && senderStreamId > 0 && joinedStreamId == senderStreamId) {
      return true;
    }
    if (joinedStreamId > 0 && receiverStreamId > 0 && joinedStreamId == receiverStreamId) {
      return false;
    }

    final int currentUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
    if (_isSamePkHost(currentUid: currentUserId, hostId: liveController.pkSenderHostId.value)) {
      return true;
    }
    if (_isSamePkHost(currentUid: currentUserId, hostId: liveController.pkReceiverHostId.value)) {
      return false;
    }

    return true;
  }

  Map<String, dynamic> _pkDisplaySide({required bool rightSide}) {
    // Right side is always OUR/JOINED side. Left side is always the opponent.
    final bool joinedIsSender = _joinedStreamIsSenderSide();
    final bool useSender = rightSide ? joinedIsSender : !joinedIsSender;

    final int senderScore = liveController.pkSenderScore.value;
    final int receiverScore = liveController.pkReceiverScore.value;

    final int senderViewerCount = liveController.pkSenderViewerCount.value;
    final int receiverViewerCount = liveController.pkReceiverViewerCount.value;

    if (useSender) {
      return <String, dynamic>{
        'is_sender_side': true,
        'host_id': liveController.pkSenderHostId.value,
        'stream_id': liveController.pkSenderLivestreamId.value,
        'score': senderScore,
        'viewer_count': senderViewerCount,
        'user': _pkSenderUser(),
        'side_label': rightSide ? 'OUR SIDE' : 'OTHER SIDE',
      };
    }

    return <String, dynamic>{
      'is_sender_side': false,
      'host_id': liveController.pkReceiverHostId.value,
      'stream_id': liveController.pkReceiverLivestreamId.value,
      'score': receiverScore,
      'viewer_count': receiverViewerCount,
      'user': _pkReceiverUser(),
      'side_label': rightSide ? 'OUR SIDE' : 'OTHER SIDE',
    };
  }

  String _pkProfileImageUrl(Map<String, dynamic> user) {
    final raw = '${user['profile_image'] ?? ''}'.trim();
    if (raw.isEmpty || raw == 'null') return '';
    return raw.startsWith('http') ? raw : ImageHelper.getImageUrl(raw);
  }

  Widget _pkBlurProfilePlaceholder(
      Map<String, dynamic> user, {
        String label = 'Connecting camera...',
        bool waiting = false,
      }) {
    final String imageUrl = _pkProfileImageUrl(user);
    final String name = '${user['name'] ?? 'Host'}';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(color: Colors.black.withValues(alpha: .36)),
            ),
          )
        else
          Container(color: Colors.black.withValues(alpha: .36)),
        Container(color: Colors.black.withValues(alpha: .44)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withValues(alpha: .18),
                backgroundImage: imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: Colors.white, size: 34)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                waiting ? 'Waiting for host...' : label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pkVideoForHost({
    required int hostId,
    required String label,
    required bool leftSide,
    required Map<String, dynamic> user,
    required int score,
    required int viewerCount,
  }) {
    final engine = _agoraService.engine;
    final channelId = _activeAgoraChannelForVideo();
    final currentUid = authController.userProfile.value.user?.id?.toInt() ?? 0;
    final int remoteAgoraUid = _pkAgoraRenderUidFromHostId(hostId);
    final bool isLocalHost = _isSamePkHost(currentUid: currentUid, hostId: hostId) && widget.isBroadcaster;
    final bool remoteOnline = isLocalHost || _isPkRemoteHostOnline(hostId);

    final bool isSpeaking = _isUserSpeaking(hostId) ||
        _isUserSpeaking(remoteAgoraUid) ||
        (isLocalHost && _isUserSpeaking(currentUid));

    Widget video;
    if (engine == null || channelId.isEmpty || hostId <= 0) {
      video = _pkBlurProfilePlaceholder(user);
    } else if (isLocalHost) {
      video = AgoraVideoView(
        key: ValueKey('pk_local_video_${channelId}_${currentUid}_$_pkVideoRenderVersion'),
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else if (!remoteOnline) {
      video = _pkBlurProfilePlaceholder(user, waiting: true);
    } else {
      video = AgoraVideoView(
        key: ValueKey('pk_remote_video_${channelId}_${remoteAgoraUid}_$_pkVideoRenderVersion'),
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: remoteAgoraUid),
          connection: RtcConnection(channelId: channelId),
        ),
      );
    }

    final Color sideColor = leftSide ? const Color(0xffff2d75) : const Color(0xff27a7ff);
    final Color glowColor = isSpeaking ? (leftSide ? const Color(0xffffe66d) : const Color(0xff7dfffb)) : sideColor;
    final String name = '${user['name'] ?? 'Host'}';
    final String uid = '${user['user_id'] ?? user['id'] ?? hostId}';

    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: leftSide ? -0.18 : 0.18, end: 0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (_, dx, child) => Transform.translate(
          offset: Offset(dx * Get.width, 0),
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: kHeight * 0.345,

          padding: EdgeInsets.all(isSpeaking ? 1 : .3),
          decoration: BoxDecoration(

            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glowColor.withValues(alpha: isSpeaking ? .98 : .88),
                sideColor.withValues(alpha: .75),
                Colors.white.withValues(alpha: .22),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: isSpeaking ? .45 : .22),
                blurRadius: isSpeaking ? 24 : 13,
                spreadRadius: isSpeaking ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(

            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.black),
                video,
                if (isSpeaking)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: SpeakingCardWave(borderRadius: 1),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .08),
                            Colors.transparent,
                            Colors.black.withValues(alpha: .50),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: leftSide ? 8 : null,
                  right: leftSide ? null : 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .48),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: .22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!leftSide) _pkSpeakingBars(isSpeaking, leftSide: leftSide),
                        if (!leftSide) const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                          ),
                        ),
                        if (leftSide) const SizedBox(width: 6),
                        if (leftSide) _pkSpeakingBars(isSpeaking, leftSide: leftSide),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .48),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: .18)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white.withValues(alpha: .18),
                          backgroundImage: _pkProfileImageUrl(user).isNotEmpty
                              ? CachedNetworkImageProvider(_pkProfileImageUrl(user))
                              : null,
                          child: _pkProfileImageUrl(user).isEmpty
                              ? const Icon(Icons.person_rounded, color: Colors.white, size: 13)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10.4,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'ID $uid',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 8.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: leftSide
                                  ? [const Color(0xffff1744), const Color(0xffff8a00)]
                                  : [const Color(0xff00c8ff), const Color(0xff0077ff)],
                            ),
                          ),
                          child: Text(
                            '$score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealPkVideoOverlay() {
    final leftSide = _pkDisplaySide(rightSide: false); // opponent
    final rightSide = _pkDisplaySide(rightSide: true); // our joined side

    final int leftScore = _pkToInt(leftSide['score']);
    final int rightScore = _pkToInt(rightSide['score']);
    final int total = (leftScore + rightScore) <= 0 ? 1 : (leftScore + rightScore);

    final int leftFlex = ((leftScore / total) * 1000).round().clamp(1, 999).toInt();
    final int rightFlex = (1000 - leftFlex).clamp(1, 999).toInt();

    final leftUser = _pkAsMap(leftSide['user']);
    final rightUser = _pkAsMap(rightSide['user']);

    return IgnorePointer(
      ignoring: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _pkVideoForHost(
                hostId: _pkToInt(leftSide['host_id']),
                label: 'OTHER SIDE',
                leftSide: true,
                user: leftUser,
                score: leftScore,
                viewerCount: _pkToInt(leftSide['viewer_count']),
              ),
              _pkVideoForHost(
                hostId: _pkToInt(rightSide['host_id']),
                label: 'OUR SIDE',
                leftSide: false,
                user: rightUser,
                score: rightScore,
                viewerCount: _pkToInt(rightSide['viewer_count']),
              ),
            ],
          ),
          // Transform.translate(
          //   offset: const Offset(0, -20),
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(999),
          //       gradient: const LinearGradient(colors: [Color(0xffff2d75), Color(0xff7a4dff), Color(0xff27a7ff)]),
          //       border: Border.all(color: Colors.white.withOpacity(.30)),
          //       boxShadow: [BoxShadow(color: Colors.black.withOpacity(.32), blurRadius: 15, offset: const Offset(0, 5))],
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Container(
          //           height: 25,
          //           width: 25,
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             color: Colors.white.withOpacity(.16),
          //           ),
          //           child: const Center(
          //             child: Text('PK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
          //           ),
          //         ),
          //         const SizedBox(width: 8),
          //         Obx(() => Text(
          //           liveController.pkFormattedRemainingTime,
          //           style: GoogleFonts.poppins(
          //             color: Colors.white,
          //             fontWeight: FontWeight.w900,
          //             fontSize: 13,
          //             letterSpacing: .2,
          //           ),
          //         )),
          //         if (widget.isBroadcaster) ...[
          //           const SizedBox(width: 10),
          //           GestureDetector(
          //             onTap: () => liveController.endPk(),
          //             child: Container(
          //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          //               decoration: BoxDecoration(
          //                 color: Colors.white.withOpacity(.18),
          //                 borderRadius: BorderRadius.circular(999),
          //                 border: Border.all(color: Colors.white.withOpacity(.18)),
          //               ),
          //               child: const Text(
          //                 'End',
          //                 style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ],
          //     ),
          //   ),
          // ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: .16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [
                    Expanded(
                      flex: leftFlex,
                      child: Container(
                        height: 14,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xffff005d), Color(0xffff8a00)]),
                        ),
                        child: Text(
                          'Other $leftScore',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    Container(width: 2, height: 14, color: Colors.white.withValues(alpha: .9)),
                    Expanded(
                      flex: rightFlex,
                      child: Container(
                        height: 14,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xff00c8ff), Color(0xff0077ff)]),
                        ),
                        child: Text(
                          'Our $rightScore',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPkStartIntroOverlay() {
    return Obx(() {
      if (!liveController.pkStartIntroVisible.value) {
        return const SizedBox.shrink();
      }

      return Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('pk_start_${liveController.currentPkId.value}_${liveController.pkStartIntroText.value}'),
              tween: Tween<double>(begin: .50, end: 1.10),
              duration: const Duration(milliseconds: 680),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xffff1744),
                      Color(0xff6a00ff),
                      Color(0xff00b8ff),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: .35), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: .55),
                      blurRadius: 38,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: .35),
                      blurRadius: 48,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  liveController.pkStartIntroText.value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPkBigCountdownOverlay() {
    return Obx(() {
      final int sec = liveController.pkRemainingSeconds.value;
      if (!liveController.pkIsRunning.value || sec <= 0 || sec > 3) {
        return const SizedBox.shrink();
      }

      return Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('pk_big_countdown_$sec'),
              tween: Tween<double>(begin: .35, end: 1.22),
              duration: const Duration(milliseconds: 720),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: (1.35 - scale).clamp(.0, 1.0).toDouble(),
                    child: Text(
                      '$sec',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 118,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Color(0xffff2d75), blurRadius: 34),
                          Shadow(color: Color(0xff27a7ff), blurRadius: 44),
                        ],
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

  Widget _buildPkResultPreviewOverlay() {
    return Obx(() {
      if (!liveController.pkResultVisible.value) {
        return const SizedBox.shrink();
      }

      final String controllerText = liveController.pkResultText.value.trim().toUpperCase();
      final String dataText = '${liveController.pkResultData['result_text'] ?? ''}'.trim().toUpperCase();
      final String text = controllerText.isNotEmpty ? controllerText : (dataText.isNotEmpty ? dataText : 'DRAW');

      final bool isDraw = text == 'DRAW';
      final bool win = text == 'WIN';

      final IconData icon = isDraw
          ? Icons.handshake_rounded
          : win
          ? Icons.emoji_events_rounded
          : Icons.heart_broken_rounded;

      final List<Color> colors = isDraw
          ? [const Color(0xffffb300), const Color(0xffff6f00)]
          : win
          ? [const Color(0xff00d084), const Color(0xff00b8ff)]
          : [const Color(0xffff1744), const Color(0xff6a00ff)];

      return Positioned.fill(
        child: IgnorePointer(
          child: Container(
            color: Colors.black.withValues(alpha: .18),
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('pk_result_$text'),
                tween: Tween(begin: .72, end: 1.0),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutBack,
                builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(colors: colors),
                    border: Border.all(color: Colors.white.withValues(alpha: .34), width: 1.4),
                    boxShadow: [
                      BoxShadow(color: colors.first.withValues(alpha: .52), blurRadius: 35, spreadRadius: 3),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 42),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  //Pk match

  Future giftBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xff16261c),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // **Premium Banner**
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff24a177),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: Icon(Icons.close, color: Colors.red),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // **Title**
            Text(
              "Choose Your Gift 🎁",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),

            // **Gift GridView**
            Obx(() {
              return livestreamController.giftList.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "No gifts available 😔",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisExtent: 120,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: livestreamController.giftList.length,
                  itemBuilder: (context, index) {
                    final gift = livestreamController.giftList[index];
                    bool isSelected =
                        livestreamController.selectedGiftId.value ==
                            gift['id'];
                    return GestureDetector(
                      onTap: () {
                        livestreamController.selectedGiftId.value =
                        gift['id'];
                        setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(0xff16261c)
                              : Color(0xff16261c),
                          border: Border.all(
                            color: isSelected
                                ? Color(0xff24a177)
                                : Color(0xff16261c),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // **Gift Image**
                            gift['gift_image'].toString().endsWith(
                              '.svga',
                            )
                                ? SizedBox(
                              height: kHeight * 0.05,
                              width: kHeight * 0.05,
                              child: SVGAEasyPlayer(
                                resUrl:
                                "$kDomainUrl/${gift['gift_image']}",
                                fit: BoxFit.cover,
                              ),
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                              child: Image.network(
                                "$kDomainUrl/${gift['gift_image']}",
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 8),

                            // **Gift Name**
                            Text(
                              gift['name'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),

                            // **Gift Coin Price**
                            Center(
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Image(
                                    image: AssetImage(
                                      'assets/icons/coin.png',
                                    ),
                                    height: 10,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    "${gift['coin']}  ",
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            SizedBox(height: 16),

            Obx(() {
              return livestreamController.selectedGiftId.value != 0
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      livestreamController.tryToSendGift(
                        receiverId:
                        livestreamController.broadcasterId.value,
                        giftId: livestreamController.selectedGiftId.value,
                        giftPrice:
                        int.tryParse(
                          authController.userProfile.value.user!.coins
                              .toString(),
                        ) ??
                            0,
                      );

                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 1,
                        horizontal: 10,
                      ),
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        "Send",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : SizedBox();
            }),
          ],
        ),
      ),
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


class _PkGridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = .55;

    const double gap = 18;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpeakingCardWave extends StatefulWidget {
  final double borderRadius;

  const SpeakingCardWave({
    super.key,
    required this.borderRadius,
  });

  @override
  State<SpeakingCardWave> createState() => _SpeakingCardWaveState();
}

class _SpeakingCardWaveState extends State<SpeakingCardWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _spread;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..repeat(reverse: true);

    _spread = Tween<double>(begin: 1.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacity = Tween<double>(begin: .70, end: .22).animate(
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
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: _opacity.value),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: _opacity.value * .55),
                  blurRadius: 18,
                  spreadRadius: _spread.value,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SmallMuteBadge extends StatelessWidget {
  final double fontSize;
  final double iconSize;
  final bool compact;

  const _SmallMuteBadge({
    required this.fontSize,
    required this.iconSize,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: .65),
          width: .6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_off,
            color: Colors.white,
            size: iconSize,
          ),
          if (!compact) ...[
            const SizedBox(width: 3),
            Text(
              'Mute',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassCallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final Color shadowColor;
  final VoidCallback onTap;

  const _GlassCallButton({
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: kHeight * 0.062,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glass shine overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: kHeight * 0.031,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: kHeight * 0.016,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.4,
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
}
