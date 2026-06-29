import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';

class MemberInvite extends StatefulWidget {
  const MemberInvite({super.key});

  @override
  State<MemberInvite> createState() => _MemberInviteState();
}

class _MemberInviteState extends State<MemberInvite>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    informationcollectionController.showRequestAgenctList(
        agencyId: int.parse(
            verifiedController.agencySingleData['agency_id'].toString()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back_ios_new),
        ),
        centerTitle: true,
        title: Text('Member Request'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xffff5582),
          labelColor: Color(0xffff5582),
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Fun'),
            Tab(text: 'Apply'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFunTab(),
          _buildApplyTab(),
        ],
      ),
    );
  }

  // Fun Tab - List of profiles with invite button
  Widget _buildFunTab() {
    return SafeArea(
      child: Obx(() {
        return Column(
          children: [
            SizedBox(height: 20),
            _buildSearchField(),
            SizedBox(height: 20),
            Expanded(
              child:
                  informationcollectionController.newAgencyRequestList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: informationcollectionController
                              .newAgencyRequestList.length,
                          itemBuilder: (BuildContext context, int index) {
                            final userData = informationcollectionController
                                .newAgencyRequestList[index];
                            return _buildFunListItem(userData);
                          },
                        ),
            )
          ],
        );
      }),
    );
  }

  // Apply Tab - Your existing member request list
  Widget _buildApplyTab() {
    return SafeArea(
      child: Obx(() {
        return Column(
          children: [
            SizedBox(height: 20),
            _buildSearchField(),
            SizedBox(height: 20),
            Expanded(
              child:
                  informationcollectionController.newAgencyRequestList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: informationcollectionController
                              .newAgencyRequestList.length,
                          itemBuilder: (BuildContext context, int index) {
                            final agencyData = informationcollectionController
                                .newAgencyRequestList[index];
                            return agencyData['status'] == "Pending"
                                ? _buildApplyListItem(agencyData)
                                : Container();
                          },
                        ),
            )
          ],
        );
      }),
    );
  }

  // Search Field Widget
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8EAF6), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search members...',
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade600,
          ),
          suffixIcon: Icon(
            Icons.close,
            color: Colors.grey.shade600,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.8),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(
              color: Color(0xFFE5E2E6),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(
              color: Color(0xffff5582),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // Fun List Item - Profile with Invite Button
  Widget _buildFunListItem(Map<String, dynamic> userData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Profile Image
          CachedNetworkImage(
            imageUrl: "$kDomainUrl/${userData['user']['profile_image']}",
            imageBuilder: (context, imageProvider) => Container(
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
                width: 60,
                height: 60,
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
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['user']['name'] ?? 'N/A',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${userData['user']['user_id']}',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: .6),
                  ),
                ),
              ],
            ),
          ),
          // Invite Button
          InkWell(
            onTap: () {
              // Add your invite logic here
              print('Invite user: ${userData['user']['user_id']}');
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: kWeight * 0.05,
              ),
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
              child: Text(
                'Invite',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Apply List Item - Your existing design
  Widget _buildApplyListItem(Map<String, dynamic> agencyData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CachedNetworkImage(
                imageUrl: "$kDomainUrl/${agencyData['user']['profile_image']}",
                imageBuilder: (context, imageProvider) => Container(
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
                    width: 60,
                    height: 60,
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
                    width: 60,
                    height: 60,
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
                    text: 'ID: ${agencyData['user']['user_id']}',
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Castontext(
                        fontSize: Get.height * 0.015,
                        fontWeight: FontWeight.w400,
                        textColor: Colors.black.withValues(alpha: .6),
                        text:
                            'Name: ${(agencyData['user']['name'] ?? 'N/A').toString().length > 6 ? '${(agencyData['user']['name'] as String).substring(0, 6)}...' : (agencyData['user']['name'] ?? 'N/A')}',
                      ),
                      SizedBox(width: 6),
                      Castontext(
                        fontSize: Get.height * 0.015,
                        fontWeight: FontWeight.w400,
                        textColor: Colors.black.withValues(alpha: .6),
                        text: 'Status: ${agencyData['status'] ?? 'N/A'}',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  informationcollectionController.AceptCreate(
                      hostId: agencyData['id']);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: kWeight * 0.02,
                  ),
                  alignment: Alignment.center,
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: kHeight * 0.014,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: kHeight * 0.03),
              InkWell(
                onTap: () {
                  informationcollectionController.ARejectCreate(
                      hostId: agencyData['id']);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: kWeight * 0.02,
                  ),
                  alignment: Alignment.center,
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: kHeight * 0.014,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            "No Request Found",
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "There are no new agency requests right now.",
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
