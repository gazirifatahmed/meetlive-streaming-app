import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExchangeTextField extends StatefulWidget {
  final controller; // controller receive করার জন্য
  const ExchangeTextField({super.key, required this.controller});

  @override
  State<ExchangeTextField> createState() => _ExchangeTextFieldState();
}

class _ExchangeTextFieldState extends State<ExchangeTextField> {
  double calculatedCoin = 0.0;

  void _calculate(String value) {
    final entered = double.tryParse(value);
    if (entered != null) {
      // Subtract 5%
      setState(() {
        calculatedCoin = entered * 0.5;
      });
    } else {
      setState(() {
        calculatedCoin = 0.0;
      });
    }

    // Form validation trigger
    // widget.controller.validateTradeForm();
  }

//this is from alamin
  // this is from Sagor
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: widget.controller,
        onChanged: _calculate,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Enter exchange amount',
          suffixText: 'Coin: ${calculatedCoin.toStringAsFixed(2)}',
          hintStyle: GoogleFonts.lato(
            color: const Color(0xff2b2b2c),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          suffixStyle: GoogleFonts.lato(
            color: const Color(0xff7C45BC),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
