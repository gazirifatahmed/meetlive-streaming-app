import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveMini_Container extends StatelessWidget {
  final Color background;
  final String text;

  const LiveMini_Container({
    super.key,
    required this.background,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: background,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
