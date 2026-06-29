import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetlivepro/app/modules/home/views/pk_live_list_view.dart';
import 'package:meetlivepro/app/modules/home/views/popular_live_list_view.dart';
import 'package:shimmer/shimmer.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/CastomContainer.dart';
import '../../livestream/widgets/GameBottomSheet.dart';
import '../../ranking/controllers/ranking_controller.dart';
import '../../ranking/views/allrank.dart';
import '../controllers/home_controller.dart';
import 'TopPkRank.dart';
import 'all_live_live_view.dart';
import 'audio_live_stream_list_view.dart';

// 🔹 Connectivity Controller (Fixed for connectivity_plus v6+)
class ConnectivityController extends GetxController {
  var isOnline = true.obs;
  // 1. টাইপ পরিবর্তন করে List<ConnectivityResult> করা হয়েছে
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    checkInitialConnectivity();
    startMonitoring();
  }

  Future<void> checkInitialConnectivity() async {
    // 2. checkConnectivity এখন List রিটার্ন করে
    var connectivityResult = await Connectivity().checkConnectivity();
    updateConnectionStatus(connectivityResult);
  }

  void startMonitoring() {
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) { // 3. এখানেও List গ্রহণ করা হচ্ছে
      updateConnectionStatus(results);
    });
  }

  // 4. প্যারামিটার টাইপ পরিবর্তন করে List<ConnectivityResult> করা হয়েছে
  void updateConnectionStatus(List<ConnectivityResult> results) {
    // যদি লিস্টে ConnectivityResult.none থাকে, তার মানে কোনো ইন্টারনেট কানেকশন নেই
    if (results.contains(ConnectivityResult.none)) {
      isOnline.value = false;
      showOfflineDialog();
    } else {
      isOnline.value = true;
      if (Get.isDialogOpen ?? false) {
        Get.back(); // Dialog বন্ধ করবে
      }
    }
  }

  void showOfflineDialog() {
    if (Get.isDialogOpen ?? false) return; // যদি ইতিমধ্যে Dialog খোলা থাকে

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You are offline',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We are unable to reach server. Please check your network settings and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    AppSettings.openAppSettings(type: AppSettingsType.wifi);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C52FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'RETRY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    connectivitySubscription.cancel();
    super.onClose();
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Map<String, dynamic>? selectedUser;

  void searchUser(String uid) {
    if (uid.isEmpty) {
      setState(() => selectedUser = null);
      return;
    }

    try {
      final user = homeController.allUserData.firstWhere(
        (u) => u['user_id'].toString() == uid,
      );

      setState(() {
        selectedUser = user;
      });
    } catch (e) {
      setState(() => selectedUser = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
    RankingController controller = Get.put(RankingController());

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(Get.height * 0.06),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, 
                end: Alignment.bottomCenter, 

                stops: [0.0, 0.5, 0.9],
                colors: [
                  Color(0xffade8f0), 
                  Color(0xffcdaafc), 
                  Colors.white, 
                ],
              ),
            ),
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Column(
                children: [
                  Container(
                    width: Get.width * 0.6,
                    height: kHeight * 0.04,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffcdaafc).withValues(alpha: 0.4), 
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 0), 
                        ),
                      ],
                    ),
                    child: TextFormField(
                      onChanged: (value) {
                        searchUser(value.trim());
                      },
                      decoration: InputDecoration(
                        hintText: "Search...",
                        hintStyle: TextStyle(
                          fontSize: kHeight * 0.015,
                          color: Colors.grey[600],
                        ),
                        prefixIcon: Icon(
                          size: kHeight * 0.023,
                          Icons.search,
                          color: Colors.grey[700],
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: kWeight * 0.02,
                          vertical: 1,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                SizedBox(width: kWeight * 0.03),
                InkWell(
                  onTap: () {
                    Get.to(() => Allrank(), transition: Transition.rightToLeft);
                  },
                  child: Image.asset(
                    'assets/images/trophy.png',
                    height: Get.height * 0.036,
                  ),
                ),
                SizedBox(width: kWeight * 0.03),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: IconButton(
                    onPressed: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: false,
                        onSelect: (Country country) {
                          controller.selectedCountry.value = country;
                        },
                      );
                    },
                    icon: Image.asset(
                      'assets/logo/globe.png',
                      height: Get.height * 0.03,
                    ),
                    tooltip: 'Change Country',
                  ),
                ),
                SizedBox(width: kWeight * 0.04),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Obx(() {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                height: controller.isLoading.value || selectedUser != null
                    ? kHeight * 0.13
                    : 0,
                width: double.infinity,
                margin: EdgeInsets.symmetric(
                    horizontal: kWeight * 0.04, vertical: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: controller.isLoading.value
                      ? shimmerWidget()
                      : selectedUser != null
                          ? profileCard(selectedUser!)
                          : const SizedBox(),
                ),
              );
            }),
            Padding(
              padding: EdgeInsets.only(right: kWeight * 0.05),
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(() => Text(
                      '${controller.selectedCountry.value.flagEmoji} ${controller.selectedCountry.value.name}',
                      style: GoogleFonts.lato(
                        fontSize: kHeight * 0.015,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    )),
              ),
            ),
            const SizedBox(height: 8,),
            SizedBox(
              height: Get.height * 0.12,
              child: FutureBuilder(
                future: homeController.showBannerList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: Get.width * 0.02),
                          width: Get.width * 0.9,
                          height: Get.height * 0.12,
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  if (homeController.bannerLstData.isEmpty) {
                    return const SizedBox();
                  }

                  return CarouselSlider.builder(
                    itemCount: homeController.bannerLstData.length,
                    itemBuilder: (context, index, realIndex) {
                      final imageUrl = homeController.bannerLstData[index]
                                  ['image']
                              ?.toString() ??
                          "";
                      final hasImage = imageUrl.isNotEmpty;

                      return Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: Get.width * 0.02),
                        width: double.infinity,
                        height: Get.height * 0.12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: hasImage ? null : Colors.grey[300],
                          image: hasImage
                              ? DecorationImage(
                                  image: NetworkImage(
                                    imageUrl.startsWith('http')
                                        ? imageUrl
                                        : ImageHelper.getImageUrl(imageUrl),
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    print(
                                        'Banner image load error: $exception');
                                  },
                                )
                              : null,
                        ),
                        child: hasImage
                            ? null
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[600],
                                  size: 40,
                                ),
                              ),
                      );
                    },
                    options: CarouselOptions(
                      height: Get.height * 0.12,
                      viewportFraction: 1.0,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      reverse: true,
                      enlargeCenterPage: false,
                      scrollDirection: Axis.horizontal,
                    ),
                  );
                },
              ),
            ),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xffade8f0),
                    Color(0xffcdaafc),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),

                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),

                labelPadding: EdgeInsets.zero,
                indicatorPadding: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 3,
                ),

                labelColor: const Color(0xff528dfb),
                unselectedLabelColor: Colors.white.withValues(alpha: 0.85),

                labelStyle: GoogleFonts.lato(
                  fontSize: kHeight * 0.015,

                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.lato(
                  fontSize: kHeight * 0.014,
                  fontWeight: FontWeight.w500,
                ),

                tabs: [
                  _buildTab("Showing"),
                  _buildTab("Popular"),
                  _buildTab("Audio"),
                  _buildTab("Pk_Match"),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  AllLiveListView(),
                  PopularLiveListView(),
                  AudioLiveListView(),
                  PkLiveListView(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Obx(() {
          return FloatingActionButton(
            backgroundColor: const Color(0xff038345),
            onPressed: homeController.isLoading.value
                ? null
                : () async {
              await homeController.getLivestreamList();
            },
            child: homeController.isLoading.value
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }
}

Widget _buildTab(String text) {
  return Tab(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text),
    ),
  );
}

Widget shimmerWidget() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[300],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120, height: 14, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 150, height: 12, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 100, height: 12, color: Colors.white),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget profileCard(dynamic user) {
  return Container(
    key: ValueKey(user['id']),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white,
          Colors.grey.shade50,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -5,
        ),
      ],
      border: Border.all(
        color: Colors.grey.withValues(alpha: 0.1),
        width: 1,
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          homeController.visitProfile(userId: '${user['id']}');
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kWeight * 0.04,
            vertical: kHeight * 0.015,
          ),
          child: const Row(
            children: [
               // প্রোফাইল কার্ডের ভেতরের বাকি ডিজাইন আপনার প্রয়োজন মত রাখতে পারেন...
            ],
          ),
        ),
      ),
    ),
  );
}