import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/livestream_controller.dart';
import '../controllers/websocket_controller.dart';
import 'go_to_live_audio.dart';
import 'goto_live_popular.dart';

class GotoLiveTabView extends StatefulWidget {
  const GotoLiveTabView({super.key});

  @override
  State<GotoLiveTabView> createState() => _GotoLiveTabViewState();
}

class _GotoLiveTabViewState extends State<GotoLiveTabView>
    with SingleTickerProviderStateMixin {
  // Removed local Agora engine and preview setup to avoid auto camera activation.

  String liveType = 'public';
  late TabController _tabController;
  TextEditingController textEditingController =
  TextEditingController(text: 'hello');

  AuthController authController = Get.find();
  LivestreamController liveController = Get.put(LivestreamController());
  WebsocketController controller = Get.put(WebsocketController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Removed initAgora to prevent camera preview at tab load
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black12,
        body: Stack(
          children: [
            // Foreground content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      GotoPopularLive(),
                      // GotoMultiLive(),
                      GotoAudioLiveView(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xffffffff),
          ),
          child: SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: kHeight * 0.015,
                horizontal: kHeight * 0.01,
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xfff93776),
                      Color(0xff7f23e8),
                      Color(0xff218afb),

                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 34,
                ),
                dividerColor: Colors.transparent,

                labelColor: Colors.white,
                unselectedLabelColor: kAppColor,

                tabs: [
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.live_tv),
                        Text(
                          'Popular',
                          style: GoogleFonts.poppins(
                            fontSize: kHeight * 0.013,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic),
                        Text(
                          'Audio',
                          style: GoogleFonts.poppins(
                            fontSize: kHeight * 0.013,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
