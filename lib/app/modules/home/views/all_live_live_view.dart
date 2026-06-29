import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../livestream/controllers/agoraTokenController.dart';
import '../../livestream/controllers/audience_join_controller.dart';
import '../../livestream/controllers/livestream_controller.dart';
import '../controllers/home_controller.dart';

class AllLiveListView extends GetView<HomeController> {
  const AllLiveListView({super.key});

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
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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

            final users = controller.showingLiveStreamList;

            if (users.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(kHeight * 0.1),
                  child: Column(
                    children: [
                      SizedBox(height: kHeight * 0.13),
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
              );
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
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
                  return UserProfileCard(
                    data: item,
                    index: index,
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class UserProfileCard extends StatelessWidget {
  final dynamic data;
  final int index;

  const UserProfileCard({super.key, required this.data, required this.index});

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Map<String, dynamic> _displayUser(Map<String, dynamic> item) {
    final callers = item['livestream_callers'];
    if (callers is List && callers.isNotEmpty) {
      final first = callers.first;
      if (first is Map && first['user'] is Map) {
        return _asMap(first['user']);
      }
    }

    if (item['user'] is Map) return _asMap(item['user']);
    if (item['sender_host'] is Map) return _asMap(item['sender_host']);
    if (item['receiver_host'] is Map) return _asMap(item['receiver_host']);

    return <String, dynamic>{};
  }

  String _profileImageUrl(Map<String, dynamic> user) {
    final raw = user['profile_image']?.toString().trim() ?? '';

    if (raw.isEmpty || raw == 'null') {
      return 'https://photosbulk.com/wp-content/uploads/2024/08/hijab-girl-pic_108.webp';
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    return ImageHelper.getImageUrl(raw);
  }

  bool _isPkRunning(Map<String, dynamic> item) {
    final int pkId = _toInt(item['pk_id'] ?? item['current_pk_id']);
    final String pkStatus = item['pk_status']?.toString().toLowerCase() ?? '';
    final String streamType = item['stream_type']?.toString().toLowerCase() ?? '';

    return pkId > 0 ||
        item['is_pk']?.toString() == '1' ||
        item['is_pk_room'] == true ||
        pkStatus == 'running' ||
        streamType == 'pk';
  }

  @override
  Widget build(BuildContext context) {
    final AudienceJoinController liveController = Get.put(AudienceJoinController());
    final AgoraTokenController agoraTokenController = Get.find();

    final Map<String, dynamic> item = _asMap(data);
    final Map<String, dynamic> displayUser = _displayUser(item);

    final String displayName = (displayUser['name'] ?? 'User').toString();
    final String imageUrl = _profileImageUrl(displayUser);
    final String streamType = item['stream_type']?.toString().toLowerCase() ?? '';
    final bool isAudio = streamType == 'audio';
    final bool isPk = _isPkRunning(item);
    final int viewerCount = _toInt(
      item['livestream_viewers_count'] ?? item['viewer_count'],
    );
    final String displayId = '${item['user_id'] ?? displayUser['user_id'] ?? displayUser['id'] ?? ''}';

    return InkWell(
      onTap: () {
        if (agoraTokenController.tokenIsLoading.value ||
            liveController.isLoading.value) {
          return;
        }

        final Map<String, dynamic> liveData = Map<String, dynamic>.from(item);

        final String normalChannel =
            '${liveData['room_id'] ?? liveData['channel_name'] ?? ''}';

        final String pkChannel =
            '${liveData['pk_channel'] ?? liveData['pk_channel_name'] ?? ''}';

        final int pkId = _toInt(liveData['pk_id'] ?? liveData['current_pk_id']);

        final bool isPkRunning = _isPkRunning(liveData);

        final String joinChannel =
        isPkRunning && pkChannel.isNotEmpty ? pkChannel : normalChannel;

        print('👀 LIVE TAP DATA => $liveData');
        print('👀 LIVE ID => ${liveData['id'] ?? liveData['livestream_id'] ?? liveData['stream_id']}');
        print('👀 NORMAL CHANNEL => $normalChannel');
        print('👀 PK CHANNEL => $pkChannel');
        print('👀 IS PK RUNNING => $isPkRunning');
        print('👀 JOIN AGORA CHANNEL => $joinChannel');

        liveController.joinAsAudience(
          channelName: joinChannel,
          data: {
            ...liveData,
            'audience_join_agora_channel': joinChannel,
            'is_pk': isPkRunning ? 1 : 0,
            'pk_id': pkId,
            'pk_channel': pkChannel,
            'pk_channel_name': pkChannel,
          },
        );

        print('Loading video ${agoraTokenController.tokenIsLoading.value}');
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Obx(() {
                if (agoraTokenController.tokenIsLoading.value) {
                  return SizedBox(
                    height: kHeight * 0.23,
                    width: kWeight * 0.8,
                    child: const Center(
                      child: SpinKitFadingCircle(
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    height: kHeight * 0.23,
                    width: kWeight * 0.8,
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Image.network(
                      'https://photosbulk.com/wp-content/uploads/2024/08/hijab-girl-pic_108.webp',
                      height: kHeight * 0.23,
                      width: kWeight * 0.8,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }),
              Container(
                height: kHeight * 0.23,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .10),
                      Colors.black.withValues(alpha: .15),
                      Colors.black.withValues(alpha: .45),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 13.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              _typeBadge(
                                isPk: isPk,
                                isAudio: isAudio,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 13, right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black.withValues(alpha: .4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.person,
                                color: Colors.white,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$viewerCount',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🇧🇩',
                            style: GoogleFonts.aBeeZee(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lobster(
                                  color: Colors.white,
                                  fontSize: Get.height * 0.014,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: kWeight * 0.013,
                                  vertical: 1,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: kWeight * 0.22,
                                  maxWidth: kWeight * 0.34,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .5),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withValues(alpha: .2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'ID :',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        displayId,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBadge({required bool isPk, required bool isAudio}) {
    final String label = isPk ? 'PK' : (isAudio ? 'Audio' : 'Live');
    final IconData icon = isPk
        ? Icons.sports_mma_rounded
        : (isAudio ? Icons.mic : Icons.live_tv);

    final List<Color> colors = isPk
        ? const [Color(0xffff7a00), Color(0xffff2d55)]
        : isAudio
        ? const [kAppColor, kAppColor]
        : const [Color(0xfff60a0a), Color(0xfff45252)];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kWeight * 0.01,
        vertical: 0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: Get.height * 0.014,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: Get.height * 0.013,
            ),
          ),
        ],
      ),
    );
  }
}

class CastomminContainer extends StatelessWidget {
  final String image;

  const CastomminContainer({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Image(
          image: AssetImage(image),
          height: 30,
        ),
      ),
    );
  }
}
