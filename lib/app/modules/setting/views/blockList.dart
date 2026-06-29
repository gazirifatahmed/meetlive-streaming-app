import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/color_constants.dart';

class BlockListPage extends StatelessWidget {
  final List<Map<String, String>> blockedUsers = const [
    {
      "name": "John Doe",
      "avatar": "https://i.pravatar.cc/150?img=1",
      "status": "Blocked",
    },
    {
      "name": "Jane Smith",
      "avatar": "https://i.pravatar.cc/150?img=2",
      "status": "Blocked",
    },
  ];

  const BlockListPage({super.key});

  @override
  Widget build(BuildContext context) {
    double kHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xffeeeeee),
      // ফিক্সড: কাস্টম অ্যাপবারের বদলে ফ্ল্যাটারের ডিফল্ট AppBar ব্যবহার করা হয়েছে
      appBar: AppBar(
        title: const Text(
          'Block List',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: blockedUsers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = blockedUsers[index];
          return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17), color: Colors.white),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                radius: kHeight * 0.035,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: CachedNetworkImageProvider(
                  user["avatar"]!,
                ),
              ),
              title: Text(
                user["name"]!,
                style:
                    GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                user["status"]!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  print("Unblocked ${user["name"]}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAppColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                ),
                // ফিক্সড: কাস্টম টেক্সটের বদলে স্ট্যান্ডার্ড Text উইজেট ব্যবহার করা হয়েছে
                child: Text(
                  'Unblock',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontSize: kHeight * 0.012,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}