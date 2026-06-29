import 'package:flutter/material.dart';

import '../../../../widgets/after/castom appbar.dart';
import 'BackPackStore.dart';

class Backpack extends StatelessWidget {
  const Backpack({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Back Pack',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [

            Expanded(child: Backpackstore()),

            // Row(
            //   spacing: 10,
            //   children: [
            //     Expanded(
            //       child: SizedBox(
            //         width: Get.width * 0.7,
            //         child: TabBar(
            //             isScrollable: true,
            //             indicatorColor: Color(0xff884DF7),
            //             labelColor: Colors.black,
            //             unselectedLabelColor: Colors.grey,
            //             splashBorderRadius: BorderRadius.circular(30),
            //             labelStyle: GoogleFonts.lato(
            //                 fontSize: 17, fontWeight: FontWeight.bold),
            //             tabs: [
            //               Tab(
            //                 child: Text('Avatar Frame'),
            //               ),
            //               Tab(
            //                 child: Text('Ride'),
            //               ),
            //               // Tab(
            //               //   child: Text('Banner'),
            //               // ),
            //               // Tab(
            //               //   child: Text('Lucky ID'),
            //               // ),
            //             ]),
            //       ),
            //     ),
            //
            //   ],
            // ),
            // Expanded(
            //     child: TabBarView(children: [
            //
            //   Backpackstore(),
            //   // Backpackstore(),
            //   // Backpackstore(),
            // ]))
          ],
        ),
      ),
    );
  }
}
