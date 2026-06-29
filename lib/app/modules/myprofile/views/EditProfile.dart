import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:meetlivepro/app/modules/myprofile/views/widgets/changeCoverImage.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../controllers/myprofile_controller.dart';
import 'Nickname.dart';
import 'SignaturePage.dart';

class Editprofile extends StatelessWidget {
  const Editprofile({super.key});

  @override
  Widget build(BuildContext context) {
    final MyprofileController controller = Get.put(MyprofileController());

    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: CustomAppBar(
        title: 'Edit Profile',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.015,
          ),
          child: Column(
            children: [
              _premiumCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _titleText('Avatar', isSmall),
                    Obx(() {
                      final frameData =
                      homeController.activeFrameData['active_asset_ids'];
                      final profileImage =
                          authController.userProfile.value.user?.profileImage;

                      // Safe convert
                      final agencyIdRaw =
                          authController.userProfile.value.user?.agencyId;
                      final int agencyId =
                          int.tryParse(agencyIdRaw?.toString() ?? '0') ?? 0;

                      return InkWell(
                        onTap: () {
                          controller.updateProfile();
                        },
                        child: SizedBox(
                          height: kHeight * 0.1,
                          width: kHeight * 0.11,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // ---------------- PROFILE IMAGE ----------------
                              CircleAvatar(
                                radius: kHeight * 0.0363,
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: controller.profileImage.isEmpty
                                      ? CachedNetworkImage(
                                    imageUrl: ImageHelper.getImageUrl(
                                        profileImage),
                                    fit: BoxFit.cover,
                                    height: kHeight * 0.07,
                                    width: kHeight * 0.07,
                                    placeholder: (context, url) =>
                                        Container(
                                          height: kHeight * 0.097,
                                          width: kHeight * 0.097,
                                          color: kAppColor.withValues(alpha: .2),
                                        ),
                                    errorWidget: (context, url, error) =>
                                        Icon(
                                          Icons.person,
                                          size: 40,
                                          color: kAppColor.withValues(alpha: .2),
                                        ),
                                  )
                                      : Image.file(
                                    File(controller.profileImage.value),
                                    height: kHeight * 0.05,
                                    width: kHeight * 0.05,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // ---------------- AGENCY FRAME (if agencyId > 0) ----------------
                              if (agencyId > 0)
                                SVGAEasyPlayer(
                                  assetsName:
                                  'assets/svga/Frame/Agency frame.svga',
                                  fit: BoxFit.cover,
                                )

                              // ---------------- NORMAL FRAME (if no agency frame) --------------
                              else if (frameData != null &&
                                  frameData['asset'] != null &&
                                  frameData['asset']['asset'] != null)
                              // Check if the asset path ends with .svga
                                (frameData['asset']['asset']
                                    .toString()
                                    .endsWith('.svga'))
                                    ? SizedBox(
                                  height: kHeight * 0.08,
                                  width: kHeight * 0.08,
                                  child: SVGAEasyPlayer(
                                    resUrl:
                                    '$kDomainUrl/${frameData['asset']['asset']}',
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : CachedNetworkImage(
                                  imageUrl:
                                  "$kDomainUrl/${frameData['asset']['asset']}",
                                  height: kHeight * 0.12,
                                  width: kHeight * 0.12,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: kHeight * 0.12,
                                    width: kHeight * 0.12,
                                    decoration: BoxDecoration(
                                      color: kAppColor.withValues(alpha: .02),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        height: kHeight * 0.12,
                                        width: kHeight * 0.12,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                          BorderRadius.circular(12),
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
                                  height: kHeight * 0.12,
                                  width: kHeight * 0.12,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.015),

              Obx(
                    () => ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: CoverImagePicker(
                    localImagePath:
                    controller.picProfileImageCover.value.isEmpty
                        ? null
                        : controller.picProfileImageCover.value,
                    networkImageUrl:
                    authController.userProfile.value.user?.coverImages,
                    onTap: () {
                      controller.updateProfileCover();
                    },
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.018),

              _premiumCard(
                child: Column(
                  children: [
                    Obx(
                          () => _profileTile(
                        title: 'Nick Name',
                        value:
                        authController.userProfile.value.user?.name ?? '',
                        isSmall: isSmall,
                        onTap: () {
                          Get.to(
                            Nickname(),
                            transition: Transition.rightToLeft,
                          );
                        },
                      ),
                    ),
                    _softDivider(),
                    Obx(
                          () => _profileTile(
                        title: 'Uid',
                        value:
                        '${authController.userProfile.value.user?.userId ?? ''}',
                        isSmall: isSmall,
                        showArrow: false,
                      ),
                    ),
                    _softDivider(),
                    Obx(
                          () => _profileTile(
                        title: 'Gender',
                        value:
                        authController.userProfile.value.user?.gender ?? '',
                        isSmall: isSmall,
                        showArrow: false,
                      ),
                    ),
                    _softDivider(),
                    Obx(
                          () => _profileTile(
                        title: 'Birth day',
                        value:
                        authController.userProfile.value.user?.dateofbirth ?? '',
                        isSmall: isSmall,
                        showArrow: false,
                      ),
                    ),
                    _softDivider(),
                    Obx(
                          () => _profileTile(
                        title: 'Country',
                        value:
                        authController.userProfile.value.user?.country ?? '',
                        isSmall: isSmall,
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: false,
                            onSelect: (Country country) {
                              controller.selectedCountry.value = country;
                            },
                          );
                        },
                      ),
                    ),
                    _softDivider(),
                    _profileTile(
                      title: 'Signature',
                      value: '',
                      isSmall: isSmall,
                      onTap: () {
                        Get.to(
                          Signaturepage(),
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _premiumCard({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: .8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .055),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget _profileTile({
    required String title,
    required String value,
    required bool isSmall,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _titleText(title, isSmall),
            ),
            Expanded(
              flex: 4,
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSmall ? 12 : 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: .58),
                ),
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: isSmall ? 12 : 14,
                color: Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _titleText(String text, bool isSmall) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isSmall ? 13 : 14.5,
        fontWeight: FontWeight.w700,
        color: Colors.black.withValues(alpha: .78),
      ),
    );
  }

  static Widget _softDivider() {
    return Divider(
      height: 1,
      thickness: .7,
      color: Colors.grey.withValues(alpha: .16),
    );
  }
}
class CastomTextLevel extends StatelessWidget {
  final String text;
  final String seText;

  const CastomTextLevel({
    super.key,
    required this.text,
    required this.seText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Castontext(fontSize: 17, fontWeight: FontWeight.w600, text: text),
        Row(
          children: [
            Castontext(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              text: seText,
            ),
            SizedBox(
              width: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: Colors.grey,
              ),
            )
          ],
        )
      ],
    );
  }
}
