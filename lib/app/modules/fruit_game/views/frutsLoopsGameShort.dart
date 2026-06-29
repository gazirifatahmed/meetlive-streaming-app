import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/fruit_game_controller.dart';
import 'buttondesign.dart';
import 'cardstyle.dart';

class frutsLoopsGameShort extends StatefulWidget {
  const frutsLoopsGameShort({super.key});

  @override
  State<frutsLoopsGameShort> createState() => _frutsLoopsGameShortState();
}

class _frutsLoopsGameShortState extends State<frutsLoopsGameShort> {
  StreamController<int> controller = StreamController<int>.broadcast();
  final fruitController = Get.put(FruitGameController());
  AuthController authController = Get.find();
  List items = [];

  int selectedNumBerCount = 0,
      selectedNumber1 = 0,
      selectedNumber2 = 0,
      selectedAmount = 0;
  bool winDone = false;

  int coinsFor1 = 0, coinsFor2 = 0, coinsFor3 = 0;

  bool pot1Selected = false, pot2Selected = false, pot3Selected = false;
  int totalBetAmount = 0, totalWinAmount = 0;

  void resetGameState() {
    fruitController.amount1.value = 0;
    fruitController.amount2.value = 0;
    fruitController.amount3.value = 0;

    totalBetAmount = 0;
    totalWinAmount = 0;
    selectedNumBerCount = 0;
    selectedNumber1 = 0;
    selectedNumber2 = 0;
    coinsFor1 = 0;
    coinsFor2 = 0;
    coinsFor3 = 0;
    pot1Selected = false;
    pot2Selected = false;
    pot3Selected = false;
    winDone = false;
    animationImage.value = '';
    stopCoinsAudio();
    if (mounted) {
      setState(() {});
    }
  }

  final AudioPlayer audioPlayerBackground = AudioPlayer();
  final AudioPlayer audioPlayerCoins = AudioPlayer();

  Future<void> stopBackgroundAudio() async {
    await audioPlayerBackground.stop();
  }

  Future<void> stopCoinsAudio() async {
    await audioPlayerCoins.stop();
  }

  final animationImage = ''.obs;

  void setupControllerObservers() {
    ever(fruitController.winnerNumber, (winnerNum) {
      controller.add(winnerNum);
      if (mounted) {
        setState(() {});
      }
    });

    DateTime? lastResetTime; // Class এর top এ declare করুন

    ever(fruitController.remainingTime, (int time) {
      switch (time) {
        case 20: // New round start (Backend থেকে automatically আসবে)
          if (lastResetTime != null) {
            final difference = DateTime.now().difference(lastResetTime!);
            print(
                "⏰ Next round আসতে সময় লেগেছে: ${difference.inSeconds} seconds");
          }

          print("game reset called");
          resetGameState();
          lastResetTime = DateTime.now(); // Reset time record করুন
          break;

        case 1:
          print("game reset time (case 1 hit)");
          fruitController.playSpinSound();
          Future.delayed(const Duration(milliseconds: 2500), () {
            try {
              controller.add(fruitController.winnerNumber.value);
            } catch (_) {}
          });
          break;

        case 25:
          print("game reset win (case 24 hit)");
          Future.delayed(const Duration(milliseconds: 200), () async {
            await fruitController.fetchUserCoins();

            if (totalBetAmount > 0) {
              showWinDialog(
                context: context,
                bitAmount: totalBetAmount,
                winAmount: totalWinAmount,
              );
            }
            setState(() {});
          });
          break;

        default:
          print("⏱️ remainingTime: $time"); // সব time value দেখতে পারবেন
          break;
      }
    });
    ever(fruitController.amount1, (amount) {
      if (mounted) setState(() {});
    });
    ever(fruitController.amount2, (amount) {
      if (mounted) setState(() {});
    });
    ever(fruitController.amount3, (amount) {
      if (mounted) setState(() {});
    });

    ever(fruitController.activeUsers, (usersList) {
      if (mounted) setState(() {});
    });
  }

  final AudioPlayer audioPlayer = AudioPlayer();

