import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/color_constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';

class EntryAnimation extends StatefulWidget {
  final dynamic data;

  const EntryAnimation({super.key, required this.data});
  @override
  _EntryAnimationState createState() => _EntryAnimationState();
}

class _EntryAnimationState extends State<EntryAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 5), // entry animation duration
      vsync: this,
    )..forward();

    // Scale Animation (pulse effect)
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Rotation Animation (slight tilt)
    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Slide Animation (Right to Left with fast + slow effect)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0), // Right side (off-screen)
      end: Offset.zero, // Final position
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutQuint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Entry animation ${widget.data}');
    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.centerLeft, // start from right
        child: Container(
          width: kWeight * 0.6,
          margin: EdgeInsets.only(left: 12),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: .8),
              bottom: BorderSide(color: Colors.white, width: .8),
            ),
            borderRadius: BorderRadius.circular(100),
            gradient: LinearGradient(
              colors: [kAppColor, kAppColor.withValues(alpha: .4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // take only content width
            children: [
              const SizedBox(width: 0),
              SizedBox(
                height: kHeight * 0.05,
                width: kHeight * 0.05,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 🟢 Profile Image with fallback
                    ClipOval(
                      child: widget.data['user']['profile_image'] == null
                          ? Image.asset(
                              'assets/images/support_user.png',
                              width: kHeight * 0.045,
                              height: kHeight * 0.045,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: ImageHelper.getImageUrl(
                                widget.data['user']['profile_image'],
                              ),
                              fit: BoxFit.cover,
                              width: kHeight * 0.03,
                              height: kHeight * 0.03,
                            ),
                    ),

                    // if (user[
                    // 'agency_id']  > 0)
                    //   SVGAEasyPlayer(
                    //     assetsName:
                    //     'assets/svga/Frame/Agency frame.svga',
                    //     fit: BoxFit.cover,
                    //   )

                    // ---------------- NORMAL FRAME (if no agency frame) --------------
                    if (widget.data['user']['asset_purchase_history'] != null &&
                        widget.data['user']['asset_purchase_history']
                                ['asset'] !=
                            null &&
                        widget.data['user']['asset_purchase_history']['asset']
                                ['asset'] !=
                            null)
                      // Check if the asset path ends with .svga
                      (widget.data['user']['asset_purchase_history']['asset']
                                  ['asset']
                              .toString()
                              .endsWith('.svga'))
                          ? SizedBox(
                              height: kHeight * 0.04,
                              width: kHeight * 0.04,
                              child: SVGAEasyPlayer(
                                resUrl: ImageHelper.getImageUrl(
                                    '${widget.data['user']['asset_purchase_history']['asset']['asset']}'),
                                fit: BoxFit.cover,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: ImageHelper.getImageUrl(
                                  '${widget.data['user']['asset_purchase_history']['asset']['asset']}'),
                              height: kHeight * 0.04,
                              width: kHeight * 0.04,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: kHeight * 0.02,
                                width: kHeight * 0.05,
                                decoration: BoxDecoration(
                                  color: kAppColor.withValues(alpha: .02),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: kHeight * 0.05,
                                width: kHeight * 0.05,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: kAppColor.withValues(alpha: .2),
                                ),
                              ),
                            )

                    // ---------------- NOTHING (no frame) ----------------
                    else
                      SizedBox(
                        height: kHeight * 0.03,
                        width: kHeight * 0.03,
                      ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  '${widget.data['user']['name']}...Entry the room',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: kHeight * 0.013,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
