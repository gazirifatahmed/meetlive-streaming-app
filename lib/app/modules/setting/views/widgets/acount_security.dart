import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../constants/color_constants.dart';
import '../../../../../constants/layout_constant.dart';
import '../../../../../widgets/after/CastomText.dart';
import '../LoginPassword.dart';

class CustomSettingOption extends StatelessWidget {
  const CustomSettingOption({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: ListTile(
        title: Text(
          'Account and security',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            fontSize: kHeight * 0.016, // Slightly larger for better readability
          ),
        ),
        trailing: SvgPicture.asset(
          'assets/audio_live/arrow_forward_ios_24dp_E3E3E3_FILL0_wght100_GRAD0_opsz24.svg',
          width: 100,
          color: kAppColor,
          height: kHeight * 0.024,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8), // Better spacing
        visualDensity: VisualDensity.comfortable, // Improved touch target size
        onTap: () {
          Get.dialog(
            Dialog(
              backgroundColor:
                  Colors.transparent, // transparent for custom shape
              insetPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 24), // dialog margin
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Account Security',
                      style: GoogleFonts.lato(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: kHeight * 0.018, // slightly bigger
                      ),
                    ),
                    SizedBox(height: 20),

                    // Login Password Card
                    Container(
                      decoration: BoxDecoration(color: Colors.grey[100]),
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        title: Text(
                          'Login Password',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: kAppColor,
                          size: kHeight * 0.02,
                        ),
                        onTap: () {
                          Get.to(LoginPassword(),
                              transition: Transition.rightToLeft);
                        },
                      ),
                    ),

                    SizedBox(height: 12),

                    // Optional: Add more security options here
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CastomSettingOption extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const CastomSettingOption({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        text,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w400,
          fontSize: kHeight * 0.016, // Slightly larger for better readability
        ),
      ),
      trailing: SvgPicture.asset(
        'assets/audio_live/arrow_forward_ios_24dp_E3E3E3_FILL0_wght100_GRAD0_opsz24.svg',
        width: 100,
        color: kAppColor,
        height: kHeight * 0.024,
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8), // Better spacing
      visualDensity: VisualDensity.comfortable, // Improved touch target size
      onTap: onPressed,
    );
  }
}

class CastomSettingOption1 extends StatelessWidget {
  final String text;
  final String secoundText;
  final VoidCallback? onPressed;
  const CastomSettingOption1({
    super.key,
    required this.text,
    this.onPressed,
    required this.secoundText,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        text,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w400,
          fontSize: kHeight * 0.016, // Slightly larger for better readability
        ),
      ),
      trailing: Castontext(
          fontSize: kHeight * 0.014,
          textColor: Colors.black.withValues(alpha: .5),
          text: secoundText),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8), // Better spacing
      visualDensity: VisualDensity.comfortable, // Improved touch target size
      onTap: onPressed,
    );
  }
}
