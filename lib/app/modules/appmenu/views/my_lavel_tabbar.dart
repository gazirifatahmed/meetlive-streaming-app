import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'my_level_wealth.dart';

class MyLevel extends StatelessWidget {
  const MyLevel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              CupertinoIcons.arrow_left,
              color: Colors.white,
            ),
          ),
          title: Text(
            'My Level',
            style: TextStyle(color: Colors.white),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff8A4CF7),
                  Color(0xffB460F0),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              // width: Get.width * 0.5,
              decoration: BoxDecoration(color: Color(0xffffffff)),
              child: TabBar(
                indicatorColor: Color(0xff6d06da).withValues(alpha: 0.01),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    text: 'Wealth',
                  ),
                  Tab(
                    text: 'Charm',
                  ),
                  Tab(text: 'Growth'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Popular Section
                  MyLevelWealth(),
                  // Party Section
                  MyLevelWealth(),
                  MyLevelWealth(),
                  // Live Section
                  // Explore Section
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
