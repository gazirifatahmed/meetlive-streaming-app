import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/registersteps/views/set_nickname.dart';

import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/setheight.dart';
import '../controllers/registersteps_controller.dart';

class SetDateOfBirth extends StatefulWidget {
  const SetDateOfBirth({super.key});

  @override
  State<SetDateOfBirth> createState() => _SetDateOfBirthState();
}

class _SetDateOfBirthState extends State<SetDateOfBirth> {
  int selectedYear = 2005;
  int selectedMonth = 10;
  int selectedDay = 26;

  final List<int> years = List.generate(
    50,
    (index) => 1982 + index,
  ); // From 1982 to 2031
  final List<int> months = List.generate(12, (index) => index + 1); // 1 to 12
  final List<int> days = List.generate(31, (index) => index + 1); // 1 to 31

  RegisterstepsController controller = Get.put(RegisterstepsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 👈 Transparent background
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Select Date of birth',
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffffffff),
              Color(0xffffffff),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SetHeight(heightSet: 0.2),
            SizedBox(
              height: Get.height * 0.3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPicker(
                    items: years,
                    selectedValue: selectedYear,
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                      });
                    },
                    label: 'Year',
                  ),
                  _buildPicker(
                    items: months,
                    selectedValue: selectedMonth,
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value;
                      });
                    },
                    label: 'Month',
                  ),
                  _buildPicker(
                    items: days,
                    selectedValue: selectedDay,
                    onChanged: (value) {
                      setState(() {
                        selectedDay = value;
                      });
                    },
                    label: 'Day',
                  ),
                ],
              ),
            ),
            SetHeight(heightSet: 0.09),
            StylishButton(
              height: kHeight * 0.058,
              width: Get.width * 0.7,

              borderColor: Color(0xffB460F0),
              textColor: Colors.white,

              buttonText: 'Next',

              gradientColors: [
                Color(0xfffdcdfb),
                Color(0xff15bccd),
              ],

              onPressed: () {
                controller.dataOfBirth.value =
                '$selectedDay-$selectedMonth-$selectedYear';

                Get.to(
                  SetNickname(),
                  transition: Transition.rightToLeft,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker({
    required String label,
    required List<int> items,
    required int selectedValue,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: kHeight * 0.019,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: items.indexOf(selectedValue),
              ),
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                onChanged(items[index]);
              },
              children: items
                  .map(
                    (item) => Center(
                      child: Text(
                        item.toString(),
                        style: TextStyle(
                            fontSize: kHeight * 0.019,
                            color: Colors.black.withValues(alpha: .7)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
