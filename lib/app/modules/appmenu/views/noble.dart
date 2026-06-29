import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/noblecastomcard.dart';

class NobleView extends StatelessWidget {
  const NobleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: kHeight * 0.17,
                decoration: BoxDecoration(color: Color(0xff8206e6)),
                child: Center(
                  child: Image.asset(
                    'assets/frame/e0374a23-41da-4371-a549-d8d51d5b3782-removebg-preview.png',
                    height: kHeight * 0.09,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: kWeight * 0.95,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: kHeight * 0.02),
                      Text(
                        'Aristocratic Privilege',
                        style: GoogleFonts.lato(
                          color: Color(0xff7b0cd6),
                          fontSize: kHeight * 0.017,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kHeight * 0.03),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, // প্রতি row তে কয়টা item
                            crossAxisSpacing: 12, // horizontal gap
                            mainAxisSpacing: 12, // vertical gap
                            childAspectRatio: 1, // width/height ratio
                          ),
                          itemCount: 4, // মোট কয়টা NobelCustomCard
                          itemBuilder: (context, index) {
                            return NobelCustomCard(
                              diayloText: 'Exclusive car',
                              image: 'assets/audio_live/new-car.png',
                            );
                          },
                        ),
                      ),

                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                      //   children: [
                      //     Column(
                      //       spacing: kHeight * 0.015,
                      //       children: [
                      //         NobelCustomCard(
                      //           diayloText: 'Approach effects',
                      //           image: 'assets/audio_live/effect.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Exclusive car',
                      //           image: 'assets/audio_live/new-car.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Rank top',
                      //           image: 'assets/audio_live/rank.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Anti-kick anti-ban',
                      //           image: 'assets/audio_live/computer.png',
                      //         ),
                      //       ],
                      //     ),
                      //     //-------second part ------------
                      //     Column(
                      //       spacing: kHeight * 0.015,
                      //       children: [
                      //         NobelCustomCard(
                      //           diayloText: 'Noble nameplate',
                      //           image: 'assets/audio_live/id-card.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Noble seat',
                      //           image: 'assets/audio_live/tea-set.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Exclusive car',
                      //           image: 'assets/audio_live/new-car.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Level acc elevation',
                      //           image: 'assets/audio_live/acces.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'List stealth',
                      //           image: 'assets/audio_live/pick-list.png',
                      //         ),
                      //       ],
                      //     ),
                      //     //-----3rd part--------------
                      //     Column(
                      //       spacing: kHeight * 0.015,
                      //       children: [
                      //         NobelCustomCard(
                      //           diayloText: 'Noble Avatar Frame',
                      //           image: 'assets/audio_live/painting.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Noble seat',
                      //           image: 'assets/audio_live/crown.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Exclusive car',
                      //           image: 'assets/audio_live/new-car.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Exclusive Gift',
                      //           image: 'assets/audio_live/gift.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Lucky Number',
                      //           image: 'assets/audio_live/red-envelope.png',
                      //         ),
                      //       ],
                      //     ),
                      //     //-------------4th part ----------
                      //     Column(
                      //       spacing: kHeight * 0.015,
                      //       children: [
                      //         NobelCustomCard(
                      //           diayloText: 'Premium Id card',
                      //           image: 'assets/audio_live/id-card.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Exclusive car',
                      //           image: 'assets/audio_live/new-car.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Chat skin',
                      //           image: 'assets/audio_live/chat.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Stealthy Approach',
                      //           image: 'assets/audio_live/pivot.png',
                      //         ),
                      //         NobelCustomCard(
                      //           diayloText: 'Exclusive car',
                      //           image: 'assets/audio_live/new-car.png',
                      //         ),
                      //       ],
                      //     ),
                      //   ],
                      // ),

                      SizedBox(
                          height: kHeight * 0.02), // space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '50000Coin/ ',
                        style: GoogleFonts.lato(
                          color: Colors.purple,
                          fontSize: kHeight * 0.016,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '15Day ',
                        style: GoogleFonts.lato(
                          color: Colors.black,
                          fontSize: kHeight * 0.016,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.bottomSheet(
                      Container(
                        height: kHeight * 0.4,
                        padding:
                            EdgeInsets.symmetric(horizontal: kWeight * 0.05),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20)),
                            color: Colors.white),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(''),
                                Text('SVIP 1'),
                                IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ))
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: kWeight * 0.05),
                              padding: EdgeInsets.symmetric(
                                  vertical: kHeight * 0.03,
                                  horizontal: kWeight * 0.045),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Color(0xff8811e8))),
                              child: Column(
                                children: [
                                  Text('15Day'),
                                  Text('50000'),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: kHeight * 0.02,
                            ),
                            Text('Remark'),
                            Text('1. 1 month= 30 days'),
                            Text(
                                '2.Equp the noble to use all the privilages of the noble '),
                            SizedBox(
                              height: kHeight * 0.04,
                            ),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff8206e6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50)),
                                  padding: EdgeInsets.symmetric(
                                      vertical: kHeight * 0.01,
                                      horizontal: kWeight * 0.1),
                                ),
                                child: Text(
                                  'Active now',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: kHeight * 0.016,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff8206e6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(
                        vertical: 12, horizontal: kWeight * 0.1),
                  ),
                  child: Text(
                    'Active now',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class nobelCastomCard extends StatelessWidget {
  final String text;
  final String image;
  const nobelCastomCard({
    super.key,
    required this.text,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print('Tapped');
        Get.dialog(
          Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff8206e6),
                    ),
                  ),
                  SizedBox(height: 20),
                  Image.asset(
                    'assets/images/logout.png',
                    height: 100,
                    width: 100,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                        ),
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back(); // add logout logic here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff8206e6),
                        ),
                        child: Text('Confirm',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Builder(builder: (context) {
        double kHeight = MediaQuery.of(context).size.height;
        return Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xffe4d8fa), Color(0xfff4f2f6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Image.asset(
                image,
                height: kHeight * 0.02,
              ),
            ),
            SizedBox(height: kHeight * 0.007),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: Color(0xff7b0cd6),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        );
      }),
    );
  }
}
