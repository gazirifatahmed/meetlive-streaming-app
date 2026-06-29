import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../livestream/controllers/livestream_controller.dart';
import '../controllers/home_controller.dart';
import 'all_live_live_view.dart';


class PkLiveListView extends GetView<HomeController> {
  const PkLiveListView({super.key});

  bool _isAudioRoom(dynamic item) {
    final String streamType = item['stream_type']?.toString().toLowerCase() ?? '';
    return streamType == 'audio';
  }

  bool _isPkRoom(dynamic item) {
    final String streamType = item['stream_type']?.toString().toLowerCase() ?? '';
    final String pkStatus = item['pk_status']?.toString().toLowerCase() ?? '';

    return streamType == 'pk' || item['is_pk_room'] == true || pkStatus == 'running';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _makePkRoomCardData(dynamic item) {
    final Map<String, dynamic> pkData = _asMap(item);
    final Map<String, dynamic> senderLive = _asMap(pkData['sender_livestream']);
    final Map<String, dynamic> receiverLive = _asMap(pkData['receiver_livestream']);

    return {
      ...senderLive,

      // Important old live data support: one PK battle card represents sender side.
      'id': pkData['sender_livestream_id'] ?? senderLive['id'] ?? pkData['id'],
      'room_id': senderLive['room_id'] ?? pkData['room_id'] ?? pkData['sender_host_id']?.toString(),
      'user_id': senderLive['user_id'] ?? pkData['sender_host_id'],

      // PK identity
      'stream_type': 'pk',
      'stream_bte': pkData['stream_bte'] ?? 'PK Battle',
      'is_pk': 1,
      'is_pk_room': true,
      'live_status': pkData['live_status'] ?? 'active',

      // PK data
      'pk_id': pkData['pk_id'],
      'pk_status': pkData['pk_status'],
      'pk_channel': pkData['pk_channel'] ?? pkData['pk_channel_name'],
      'pk_channel_name': pkData['pk_channel_name'] ?? pkData['pk_channel'],
      'pk_start_time': pkData['pk_start_time'],
      'duration_seconds': pkData['duration_seconds'],
      'remaining_seconds': pkData['remaining_seconds'],
      'remaining_time': pkData['remaining_time'],

      'sender_livestream_id': pkData['sender_livestream_id'],
      'receiver_livestream_id': pkData['receiver_livestream_id'],
      'pk_sender_livestream_id': pkData['sender_livestream_id'],
      'pk_receiver_livestream_id': pkData['receiver_livestream_id'],
      'sender_host_id': pkData['sender_host_id'],
      'receiver_host_id': pkData['receiver_host_id'],

      'sender_score': pkData['sender_score'] ?? 0,
      'receiver_score': pkData['receiver_score'] ?? 0,
      'total_score': pkData['total_score'] ?? 0,
      'sender_score_percent': pkData['sender_score_percent'] ?? 50,
      'receiver_score_percent': pkData['receiver_score_percent'] ?? 50,

      'sender_host': pkData['sender_host'],
      'receiver_host': pkData['receiver_host'],
      'sender_livestream': senderLive,
      'receiver_livestream': receiverLive,
      // UserProfileCard old support: sender host/card image will show, but join opens PK.
      'livestream_callers': pkData['livestream_callers'] ??
          senderLive['livestream_callers'] ??
          receiverLive['livestream_callers'] ??
          [],
      'viewer_count': pkData['viewer_count'] ?? 0,
      'livestream_viewers_count': pkData['livestream_viewers_count'] ?? 0,
      // Full original PK object
      'pk_room_data': pkData,
    };
  }
  List<dynamic> _prepareAudioPkList(List<dynamic> sourceList) {
    final List<dynamic> list = [];
    final Set<String> seenPkIds = {};
    final Set<String> seenAudioLiveIds = {};
    for (final raw in sourceList) {
      final item = _asMap(raw);
      if (item.isEmpty) continue;
      if (_isPkRoom(item)) {
        final String pkId = '${item['pk_id'] ?? item['id'] ?? ''}';
        if (pkId.isNotEmpty && pkId != 'null' && seenPkIds.contains(pkId)) {
          continue;
        }
        if (pkId.isNotEmpty && pkId != 'null') seenPkIds.add(pkId);
        list.add(_makePkRoomCardData(item));
        continue;
      }
      if (_isAudioRoom(item)) {
        final String liveId = '${item['id'] ?? item['livestream_id'] ?? item['stream_id'] ?? ''}';
        if (liveId.isNotEmpty && liveId != 'null' && seenAudioLiveIds.contains(liveId)) {
          continue;
        }
        if (liveId.isNotEmpty && liveId != 'null') seenAudioLiveIds.add(liveId);
        list.add(item);
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());
    Get.put(LivestreamController());

    return Scaffold(
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await homeController.getLivestreamList();
        },
        builder: (
            BuildContext context,
            Widget child,
            IndicatorController refreshController,
            ) {
          return Stack(
            children: [
              child,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: refreshController,
                  builder: (context, _) {
                    return SizedBox(
                      height: refreshController.value * 80,
                      child: Center(
                        child: refreshController.isIdle
                            ? const SizedBox()
                            : Container(
                          decoration: BoxDecoration(
                            color: kAppColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Transform.scale(
                            scale: refreshController.value.clamp(0.0, 1.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.asset(
                                appLogo,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Obx(() {
            if (controller.isLoading.value) {
              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: kHeight * 0.23,
                  childAspectRatio: 0.7,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(4),
                    ),
                  );
                },
              );
            }

            final List<dynamic> users = _prepareAudioPkList(
              List<dynamic>.from(controller.showingLiveStreamList),
            );

            if (users.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: Get.height * 0.65,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(kHeight * 0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/flaticons/nYuPvdjcOD.json',
                            height: kHeight * 0.14,
                            width: kHeight * 0.14,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: kHeight * 0.01),
                          Castontext(
                            fontWeight: FontWeight.w500,
                            textColor: Colors.black.withValues(alpha: .6),
                            fontSize: kHeight * 0.012,
                            text: 'No Stream Available',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: kHeight * 0.23,
                childAspectRatio: 0.7,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final item = users[index];

                debugPrint(
                  '🎯 AUDIO/PK CARD => type: ${item['stream_type']} | '
                      'id: ${item['id']} | '
                      'room_id: ${item['room_id']} | '
                      'is_pk_room: ${item['is_pk_room']} | '
                      'pk_id: ${item['pk_id']}',
                );

                return UserProfileCard(
                  data: item,
                  index: index,
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
