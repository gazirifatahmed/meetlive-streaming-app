import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SvipController extends GetxController {
  final List<Map<String, String>> gridItems = [
    {'image': 'assets/svga/Frame/Vip frame 1.svga', 'text': 'Vip1 Frame'},
    {'image': 'assets/Svip/Svip.png', 'text': 'VIP Title'},
    {'image': 'assets/Svip/profile (2).png', 'text': 'VIP Badge'},
    {'image': 'assets/Svip/svip1.png', 'text': 'VIP Entry'},
    {'image': 'assets/Svip/frame.png', 'text': 'Colourful Profile'},
    {'image': 'assets/Svip/animal.png', 'text': 'Colourful Chat'},
  ];
  final List<Map<String, String>> gridItems2 = [
    {
      'image': 'assets/svip_exclusive_image/svipacount2.png',
      'text': 'Anti-comment Mute'
    },
    {
      'image': 'assets/svip_exclusive_image/svipLodo.png',
      'text': 'Anti-kick\nanti-ban'
    },
    {'image': 'assets/svip_exclusive_image/svipLodo.png', 'text': 'Anti-block'},
    {'image': 'assets/svip_exclusive_image/svipeye.png', 'text': 'Invisible'},
    {'image': 'assets/svip_exclusive_image/svip gift1.png', 'text': 'Vip Gift'},
    {
      'image': 'assets/svip_exclusive_image/svipimaogi.png',
      'text': 'Vip emoji '
    },
    {
      'image': 'assets/svip_exclusive_image/SvipProfileBg.png',
      'text': 'GIF Profile Pic'
    },
    {
      'image': 'assets/svip_exclusive_image/SvipProfileBg.png',
      'text': 'VIP Set'
    },
    {
      'image': 'assets/svip_exclusive_image/SvipProfileBg.png',
      'text': 'Entry Banner'
    },
  ];
  //------------svip tabbar -----------------------------------

  var selectedTab = 0.obs;

  void changeTab(int index) {
    selectedTab.value = index;
  }

  //----------------------------bottom show hide ---------------------
  final scrollController = ScrollController();
  final showBottomCard = true.obs;
  double lastOffset = 0.0;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final currentOffset = scrollController.offset;

    if (currentOffset > lastOffset && currentOffset - lastOffset > 5) {
      // Scrolling down
      showBottomCard.value = false;
    } else if (currentOffset < lastOffset && lastOffset - currentOffset > 5) {
      // Scrolling up
      showBottomCard.value = true;
    }

    lastOffset = currentOffset;
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
