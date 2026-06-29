import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/auth/views/resent_password_page.dart';
import 'package:pinput/pinput.dart';
import '../../../../constants/color_constants.dart';

class ForgetPasswordPage extends StatelessWidget {
  ForgetPasswordPage({super.key});

  final otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final kHeight = MediaQuery.of(context).size.height;

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
        title: Text("Forgot Password"),
        centerTitle: true,
        backgroundColor: kAppColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: kHeight * 0.05),
            Text(
              "Enter the 6-digit code sent to your email/phone",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 30),

            /// Pinput field
            Pinput(
              length: 6,
              controller: otpController,
              defaultPinTheme: PinTheme(
                width: 50,
                height: 55,
                textStyle: GoogleFonts.roboto(
                  fontSize: kHeight * 0.02,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 50,
                height: 55,
                textStyle: const TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
              ),
              onCompleted: (value) {
                print("OTP Entered: $value");
              },
            ),
            SizedBox(height: 40),

            /// Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (otpController.text.length == 6) {
                    Get.to(NewPasswordPage(),
                        transition: Transition.rightToLeft);
                    Get.snackbar(
                      "Success",
                      "OTP Verified!",
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      "Error",
                      "Please enter the complete code",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
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
                  "Verify",
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Resend code
            TextButton(
              onPressed: () {
                Get.snackbar("Resent", "Verification code resent!");
              },
              child: const Text(
                "Resend Code",
                style: TextStyle(color: Colors.deepPurple),
              ),
            )
          ],
        ),
      ),
    );
  }
}
