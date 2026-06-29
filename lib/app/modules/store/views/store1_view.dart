import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/store/views/store_tabber_view/LuckyIdView.dart';
import 'package:meetlivepro/app/modules/store/views/store_tabber_view/bannerView.dart';
import 'package:meetlivepro/app/modules/store/views/store_tabber_view/rideView.dart';


import '../../../../widgets/after/castom appbar.dart';
import '../../coinshop/views/store_view.dart';
import '../controllers/store1_controller.dart';

class Store1View extends GetView<Store1Controller> {
  const Store1View({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Store',
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: Get.width * 0.7,
                      child: TabBar(
                          isScrollable: true,
                          indicatorColor: Color(0xffb94df7),
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          splashBorderRadius: BorderRadius.circular(30),
                          labelStyle: GoogleFonts.lato(
                              fontSize: 17, fontWeight: FontWeight.bold),
                          tabs: [
                            Tab(
                              child: Text('Avatar Frame'),
                            ),
                            Tab(
                              child: Text('Ride'),
                            ),
                            Tab(
                              child: Text('Banner'),
                            ),
                            Tab(
                              child: Text('Lucky ID'),
                            ),
                          ]),
                    ),
                  ),
                ],
              ),
              Expanded(
                  child: TabBarView(children: [
                StoreView(),
                Rideview(),
                Bannerview(),
                Luckyidview(),
              ]))
            ],
          ),
        ),
      ),
    );
  }
}
