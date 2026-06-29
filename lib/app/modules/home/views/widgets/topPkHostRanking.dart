import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../constants/image_helper.dart';
import '../../../../../constants/layout_constant.dart';
import '../../../../../widgets/after/CastomText.dart';
import '../../../ranking/controllers/ranking_controller.dart';
import '../../../ranking/views/ranking_view.dart';

class Toppkhostranking extends GetView<RankingController> {
  const Toppkhostranking({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RankingController());
    controller.getRankingList();
    return Scaffold(
      backgroundColor: Color(0xffb5a7fe),
      body: FutureBuilder(
          future: controller.showTopPkHost(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                controller.senderRanking.isEmpty) {
              return _buildShimmerLoading();
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
                                frame: second['sender']
                                            ['asset_purchase_history2'] ==
                                        null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(
                                          ImageHelper.getImageUrl(
                                              '${second['sender']['asset_purchase_history2']['asset']['asset']}'),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                coin: '${second['total_coin']}',
                                profileImage: ImageHelper.getImageUrl(
                                    '${second['sender']['profile_image']}'),
                                pwidth: Get.width * 0.077,
                                fastColor: Color(0xFFe3dce3),
                                secondColor: Color(0xff8A4CF7),
                                height: Get.height * 0.13,
                                width: Get.width * 0.23,
                                bottomColor: Color(0xff8A4CF7),
                                rankText: '2',
                                name: '${second['sender']['name']}', backgroundImage: 'assets/new/rankfastcard.png',
                              ),
                              SizedBox(height: kHeight * 0.032),
                              // rankinFollowButton(
                              //   text: 'Follow',
                              //   onPressed: () {
                              //     momentsController.followCreate(
                              //         userId: '${second['sender']['id']}');
                              //   },
                              // ),
                            ],
                          ),

                        // -------- 1st Place (Middle) --------
                        Column(
                          children: [
                            CastonRankingcard(
                              frame: first['sender']
                                          ['asset_purchase_history2'] ==
                                      null
                                  ? null
                                  : DecorationImage(
                                      image: NetworkImage(
                                        ImageHelper.getImageUrl(
                                            '${first['sender']['asset_purchase_history2']['asset']['asset']}'),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                              coin: '${first['total_coin']}',
                              profileImage: ImageHelper.getImageUrl(
                                  '${first['sender']['profile_image']}'),
                              pwidth: Get.width * 0.1,
                              fastColor: Color(0xff8A4CF7),
                              secondColor: Color(0xFFfec42a),
                              height: Get.height * 0.17,
                              width: Get.width * 0.29,
                              bottomColor: Color(0xFFfec42a),
                              rankText: '1',
                              name: '${first['sender']['name']}', backgroundImage: 'assets/new/rankfastcard.png',
                            ),
                            SizedBox(height: kHeight * 0.032),
                            // rankinFollowButton(
                            //   text: 'Follow',
                            //   onPressed: () {
                            //     momentsController.followCreate(
                            //         userId: '${first['sender']['id']}');
                            //   },
                            // ),
                          ],
                        ),

                        // -------- 3rd Place (Right) --------
                        if (third != null)
                          Column(
                            children: [
                              CastonRankingcard(
                                frame: third['sender']
                                            ['asset_purchase_history2'] ==
                                        null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(
                                          ImageHelper.getImageUrl(
                                              '${third['sender']['asset_purchase_history2']['asset']['asset']}'),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                coin: '${third['total_coin']}',
                                profileImage: ImageHelper.getImageUrl(
                                    '${third['sender']['profile_image']}'),
                                pwidth: Get.width * 0.076,
                                fastColor: Color(0xFFfdbca0),
                                secondColor: Color(0xFFff847d),
                                height: Get.height * 0.13,
                                width: Get.width * 0.23,
                                bottomColor: Color(0xFFff847d),
                                rankText: '3',
                                name: '${third['sender']['name']}', backgroundImage: 'assets/new/rankfastcard.png',
                              ),
                              SizedBox(height: kHeight * 0.032),
                              // rankinFollowButton(
                              //   text: 'Follow',
                              //   onPressed: () {
                              //     momentsController.followCreate(
                              //         userId: '${third['sender']['id']}');
                              //   },
                              // ),
                            ],
                          )
                      ],
                    ),
                  );
                }

                // 🔹 4th থেকে normal card
                if (index >= 3) {
                  final item = controller.senderRanking[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff9d67fd), Color(0xffc87efd)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Rank Number
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
                            // Frame Image
                            Container(
                              height: kHeight * 0.045,
                              width: kHeight * 0.045,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: item['sender']
                                            ['asset_purchase_history2'] ==
                                        null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(
                                          ImageHelper.getImageUrl(
                                              '${item['sender']['asset_purchase_history2']['asset']['asset']}'),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            // Profile Image
                            Container(
                              height: kHeight * 0.03,
                              width: kHeight * 0.03,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors
                                    .grey.shade200, // placeholder background
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: CachedNetworkImage(
                                  imageUrl: ImageHelper.getImageUrl(
                                      "${item['sender']['profile_image']}"),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      SizedBox(), // কোন delay না
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.person), // error হলে icon
                                  fadeInDuration:
                                      Duration.zero, // fade effect বন্ধ
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Avatar

                        const SizedBox(width: 12),

                        // Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['sender']['name']}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Castontext(
                                  textColor: Colors.yellow,
                                  text: 'Coins :${item['sender']['coins']}')
                            ],
                          ),
                        ),

                        // Points
                        Row(
                          children: [
                            // rankinFollowButton(
                            //   text: 'Follow',
                            //   onPressed: () {
                            //     momentsController.followCreate(
                            //         userId: '${item['sender']['id']}');
                            //   },
                            // ),
                          ],
                        ),
                      ],
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

Widget _buildShimmerLoading() {
  return SingleChildScrollView(
    child: Column(
      children: [
        // -------- Top 3 Shimmer --------
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
          child: Shimmer.fromColors(
            baseColor: Color(0xffcbbffe),
            highlightColor: Color(0xffe8e0ff),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 2nd Place Shimmer
                _shimmerTopCard(
                    height: Get.height * 0.13, width: Get.width * 0.23),

                // 1st Place Shimmer (বড়)
                _shimmerTopCard(
                    height: Get.height * 0.17, width: Get.width * 0.29),

                // 3rd Place Shimmer
                _shimmerTopCard(
                    height: Get.height * 0.13, width: Get.width * 0.23),
              ],
            ),
          ),
        ),

        // -------- List Items Shimmer (4th থেকে) --------
        Shimmer.fromColors(
          baseColor: Color(0xffcbbffe),
          highlightColor: Color(0xffe8e0ff),
          child: Column(
            children: List.generate(
              6, // কতগুলো skeleton দেখাবে
              (index) => _shimmerListCard(),
            ),
          ),
        ),
      ],
    ),
  );
}

// Top 3 এর shimmer card
Widget _shimmerTopCard({required double height, required double width}) {
  return Column(
    children: [
      Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      SizedBox(height: 8),
      Container(
        height: 30,
        width: width * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ],
  );
}

// Normal list card shimmer
Widget _shimmerListCard() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        // Rank number placeholder
        Container(width: 20, height: 20, color: Colors.white),
        SizedBox(width: 12),

        // Avatar placeholder
        CircleAvatar(radius: 22, backgroundColor: Colors.white),
        SizedBox(width: 12),

        // Name placeholder
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                color: Colors.white,
              ),
              SizedBox(height: 6),
              Container(
                height: 12,
                width: 100,
                color: Colors.white,
              ),
            ],
          ),
        ),

        // Follow button placeholder
        Container(
          height: 30,
          width: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    ),
  );
}
