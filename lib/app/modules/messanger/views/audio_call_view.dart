import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../auth/controllers/auth_controller.dart';

class AudioCallView extends StatefulWidget {
  final String channelName;
  final bool isBroadcaster;
  final String token;
  final dynamic profile;
  final bool isOutGoingCall;

  const AudioCallView({
    super.key,
    required this.profile,
    this.isOutGoingCall = false,
    required this.channelName,
    required this.isBroadcaster,
    required this.token,
  });

  @override
  State<AudioCallView> createState() => _AudioCallViewState();
}

class _AudioCallViewState extends State<AudioCallView> {
  final receiverData = Get.arguments;
  final AuthController authController = Get.find<AuthController>(); // ✅ Fixed

  RtcEngine? engine;
  int? _remoteUid;
  bool muted = false;
  bool isSpeakerOn = true;
  bool isJoined = false;
  Duration _callDuration = Duration.zero;
  Timer? _callTimer;

  // ✅ Ringing system
// ✅ AudioPlayer replace করো
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRinging = false;

  @override
  void initState() {
    super.initState();
    initializeAgora();

    // ✅ Outgoing call হলে রিং শুরু
    if (widget.isOutGoingCall) {
      _startRinging();
    }
  }

  // ✅ রিং শুরু — loop করবে
  Future<void> _startRinging() async {
    try {
      _isRinging = true;
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('video/callSound.mp3'));
    } catch (e) {
      print('Ringing error: $e');
    }
  }

  // ✅ রিং বন্ধ
  Future<void> _stopRinging() async {
    if (_isRinging) {
      _isRinging = false;
      await _audioPlayer.stop();
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration += Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> initializeAgora() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission denied');
      }

      engine = createAgoraRtcEngine();
      await engine!.initialize(RtcEngineContext(appId: appId));

      await engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      await engine!.enableAudio();
      await engine!
          .setChannelProfile(ChannelProfileType.channelProfileCommunication);

      setupEventHandlers();

      int userId =
          authController.userProfile.value.user!.id!.toInt(); // ✅ Fixed
      await engine!.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: userId,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      print("Error initializing Agora: $e");
      Get.snackbar("Error", "Failed to initialize audio call: ${e.toString()}");
      Future.delayed(Duration(seconds: 2), () => Get.back());
    }
  }

  void setupEventHandlers() {
    engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print("🎉 Joined channel successfully");
        if (mounted) setState(() => isJoined = true);
        _startCallTimer(); // ✅ join হলে timer শুরু
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        print("👤 Remote user joined: $remoteUid");
        _stopRinging(); // ✅ user join করলে রিং বন্ধ
        if (mounted) setState(() => _remoteUid = remoteUid);
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        print("🚫 Remote user left: $remoteUid");
        if (mounted) setState(() => _remoteUid = null);
        _endCall();
      },
      onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid,
          RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
        print("Remote audio state changed: $state");
      },
      onError: (ErrorCodeType err, String msg) {
        print("Error: $err, $msg");
        Get.snackbar("Error", "Audio call error: $msg");
      },
    ));
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _stopRinging(); // ✅ রিং বন্ধ
    _audioPlayer.dispose(); // ✅ player dispose
    engine?.leaveChannel();
    engine?.release();
    engine = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1a1a2e),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMainView(),
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: CircleAvatar(
              radius: 80,
              backgroundImage: CachedNetworkImageProvider(
                  '$kDomainUrl/${receiverData['profile_image']}'),
            ),
          ),
          SizedBox(height: 24),

          // Name
          Text(
            receiverData['name'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),

          // Status
          Text(
            _remoteUid != null
                ? "Connected"
                : widget.isOutGoingCall
                    ? "Calling..."
                    : "Connecting...",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          SizedBox(height: 10),

          // Duration — শুধু connected হলে দেখাবে
          if (_remoteUid != null)
            Text(
              "${_callDuration.inMinutes.toString().padLeft(2, '0')}:"
              "${(_callDuration.inSeconds % 60).toString().padLeft(2, '0')}",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),

          // Loading spinner — connecting এর সময়
          if (_remoteUid == null) ...[
            SizedBox(height: 20),
            SpinKitChasingDots(
              size: 40,
              color: kPrimaryColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: muted ? Icons.mic_off : Icons.mic,
            color: muted ? Colors.red : Colors.white,
            backgroundColor: Colors.white12,
            onPressed: _toggleMicrophone,
          ),

          // End call
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.white,
            backgroundColor: Colors.red,
            isLarge: true,
            onPressed: _endCall,
          ),

          // Speaker
          _buildControlButton(
            icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            color: isSpeakerOn ? kPrimaryColor : Colors.white,
            backgroundColor: Colors.white12,
            onPressed: _toggleSpeaker,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return Container(
      width: isLarge ? 68 : 56,
      height: isLarge ? 68 : 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: isLarge ? 32 : 26, color: color),
        onPressed: onPressed,
      ),
    );
  }

  void _toggleMicrophone() {
    if (mounted) setState(() => muted = !muted);
    engine?.muteLocalAudioStream(muted);
  }

  void _toggleSpeaker() {
    if (mounted) setState(() => isSpeakerOn = !isSpeakerOn);
    engine?.setEnableSpeakerphone(isSpeakerOn);
  }

  Future<void> _endCall() async {
    try {
      _stopRinging(); // ✅ call কাটলে রিং বন্ধ
      await engine?.leaveChannel();
      Get.back();
    } catch (e) {
      print("Error ending call: $e");
      Get.back();
    }
  }
}
