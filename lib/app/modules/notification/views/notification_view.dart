import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/constants/layout_constant.dart';

import '../../appmenu/views/widgets/Flower.dart';
import '../../appmenu/views/widgets/FlowingList.dart';
import '../../messanger/views/messanger_view.dart';
import '../controllers/notification_controller.dart';
import 'notificationCard.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: h * 0.065,

        // ❌ এটা remove করো
        backgroundColor: Colors.transparent,

        // ✅ Gradient add
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffade8f0), // Light Blue
                Color(0xffcdaafc), // light blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        title: Text(
          'Message',
          style: GoogleFonts.lato(
            fontSize: w * 0.048,
            fontWeight: FontWeight.w800,
            color: const Color(0xff222222),
          ),
        ),
      ),

      body: Column(
        children: [
          SizedBox(height: h * 0.025),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.065),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap:(){
                     Get.to(MessengerView(),transition: Transition.fade);
                        },
                  child: _topIcon(
                    w: w,
                    title: 'Messages',
                    icon: Icons.chat_bubble_outline,
                    colors: const [Color(0xff1AD8D2), Color(0xff2D9BF3)],
                  ),
                ),
                InkWell(
                  onTap: (){
                    Get.to(FollowinfList(),transition: Transition.fade);
                  },
                  child: _topIcon(
                    w: w,
                    title: 'Following',
                    icon: Icons.favorite_border,
                    showPlus: true,
                    colors: const [Color(0xffFFD64D), Color(0xffFF842D)],
                  ),
                ),
                InkWell(
                  onTap: (){
                    Get.to(Follower(),transition: Transition.rightToLeft);
                  },
                  child: _topIcon(   
                    w: w,
                    title: 'Follow',
                    icon: Icons.star_border,
                    colors: const [Color(0xffB84CFF), Color(0xff25C8FF)],
                  ),
                ),
                SizedBox(width: kWeight*0.08,)
              ],
            ),
          ),

          SizedBox(height: h * 0.032),

          Container(
            height: h * 0.018,
            color: const Color(0xffF5F5F5),
          ),

          Expanded(
            child: NotificationCardView(),
          ),
        ],
      ),
    );
  }

  Widget _topIcon({
    required double w,
    required String title,
    required IconData icon,
    required List<Color> colors,
    bool showPlus = false,
  }) {
    final circleSize = w * 0.112;

    return Column(
      children: [
        Container(
          height: circleSize,
          width: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: w * 0.05,
              ),
              if (showPlus)
                Positioned(
                  right: circleSize * 0.24,
                  bottom: circleSize * 0.27,
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: w * 0.025,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: w * 0.018),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: kHeight * 0.015,
            fontWeight: FontWeight.w500,
            color: const Color(0xff434343),
          ),
        ),
      ],
    );
  }

}