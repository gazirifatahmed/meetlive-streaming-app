import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

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
          "User Agreement",
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
                  "MEET LIVE – TERMS OF SERVICE",
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
                "Welcome to Meet Live! These Terms of Service (\"Terms\") govern your access to and use of the Meet Live mobile application and services provided by Meet Live Team. By creating an account or using our services, you agree to be bound by these Terms.",
              ),

              _sectionTitle("1. Eligibility & Registration"),
              _bullet(
                "Age Requirement:",
                "You must be at least 18 years old to use Meet Live. By using this service, you represent and warrant that you meet this age requirement.",
              ),
              _bullet(
                "Account Security:",
                "You are responsible for safeguarding your account credentials (username/password). Any activity performed through your account is your sole responsibility.",
              ),
              _bullet(
                "Accuracy of Information:",
                "You agree to provide true, accurate, and complete information during the registration process.",
              ),

              _sectionTitle("2. User-Generated Content (UGC) Policy"),
              _paragraph(
                "Meet Live allows users to stream video, chat, and post content. To maintain a safe community, you agree to the following:",
              ),
              _subTitle("Prohibited Content:"),
              _smallBullet("Sexually explicit, pornographic, or contains nudity."),
              _smallBullet("Violent, hateful, discriminatory, or promotes illegal activities."),
              _smallBullet("Harassing, bullying, or threatening towards other users."),
              _smallBullet("Infringing on intellectual property or privacy rights of others."),
              _bullet(
                "Monitoring & Removal:",
                "We reserve the right to monitor, review, and remove any content that violates these Terms without prior notice.",
              ),
              _bullet(
                "Zero Tolerance for Child Abuse:",
                "Any content involving child exploitation or harm will result in an immediate permanent ban and report to law enforcement authorities.",
              ),

              _sectionTitle("3. Community Safety Tools"),
              _paragraph(
                "In compliance with Google Play Store policies, we provide:",
              ),
              _bullet(
                "Reporting Mechanism:",
                "Users can report any objectionable content or behavior directly through the app.",
              ),
              _bullet(
                "Blocking Feature:",
                "Users have the right to block any other user to prevent further interaction.",
              ),
              _bullet(
                "Action against Violations:",
                "We act upon reports within 24 hours. Violators may face account suspension or permanent termination.",
              ),

              _sectionTitle("4. Virtual Items & Payments"),
              _bullet(
                "Diamonds & Gifts:",
                "Users may purchase virtual \"Diamonds\" to send \"Gifts\" to broadcasters.",
              ),
              _bullet(
                "No Refunds:",
                "All purchases of virtual items are final and non-refundable. Diamonds and Gifts cannot be exchanged for cash or legal tender.",
              ),
              _bullet(
                "Third-Party Billing:",
                "Payments are processed via authorized third-party gateways. You must comply with their respective terms and conditions.",
              ),

              _sectionTitle("5. Intellectual Property"),
              _bullet(
                "Our Content:",
                "All app designs, logos, software, and technical features are the exclusive property of Meet Live Team.",
              ),
              _bullet(
                "Your License to Us:",
                "By streaming or posting content on Meet Live, you grant us a worldwide, royalty-free license to host, store, use, display, and distribute your content within the platform.",
              ),

              _sectionTitle("6. Termination of Service"),
              _paragraph(
                "We reserve the right to suspend or terminate your access to Meet Live at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.",
              ),

              _sectionTitle("7. Disclaimer of Warranties"),
              _paragraph(
                "Meet Live is provided on an \"AS IS\" and \"AS AVAILABLE\" basis. We do not guarantee that the service will be uninterrupted, secure, or error-free. Your use of the service is at your own risk.",
              ),

              _sectionTitle("8. Limitation of Liability"),
              _paragraph(
                "To the maximum extent permitted by law, Meet Live Team shall not be liable for any indirect, incidental, or consequential damages resulting from your use of the service or any interactions with other users.",
              ),

              _sectionTitle("9. Governing Law"),
              _paragraph(
                "These Terms shall be governed by and construed in accordance with the laws of the jurisdiction where the operating company is registered, without regard to its conflict of law provisions.",
              ),

              _sectionTitle("10. Contact Us"),
              _paragraph(
                "For any questions, legal inquiries, or support, please contact:",
              ),
              _contactRow("Website:", "www.meetlive.fun"),
              _contactRow("Email:", "support.meetlive@gmail.com"),
              _contactRow("Operator:", "Meet Live Team"),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "By using Meet Live, you agree to these Terms of Service.",
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

  static Widget _subTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.5,
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