import 'dart:async';
import 'dart:ui';

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

class BottomGamePage extends StatefulWidget {
  const BottomGamePage({super.key});

  @override
  State<BottomGamePage> createState() => _BottomGamePageState();
}

class _BottomGamePageState extends State<BottomGamePage> {
  StreamController<int> controller = StreamController<int>.broadcast();
  final fruitController = Get.put(FruitGameController());
  AuthController authController = Get.find();
  List items = [];

  int selectedNumBerCount = 0,
      selectedNumber1 = 0,
      selectedNumber2 = 0,
      selectedAmount = 0;
  bool winDone = false;
  bool _spinStartedForRound = false;
  bool _resultDialogShownForRound = false;

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
    _spinStartedForRound = false;
    _resultDialogShownForRound = false;
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
      // Winner number আসলেও সাথে সাথে wheel spin করাবো না।
      // remainingTime == 1 হলে wheel spin শুরু হবে।
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
          print("game spin start (case 1 hit)");
          if (!_spinStartedForRound) {
            _spinStartedForRound = true;
            fruitController.playSpinSound();
            try {
              controller.add(fruitController.winnerNumber.value);
            } catch (_) {}
          }
          break;

        case 0:
          print("Bet stopped");
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
          gradient: LinearGradient(
            colors: [
              Color(0xff301d53),
              Color(0xFFd85466),
              Color(0xFF080e6f),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fruit Loop Image - Responsive height
          Image.asset(
            "assets/game/fruitloop.png",
            height: MediaQuery.of(context).size.height *
                0.35, // Screen height এর 35%
          ),
          const SizedBox(height: 30),

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
              progressColor: const Color(0xffCE6D1B),
              backgroundColor: const Color(0xff613479),
              curve: Curves.bounceIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen(Size size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Image
        const SizedBox.expand(
          child: Image(
            image: AssetImage(
              "assets/audio_live/116398-abstract-dark-blue-blurred-bokeh-background-design.jpg",
            ),
            fit: BoxFit.cover,
          ),
        ),

        // Main Game Content
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              left: kWeight * 0.01,
              right: kWeight * 0.01,
              top: kHeight * 0.04,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPlayerColumn(0, 3),
                SizedBox(width: kWeight * 0.01),
                _buildGamePots(size),
                SizedBox(width: kWeight * 0.01),
                _buildPlayerColumn(3, 6),
              ],
            ),
          ),
        ),

        // Bottom Coin Selection Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildCoinSelectionBar(size),
        ),

        // Top Action Buttons
        Positioned(
          top: kHeight * 0.015,
          right: kWeight * 0.01,
          child: _buildTopActionButtons(),
        ),

        // Back & Trending Buttons

        // Fortune Wheel
        Positioned(
          top: -MediaQuery.of(context).size.height * 0.04,
          left: 0,
          right: 0,
          child: Center(child: _buildFortuneWheel()),
        ),

        // Spin Frame
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/game/spin_frame.png',
            height: kHeight * 0.17,
          ),
        ),

        // Timer (shows only when time <= 10)
        if (fruitController.remainingTime.value <= 20 &&
            fruitController.remainingTime.value > 0)
          Positioned(
            top: size.height * .07,
            right: size.width * .15,
            child: _buildTimerWidget(), // ✅ renamed for clarity
          ),

        // Game Status Messages
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
        Positioned(
          top: kHeight * 0.015,
          left: kWeight * 0.01,
          child: Row(
            children: [
              _buildBackButton(),
              SizedBox(width: kWeight * 0.04),
              _buildTrendingButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerWidget() {
    return Obx(() {
      final int time = fruitController.remainingTime.value;
      final bool isLastThreeSeconds = time <= 3 && time > 0;

      final timerBox = Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLastThreeSeconds ? 18 : 12,
          vertical: isLastThreeSeconds ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: isLastThreeSeconds
              ? Colors.redAccent.withValues(alpha: 0.88)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(isLastThreeSeconds ? 14 : 10),
          border: Border.all(
            color: isLastThreeSeconds ? Colors.yellowAccent : Colors.white,
            width: isLastThreeSeconds ? 2.5 : 1.5,
          ),
          boxShadow: isLastThreeSeconds
              ? [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.7),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ]
              : [],
        ),
        child: Text(
          time.toString(), // ✅ 1 second = 1 second
          style: TextStyle(
            fontSize: isLastThreeSeconds ? 34 : 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      if (!isLastThreeSeconds) return timerBox;

      return TweenAnimationBuilder<double>(
        key: ValueKey(time),
        tween: Tween<double>(begin: 0.55, end: 1.25),
        duration: const Duration(milliseconds: 450),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: timerBox,
      );
    });
  }

  Widget _buildPlayerColumn(int start, int end) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        end - start,
            (index) => Padding(
          padding: EdgeInsets.only(bottom: kHeight * 0.025),
          child: SizedBox(
            height: kHeight * 0.045,
            width: kHeight * 0.045,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (fruitController.activeUsers.length > start + index)
                  CachedNetworkImage(
                    imageUrl: ImageHelper.getImageUrl(
                      fruitController.activeUsers[start + index]
                      ['profile_image'],
                    ),
                    height: kHeight * 0.04,
                    fit: BoxFit.contain,
                  )
                else
                  Container(),
                const Image(
                  image: AssetImage("assets/game/profile_frame.png"),
                  fit: BoxFit.fill,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGamePots(Size size) {
    return Container(
      padding: EdgeInsets.only(bottom: 10, top: 5),
      margin: EdgeInsets.only(top: 0, bottom: kHeight * 0.02),
      height: kHeight * 0.16,
      width: kWeight * 0.7,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xfff4b107), width: kWeight * 0.002),
        borderRadius: BorderRadius.circular(7),
        color: Color(0xff6939fd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPot(
            fruitImage: "assets/game/orange.png",
            potColor: Colors.orange,
            potAmount: fruitController.amount1.value,
            userAmount: coinsFor1,
            onTap: () => _placeBet(1),
            isWinner: winDone && fruitController.winnerNumber.value == 1,
          ),
          _buildPot(
            fruitImage: "assets/game/watermelon.png",
            potColor: Colors.green,
            potAmount: fruitController.amount2.value,
            userAmount: coinsFor2,
            onTap: () => _placeBet(2),
            isWinner: winDone && fruitController.winnerNumber.value == 2,
          ),
          _buildPot(
            fruitImage: "assets/game/apple.png",
            potColor: Colors.red,
            potAmount: fruitController.amount3.value,
            userAmount: coinsFor3,
            onTap: () => _placeBet(3),
            isWinner: winDone && fruitController.winnerNumber.value == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPot({
    required String fruitImage,
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
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: kHeight * 0.03,
            width: kHeight * 0.032,
            child: Image(
              image: AssetImage(fruitImage),
              fit: BoxFit.fill,
            ),
          ),
          Stack(
            children: [
              Container(
                height: kHeight * 0.08,
                width: kWeight * 0.2,
                decoration: BoxDecoration(
                  color: (winDone && !isWinner) ? Colors.blueGrey : potColor,
                ),
                child: const Image(
                  image: AssetImage("assets/game/potframe.png"),
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: kHeight * 0.01,
                left: kWeight * 0.009,
                child: Row(
                  children: [
                    Text(
                      ' Pot: ',
                      style: GoogleFonts.roboto(
                          color: Colors.white, fontSize: kHeight * 0.013),
                    ),
                    Text(
                      potAmount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: kHeight * 0.012,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: kHeight * 0.015,
                left: kWeight * 0.01,
                child: Row(
                  children: [
                    Text(
                      "YOU : ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: kHeight * 0.013,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      userAmount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: kHeight * 0.012,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 40,
                bottom: 20,
                left: 55,
                right: 25,
                child: Text(
                  "x3",
                  style: TextStyle(color: Colors.black38, fontSize: 200),
                ),
              ),
              Positioned(
                top: 16,
                bottom: 30,
                left: 40,
                right: 25,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(fruitImage, fit: BoxFit.fill),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _placeBet(int betType) async {
    final int time = fruitController.remainingTime.value;

    // ✅ Bet only from 20 to 4 seconds. Last 3 seconds betting বন্ধ।
    if (selectedAmount <= 0) {
      Get.snackbar(
        'Select Coin',
        'Please select bet amount first',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (time <= 3 || time > 20) {
      Get.snackbar(
        'Bet Closed',
        'Last 3 seconds betting is closed',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final bool alreadySelected = betType == 1
        ? pot1Selected
        : betType == 2
        ? pot2Selected
        : pot3Selected;

    if (!alreadySelected && selectedNumBerCount >= 2) {
      Get.snackbar(
        'Limit Reached',
        'You can bet only 2 fruits in one round',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (selectedAmount > fruitController.userCurrentCoins.value) {
      debugPrint(
          'Bet blocked: selectedAmount=$selectedAmount exceeds available coins=${fruitController.userCurrentCoins.value}');
      Get.snackbar(
        'Insufficient Balance',
        'Please recharge',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // ✅ Tap করার সাথে সাথে main balance থেকে coin কেটে দেখাবে।
    setState(() {
      fruitController.userCurrentCoins.value -= selectedAmount;

      if (betType == 1) {
        coinsFor1 += selectedAmount;
        fruitController.amount1.value += selectedAmount;
        if (!pot1Selected) {
          pot1Selected = true;
          selectedNumBerCount++;
        }
      } else if (betType == 2) {
        coinsFor2 += selectedAmount;
        fruitController.amount2.value += selectedAmount;
        if (!pot2Selected) {
          pot2Selected = true;
          selectedNumBerCount++;
        }
      } else if (betType == 3) {
        coinsFor3 += selectedAmount;
        fruitController.amount3.value += selectedAmount;
        if (!pot3Selected) {
          pot3Selected = true;
          selectedNumBerCount++;
        }
      }

      totalBetAmount += selectedAmount;
    });

    try {
      await fruitController.placeBet(
        userId: authController.userProfile.value.user!.id!.toInt(),
        betType: betType,
        amount: selectedAmount,
      );
    } catch (e) {
      // ❌ API fail হলে local balance/pot rollback হবে।
      setState(() {
        fruitController.userCurrentCoins.value += selectedAmount;

        if (betType == 1) {
          coinsFor1 -= selectedAmount;
          fruitController.amount1.value -= selectedAmount;
          if (coinsFor1 <= 0) {
            coinsFor1 = 0;
            pot1Selected = false;
            selectedNumBerCount--;
          }
        } else if (betType == 2) {
          coinsFor2 -= selectedAmount;
          fruitController.amount2.value -= selectedAmount;
          if (coinsFor2 <= 0) {
            coinsFor2 = 0;
            pot2Selected = false;
            selectedNumBerCount--;
          }
        } else if (betType == 3) {
          coinsFor3 -= selectedAmount;
          fruitController.amount3.value -= selectedAmount;
          if (coinsFor3 <= 0) {
            coinsFor3 = 0;
            pot3Selected = false;
            selectedNumBerCount--;
          }
        }

        if (selectedNumBerCount < 0) selectedNumBerCount = 0;
        totalBetAmount -= selectedAmount;
        if (totalBetAmount < 0) totalBetAmount = 0;
      });

      Get.snackbar(
        'Bet Failed',
        'Please try again',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Widget _buildCoinSelectionBar(Size size) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(
          bottom: size.height * 0.018,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.015,
        ),
        height: size.height * 0.07,
        // responsive height
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF41416E),
              const Color(0x7E9494E3),
              const Color(0xFF41416E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(kHeight * 0.03),
              topLeft: Radius.circular(kHeight * 0.03)),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
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
    );
  }

  Widget _buildCoinDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kWeight * 0.008),
      height: kHeight * 0.04,
      width: MediaQuery.of(context).size.width * .15,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/game/diamond.png", height: kHeight * 0.017),
          SizedBox(
            width: kWeight * 0.002,
          ),
          Flexible(
            child: Obx(
                  () {
                double fontSize = kHeight * 0.016;
                int coinValue = fruitController.userCurrentCoins.value;

                if (coinValue >= 10000000) {
                  fontSize = kHeight * 0.010; // 10M+
                } else if (coinValue >= 1000000) {
                  fontSize = kHeight * 0.011; // 1M+
                } else if (coinValue >= 100000) {
                  fontSize = kHeight * 0.012; // 100K+
                }

                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatNumber(coinValue),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinButton(int amount) {
    String displayText =
    amount < 1000 ? amount.toString() : '${amount ~/ 1000}k';
    return InkWell(
      onTap: () => setState(() => selectedAmount = amount),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage(
                amount == 1000 || amount == 50000
                    ? "assets/game/casino3.png"
                    : "assets/game/casino2.png",
              ),
              height:
              selectedAmount == amount ? kHeight * 0.07 : kHeight * 0.06,
              width: selectedAmount == amount ? kHeight * 0.07 : kHeight * 0.06,
            ),
            Text(
              displayText,
              style: TextStyle(
                color: Colors.white,
                fontSize: kHeight * 0.011,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingButton() {
    return InkWell(
      onTap: () => _showTrendingDialog(),
      child: Container(
        height: kHeight * 0.03,
        width: kHeight * 0.03,
        decoration: const BoxDecoration(
          color: Colors.pink,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.trending_up, color: Colors.white),
      ),
    );
  }

  void _showTrendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.4, // Medium height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2A1A4D),
                  const Color(0xFF1A1335),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.purpleAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: kHeight * 0.01,
                    horizontal: kWeight * 0.04,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purpleAccent.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.purpleAccent,
                            size: kHeight * 0.025,
                          ),
                          SizedBox(width: kWeight * 0.02),
                          Text(
                            'Fruits Trending',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: kHeight * 0.02,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(kHeight * 0.008),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: kHeight * 0.02,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Fruit Icons Section
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: kHeight * 0.01,
                    horizontal: kWeight * 0.04,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: kHeight * 0.012,
                    horizontal: kWeight * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1F4A).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFruitIcon("assets/game/orange.png", "Orange"),
                      _buildFruitIcon("assets/game/watermelon.png", "Melon"),
                      _buildFruitIcon("assets/game/apple.png", "Apple"),
                    ],
                  ),
                ),

                // List Section
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: kWeight * 0.04),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1335).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Obx(() {
                      if (fruitController.winnerTrend.isEmpty) {
                        return Center(
                          child: Text(
                            'No trending data yet',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: kHeight * 0.016,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.all(kWeight * 0.01),
                        itemCount: fruitController.winnerTrend.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: kHeight * 0.006),
                            child: Container(
                              height: kHeight * 0.03,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF442C68).withValues(alpha: 0.6),
                                    const Color(0xFF2D1F4A).withValues(alpha: 0.4),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.purpleAccent.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: kWeight * 0.03,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                                children: [
                                  _buildResultText(
                                    fruitController.winnerTrend[index]
                                    ['field1'],
                                  ),
                                  _buildResultText(
                                    fruitController.winnerTrend[index]
                                    ['field2'],
                                  ),
                                  _buildResultText(
                                    fruitController.winnerTrend[index]
                                    ['field3'],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),

                SizedBox(height: kHeight * 0.015),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper Widget for Fruit Icons
  Widget _buildFruitIcon(String assetPath, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(kHeight * 0.008),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Image.asset(
            assetPath,
            width: kHeight * 0.025,
            height: kHeight * 0.025,
          ),
        ),
        SizedBox(height: kHeight * 0.005),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: kHeight * 0.01,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

// Helper Widget for Result Text
  Widget _buildResultText(String? value) {
    bool isWin = value == 'Win';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kWeight * 0.025,
        vertical: kHeight * 0.004,
      ),
      decoration: BoxDecoration(
        color: isWin ? Colors.pink.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isWin
            ? Border.all(color: Colors.pink.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Text(
        isWin ? 'WIN' : '—',
        style: TextStyle(
          color: isWin ? Colors.pink : Colors.white38,
          fontSize: kHeight * 0.01,
          fontWeight: isWin ? FontWeight.bold : FontWeight.normal,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTopActionButtons() {
    return Row(
      children: [
        _buildSettingButton(),
        SizedBox(width: kWeight * 0.03),
        // InkWell(
        //   child: Container(
        //     height: kHeight * 0.02,
        //     width: kHeight * 0.02,
        //     child: const Image(
        //       image: AssetImage("assets/game/question-mark.png"),
        //       fit: BoxFit.fill,
        //     ),
        //   ),
        // ),
        // const SizedBox(width: 15),
        _buildPlayerListButton(),
      ],
    );
  }

  Widget _buildSettingButton() {
    return InkWell(
      onTap: () => _showSettingsDialog(),
      child: SizedBox(
        height: kHeight * 0.035,
        width: kHeight * 0.035,
        child: const Image(
          image: AssetImage("assets/game/setting.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter, // 👈 নিচে show হবে
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1), // নিচ থেকে আসবে
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 25, left: 16, right: 16),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎵 Sound Setting',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        if (isMute.value) {
                          // playAudio();
                        } else {
                          stopCoinsAudio();
                          stopBackgroundAudio();
                        }
                        isMute.value = !isMute.value;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(() => Icon(
                              isMute.value
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              size: 35,
                              color: Colors.white,
                            )),
                            const SizedBox(width: 12),
                            const Text(
                              "ON / OFF",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerListButton() {
    return InkWell(
      onTap: () => _showPlayerListDialog(),
      child: SizedBox(
        height: kHeight * 0.03,
        width: kHeight * 0.03,
        child: const Image(
          image: AssetImage("assets/game/group.png"),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  void _showPlayerListDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        final size = MediaQuery.of(context).size;

        return Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: size.width * 0.94,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF141E30).withValues(alpha: 0.8),
                        const Color(0xFF243B55).withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        blurRadius: 25,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const Text(
                          '👥 Player List',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: size.height * 0.42,
                          child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: size.width > 600 ? 5 : 3,
                              crossAxisSpacing: 14.0,
                              mainAxisSpacing: 14.0,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: fruitController.activeUsers.length,
                            itemBuilder: (BuildContext context, int index) {
                              final user = fruitController.activeUsers[index];
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00C6FF),
                                      Color(0xFF0072FF)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.lightBlueAccent
                                          .withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(100),
                                          child: CachedNetworkImage(
                                            imageUrl: ImageHelper.getImageUrl(
                                                user['profile_image']),
                                            height: 55,
                                            width: 55,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const Image(
                                          image: AssetImage(
                                              "assets/game/profile_frame.png"),
                                          height: 65,
                                          fit: BoxFit.fill,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      user['full_name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 35, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Close",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
        child: const Image(
          image: AssetImage("assets/game/less-than_18757930.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFortuneWheel() {
    return SizedBox(
      height: kHeight * 0.16,
      width: kHeight * 0.31,
      child: FortuneWheel(
        onAnimationStart: () {},
        selected: controller.stream,
        styleStrategy: const UniformStyleStrategy(
          borderColor: Colors.transparent,
          color: Colors.blueAccent,
        ),
        indicators: const <FortuneIndicator>[
          FortuneIndicator(
            alignment: Alignment.topCenter,
            child: TriangleIndicator(color: Colors.deepOrange),
          ),
        ],
        onAnimationEnd: () {
          fruitController.stopSpinSound();

          if (_resultDialogShownForRound) return;
          _resultDialogShownForRound = true;

          setState(() {
            winDone = true;

            // ✅ Bet amount আগেই balance থেকে কাটা হয়েছে।
            // ✅ Win হলে শুধু payout add হবে, loss হলে আর কিছু add হবে না।
            if (fruitController.winnerNumber.value == 1) {
              totalWinAmount += coinsFor1 * 3;
            } else if (fruitController.winnerNumber.value == 2) {
              totalWinAmount += coinsFor2 * 3;
            } else if (fruitController.winnerNumber.value == 3) {
              totalWinAmount += coinsFor3 * 3;
            }

            if (totalWinAmount > 0) {
              fruitController.userCurrentCoins.value += totalWinAmount;
            }
          });

          if (totalBetAmount > 0) {
            showWinDialog(
              context: context,
              bitAmount: totalBetAmount,
              winAmount: totalWinAmount,
            );
          }
        },
        animateFirst: false,
        items: [
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 20),
              child:
              Image.asset('assets/game/apple.png', height: kHeight * 0.022),
            ),
          ),
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 20),
              child: Image.asset('assets/game/orange.png',
                  height: kHeight * 0.022),
            ),
          ),
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 20),
              child: Image.asset('assets/game/watermelon.png',
                  height: kHeight * 0.022),
            ),
          ),
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 20),
              child:
              Image.asset('assets/game/apple.png', height: kHeight * 0.022),
            ),
          ),
          FortuneItem(
              child: Container(
                margin: const EdgeInsets.only(left: 20),
                child:
                Image.asset('assets/game/orange.png', height: kHeight * 0.022),
              )),
          FortuneItem(
            child: Container(
              margin: const EdgeInsets.only(left: 20),
              child: Image.asset('assets/game/watermelon.png',
                  height: kHeight * 0.022),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatusMessage(Size size) {
    String message = '';
    if (fruitController.remainingTime.value == 20) {
      message = 'Start Bet';
    } else if (fruitController.remainingTime.value <= 3 &&
        fruitController.remainingTime.value > 0) {
      message = 'Stop Bet';
    } else if (fruitController.remainingTime.value == 0) {
      message = 'Waiting for next Round';
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
