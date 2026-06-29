import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../apis/api_endpoints.dart';
import '../../../../../constants/layout_constant.dart';
import '../../../../../widgets/setheight.dart';
import '../../../backpack/controllers/store_controller.dart';
import '../../controllers/store1_controller.dart';

class Followinglist extends StatelessWidget {
  const Followinglist({super.key});

  @override
  Widget build(BuildContext context) {
    Store1Controller store1controller = Get.put(Store1Controller());

    StoreController storeController = Get.put(StoreController());
    // 🔹 Page load hole data fetch
    store1controller.showFollowingList();

    return Scaffold(
      body: Column(
        children: [
          SetHeight(heightSet: 0.02),
          Container(
            margin: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.grey[100],
            ),
            height: 40,
            child: TextFormField(
              onChanged: (value) {
                store1controller.searchByFollowing(value);
              },
              decoration: InputDecoration(
                hintText: "Search by User ID...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                contentPadding: EdgeInsets.symmetric(horizontal: 15),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SetHeight(heightSet: 0.01),

          // 🔹 Obx() use koro FutureBuilder na
          Expanded(
            child: Obx(() {
              // 🔹 Loading State
              if (store1controller.isFollowingLoading.value) {
                return ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(kHeight * 0.012),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Container(
                            height: 12,
                            width: 120,
                            color: Colors.grey,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Container(
                                height: 10,
                                width: 160,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 4),
                              Container(
                                height: 10,
                                width: 100,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          trailing: Container(
                            height: 14,
                            width: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              // 🔹 Empty State
              if (store1controller.filteredFollowingList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No following found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 🔹 Real Data
              return ListView.builder(
                itemCount: store1controller.filteredFollowingList.length,
                itemBuilder: (BuildContext context, int index) {
                  var follower = store1controller.filteredFollowingList[index];

                  // ✅ Safe null checking
                  var followingUser = follower['following'];

                  if (followingUser == null) {
                    return SizedBox.shrink(); // Skip if data is null
                  }

                  print('follower data: $followingUser');

                  // ✅ Extract values safely
                  String profileImage =
                      followingUser['profile_image']?.toString() ?? '';
                  String userName = followingUser['name']?.toString() ?? 'User';
                  String userId = followingUser['user_id']?.toString() ?? 'N/A';
                  String userType =
                      followingUser['user_type']?.toString() ?? 'Unknown';
                  String isOnline =
                      followingUser['is_online']?.toString() ?? 'false';

                  return InkWell(
                    onTap: () {
                      storeController.sendingAsset(userId: userId.toString());
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(kHeight * 0.012),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.1), // Changed from white
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profileImage.isNotEmpty
                                ? '$kMainUrl/$profileImage'
                                : 'https://ui-avatars.com/api/?name=$userName',
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.grey,
                            ),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          'Uid: $userId',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w600,
                            fontSize: kHeight * 0.016,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              'Name: $userName',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w500,
                                fontSize: kHeight * 0.012,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              userType,
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w500,
                                fontSize: kHeight * 0.012,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isOnline.toLowerCase() == 'true'
                                ? Colors.green
                                : Colors.grey,
                          ),
                          child: Text(
                            isOnline.toLowerCase() == 'true'
                                ? 'Online'
                                : 'Offline',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: kHeight * 0.013,
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
          )
        ],
      ),
    );
  }
}
