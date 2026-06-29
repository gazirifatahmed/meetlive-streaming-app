import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../constants/layout_constant.dart';
import '../../accountInfornation/views/widget/CastomBtton.dart';
import '../controllers/withdraw_controller.dart';

class PaymentMethodList extends StatefulWidget {
  const PaymentMethodList({super.key});

  @override
  State<PaymentMethodList> createState() => _PaymentMethodListState();
}

class _PaymentMethodListState extends State<PaymentMethodList> {
  final WithdrawController withdrawController = Get.put(WithdrawController());
  String? _selectedId;

  // ✅ Allowed amounts
  final List<int> allowedAmounts = [
    200000,
    500000,
    1000000,
    2000000,
    4000000,
    6000000,
    8000000,
    10000000,
    15000000,
    20000000,
    35000000,
    50000000,
  ];

  // ✅ Form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    withdrawController.getWithdrawList();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Obx(() {
      final list = withdrawController.withDrawList;

      if (list.isEmpty) {
        return const Center(
          child: Text('Set withdraw method first'),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical: height * 0.015,
          horizontal: width * 0.04,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final bool selected = item['id'].toString() == _selectedId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedId = item['id'].toString();
              });

              // ✅ Open Bottom Sheet
              Get.bottomSheet(
                SafeArea(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Get.width * 0.05,
                      vertical: Get.height * 0.02,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Get.back(),
                                child: const Icon(Icons.close, size: 24),
                              ),
                            ],
                          ),
                          SizedBox(height: Get.height * 0.015),
                          Text(
                            "Selected Method: ${item['method_name']}",
                            style: TextStyle(
                              fontSize: Get.height * 0.022,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: Get.height * 0.02),
                          Text(
                            "Account: ${item['method_account']}",
                            style: TextStyle(fontSize: Get.height * 0.018),
                          ),
                          SizedBox(height: Get.height * 0.03),

                          // ✅ Amount Input
                          Center(
                            child: SizedBox(
                              width: kWeight * 0.9,
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: withdrawController.amount,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                                cursorColor: Colors.black87,
                                decoration: InputDecoration(
                                  hintText: 'Enter amount',
                                  prefixIcon: Icon(Icons.diamond,
                                      color: Color(0xff813aec)),
                                  hintStyle: GoogleFonts.lato(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16),
                                  fillColor: Colors.grey.withValues(alpha: 0.3),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.white, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.white, width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  final amount = int.tryParse(value);
                                  if (amount == null) {
                                    return 'Enter a valid number';
                                  }
                                  if (!allowedAmounts.contains(amount)) {
                                    return 'Invalid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: Get.height * 0.02),

                          // ✅ Submit Button
                          // ✅ Submit Button
                          Center(
                            child: CastomAppButton(
                              fastColor: const Color(0xff8A4CF7),
                              secondColor: const Color(0xffB460F0),
                              onPressed: () {
                                withdrawController.withdrawSubmit(
                                  methodId: item[
                                      'id'], // ✅ Convert to String if needed
                                );
                              },
                              child: const Text(
                                "Sure",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: Get.height * 0.03),
                        ],
                      ),
                    ),
                  ),
                ),
                isScrollControlled: true,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(bottom: height * 0.015),
              padding: EdgeInsets.symmetric(
                  vertical: height * 0.018, horizontal: width * 0.04),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.purpleAccent.shade100,
                        ],
                      )
                    : const LinearGradient(
                        colors: [Colors.white, Colors.white],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: selected ? 0.18 : 0.06),
                    blurRadius: selected ? 18 : 8,
                    offset: Offset(0, selected ? 10 : 6),
                  ),
                ],
                border: Border.all(
                  color: selected
                      ? Colors.purpleAccent.withValues(alpha: 0.9)
                      : Colors.grey.withValues(alpha: 0.12),
                  width: selected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: width * 0.14,
                    height: width * 0.14,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.all(width * 0.025),
                    child: _buildLogo(item['method_name']),
                  ),
                  SizedBox(width: width * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['method_name'] ?? 'Unknown',
                          style: GoogleFonts.roboto(
                            fontSize: height * 0.020,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: height * 0.006),
                        Text(
                          item['method_account'] ?? '',
                          style: GoogleFonts.roboto(
                            fontSize: height * 0.016,
                            color: selected ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: height * 0.010),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.025,
                                  vertical: height * 0.004),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white24
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Instant",
                                style: GoogleFonts.roboto(
                                  fontSize: height * 0.014,
                                  color:
                                      selected ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.025),
                            Text(
                              "No extra fee",
                              style: GoogleFonts.roboto(
                                fontSize: height * 0.014,
                                color:
                                    selected ? Colors.white70 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected ? Colors.white : Colors.grey,
                        size: height * 0.028,
                      ),
                      SizedBox(height: height * 0.008),
                      Icon(
                        Icons.chevron_right,
                        color: selected ? Colors.white70 : Colors.grey.shade400,
                        size: height * 0.030,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildLogo(String? methodName) {
    final name = methodName?.toLowerCase() ?? '';
    String asset = 'assets/images/default_wallet.png';
    if (name == 'bkash') {
      asset = 'assets/audio_live/BKash-Icon2-Logo.wine.png';
    } else if (name == 'nagad') {
      asset = 'assets/audio_live/Nagad-Vertical-Logo.wine.png';
    } else if (name.contains('card')) {
      asset = 'assets/images/card.png';
    }

    return Image.asset(
      asset,
      height: kHeight * 0.07,
      width: kHeight * 0.07,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.account_balance_wallet,
          size: 28,
          color: Colors.grey,
        );
      },
    );
  }
}
