import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class castomSvipCard extends StatelessWidget {
  final Gradient? gradient;
  final Widget? child;
  const castomSvipCard({
    super.key,
    this.gradient,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: Get.height * 0.015, horizontal: Get.width * 0.017),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: gradient,
          border: Border.all(color: Color(0xffc3b0b0), width: 1.5)),
      child: child,
    );
  }
}

class BoatShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 40);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SvipOptionCard extends StatelessWidget {
  final String image;
  final String text;

  const SvipOptionCard({
    super.key,
    required this.image,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            vertical: Get.height * 0.014,
            horizontal: Get.height * 0.014,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xff6c665c), width: 0.7),
            color: Color(0xff2e2a22),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Image.asset(
            image,
            height: Get.height * 0.04,
          ),
        ),
        SizedBox(
          height: 12,
        ),
        Text(
          text,
          style: GoogleFonts.roboto(
              fontWeight: FontWeight.w400,
              fontSize: Get.height * 0.016,
              color: Color(0xfff3d16d)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
