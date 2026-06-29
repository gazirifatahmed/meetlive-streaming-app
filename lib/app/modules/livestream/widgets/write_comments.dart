import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/livestream/widgets/reseableIconButton.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/message_bottom.dart';
import '../../../services/agora_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/livestream_controller.dart';
import '../controllers/websocket_controller.dart';
import 'entertainment_tools_widget.dart';
import 'gift_bottom_sheet.dart';
import 'live_imogi_bottom_sheet.dart';
import 'live_viewer_list.dart';

class WriteCommentSection extends StatefulWidget {
  RtcEngine rtcEngine;
  final String streamType;
  final RxMap broadcasterData;

  WriteCommentSection(
      {super.key, required this.rtcEngine,
        required this.streamType,
        required this.broadcasterData});

  @override
  _WriteCommentSectionState createState() => _WriteCommentSectionState();
}

class _WriteCommentSectionState extends State<WriteCommentSection> {
  final TextEditingController addComments = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();

  final LivestreamController livestreamController = Get.find();
  final WebsocketController websocketController = Get.find();
  final AuthController authController = Get.find();

  bool isTyping = false;
  bool isSwitched = false;
  bool showAnimatedMessage = false;
  bool _sendingComment = false;

  /// Local speaker/remote-audio mute.
  /// Eta shudhu ei device-er jonno kaj korbe:
  /// - mic mute hobe na
  /// - audience/caller ra apnar voice sunte parbe
  /// - apni broad-er karo voice sunben na jokhon speaker off thakbe
  bool _isBroadSpeakerMuted = false;

