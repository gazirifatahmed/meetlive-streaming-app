import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:meetlivepro/constants/layout_constant.dart';

class InvitePage extends StatelessWidget {
  const InvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/new/rankingbgimage.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * .045, vertical: 16),
            child: Column(
              children: [
                Image.asset("assets/images/pngwing.com.png", height: w * .42),

                GlassBox(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          InfoItem(
                            icon: Icons.person_add_alt,
                            text: 'You invite a new\nfriend "X"',
                          ),
                          InfoItem(
                            icon: Icons.attach_money,
                            text:
                                'Get 10% commission\njust by creating an\nID and recharging!',
                          ),
                          InfoItem(
                            icon: Icons.percent,
                            text: 'You get up to 10%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          gradient: const LinearGradient(
                            colors: [Color(0xff7b2cff), Color(0xffc47cff)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withValues(alpha: .5),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Invite",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/images/invite_online.png",
                    width: double.infinity,
                    height: kHeight * 0.09,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 8),

                GlassBox(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Rank",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                            child: const Text(
                              "Monthly   Total",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const RankTile(
                        rank: 1,
                        name: "Alice 1",
                        level: "LV 1",
                        amount: "\$1000",
                        crownColor: Colors.amber,
                      ),
                      const RankTile(
                        rank: 2,
                        name: "Alice 2",
                        level: "LV 2",
                        amount: "\$1001",
                        crownColor: Colors.white70,
                      ),
                      const RankTile(
                        rank: 3,
                        name: "Alice 3",
                        level: "LV 3",
                        amount: "\$1002",
                        crownColor: Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBox extends StatelessWidget {
  final Widget child;
  const GlassBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: .45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: .25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RankTile extends StatelessWidget {
  final int rank;
  final String name;
  final String level;
  final String amount;
  final Color crownColor;

  const RankTile({
    super.key,
    required this.rank,
    required this.name,
    required this.level,
    required this.amount,
    required this.crownColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: crownColor, size: 42),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage("assets/avatar.jpg"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    pill(Icons.star, level),
                    const SizedBox(width: 8),
                    pill(Icons.male, "32"),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pinkAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellow, size: 15),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
