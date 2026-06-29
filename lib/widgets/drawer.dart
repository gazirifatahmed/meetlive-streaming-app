import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/color_constants.dart';
import 'button_with_icon.dart';

Drawer CustomDrawr() {
  return Drawer(
    child: Center(
      // Center widget added here
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/profile-picture.png'),
            ),
            const SizedBox(height: 20),
            const Text(
              'নামঃ সাগর হোসেন',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'ফোনঃ ০১৯৯৪১২১৫৪৫১',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Text(
              'ইমেইলঃ example@email.com',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Text(
              'ঠিকানাঃ ঢাকা, বাংলাদেশ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),
            ButtonWithIcon(
              height: Get.height * 0.07,
              width: Get.width * 0.8,
              backgroundColor: Colors.white,
              borderColor: kPrimaryColor,
              textColor: Colors.black,
              buttonText: 'এড্রেস বুক',
              onPressed: () {},
              iconColor: Colors.black,
              icone: Icons.book_online,
            ),
            const SizedBox(height: 15),
            ButtonWithIcon(
              height: Get.height * 0.07,
              width: Get.width * 0.8,
              backgroundColor: Colors.white,
              borderColor: kPrimaryColor,
              textColor: Colors.black,
              buttonText: 'প্রোফাইল আপডেট',
              onPressed: () {
                // Get.to(const ProfileUpdateView());
              },
              iconColor: Colors.black,
              icone: Icons.person_remove_alt_1_outlined,
            ),
            const SizedBox(height: 15),
            ButtonWithIcon(
              height: Get.height * 0.07,
              width: Get.width * 0.8,
              backgroundColor: Colors.white,
              borderColor: kPrimaryColor,
              textColor: Colors.black,
              buttonText: 'পাসওয়ার্ড পরিবর্তন',
              onPressed: () {
                // Get.to(const PasswordChangeView());
              },
              iconColor: Colors.black,
              icone: Icons.book_online,
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () {
                // Handle logout button press
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('লগ আউট করুন',
                  style: TextStyle(fontSize: 18, color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                side: const BorderSide(color: Colors.redAccent, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
