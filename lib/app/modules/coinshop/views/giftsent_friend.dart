import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../store/views/store_tabber_view/FollowingList.dart';
import 'friend_giftSent.dart';

class GiftSentFriend extends StatelessWidget {
  const GiftSentFriend({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            indicatorColor: Color(0xff050303),
            labelColor: Color(0xff050303),
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                text: 'Follower',
              ),
              Tab(
                text: 'Following',
              ),
            ],
          ),
          leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(Icons.arrow_back_ios_rounded)),
          centerTitle: true,
          title: Text(
            'Select gift object',
            style: GoogleFonts.lato(fontSize: 19, fontWeight: FontWeight.w600),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  // Popular Section

                  // Party Section
                  FollowerList(),
                  Followinglist(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
