import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/layout_constant.dart';

class NewPasswordPage extends StatelessWidget {
  NewPasswordPage({super.key});

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            )),
        title: const Text("Reset Password"),
        centerTitle: true,
        backgroundColor: kAppColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// Instruction
            const Text(
              "Enter your new password and confirm it",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 30),

            /// New Password
            TextField(
              cursorColor: kAppColor,
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "New Password",
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: kAppColor,
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: kAppColor, width: 1),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Confirm Password
            TextField(
              cursorColor: kAppColor,
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Confirm Password",
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                prefixIcon: Icon(
                  Icons.lock,
                  color: kAppColor,
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: kAppColor, width: 1),
                ),
              ),
            ),

            const SizedBox(height: 40),

            /// Reset Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (newPasswordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    Get.snackbar(
                      "Error",
                      "Please fill all fields",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  } else if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    Get.snackbar(
                      "Error",
                      "Passwords do not match",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      "Success",
                      "Password reset successfully!",
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );

                    // Navigate to login page (example)
                    // Get.offAll(() => LoginPage());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAppColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Reset Password",
                  style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: kHeight * 0.015,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
