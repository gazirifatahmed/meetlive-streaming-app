import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

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
          "About Us",
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
                  "Meet Live – Recharge & Reseller Agreement Policy",
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
                  "Effective Date: May 12, 2026",
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _paragraph(
                "This Recharge Agreement (\"Agreement\") establishes a formal legal understanding between Meet Live (\"Platform\", \"Company\", \"We\") and the Recharge Partner, Reseller, or User (\"You\"). This policy governs the purchase, distribution, and management of in-app virtual currency such as Coins, Diamonds, and Points within the Meet Live ecosystem.",
              ),

              _paragraph(
                "By engaging in any recharge or top-up activities, you acknowledge that you have read, understood, and agreed to the following terms:",
              ),

              _sectionTitle("1. Eligibility & Registration"),

              _paragraph(
                "To act as an authorized Recharge Partner or Reseller, you must:",
              ),

              _smallBullet(
                "Be at least 18 years of age or the legal age of majority in your jurisdiction.",
              ),
              _smallBullet(
                "Provide valid legal identification such as NID or Passport and business credentials if requested.",
              ),
              _smallBullet(
                "Complete the official registration process and receive formal approval from the Meet Live Admin Team.",
              ),

              _sectionTitle("2. Recharge Protocols"),

              _bullet(
                "Official Channels:",
                "All recharges must be conducted through the official API or methods authorized by Meet Live.",
              ),

              _bullet(
                "Rate Variations:",
                "Recharge rates, commission percentages, and bonus structures are at the sole discretion of the Platform. These rates are subject to change based on market conditions without prior individual notice.",
              ),

              _bullet(
                "Prohibited Methods:",
                "Use of stolen cards, fraudulent accounts, or any third-party unauthorized gateways is strictly forbidden.",
              ),

              _sectionTitle("3. Commission & Settlement Framework"),

              _bullet(
                "Earnings:",
                "Authorized resellers are eligible for commissions based on their transaction volume as per the tier-based structure.",
              ),

              _bullet(
                "Payout Cycle:",
                "Settlements are processed on a weekly or monthly basis, subject to account verification and minimum threshold requirements.",
              ),

              _bullet(
                "Dispute Window:",
                "Any discrepancies in commission calculations must be reported to the Admin within 48 hours of the settlement statement.",
              ),

              _sectionTitle("4. Refund & Correction Policy"),

              _bullet(
                "Finality of Sale:",
                "All successful virtual currency deliveries are final and non-refundable.",
              ),

              _bullet(
                "User Error:",
                "Meet Live is not responsible for recharges made to incorrect User IDs due to Reseller or User negligence.",
              ),

              _bullet(
                "Technical Failure:",
                "If a transaction is successful but assets are not credited, a claim must be filed within 24 hours with valid proof such as Transaction ID and Screenshot.",
              ),

              _sectionTitle("5. Fraud Prevention & Account Security"),

              _paragraph(
                "Meet Live maintains a Zero Tolerance Policy toward:",
              ),

              _smallBullet("Artificial inflation of sales via bot accounts."),
              _smallBullet(
                "Money laundering or using the platform for unauthorized currency exchange.",
              ),

              _bullet(
                "Consequences:",
                "Immediate termination of access, forfeiture of all pending commissions or balances, and a permanent ban from the ecosystem.",
              ),

              _sectionTitle("6. Confidentiality Clause"),

              _paragraph(
                "Resellers shall maintain strict confidentiality regarding:",
              ),

              _smallBullet(
                "Special commission rates and internal admin communications.",
              ),
              _smallBullet(
                "Platform backend operations and proprietary recharge tools.",
              ),
              _smallBullet(
                "Unauthorized disclosure of these details will result in immediate contract termination and potential legal pursuit.",
              ),

              _sectionTitle("7. Compliance & Legal Obligations"),

              _paragraph(
                "You agree to comply with all local and international financial regulations. Meet Live shall not be held liable for any tax obligations or legal violations committed by the Reseller in their respective jurisdiction.",
              ),

              _sectionTitle("8. Termination of Agreement"),

              _paragraph(
                "Meet Live reserves the right to:",
              ),

              _smallBullet(
                "Modify or update this policy at any time via the official website.",
              ),
              _smallBullet(
                "Revoke Reseller status if performance targets are not met or if policy violations occur.",
              ),
              _smallBullet(
                "Hold pending payments during investigations of suspicious activity.",
              ),

              _sectionTitle("9. Support & Dispute Resolution"),

              _paragraph(
                "For any queries, technical assistance, or dispute reporting, please contact our official channels:",
              ),

              _contactRow("Official Website:", "www.meetlive.fun"),
              _contactRow("Support Email:", "support.meetlive@gmail.com"),
              _contactRow("Telegram/Admin Support:", "Insert ID if applicable"),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "By clicking \"Accept\" or proceeding with a transaction, you confirm your status as an authorized agent/user of Meet Live and agree to be bound by these terms.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
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