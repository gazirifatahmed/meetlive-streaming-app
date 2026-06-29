import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "PRIVACY POLICY – MEET LIVE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  "Last Updated: May 12, 2026",
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _paragraph(
                "Meet Live Team (\"we,\" \"us,\" or \"our\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application, Meet Live.",
              ),

              _paragraph(
                "By using the app, you agree to the collection and use of information in accordance with this policy.",
              ),

              _sectionTitle("1. Information We Collect"),

              _paragraph(
                "To provide a seamless live streaming experience, we may collect the following types of information:",
              ),

              _bullet(
                "Personal Data:",
                "Name, email address, phone number, and profile picture provided during registration.",
              ),

              _bullet(
                "Media Access:",
                "We require access to your device’s Camera and Microphone to enable live streaming and video interaction features.",
              ),

              _bullet(
                "Device Information:",
                "IP address, device model, operating system version, and unique device identifiers.",
              ),

              _bullet(
                "Location Data:",
                "General location (city/country) to suggest relevant local content and streamers.",
              ),

              _sectionTitle("2. How We Use Your Information"),

              _paragraph(
                "We use the collected data for various purposes:",
              ),

              _smallBullet("To provide and maintain our service."),
              _smallBullet("To manage your account and provide customer support."),
              _smallBullet("To monitor for fraudulent or illegal activity and ensure platform safety."),
              _smallBullet("To improve app functionality and user experience."),
              _smallBullet("To process virtual item transactions such as Diamonds and Gifts."),

              _sectionTitle("3. User-Generated Content (UGC) & Safety"),

              _paragraph(
                "Meet Live is a public platform. Any content you stream or post is visible to other users.",
              ),

              _bullet(
                "Safety Tools:",
                "In compliance with Google Play policies, we provide tools for users to Report and Block others who violate our community standards.",
              ),

              _bullet(
                "Moderation:",
                "We actively monitor and remove content that is offensive, adult-oriented, or harmful.",
              ),

              _sectionTitle("4. Data Sharing & Disclosure"),

              _paragraph(
                "We do not sell your personal data to third parties. We may share information only in the following cases:",
              ),

              _bullet(
                "With Service Providers:",
                "To facilitate our service, such as cloud hosting or payment processors.",
              ),

              _bullet(
                "For Legal Reasons:",
                "If required by law, regulation, or legal process to protect the safety of our users or the public.",
              ),

              _bullet(
                "Business Transfers:",
                "In connection with any merger, sale of company assets, or acquisition.",
              ),

              _sectionTitle("5. Data Retention & Deletion"),

              _paragraph(
                "We retain your information as long as your account is active.",
              ),

              _bullet(
                "Account Deletion:",
                "You can request to delete your account and associated data at any time by contacting us at support.meetlive@gmail.com. Once deleted, this data cannot be recovered.",
              ),

              _sectionTitle("6. Children’s Privacy"),

              _paragraph(
                "Meet Live is strictly for users aged 18 and above. We do not knowingly collect personal information from children. If we discover that a minor has provided us with personal data, we will delete it immediately.",
              ),

              _sectionTitle("7. Security of Data"),

              _paragraph(
                "We use industry-standard security measures to protect your data. However, please remember that no method of transmission over the internet is 100% secure.",
              ),

              _sectionTitle("8. Changes to This Privacy Policy"),

              _paragraph(
                "We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last Updated\" date.",
              ),

              _sectionTitle("Contact Us"),

              _paragraph(
                "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us:",
              ),

              _contactRow("Email:", "support.meetlive@gmail.com"),
              _contactRow("Website:", "www.meetlive.fun"),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Your privacy and safety are important to Meet Live.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }

  static Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          height: 1.65,
        ),
      ),
    );
  }

  static Widget _bullet(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          Expanded(
            child: RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
                children: [
                  TextSpan(
                    text: "$title ",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.6,
                    ),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _smallBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "– ",
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _contactRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 13.5,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: "$title ",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}