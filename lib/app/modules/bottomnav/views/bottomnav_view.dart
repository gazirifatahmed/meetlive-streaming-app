import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../constants/color_constants.dart';
import '../../appmenu/views/appmenu_view.dart';
import '../../home/views/home_view.dart';
import '../../livestream/go_to_live/goto_live_tabbar.dart';
import '../../moments/views/moments_view.dart';
import '../../notification/views/notification_view.dart';

class BottomnavView extends StatefulWidget {
  const BottomnavView({super.key});

  @override
  State<BottomnavView> createState() => _BottomnavViewState();
}

class _BottomnavViewState extends State<BottomnavView>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _liveController;
  late AnimationController _borderController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  final List<Widget> _pages = [
    const HomeView(),
    MomentsView(),
    GotoLiveTabView(),
    NotificationView(),
    AppmenuView(),
  ];

  @override
  void initState() {
    super.initState();

    _liveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _liveController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.60).animate(
      CurvedAnimation(parent: _liveController, curve: Curves.easeInOut),
    );

    _checkAndRequestPermissions();
  }

  @override
  void dispose() {
    _liveController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;

    if ((!camera.isGranted || !mic.isGranted) && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _showPermissionDialog();
    }
  }

  Future<bool> _requestPermissions() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return camera.isGranted && mic.isGranted;
  }

  void _showPermissionDialog() {
    _showCustomDialog(
      icon: FontAwesomeIcons.triangleExclamation,
      iconColor: Colors.orange,
      title: "Permission Required",
      message: "Camera and microphone permissions are required for live streaming.",
      buttonText: "Grant Permission",
      buttonColor: kAppColor,
      onConfirm: () async {
        Navigator.pop(context);
        final granted = await _requestPermissions();
        if (!granted && mounted) _showSettingsDialog();
      },
    );
  }

  void _showSettingsDialog() {
    _showCustomDialog(
      icon: FontAwesomeIcons.gear,
      iconColor: Colors.red,
      title: "Open Settings",
      message: "Please enable camera and microphone permissions from app settings.",
      buttonText: "Open Settings",
      buttonColor: Colors.red,
      onConfirm: () {
        Navigator.pop(context);
        openAppSettings();
      },
    );
  }

  // সমাধান ১: প্যারামিটার টাইপ 'dynamic' বা 'IconData' রাখা হয়েছে যেন FontAwesomeIcons সরাসরি অ্যাক্সেপ্ট হয়।
  void _showCustomDialog({
    required dynamic icon, 
    required Color iconColor,
    required String title,
    required String message,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            // সমাধান ২: এখানে FaIcon ব্যবহার করা হয়েছে, যা টাইপ এরর ছাড়াই FontAwesome এর গ্লিচমুক্ত রেন্ডারিং নিশ্চিত করবে।
            FaIcon(icon, color: iconColor, size: 22), 
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.roboto(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.roboto(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(buttonText, style: GoogleFonts.roboto(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final exitApp = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Exit app",
          style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to exit?",
          style: GoogleFonts.roboto(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text("Yes", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    return exitApp ?? false;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          height: 64 + bottomPadding,
          padding: EdgeInsets.only(
            left: width * 0.045,
            right: width * 0.045,
            bottom: bottomPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAssetNavItem("assets/new/home.png", 0),
              _buildAssetNavItem("assets/new/youtube.png", 1),
              _buildCenterButton(),
              _buildAssetNavItem("assets/new/notification.png", 3, badge: "02"),
              _buildAssetNavItem("assets/new/user.png", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = _selectedIndex == 2;

    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Transform.translate(
        offset: const Offset(0, -16),
        child: AnimatedBuilder(
          animation: Listenable.merge([_liveController, _borderController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Transform.rotate(
                    angle: _borderController.value * 6.28318530718,
                    child: Container(
                      height: isSelected ? 52 : 50,
                      width: isSelected ? 52 : 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            Color(0xfff93776),
                            Color(0xff7f23e8),
                            Color(0xff218afb),
                            Color(0xfff93776),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff7B6CFF)
                                .withValues(alpha: _glowAnimation.value),
                            blurRadius: 22,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    height: isSelected ? 46 : 44,
                    width: isSelected ? 46 : 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffade8f0),
                          Color(0xffcdaafc),
                          Color(0xffA78BFA),
                          Color(0xffade8f0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff6C63FF)
                              .withValues(alpha: _glowAnimation.value),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          "assets/new/facetime-button.png",
                          height: 25,
                          width: 25,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAssetNavItem(
    String assetPath,
    int index, {
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 48,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xffF1EDFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: isSelected
                  ? ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xff9B8CFF),
                          Color(0xff6C63FF),
                          Color(0xff5AA9FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Image.asset(
                        assetPath,
                        height: 24,
                        width: 24,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      assetPath,
                      height: 24,
                      width: 24,
                      fit: BoxFit.contain,
                      color: const Color(0xffD7D7D7),
                    ),
            ),
            if (badge != null)
              Positioned(
                top: 4,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}