  String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else {
      double result = number / 1000;
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}k';
    }
  }

  @override
  void initState() {
    super.initState();
    fruitController.userCurrentCoins.value =
        int.parse(authController.userProfile.value.user!.coins!);
    setupControllerObservers();
    fruitController.joinGame(
        userId: authController.userProfile.value.user!.id!.toInt());
    fruitController.fetchStatus();
  }

  @override
  void dispose() {
    fruitController.stopBgm();
    fruitController.leaveGame(
        userId: authController.userProfile.value.user!.id!.toInt());
    controller.close();
    super.dispose();
  }

  void showWinDialog({
    required BuildContext context,
    required int bitAmount,
    required int winAmount,
  }) {
    Get.dialog(
      Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          height: 160,
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(0),
            border: GradientBoxBorder(
              gradient: LinearGradient(
                colors: [
                  Colors.purpleAccent,
                  Colors.blueAccent,
                  Colors.cyanAccent,
                ],
              ),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Your Bet: $bitAmount",
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You Win: $winAmount",
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    Future.delayed(const Duration(seconds: 4), () {
      Get.back();
    });
  }

  bool isLoading = true;
  final isMute = false.obs;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    });

    return Scaffold(
      // Use Scaffold for a full-screen page
      body: Container(
        height: size.height, // Full height
        width: size.width, // Full width
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/game/frootsBgImage.png'),fit: BoxFit.cover),
          // Removed borderRadius as it's a full screen, not a bottom sheet
          // borderRadius: BorderRadius.only(
          //   topLeft: Radius.circular(30),
          //   topRight: Radius.circular(30),
          // ),
        ),
        child: isLoading ? _buildLoadingScreen() : _buildGameScreen(size),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fruit Loop Image - Responsive height
            Image.asset(
              "assets/game/Fruit Loops logo with vibrant fruits.png",
              height: MediaQuery.of(context).size.height *
                  0.35, // Screen height এর 35%
            ),


            // Progress Indicator - Responsive width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearPercentIndicator(
                width: MediaQuery.of(context).size.width * 0.75,
                // Screen width এর 75%
                animation: true,
                animationDuration: 2000,
                lineHeight: 18.0,
                percent: 1,
                center: const Text(
                  "100.0%",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                barRadius: const Radius.circular(15),
                linearStrokeCap: LinearStrokeCap.roundAll,
                progressColor: const Color(0xfff13c04),
                backgroundColor: const Color(0xffa706fd),
                curve: Curves.bounceIn,
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildTopActionButtons() {
    return GestureDetector(
      onTap: () => _showMoreOptionsPopup(),
      child: Container(
        padding: EdgeInsets.all(kHeight * 0.008),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9B0AEF), Color(0xFF4F0AEF)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: kHeight * 0.025,
        ),
      ),
    );
  }

  void _showMoreOptionsPopup() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final size = MediaQuery.of(context).size;

    showMenu(
      context: context,
      color: Colors.transparent,
      elevation: 0,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(
            Offset(button.size.width - size.width * 0.38, kHeight * 0.06),
            ancestor: overlay,
          ),
          button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: _buildPopupContent(),
        ),
      ],
    );
  }

  Widget _buildPopupContent() {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width * 0.38,
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.008,
        horizontal: size.width * 0.02,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C0A3A), Color(0xFF0D0820)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF9B0AEF).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPopupOption(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () {
              Navigator.pop(context);
              _showSettingsDialog();
            },
          ),
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(vertical: size.height * 0.004),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF9B0AEF).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          _buildPopupOption(
            icon: Icons.people_alt_rounded,
            label: 'Players',
            onTap: () {
              Navigator.pop(context);
              _showPlayerListDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopupOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.025,
          vertical: size.height * 0.01,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(size.width * 0.015),
              decoration: BoxDecoration(
                color: const Color(0xFF9B0AEF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF9B0AEF),
                size: size.height * 0.022,
              ),
            ),
            SizedBox(width: size.width * 0.025),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: size.height * 0.016,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGameScreen(Size size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Background Image
        const SizedBox.expand(
          child: Image(
            image: AssetImage("assets/game/frootsBgImage.png"),
            fit: BoxFit.cover,
          ),
        ),

        // 2. Main Game Content
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              left: kWeight * 0.01,
              right: kWeight * 0.01,
              top: kHeight * 0.04,
            ),
            child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                _buildGamePots(size),
              ],
            ),
          ),
        ),

        // 3. Bottom Coin Selection Bar
        Positioned(
          bottom: 25,
          left: 0,
          right: 0,
          child: _buildCoinSelectionBar(size),
        ),

        // 4. Fortune Wheel
        Positioned(
          top: -MediaQuery.of(context).size.height * 0.13,
          left: 0,
          right: 0,
          child: Center(child: _buildFortuneWheel()),
        ),

        // 5. Spin Frame — IgnorePointer দিয়ে wrap করা হয়েছে ✅
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Image.asset(
              'assets/game/fff.png',
              height: kHeight * 0.16,
            ),
          ),
        ),

        // 6. Timer (shows only when time <= 20)
        if (fruitController.remainingTime.value <= 20 &&
            fruitController.remainingTime.value > 0)
          Positioned(
            top: size.height * .09,
            right: size.width * .08,
            child: _buildTimerWidget(),
          ),

        // 7. Game Status Messages
        Positioned(
          top: size.height * .093,
          left: 0,
          right: 0,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kWeight * 0.06),
              child: _buildGameStatusMessage(size),
            ),
          ),
        ),

        // 8. Back & Trending Buttons
        Positioned(
          top: kHeight * 0.015,
          left: kWeight * 0.01,
          child: Column(
            spacing: 10,
            children: [
              _buildBackButton(),
              
              _buildTrendingButton(),
            ],
          ),
        ),

        // 9. Top Action Buttons — সবার শেষে, সবার উপরে ✅
        Positioned(
          top: kHeight * 0.015,
          right: kWeight * 0.01,
          child: Obx(() {
            final isOn = fruitController.isMusicOn.value;
            return GestureDetector(
              onTap: () => fruitController.toggleSound(),
              child: Container(
                padding: EdgeInsets.all(size.width * 0.02),
                decoration: BoxDecoration(
                  color: isOn
                      ? const Color(0xFF9B0AEF).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOn
                        ? const Color(0xFF9B0AEF).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: isOn
                      ? const Color(0xFF9B0AEF)
                      : Colors.white38,
                  size: size.height * 0.032,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
  Widget _buildTimerWidget() {
    final size = MediaQuery.of(context).size;
    return Obx(() {
      final time = ((fruitController.remainingTime.value) / 2).ceil();
      final isUrgent = time <= 5;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size.height * 0.06,
        height: size.height * 0.06,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: isUrgent
                ? [
              const Color(0xFFFF4444),
              const Color(0xFF990000),
            ]
                : [
              const Color(0xFF9B0AEF),
              const Color(0xFF3A0080),
            ],
          ),
          border: Border.all(
            color: Colors.transparent,
            width: 0,
          ),
          boxShadow: [
            // Outer glow
            BoxShadow(
              color: isUrgent
                  ? const Color(0xFFFF4444).withValues(alpha: 0.6)
                  : const Color(0xFF9B0AEF).withValues(alpha: 0.6),
              blurRadius: 16,
              spreadRadius: 2,
            ),
            // 3D bottom shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient border ring
            Container(
              width: size.height * 0.06,
              height: size.height * 0.06,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: isUrgent
                      ? [
                    const Color(0xFFFF4444),
                    const Color(0xFFFFAA00),
                    const Color(0xFFFF4444),
                  ]
                      : [
                    const Color(0xFF9B0AEF),
                    const Color(0xFF00C6FF),
                    const Color(0xFF4F0AEF),
                    const Color(0xFF9B0AEF),
                  ],
                ),
              ),
            ),

            // Inner circle (3D effect)
            Container(
              width: size.height * 0.052,
              height: size.height * 0.052,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.4),
                  radius: 1.0,
                  colors: isUrgent
                      ? [
                    const Color(0xFFFF6666),
                    const Color(0xFF880000),
                  ]
                      : [
                    const Color(0xFFBB44FF),
                    const Color(0xFF2A006A),
                  ],
                ),
              ),
            ),

            // Top shine (3D highlight)
            Positioned(
              top: size.height * 0.008,
              child: Container(
                width: size.height * 0.03,
                height: size.height * 0.015,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Timer number
            Text(
              time.toString(),
              style: TextStyle(
                fontSize: size.height * 0.026,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGamePots(Size size) {
    return Container(
      margin: EdgeInsets.only(top:  kHeight * 0.03, bottom: kHeight * 0.01),
      height: kHeight * 0.21,
      width: kWeight * 0.95,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow



          // Main body
          Container(
            margin: const EdgeInsets.all(1.5),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF43a4b5).withValues(alpha: .8),
                  const Color(0xFF43a4b5).withValues(alpha: .8),
                 
                ],
              ),

            ),
            child: Stack(
              children: [
                // Top shine (3D highlight)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: kHeight * 0.04,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom shadow strip (3D depth)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: kHeight * 0.03,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Pots row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPot(
                      fruitImage: "assets/game/orange.png",
                      potColor: Colors.orange,
                      potAmount: fruitController.amount1.value,
                      userAmount: coinsFor1,
                      onTap: () => _placeBet(1),
                      isWinner: winDone &&
                          fruitController.winnerNumber.value == 1, fruitName: 'Orange',
                    ),

                    // Vertical divider
                    Container(
                      width: 1,
                      height: kHeight * 0.1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFFf4b107).withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    _buildPot(
                      fruitImage: "assets/game/watermelon.png",
                      potColor: Colors.green,
                      potAmount: fruitController.amount2.value,
                      userAmount: coinsFor2,
                      onTap: () => _placeBet(2),
                      isWinner: winDone &&
                          fruitController.winnerNumber.value == 2, fruitName: 'Watermelon',
                    ),

                    // Vertical divider
                    Container(
                      width: 1,
                      height: kHeight * 0.1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFFf4b107).withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    _buildPot(
                      fruitImage: "assets/game/apple.png",
                      potColor: Colors.red,
                      potAmount: fruitController.amount3.value,
                      userAmount: coinsFor3,
                      onTap: () => _placeBet(3),
                      isWinner: winDone &&
                          fruitController.winnerNumber.value == 3, fruitName: 'Apple',
                    ),
                  ],
                ),



              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPot({
    required String fruitImage,
    required String fruitName, // নতুন প্যারামিটার
    required Color potColor,
    required int potAmount,
    required int userAmount,
    required VoidCallback onTap,
    required bool isWinner,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ফলের ওপরের ছোট আইকন অংশ (আগের মতোই থাকবে)
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: kHeight * 0.045,
            width: kHeight * 0.045,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: kHeight * 0.045,
                  height: kHeight * 0.045,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Color(0xffc5f0f8).withValues(alpha: .3),
                        Color(0xffc7f0f6).withValues(alpha: .3),

                      ],
                    ),

                  ),
                ),

                // Inner dark bg circle
                Container(
                  width: kHeight * 0.038,
                  height: kHeight * 0.038,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      radius: 1.0,
                      colors: [
                        Color(0xffc5f0f8).withValues(alpha: .5),
                        Color(0xffc5f0f8).withValues(alpha: .5),
                      ],
                    ),
                  ),
                ),

                // Fruit Image
                ClipOval(
                  child: Container(
                    width: kHeight * 0.034,
                    height: kHeight * 0.034,
                    padding: EdgeInsets.all(kHeight * 0.003),
                    child: Image(
                      image: AssetImage(fruitImage),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Top shine highlight (3D effect)
                Positioned(
                  top: kHeight * 0.004,
                  child: Container(
                    width: kHeight * 0.018,
                    height: kHeight * 0.009,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // ১. মেইন কার্ড বডি (আগের মতোই থাকবে)
              ClipPath(
                clipper: GameCardClipper(),
                child: Container(
                  height: kHeight * 0.14,
                  width: kWeight * 0.23,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: (winDone && !isWinner)
                          ? [Colors.blueGrey.shade400, Colors.blueGrey.shade800]
                          : [
                        potColor.withValues(alpha: 0.8),
                        potColor,
                        potColor.darken(0.2),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: kHeight * 0.025),
                      // Multiplier Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "X 3",
                          style: TextStyle(color: Colors.white, fontSize: kHeight * 0.012, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: kHeight * 0.01),
                      // Info Box
                      Container(
                        width: kWeight * 0.18,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _buildSimpleText("Pot: $potAmount"),
                            const Divider(height: 4, color: Colors.black26, thickness: 0.5),
                            _buildSimpleText("You: $userAmount"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ২. ডাইনামিক নাম এবং কালার অনুযায়ী ব্যাজ (এখানেই পরিবর্তন)
              Positioned(
                top: -kHeight * 0.01,
                child: NeonButton(
                  text: fruitName,
                  color: getFruitColor(fruitName),
                  width: kWeight * 0.2,   // 🔥 ছোট করা
                  height: kHeight * 0.025, // 🔥 ছোট করা
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  Widget _buildSimpleText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: kHeight * 0.012,
        fontStyle: FontStyle.italic,
      ),
    );
  }
  Widget _buildInfoBadge({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kWeight * 0.007,
        vertical: kHeight * 0.003,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: kHeight * 0.012),
          SizedBox(width: kWeight * 0.004),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: kHeight * 0.011,
              fontStyle: FontStyle.italic,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _placeBet(int betType) async {
    if (selectedAmount > 0 &&
        fruitController.remainingTime.value > 1 &&
        fruitController.remainingTime.value < 20) {
      if (selectedAmount > fruitController.userCurrentCoins.value) {
        debugPrint(
            'Bet blocked: selectedAmount=$selectedAmount exceeds available coins=${fruitController.userCurrentCoins.value}');
        Get.snackbar('Insufficient Balance', 'Please recharge',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2));
        return;
      }

      await fruitController.placeBet(
        userId: authController.userProfile.value.user!.id!.toInt(),
        betType: betType,
        amount: selectedAmount,
      );

      setState(() {
        bool potSelected = betType == 1
            ? pot1Selected
            : betType == 2
            ? pot2Selected
            : pot3Selected;

        if (potSelected) {
          if (betType == 1) coinsFor1 += selectedAmount;
          if (betType == 2) coinsFor2 += selectedAmount;
          if (betType == 3) coinsFor3 += selectedAmount;
          totalBetAmount += selectedAmount;
        } else {
          if (selectedNumBerCount < 2) {
            if (betType == 1) {
              pot1Selected = true;
              coinsFor1 += selectedAmount;
            }
            if (betType == 2) {
              pot2Selected = true;
              coinsFor2 += selectedAmount;
            }
            if (betType == 3) {
              pot3Selected = true;
              coinsFor3 += selectedAmount;
            }
            selectedNumBerCount++;
            totalBetAmount += selectedAmount;
          }
        }
      });
    }
  }

  Widget _buildCoinSelectionBar(Size size) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Stack(
        children: [
          // Outer glow
          Container(
            height: size.height * 0.075,
            width: double.infinity,
            decoration: BoxDecoration(

              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF84be44).withValues(alpha: 0.5),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
          ),

          // Sweep gradient border top
          Container(
            height: size.height * 0.075,
            width: double.infinity,
            decoration: BoxDecoration(

              gradient: LinearGradient(
                colors: [
                  const Color(0xFF96c26b),
                  const Color(0xFF96c26b),

                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          // Main body
          Container(
            margin: const EdgeInsets.only(top: 1.5),
            height: size.height * 0.075,
            width: double.infinity,
            decoration: BoxDecoration(

              gradient: LinearGradient(
                colors: [
                  const Color(0xFF84be44),
                  const Color(0xFFcbee6d),
                  const Color(0xFF84be44),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Top shine
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: size.height * 0.018,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(kHeight * 0.03),
                        topRight: Radius.circular(kHeight * 0.03),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.015,
                    vertical: 10
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      _buildCoinDisplay(),
                      _buildCoinButton(500),
                      _buildCoinButton(1000),
                      _buildCoinButton(10000),
                      _buildCoinButton(50000),
                      _buildCoinButton(100000),
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

  Widget _buildCoinDisplay() {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Coin display
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              height: kHeight * 0.046,
              width: size.width * 0.17,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFf4b107).withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),

            // Sweep gradient border
            Container(
              height: kHeight * 0.046,
              width: size.width * 0.17,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFf4b107),
                    Color(0xFFFF6B00),
                    Color(0xFFf4b107),
                    Color(0xFFFFD700),
                  ],
                ),
              ),
            ),

            // Inner body
            Container(
              height: kHeight * 0.043,
              width: size.width * 0.168,
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1C0A3A),
                    Color(0xFF0D0820),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Top shine
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: kHeight * 0.013,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(9),
                          topRight: Radius.circular(9),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom shadow
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: kHeight * 0.01,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(9),
                          bottomRight: Radius.circular(9),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content — perfectly centered
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Diamond icon with glow
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFf4b107).withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/game/diamond.png",
                            height: kHeight * 0.02,
                          ),
                        ),
                        SizedBox(width: kWeight * 0.008),
                        Obx(() {
                          double fontSize = kHeight * 0.016;
                          int coinValue = fruitController.userCurrentCoins.value;
                          if (coinValue >= 10000000) {
                            fontSize = kHeight * 0.010;
                          } else if (coinValue >= 1000000) {
                            fontSize = kHeight * 0.011;
                          } else if (coinValue >= 100000) {
                            fontSize = kHeight * 0.012;
                          }
                          return Text(
                            formatNumber(coinValue),
                            style: TextStyle(
                              color: const Color(0xFFf4b107),
                              fontSize: fontSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFf4b107).withValues(alpha: 0.5),
                                  offset: const Offset(0, 0),
                                  blurRadius: 6,
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(width: kWeight * 0.01),

        // Top-up button
        GestureDetector(
          onTap: () {
            // topup action
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Container(
                height: kHeight * 0.045,
                width: kHeight * 0.045,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C6FF).withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              // Gradient border
              Container(
                height: kHeight * 0.045,
                width: kHeight * 0.045,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00C6FF),
                      Color(0xFF9B0AEF),
                    ],
                  ),
                ),
              ),

              // Inner body
              Container(
                height: kHeight * 0.042,
                width: kHeight * 0.042,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A0A3A),
                      Color(0xFF0D0820),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top shine
                    Positioned(
                      top: kHeight * 0.004,
                      child: Container(
                        width: kHeight * 0.018,
                        height: kHeight * 0.008,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // + icon
                    Icon(
                      Icons.add_rounded,
                      color: const Color(0xFF00C6FF),
                      size: kHeight * 0.022,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00C6FF).withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoinButton(int amount) {
    final isSelected = selectedAmount == amount;
    String displayText =
    amount < 1000 ? amount.toString() : '${amount ~/ 1000}k';

    return GestureDetector(
      onTap: () => setState(() => selectedAmount = amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        height: isSelected ? kHeight * 0.065 : kHeight * 0.045,
        width: isSelected ? kHeight * 0.065 : kHeight * 0.045,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow (selected only)
            // Thin gradient border (selected only)

            // Inner
            Container(
              margin: isSelected
                  ? const EdgeInsets.all(1.8)
                  : EdgeInsets.zero,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Coin image — only zoom, no border
                  Image(
                    image: AssetImage(
                      amount == 1000 || amount == 50000
                          ? "assets/game/coin.png"
                          : "assets/game/coin2.png",
                    ),
                    fit: BoxFit.contain,
                  ),

                  // Top shine
                  Positioned(
                    top: kHeight * 0.004,
                    child: Container(
                      width: kHeight * 0.018,
                      height: kHeight * 0.008,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Amount text
                  Positioned(
                    bottom:isSelected? kHeight * 0.017:kHeight * 0.015,
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFf4b107)
                            : Colors.white,
                        fontSize: isSelected
                            ? kHeight * 0.014
                            : kHeight * 0.013,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTrendingButton() {
    return Container(
      margin: EdgeInsets.only(left: 6),
      padding: EdgeInsets.symmetric(vertical: 3,horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(colors: [
          Color(0xff9b0aef),
          Color(0xff4f0aef),
        ])
      ),
      child: InkWell(
        onTap: () => _showTrendingDialog(),
        child: Icon(Icons.refresh,color: Colors.white,),
      ),
    );
  }

  void _showTrendingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        return Container(
          height: size.height * 0.6, // একটু হাইট বাড়িয়ে দেওয়া হয়েছে
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header Section
              Padding(
                padding: EdgeInsets.all(size.width * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B0AEF), Color(0xFF7000FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Game Statistics',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Real-time history tracking',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.cancel, color: Colors.grey[400], size: 28),
                    ),
                  ],
                ),
              ),

              // Fruit Stats Cards
              Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFruitIcon("assets/game/orange.png", "Orange", Colors.orange),
                    _buildVerticalDivider(),
                    _buildFruitIcon("assets/game/watermelon.png", "Melon", Colors.green),
                    _buildVerticalDivider(),
                    _buildFruitIcon("assets/game/apple.png", "Apple", Colors.red),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Table Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderLabel('ROUND'),
                    _buildHeaderLabel('WINNER'),
                    _buildHeaderLabel('REWARD'),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // History List
              Expanded(
                child: Obx(() {
                  if (fruitController.winnerTrend.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                    itemCount: fruitController.winnerTrend.length,
                    itemBuilder: (context, index) {
                      final data = fruitController.winnerTrend[index];
                      return _buildHistoryRow(data, index);
                    },
                  );
                }),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 30, color: Colors.grey[200]);
  }

  Widget _buildFruitIcon(String assetPath, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Image.asset(assetPath, width: 24, height: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }

  Widget _buildHistoryRow(Map data, int index) {
    bool isWin = data['field2'] == 'Win'; // আপনার লজিক অনুযায়ী পরিবর্তন করুন
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: index % 2 == 0 ? Colors.grey[100]! : Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("#${data['field1']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),

          // Winner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isWin ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isWin ? "Winner" : "Loss",
              style: TextStyle(color: isWin ? Colors.green[700] : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),

          Text(
            data['field3'] ?? "---",
            style: TextStyle(color: Color(0xFF9B0AEF), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_toggle_off_rounded, size: 50, color: Colors.grey[200]),
        const SizedBox(height: 10),
        const Text("No history available", style: TextStyle(color: Colors.grey)),
      ],
    );
  }


  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        return Container(
          padding: EdgeInsets.only(
            left: size.width * 0.05,
            right: size.width * 0.05,
            top: size.height * 0.012,
            bottom: size.height * 0.04,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1C0A3A),
                const Color(0xFF0D0820),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(
              color: const Color(0xFF9B0AEF).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: size.width * 0.1,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(size.width * 0.018),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9B0AEF), Color(0xFF4F0AEF)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: size.height * 0.022,
                    ),
                  ),
                  SizedBox(width: size.width * 0.025),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.height * 0.02,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      Text(
                        'Sound & preferences',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: size.height * 0.013,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.015),

              // Gradient Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF9B0AEF).withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Sound Toggle Row


              SizedBox(height: size.height * 0.025),

              // Close Button

            ],
          ),
        );
      },
    );
  }

  void _showPlayerListDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        return Container(
          height: size.height * 0.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1C0A3A),
                const Color(0xFF0D0820),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(
              color: const Color(0xFF9B0AEF).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: EdgeInsets.only(top: size.height * 0.012),
                width: size.width * 0.1,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.012,
                  horizontal: size.width * 0.05,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(size.width * 0.018),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF9B0AEF),
                                Color(0xFF4F0AEF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: size.height * 0.022,
                          ),
                        ),
                        SizedBox(width: size.width * 0.025),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Player List',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.height * 0.02,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Obx(() => Text(
                              '${fruitController.activeUsers.length} active players',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: size.height * 0.013,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.none,
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(size.width * 0.018),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white60,
                          size: size.height * 0.02,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Gradient Divider
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF9B0AEF).withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.012),

              // Grid List
              Expanded(
                child: Obx(() {
                  if (fruitController.activeUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_rounded,
                            color: Colors.white12,
                            size: size.height * 0.05,
                          ),
                          SizedBox(height: size.height * 0.01),
                          Text(
                            'No active players',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: size.height * 0.016,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.height * 0.008,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: size.width > 600 ? 5 : 3,
                      crossAxisSpacing: size.width * 0.03,
                      mainAxisSpacing: size.height * 0.015,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: fruitController.activeUsers.length,
                    itemBuilder: (context, index) {
                      final user = fruitController.activeUsers[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF9B0AEF).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow ring
                                Container(
                                  width: size.width * 0.14,
                                  height: size.width * 0.14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF9B0AEF).withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: ImageHelper.getImageUrl(
                                        user['profile_image']),
                                    height: size.height * 0.055,
                                    width: size.height * 0.055,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Image(
                                  image: const AssetImage(
                                      "assets/game/profile frame.png"),
                                  height: size.height * 0.08,
                                  fit: BoxFit.fill,
                                ),
                              ],
                            ),
                            SizedBox(height: size.height * 0.006),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.01),
                              child: Text(
                                user['full_name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: size.height * 0.013,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),

              SizedBox(height: size.height * 0.1),
            ],
          ),
        );
      },
    );
  }
  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.of(context).pop(true),
      child: SizedBox(
        height: kHeight * 0.035,
        width: kHeight * 0.035,
        child: Icon(Icons.close,color: Colors.white,size:kHeight * 0.035 ,),
      ),
    );
  }

  Widget _buildFortuneWheel() {
    return SizedBox(
      height: kHeight * 0.29,
      width: kHeight * 0.31,
      child: FortuneWheel(
        onAnimationStart: () {},
        selected: controller.stream,
        styleStrategy: const UniformStyleStrategy(
          borderColor: Colors.transparent,
          color: Color(0xff9410d6),
        ),
        indicators: const <FortuneIndicator>[
          FortuneIndicator(
            alignment: Alignment.topCenter,
            child: TriangleIndicator(color: Colors.deepOrange),
          ),
        ],
        onAnimationEnd: () {
          // ১. চাকা থামা মাত্রই সাউন্ড বন্ধ হবে
          fruitController.stopSpinSound();

          // ২. বাকি ক্যালকুলেশন শুরু হবে
          setState(() {
            winDone = true;
            if (fruitController.winnerNumber.value == 1) {
              fruitController.userCurrentCoins.value =
                  fruitController.userCurrentCoins.value + (coinsFor1 * 3);
              totalWinAmount = totalWinAmount + (coinsFor1 * 3);
            }

            if (fruitController.winnerNumber.value == 2) {
              totalWinAmount = totalWinAmount + (coinsFor2 * 3);
              fruitController.userCurrentCoins.value =
                  fruitController.userCurrentCoins.value + (coinsFor2 * 3);
            }

            if (fruitController.winnerNumber.value == 3) {
              totalWinAmount = totalWinAmount + (coinsFor3 * 3);
              fruitController.userCurrentCoins.value =
                  fruitController.userCurrentCoins.value + (coinsFor3 * 3);
            }
          });
        },
        animateFirst: false,
        items: [
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 45),
              child:
              Image.asset('assets/game/apple.png', height: kHeight * 0.057),
            ),
          ),
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 45),
              child: Image.asset('assets/game/orange.png',
                  height: kHeight * 0.057),
            ),
          ),
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 45),
              child: Image.asset('assets/game/watermelon.png',
                  height: kHeight * 0.057),
            ),
          ),
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 45),
              child:
              Image.asset('assets/game/apple.png', height: kHeight * 0.057),
            ),
          ),
          FortuneItem(
              child: Container(
                margin: const EdgeInsets.only(left: 45),
                child:
                Image.asset('assets/game/orange.png', height: kHeight * 0.057),
              )),
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 45),
              child: Image.asset('assets/game/watermelon.png',
                  height: kHeight * 0.057),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatusMessage(Size size) {
    String message = '';
    if (fruitController.remainingTime.value == 22) {
      message = 'Start Bet';
    } else if (fruitController.remainingTime.value == 24) {
      message = 'Waiting for next Round';
    } else if (fruitController.remainingTime.value == 0) {
      message = 'Stop Bet';
    }

    if (message.isEmpty) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset('assets/game/waitingframe.png', height: size.height * .25),
        Text(
          message,
          style: GoogleFonts.roboto(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: kHeight * 0.02,
          ),
        ),
      ],
    );
  }
}
extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

Color getFruitColor(String fruit) {
  switch (fruit.toLowerCase()) {
    case "apple":
      return Colors.redAccent;
    case "banana":
      return Colors.amber;
    case "grape":
      return Colors.purpleAccent;
    case "orange":
      return Colors.orange;
    case "watermelon":
      return Colors.green;
    default:
      return Colors.blueAccent;
  }
}