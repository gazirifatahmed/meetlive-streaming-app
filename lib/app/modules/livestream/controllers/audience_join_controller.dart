import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../../../constants/constants.dart';
import '../../home/controllers/home_controller.dart';
import '../../messanger/views/audio_call_view.dart';
import '../../messanger/views/video_call_view.dart';
import '../views/audio_live_view.dart';
import '../views/multi_live_view.dart';
import '../views/popular_live_view.dart';
import 'agoraTokenController.dart';
import 'livestream_controller.dart';

class AudienceJoinController extends GetxController {
  final isLoading = false.obs;

  final HomeController controller = Get.put(HomeController());
  final LivestreamController livestreamController = Get.find();
  final AgoraTokenController agoraTokenController = Get.find();

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _safeText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text == 'null') return '';
    return text;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _safeText(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  int _firstInt(List<dynamic> values) {
    for (final value in values) {
      final id = _toInt(value);
      if (id > 0) return id;
    }
    return 0;
  }

  bool _isPkLive(Map<String, dynamic> data) {
    final int pkId = _firstInt([
      data['pk_id'],
      data['current_pk_id'],
      data['pk'] is Map ? data['pk']['id'] : null,
      data['current_pk'] is Map ? data['current_pk']['id'] : null,
    ]);

    final String pkStatus = _firstText([
      data['pk_status'],
      data['pk'] is Map ? data['pk']['status'] : null,
      data['current_pk'] is Map ? data['current_pk']['status'] : null,
    ]).toLowerCase();

    final String pkChannel = _firstText([
      data['pk_channel'],
      data['pk_channel_name'],
      data['agora_pk_channel'],
      data['pk'] is Map ? data['pk']['pk_channel'] : null,
      data['pk'] is Map ? data['pk']['channel_name'] : null,
      data['current_pk'] is Map ? data['current_pk']['pk_channel'] : null,
      data['current_pk'] is Map ? data['current_pk']['channel_name'] : null,
    ]);

    final String isPk = _safeText(data['is_pk']).toLowerCase();

    return pkId > 0 ||
        pkChannel.isNotEmpty ||
        isPk == '1' ||
        isPk == 'true' ||
        pkStatus == 'running' ||
        pkStatus == 'started' ||
        pkStatus == 'active';
  }

  int _pkId(Map<String, dynamic> data) {
    return _firstInt([
      data['pk_id'],
      data['current_pk_id'],
      data['pk'] is Map ? data['pk']['id'] : null,
      data['current_pk'] is Map ? data['current_pk']['id'] : null,
    ]);
  }

  String _normalChannel(Map<String, dynamic> data) {
    return _firstText([
      data['room_id'],
      data['channel_name'],
      data['agora_channel'],
      data['channel'],
    ]);
  }

  String _pkChannel(Map<String, dynamic> data) {
    return _firstText([
      data['pk_channel'],
      data['pk_channel_name'],
      data['agora_pk_channel'],
      data['pk'] is Map ? data['pk']['pk_channel'] : null,
      data['pk'] is Map ? data['pk']['pk_channel_name'] : null,
      data['pk'] is Map ? data['pk']['channel_name'] : null,
      data['current_pk'] is Map ? data['current_pk']['pk_channel'] : null,
      data['current_pk'] is Map ? data['current_pk']['pk_channel_name'] : null,
      data['current_pk'] is Map ? data['current_pk']['channel_name'] : null,
    ]);
  }

  int _livestreamId(Map<String, dynamic> data) {
    return _firstInt([
      data['id'],
      data['livestream_id'],
      data['stream_id'],
      data['live_stream_id'],
    ]);
  }

  int _pkSenderLivestreamId(Map<String, dynamic> data, int originalLivestreamId) {
    return _firstInt([
      data['pk_sender_livestream_id'],
      data['sender_livestream_id'],
      data['from_livestream_id'],
      data['pk'] is Map ? data['pk']['sender_livestream_id'] : null,
      data['pk'] is Map ? data['pk']['from_livestream_id'] : null,
      data['current_pk'] is Map ? data['current_pk']['sender_livestream_id'] : null,
      data['current_pk'] is Map ? data['current_pk']['from_livestream_id'] : null,
      originalLivestreamId,
    ]);
  }

  int _pkReceiverLivestreamId(Map<String, dynamic> data) {
    return _firstInt([
      data['pk_receiver_livestream_id'],
      data['receiver_livestream_id'],
      data['opponent_livestream_id'],
      data['to_livestream_id'],
      data['pk'] is Map ? data['pk']['receiver_livestream_id'] : null,
      data['pk'] is Map ? data['pk']['opponent_livestream_id'] : null,
      data['pk'] is Map ? data['pk']['to_livestream_id'] : null,
      data['current_pk'] is Map ? data['current_pk']['receiver_livestream_id'] : null,
      data['current_pk'] is Map ? data['current_pk']['opponent_livestream_id'] : null,
      data['current_pk'] is Map ? data['current_pk']['to_livestream_id'] : null,
    ]);
  }

  int _pkSenderHostId(Map<String, dynamic> data) {
    return _firstInt([
      data['pk_sender_host_id'],
      data['sender_host_id'],
      data['host_id'],
      data['user_id'],
      data['user'] is Map ? data['user']['id'] : null,
      data['pk'] is Map ? data['pk']['sender_host_id'] : null,
      data['current_pk'] is Map ? data['current_pk']['sender_host_id'] : null,
    ]);
  }

  int _pkReceiverHostId(Map<String, dynamic> data) {
    return _firstInt([
      data['pk_receiver_host_id'],
      data['receiver_host_id'],
      data['opponent_host_id'],
      data['opponent_user_id'],
      data['opponent'] is Map ? data['opponent']['id'] : null,
      data['opponent'] is Map ? data['opponent']['user_id'] : null,
      data['opponent_livestream'] is Map ? data['opponent_livestream']['user_id'] : null,
      data['opponent_livestream'] is Map && data['opponent_livestream']['user'] is Map
          ? data['opponent_livestream']['user']['id']
          : null,
      data['pk'] is Map ? data['pk']['receiver_host_id'] : null,
      data['current_pk'] is Map ? data['current_pk']['receiver_host_id'] : null,
    ]);
  }

  void _syncAudiencePkState({
    required Map<String, dynamic> data,
    required int originalLivestreamId,
    required int pkId,
    required String pkChannel,
  }) {
    final int senderStreamId = _pkSenderLivestreamId(data, originalLivestreamId);
    final int receiverStreamId = _pkReceiverLivestreamId(data);
    final int senderHostId = _pkSenderHostId(data);
    final int receiverHostId = _pkReceiverHostId(data);

    livestreamController.pkModeActive.value = true;
    livestreamController.currentPkId.value = pkId;
    livestreamController.pkChannelName.value = pkChannel;

    if (senderStreamId > 0) {
      livestreamController.pkSenderLivestreamId.value = senderStreamId;
    }

    if (receiverStreamId > 0) {
      livestreamController.pkReceiverLivestreamId.value = receiverStreamId;
    }

    if (senderHostId > 0) {
      livestreamController.pkSenderHostId.value = senderHostId;
    }

    if (receiverHostId > 0) {
      livestreamController.pkReceiverHostId.value = receiverHostId;
    }

    livestreamController.currentPkData.assignAll({
      ...data,
      'is_pk': 1,
      'pk_id': pkId,
      'pk_channel': pkChannel,
      'pk_channel_name': pkChannel,
      'audience_join_livestream_id': originalLivestreamId,
      'audience_join_agora_channel': pkChannel,
      'sender_livestream_id': senderStreamId,
      'receiver_livestream_id': receiverStreamId,
      'opponent_livestream_id':
      originalLivestreamId == senderStreamId ? receiverStreamId : senderStreamId,
    });

    print('✅ Audience PK state synced');
    print('✅ pkId => $pkId');
    print('✅ pkChannel => $pkChannel');
    print('✅ senderStreamId => $senderStreamId');
    print('✅ receiverStreamId => $receiverStreamId');
    print('✅ senderHostId => $senderHostId');
    print('✅ receiverHostId => $receiverHostId');
  }

  void _clearAudiencePkStateIfNormal() {
    // Normal live join er shomoy old PK state pore thakle comment/viewer filter problem kore.
    livestreamController.pkModeActive.value = false;
    livestreamController.currentPkId.value = 0;
    livestreamController.pkChannelName.value = '';
    livestreamController.pkSenderLivestreamId.value = 0;
    livestreamController.pkReceiverLivestreamId.value = 0;
    livestreamController.pkSenderHostId.value = 0;
    livestreamController.pkReceiverHostId.value = 0;
    livestreamController.currentPkData.clear();

    print('✅ Audience normal live join: old PK state cleared');
  }

  Future<void> joinAsAudience({
    required String channelName,
    required dynamic data,
  }) async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      final Map<String, dynamic> liveData = _asMap(data);

      final int userId =
          authController.userProfile.value.user?.id?.toInt() ?? 0;

      final int originalLivestreamId = _livestreamId(liveData);
      final bool isPkRunning = _isPkLive(liveData);
      final int pkId = _pkId(liveData);

      final String normalChannel = _normalChannel(liveData).isNotEmpty
          ? _normalChannel(liveData)
          : channelName;

      final String pkJoinChannel = _pkChannel(liveData);

      // Viewer/check/addviewer always original livestream id.
      // Agora channel PK running hole pk channel, normal hole normal room/channel.
      final String finalAgoraChannel =
      isPkRunning && pkJoinChannel.isNotEmpty ? pkJoinChannel : normalChannel;

      print('================ AUDIENCE JOIN START ================');
      print('👀 userId => $userId');
      print('👀 originalLivestreamId => $originalLivestreamId');
      print('👀 isPkRunning => $isPkRunning');
      print('👀 pkId => $pkId');
      print('👀 normalChannel => $normalChannel');
      print('👀 pkJoinChannel => $pkJoinChannel');
      print('👀 finalAgoraChannel => $finalAgoraChannel');
      print('👀 liveData => $liveData');

      if (userId == 0 || originalLivestreamId == 0 || finalAgoraChannel.isEmpty) {
        Get.snackbar(
          'Error',
          'Live join data missing. Please refresh and try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final result = await livestreamController.checkCanJoinLivestream(
        originalLivestreamId,
        userId,
      );

      if (result['can_join'] != true) {
        _showKickedDialog(result['message'] ?? 'You cannot join this livestream');
        return;
      }

      // Original live state set first. PK id kokhono streamId e boshbe na.
      livestreamController.streamId.value = originalLivestreamId;
      websocketController.streamID.value = originalLivestreamId;

      if (isPkRunning) {
        _syncAudiencePkState(
          data: liveData,
          originalLivestreamId: originalLivestreamId,
          pkId: pkId,
          pkChannel: finalAgoraChannel,
        );
      } else {
        _clearAudiencePkStateIfNormal();
      }

      await livestreamController.tryToGetCallList(streamId: originalLivestreamId);

      await livestreamController.tryToAddViewer(
        streamId: originalLivestreamId,
        viewerId: userId,
      );

      await agoraTokenController.tryToGenerateBroadcasterToken(
        isBroadcaster: false,
        userId: userId,
        channelName: finalAgoraChannel,
        streamId: '$originalLivestreamId',
        pkId: isPkRunning ? pkId : null,
      );

      livestreamController.showLiveViewerListList(streamId: originalLivestreamId);

      if (agoraTokenController.agoraToken.isEmpty ||
          agoraTokenController.getTokenString().isEmpty) {
        Get.snackbar(
          'Error',
          'Failed to generate token. Please try again later.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final Map<String, dynamic> routeArguments = {
        ...liveData,
        'id': originalLivestreamId,
        'livestream_id': originalLivestreamId,
        'stream_id': originalLivestreamId,
        'room_id': normalChannel,
        'channel_name': normalChannel,
        'audience_join_livestream_id': originalLivestreamId,
        'audience_join_agora_channel': finalAgoraChannel,
        'is_pk': isPkRunning ? 1 : 0,
        if (isPkRunning) 'pk_id': pkId,
        if (isPkRunning) 'pk_channel': finalAgoraChannel,
        if (isPkRunning) 'pk_channel_name': finalAgoraChannel,
      };

      final String streamType = _safeText(liveData['stream_type']).toLowerCase();

      if (streamType == 'audio') {
        Get.to(
          AudioLiveView(
            channelName: finalAgoraChannel,
            isBroadcaster: false,
            token: agoraTokenController.getTokenString(),
            seatCount: liveData['seat_count'] ?? 6,
          ),
          arguments: routeArguments,
        );
      } else if (streamType == 'multi') {
        livestreamController.seatCount.value = liveData['seat_count'] ?? 6;

        Get.to(
          MultiLiveView(
            channelName: finalAgoraChannel,
            isBroadcaster: false,
            token: agoraTokenController.getTokenString(),
            seatCount: liveData['seat_count'] ?? 6,
          ),
          arguments: routeArguments,
        );
      } else {
        Get.to(
          PopularLiveView(
            channelName: finalAgoraChannel,
            isBroadcaster: false,
            token: agoraTokenController.getTokenString(),
          ),
          arguments: routeArguments,
        );
      }

      print('================ AUDIENCE JOIN END ==================');
    } catch (e, stack) {
      print('❌ Audience join error => $e');
      print(stack);

      Get.snackbar(
        'Error',
        'Something went wrong while joining live.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Show dialog when user is kicked and cannot join
  void _showKickedDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.block,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              "Access Denied",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "OK",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> joinAsCallReceiver({
    required String channelName,
    required dynamic data,
  }) async {
    await livestreamController.tryToGenerateToken(
      roleId: 1,
      userId: authController.userProfile.value.user!.id!.toInt(),
      channelName: channelName,
    );

    livestreamController.getTokens.isNotEmpty
        ? data['peeredUserCallType'] == 'audio'
        ? Get.to(
      AudioCallView(
        channelName: channelName,
        isBroadcaster: false,
        token: livestreamController.getTokens['token'],
        profile: null,
      ),
      arguments: data,
    )
        : Get.to(
      VideoCallView(
        channelName: channelName,
        isBroadcaster: false,
        token: livestreamController.getTokens['token'],
        profile: null,
      ),
      arguments: data,
    )
        : Get.snackbar(
      'Error',
      'Failed to generate token. Please try again later.',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
  }
}
