import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String name, text;
  final int senderId, uid;
  final dynamic timestamp;
  const MessageBubble(
      {super.key,
      required this.name,
      required this.text,
      required this.senderId,
      required this.uid,
      required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment:
            senderId == uid ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          senderId != uid
              ? Text(
                  name,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Container(),
          Material(
            borderRadius: senderId == uid
                ? const BorderRadius.all(Radius.circular(10))
                : const BorderRadius.all(Radius.circular(10)),
            elevation: 0,
            color: senderId == uid
                ? const Color(0xff00ddcb)
                : const Color(0xffE6E7EE),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                text,
                style: TextStyle(
                    color: senderId == uid ? Colors.white : Colors.black,
                    fontSize: 15),
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            DateFormat
                    // .yMMMEd()
                    .MEd()
                .add_jm()
                .format(DateTime.parse(timestamp.toString()).toLocal()),
            // timestamp.toString(),
            style: const TextStyle(fontSize: 8, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
