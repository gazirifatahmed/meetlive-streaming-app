import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../ranking/controllers/ranking_controller.dart';
import '../../ranking/views/hederRanking/FollowButton.dart';
import '../../ranking/views/ranking_view.dart';

class ProfileContributionList extends StatelessWidget {
  const ProfileContributionList({super.key});

  DecorationImage? getFrame(Map<String, dynamic> contributor) {
    final assetHistory = contributor['sender']['asset_purchase_history'];
    if (assetHistory == null) return null;

    final asset = assetHistory['asset']?['asset'];
    if (asset == null || asset.isEmpty) return null;

    return DecorationImage(
      image: NetworkImage(ImageHelper.getImageUrl(asset)),
      fit: BoxFit.cover,
    );
  }

  Widget normalContributionCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xff171109).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff6f5426).withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xff3b2614),
              border: Border.all(color: const Color(0xffffd16a)),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: kHeight * 0.058,
                width: kHeight * 0.058,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: getFrame(item),
                ),
              ),
              Container(
                height: kHeight * 0.048,
                width: kHeight * 0.048,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: ImageHelper.getImageUrl(
                      '${item['sender']['profile_image']}',
                    ),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.person),
                    fadeInDuration: Duration.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${item['sender']['name']}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '${item['sender']['earned_coins']}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xffffc653),
            ),
          ),
        ],
      ),
    );
  }

  Widget topRankCard({
    required Map<String, dynamic> item,
    required String rankText,
    required double height,
    required double width,
    required double profileWidth,
    required Color fastColor,
    required Color secondColor,
    required Color bottomColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CastonRankingcard(
          frame: getFrame(item),
          coin: '${item['sender']['earned_coins']}',
          profileImage: ImageHelper.getImageUrl(
            '${item['sender']['profile_image']}',
          ),
          pwidth: profileWidth,
          fastColor: fastColor,
          secondColor: secondColor,
          height: height,
          width: width,
          bottomColor: bottomColor,
          rankText: rankText,
          name: '${item['sender']['name']}', backgroundImage: 'assets/new/rankfastcard.png',
        ),
        SizedBox(height: kHeight * 0.018),
        RankinFollowButton(
          text: 'Follow',
          onPressed: () {},
        ),
      ],
    );
  }

  Widget topThreePremiumSection({
    required Map<String, dynamic> first,
    Map<String, dynamic>? second,
    Map<String, dynamic>? third,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 12),
      child: SizedBox(
        height: Get.height * 0.30,
        width: Get.width,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (second != null)
              Positioned(
                left: Get.width * 0.02,
                top: Get.height * 0.055,
                child: topRankCard(
                  item: second,
                  rankText: '2',
                  height: Get.height * 0.135,
                  width: Get.width * 0.25,
                  profileWidth: Get.width * 0.078,
                  fastColor: const Color(0xFFe3dce3),
                  secondColor: const Color(0xff8A4CF7),
                  bottomColor: const Color(0xff8A4CF7),
                ),
              ),

            Positioned(
              top: 0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffffd15c).withValues(alpha: 0.45),
                      blurRadius: 35,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: topRankCard(
                  item: first,
                  rankText: '1',
                  height: Get.height * 0.185,
                  width: Get.width * 0.34,
                  profileWidth: Get.width * 0.11,
                  fastColor: const Color(0xff8A4CF7),
                  secondColor: const Color(0xFFfec42a),
                  bottomColor: const Color(0xFFfec42a),
                ),
              ),
            ),

            if (third != null)
              Positioned(
                right: Get.width * 0.02,
                top: Get.height * 0.055,
                child: topRankCard(
                  item: third,
                  rankText: '3',
                  height: Get.height * 0.135,
                  width: Get.width * 0.25,
                  profileWidth: Get.width * 0.078,
                  fastColor: const Color(0xFFfdbca0),
                  secondColor: const Color(0xFFff847d),
                  bottomColor: const Color(0xFFff847d),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(RankingController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Obx(() {
            final contributions = myprofileController.profileContributionList;
            final total = contributions.length;

            if (total == 0) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_dissatisfied,
                      size: Get.height * 0.16,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Contributions Yet!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Start contributing to see your ranking here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: total,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final first = contributions[0];
                  final second = total > 1 ? contributions[1] : null;
                  final third = total > 2 ? contributions[2] : null;

                  return topThreePremiumSection(
                    first: first,
                    second: second,
                    third: third,
                  );
                }

                if (index >= 3) {
                  final item = contributions[index];
                  return normalContributionCard(item, index);
                }

                return const SizedBox.shrink();
              },
            );
          }),
        ),
      ),
    );
  }
}