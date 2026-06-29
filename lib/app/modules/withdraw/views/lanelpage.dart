import 'package:flutter/material.dart';
import 'package:meetlivepro/widgets/after/castom%20appbar.dart';

class MyLevelPage extends StatelessWidget {
  const MyLevelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'My Level'),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              

              SizedBox(height: w * 0.06),

              Center(
                child: Image.asset(
                  "assets/new/lvv.png",
                  width: w * 0.58,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: w * 0.04),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: 35 / 50000,
                  minHeight: 18,
                  backgroundColor: const Color(0xfff7f7f7),
                  valueColor: const AlwaysStoppedAnimation(Color(0xfff25aa3)),
                ),
              ),

              SizedBox(height: w * 0.05),

              const Center(
                child: Text(
                  "35 / 50000",
                  style: TextStyle(
                    fontSize: 22,
                    color: Color(0xff777777),
                  ),
                ),
              ),

              SizedBox(height: w * 0.15),

              const Text(
                "How to upgrade",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff333333),
                ),
              ),

              SizedBox(height: w * 0.06),

              _UpgradeItem(
                number: "1",
                text:
                "Different level icons are different, the higher the more noble",
              ),

              SizedBox(height: w * 0.04),

              _UpgradeItem(
                number: "2",
                text:
                "Your identity is visible at a glance, and your dignity is visible",
              ),

              SizedBox(height: w * 0.04),

              _UpgradeItem(
                number: "3",
                text:
                "Sending gifts is the fastest way to upgrade, the more points\n\nyou send, the faster you upgrade",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeItem extends StatelessWidget {
  final String number;
  final String text;

  const _UpgradeItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: w * 0.045,
          height: w * 0.045,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xffffd5e3),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: w * 0.025,
              fontWeight: FontWeight.bold,
              color: const Color(0xfff25a8f),
            ),
          ),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: w * 0.035,
              height: 1.6,
              color: const Color(0xff888888),
            ),
          ),
        ),
      ],
    );
  }
}