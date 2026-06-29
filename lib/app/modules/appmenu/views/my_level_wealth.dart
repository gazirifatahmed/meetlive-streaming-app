import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/layout_constant.dart';

class MyLevelWealth extends StatelessWidget {
  const MyLevelWealth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            //-----------------card 1 ---------------
            Container(
              padding: EdgeInsets.symmetric(vertical: kHeight * 0.03),
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(colors: [
                    Color(0xffdfe5ff),
                    Color(0xffca89f4),
                    Color(0xff8662f8)
                  ])),
              child: Column(
                children: [
                  ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQIVccmV9VYm3TTIDXOnKakc1B2Mt8UFga_jgXEUH_31lY4xL2czYqn-kk&s',
                        fit: BoxFit.cover,
                        height: kHeight * 0.07,
                        width: kWeight * 0.12,
                      ),
                    ),
                    title: Text(
                      'TOM',
                      style: GoogleFonts.poppins(
                          color: Color(0xff7b0bd6),
                          fontSize: 20,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(right: kWeight * 0.56),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 1, horizontal: 3),
                        width: Get.width * 0.03,
                        decoration: BoxDecoration(
                          color: Color(0xff6deca8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          spacing: 5,
                          children: [
                            Icon(
                              Icons.currency_bitcoin,
                              size: 16,
                              color: Colors.yellow,
                            ),
                            Text(
                              '30',
                              style: GoogleFonts.mako(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: kWeight * 0.85,
                    child: LinearProgressIndicator(
                      value: 0.6, // 0.0 to 1.0 (optional, null দিলে indefinite)
                      backgroundColor: Color(0xff7b0bd6),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lv31',
                          style: GoogleFonts.lato(
                              color: Color(0xff7b0bd6),
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Upgrade level still need to  ',
                            style: GoogleFonts.poppins(
                                color: Color(0xff7b0bd6),
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            children: <TextSpan>[
                              TextSpan(
                                text: '29362',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Lv31',
                          style: GoogleFonts.lato(
                              color: Color(0xff7b0bd6),
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            //-----------------card 2 --------------
            Text(
              'Badge reward ',
              style:
                  GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: kHeight * 0.03,
            ),
            Text(
              ' Higher level gets better_loking badges ',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black12),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: kHeight * 0.03, horizontal: kWeight * 0.04),
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                  color: Color(0xfff6f6fe),
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                spacing: kHeight * 0.04,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CastomBadges(
                        bacground: Color(0xfff3a9a9),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xfff3c8a9),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xffb0f3a9),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xffd8a9f3),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xffa9f3df),
                        text: '  4',
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CastomBadges(
                        bacground: Color(0xffa9b8f3),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xffe9f3a9),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xffc7a9f3),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xfff3a9bf),
                        text: '  4',
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CastomBadges(
                        bacground: Color(0xffa9f3d9),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xffa9eaf3),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xffa9c9f3),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xffd5a9f3),
                        text: '  4',
                      ),
                      CastomBadges(
                        bacground: Color(0xfff3d5a9),
                        text: '  4',
                      ),
                    ],
                  )
                ],
              ),
            ),
            //-----------------card 3 ---------------
            Text(
              'Gifts reward ',
              style:
                  GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: kHeight * 0.03,
            ),
            Text(
              ' Higher level gets better_loking badges ',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black12),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: kHeight * 0.03, horizontal: kWeight * 0.03),
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                  color: Color(0xfff6f6fe),
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          CastomGiftReword(
                            image:
                                appLogo,
                            text: '365 Days',
                          ),
                          SizedBox(
                            height: kHeight * 0.01,
                          ),
                          Text(
                            '          contact\n '
                            'customer services',
                            style: GoogleFonts.poppins(
                                color: Color(0xffed9f45), fontSize: 12),
                          )
                        ],
                      ),
                      Column(
                        children: [
                          CastomGiftReword(
                            image:
                              appLogo,
                            text: '365 Days',
                          ),
                          SizedBox(
                            height: kHeight * 0.01,
                          ),
                          Text(
                            '          contact\n '
                            'customer services',
                            style: GoogleFonts.poppins(
                                color: Color(0xffed9f45), fontSize: 12),
                          )
                        ],
                      ),
                      Column(
                        children: [
                          CastomGiftReword(
                            image:
                                'assets/frame/f19eb9f3-67d8-4451-bce6-bfbe1dd4bd19.png',
                            text: '365 Days',
                          ),
                          SizedBox(
                            height: kHeight * 0.01,
                          ),
                          Text(
                            '          contact\n '
                            'customer services',
                            style: GoogleFonts.poppins(
                                color: Color(0xffed9f45), fontSize: 12),
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            Text(
              'How to upgrade?',
              style:
                  GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: kHeight * 0.03,
            ),
            Image(
              image: AssetImage(
                  'assets/frame/5ac45343-1da5-49c1-b607-044ed4015917.jpeg'),
              height: kHeight * 0.6,
            ),
          ],
        ),
      ),
    );
  }
}

class CastomGiftReword extends StatelessWidget {
  final String image;
  final String text;
  const CastomGiftReword({
    super.key,
    required this.image,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xffed9f45))),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: kHeight * 0.025, horizontal: kWeight * 0.055),
            child: Image(
              image: AssetImage(image),
              height: kHeight * 0.055,
            ),
          ),
          Container(
              padding: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10)),
                  color: Color(0xffecd9b8)),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                    color: Color(0xffed9f45),
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ))
        ],
      ),
    );
  }
}

class CastomBadges extends StatelessWidget {
  final Color bacground;
  final String text;
  const CastomBadges({
    super.key,
    required this.bacground,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: bacground,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        Positioned(
          left: -4,
          top: 0,
          child: Image.asset(
            'assets/frame/reward_6492776.png',
            height: kHeight * 0.022,
          ),
        ),
      ],
    );
  }
}
