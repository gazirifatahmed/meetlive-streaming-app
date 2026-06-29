import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';


import '../../../../constants/layout_constant.dart';
import '../controllers/invitation_controller.dart';

class InvitationView extends GetView<InvitationController> {
  const InvitationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Color
          Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(
                        'https://images.pexels.com/photos/7629316/pexels-photo-7629316.jpeg'),
                    fit: BoxFit.cover),
                gradient: LinearGradient(colors: [
                  Color(0xffb5a7fe),
                  Color(0xffffffff),
                ], begin: Alignment.topRight, end: Alignment.bottomRight)),
          ),

          // Main Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: kHeight * 0.04,
                      ),
                      Image.asset(
                        'assets/images/pngwing.com.png', // Replace with your asset path
                        height: kHeight * 0.13,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ),

                // Invite Instructions
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: kWeight * 0.03),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(kHeight * 0.01),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(Icons.person_add,
                                        size: kHeight * 0.03,
                                        color: const Color(0xff8A4CF7)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You invite a new friend "X"',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: kHeight * 0.011,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(Icons.monetization_on,
                                        size: kHeight * 0.027,
                                        color: Colors.amber),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Get 10% commission just by creating an ID and recharging!',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          fontSize: kHeight * 0.011),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(Icons.percent,
                                        size: kHeight * 0.021,
                                        color: Colors.blue),
                                    const SizedBox(height: 8),
                                    Text('You get up to 10%',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                            fontSize: kHeight * 0.011)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: kHeight * 0.014),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff8A4CF7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: Get.width * 0.3,
                                    vertical: kHeight * 0.012),
                              ),
                              onPressed: () {
                                Share.share(' https://yourapp.link');
                              },
                              child: Text(
                                'Invite',
                                style: GoogleFonts.poppins(
                                  fontSize: kHeight * 0.015,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Invite Image
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/invite_online.png',
                    ),
                  ),
                ),

                // Ranking Section
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Ranking Header
                      const SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: kWeight * 0.014,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events,
                                    color: Colors.orange),
                                Text(
                                  'Rank',
                                  style: GoogleFonts.poppins(
                                    fontSize: kHeight * 0.014,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: kHeight * 0.01,
                                      vertical: kHeight * 0.005),
                                  decoration: BoxDecoration(
                                    color: Color(0xffB460F0),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Monthly',
                                    style: GoogleFonts.poppins(
                                      fontSize: kHeight * 0.012,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: kHeight * 0.01,
                                      vertical: kHeight * 0.006),
                                  decoration: BoxDecoration(
                                    color: Color(0xff8A4CF7),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Total  ',
                                    style: GoogleFonts.poppins(
                                      fontSize: kHeight * 0.01,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Ranking List
                      SizedBox(
                        height: kHeight * 0.47,
                        child: ListView.builder(
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3.0, vertical: 8.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/king.png',
                                        height: kHeight * 0.03,
                                        width: kHeight * 0.03,
                                      ),
                                      const SizedBox(width: 3),
                                      CircleAvatar(
                                        backgroundImage: AssetImage(
                                          'assets/images/profileiamge.avif', // Replace with dynamic image
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    'Alice ${index + 1}',
                                    style: GoogleFonts.poppins(
                                      fontSize: kHeight * 0.014,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: kHeight * 0.01,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.pink,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.orangeAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'LV ${index + 1}',
                                              style: GoogleFonts.poppins(
                                                fontSize: kHeight * 0.01,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: kHeight * 0.01,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.pink,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.male,
                                              color: Colors.orangeAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '32',
                                              style: GoogleFonts.poppins(
                                                fontSize: kHeight * 0.01,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '\$${index + 1000}',
                                    style: GoogleFonts.poppins(
                                      fontSize: kHeight * 0.013,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
