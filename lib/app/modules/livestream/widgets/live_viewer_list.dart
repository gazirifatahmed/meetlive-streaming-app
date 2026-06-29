import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../../../widgets/live_viewers_list.dart';

class LiveViewerList extends StatelessWidget {
  const LiveViewerList({
    super.key,
    required this.filteredList,
    this.isFromPk = false, // ✅ default value false
  });

  final bool isFromPk; // ✅ final রাখা ঠিক আছে
  final List filteredList;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kHeight * 0.6,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          SizedBox(height: kHeight * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: kWeight * 0.02),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Castontext(
                    fontSize: kHeight * 0.023,
                    fontWeight: FontWeight.w600,
                    textColor: Colors.black.withValues(alpha: .7),
                    text: 'All Viewer List',
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(28, 28),
                  ),
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: kAppColor, size: 18),
                ),
              ],
            ),
          ),
          SizedBox(height: kHeight * 0.004),

          /// 🔹 যদি Viewer না থাকে, তাহলে Center করে Empty Message দেখাও
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      'No viewers yet 👀',
                      style: GoogleFonts.roboto(
                        fontSize: kHeight * 0.016,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : LiveViewersList(

                    viewerList: filteredList,
                    isBroadcaster: livestreamController.isBroadcaster.value,
                    isFromPk: isFromPk,
                    onKickUser: (userId) {
                      livestreamController.kickOutUser(userId);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
