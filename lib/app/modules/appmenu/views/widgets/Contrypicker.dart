import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../registersteps/controllers/registersteps_controller.dart';
import '../../controllers/appmenu_controller.dart';

class CountryPickerWidget extends StatefulWidget {
  final double kHeight;

  const CountryPickerWidget({super.key, required this.kHeight});

  @override
  State<CountryPickerWidget> createState() => _CountryPickerWidgetState();
}

class _CountryPickerWidgetState extends State<CountryPickerWidget> {
  Country? selectedCountry;
  final RegisterstepsController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    AppmenuController controller1 = Get.put(AppmenuController());
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.04,
        vertical: Get.height * 0.015,
      ),
      margin: EdgeInsets.symmetric(
        horizontal: Get.width * 0.05,
        vertical: Get.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () {
          showCountryPicker(
            context: context,
            showPhoneCode: true,
            countryListTheme: CountryListThemeData(
              borderRadius: BorderRadius.circular(16),
              inputDecoration: InputDecoration(
                labelText: 'Search country',
                hintText: 'Start typing...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            onSelect: (Country country) {
              setState(() {
                selectedCountry = country;
              });
              controller1.selectedCountry.value = country.name;
            },
          );
        },
        child: Row(
          children: [
            SizedBox(width: Get.width * 0.02),
            Expanded(
              child: Text(
                selectedCountry == null
                    ? 'Select your country'
                    : '${selectedCountry!.flagEmoji} ${selectedCountry!.name}',
                style: GoogleFonts.lato(
                  fontSize: Get.height * 0.018,
                  color: selectedCountry == null
                      ? Colors.grey.shade500
                      : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: Get.height * 0.026,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
