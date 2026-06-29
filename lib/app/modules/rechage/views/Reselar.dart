import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/rechage/views/rechage_view.dart';

import '../../../../constants/layout_constant.dart';
import 'RechargeList.dart';

class Reselar extends StatelessWidget {
  const Reselar({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              gradient: LinearGradient(
                colors: [
                  Color(0xffade8f0), // Light Blue
                  Color(0xffcdaafc),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
          title: Text(
            'Recharge',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black, // text color change for visibility
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              // width: Get.width * 0.5,
              decoration: BoxDecoration(color: Color(0xffffffff)),
              child: TabBar(
                isScrollable: true,
                indicatorColor: Color(0xffade8f0),
                labelColor: Color(0xffade8f0),
                unselectedLabelColor: Color(0xff0b0a0b),
                labelStyle: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    text: 'Reseller List',
                  ),
                  Tab(
                    text: 'Recharge Offer',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: kHeight * 0.01,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Popular Section
                  Rechargelist(),
                  // Party Section
                  RechageView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
