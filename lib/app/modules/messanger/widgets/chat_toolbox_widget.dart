import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/messanger_controller.dart';
import 'circle_button.dart';

Widget chatToolboxWidget({
  required BuildContext context,
  required MessangerController messengerController,
  required AuthController authController,
  required FirebaseFirestore firestore,
  required chatId,
  required peerUsername,
  required peerUserId,
  required TextEditingController controllerText,
}) {
  TextEditingController editingControllerText = TextEditingController();

  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(children: [
              //arnab implement
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(width: 1, color: Colors.grey)),
                child: const Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // border: Border.all(color: Colors.grey, width: 2)
                  ),
                  child: TextField(
                    controller: controllerText,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                        // border: OutlineInputBorder(
                        //     borderSide: BorderSide(color: Colors.teal)),
                        // prefixIcon: Icon(
                        //   Icons.chat_outlined,
                        //   color: Colors.blueGrey,
                        // ),
                        hintText: ' Type here'),
                    onChanged: (value) =>
                        messengerController.setMessageText(text: value),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ),
            ]),
          ),
        ),
        Obx(
          () {
            return messengerController.messageText.value != ''
                ? GestureDetector(
                    child: Icon(
                      Icons.send,
                      size: 46,
                      color: Theme.of(context).primaryColor,
                    ),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      String text = messengerController.messageText.value;
                      if (text.isNotEmpty) {
                        //Original Message
                        controllerText.clear();
                        firestore.collection('chats/messages/$chatId').add({
                          'sender_name':
                              authController.userProfile.value.user!.name,
                          'sender_id':
                              authController.userProfile.value.user!.id,
                          'text': text,
                          'imageUrl': authController
                              .userProfile.value.user!.profileImage,
                          'timestamp': DateTime.now().toString(),
                        }).then((value) {
                          messengerController.clearMessageText();
                          controllerText.clear();
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Can\'t send message',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                        //Owner copy for showing on Own Message List
                        firestore
                            .collection(
                                'chats/${authController.userProfile.value.user!.id}/message-list')
                            .doc(chatId)
                            .set({
                          'sender_name':
                              authController.userProfile.value.user!.name,
                          'sender_id':
                              authController.userProfile.value.user!.id,
                          'text': text,
                          'timestamp': DateTime.now().toString(),
                          'peerUsername': peerUsername,
                          'peerUserId': peerUserId,
                          'peerUserImageUrl': null,
                          'imageUrl': null,
                          'chatId': chatId,
                        });
                        //Admin copy for showing on Admin Message List
                        firestore
                            .collection('chats/$peerUserId/message-list')
                            .doc(chatId)
                            .set({
                          'sender_name':
                              authController.userProfile.value.user!.name,
                          'sender_id':
                              authController.userProfile.value.user!.id,
                          'text': text,
                          'timestamp': DateTime.now().toString(),
                          'peerUsername':
                              authController.userProfile.value.user!.name,
                          'peerUserId':
                              authController.userProfile.value.user!.id,
                          'peerUserImageUrl': authController
                              .userProfile.value.user!.profileImage,
                          'imageUrl': authController
                              .userProfile.value.user!.profileImage,
                          'chatId': chatId,
                        });
                      }
                    },
                  )
                :

                //arnab implementation
                Container(
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CircleButton(
                          icon: Icons.emoji_emotions,
                          iconSize: 25,
                          minWidth: 36,
                          minHeight: 36,
                          onPressed: () {},
                          backgroundColor: Colors.grey,
                          iconColor: Colors.white,
                        ),
                        CircleButton(
                          icon: Icons.image,
                          iconSize: 25,
                          minWidth: 36,
                          minHeight: 36,
                          onPressed: () {},
                          backgroundColor: Colors.grey,
                          iconColor: Colors.white,
                        ),
                        CircleButton(
                          icon: Icons.games_sharp,
                          iconSize: 25,
                          minWidth: 36,
                          minHeight: 36,
                          onPressed: () {},
                          backgroundColor: Colors.grey,
                          iconColor: Colors.white,
                        ),
                        CircleButton(
                          icon: Icons.video_call_rounded,
                          iconSize: 25,
                          minWidth: 36,
                          minHeight: 36,
                          onPressed: () {},
                          backgroundColor: Colors.grey,
                          iconColor: Colors.white,
                        ),
                      ],
                    ),
                  );
          },
        ),
      ],
    ),
  );
}
