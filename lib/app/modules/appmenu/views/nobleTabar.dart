import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/layout_constant.dart';
import 'noble.dart';

class StylishTabBar extends StatelessWidget {
  const StylishTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff8A4CF7),
                  Color(0xffB460F0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              )),
          title: Text('List of Nobles',
              style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: kHeight * 0.021)),
          bottom: TabBar(
            indicatorPadding:
                EdgeInsets.symmetric(horizontal: -10, vertical: 8),
            isScrollable: true,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffa24bfd), Color(0xff7a32f8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: 'VIP 1'),
              Tab(text: 'VIP 2'),
              Tab(text: 'VIP 3'),
              Tab(text: 'VIP 4'),
              Tab(text: 'VIP 5'),
              Tab(text: 'VIP 6'),
              Tab(text: 'VIP 7'),
              Tab(text: 'SVIP'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NobleView(),
            NobleView(),
            NobleView(),
            NobleView(),
            NobleView(),
            NobleView(),
            NobleView(),
            NobleView(),
          ],
        ),
      ),
    );
  }
}
