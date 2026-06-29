import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../apis/api_endpoints.dart';
import '../../../../../constants/constants.dart';
import '../../../../../constants/layout_constant.dart';
import '../../../../../widgets/after/CastomText.dart';
import '../../../../../widgets/after/castom appbar.dart';
import '../../../store/controllers/store1_controller.dart';


class FollowinfList extends StatelessWidget {
  const FollowinfList({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(Store1Controller());
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Following',
      ),
      body: FutureBuilder(
          future: store1controller.showFollowingList(),
          builder: (context, snapshot) {
            return ListView.builder(
              itemCount: store1controller.followingList.length,
              itemBuilder: (context, flowingIndex) {
                final flowing = store1controller.followingList;
                // final bool isJoined = flowing?.?? false;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xff843af4)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ListTile(
                      leading: Container(
                        height: kHeight * 0.06,
                        width: kHeight * 0.06,
                        decoration: BoxDecoration(
                            image: flowing[flowingIndex]['following']
                                        ['asset_purchase_history'] ==
                                    null
                                ? null
                                : DecorationImage(
                                    image: NetworkImage(
                                        '$kDomainUrl/${flowing[flowingIndex]['following']['asset_purchase_history']['asset']['asset']}'),
                                    fit: BoxFit.cover)),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl:
                                  '$kDomainUrl/${flowing[flowingIndex]['following']['profile_image']}',
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      title: Castontext(
                        textColor: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 19,
                        text:
                            '${flowing[flowingIndex]['following']['name']}',
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            height: 15,
                            width: 35,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                              color: Color(0xff843af4),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(Icons.leaderboard,
                                    size: 11, color: Colors.white),
                                Text(
                                  '${authController.userProfile.value.user!.level}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: kWeight * 0.01),
                          Text(
                            flowing[flowingIndex]['following']['country'] ==
                                    'Bangladesh'
                                ? '🇧🇩'
                                : '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      trailing:
                          // isJoined
                          //     ? Text(
                          //         '',
                          //         style: GoogleFonts.lato(
                          //           fontSize: 15,
                          //           color: Colors.grey,
                          //           fontWeight: FontWeight.w600,
                          //         ),
                          //       )
                          //     :
                          Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            colors: [Color(0xff9d67fd), Color(0xffc87efd)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Text(
                          'Living',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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
