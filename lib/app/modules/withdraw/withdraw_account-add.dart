import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/withdraw/views/paymentMethodeList.dart';


import '../../../constants/constants.dart';
import '../../../constants/layout_constant.dart';
import '../../../widgets/after/castom appbar.dart';
import '../accountInfornation/views/widget/CastomBtton.dart';
import '../wallet/controllers/wallet_controller.dart';
import 'controllers/withdraw_controller.dart';

class WithdrawAccount extends StatefulWidget {
  const WithdrawAccount({super.key});

  @override
  State<WithdrawAccount> createState() => _WithdrawAccountState();
}

class _WithdrawAccountState extends State<WithdrawAccount> {
  String? selectedPayment;
  final TextEditingController paymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    WithdrawController withdrawController = Get.put(WithdrawController());
    WalletController controller = Get.put(WalletController());
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Account Details',
      ),
      body: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ Add this
        children: [
          SizedBox(height: kHeight * 0.04),

          Center(
            child: CastomAppButton(
              onPressed: () {
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
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // ✅ important here
                          children: [
                            // 🔻 all your form widgets 🔻
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
                              "Add account",
                              style: TextStyle(
                                fontSize: Get.height * 0.025,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: Get.height * 0.025),
                            Castomtextfeild(
                              text:
                                  'Uid : ${authController.userProfile.value.user?.userId ?? ""}',
                            ),
                            SizedBox(height: Get.height * 0.015),
                            Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CustomDropdown(
                                closedHeaderPadding: EdgeInsets.symmetric(
                                  vertical: Get.height * 0.015,
                                  horizontal: Get.width * 0.04,
                                ),
                                hintText: 'Select National ID Type',
                                items: controller.nationalIdentity,
                                initialItem: controller.nationalIdentity[0],
                                canCloseOutsideBounds: true,
                                decoration: CustomDropdownDecoration(
                                  closedSuffixIcon: const Icon(
                                    Icons.arrow_drop_down_outlined,
                                    color: Colors.black87,
                                  ),
                                  headerStyle: GoogleFonts.lato(
                                    fontSize: Get.height * 0.018,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  closedFillColor: Colors.white,
                                  listItemStyle: GoogleFonts.lato(
                                    fontSize: Get.height * 0.018,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  hintStyle: GoogleFonts.lato(
                                    fontSize: Get.height * 0.018,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                  closedBorderRadius: BorderRadius.circular(8),
                                  expandedFillColor: Colors.white,
                                ),
                                onChanged: (value) {
                                  withdrawController.selectMethode.value =
                                      value!;
                                },
                              ),
                            ),
                            SizedBox(height: Get.height * 0.015),
                            Castomtextfeild(
                                controller: withdrawController.number,
                                text: 'Enter account number'),
                            SizedBox(height: Get.height * 0.025),
                            CastomAppButton(
                              onPressed: () {
                                withdrawController.withdrawPost();
                              },
                              buttonText: 'Submit',
                            ),
                            SizedBox(height: Get.height * 0.06),
                          ],
                        ),
                      ),
                    ),
                  ),
                  isScrollControlled: true,
                );
              },
              buttonText: 'Add account',
            ),
          ),

          // ✅ FIX HERE → Replace Expanded with Flexible
          SizedBox(
            height: kHeight * 0.8,
            child: PaymentMethodList(),
          ),
        ],
      )),
    );
  }
}

class Castomtextfeild extends StatelessWidget {
  final String text;
  final controller;
  const Castomtextfeild({
    super.key,
    required this.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          labelText: text,
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xff8A4CF7), width: 2),
          ),
        ),
      ),
    );
  }
}
