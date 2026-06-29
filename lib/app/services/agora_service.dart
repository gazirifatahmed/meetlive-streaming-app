import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import '../../constants/constants.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isFrontCamera =
  true; // Track camera direction (true = front, false = back)



  // =================== LIVE PERFORMANCE GUARDS ===================
  // These prevent repeated Agora SDK calls from build/resume/event loops.
  ClientRoleType? _lastClientRole;
  bool? _lastLocalAudioMuted;
  bool? _lastLocalVideoMuted;
  bool? _lastLocalVideoEnabled;
  String? _joinedChannelId;
  int? _joinedUid;
  bool _isJoiningChannel = false;

  // Queued effects to apply once engine is ready
  BeautyOptions? _queuedBeauty;
  bool _queuedBeautyEnabled = false;
  ColorEnhanceOptions? _queuedColor;
  bool _queuedColorEnabled = false;

  // final String appId = "4d68656dc95447fc97b709a5321482bd";

  // Getters
  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isFrontCamera => _isFrontCamera;

  // Initialize the engine (singleton pattern)
  Future<bool> initializeEngine() async {
    // If already initialized, return true
    if (_isInitialized && _engine != null) {
      print('Agora engine already initialized');
      return true;
    }

    // If currently initializing, wait for it to complete
    if (_isInitializing) {
      print('Agora engine is currently initializing, waiting...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    try {
      _isInitializing = true;

      // Defer camera/microphone permission requests until user actually enters a live session.
      // No permission prompt or camera usage at app start.

      // Create and initialize engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: appId));

      // Configure video settings
      await _engine!.enableVideo();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 650,
        ),
      );

      // Do NOT start preview automatically; preview will start only when entering a live session.

      _isInitialized = true;
      _isInitializing = false;

      print('Agora engine initialized successfully');
      // Apply any queued effects selected before engine init
      await _applyQueuedEffects();
      return true;
    } catch (e) {
      print('Error initializing Agora engine: $e');
      _isInitialized = false;
      _isInitializing = false;
      return false;
    }
  }

  // Stop preview (useful when switching between screens)
  Future<void> stopPreview() async {
    if (_engine != null && _isInitialized) {
      await _engine!.stopPreview();
      print('Agora preview stopped');
    }
  }

  // Start preview (useful when switching between screens)
  Future<void> startPreview() async {
    // Preview should only be started explicitly from live screens,
    // and only after permissions are granted and user opted in.
    if (_engine != null && _isInitialized) {
      await _engine!.startPreview();
      print('Agora preview started');
    }
  }

  // Join channel for live streaming
  Future<void> joinChannel(String channelName, int uid) async {
    if (_engine != null && _isInitialized) {
      await _engine!.joinChannel(
        token:
        "", // Use empty string for testing, implement token server for production
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(),
      );
      print('Joined channel: $channelName with uid: $uid');
    }
  }

  // Leave channel
  Future<void> leaveChannel() async {
    if (_engine != null && _isInitialized) {
      await _engine!.leaveChannel();
      _joinedChannelId = null;
      _joinedUid = null;
      _lastClientRole = null;
      _lastLocalAudioMuted = null;
      _lastLocalVideoMuted = null;
      _lastLocalVideoEnabled = null;
      debugPrint('Left channel');
    }
  }

  // Dispose the engine (call this when app is closing)
  Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
      _isInitializing = false;
      print('Agora engine disposed');
    }
  }

  // Toggle audio
  Future<void> toggleAudio(bool enabled) async {
    if (_engine != null && _isInitialized) {
      if (enabled) {
        await _engine!.enableAudio();
        await _engine!.muteLocalAudioStream(false);
      } else {
        await _engine!.muteLocalAudioStream(true);
      }
      print('Audio ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // Toggle video
  Future<void> toggleVideo(bool enabled) async {
    if (_engine != null && _isInitialized) {
      if (enabled) {
        await _engine!.enableLocalVideo(true);
        await _engine!.muteLocalVideoStream(false);
      } else {
        await _engine!.muteLocalVideoStream(true);
      }
      print('Video ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  Future<void> flipCamera() async {
    if (_engine != null && _isInitialized) {
      try {
        // Switch camera direction
        await _engine!.switchCamera();

        // Update the camera state
        _isFrontCamera = !_isFrontCamera;

        print('Camera flipped to ${_isFrontCamera ? 'front' : 'back'} camera');
      } catch (e) {
        print('Error flipping camera: $e');
      }
    } else {
      print('Cannot flip camera: Engine not initialized');
    }
  }

  Future<void> enableVideo(bool enabled) async {
    if (_engine != null && _isInitialized) {
      if (enabled) {
        await _engine!.enableLocalVideo(true);
        await _engine!.muteLocalVideoStream(false);
      } else {
        await _engine!.muteLocalVideoStream(true);
      }
      print('Video ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // =================== VIDEO EFFECTS / BEAUTY HELPERS ===================
  /// Preset types to make choosing filters easy (Bigo-like)
  static const _defaultBeauty = BeautyOptions(
    lighteningContrastLevel: LighteningContrastLevel.lighteningContrastLow,
    lighteningLevel: 0.3,
    smoothnessLevel: 0.4,
    rednessLevel: 0.2,
    sharpnessLevel: 0.2,
  );

  Future<void> disableAllVideoEffects() async {
    if (_engine == null || !_isInitialized) {
      // Queue disable so it applies when engine becomes ready
      _queuedBeauty = _defaultBeauty;
      _queuedBeautyEnabled = false;
      _queuedColor = const ColorEnhanceOptions();
      _queuedColorEnabled = false;
      debugPrint('🔧 Queued disable effects (engine not ready)');
      return;
    }
    try {
      await _engine!
          .setBeautyEffectOptions(enabled: false, options: _defaultBeauty);
      // Guard these APIs for SDK versions; catch if unsupported.
      try {
        await _engine!.setColorEnhanceOptions(
            enabled: false, options: const ColorEnhanceOptions());
      } catch (_) {}
      debugPrint('🔧 Agora effects disabled');
    } catch (e) {
      debugPrint('Agora disable effects error: $e');
    }
  }

  Future<void> setBeautyNatural() async {
    await _applyBeauty(const BeautyOptions(
      lighteningContrastLevel: LighteningContrastLevel.lighteningContrastLow,
      lighteningLevel: 0.35,
      smoothnessLevel: 0.45,
      rednessLevel: 0.20,
      sharpnessLevel: 0.25,
    ));
  }

  Future<void> setBeautySmooth() async {
    await _applyBeauty(const BeautyOptions(
      lighteningContrastLevel: LighteningContrastLevel.lighteningContrastNormal,
      lighteningLevel: 0.45,
      smoothnessLevel: 0.70,
      rednessLevel: 0.18,
      sharpnessLevel: 0.20,
    ));
  }

  Future<void> setBeautyGlossy() async {
    await _applyBeauty(const BeautyOptions(
      lighteningContrastLevel: LighteningContrastLevel.lighteningContrastHigh,
      lighteningLevel: 0.60,
      smoothnessLevel: 0.60,
      rednessLevel: 0.35,
      sharpnessLevel: 0.30,
    ));
  }

  Future<void> setBeautyRosy() async {
    await _applyBeauty(const BeautyOptions(
      lighteningContrastLevel: LighteningContrastLevel.lighteningContrastNormal,
      lighteningLevel: 0.40,
      smoothnessLevel: 0.55,
      rednessLevel: 0.60,
      sharpnessLevel: 0.25,
    ));
  }

  /// Blemish/acne softening preset (approximation using smoothing)
  Future<void> setBeautyBlemish() async {
    await _applyBeauty(const BeautyOptions(
      lighteningContrastLevel: LighteningContrastLevel.lighteningContrastNormal,
      lighteningLevel: 0.50,
      smoothnessLevel: 0.80,
      rednessLevel: 0.22,
      sharpnessLevel: 0.35,
    ));
  }

  Future<void> setBeautyHD() async {
    await _applyBeauty(const BeautyOptions(
      lighteningContrastLevel: LighteningContrastLevel.lighteningContrastHigh,
      lighteningLevel: 0.50,
      smoothnessLevel: 0.50,
      rednessLevel: 0.20,
      sharpnessLevel: 0.70,
    ));
  }

  /// Custom beauty with sliders
  Future<void> setBeautyCustom({
    LighteningContrastLevel contrast =
        LighteningContrastLevel.lighteningContrastNormal,
    double lightening = 0.4,
    double smoothness = 0.5,
    double redness = 0.2,
    double sharpness = 0.2,
  }) async {
    await _applyBeauty(BeautyOptions(
      lighteningContrastLevel: contrast,
      lighteningLevel: lightening.clamp(0.0, 1.0),
      smoothnessLevel: smoothness.clamp(0.0, 1.0),
      rednessLevel: redness.clamp(0.0, 1.0),
      sharpnessLevel: sharpness.clamp(0.0, 1.0),
    ));
  }

  Future<void> _applyBeauty(BeautyOptions options) async {
    if (_engine == null || !_isInitialized) {
      _queuedBeauty = options;
      _queuedBeautyEnabled = true;
      debugPrint('🎨 Queued beauty preset: $options');
      return;
    }
    try {
      await _engine!.setBeautyEffectOptions(enabled: true, options: options);
      debugPrint('🎨 Applied beauty: $options');
    } catch (e) {
      debugPrint('Agora beauty apply error: $e');
    }
  }

  // Optional extra tweaks
  Future<void> setColorEnhance(
      {double strength = 0.4, double skinProtect = 0.3}) async {
    if (_engine == null || !_isInitialized) {
      _queuedColor = ColorEnhanceOptions(
        strengthLevel: strength.clamp(0.0, 1.0),
        skinProtectLevel: skinProtect.clamp(0.0, 1.0),
      );
      _queuedColorEnabled = true;
      debugPrint(
          '🌈 Queued color enhance: strength=$strength, skin=$skinProtect');
      return;
    }
    try {
      await _engine!.setColorEnhanceOptions(
        enabled: true,
        options: ColorEnhanceOptions(
          strengthLevel: strength.clamp(0.0, 1.0),
          skinProtectLevel: skinProtect.clamp(0.0, 1.0),
        ),
      );
      debugPrint('🌈 Color enhance set: strength=$strength, skin=$skinProtect');
    } catch (e) {
      debugPrint('Agora color enhance error: $e');
    }
  }

  Future<void> _applyQueuedEffects() async {
    if (_engine == null || !_isInitialized) return;
    try {
      if (_queuedBeauty != null) {
        await _engine!.setBeautyEffectOptions(
            enabled: _queuedBeautyEnabled, options: _queuedBeauty!);
        debugPrint('✅ Applied queued beauty');
      }

      if (_queuedColor != null) {
        await _engine!.setColorEnhanceOptions(
            enabled: _queuedColorEnabled, options: _queuedColor!);
        debugPrint('✅ Applied queued color enhance');
      }

      // Clear queue
      _queuedBeauty = null;
      _queuedColor = null;
      _queuedBeautyEnabled = false;
      _queuedColorEnabled = false;
    } catch (e) {
      debugPrint('Error applying queued effects: $e');
    }
  }

  // =================== SAFE LIVE HELPERS ===================
  /// Use this instead of calling engine.setClientRole repeatedly from UI/build.
  Future<void> setClientRoleSafe(ClientRoleType role) async {
    if (_engine == null || !_isInitialized) return;
    if (_lastClientRole == role) return;

    try {
      await _engine!.setClientRole(role: role);
      _lastClientRole = role;
      debugPrint('✅ Agora role set safely: $role');
    } catch (e) {
      debugPrint('❌ Agora setClientRoleSafe error: $e');
    }
  }

  Future<void> muteLocalAudioSafe(bool mute) async {
    if (_engine == null || !_isInitialized) return;
    if (_lastLocalAudioMuted == mute) return;

    try {
      await _engine!.muteLocalAudioStream(mute);
      _lastLocalAudioMuted = mute;
    } catch (e) {
      debugPrint('❌ Agora muteLocalAudioSafe error: $e');
    }
  }

  Future<void> enableLocalVideoSafe(bool enabled) async {
    if (_engine == null || !_isInitialized) return;
    if (_lastLocalVideoEnabled == enabled) return;

    try {
      await _engine!.enableLocalVideo(enabled);
      _lastLocalVideoEnabled = enabled;
    } catch (e) {
      debugPrint('❌ Agora enableLocalVideoSafe error: $e');
    }
  }

  Future<void> muteLocalVideoSafe(bool mute) async {
    if (_engine == null || !_isInitialized) return;
    if (_lastLocalVideoMuted == mute) return;

    try {
      await _engine!.muteLocalVideoStream(mute);
      _lastLocalVideoMuted = mute;
    } catch (e) {
      debugPrint('❌ Agora muteLocalVideoSafe error: $e');
    }
  }

  /// Prevent duplicate joinChannel calls when page rebuilds/resumes.
  Future<void> joinChannelSafe({
    required String token,
    required String channelId,
    required int uid,
    required ClientRoleType role,
    bool force = false,
    bool? publishCameraTrack,
    bool? publishMicrophoneTrack,
    bool autoSubscribeAudio = true,
    bool autoSubscribeVideo = true,
  }) async {
    if (_engine == null || !_isInitialized) return;

    if (_isJoiningChannel) {
      debugPrint('⏳ Agora join already running, skip');
      return;
    }

    final bool isBroadcaster = role == ClientRoleType.clientRoleBroadcaster;

    if (!force && _joinedChannelId == channelId && _joinedUid == uid) {
      await setClientRoleSafe(role);
      if (isBroadcaster) {
        await enableLocalVideoSafe(publishCameraTrack ?? true);
        await muteLocalAudioSafe(!(publishMicrophoneTrack ?? true));
        await muteLocalVideoSafe(!(publishCameraTrack ?? true));
      } else {
        await enableLocalVideoSafe(false);
        await muteLocalAudioSafe(true);
        await muteLocalVideoSafe(true);
      }
      debugPrint('✅ Agora already joined same channel, skip join');
      return;
    }

    _isJoiningChannel = true;

    try {
      if (_joinedChannelId != null &&
          (_joinedChannelId != channelId || _joinedUid != uid || force)) {
        await _engine!.leaveChannel();
        _joinedChannelId = null;
        _joinedUid = null;
        _lastClientRole = null;
        _lastLocalAudioMuted = null;
        _lastLocalVideoMuted = null;
        _lastLocalVideoEnabled = null;
      }

      await _engine!.enableAudio();
      await _engine!.enableVideo();
      await _engine!.setClientRole(role: role);

      if (isBroadcaster) {
        await _engine!.enableLocalVideo(publishCameraTrack ?? true);
        await _engine!.muteLocalVideoStream(!(publishCameraTrack ?? true));
        await _engine!.muteLocalAudioStream(!(publishMicrophoneTrack ?? true));
        _lastLocalVideoEnabled = publishCameraTrack ?? true;
        _lastLocalVideoMuted = !(publishCameraTrack ?? true);
        _lastLocalAudioMuted = !(publishMicrophoneTrack ?? true);
      } else {
        await _engine!.enableLocalVideo(false);
        await _engine!.muteLocalVideoStream(true);
        await _engine!.muteLocalAudioStream(true);
        _lastLocalVideoEnabled = false;
        _lastLocalVideoMuted = true;
        _lastLocalAudioMuted = true;
      }

      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: role,
          publishCameraTrack: publishCameraTrack ?? isBroadcaster,
          publishMicrophoneTrack: publishMicrophoneTrack ?? isBroadcaster,
          autoSubscribeAudio: autoSubscribeAudio,
          autoSubscribeVideo: autoSubscribeVideo,
        ),
      );

      _joinedChannelId = channelId;
      _joinedUid = uid;
      _lastClientRole = role;
      debugPrint('✅ Agora joined safely: channel=$channelId uid=$uid role=$role');
    } catch (e) {
      debugPrint('❌ Agora joinChannelSafe error: $e');
    } finally {
      _isJoiningChannel = false;
    }
  }

  Future<void> joinPkChannelSafe({
    required String token,
    required String channelId,
    required int uid,
    required bool isBroadcaster,
    bool force = true,
  }) async {
    await joinChannelSafe(
      token: token,
      channelId: channelId,
      uid: uid,
      role: isBroadcaster
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
      force: force,
      publishCameraTrack: isBroadcaster,
      publishMicrophoneTrack: isBroadcaster,
      autoSubscribeAudio: true,
      autoSubscribeVideo: true,
    );
  }

  bool get isJoinedChannel => _joinedChannelId != null;
  String? get joinedChannelId => _joinedChannelId;
  int? get joinedUid => _joinedUid;

}
