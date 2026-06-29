import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/websocket_controller.dart';

class EmojiAnimationWidget extends StatelessWidget {
  final WebsocketController websocketController = Get.find();

  // সমাধান: কনস্ট্রাক্টর থেকে 'const' কিওয়ার্ডটি সরিয়ে ফেলা হয়েছে
  EmojiAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!websocketController.showEmojiAnimation.value || 
          websocketController.emojiAnimations.isEmpty) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 100,
        left: 20,
        right: 20,
        child: SizedBox(
          height: 200,
          child: Stack(
            children: websocketController.emojiAnimations.map((emojiData) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                top: 0,
                left: (websocketController.emojiAnimations.indexOf(emojiData) * 60.0) % 
                      (MediaQuery.of(context).size.width - 100),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 5),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -value * 150),
                      child: Opacity(
                        opacity: 1.0 - value,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                emojiData['emoji'] ?? '',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                emojiData['user']?['name'] ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}