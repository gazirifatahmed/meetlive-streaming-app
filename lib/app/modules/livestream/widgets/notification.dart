import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/layout_constant.dart';
import '../../notification/views/panalNotification.dart';

class notiificationtabbar extends StatelessWidget {
  const notiificationtabbar({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock unread count - replace with actual controller data
    int unreadCount = 3;

    return Scaffold(
        body: Column(
      children: [
        InkWell(
          onTap: () {
            Get.to(Panalnotification());
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3), // ছায়ার রঙ
                  spreadRadius: 3, // ছড়ানোর পরিমাণ
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(vertical: kHeight * 0.005),
            child: ListTile(
              leading: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      'assets/frame/bell.png',
                      height: kHeight * 0.04,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                'Notification ',
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.w500, fontSize: kHeight * 0.015),
              ),
              subtitle: Text(
                unreadCount > 0
                    ? '$unreadCount new notification${unreadCount > 1 ? 's' : ''}'
                    : 'Exchange : On',
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.w500,
                    fontSize: kHeight * 0.012,
                    color: unreadCount > 0 ? Colors.blue : null),
              ),
              trailing: unreadCount > 0
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.lato(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: kHeight * 0.01),
                      ),
                    )
                  : Text(
                      '2025-01-12 12:30',
                      style: GoogleFonts.lato(
                          color: Colors.grey.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: kHeight * 0.013),
                    ),
            ),
          ),
        )
      ],
    ));
  }
}
