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

class AgencyRankingList extends GetView<RankingController> {
  const AgencyRankingList({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RankingController());
    controller.showRankingList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
          future: controller.showRankingList(),
          builder: (context, snapshot) {
            return ListView.builder(
              itemCount: controller.agencyRanking.length,
              itemBuilder: (BuildContext context, int index) {
              
                if (index == 0) {
                  final first = controller.agencyRanking[0];
                  final second = controller.agencyRanking.length > 1
                      ? controller.agencyRanking[1]
                      : null;
                  final third = controller.agencyRanking.length > 2
                      ? controller.agencyRanking[2]
                      : null;
                  print('fast Iteam $second');
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
                                frame: second['asset_purchase_history2'] == null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(
                                          ImageHelper.getImageUrl(
                                              '${second['asset_purchase_history2']['asset']?['asset']}'),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                coin: '${second['total_coin'] ?? 0}',
                                profileImage: ImageHelper.getImageUrl(
                                    '${second['sender']?['profile_image']}'),
                                pwidth: Get.width * 0.077,
                                fastColor: Color(0xFFe3dce3),
                                secondColor: Color(0xff8A4CF7),
                                height: Get.height * 0.13,
                                width: Get.width * 0.23,
                                bottomColor: Color(0xff8A4CF7),
                                rankText: '2',
                                name: '${second['sender']?['name']}', backgroundImage: 'assets/new/rankfastcard.png',
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
                              frame: first['asset_purchase_history2'] == null
                                  ? null
                                  : DecorationImage(
                                      image: NetworkImage(
                                        ImageHelper.getImageUrl(
                                            '${first['asset_purchase_history2']['asset']['asset']}'),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                              coin: '${first['earned_coins']}',
                              profileImage: ImageHelper.getImageUrl(
                                  '${first['profile_image']}'),
                              pwidth: Get.width * 0.1,
                              fastColor: Color(0xff8A4CF7),
                              secondColor: Color(0xFFfec42a),
                              height: Get.height * 0.17,
                              width: Get.width * 0.29,
                              bottomColor: Color(0xFFfec42a),
                              rankText: '1',
                              name: '${first['name']}', backgroundImage: 'assets/new/rankfastcard.png',
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
                                frame: third['asset_purchase_history2'] == null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(
                                          ImageHelper.getImageUrl(
                                              '${third['asset_purchase_history2']['asset']['asset']}'),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                coin: '${third['earned_coins']}',
                                profileImage: ImageHelper.getImageUrl(
                                    '${third['profile_image']}'),
                                pwidth: Get.width * 0.076,
                                fastColor: Color(0xFFfdbca0),
                                secondColor: Color(0xFFff847d),
                                height: Get.height * 0.13,
                                width: Get.width * 0.23,
                                bottomColor: Color(0xFFff847d),
                                rankText: '3',
                                name: '${third['name']}', backgroundImage: 'assets/new/rankfastcard.png',
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
                  final item = controller.agencyRanking[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),

                            // 🔥 glass base
                            color: Colors.white.withValues(alpha: 0.10),



                            // 🔥 shadow
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
                                  // Rank
                                  Text(
                                    '${index + 1}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Avatar
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: kHeight * 0.045,
                                        width: kHeight * 0.045,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: item['asset_purchase_history2'] == null
                                              ? null
                                              : DecorationImage(
                                            image: NetworkImage(
                                              ImageHelper.getImageUrl(
                                                '${item['asset_purchase_history2']['asset']?['asset']}',
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
                                              "${item['profile_image']}",
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

                                  // Name + coins
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item['name']}',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Castontext(
                                          textColor: Colors.yellow,
                                          text: 'Coins :${item['earned_coins']}',
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Follow button (glass)
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
