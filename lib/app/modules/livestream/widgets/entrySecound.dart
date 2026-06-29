import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';

class UserJoinAnimation extends StatefulWidget {
  final String imageUrl;
  final dynamic imageFrame;
  final String userName;
  final String userLv;
  final String userLvFrame;
  const UserJoinAnimation({
    super.key,
    required this.imageUrl,
    required this.userName,
    required this.userLv,
    required this.imageFrame,
    required this.userLvFrame,
  });

  @override
  State<UserJoinAnimation> createState() => _UserJoinAnimationState();
}

class _UserJoinAnimationState extends State<UserJoinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
//hello
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kHeight = MediaQuery.of(context).size.height;
    final kWidth = MediaQuery.of(context).size.width;
    print('Level Frame kamal ${widget.userLvFrame}');
    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: kWidth * 0.615,
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 5),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            border: Border.all(color: kAppColor),
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: kHeight * 0.035,
                width: kHeight * 0.035,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 🟢 Profile Image with fallback
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        height: kHeight * 0.025,
                        width: kHeight * 0.025,
                        fit: BoxFit.cover,
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
                    if (widget.imageFrame != null &&
                        widget.imageFrame['asset'] != null &&
                        widget.imageFrame['asset']['asset'] != null)
                      // Check if the asset path ends with .svga
                      (widget.imageFrame['asset']['asset']
                              .toString()
                              .endsWith('.svga'))
                          ? SizedBox(
                              height: kHeight * 0.035,
                              width: kHeight * 0.035,
                              child: SVGAEasyPlayer(
                                resUrl: ImageHelper.getImageUrl(
                                    '${widget.imageFrame['asset']['asset']}'),
                                fit: BoxFit.cover,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: ImageHelper.getImageUrl(
                                  '${widget.imageFrame['asset']['asset']}'),
                              height: kHeight * 0.035,
                              width: kHeight * 0.035,
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
              const SizedBox(width: 1),
              SizedBox(
                height: kHeight * 0.025, // পুরো ফ্রেমের ফিক্সড সাইজ
                width: kHeight * 0.05,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Background SVGA animation
                    Container(
                        margin: EdgeInsets.only(
                            left: kWidth * 0.03, right: kWidth * 0.02),
                        height: kHeight * 0.015, // পুরো ফ্রেমের ফিক্সড সাইজ
                        width: kHeight * 0.02,
                        child: authController
                                    .userProfile.value.user!.levelImage ==
                                null
                            ? SizedBox(
                                height: kHeight * 0.016,
                                width: kHeight * 0.02,
                                child: SVGAEasyPlayer(
                                  assetsName:
                                      'assets/svga/Level/level_0_to_9_bg.svga',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : SizedBox(
                                height: kHeight * 0.016,
                                width: kHeight * 0.02,
                                child: SVGAEasyPlayer(
                                  resUrl: ImageHelper.getImageUrl(authController
                                      .userProfile.value.user!.levelImage),
                                  fit: BoxFit.cover,
                                ),
                              )),

                    // Level Text
                    Positioned(
                      right: widget.userLv.length == 1
                          ? kHeight * 0.011
                          : kHeight * 0.007,
                      child: Text(
                        widget.userLv,
                        style: GoogleFonts.roboto(
                          fontSize: kHeight * 0.011,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black45,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.userName,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: kHeight * 0.014,
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
}
