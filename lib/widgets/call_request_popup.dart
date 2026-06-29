import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


import '../constants/color_constants.dart';
import '../constants/image_helper.dart';
import '../constants/layout_constant.dart';

class CallRequestPopup extends StatefulWidget {
  final Map<String, dynamic> callData;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const CallRequestPopup({
    super.key,
    required this.callData,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<CallRequestPopup> createState() => _CallRequestPopupState();
}

class _CallRequestPopupState extends State<CallRequestPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for popup entrance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Pulse animation for avatar
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map user = widget.callData['user'] is Map
        ? Map.from(widget.callData['user'])
        : {};

    final callerId = widget.callData['caller_id'] ??
        widget.callData['user_id'] ??
        user['id'] ??
        user['user_id'];

    final userName = (user['name'] ??
        widget.callData['name'] ??
        widget.callData['caller_name'] ??
        (callerId == null ? 'Unknown User' : 'User $callerId'))
        .toString();

    final userImage = (user['profile_image'] ??
        widget.callData['profile_image'] ??
        widget.callData['caller_image'] ??
        '')
        .toString();

    final userLevel = user['level'] ??
        widget.callData['level'] ??
        widget.callData['caller_level'] ??
        0;

    final displayUid = user['user_id'] ??
        widget.callData['uid'] ??
        callerId ??
        'N/A';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: kWeight * 0.08),
              padding: EdgeInsets.all(kWeight * 0.06),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: kWeight * 0.04,
                      vertical: kHeight * 0.01,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.callData['call_type'] == "audio"
                              ? Icons.call
                              : Icons.video_call,
                          color: Colors.white,
                          size: kWeight * 0.05,
                        ),
                        SizedBox(width: kWeight * 0.02),
                        Text(
                          'Incoming Call Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: kWeight * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: kHeight * 0.03),

                  // User Avatar with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: kWeight * 0.25,
                          height: kWeight * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                kPrimaryColor.withValues(alpha: 0.3),
                                kPrimaryColor.withValues(alpha: 0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(kWeight * 0.01),
                            child: ClipOval(
                              child: userImage.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl:
                                ImageHelper.getImageUrl(userImage),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: SpinKitFadingCircle(
                                    color: kPrimaryColor,
                                    size: kWeight * 0.08,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    Container(
                                      color: Colors.grey.shade300,
                                      child: Icon(
                                        Icons.person,
                                        size: kWeight * 0.12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                              )
                                  : Container(
                                color: Colors.grey.shade300,
                                child: Icon(
                                  Icons.person,
                                  size: kWeight * 0.12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: kHeight * 0.02),

                  // User Name
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: kWeight * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: kHeight * 0.005),

                  // User Level
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: kWeight * 0.03,
                      vertical: kHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Level $userLevel',
                      style: TextStyle(
                        fontSize: kWeight * 0.035,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),

                  SizedBox(height: kHeight * 0.006),

                  Text(
                    'ID: $displayUid',
                    style: TextStyle(
                      fontSize: kWeight * 0.032,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: kHeight * 0.01),

                  // Call request message
                  Text(
                    'wants to join your live stream',
                    style: TextStyle(
                      fontSize: kWeight * 0.04,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: kHeight * 0.04),

                  // Action Buttons
                  Row(
                    children: [
                      // Reject Button
                      Expanded(
                        child: SizedBox(
                          height: kHeight * 0.06,
                          child: ElevatedButton(
                            onPressed: () {
                              _scaleController.reverse().then((_) {
                                widget.onReject();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade500,
                              foregroundColor: Colors.white,
                              elevation: 5,
                              shadowColor: Colors.red.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.call_end,
                                  size: kWeight * 0.05,
                                ),
                                SizedBox(width: kWeight * 0.02),
                                Text(
                                  'Reject',
                                  style: TextStyle(
                                    fontSize: kWeight * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: kWeight * 0.04),

                      // Accept Button
                      Expanded(
                        child: SizedBox(
                          height: kHeight * 0.06,
                          child: ElevatedButton(
                            onPressed: () {
                              _scaleController.reverse().then((_) {
                                widget.onAccept();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              foregroundColor: Colors.white,
                              elevation: 5,
                              shadowColor: Colors.green.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.call,
                                  size: kWeight * 0.05,
                                ),
                                SizedBox(width: kWeight * 0.02),
                                Text(
                                  'Accept',
                                  style: TextStyle(
                                    fontSize: kWeight * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show the call request popup
  static void show({
    required BuildContext context,
    required Map<String, dynamic> callData,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CallRequestPopup(
        callData: callData,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }
}
