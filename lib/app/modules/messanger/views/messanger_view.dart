import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:meetlivepro/constants/layout_constant.dart';


import '../../../../constants/image_helper.dart';
import 'chat_controller.dart';
import 'chat_model.dart';
import 'chatpage_view.dart';


class MessengerView extends StatelessWidget {
  final ChatController _chatController = Get.put(ChatController());
  MessengerView({super.key});
//alamin
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Get.back();
        }, icon: Icon(Icons.arrow_back,color: Colors.black,size: kHeight*0.028,)),
        elevation: 0,
        centerTitle: true,
        title: Text('Messages',style: GoogleFonts.poppins(
          fontSize: kHeight*0.019,
          fontWeight: FontWeight.w500
        ),),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffade8f0), // Light Blue
                Color(0xffcdaafc), // দ্বিতীয় color
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
        body:  Column(
          children: [
            SizedBox(
              height: Get.height * 0.02,
            ),
            Expanded(
              child: StreamBuilder<List<Chat>>(
                stream: _chatController.chats,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    // In MessengerView's ListView.builder
                    itemBuilder: (context, index) {
                      final chat = snapshot.data![index];

                      // Safely get the other participant
                      String? otherUserId;
                      try {
                        otherUserId = chat.participants.firstWhere(
                              (id) => id != _chatController.currentUserId,
                        );
                      } catch (e) {
                        // Skip malformed chats
                        return const SizedBox.shrink();
                      }

                      return _ChatTile(
                        chat: chat,
                        userId: otherUserId,
                        onTap: () => _openChat(chat, otherUserId!),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),);
  }

  void _openChat(Chat chat, String otherUserId) {
    final participantNames = chat.participantNames;
    final participantImages = chat.participantImages;

    Get.to(() => ChatPage(
          receiverId: otherUserId,
          receiverName: participantNames[otherUserId] ?? 'Unknown',
          receiverImage: participantImages[otherUserId] ?? '',
        ));
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  final String userId; // এটা হলো other user এর ID
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    final participantNames = chat.participantNames;
    final participantImages = chat.participantImages;

    // IMPORTANT: Current user এর unread count নিতে হবে
    final unreadCount = chat.unreadCounts[chatController.currentUserId] ?? 0;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: participantImages[userId] != null &&
                      participantImages[userId]!.isNotEmpty
                  ? NetworkImage(
                      ImageHelper.getImageUrl(participantImages[userId]!))
                  : null,
              radius: 23,
              child: participantImages[userId] == null ||
                      participantImages[userId]!.isEmpty
                  ? Icon(Icons.person, size: 23)
                  : null,
            ),
            title: Text(
              participantNames[userId] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              chat.lastMessage,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(chat.lastMessageTime),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                if (unreadCount > 0)
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                left: Get.width * 0.16, right: Get.width * 0.04),
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          )
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
