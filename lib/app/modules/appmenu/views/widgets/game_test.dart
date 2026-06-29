import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



import '../../../../../constants/constants.dart';
import '../../../../../constants/image_helper.dart';
import '../../../../../constants/layout_constant.dart';

class LevelFrame extends StatelessWidget {
  final String level;

  const LevelFrame({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kHeight * 0.04, // পুরো ফ্রেমের ফিক্সড সাইজ
      width: kHeight * 0.07,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // // Background SVGA animation
          // authController.userProfile.value.user?.levelImage == null
          //     ?

          CachedNetworkImage(
            imageUrl: ImageHelper.getImageUrl(
              authController.userProfile.value.user?.levelImage ?? '',
            ),
            fit: BoxFit.cover,
            height: kHeight * 0.04,
            width: kHeight * 0.06,

            placeholder: (context, url) => SizedBox(
              height: kHeight * 0.04,
              width: kHeight * 0.06,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

            errorWidget: (context, url, error) => Image.asset(
              'assets/flaticons/lv__1_-removebg-preview.png',
              fit: BoxFit.cover,
              height: kHeight * 0.04,
              width: kHeight * 0.06,
            ),
          ),
              // : SizedBox(
              //     height: kHeight * 0.12,
              //     width: kHeight * 0.12,
              //     child: SVGAEasyPlayer(
              //       resUrl: ImageHelper.getImageUrl(
              //           authController.userProfile.value.user?.levelImage),
              //       fit: BoxFit.cover,
              //     ),
              //   ),
          Positioned(
            right: kHeight * 0.02,
            child: Text(
              level,
              style: GoogleFonts.roboto(
                fontSize: kHeight * 0.014,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black45,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
          // Level Text

        ],
      ),
    );
  }
}
