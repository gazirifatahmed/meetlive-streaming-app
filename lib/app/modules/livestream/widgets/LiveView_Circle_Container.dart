import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/livestream_controller.dart';
import '../controllers/websocket_controller.dart';

class LiveViewCircle_container extends StatelessWidget {
  final int seatNo;
  final Map data;

  LiveViewCircle_container({
    super.key,
    required this.data,
    required this.seatNo,
  });

  final LivestreamController livestreamController = Get.find();
  final WebsocketController websocketController = Get.find();
  final AuthController authController = Get.find();

  bool get isLockedSeat => websocketController.isSeatLocked(seatNo) || _seatLockedFromData();

  String _truncateName(String name, int maxLength) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength)}..';
  }

  bool _truthyLocal(dynamic value) {
    final v = value?.toString().toLowerCase().trim() ?? '';
    return v == '1' ||
        v == 'true' ||
        v == 'yes' ||
        v == 'y' ||
        v == 'locked' ||
        v == 'lock' ||
        v == 'mute' ||
        v == 'muted';
  }

  bool _falseyLocal(dynamic value) {
    final v = value?.toString().toLowerCase().trim() ?? '';
    return v == '0' ||
        v == 'false' ||
        v == 'no' ||
        v == 'n' ||
        v == 'off' ||
        v == 'unlocked' ||
        v == 'unlock' ||
        v == 'unmute' ||
        v == 'unmuted';
  }

  bool _seatLockedFromData() {
    final lockValue = data['is_locked'] ??
        data['locked'] ??
        data['seat_locked'] ??
        data['lock_status'];
    return _truthyLocal(lockValue);
  }

  bool _isAudioMuted(Map seatData) {
    final rawUserId = seatData['user'] is Map
        ? seatData['user']['id']
        : (seatData['user_id'] ?? seatData['caller_id'] ?? seatData['id']);
    final int userId = int.tryParse(rawUserId?.toString() ?? '0') ?? 0;

    /// Websocket known state has highest priority so unrelated seat events
    /// cannot reset mute icon incorrectly.
    if (userId > 0 && websocketController.audioMutedUserMap.containsKey(userId)) {
      return websocketController.audioMutedUserMap[userId] == true;
    }

    final audioOn = seatData['audio_on'] ??
        seatData['is_audio_on'] ??
        seatData['mic_on'] ??
        seatData['microphone_on'];

    final muted = seatData['is_muted'] ??
        seatData['muted'] ??
        seatData['is_muted_by_host'] ??
        seatData['mute_status'];

    if (_falseyLocal(audioOn)) return true;
    if (_truthyLocal(muted)) return true;

    return false;
  }

  Map<String, dynamic> _safeUserMap() {
    if (data['user'] is Map) {
      return Map<String, dynamic>.from(data['user']);
    }

    final fallbackId = data['caller_id'] ?? data['user_id'] ?? data['id'];
    return {
      'id': fallbackId,
      'user_id': fallbackId,
      'name': data['name'] ?? data['user_name'] ?? (fallbackId == null ? 'User' : 'User $fallbackId'),
      'profile_image': data['profile_image'] ?? data['avatar'] ?? '',
      'level': data['level'] ?? 0,
      'asset_purchase_history': data['asset_purchase_history'],
    };
  }

  Future<void> _handleSeatTap() async {
    final bool isBroadcaster = livestreamController.isBroadcaster.value;

    /// Occupied seat => show profile only.
    if (data.isNotEmpty) {
      final user = _safeUserMap();
      final userId = user['id'] ?? data['caller_id'] ?? data['user_id'] ?? data['id'];
      if (userId != null) {
        homeController.liveVisitProfile(
          userId: '$userId',
          seatData: data,
        );
      }
      return;
    }

    /// Empty locked seat.
    if (isLockedSeat) {
      if (isBroadcaster) {
        _showSeatOptionSheet();
      } else {
        Fluttertoast.showToast(msg: 'This seat is locked');
      }
      return;
    }

    /// Audience can join only unlocked empty seat.
    if (!isBroadcaster) {
      final availableSeats = await livestreamController.getAvailableSeats(
        livestreamController.streamId.value,
      );

      if (availableSeats != null) {
        try {
          websocketController.syncSeatLocksFromAnyPayload(
            Map<String, dynamic>.from(availableSeats),
            allowUnlock: false,
            source: 'available_seats_tap',
          );
        } catch (e) {
          debugPrint('Seat lock sync from availableSeats failed: $e');
        }
      }

      final List availableSeatList = availableSeats?['available_seats'] is List
          ? availableSeats!['available_seats'] as List
          : [];

      final List lockedSeatList = availableSeats?['locked_seats'] is List
          ? availableSeats!['locked_seats'] as List
          : [];

      final bool lockedFromApi = lockedSeatList
          .map((e) => e.toString())
          .contains(seatNo.toString());

      if (lockedFromApi || isLockedSeat) {
        websocketController.updateSeatLockStatus(
          seatNo: seatNo,
          isLocked: true,
          source: 'available_seats_tap_locked',
        );
        Fluttertoast.showToast(msg: 'This seat is locked');
        return;
      }

      if (availableSeatList.map((e) => e.toString()).contains(seatNo.toString())) {
        final userId = authController.userProfile.value.user?.id?.toInt() ?? 0;

        final alreadyInMic = websocketController.liveCallList.any((call) {
          final callerId = call['caller_id'];
          final callUserId = call['user']?['id'];
          return callerId.toString() == userId.toString() ||
              callUserId.toString() == userId.toString();
        });

        if (!alreadyInMic) {
          await livestreamController.tryToCallLivestream(
            streamId: livestreamController.streamId.value,
            callerId: userId,
            callType: 'audio',
            seatNO: seatNo,
          );

          try {
            await livestreamController.tryToGetCallList(
              streamId: livestreamController.streamId.value,
            );
            websocketController.liveCallList.refresh();
          } catch (e) {
            debugPrint('Audio seat call list refresh failed: $e');
          }
        } else {
          /// Already on a mic seat => switch directly to selected empty seat.
          /// Backend will broadcast action_type: seat_switched so everyone updates.
          await livestreamController.switchAudioSeat(
            livestreamId: livestreamController.streamId.value,
            toSeatNo: seatNo,
          );
        }
      } else {
        Fluttertoast.showToast(msg: 'Seat is not available');
      }
      return;
    }

    /// Broadcaster gets lock/unlock option only.
    _showSeatOptionSheet();
  }

  void _showSeatOptionSheet() {
    if (!livestreamController.isBroadcaster.value) return;

    Get.bottomSheet(
      Container(
        margin: EdgeInsets.symmetric(horizontal: kWeight * 0.025),
        height: kHeight * 0.25,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            SizedBox(height: kHeight * 0.015),
            _sheetItem('Invite', () {}),
            Obx(
                  () {
                final locked = isLockedSeat;
                return _sheetItem(
                  locked ? 'Unlock seat' : 'Lock seat',
                      () async {
                    Get.back();
                    final wasLocked = isLockedSeat;
                    await livestreamController.toggleSeatLock(
                      livestreamId: livestreamController.streamId.value,
                      seatNo: seatNo,
                    );

                    /// Keep UI stable immediately after host action.
                    /// The websocket event/API refresh will confirm the same state.
                    websocketController.updateSeatLockStatus(
                      seatNo: seatNo,
                      isLocked: !wasLocked,
                      source: wasLocked ? 'manual_unlock_after_api' : 'manual_lock_after_api',
                    );
                  },
                );
              },
            ),
            _sheetItem('Cancel', () => Get.back(), showBorder: false),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(String title, VoidCallback onTap, {bool showBorder = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: kHeight * 0.012),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: .3),
              width: 1,
            ),
          )
              : null,
        ),
        child: Castontext(
          fontWeight: FontWeight.w500,
          textColor: Colors.black.withValues(alpha: .9),
          fontSize: kHeight * 0.02,
          text: title,
        ),
      ),
    );
  }


  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  dynamic _pickFirst(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty && value.toString() != 'null') {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic> _normalizeImogiPayload(dynamic rawItem) {
    Map<String, dynamic> map = _toMap(rawItem);

    /// Some websocket handlers store payload inside data/payload.
    final innerData = _toMap(map['data']);
    if (innerData.isNotEmpty && (innerData['action_type'] != null || innerData['sender'] != null || innerData['imogi'] != null || innerData['emoji'] != null)) {
      map = innerData;
    }

    final innerPayload = _toMap(map['payload']);
    if (innerPayload.isNotEmpty && (innerPayload['action_type'] != null || innerPayload['sender'] != null || innerPayload['imogi'] != null || innerPayload['emoji'] != null)) {
      map = innerPayload;
    }

    return map;
  }

  Map<String, dynamic>? _activeImogiForUser(dynamic rawUserId) {
    final userId = rawUserId?.toString() ?? '';
    if (userId.isEmpty || userId == 'null') return null;

    for (final rawItem in websocketController.liveImogiAnimations.reversed) {
      final map = _normalizeImogiPayload(rawItem);

      final sender = _toMap(map['sender']);
      final user = _toMap(map['user']);

      final senderId = _pickFirst(sender, ['id', 'user_id', 'caller_id']) ??
          _pickFirst(user, ['id', 'user_id', 'caller_id']) ??
          _pickFirst(map, [
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

  String _safeImogiImage(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'null' || raw == 'file:///') return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return ImageHelper.getImageUrl(raw);
  }

  Widget _seatImogiOverlay(dynamic rawUserId) {
    return Obx(() {
      final item = _activeImogiForUser(rawUserId);
      if (item == null) return const SizedBox.shrink();

      final imogi = _toMap(item['imogi']);
      final emoji = _toMap(item['emoji']);
      final giftLike = _toMap(item['gift']);

      final image = _safeImogiImage(
        _pickFirst(imogi, [
          'image',
          'icon',
          'imogi_image',
          'emoji_image',
          'show_image',
          'url',
          'file',
        ]) ??
            _pickFirst(emoji, [
              'image',
              'icon',
              'imogi_image',
              'emoji_image',
              'show_image',
              'url',
              'file',
            ]) ??
            _pickFirst(giftLike, [
              'image',
              'icon',
              'imogi_image',
              'emoji_image',
              'show_image',
              'url',
              'file',
            ]) ??
            _pickFirst(item, [
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

      return IgnorePointer(
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
                height: kHeight * 0.050,
                width: kHeight * 0.050,
                padding: EdgeInsets.all(kHeight * 0.004),
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
                child: CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _emptySeat() {
    /// Parent slot e height kom thakleo overflow korbe na.
    /// FittedBox full Column-ke scale kore slot-er moddhe fit kore.
    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
                  () {
                final bool locked = isLockedSeat;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: kHeight * 0.055,
                  width: kHeight * 0.055,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: locked
                          ? [
                        const Color(0xff4B3A5E).withValues(alpha: .90),
                        const Color(0xff2F2442).withValues(alpha: .80),
                      ]
                          : [
                        const Color(0xff6f547f).withValues(alpha: .90),
                        const Color(0xff9277a5).withValues(alpha: .75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    locked
                        ? 'assets/logo/padlock (1).png'
                        : 'assets/audio_live/sit.png',
                    height: kHeight * 0.026,
                    width: kHeight * 0.026,
                    color: Colors.white70,
                  ),
                );
              },
            ),
            SizedBox(height: kHeight * 0.008),
            Obx(
                  () => Text(
                isLockedSeat ? 'Locked' : 'Join',
                style: GoogleFonts.roboto(
                  fontSize: kHeight * 0.0105,
                  color: Colors.white.withValues(alpha: .85),
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _occupiedSeat() {
    final user = _safeUserMap();
    final name = _truncateName('${user['name'] ?? 'User'}', 8);
    final profile = ImageHelper.getImageUrl('${user['profile_image'] ?? ''}');
    final frameData = user['asset_purchase_history'];
    final bool muted = _isAudioMuted(data);
    final bool isSpeaking = _truthyLocal(data['is_speaking']);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: kHeight * 0.064,
            width: kHeight * 0.064,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (isSpeaking && !muted)
                  SpeakingWave(size: kHeight * 0.070),

                Container(
                  height: kHeight * 0.055,
                  width: kHeight * 0.055,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: profile,
                      placeholder: (context, url) => Container(
                        color: Colors.white.withValues(alpha: .15),
                        child: Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: kHeight * 0.025,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white.withValues(alpha: .15),
                        child: Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: kHeight * 0.025,
                        ),
                      ),
                    ),
                  ),
                ),
                if (frameData != null &&
                    frameData['asset'] != null &&
                    frameData['asset']['asset'] != null)
                  frameData['asset']['asset'].toString().endsWith('.svga')
                      ? SizedBox(
                    height: kHeight * 0.080,
                    width: kHeight * 0.080,
                    child: SVGAEasyPlayer(
                      resUrl: '$kDomainUrl/${frameData['asset']['asset']}',
                      fit: BoxFit.cover,
                    ),
                  )
                      : CachedNetworkImage(
                    imageUrl: "$kDomainUrl/${frameData['asset']['asset']}",
                    height: kHeight * 0.080,
                    width: kHeight * 0.080,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                    const SizedBox.shrink(),
                  ),
                if (muted)
                  Positioned(
                    right: 3,
                    bottom: 4,
                    child: Container(
                      height: kHeight * 0.018,
                      width: kHeight * 0.018,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: .90),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: .7),
                      ),
                      child: Icon(
                        Icons.mic_off,
                        color: Colors.white,
                        size: kHeight * 0.011,
                      ),
                    ),
                  ),
                _seatImogiOverlay(user['id'] ?? data['caller_id']),
              ],
            ),
          ),
          if (muted) ...[
            SizedBox(height: kHeight * 0.002),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: kWeight * 0.012,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .65),
                  width: .6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic_off,
                    color: Colors.white,
                    size: kHeight * 0.0085,
                  ),
                  SizedBox(width: kWeight * 0.004),
                  Text(
                    'Mute',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: kHeight * 0.0078,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: kHeight * 0.0108,
              color: Colors.white.withValues(alpha: .92),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: kHeight * 0.002),
          Container(
            padding: EdgeInsets.symmetric(horizontal: kWeight * 0.012, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/diamond-removebg-preview.png',
                  height: kHeight * 0.012,
                ),
                SizedBox(width: kWeight * 0.004),
                Text(
                  formatNumber(
                    data['earn_coins'] ??
                        data['gift_coins'] ??
                        data['received_coins'] ??
                        user['earned_coins'] ??
                        user['gifts_coins'] ??
                        0,
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: kHeight * 0.0105,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleSeatTap,
      borderRadius: BorderRadius.circular(50),
      child: SizedBox(
        width: Get.width * 0.165,
        child: data.isNotEmpty ? _occupiedSeat() : _emptySeat(),
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
