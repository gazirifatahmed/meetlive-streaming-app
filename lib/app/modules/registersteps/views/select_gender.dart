import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:meetlivepro/app/modules/registersteps/views/set_dateofbith.dart';

import '../../../../widgets/after/castom appbar.dart';
import '../../../../widgets/big_text_widgets.dart';
import '../../../../widgets/small_text_widgets.dart';
import '../controllers/registersteps_controller.dart';

class SelectGenderView extends GetView<RegisterstepsController> {
  const SelectGenderView({super.key});

  @override
  Widget build(BuildContext context) {
    final RegisterstepsController genderController = Get.put(
      RegisterstepsController(),
    );

    return Scaffold(
      backgroundColor: Colors.white, // 👈 Transparent background
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Select gender',
      ),
      body: Stack(
        children: [
          // Container(
          //   decoration: BoxDecoration(
          //       gradient: LinearGradient(colors: [
          //     Color(0xffb5a7fe),
          //     Color(0xffffffff),
          //   ], begin: Alignment.topRight, end: Alignment.bottomRight)),
          // ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Obx(
                    () => _buildGenderOption(
                      imagePath: 'assets/flaticons/boy.png',
                      label: 'Male',
                      isSelected: genderController.isGenderSelected('Male'),
                      onTap: () {
                        genderController.selectGender('Male');
                      },
                    ),
                  ),
                  Obx(
                    () => _buildGenderOption(
                      imagePath: 'assets/flaticons/beauty.png',
                      label: 'Female',
                      isSelected: genderController.isGenderSelected('Female'),
                      onTap: () {
                        genderController.selectGender('Female');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "⚠ You can't change after confirmation",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (genderController.selectedGender.value.isEmpty) {
                    _showAlertDialog(
                        context, 'Error', 'Please select a gender.');
                  } else {
                    Get.defaultDialog(
                      // title: 'Do you confirm your gender?',
                      content: Column(
                        children: [
                          LargeTextStyle(
                            color: Colors.black,
                            text: 'Do you confirm your gender?',
                            fontSize: 18,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SmallTextStyle(
                              color: Colors.grey,
                              text:
                                  'After the account is registered the gender cannot be modified',
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Get.back();
                            Get.to(
                              SetDateOfBirth(),
                              transition: Transition.rightToLeft,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffB460F0),
                          ),
                          child: const Text(
                            'Yes,I am sure',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff8A4CF7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption({
    required String imagePath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xff8A4CF7) : Color(0xffe9cbfd),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Image.asset(imagePath, width: 80, height: 80),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xff8A4CF7) : Color(0xffB460F0),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
