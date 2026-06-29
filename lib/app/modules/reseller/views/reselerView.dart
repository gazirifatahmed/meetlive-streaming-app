import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/reseller/views/reseller_view.dart';

import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../../trading/views/tradingsend.dart';
import 'ResellerTrading.dart';

class Reselerview extends StatelessWidget {
  const Reselerview({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Reseller',
        ),
        body: Column(
          children: [
            Container(
              // width: Get.width * 0.5,
              decoration: BoxDecoration(color: Color(0xffffffff)),
              child: TabBar(
                indicatorColor: Color(0xff050303),
                labelColor: Color(0xff050303),
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.lato(
                  fontSize: kHeight * 0.014,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    text: 'Reseller',
                  ),
                  Tab(
                    text: 'Trading',
                  ),
                  Tab(
                    text: 'History',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Popular Section
                  ResellerView(),
                  // Party Section
                  Resellertrading(),
                  Tradingsend(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
