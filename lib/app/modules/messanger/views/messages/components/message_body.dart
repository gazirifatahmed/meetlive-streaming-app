import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../auth/controllers/auth_controller.dart';
import '../../../controllers/messanger_controller.dart';
import '../../../widgets/chat_toolbox_widget.dart';
import '../../../widgets/message_bubble_widget.dart';

class MessageBody extends GetView {
  MessageBody({
    super.key,
    required this.chatId,
    required this.peerUsername,
    required this.peerUserId,
    this.peerUserImageUrl,
  });
  final String chatId, peerUsername;
  final String? peerUserImageUrl;
  final int peerUserId;
  final AuthController _authController = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controllerText = TextEditingController();
  final MessangerController _messengerController = Get.find();

  @override
  Widget build(BuildContext context) {
    Future.delayed(
        Duration.zero, (() => _messengerController.clearMessageText()));
    return Scaffold(
      body: Column(
        children: [
          // Chat body
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats/messages/$chatId')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Something went wrong',
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        backgroundColor: Colors.white),
                  );
                }

                final messages = snapshot.data?.docs.reversed;
                if (messages == null) {
                  return Container();
                }
                return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages.elementAt(index);
                      final messageText = message.get('text');
                      final messageSenderName = message.get('sender_name');
                      final messageSenderId = message.get('sender_id');
                      final timestamp = message.get('timestamp');
                      return MessageBubble(
                        name: messageSenderName,
                        text: messageText,
                        senderId: messageSenderId,
                        uid:
                            _authController.userProfile.value.user!.id!.toInt(),
                        timestamp: timestamp,
                      );
                      // return Text('eee');
                    });
              },
            ),
          ),
          chatToolboxWidget(
            context: context,
            messengerController: _messengerController,
            authController: _authController,
            firestore: _firestore,
            chatId: chatId,
            peerUsername: peerUsername,
            peerUserId: peerUserId,
            controllerText: _controllerText,
          ),
        ],
      ),
    );
  }
}
