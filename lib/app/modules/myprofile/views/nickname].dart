import 'package:flutter/material.dart';

class WordCountTextField1 extends StatefulWidget {
  final TextEditingController controller;

  const WordCountTextField1({
    super.key,
    required this.controller,
  });

  @override
  State<WordCountTextField1> createState() => _WordCountTextField1State();
}

class _WordCountTextField1State extends State<WordCountTextField1> {
  int letterCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_countLetters);
  }

  void _countLetters() {
    final text = widget.controller.text;
    setState(() {
      // Count all characters except spaces, tabs, and newlines
      letterCount = text.replaceAll(RegExp(r'\s+'), '').length;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_countLetters);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double kWeight = MediaQuery.of(context).size.width;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: kWeight * 0.03),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff8A4CF7)),
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Type here...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 25.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$letterCount/30',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
