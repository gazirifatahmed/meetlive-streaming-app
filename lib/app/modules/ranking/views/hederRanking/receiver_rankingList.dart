import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../constants/image_helper.dart';
import '../../../../../constants/layout_constant.dart';
import '../../../../../widgets/after/CastomText.dart';
import '../../controllers/ranking_controller.dart';
import '../ranking_view.dart';
import 'FollowButton.dart';

class RankingReciverList extends GetView<RankingController> {
  const RankingReciverList({super.key});
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

  @override
  Widget build(BuildContext context) {
    Get.put(RankingController());
    controller.getRankingList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
          future: controller.showRankingList(),
          builder: (context, snapshot) {
            return ListView.builder(
              itemCount: controller.receiverRanking.length,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  final first = controller.receiverRanking[0];
                  final second = controller.receiverRanking.length > 1
                      ? controller.receiverRanking[1]
                      : null;
                  final third = controller.receiverRanking.length > 2
                      ? controller.receiverRanking[2]
                      : null;

                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // -------- 2nd Place (Left) --------
                        if (second != null)
                          Column(
                            children: [
                              CastonRankingcard(
                                frame: second['receiver']
                                            ['asset_purchase_history2'] ==
                                        null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(
                                          ImageHelper.getImageUrl(
                                              '${second['receiver']['asset_purchase_history2']['asset']['asset']}'),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                coin: formatCoin(second['total_coin']),
                                profileImage: ImageHelper.getImageUrl(
                                    '${second['receiver']['profile_image']}'),
                                pwidth: Get.width * 0.077,
                                fastColor: Color(0xFFe3dce3),
                                secondColor: Color(0xff8A4CF7),
                                height: Get.height * 0.16,
                                width: Get.width * 0.24,
                                bottomColor: Color(0xff8A4CF7),
                                rankText: '2',
                                name: '${second['receiver']['name']}', backgroundImage: 'assets/new/recivingRank2.png',
                              ),
                              SizedBox(height: kHeight * 0.032),
                              RankinFollowButton(
                                text: 'Follow',
                                onPressed: () {},
                              )
                            ],
                          ),

                        // -------- 1st Place (Middle) --------
                        Column(
                          children: [
                            CastonRankingcard(
                              frame: first['receiver']
                                          ['asset_purchase_history2'] ==
                                      null
                                  ? null
                                  : DecorationImage(
                                      image: NetworkImage(
                                        ImageHelper.getImageUrl(
                                            '${first['receiver']['asset_purchase_history2']['asset']['asset']}'),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                              coin: formatCoin(first['total_coin']),
                              profileImage: ImageHelper.getImageUrl(
                                  '${first['receiver']['profile_image']}'),
                              pwidth: Get.width * 0.1,
                              fastColor: Color(0xff8A4CF7),
                              secondColor: Color(0xFFfec42a),
                              height: Get.height * 0.19,
                              width: Get.width * 0.29,
                              bottomColor: Color(0xFFfec42a),
                              rankText: '1',
                              name: '${first['receiver']['name']}', backgroundImage: 'assets/new/RecivingRank.png',
                            ),
                            SizedBox(height: kHeight * 0.032),
                            RankinFollowButton(
                              text: 'Follow',
                              onPressed: () {},
                            )
                          ],
                        ),

                        // -------- 3rd Place (Right) --------
                        if (third != null)
                          Column(
                            children: [
                              CastonRankingcard(
                                frame: third['receiver']
                                            ['asset_purchase_history2'] ==
                                        null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(
                                          ImageHelper.getImageUrl(
                                              '${third['receiver']['asset_purchase_history2']['asset']['asset']}'),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                coin: formatCoin(third['total_coin']),
                                profileImage: ImageHelper.getImageUrl(
                                    '${third['receiver']['profile_image']}'),
                                pwidth: Get.width * 0.076,
                                fastColor: Color(0xFFfdbca0),
                                secondColor: Color(0xFFff847d),
                                height: Get.height * 0.15,
                                width: Get.width * 0.23,
                                bottomColor: Color(0xFFff847d),
                                rankText: '3',
                                name: '${third['receiver']['name']}', backgroundImage: 'assets/new/recive#.png',
                              ),
                              SizedBox(height: kHeight * 0.032),
                              RankinFollowButton(
                                text: 'Follow',
                                onPressed: () {},
                              )
                            ],
                          )
                      ],
                    ),
                  );
                }

                // 🔹 4th থেকে normal card


                if (index >= 3) {
                  final item = controller.receiverRanking[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0,horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white.withValues(alpha: 0.10),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Row(
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
                                          image: item['receiver']?['asset_purchase_history2'] == null
                                              ? null
                                              : DecorationImage(
                                            image: NetworkImage(
                                              ImageHelper.getImageUrl(
                                                '${item['receiver']['asset_purchase_history2']['asset']['asset']}',
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
                                              "${item['receiver']?['profile_image']}",
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

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item['receiver']?['name']}',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Castontext(
                                          textColor: Colors.yellow,
                                          text: 'Coins :${formatCoin(item['total_coin'])}',
                                        ),
                                      ],
                                    ),
                                  ),

                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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


                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            );
          }),
    );
  }
}
