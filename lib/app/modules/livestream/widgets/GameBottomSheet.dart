import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomNameCard.dart';
import '../../fruit_game/views/bottomfrutegamePage.dart';
import '../../fruit_game/views/fruit_game_view.dart';


class GameBottomSheet extends StatelessWidget {
  final bool isGame;
  const GameBottomSheet({
    super.key,
    required this.isGame,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: kHeight * 0.02, horizontal: kWeight * 0.04),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xffad77e6), width: 2)),
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [
            Color(0xff1a0c2d),
            Color(0xff5e07b8),
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      width: double.infinity,
      height: kHeight * 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'GAME CENTER',
              style: GoogleFonts.lato(
                  fontSize: 19,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: kHeight * 0.02,
          ),

          //----------game card -----------

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              castom_game_card(
                onPress: () {
                  Get.back();
                  isGame
                      ? Get.to(() => FruitGameView())
                      : Get.bottomSheet(
                          backgroundColor:
                              Colors.transparent, // Bottom sheet এর color
                          barrierColor:
                              Colors.transparent, // Background dark করবে
                          isDismissible: true, // Tap করলে close হবে
                          enableDrag: true,
                          Container(
                            padding: EdgeInsets.only(bottom: kHeight * 0.02),
                            height: kHeight * 0.45,
                            child: BottomGamePage(),
                          ),
                        );
                },
                image: 'assets/grady/frutes game logo.png',
                text: 'Fruits Loop',
              ),
              castom_game_card(
                onPress: () {
                  Fluttertoast.showToast(
                    msg: "Coming Soon",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.grey,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                  // Get.to(() => GreedyGameView());
                },
                image: 'assets/frame/1ec4564f-084a-4222-bb3e-975a7c0d068f.png',
                text: 'King',
              ),
              castom_game_card(
                onPress: () {
                  Fluttertoast.showToast(
                    msg: "Coming Soon",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.grey,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                },
                image: 'assets/frame/ad4d23ae-e5e2-4401-af84-5e7d44b09603.png',
                text: 'Ludo',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
