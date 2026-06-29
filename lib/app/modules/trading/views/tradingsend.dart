import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../controllers/trading_controller.dart';

class Tradingsend extends StatelessWidget {
  const Tradingsend({super.key});

  @override
  Widget build(BuildContext context) {
    TradingController tradingController = Get.put(TradingController());
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: FutureBuilder(
            future: tradingController.showTradingList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  itemCount: 6, // লোডিং অবস্থায় ৬টা শিমার কার্ড দেখাবে
                  itemBuilder: (context, index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(kHeight * 0.012),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: ListTile(
                        leading: Container(
                          width: 30,
                          height: 30,
                          color: Colors.white,
                        ),
                        title: Container(
                          height: 14,
                          color: Colors.white,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 6),
                            Container(height: 12, color: Colors.white),
                            SizedBox(height: 6),
                            Container(height: 12, color: Colors.white),
                          ],
                        ),
                        trailing: Container(
                          width: 50,
                          height: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              } else if (tradingController.tradingListData.isEmpty) {
                return Center(
                  child: Text(
                    'No trading data available!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(bottom: 12),
                itemCount: tradingController.tradingListData.length,
                itemBuilder: (context, index) {
                  final trading = tradingController.tradingListData[index];

                  DateTime createdAt =
                      DateTime.tryParse(trading['created_at']) ??
                          DateTime.now();
                  String formattedDate =
                      DateFormat("dd MMM yyyy, hh:mm a").format(createdAt);

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(kHeight * 0.012),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Castontext(
                        fontSize: kHeight * 0.019,
                        text: '${index + 1}',
                      ),
                      title: Text(
                        '${trading['sender']['name']}',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: kHeight * 0.016,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UID : ${trading['sender']['id']}',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w500,
                              fontSize: kHeight * 0.012,
                            ),
                          ),
                          Text(
                            'Time : $formattedDate',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w500,
                              fontSize: kHeight * 0.012,
                            ),
                          ),
                        ],
                      ),
                      trailing: Castontext(
                        fontWeight: FontWeight.w600,
                        fontSize: kHeight * 0.018,
                        textColor: Color(0xff8A4CF7),
                        text: 'Coin : ${trading['sender']['earned_coins']}',
                      ),
                    ),
                  );
                },
              );
            },
          ))
        ],
      ),
    );
  }
}
