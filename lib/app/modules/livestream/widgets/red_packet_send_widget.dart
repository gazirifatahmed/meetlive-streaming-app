import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/livestream_controller.dart';
import '../controllers/websocket_controller.dart';

class RedPacketSendWidget extends StatefulWidget {
  final int streamId;
  
  const RedPacketSendWidget({
    super.key,
    required this.streamId,
  });

  @override
  State<RedPacketSendWidget> createState() => _RedPacketSendWidgetState();
}

class _RedPacketSendWidgetState extends State<RedPacketSendWidget> {
  final LivestreamController liveController = Get.find();
  final WebsocketController websocketController = Get.find();
  
  final TextEditingController amountController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  
  int selectedCount = 1;
  final List<int> countOptions = [1, 5, 10, 20, 50];
  
  int selectedDuration = 2; // Default 2 minutes
  String selectedScope = 'Current Stream'; // Default scope
  
  bool isLoading = false;

  @override
  void dispose() {
    amountController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFFF8E8E),
            Color(0xFFFFB3B3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Send Red Packet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Amount Input
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter amount (coins)',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.monetization_on, color: Colors.white70),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Count Selection
          Text(
            'Number of Red Packets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: countOptions.map((count) {
              final isSelected = selectedCount == count;
              return GestureDetector(
                onTap: () => setState(() => selectedCount = count),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.transparent 
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Color(0xFFFF6B6B) : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 16),
          
          // Message Input
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: messageController,
              style: TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a message (optional)',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.message, color: Colors.white70),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Send Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _sendRedPacket,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6B6B),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Send Red Packet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRedPacket() async {
    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter an amount",
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        "Error",
        "Please enter a valid amount",
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await liveController.sendRedPacket(
        amount: amount,
        message: messageController.text.trim().isNotEmpty 
            ? messageController.text.trim() 
            : null,
        durationMinutes: selectedDuration,
        isGlobal: selectedScope == 'Global',
      );

      if (success) {
        Navigator.pop(context);
        Get.snackbar(
          "🧧 Success!",
          "Red packet sent successfully!",
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to send red packet. Please try again.",
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "An error occurred: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