  Future<void> _toggleBroadSpeakerMute() async {
    final bool nextMuted = !_isBroadSpeakerMuted;

    _safeSetState(() {
      _isBroadSpeakerMuted = nextMuted;
    });

    try {
      await widget.rtcEngine.muteAllRemoteAudioStreams(nextMuted);
      await widget.rtcEngine.adjustPlaybackSignalVolume(nextMuted ? 0 : 100);

      if (!nextMuted) {
        await widget.rtcEngine.setEnableSpeakerphone(true);
        await widget.rtcEngine.setDefaultAudioRouteToSpeakerphone(true);
      }

      debugPrint('🔈 Broad speaker local mute => $nextMuted');
    } catch (e) {
      debugPrint('❌ Broad speaker mute error: $e');
      _safeSetState(() {
        _isBroadSpeakerMuted = !nextMuted;
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _syncTypingState() {
    final next = commentFocusNode.hasFocus || addComments.text.trim().isNotEmpty;
    if (next == isTyping) return;
    _safeSetState(() {
      isTyping = next;
    });
  }

  void showFlyingMessage(String message) {
    _safeSetState(() {
      showAnimatedMessage = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      _safeSetState(() {
        showAnimatedMessage = false;
      });
    });
  }

  Future<void> _sendCommentFast() async {
    final text = addComments.text.trim();

    if (text.isEmpty || _sendingComment) return;

    _sendingComment = true;

    addComments.clear();
    commentFocusNode.unfocus();
    _safeSetState(() {
      isTyping = false;
    });

    try {
      await livestreamController.tryToAddComment(comment: text);
    } catch (e) {
      debugPrint('❌ Comment send failed: $e');
    } finally {
      _sendingComment = false;
    }
  }

  @override
  void initState() {
    super.initState();

    commentFocusNode.addListener(_syncTypingState);
    addComments.addListener(_syncTypingState);
  }

  @override
  void dispose() {
    commentFocusNode.removeListener(_syncTypingState);
    addComments.removeListener(_syncTypingState);
    addComments.dispose();
    commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12, // Glass effect
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 10,
          right: 10,
          top: 5,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      // color: Colors.grey.withOpacity(0.2),
                    ),
                    child: isTyping
                        ? SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Container(
                            height: kHeight * 0.04,
                            width: kWeight * 0.18,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Stack(
                              children: [
                                // Moving background highlight
                                AnimatedAlign(
                                  duration: Duration(milliseconds: 300),
                                  alignment: isSwitched
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Container(
                                    height: 50,
                                    width: kWeight * 0.1,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                                // ON/OFF Texts
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            isSwitched = false;
                                          });
                                        },
                                        child: Center(
                                          child: Text(
                                            'OFF',
                                            style: TextStyle(
                                              fontSize: kHeight * 0.013,
                                              fontWeight: FontWeight.bold,
                                              color: isSwitched
                                                  ? Colors.red
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            isSwitched = true;
                                          });
                                        },
                                        child: Center(
                                          child: Text(
                                            'ON',
                                            style: TextStyle(
                                              fontSize: kHeight * 0.013,
                                              fontWeight: FontWeight.bold,
                                              color: isSwitched
                                                  ? Colors.black
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              cursorColor: kAppColor,
                              controller: addComments,
                              focusNode: commentFocusNode,
                              style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withValues(alpha: .7),
                                  fontSize: kHeight * 0.014),
                              textInputAction: TextInputAction.send,
                              onFieldSubmitted: (_) => _sendCommentFast(),
                              decoration: InputDecoration(
                                hintText: 'Write a comment...',
                                hintStyle: GoogleFonts.roboto(
                                    color: Colors.black.withValues(alpha: .6),
                                    fontSize: kHeight * 0.013),
                                filled: true,
                                isCollapsed: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 11,
                                    horizontal: kWeight * 0.05),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        style: IconButton.styleFrom(
                            backgroundColor:
                            Colors.white.withValues(alpha: 0.8)),
                        onPressed: () {
                          _safeSetState(() {
                            isTyping = true;
                          });
                          commentFocusNode.requestFocus();
                        },
                        icon: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [
                                kAppColor, // Gradient Start (e.g., red-pink)
                                kAppColor // Gradient End (e.g., orange)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: Image.asset(
                            'assets/frame/comment_7945005.png',
                            height: kHeight * 0.02,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: isTyping
                      ? GestureDetector(
                    key: ValueKey(1),
                    behavior: HitTestBehavior.opaque,
                    onTap: _sendCommentFast,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: LinearGradient(
                          colors: [kAppColor, kAppColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Text(
                        _sendingComment ? 'Sending...' : 'Send',
                        style: GoogleFonts.lato(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: kHeight * 0.015),
                      ),
                    ),
                  )
                      : Row(
                    key: ValueKey(2),
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      widget.streamType == "popular" ||
                          widget.streamType == "multi"
                          ? Container()
                          : message_bottom(
                        onPress: () async {
                          final livestreamController = Get.find<LivestreamController>();

                          await livestreamController.fetchImogiList();

                          showLiveImogiBottomSheet(
                            context: context,
                            streamId: livestreamController.streamId.value,
                          );
                        },
                        color2: Color(0xffffa39d),
                        image: 'assets/new/happy (1).png',
                        color: Color(0xfffe5d56),
                      ),
                      widget.streamType == "popular" &&
                          livestreamController.broadcasterId.value ==
                              authController
                                  .userProfile.value.user!.id
                          ? InkWell(
                        onTap: () {
                          // Get.bottomSheet(
                          //     isScrollControlled: true,
                          //     CustomTeamPkBottom());
                          Get.bottomSheet(
                            LiveViewerList(
                                isFromPk: true,
                                filteredList: livestreamController
                                    .liveViewerList),
                            isScrollControlled: true,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  Color(0xffc4f894),
                                  Color(0xff1dfa62),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: GradientText(
                            'PK',
                            style: GoogleFonts.lato(
                                fontSize: kHeight * 0.015,
                                fontWeight: FontWeight.bold),
                            colors: [
                              Color(0xff9644ef),
                              Color(0xffca12f3),
                              Color(0xfff81b69),
                              Color(0xfff80d0d)
                            ],
                          ),
                        ),
                      )
                          : Container(),
                      SizedBox(
                        width: kWeight * 0.025,
                      ),

                      widget.streamType == "popular" &&
                          livestreamController.broadcasterId.value ==
                              authController
                                  .userProfile.value.user!.id
                          ? InkWell(
                        onTap: () {
                          AgoraService().flipCamera();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  Color(0xffc4f894),
                                  Color(0xff1dfa62),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.cameraswitch_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : Container(),

                      SizedBox(
                        width: kWeight * 0.0,
                      ),

                      //------------------- micOff-----------

                      SizedBox(
                        width: kWeight * 0.025,
                      ),
                      // ✅ Replace your old mute button block with this full fixed block.
// Broadcaster and audience both use backend/API toggle,
// so everyone can see mute/unmute status in realtime.

                      (widget.broadcasterData['user']?['id'] != null &&
                          widget.broadcasterData['user']?['id'] ==
                              authController.userProfile.value.user?.id)
                          ? Obx(() {
                        final int userId =
                        authController.userProfile.value.user!.id!.toInt();

                        final hostCallIndex = websocketController.liveCallList.indexWhere((call) {
                          final callerId = call['caller_id'];
                          final callUserId = call['user']?['id'];
                          return callerId.toString() == userId.toString() ||
                              callUserId.toString() == userId.toString();
                        });

                        // ✅ Host mute icon priority:
                        // 1) websocket last known state
                        // 2) local livestreamController.mute
                        // 3) liveCallList audio_on fallback
                        // This prevents host from showing unmute when host is actually muted.
                        final bool knownMuted =
                            websocketController.audioMutedUserMap[userId] == true ||
                                livestreamController.mute.value == true;

                        final bool audioOn = knownMuted
                            ? false
                            : (hostCallIndex != -1
                            ? (websocketController.liveCallList[hostCallIndex]['audio_on'] == 1 ||
                            websocketController.liveCallList[hostCallIndex]['audio_on'].toString() == '1')
                            : true);

                        return message_bottom(
                          onPress: () async {
                            await livestreamController.toggleSpecificUserAudio(
                              userId,
                              rtcEngine: widget.rtcEngine,
                            );
                          },
                          color2: audioOn ? Colors.red : const Color(0xffaa5cf8),
                          image: audioOn
                              ? 'assets/audio_live/unMute.png'
                              : 'assets/audio_live/mute.png',
                          color: audioOn
                              ? Colors.grey.withValues(alpha: 0.5)
                              : const Color(0xffc4b9f6),
                        );
                      })
                          : Obx(() {
                        final int userId =
                        authController.userProfile.value.user!.id!.toInt();

                        final myCallIndex = websocketController.liveCallList.indexWhere((call) {
                          final callerId = call['caller_id'];
                          final callUserId = call['user']?['id'];
                          return callerId.toString() == userId.toString() ||
                              callUserId.toString() == userId.toString();
                        });

                        final bool knownMuted =
                            websocketController.audioMutedUserMap[userId] == true ||
                                livestreamController.mute.value == true;

                        final bool audioOn = knownMuted
                            ? false
                            : (myCallIndex != -1
                            ? (websocketController.liveCallList[myCallIndex]['audio_on'] == 1 ||
                            websocketController.liveCallList[myCallIndex]['audio_on'].toString() == '1')
                            : true);

                        return message_bottom(
                          onPress: () async {
                            // ✅ This updates Agora local mic + backend + liveCallList
                            // so all users can see this audience is muted/unmuted.
                            await livestreamController.toggleMyAudioFromAnyButton(
                              rtcEngine: widget.rtcEngine,
                            );
                          },
                          color2: const Color(0xffa35df8),
                          color: const Color(0xfff852ef),
                          image: audioOn
                              ? 'assets/audio_live/mute.png'
                              : 'assets/audio_live/mute.png',
                        );
                      }),

                      SizedBox(
                        width: kWeight * 0.025,
                      ),

                      // ✅ Local speaker off/on button.
                      // Mic mute na, shudhu ei device-e broad-er sob remote voice off/on.
                      message_bottom(
                        onPress: _toggleBroadSpeakerMute,
                        color2: _isBroadSpeakerMuted
                            ? Colors.red
                            : const Color(0xff42d392),
                        color: _isBroadSpeakerMuted
                            ? Colors.grey.withValues(alpha: 0.5)
                            : const Color(0xff2bc7ff),
                        image: _isBroadSpeakerMuted
                            ? 'assets/audio_live/mute.png':
                            'assets/audio_live/unMute.png'
                            ,
                      ),

                      SizedBox(
                        width: kWeight * 0.025,
                      ),

                      ReusableIconButton(
                        onPressed: () {
                          final liveUrl = 'https://yourapp.com/live/';
                          Share.share(
                              '🔴 I\'m live now! Watch here: $liveUrl');
                        },
                        assetImage: 'assets/icons/share.png',
                        imageHeight: kHeight * 0.02,
                        backgroundColor:
                        Color(0xffa09ea3).withValues(alpha: 0.3),
                      ),

                      widget.streamType == "popular" &&
                          livestreamController.broadcasterId.value ==
                              authController
                                  .userProfile.value.user!.id
                          ? SizedBox.shrink()
                          : SizedBox(
                        width: kWeight * 0.025,
                      ),

                      ///----------------- giftSent-------------------
                      buildGiftButton(),

                      EntertainmentToolsWidget(
                        rtcEngine: widget.rtcEngine,
                        streamType: widget.streamType,
                        isBroadcaster:
                        livestreamController.isBroadcaster.value,
                      ),

                      SizedBox(
                        width: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildGiftButton() {
    if (widget.streamType == 'popular') {
      // popular stream
      if (widget.broadcasterData['user']?['id'] ==
          authController.userProfile.value.user!.id) {
        return Container(); // নিজে হলে কিছু দেখাবে না
      } else {
        return gift_bottom_sheet(
          isbrodcaster: widget.broadcasterData,
          liveType: 'popular',
        ); // অন্য কারো হলে
      }
    } else {
      // popular না হলে
      return gift_bottom_sheet(
        isbrodcaster: widget.broadcasterData,
        liveType: 'audio',
      ); // সবসময় দেখাবে
    }
  }

  Widget _buildCallList(List callList, bool isPending) {
    return ListView.builder(
      itemCount: callList.length,
      itemBuilder: (context, index) {
        final call = callList[index];
        return call['user']['id'] == authController.userProfile.value.user!.id!
            ? Container()
            : Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(ImageHelper.getImageUrl(
                  '${call['user']['profile_image']}')),
            ),
            title: Text(call['user']['name'],
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Level: ${call['user']['level']}',
                style: TextStyle(color: Colors.grey[700])),
            trailing: isPending
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () {
                    livestreamController.tryToAcceptCall(
                      streamId: livestreamController.streamId.value,
                      userId: call['user']['id'],
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    livestreamController.tryToRejectCall(
                      streamId: livestreamController.streamId.value,
                      userId: call['user']['id'],
                    );
                  },
                ),
              ],
            )
                : IconButton(
              icon: Icon(Icons.cancel, color: Colors.redAccent),
              onPressed: () {
                livestreamController.tryToRejectCall(
                  streamId: livestreamController.streamId.value,
                  userId: call['user']['id'],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void showCallBottomSheet(BuildContext context, RtcEngine rtcEngine) {
    Get.bottomSheet(
      DefaultTabController(
        length: 2,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight * 0.5,
              width: constraints.maxWidth * 0.9,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (livestreamController.isBroadcaster.value) ...[
                            Expanded(
                              child: Column(
                                children: [
                                  TabBar(
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.white70,
                                    indicator: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.black45.withValues(alpha: 0.3),
                                    ),
                                    tabs: const [
                                      Tab(text: 'Pending Calls'),
                                      Tab(text: 'Live Calls'),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        Obx(() => _buildCallList(
                                            websocketController.pendingCall,
                                            true)),
                                        Obx(() => _buildCallList(
                                            websocketController.liveCallList,
                                            false)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Viewer buttons
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                livestreamController.tryToCallLivestream(
                                  streamId: livestreamController.streamId.value,
                                  callerId: authController
                                      .userProfile.value.user!.id!
                                      .toInt(),
                                  callType: 'video',
                                );
                                Get.back();
                              },
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/video-call_5535718.png',
                                    height: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Make a Call',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xffbf5701),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (websocketController.pendingCall.isNotEmpty ||
                                websocketController.liveCallList.isNotEmpty)
                              const SizedBox(height: 12),
                            if (websocketController.pendingCall.isNotEmpty ||
                                websocketController.liveCallList.isNotEmpty)
                              const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                await livestreamController.tryToRejectCall(
                                  streamId: livestreamController.streamId.value,
                                  userId: authController
                                      .userProfile.value.user!.id!
                                      .toInt(),
                                );

                                livestreamController.removeBroadcaster(
                                  engine: rtcEngine,
                                );
                                Get.back();
                              },
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/close_463612.png',
                                    height: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Cancel Call',
                                    style: GoogleFonts.lato(
                                      color: const Color(0xff981701),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
