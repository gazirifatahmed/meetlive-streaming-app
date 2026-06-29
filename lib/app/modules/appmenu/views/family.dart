import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:meetlivepro/app/modules/appmenu/views/widgets/FamilyCreate.dart';

import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/castom appbar.dart';

class FamilyView extends StatelessWidget {
  const FamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Family',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xffB460F0),
                    Color(0xffB460F0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: kHeight * 0.04,
                  ),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: CircleAvatar(
                        radius: kHeight * 0.04,
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://media.gettyimages.com/id/1317804578/photo/one-businesswoman-headshot-smiling-at-the-camera.jpg?s=612x612&w=gi&k=20&c=tFkDOWmEyqXQmUHNxkuR5TsmRVLi5VZXYm3mVsjee0E=',
                          height: kHeight * 0.14,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 7,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      '🌻 ${authController.userProfile.value.user!.name} 🌻',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: kHeight * 0.012),
                    ),
                  ),
                  //-text-----------
                  SizedBox(
                    height: kHeight * 0.01,
                  ),
                  Text(
                    'You have not joined any family yet',
                    style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: kHeight * 0.015),
                  ),
                  SizedBox(
                    height: kHeight * 0.01,
                  ),
                  SizedBox(
                    height: 30,
                    width: kWeight * 0.8,
                    child: Marquee(
                      text: 'You have not joined any family yet',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: kHeight * 0.016,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      blankSpace: 20.0,
                      velocity: 50.0,
                      pauseAfterRound: Duration(seconds: 1),
                      startPadding: 10.0,
                      accelerationDuration: Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                    ),
                  ),
                  //-----------------button ----------
                  SizedBox(
                    height: kHeight * 0.015,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.to(Familycreate(),
                          transition: Transition.rightToLeft);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color(0xFF016B45), // dark green background
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                            color: Colors.amber, width: 3), // golden border
                      ),
                      elevation: 8,
                      shadowColor: Colors.amberAccent.withValues(alpha: 0.5),
                    ),
                    child: Text(
                      'Create family',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: kHeight * 0.015,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: kHeight * 0.03,
                  ),

                  // --------secound part -----------------

                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            topLeft: Radius.circular(20))),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image(
                                    image: AssetImage(
                                        'assets/frame/e62f3718-8b63-4ab2-96f3-fe49c1ad24b1-removebg-preview (1).png'),
                                    height: kHeight * 0.03,
                                  ),
                                  Text(
                                    'Family recommendation',
                                    style: GoogleFonts.lato(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: kHeight * 0.017),
                                  )
                                ],
                              ),
                              IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    CupertinoIcons.refresh,
                                    color: Colors.grey,
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: kHeight * 0.5,
                          child: ListView.builder(
                            itemCount: 10,
                            itemBuilder: (context, index) => Container(
                              padding: EdgeInsets.symmetric(
                                vertical: kHeight *
                                    0.018, // Responsive vertical padding
                                horizontal: kWeight * 0.03,
                              ),
                              margin: EdgeInsets.symmetric(
                                vertical: kHeight * 0.015,
                                horizontal: kWeight * 0.03,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xfffef0e6),
                                    Color(0xfffaf7f5)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Color(0xfff36c0b), width: 2),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              kHeight * 0.01),
                                          child: CircleAvatar(
                                            radius: kHeight *
                                                0.04, // Responsive avatar size
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  'https://media.gettyimages.com/id/1317804578/photo/one-businesswoman-headshot-smiling-at-the-camera.jpg?s=612x612&w=gi&k=20&c=tFkDOWmEyqXQmUHNxkuR5TsmRVLi5VZXYm3mVsjee0E=',
                                              fit: BoxFit.cover,
                                              height: kHeight * 0.09,
                                              width: kHeight * 0.09,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: kWeight * 0.03),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '🌻 ${authController.userProfile.value.user!.name}',
                                                style: GoogleFonts.lato(
                                                  fontSize: kHeight * 0.02,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'UID : ${authController.userProfile.value.user!.userId}',
                                                style: GoogleFonts.lato(
                                                  fontSize: kHeight * 0.018,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Number numbers (89/20)',
                                                style: GoogleFonts.lato(
                                                  fontSize: kHeight * 0.015,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: kWeight * 0.02),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFfd6e53),
                                            Color(0xFFfe555c)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: kHeight * 0.006,
                                          horizontal: kWeight * 0.04,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Apply',
                                          style: GoogleFonts.lato(
                                            fontSize: kHeight * 0.016,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
