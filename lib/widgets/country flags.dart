import 'package:country_flags/country_flags.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class countryflags extends StatelessWidget {
  final String country;
  final String text;

  const countryflags({
    super.key,
    required this.country,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(
      children: [
        CountryFlag.fromCountryCode(
          country,
          height: 20,
          width: 30,
        ),
        SizedBox(
          height: 7,
        ),
        Text(
          text,
          style: GoogleFonts.philosopher(
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        )
      ],
    ));
  }
}
