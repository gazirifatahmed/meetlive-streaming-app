import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../constants/constants.dart';
import '../../../../../constants/image_helper.dart';
import '../../../../../constants/layout_constant.dart';
import '../../../../../widgets/after/castom appbar.dart';
import '../../../store/controllers/store1_controller.dart';
import 'game_test.dart';


class Follower extends StatelessWidget {
  const Follower({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(Store1Controller());
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Follower',
      ),
      body: FutureBuilder(
          future: store1controller.showFollowerList(),
          builder: (context, snapshot) {
            return ListView.builder(
              itemCount: store1controller.followerList.length ?? 0,
              itemBuilder: (context, flowingIndex) {
                final flowing = store1controller.followerList;
                // final bool isJoined = flowing?.?? false;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,

                      // 🔥 Leading (Premium Avatar)
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CachedNetworkImage(
                          imageUrl:ImageHelper.getImageUrl(flowing[flowingIndex]['user']['profile_image']),

                          height: kHeight*0.055,
                          width:  kHeight*0.055,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // 🔥 Title
                      title: Text(
                        flowing[flowingIndex]['user']['name'],
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      // 🔥 Subtitle
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          LevelFrame(
                            level: '${authController.userProfile.value.user?.level ?? 0}',
                          ),
                        ],
                      ),

                      // 🔥 Trailing Button
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xff9d67fd), Color(0xffc87efd)],
                          ),
                        ),
                        child: Text(
                          'Follow',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}
