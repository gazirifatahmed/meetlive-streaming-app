import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';


import '../apis/api_endpoints.dart';
import '../app/modules/appmenu/views/widgets/game_test.dart';
import '../constants/color_constants.dart';
import '../constants/constants.dart';
import '../constants/image_helper.dart';
import '../constants/layout_constant.dart';
import 'after/CastomText.dart';

class LiveViewersList extends StatelessWidget {
  final List<dynamic> viewerList;
  final bool isBroadcaster;
  final bool isFromPk;

  final Function(int)? onKickUser;

  const LiveViewersList({
    super.key,
    required this.viewerList,
    required this.isBroadcaster,
    this.onKickUser,
    required this.isFromPk,
  });

  @override
  Widget build(BuildContext context) {
    print('sagor from pk $isFromPk');
    return Container(
      child: viewerList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: kHeight * 0.08,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                  SizedBox(height: kHeight * 0.02),
                  Text(
                    "No viewers yet",
                    style: TextStyle(
                      fontSize: kHeight * 0.018,
                      color: Colors.grey.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: viewerList.length,
              itemBuilder: (BuildContext context, int viewerIndex) {
                final liveViewer = viewerList[viewerIndex];
                return Container(
                  margin: EdgeInsets.symmetric(
                      vertical: 5, horizontal: kWeight * 0.015),
                  padding: EdgeInsets.symmetric(
                      vertical: 5, horizontal: kWeight * 0.02),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(17)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: kHeight * 0.06,
                            width: kHeight * 0.06,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // ---------------- PROFILE IMAGE ----------------
                                Container(
                                  height: Get.height * 0.055,
                                  width: Get.height * 0.055,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: CachedNetworkImage(
                                      fit: BoxFit.cover,
                                      imageUrl: ImageHelper.getImageUrl(
                                          '${liveViewer['user']['profile_image']}'),
                                    ),
                                  ),
                                ),

                                if (liveViewer['user']
                                            ['asset_purchase_history'] !=
                                        null &&
                                    liveViewer['user']['asset_purchase_history']
                                            ['asset'] !=
                                        null &&
                                    liveViewer['user']['asset_purchase_history']
                                            ['asset']['asset'] !=
                                        null)
                                  // Check if the asset path ends with .svga
                                  (liveViewer['user']['asset_purchase_history']
                                              ['asset']['asset']
                                          .toString()
                                          .endsWith('.svga'))
                                      ? SizedBox(
                                          height: kHeight * 0.08,
                                          width: kHeight * 0.08,
                                          child: SVGAEasyPlayer(
                                            resUrl:
                                                '$kDomainUrl/${liveViewer['user']['asset_purchase_history']['asset']['asset']}',
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl:
                                              "$kDomainUrl/${liveViewer['user']['asset_purchase_history']['asset']['asset']}",
                                          height: kHeight * 0.12,
                                          width: kHeight * 0.12,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            height: kHeight * 0.06,
                                            width: kHeight * 0.06,
                                            decoration: BoxDecoration(
                                              color: kAppColor.withValues(alpha: .02),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            height: kHeight * 0.12,
                                            width: kHeight * 0.12,
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 40,
                                              color: kAppColor.withValues(alpha: .2),
                                            ),
                                          ),
                                        )

                                // ---------------- NOTHING (no frame) ----------------
                                else
                                  SizedBox(
                                    height: kHeight * 0.03,
                                    width: kHeight * 0.03,
                                  ),
                              ],
                            ),
                          ),

                          SizedBox(width: kWeight * 0.02),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Castontext(
                                  fontWeight: FontWeight.w600,
                                  fontSize: kHeight * 0.02,
                                  textColor: Colors.black.withValues(alpha: .7),
                                  text: '${liveViewer['user']['name']}'),
                              SizedBox(height: kHeight * 0.007),
                              Padding(
                                padding: EdgeInsets.only(left: kWeight * 0.02),
                                child: LevelFrame(
                                  level: '${liveViewer['user']['level']}',
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      // Kick button - only visible for broadcaster
                      if (isBroadcaster && onKickUser != null)
                        GestureDetector(
                          onTap: () {
                            if (isFromPk) {
                              livestreamController.tryToCallLivestream(
                                  streamId: livestreamController.streamId.value,
                                  callerId: int.parse(
                                      liveViewer['user']['id'].toString()),
                                  callType: 'pk');
                            } else {
                              onKickUser!(liveViewer['user']['id']);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: kHeight * 0.007,
                                horizontal: kWeight * 0.05),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                    colors: [
                                      kAppColor.withValues(alpha: .7),
                                      kAppColor
                                    ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft)),
                            child: Castontext(
                                fontWeight: FontWeight.w500,
                                fontSize: kHeight * 0.016,
                                textColor: Colors.white.withValues(alpha: .8),
                                text: isFromPk ? 'PK Request' : 'Kick'),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
