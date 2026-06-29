import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';

class LiveProfile extends StatelessWidget {
  final dynamic data;

  const LiveProfile({
    super.key,
    required this.data,
  });

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _getUserMap(dynamic rawData) {
    final item = _asMap(rawData);

    if (item['user'] is Map) {
      return _asMap(item['user']);
    }

    // viewer event থেকে direct user data আসলে fallback
    return item;
  }

  dynamic _getUserId(Map<String, dynamic> item, Map<String, dynamic> user) {
    return user['id'] ??
        item['viewer_id'] ??
        item['user_id'] ??
        item['caller_id'] ??
        item['id'];
  }

  @override
  Widget build(BuildContext context) {
    final item = _asMap(data);
    final user = _getUserMap(data);

    final userId = _getUserId(item, user);
    final profileImage = user['profile_image'];

    final assetPurchaseHistory = user['asset_purchase_history'];
    final asset = assetPurchaseHistory is Map ? assetPurchaseHistory['asset'] : null;
    final assetPath = asset is Map ? asset['asset'] : null;

    return InkWell(
      onTap: () {
        if (userId != null) {
          homeController.liveVisitProfile(
            userId: '$userId',
            seatData: item,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: SizedBox(
            height: kHeight * 0.08,
            width: kHeight * 0.04,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ---------------- PROFILE IMAGE ----------------
                Container(
                  height: Get.height * 0.03,
                  width: Get.height * 0.03,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: profileImage == null || profileImage.toString().isEmpty
                        ? Image.asset(
                      'assets/flaticons/boy.png',
                      height: kHeight * 0.04,
                      width: kHeight * 0.04,
                      fit: BoxFit.cover,
                    )
                        : CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: ImageHelper.getImageUrl('$profileImage'),
                      placeholder: (context, url) => Image.asset(
                        'assets/flaticons/boy.png',
                        height: kHeight * 0.04,
                        width: kHeight * 0.04,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/flaticons/boy.png',
                        height: kHeight * 0.04,
                        width: kHeight * 0.04,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // ---------------- NORMAL FRAME ----------------
                if (assetPath != null && assetPath.toString().isNotEmpty)
                  assetPath.toString().endsWith('.svga')
                      ? SizedBox(
                    height: kHeight * 0.09,
                    width: kHeight * 0.09,
                    child: SVGAEasyPlayer(
                      resUrl: '$kDomainUrl/$assetPath',
                      fit: BoxFit.cover,
                    ),
                  )
                      : CachedNetworkImage(
                    imageUrl: "$kDomainUrl/$assetPath",
                    height: kHeight * 0.09,
                    width: kHeight * 0.09,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: kHeight * 0.06,
                      width: kHeight * 0.06,
                      decoration: BoxDecoration(
                        color: kAppColor.withValues(alpha: .02),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: kHeight * 0.12,
                      width: kHeight * 0.12,
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
                else
                  SizedBox(
                    height: kHeight * 0.03,
                    width: kHeight * 0.03,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
