import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../../ranking/controllers/ranking_controller.dart';

class ProfileFlower extends StatelessWidget {
  ProfileFlower({super.key});

  final List<Map<String, dynamic>> users = [
    {
      'name': 'Tom',
      'id': '18752',
      'status': 'joined',
      'imageUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRO_zU_CkIPahftPFxoH-_Ssrk0tTLz0BRkLYea4mE1MtJ3uPa-fwbK7Ppr1_XXtJagCOI',
    },
    {
      'name': 'Jerry',
      'id': '10498',
      'status': 'invite',
      'imageUrl': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'name': 'Tom',
      'id': '18752',
      'status': 'joined',
      'imageUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRO_zU_CkIPahftPFxoH-_Ssrk0tTLz0BRkLYea4mE1MtJ3uPa-fwbK7Ppr1_XXtJagCOI',
    },
    {
      'name': 'Jerry',
      'id': '10498',
      'status': 'invite',
      'imageUrl': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'name': 'Tom',
      'id': '18752',
      'status': 'joined',
      'imageUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRO_zU_CkIPahftPFxoH-_Ssrk0tTLz0BRkLYea4mE1MtJ3uPa-fwbK7Ppr1_XXtJagCOI',
    },
    {
      'name': 'Jerry',
      'id': '10498',
      'status': 'invite',
      'imageUrl': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    RankingController controller = Get.put(RankingController());
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Follower',
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              Color(0xffb5a7fe),
              Color(0xffffffff),
            ], begin: Alignment.topRight, end: Alignment.bottomRight)),
          ),
          InkWell(
            onTap: () {},
            child: ListView.builder(
              itemCount: controller.rankingList.length,
              itemBuilder: (context, index) {
                final item = controller.rankingList[index];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xff843af4)),
                    // gradient: const LinearGradient(
                    //   colors: [Color(0xff9d67fd), Color(0xffc87efd)],
                    //   begin: Alignment.topCenter,
                    //   end: Alignment.bottomCenter,
                    // ),
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

                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: index == 0
                            ? const Color(0xFFFFD700)
                            : index == 1
                                ? const Color(0xFFC0C0C0)
                                : index == 2
                                    ? const Color(0xFFCD7F32)
                                    : Colors.tealAccent[100],
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: CachedNetworkImage(
                            imageUrl: ImageHelper.getImageUrl(
                                '${item['profile_image']}'),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name
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
                            Row(
                              children: [
                                Container(
                                  height: 15,
                                  width: 35,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(50),
                                    ),
                                    color: Color(0xff843af4),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.leaderboard,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        '2',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: kWeight * 0.01,
                                ),
                                Container(
                                  height: 15,
                                  width: 35,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(50),
                                    ),
                                    color: Color(0xff843af4),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.male,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        '22',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: kWeight * 0.01,
                                ),
                                Text(
                                  '🇧🇩',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      // Points
                      Row(
                        children: [
                          Obx(
                            () => InkWell(
                              onTap: () {
                                controller.isFollow.value =
                                    !controller.isFollow.value;
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 7),
                                decoration: BoxDecoration(
                                    color: Color(0xff8A4CF7),
                                    borderRadius: BorderRadius.circular(50),
                                    border:
                                        Border.all(color: Color(0xff8A4CF7))),
                                child: Text(
                                  controller.isFollow.value == true
                                      ? '+ Follow'
                                      : 'Following',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
