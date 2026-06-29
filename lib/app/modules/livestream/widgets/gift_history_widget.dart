import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/image_helper.dart';

class GiftHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> giftHistory;
  final Map<int, Map<String, dynamic>> seatUsers;

  const GiftHistoryWidget({
    super.key,
    required this.giftHistory,
    required this.seatUsers,
  });

  @override
  Widget build(BuildContext context) {
    // Show only last 10 minutes of gifts
    final now = DateTime.now();
    final recentGifts = giftHistory.where((gift) {
      final giftTime =
          DateTime.parse(gift['timestamp'] ?? now.toIso8601String());
      return now.difference(giftTime).inMinutes <= 10;
    }).toList();

    if (recentGifts.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Gifts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: recentGifts.length,
              itemBuilder: (context, index) {
                final gift = recentGifts[index];
                final senderSeat = gift['sender_seat'] ?? 0;
                final receiverSeat = gift['receiver_seat'] ?? 0;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Gift image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: ImageHelper.getImageUrl('${gift['gift']['gift_image']}'),
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 30,
                            height: 30,
                            color: Colors.grey[300],
                            child: Icon(Icons.card_giftcard, size: 16),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 30,
                            height: 30,
                            color: Colors.grey[300],
                            child: Icon(Icons.card_giftcard, size: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Gift details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getSeatUserName(senderSeat)} → ${_getSeatUserName(receiverSeat)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  gift['gift']['name'],
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.monetization_on,
                                    color: Colors.yellow, size: 12),
                                Text(
                                  '${gift['amount']}',
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Time
                      Text(
                        _formatTime(gift['timestamp']),
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getSeatUserName(int seatNo) {
    if (seatUsers.containsKey(seatNo)) {
      return seatUsers[seatNo]!['name'] ?? 'Seat $seatNo';
    }
    return 'Seat $seatNo';
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else {
        return '${difference.inHours}h';
      }
    } catch (e) {
      return '';
    }
  }
}
