import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/after/castom appbar.dart';

class ProfileFolloing extends StatelessWidget {
  ProfileFolloing({super.key});

  final List<Map<String, dynamic>> users = [
    {
      'name': 'Tom',
      'id': '18752',
      'status': 'joined',
      'imageUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRO_zU_CkIPahftPFxoH-_Ssrk0tTLz0BRkLYea4mE1MtJ3uPa-fwbK7Ppr1_XXtJagCOI',
    },
    {
      'name': 'Jerry',
      'id': '10498',
      'status': 'invite',
      'imageUrl': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'name': 'Tom',
      'id': '18752',
      'status': 'joined',
      'imageUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRO_zU_CkIPahftPFxoH-_Ssrk0tTLz0BRkLYea4mE1MtJ3uPa-fwbK7Ppr1_XXtJagCOI',
    },
    {
      'name': 'Jerry',
      'id': '10498',
      'status': 'invite',
      'imageUrl': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'name': 'Tom',
      'id': '18752',
      'status': 'joined',
      'imageUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRO_zU_CkIPahftPFxoH-_Ssrk0tTLz0BRkLYea4mE1MtJ3uPa-fwbK7Ppr1_XXtJagCOI',
    },
    {
      'name': 'Jerry',
      'id': '10498',
      'status': 'invite',
      'imageUrl': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Following',
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              Color(0xffb5a7fe),
              Color(0xffffffff),
            ], begin: Alignment.topRight, end: Alignment.bottomRight)),
          ),
          ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isJoined = user['status'] == 'joined';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xff843af4)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: CachedNetworkImage(
                        imageUrl: ImageHelper.getImageUrl(user['imageUrl']),
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Castontext(
                        textColor: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 19,
                        text: user['name']),
                    subtitle: Row(
                      children: [
                        Container(
                          height: 15,
                          width: 35,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(50),
                            ),
                            color: Color(0xff843af4),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                Icons.leaderboard,
                                size: 11,
                                color: Colors.white,
                              ),
                              Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: kWeight * 0.01,
                        ),
                        Container(
                          height: 15,
                          width: 35,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(50),
                            ),
                            color: Color(0xff843af4),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                Icons.male,
                                size: 11,
                                color: Colors.white,
                              ),
                              Text(
                                '22',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: kWeight * 0.01,
                        ),
                        Text(
                          '🇧🇩',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    trailing: isJoined
                        ? Text(
                            '',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              gradient: const LinearGradient(
                                colors: [Color(0xff9d67fd), Color(0xffc87efd)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Text(
                              'Living',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
