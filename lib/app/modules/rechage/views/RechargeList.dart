import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/layout_constant.dart';
import '../controllers/rechage_controller.dart';

class Rechargelist extends GetView<RechageController> {
  const Rechargelist({super.key});

  @override
  Widget build(BuildContext context) {
    RechageController rechageController = Get.put(RechageController());
    return Scaffold(
      body: FutureBuilder(
        future: rechageController.showResellerList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 🔹 Shimmer Loading UI
            return ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                margin: EdgeInsets.symmetric(
                    horizontal: kWeight * 0.03, vertical: kHeight * 0.003),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade300),
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                        ),
                        title: Container(
                          height: 16,
                          width: 100,
                          color: Colors.white,
                        ),
                        subtitle: Container(
                          height: 14,
                          width: 60,
                          margin: EdgeInsets.only(top: 5),
                          color: Colors.white,
                        ),
                        trailing: Container(
                          height: 30,
                          width: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading data"));
          } else {
            return ListView.builder(
              itemCount: rechageController.resellerListData.length,
              itemBuilder: (context, index) {

                return Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: kWeight * 0.03, vertical: kHeight * 0.003),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ListTile(

                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CachedNetworkImage(
                              imageUrl:
                                  '$kDomainUrl/${rechageController.resellerListData[index]['profile_image']}',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey.shade300,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey.shade300,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          '${rechageController.resellerListData[index]['name']}',
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.w600, fontSize: kHeight*0.018),
                        ),

                        subtitle: Text(
                          'ID : ${rechageController.resellerListData[index]['id']}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500, fontSize: kHeight*0.015),
                        ),
                        trailing: InkWell(
                          onTap: () async {
                            try {
                              final phoneNumber = rechageController
                                  .resellerListData[index]['whatsapp_number'];
                              // Phone number থেকে + এবং space remove করুন
                              final cleanNumber = phoneNumber
                                  .toString()
                                  .replaceAll(RegExp(r'[^\d]'), '');

                              // Bangladesh number format করুন
                              String formattedNumber = cleanNumber;
                              if (cleanNumber.startsWith('01')) {
                                formattedNumber =
                                    '88$cleanNumber'; // 88 prefix যোগ করুন
                              } else if (cleanNumber.startsWith('8801')) {
                                formattedNumber =
                                    cleanNumber; // Already formatted
                              }

                              final whatsappUrl =
                                  "https://wa.me/$formattedNumber";
                              print(
                                  "Opening WhatsApp URL: $whatsappUrl"); // Debug

                              await launchUrl(
                                Uri.parse(whatsappUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              print("WhatsApp Error: $e");
                              // Fallback - Browser এ open করুন
                              try {
                                final phoneNumber = rechageController
                                    .resellerListData[index]['phone'];
                                final cleanNumber = phoneNumber
                                    .toString()
                                    .replaceAll(RegExp(r'[^\d]'), '');
                                String formattedNumber =
                                    cleanNumber.startsWith('01')
                                        ? '88$cleanNumber'
                                        : cleanNumber;

                                await launchUrl(
                                  Uri.parse(
                                      "https://web.whatsapp.com/send?phone=$formattedNumber"),
                                  mode: LaunchMode.inAppWebView,
                                );
                              } catch (e2) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Could not open WhatsApp')),
                                );
                              }
                            }
                          },
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.asset(
                              'assets/frame/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
