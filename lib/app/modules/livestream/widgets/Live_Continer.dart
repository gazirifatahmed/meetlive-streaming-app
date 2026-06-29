import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Live_Container extends StatelessWidget {
  final String text;
  final String name;

  const Live_Container({
    super.key,
    required this.text,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withValues(alpha: .2),
            image: const DecorationImage(
              image: AssetImage('assets/images/images (2).jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.black.withValues(alpha: .2),
                    ),
                    child: Row(
                      children: [
                        // পরিবর্তন ১: Icon থেকে FaIcon করা হয়েছে
                        const FaIcon(
                          FontAwesomeIcons.gift,
                          size: 10,
                          color: Colors.white,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0, right: 2.0),
                          child: Text(
                            text,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        // পরিবর্তন ২: Icon থেকে FaIcon করা হয়েছে
                        const FaIcon(
                          FontAwesomeIcons.starHalfStroke,
                          size: 10,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    // পরিবর্তন ৩: Icon থেকে FaIcon করা হয়েছে
                    child: FaIcon(
                      FontAwesomeIcons.house, // নোট: লেটেস্ট প্যাকেজে 'home' এর জায়গায় 'house' লেখা নিরাপদ
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // এটি Flutter-এর নিজস্ব Icons, তাই এখানে Icon উইজেটই থাকবে
                  const Icon(
                    Icons.mic,
                    color: Colors.green,
                    size: 18,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}