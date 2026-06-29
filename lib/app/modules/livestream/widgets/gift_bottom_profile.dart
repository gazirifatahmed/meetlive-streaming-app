import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class gift_bottom_profile extends StatelessWidget {
  const gift_bottom_profile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Image(
              image: AssetImage('assets/images/profile pic.jpg'),
              height: 40,
            ),
            Positioned(
              top: 28,
              left: 1,
              child: Container(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
                // সমাধান: Icon-এর পরিবর্তে FaIcon এবং home-এর পরিবর্তে house ব্যবহার করা হয়েছে
                child: const FaIcon(
                  FontAwesomeIcons.house, 
                  color: Colors.white,
                  size: 10,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}