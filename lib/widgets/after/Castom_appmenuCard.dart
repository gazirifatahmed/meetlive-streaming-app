import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../constants/color_constants.dart';
import '../../constants/layout_constant.dart';

class castomCard extends StatelessWidget {
  final Color bacgroundColor;
  final VoidCallback? onPress;
  final double? height;
  final String text;
  final String image;
  const castomCard({
    super.key,
    required this.bacgroundColor,
    required this.text,
    required this.image,
    this.height,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: onPress,
        child: Container(
          width: kWeight * 0.215,
          alignment: Alignment.center,
          
          decoration: BoxDecoration(




            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: .2)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: .2)),
            ),
          
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: bacgroundColor),
                child: Image(
                  image: AssetImage(image),
                  height: kHeight * 0.012,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                text,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: kHeight * 0.009,
                    color: Colors.black),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class castomCard3 extends StatelessWidget {
  final Color bacgroundColor;
  final VoidCallback? onPress;
  final double? height;
  final String text;
  final String image;
  const castomCard3({
    super.key,
    required this.bacgroundColor,
    required this.text,
    required this.image,
    this.height,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: onPress,
        child: Container(
          width: kWeight * 0.215,
          alignment: Alignment.center,

          decoration: BoxDecoration(

            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: .3)),

            ),

          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: bacgroundColor),
                child: Image(
                  image: AssetImage(image),
                  height: kHeight * 0.012,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                text,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: kHeight * 0.009,
                    color: Colors.black),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class castomCard2 extends StatelessWidget {
  final Color bacgroundColor;
  final VoidCallback? onPress;
  final double? height;
  final String text;
  final String image;
  const castomCard2({
    super.key,
    required this.bacgroundColor,
    required this.text,
    required this.image,
    this.height,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: onPress,
        child: Container(
          width: kWeight * 0.215,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .2)),
            ),

          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: bacgroundColor),
                child: Image(
                  image: AssetImage(image),
                  height: kHeight * 0.012,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                text,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: kHeight * 0.009,
                    color: Colors.black),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class castomCard1 extends StatelessWidget {
  final Color bacgroundColor;
  final VoidCallback? onPress;
  final double? height;
  final String text;
  final String image;
  const castomCard1({
    super.key,
    required this.bacgroundColor,
    required this.text,
    required this.image,
    this.height,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              // Glass effect background
              color: Colors.white.withValues(alpha: 0.15),
              // Glass border
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              // 3D depth shadow
              boxShadow: [
                // Outer dark shadow (depth)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: Offset(4, 4),
                ),
                // Inner light highlight (3D shine)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: Offset(-3, -3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: SvgPicture.asset(
                  image,
                  width: kHeight * 0.025,
                  height: kHeight * 0.025,
                  colorFilter: const ColorFilter.mode(
                    kAppColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            text,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: kHeight * 0.009,
                color: Colors.black),
          )
        ],
      ),
    );
  }
}

class addvipcenter extends StatelessWidget {
  final String text;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;
  final Color fastColor;
  final IconData icon;
  final String secondText;
  final Color textcolor;
  final Color secondColor;
  final String image;
  final VoidCallback onTap;

  const addvipcenter({
    super.key,
    required this.text,
    required this.image,
    required this.textcolor,
    required this.onPressed,
    required this.fastColor,
    required this.secondColor,
    required this.secondText,
    required this.buttonText,
    required this.buttonColor,
    required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child:InkWell(
          onTap:onTap,
          child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .4)
                  ),
          gradient: LinearGradient(
            colors: [fastColor, secondColor],
          ),
          borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  icon,
                  size: kHeight * 0.06,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 15),
                  child: Row(
                    children: [
                      Image.asset(
                        image, // Use your coin icon here
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        secondText,
                        style: TextStyle(
                          fontSize: kHeight * 0.016,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: kHeight * 0.02,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

              ],
            ),
          ],
                ),
              ),
        )


        );
  }
}
