import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../constants/image_helper.dart';
import '../controllers/notification_controller.dart';

class Panalnotification extends GetView<NotificationController> {
  const Panalnotification({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(NotificationController());
    controller.showNotificationData();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 7),
          style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              backgroundColor: Colors.white),
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            weight: .1,
            color: Colors.black.withValues(alpha: .6),
          ),
        ),
        title: Text(
          'Notification',
          style: TextStyle(color: Colors.black.withValues(alpha: .6)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.notificationListData.isEmpty) {
                return ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      margin: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                      ),
                      child: ListTile(
                        leading: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: Get.height * 0.06,
                            height: Get.height * 0.08,
                            color: Colors.grey,
                          ),
                        ),
                        title: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 15,
                            width: double.infinity,
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 12,
                            width: double.infinity,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 12,
                            width: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                // Show real list
                return ListView.builder(
                  itemCount: controller.notificationListData.length,
                  itemBuilder: (context, index) {
                    var notification = controller.notificationListData[index];
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      margin: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl:
                                ImageHelper.getImageUrl('${notification['sender']['profile_image']}'),
                            fit: BoxFit.cover,
                            height: Get.height * 0.08,
                            width: Get.height * 0.06,
                          ),
                        ),
                        title: Text(
                          'UID : ${notification['sender']['user_id']}',
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                        subtitle: Text(
                          '${notification['sender']['name']} is now on live! Tap to view!',
                          style: TextStyle(fontSize: 13),
                        ),
                        trailing: Text(
                          (notification?['sender']?['created_at'] != null)
                              ? DateFormat('hh:mm a').format(
                                  DateTime.parse(notification!['sender']
                                          ['created_at']
                                      .toString()),
                                )
                              : "--:--", // fallback
                          style: GoogleFonts.lato(fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              }
            }),
          )


        ],
      ),
    );
  }
}
