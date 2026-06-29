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

class VideoCallView extends StatefulWidget {
  final String channelName;
  final bool isBroadcaster;
  final String token;
  final dynamic profile;
  final bool isOutGoingCall;

  const VideoCallView({
    super.key,
    required this.profile,
    this.isOutGoingCall = false,
    required this.channelName,
    required this.isBroadcaster,
    required this.token,
  });

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  final receiverData = Get.arguments;
  final AuthController authController = Get.find<AuthController>();

  RtcEngine? engine;
  int? _remoteUid;
  bool muted = false;
  bool videoDisabled = false;
  bool isSpeakerOn = true;
  bool isFrontCamera = true;
  bool isJoined = false;

  Duration _callDuration = Duration.zero;
  Timer? _callTimer;
  bool _isLocalPreviewMaximized = false;
  bool _isRemoteVideoMuted = false;

  // ✅ Ringing system
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRinging = false;

  @override
  void initState() {
    super.initState();
    initializeAgora();

    // ✅ Outgoing call হলে রিং শুরু করো
    // ✅ WidgetsBinding দিয়ে করো
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ আগে রিং শুরু করো
      if (widget.isOutGoingCall) {
        await _startRinging();
      }
      // ✅ তারপর Agora initialize করো
      await initializeAgora();
    });
  }

  // ✅ রিংটোন শুরু — loop করবে
  Future<void> _startRinging() async {
    try {
      _isRinging = true;

      // ✅ Agora initialize হওয়ার পর রিং বাজাও
      await Future.delayed(Duration(milliseconds: 500));

      if (!_isRinging) return; // ✅ ইতিমধ্যে বন্ধ হয়ে গেলে return

      await _audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck, // ✅ এটা দাও
        ),
      ));

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('icons/callSound.mp3'));
      print('🔔 Ringing started');
    } catch (e) {
      print('Ringing error: $e');
    }
  }

  // ✅ রিংটোন বন্ধ
  Future<void> _stopRinging() async {
    if (!_isRinging) return;
    _isRinging = false;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release(); // ✅ audio session ছেড়ে দাও
      print('🔕 Ringing stopped');
    } catch (e) {
      print('Stop ringing error: $e');
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
      final status = await [Permission.camera, Permission.microphone].request();
      if (!status[Permission.camera]!.isGranted ||
          !status[Permission.microphone]!.isGranted) {
        throw Exception('Camera/Mic permission denied');
      }

      engine = createAgoraRtcEngine();
      await engine!.initialize(RtcEngineContext(appId: appId));

      await engine!.enableVideo();
      await engine!.setVideoEncoderConfiguration(
        VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 0,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      await engine!.enableAudio();
      await engine!
          .setChannelProfile(ChannelProfileType.channelProfileCommunication);

      setupEventHandlers();

      int userId = authController.userProfile.value.user!.id!.toInt();
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
      Get.snackbar("Error", "Failed to initialize video call: ${e.toString()}");
      Future.delayed(Duration(seconds: 2), () => Get.back());
    }
  }

  void setupEventHandlers() {
    engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print("🎉 Joined channel successfully");
        if (mounted) {
          setState(() {
            isJoined = true;
          });
        }
        // ✅ Join হলে call timer শুরু করো
        _startCallTimer();
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        print("👤 Remote user joined: $remoteUid");

        // ✅ User join করলে রিং বন্ধ করো
        _stopRinging();

        if (mounted) {
          setState(() {
            _remoteUid = remoteUid;
          });
        }
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        print("🚫 Remote user left: $remoteUid");
        if (mounted) {
          setState(() {
            _remoteUid = null;
          });
        }
        _endCall();
      },
      onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid,
          RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
        if (mounted) {
          setState(() {
            _isRemoteVideoMuted =
                state == RemoteVideoState.remoteVideoStateStopped;
          });
        }
      },
      onError: (ErrorCodeType err, String msg) {
        print("❌ Agora Error[$err]: $msg");

        // ✅ Main thread এ run করো
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          // ✅ শুধু critical error এ snackbar দেখাও
          // token error, network error ছাড়া বাকিগুলো ignore করো
          if (err == ErrorCodeType.errInvalidToken ||
              err == ErrorCodeType.errTokenExpired) {
            Get.snackbar(
              "Call Error",
              "Token expired. Please try again.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            Future.delayed(Duration(seconds: 2), () => _endCall());
          } else if (err == ErrorCodeType.errJoinChannelRejected) {
            Get.snackbar(
              "Call Error",
              "Could not join call. Please try again.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            Future.delayed(Duration(seconds: 2), () => _endCall());
          }
          // ✅ অন্য error গুলো শুধু print করো, snackbar না
        });
      },
    ));
  }

  // @override
  // void dispose() {
  //   _callTimer?.cancel();
  //   _stopRinging();
  //   _audioPlayer.dispose();
  //   engine?.leaveChannel();
  //   engine?.release();
  //   engine = null;
  //   super.dispose();
  // }
  @override
  void dispose() {
    _callTimer?.cancel();
    _stopRinging();
    _audioPlayer.dispose();
    engine?.leaveChannel();
    engine?.release();
    engine = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildMainVideoView(),
            if (isJoined) _buildLocalVideoPreview(),
            _buildTopBar(),
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainVideoView() {
    if (engine == null) {
      return Center(child: _buildLoadingIndicator());
    }

    if (_remoteUid != null) {
      return GestureDetector(
        onDoubleTap: () {
          if (mounted) {
            setState(() {
              _isLocalPreviewMaximized = !_isLocalPreviewMaximized;
            });
          }
        },
        child: Stack(
          children: [
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            ),
            if (_isRemoteVideoMuted)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: CachedNetworkImageProvider(
                          '$kDomainUrl/${receiverData['profile_image']}'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      receiverData['name'] ?? '',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } else {
      return _buildWaitingView();
    }
  }

  Widget _buildWaitingView() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: CachedNetworkImageProvider(
                '$kDomainUrl/${receiverData['profile_image']}'),
          ),
          SizedBox(height: 20),
          Text(
            receiverData['name'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.isOutGoingCall ? "Calling..." : "Connecting...",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          SizedBox(height: 20),
          _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SpinKitChasingDots(
      size: 40,
      color: kPrimaryColor,
    );
  }

  Widget _buildLocalVideoPreview() {
    if (_isLocalPreviewMaximized) return SizedBox.shrink();

    return Positioned(
      right: 20,
      top: 20,
      child: GestureDetector(
        onTap: _switchCamera,
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine!,
                    canvas: VideoCanvas(uid: 0),
                  ),
                ),
                if (videoDisabled)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Icon(Icons.videocam_off, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    String formattedDuration =
        "${_callDuration.inMinutes.toString().padLeft(2, '0')}:"
        "${(_callDuration.inSeconds % 60).toString().padLeft(2, '0')}";

    return Positioned(
      top: 20,
      left: 20,
      right: 160, // local preview এর জায়গা দেওয়ার জন্য
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _remoteUid != null ? formattedDuration : "Waiting...",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: muted ? Icons.mic_off : Icons.mic,
            color: muted ? Colors.red : Colors.white,
            onPressed: _toggleMicrophone,
          ),
          _buildControlButton(
            icon: videoDisabled ? Icons.videocam_off : Icons.videocam,
            color: videoDisabled ? Colors.red : Colors.white,
            onPressed: _toggleCamera,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            isLarge: true,
            onPressed: _endCall,
          ),
          _buildControlButton(
            icon: Icons.switch_camera,
            color: Colors.white,
            onPressed: _switchCamera,
          ),
          _buildControlButton(
            icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
            onPressed: _toggleSpeaker,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return Container(
      width: isLarge ? 64 : 52,
      height: isLarge ? 64 : 52,
      decoration: BoxDecoration(
        color: isLarge ? Colors.red.withValues(alpha: 0.85) : Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: isLarge ? 30 : 24, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  void _toggleMicrophone() {
    if (mounted) setState(() => muted = !muted);
    engine?.muteLocalAudioStream(muted);
  }

  void _toggleCamera() {
    if (mounted) setState(() => videoDisabled = !videoDisabled);
    engine?.muteLocalVideoStream(videoDisabled);
  }

  void _switchCamera() {
    if (mounted) setState(() => isFrontCamera = !isFrontCamera);
    engine?.switchCamera();
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
