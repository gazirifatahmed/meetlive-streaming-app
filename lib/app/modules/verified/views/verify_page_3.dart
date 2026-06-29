import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/verified/views/verify_page_2.dart';
import 'package:shimmer/shimmer.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../controllers/verified_controller.dart';

class VerifyPage3 extends StatefulWidget {
  const VerifyPage3({super.key});

  @override
  State<VerifyPage3> createState() => _VerifyPage3State();
}

class _VerifyPage3State extends State<VerifyPage3> {
  Map<String, dynamic>? selectedUser;

  void searchUser(String uid) {
    print("Searching UID: $uid");
    print("Total Agency List: ${homeController.agencyList}");
    if (uid.isEmpty) {
      setState(() => selectedUser = null);
      return;
    }

    try {
      final user = homeController.agencyList.firstWhere(
        (u) => u['user_id'].toString() == uid,
      );

      setState(() {
        selectedUser = user;
      });
    } catch (e) {
      setState(() => selectedUser = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    VerifiedController verifiedController = Get.put(VerifiedController());
    homeController.showingAgencyList();
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Host Verify',
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.03,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                searchUser(value.trim());
              },
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: kHeight * 0.025, vertical: kHeight * 0.012),
                hintText: 'Search by Agency name or Id',
                hintStyle: TextStyle(
                    fontSize: kHeight * 0.014, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: TextStyle(fontSize: 16),
            ),
          ),

          /// --------------------- Agency Profile show --------------
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: kWeight * 0.9,
            child: selectedUser != null
                ? selectedUser == null
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[300],
                          ),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 10),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 150,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 100,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          verifiedController.agencyJoinPost(
                              agencyId: selectedUser!['user_id']);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[100],
                          ),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 10),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        "$kDomainUrl/${selectedUser!['profile_image']}",
                                    imageBuilder: (context, imageProvider) =>
                                        Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTD8qrkPg5tffSPQIqlxXcW-czht693ZlfJnHGej1zZUVvStsw638N4108&s',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Castontext(
                                        fontSize: Get.height * 0.016,
                                        fontWeight: FontWeight.w600,
                                        textColor: Colors.black.withValues(alpha: .6),
                                        text: 'ID: ${selectedUser!['id']}',
                                      ),
                                      const SizedBox(height: 5),
                                      Castontext(
                                        fontSize: Get.height * 0.015,
                                        fontWeight: FontWeight.w400,
                                        textColor: Colors.black.withValues(alpha: .6),
                                        text:
                                            'Name: ${selectedUser!['name'] ?? 'N/A'}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xff8A4CF7),
                                          Color(0xffB460F0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 20),
                                      child: Text(
                                        'Join',
                                        style: GoogleFonts.lato(
                                          color: Colors.white,
                                          fontSize: kHeight * 0.014,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                : SizedBox(),
          ),

          Expanded(child: Obx(() {
            return ListView.builder(
              itemCount: homeController.agencyList.length,
              itemBuilder: (BuildContext context, int index) {
                final agencyData = homeController.agencyList[index];
                return GestureDetector(
                  onTap: () {
                    // verifiedController.agencyJoinPost(
                    //     userId: selectedUser!['user_id']);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[100],
                    ),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CachedNetworkImage(
                              imageUrl:
                                  "$kDomainUrl/${agencyData['profile_image']}",
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTD8qrkPg5tffSPQIqlxXcW-czht693ZlfJnHGej1zZUVvStsw638N4108&s',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Castontext(
                                  fontSize: Get.height * 0.016,
                                  fontWeight: FontWeight.w600,
                                  textColor: Colors.black.withValues(alpha: .6),
                                  text: 'ID: ${agencyData['agency_id']}',
                                ),
                                const SizedBox(height: 5),
                                Castontext(
                                  fontSize: Get.height * 0.015,
                                  fontWeight: FontWeight.w400,
                                  textColor: Colors.black.withValues(alpha: .6),
                                  text: 'Name: ${agencyData['name'] ?? 'N/A'}',
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05,
                          child: ElevatedButton(
                            onPressed: () {
                              Get.offAll(VerifyPage2(),
                                  arguments: agencyData,
                                  transition: Transition.rightToLeft);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xff8A4CF7),
                                    Color(0xffB460F0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                child: Text(
                                  'Join',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: kHeight * 0.014,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }))
        ],
      ),
    );
  }
}
