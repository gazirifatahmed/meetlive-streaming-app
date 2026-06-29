import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../constants/constants.dart';
import '../../../../../constants/layout_constant.dart';
import '../../../../../widgets/after/castom appbar.dart';

class Joinfamily extends StatelessWidget {
  const Joinfamily({super.key});

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
                          fontSize: kHeight * 0.016),
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
                    height: kHeight * 0.09,
                  ),
                  //-----------------button ----------

                  // --------secound part -----------------
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: kHeight * 0.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xfff8e8ff),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  top: -kHeight * 0.06,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: kHeight * 0.018,
                      horizontal: kWeight * 0.03,
                    ),
                    margin: EdgeInsets.symmetric(
                      horizontal: kWeight * 0.03,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xffe3d0f5),
                          Color(0xfffefefe),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Color(0xffa455e3), width: 1.8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar & Info
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: kHeight * 0.09,
                                width: kHeight * 0.09,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xff9533fd), // or any color
                                    width: 2,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(kHeight * 0.01),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(kHeight * 0.01),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        'https://media.gettyimages.com/id/1317804578/photo/one-businesswoman-headshot-smiling-at-the-camera.jpg?s=612x612&w=gi&k=20&c=tFkDOWmEyqXQmUHNxkuR5TsmRVLi5VZXYm3mVsjee0E=',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: kWeight * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🌻 ${authController.userProfile.value.user!.name}',
                                      style: GoogleFonts.lato(
                                        fontSize: kHeight * 0.02,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepPurple,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'UID : ${authController.userProfile.value.user!.userId}',
                                      style: GoogleFonts.lato(
                                        fontSize: kHeight * 0.017,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Number numbers (89/20)',
                                      style: GoogleFonts.lato(
                                        fontSize: kHeight * 0.016,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
