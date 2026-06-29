import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/image_helper.dart';


class GiftAnimationWidget extends StatefulWidget {
  final dynamic giftData;

  const GiftAnimationWidget({super.key, required this.giftData});

  @override
  State<GiftAnimationWidget> createState() => _GiftAnimationWidgetState();
}

class _GiftAnimationWidgetState extends State<GiftAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  AudioPlayer? _audioPlayer;
  bool _isDisposed = false;
  bool _isPlayingAudio = false; // Duplicate play প্রতিরোধের জন্য

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    // শুধুমাত্র একবার audio play করার জন্য
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_isDisposed && !_isPlayingAudio) {
        _playGiftAudio();
      }
    });

    // ৫ সেকেন্ড পর বন্ধ হবে
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted && !_isDisposed) {
        _controller.reverse().then((_) {
          if (mounted && !_isDisposed) {
            Navigator.of(context).maybePop();
          }
        });
      }
    });
  }

  Future<void> _playGiftAudio() async {
    // যদি ইতিমধ্যে play করা শুরু হয়ে গেছে, তাহলে return
    if (_isDisposed || _isPlayingAudio) {
      print("⚠️ Already playing or disposed");
      return;
    }

    _isPlayingAudio = true;

    try {
      final gift = widget.giftData['gift'];
      final audioPath = gift['audio'];

      if (audioPath == null || audioPath.toString().isEmpty) {
        print("⚠️ Audio path is empty or null");
        _isPlayingAudio = false;
        return;
      }

      String rawUrl = audioPath.toString().startsWith('http')
          ? audioPath.toString()
          : "$kAudioUrl/$audioPath";

      print("🔊 Original URL: $rawUrl");

      // নতুন AudioPlayer instance তৈরি করা
      _audioPlayer = AudioPlayer();

      // Player mode সেট করা
      await _audioPlayer!.setReleaseMode(ReleaseMode.release);
      await _audioPlayer!.setVolume(1.0);

      // Player state listener
      _audioPlayer!.onPlayerStateChanged.listen((PlayerState state) {
        print("🎵 Player State: $state");

        if (state == PlayerState.playing) {
          print("✅ Audio is playing successfully!");
        } else if (state == PlayerState.completed) {
          print("✅ Audio completed");
          _isPlayingAudio = false;
        } else if (state == PlayerState.stopped) {
          print("⏹️ Audio stopped");
          _isPlayingAudio = false;
        }
      });

      // Audio play করা - সরাসরি original URL দিয়ে
      print("▶️ Starting audio playback...");
      await _audioPlayer!.play(UrlSource(rawUrl));

      print("✅ Audio play command executed");
    } catch (e, stack) {
      print("❌ Audio Error: $e");
      print("📍 Stack: $stack");
      print(
          "💡 Suggestion: Check if audio file exists on server (404 error means file not found)");
      _isPlayingAudio = false;

      // Development mode তে user কে জানানো
      if (mounted) {
        // Remove this in production or make it conditional
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text("Audio file not found on server (404)"),
        //     duration: Duration(seconds: 2),
        //     backgroundColor: Colors.orange,
        //   ),
        // );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isPlayingAudio = false;

    // Audio player dispose করার আগে stop করা
    _audioPlayer?.stop().then((_) {
      _audioPlayer?.dispose();
      _audioPlayer = null;
    });

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gift = widget.giftData['gift'];
    final sender = widget.giftData['sender'];
    final receiver = widget.giftData['receiver'];

    // স্ক্রিনের সাইজ নেওয়া
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ১. Gift Animation
              Positioned.fill(
                child: gift['gift_image'].toString().endsWith('.svga')
                    ? SVGAEasyPlayer(
                  resUrl:
                  ImageHelper.getImageUrl("${gift['gift_image']}"),
                  fit: BoxFit.contain,
                )
                    : Image.network(
                  ImageHelper.getImageUrl("${gift['gift_image']}"),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(),
                ),
              ),

              // ২. টেক্সট ইনফো
              Positioned(
                bottom: 150,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                    border:
                    Border.all(color: Colors.yellowAccent.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${sender['name']} 🎁 ${receiver['name']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "${gift['name']} (${gift['coin']} coins)",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.yellowAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
