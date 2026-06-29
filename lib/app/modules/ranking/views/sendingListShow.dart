import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/ranking/views/ranking_view.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../controllers/ranking_controller.dart';
import 'hederRanking/FollowButton.dart';

class Sendinglistshow extends GetView<RankingController> {
  const Sendinglistshow({super.key});

  String formatCoin(dynamic value) {
    if (value == null) return '0';
    double number = double.tryParse(value.toString()) ?? 0;

    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  Widget rankingShimmer() {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Shimmer.fromColors(
            baseColor: Colors.white.withValues(alpha: 0.12),
            highlightColor: Colors.white.withValues(alpha: 0.35),
            child: Container(
              height: index == 0 ? 170 : 65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(RankingController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: controller.showRankingList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return rankingShimmer();
          }

          if (controller.senderRanking.isEmpty) {
            return const Center(
              child: Text(
                'No ranking found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.senderRanking.length,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                final first = controller.senderRanking[0];
                final second = controller.senderRanking.length > 1
                    ? controller.senderRanking[1]
                    : null;
                final third = controller.senderRanking.length > 2
                    ? controller.senderRanking[2]
                    : null;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18.0,
                    vertical: 20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (second != null)
                        Column(
                          children: [
                            CastonRankingcard(
                              frame: second['sender']
                              ?['asset_purchase_history2'] ==
                                  null
                                  ? null
                                  : DecorationImage(
                                image: NetworkImage(
                                  ImageHelper.getImageUrl(
                                    '${second['sender']['asset_purchase_history2']['asset']['asset']}',
                                  ),
                                ),
                                fit: BoxFit.cover,
                              ),
                              coin: formatCoin(second['total_coin']),
                              profileImage: ImageHelper.getImageUrl(
                                '${second['sender']?['profile_image']}',
                              ),
                              pwidth: Get.width * 0.077,
                              fastColor: const Color(0xfff8205e),
                              secondColor: const Color(0xfff61b97),
                              height: Get.height * 0.15,
                              width: Get.width * 0.23,
                              topBorderColor: Color(0xffb30319),
                              sideBorderColor: Color(0xffb30319),
                              bottomColor: const Color(0xfff8205e),
                              rankText: '2',
                              name: '${second['sender']?['name']}', backgroundImage: 'assets/new/rank2.png',
                            ),
                            SizedBox(height: kHeight * 0.032),
                            RankinFollowButton(
                              text: 'Follow',
                              onPressed: () {},
                            ),
                          ],
                        ),

                      Column(
                        children: [
                          CastonRankingcard(

                            frame: first['sender']
                            ?['asset_purchase_history2'] ==
                                null
                                ? null
                                : DecorationImage(
                              image: NetworkImage(
                                ImageHelper.getImageUrl(
                                  '${first['sender']['asset_purchase_history2']['asset']['asset']}',
                                ),
                              ),
                              fit: BoxFit.cover,
                            ),
                            coin: formatCoin(first['total_coin']),
                            profileImage: ImageHelper.getImageUrl(
                              '${first['sender']?['profile_image']}',
                            ),
                            pwidth: Get.width * 0.12,
                            fastColor: const Color(0xffa601e9),
                            secondColor: const Color(0xff2001e9),
                            height: Get.height * 0.19,
                            topBorderColor: Color(0xff210183),
                            sideBorderColor: Color(0xff210183),
                            width: Get.width * 0.29,
                            bottomColor: const Color(0xffa601e9),
                            rankText: '1',
                            name: '${first['sender']?['name']}', backgroundImage: 'assets/new/rank1-removebg-preview.png',
                          ),
                          SizedBox(height: kHeight * 0.032),
                          RankinFollowButton(
                            text: 'Follow',
                            onPressed: () {},
                          ),
                        ],
                      ),

                      if (third != null)
                        Column(
                          children: [
                            CastonRankingcard(
                              frame: third['sender']
                              ?['asset_purchase_history2'] ==
                                  null
                                  ? null
                                  : DecorationImage(
                                image: NetworkImage(
                                  ImageHelper.getImageUrl(
                                    '${third['sender']['asset_purchase_history2']['asset']['asset']}',
                                  ),
                                ),
                                fit: BoxFit.cover,
                              ),
                              coin: formatCoin(third['total_coin']),
                              profileImage: ImageHelper.getImageUrl(
                                '${third['sender']?['profile_image']}',
                              ),
                              pwidth: Get.width * 0.076,
                              fastColor: const Color(0xff1bfa7a),
                              secondColor: const Color(0xff06c5a2),
                              height: Get.height * 0.15,
                              width: Get.width * 0.23,
                              topBorderColor: Color(0xff026e3d),
                              sideBorderColor: Color(0xff026e3d),
                              bottomColor: const Color(0xff1bfa7a),
                              rankText: '3',
                              name: '${third['sender']?['name']}', backgroundImage: 'assets/new/rankfastcard.png',
                            ),
                            SizedBox(height: kHeight * 0.032),
                            RankinFollowButton(
                              text: 'Follow',
                              onPressed: () {},
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }

              if (index >= 3) {
                final item = controller.senderRanking[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2.0,
                    horizontal: 7,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                     gradient: LinearGradient(colors: [
                       Color(0xff03adf4),
                       Color(0xff4efbed),
                     ],begin: AlignmentGeometry.topCenter,end: AlignmentGeometry.bottomCenter),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: kHeight * 0.045,
                              width: kHeight * 0.045,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: item['sender']
                                ?['asset_purchase_history2'] ==
                                    null
                                    ? null
                                    : DecorationImage(
                                  image: NetworkImage(
                                    ImageHelper.getImageUrl(
                                      '${item['sender']['asset_purchase_history2']['asset']['asset']}',
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              height: kHeight * 0.03,
                              width: kHeight * 0.03,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: CachedNetworkImage(
                                  imageUrl: ImageHelper.getImageUrl(
                                    "${item['sender']?['profile_image']}",
                                  ),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                  const SizedBox(),
                                  errorWidget: (context, url, error) =>
                                  const Icon(Icons.person),
                                  fadeInDuration: Duration.zero,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['sender']?['name']}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Castontext(
                                textColor: Colors.yellow,
                                text:
                                'Coins :${formatCoin(item['total_coin'])}',
                              ),
                            ],
                          ),
                        ),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: InkWell(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  'Follow',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}