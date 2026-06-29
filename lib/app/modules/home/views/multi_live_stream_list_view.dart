import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_const/image_conost.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomText.dart';
import '../../livestream/controllers/livestream_controller.dart';
import '../controllers/home_controller.dart';
import 'all_live_live_view.dart';

class MultiLiveListView extends GetView<HomeController> {
  const MultiLiveListView({super.key});

  @override
  Widget build(BuildContext context) {
    HomeController controller = Get.put(HomeController());
    Get.put(LivestreamController());
    return Scaffold(
      // backgroundColor: Color(0xfffcfdfd),

      body: CustomRefreshIndicator(
        onRefresh: () async {
          await homeController.getLivestreamList();
        },
        builder: (BuildContext context, Widget child,
            IndicatorController controller) {
          return Stack(
            children: [
              child, // Your scrollable content
              // Custom indicator
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return SizedBox(
                      height: controller.value * 80, // adjust height as needed
                      child: Center(
                        child: controller.isIdle
                            ? const SizedBox()
                            : Container(
                                decoration: BoxDecoration(
                                    color: kAppColor,
                                    borderRadius: BorderRadius.circular(50)),
                                child: Transform.scale(
                                  scale: controller.value
                                      .clamp(0.0, 1.0), // grow as you pull
                                  child: Image.asset(
                                    appLogo, // your image path
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Obx(() {
            final users = controller.showingLiveStreamList;

            if (users.isEmpty) {
              return Center(
                child: Padding(
                    padding: EdgeInsets.all(kHeight * 0.1),
                    child: Column(
                      children: [
                        SizedBox(
                          height: kHeight * 0.01,
                        ),
                        Lottie.asset(
                          'assets/flaticons/nYuPvdjcOD.json',
                          height: kHeight * 0.14,
                          width: kHeight * 0.14,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(
                          height: kHeight * 0.01,
                        ),
                        Castontext(
                            fontWeight: FontWeight.w500,
                            textColor: Colors.black.withValues(alpha: .6),
                            fontSize: kHeight * 0.012,
                            text: 'No Stream Available'),
                      ],
                    )),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: kHeight * 0.23,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(4),
                        ),
                      );
                    },
                  );
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: kHeight * 0.23,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: controller.showingLiveStreamList.length,
                  itemBuilder: (context, index) {
                    final item = controller.showingLiveStreamList[index];
                    return item['stream_type'] == 'multi'
                        ? UserProfileCard(
                            data: item,
                            index: index,
                          )
                        : Container();
                  },
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}
