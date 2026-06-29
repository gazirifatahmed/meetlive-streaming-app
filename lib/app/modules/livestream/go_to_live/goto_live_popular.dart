import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/layout_constant.dart';
import '../../../services/agora_service.dart';
import '../controllers/agoraTokenController.dart';
import '../controllers/livestream_controller.dart';

class GotoPopularLive extends StatefulWidget {
  const GotoPopularLive({super.key});

  @override
  State<GotoPopularLive> createState() => _GotoPopularLiveState();
}

class _GotoPopularLiveState extends State<GotoPopularLive> {
  final LivestreamController liveController = Get.find<LivestreamController>();
  final AgoraService _agoraService = AgoraService();
  bool isEngineReady = false;

  final TextEditingController textEditingController = TextEditingController(
    text: 'hello',
  );

  Future<void> initAgora() async {
    print('GotoPopularLive: Checking Agora status...');

    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      print('Permissions not granted');
      if (mounted) {
        setState(() {
          isEngineReady = false;
        });
      }
      return;
    }

    bool success = _agoraService.isInitialized && _agoraService.engine != null;
    if (!success) {
      print('GotoPopularLive: AgoraService not ready, attempting to initialize...');
      success = await _agoraService.initializeEngine();
    }

    if (success && _agoraService.engine != null) {
      await _agoraService.engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 2000,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );
      await _agoraService.startPreview();
    }

    if (mounted) {
      setState(() {
        isEngineReady = success;
      });
    }

    if (success) {
      print('GotoPopularLive: Agora is ready');
    } else {
      print('GotoPopularLive: Failed to initialize Agora');
    }
  }

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    _agoraService.engine?.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double kHeight = Get.height; 
    final double kWeight = Get.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // === FULL SCREEN CAMERA BACKGROUND ===
          Positioned.fill(
            child: isEngineReady && _agoraService.engine != null
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _agoraService.engine!,
                      canvas: const VideoCanvas(
                        uid: 0,
                        renderMode: RenderModeType.renderModeHidden,
                        mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Initializing camera...',
                            style: GoogleFonts.lato(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // === UI OVERLAY ===
          SafeArea(
            child: Column(
              children: [
                // ==== Top bar ====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.dialog(
                          Dialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(
                              width: Get.width * 0.85,
                              padding: const EdgeInsets.all(16),
                              child: Obx(() {
                                final isPasswordMode =
                                    liveController.selectedType.value ==
                                        "Please set room password";

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color(0xffb5a7fe)),
                                        color: const Color(0xffb5a7fe),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CustomDropdown(
                                        closedHeaderPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 10),
                                        hintText: 'Select National ID Type',
                                        items: liveController.nationalIdentity,
                                        initialItem:
                                            liveController.nationalIdentity[0],
                                        canCloseOutsideBounds: true,
                                        decoration: CustomDropdownDecoration(
                                          prefixIcon: isPasswordMode
                                              ? const Icon(
                                                  Icons.password_outlined,
                                                  color: Color(0xff933efa),
                                                )
                                              : Image.asset(
                                                  'assets/audio_live/gift.png',
                                                  height: 20,
                                                  width: 20,
                                                ),
                                          closedSuffixIcon: const Icon(
                                            Icons.arrow_drop_down_outlined,
                                            color: Colors.black87,
                                          ),
                                          headerStyle: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                          closedFillColor:
                                              const Color(0xffb5a7fe),
                                          listItemStyle: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          hintStyle: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                          closedBorderRadius:
                                              BorderRadius.circular(8),
                                          expandedFillColor: Colors.white,
                                        ),
                                        onChanged: (value) {
                                          liveController.selectedType.value =
                                              value!.toString();
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      obscureText: isPasswordMode,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        hintText: isPasswordMode
                                            ? 'Enter your password'
                                            : 'Enter gift ',
                                        hintStyle:
                                            const TextStyle(color: Colors.grey),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 12),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: const BorderSide(
                                              color: Colors.black38),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: const BorderSide(
                                              color: Color(0xff8b42fa)),
                                        ),
                                        suffixIcon: isPasswordMode
                                            ? const Padding(
                                                padding: EdgeInsets.all(12.0),
                                                child: FaIcon(
                                                  FontAwesomeIcons.eyeSlash,
                                                  color: Color(0xff8b42fa),
                                                  size: 14,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Get.back();
                                        },
                                        child: const Text(
                                          "Confirm",
                                          style: TextStyle(
                                            color: Color(0xff8b42fa),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        // 🟢 কাস্টম উইজেট সরিয়ে সরাসরি স্ট্যান্ডার্ড Text উইজেট ব্যবহার করা হলো
                        child: Text(
                          'password',
                          style: TextStyle(
                            fontSize: kHeight * 0.017,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Get.back();
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // ==== Middle scrollable area ====
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                liveController.kycNidShow();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: kHeight * 0.01,
                                    horizontal: kWeight * 0.02),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                height: kHeight * 0.13,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.black38,
                                ),
                                child: Row(
                                  children: [
                                    Obx(() => liveController.videoImage.isEmpty
                                        ? Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xff2c0375), 
                                                  Color(0xff41026e),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                  spreadRadius: 2,
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.asset(
                                                appLogo,
                                                width: kHeight * 0.1,
                                                height: kHeight * 0.1,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => 
                                                    const Icon(Icons.image, color: Colors.white),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            width: kWeight * 0.21,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                File(liveController.videoImage.value),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}