import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/image_helper.dart';
import '../../../../widgets/message_bottom.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/livestream_controller.dart';
import '../controllers/websocket_controller.dart';

class gift_bottom_sheet extends StatefulWidget {
  final dynamic isbrodcaster;
  final String liveType;

  const gift_bottom_sheet({
    super.key,
    required this.isbrodcaster,
    required this.liveType,
  });

  @override
  State<gift_bottom_sheet> createState() => _gift_bottom_sheetState();
}

class _gift_bottom_sheetState extends State<gift_bottom_sheet> {
  final LivestreamController livestreamController = Get.find();
  final WebsocketController websocketController = Get.find();
  final AuthController authController = Get.find();

  final RxList<int> selectedLocalReceiverIds = <int>[].obs;
  final Rxn<Map<String, dynamic>> selectedGift = Rxn<Map<String, dynamic>>();

  bool get isSmallScreen => Get.width < 370;
  bool get isTinyScreen => Get.width < 340;

  double get sheetHeight {
    if (Get.height < 680) return Get.height * .64;
    if (Get.height < 760) return Get.height * .60;
    return Get.height * .56;
  }

  double get avatarSize => isSmallScreen ? 38 : 42;
  double get avatarBoxWidth => isSmallScreen ? 47 : 52;
  double get tabFontSize => isSmallScreen ? 11 : 12;
  double get giftNameFontSize => isSmallScreen ? 9 : 10;
  double get coinFontSize => isSmallScreen ? 9 : 10;
  double get giftImageSize => isSmallScreen ? 28 : 32;

  @override
  void initState() {
    super.initState();

    if (livestreamController.giftList.isEmpty) {
      livestreamController.fetchGiftList();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDefaultReceiver();
      livestreamController.selectedGiftCategoryIndex.value = -1;
    });
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _hostUser() {
    final map = _asMap(widget.isbrodcaster);

    if (map['user'] is Map) {
      return _asMap(map['user']);
    }

    return map;
  }

  String _safeImage(dynamic value) {
    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty || raw == 'null' || raw == 'file:///') return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    return ImageHelper.getImageUrl(raw);
  }

  bool _isSvga(dynamic value) {
    return value?.toString().toLowerCase().endsWith('.svga') == true;
  }

  String _giftImage(Map<String, dynamic> gift) {
    return _safeImage(
      gift['show_image'] ??
          gift['gift_image'] ??
          gift['image'] ??
          gift['icon'] ??
          gift['thumbnail'],
    );
  }

  String _categoryName(Map<String, dynamic> gift) {
    return (gift['category'] ??
        gift['gift_category'] ??
        gift['type'] ??
        gift['gift_type'] ??
        'Gifts')
        .toString()
        .trim();
  }

  String _prettyCategory(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('robot')) return 'Robot';
    if (lower.contains('vip')) return 'VIP';
    if (lower.contains('animal')) return 'Animal';
    if (lower.contains('face')) return 'Face';
    if (lower.contains('love')) return 'Love';
    if (lower.contains('funny')) return 'Funny';
    if (lower.contains('lucky')) return 'Lucky';
    if (lower.contains('custom')) return 'Custom';
    if (lower.contains('country')) return 'Country';
    if (lower.contains('cp')) return 'CP';
    if (lower.contains('gift')) return 'Gifts';

    return name.isEmpty ? 'Gifts' : name;
  }

  List<String> _giftCategories() {
    final set = <String>{};

    for (final item in livestreamController.giftList) {
      final gift = Map<String, dynamic>.from(item);
      final category = _prettyCategory(_categoryName(gift));

      if (category.isNotEmpty) {
        set.add(category);
      }
    }

    final list = set.toList();

    final order = [
      'Gifts',
      'Robot',
      'VIP',
      'Animal',
      'Face',
      'Love',
      'Funny',
      'Lucky',
      'Custom',
      'CP',
      'Country',
    ];

    list.sort((a, b) {
      final ai = order.indexOf(a);
      final bi = order.indexOf(b);

      if (ai != -1 && bi != -1) return ai.compareTo(bi);
      if (ai != -1) return -1;
      if (bi != -1) return 1;

      return a.compareTo(b);
    });

    return list;
  }

  List<Map<String, dynamic>> _allGiftList() {
    return livestreamController.giftList
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _giftListBySelectedCategory() {
    final selectedIndex = livestreamController.selectedGiftCategoryIndex.value;

    if (selectedIndex == -1) {
      return _allGiftList();
    }

    final categories = _giftCategories();

    if (categories.isEmpty) {
      return _allGiftList();
    }

    final safeIndex = selectedIndex < 0
        ? 0
        : selectedIndex >= categories.length
        ? categories.length - 1
        : selectedIndex;

    final selectedCategory = categories[safeIndex].toLowerCase();

    return livestreamController.giftList
        .map((e) => Map<String, dynamic>.from(e))
        .where(
          (gift) =>
      _prettyCategory(_categoryName(gift)).toLowerCase() ==
          selectedCategory,
    )
        .toList();
  }

  List<Map<String, dynamic>> _receiverList() {
    final receivers = <Map<String, dynamic>>[];
    final added = <String>{};

    void addUser(Map<String, dynamic> user, {dynamic seatNo}) {
      final id = int.tryParse('${user['id'] ?? 0}') ?? 0;

      if (id == 0) return;
      if (added.contains(id.toString())) return;

      added.add(id.toString());

      receivers.add({
        ...user,
        'id': id,
        'seat_no': seatNo,
      });
    }

    final host = _hostUser();
    addUser(host, seatNo: host['seat_no'] ?? 1);

    for (final item in websocketController.liveCallList) {
      if (item is! Map) continue;

      final call = Map<String, dynamic>.from(item);

      final user = call['user'] is Map
          ? Map<String, dynamic>.from(call['user'])
          : <String, dynamic>{
        'id': call['caller_id'] ?? call['user_id'] ?? call['id'],
        'name': call['caller_name'] ?? call['name'] ?? 'User',
        'profile_image': call['profile_image'],
      };

      addUser(user, seatNo: call['seat_no']);
    }

    final me = authController.userProfile.value.user;

    if (me != null) {
      addUser({
        'id': me.id,
        'name': me.name,
        'profile_image': me.profileImage,
        'level': me.level,
      }, seatNo: null);
    }

    return receivers;
  }

  List<int> _allReceiverIds(List<Map<String, dynamic>> receivers) {
    return receivers
        .map((e) => int.tryParse('${e['id'] ?? 0}') ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  String _formatCoins(dynamic value) {
    final num coin = num.tryParse(value?.toString() ?? '0') ?? 0;

    if (coin >= 1000000) {
      final v = coin / 1000000;
      return v % 1 == 0 ? '${v.toInt()}m' : '${v.toStringAsFixed(1)}m';
    }

    if (coin >= 1000) {
      final v = coin / 1000;
      return v % 1 == 0 ? '${v.toInt()}k' : '${v.toStringAsFixed(1)}k';
    }

    return coin.toInt().toString();
  }

  Future<void> _sendSelectedGift() async {
    final gift = selectedGift.value;

    if (gift == null) {
      Fluttertoast.showToast(msg: 'Please select gift');
      return;
    }

    final giftId = int.tryParse('${gift['id'] ?? 0}') ?? 0;
    final giftPrice = int.tryParse('${gift['coin'] ?? gift['price'] ?? 0}') ?? 0;

    if (giftId == 0) {
      Fluttertoast.showToast(msg: 'Gift not found');
      return;
    }

    if (selectedLocalReceiverIds.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select receiver');
      return;
    }

    final me = authController.userProfile.value.user;
    final myCoins = int.tryParse(me?.coins.toString() ?? '0') ?? 0;

    // Invalid/insufficient cases e bottom sheet close korbo na.
    if (giftPrice > 0 && myCoins < giftPrice) {
      Fluttertoast.showToast(
        msg: 'Insufficient balance. Please recharge!',
        backgroundColor: Colors.white,
        textColor: Colors.red,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final receivers = selectedLocalReceiverIds.toList(growable: false);
    final optimisticGift = Map<String, dynamic>.from(gift);
    final optimisticEvent = _buildOptimisticGiftEvent(
      gift: optimisticGift,
      receiverId: receivers.first,
    );

    livestreamController.selectedReceiverIds
      ..clear()
      ..addAll(receivers);

    // ✅ Professional send UX: no loading, close instantly.
    selectedGift.value = null;
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    // ✅ If backend websocket echo is delayed/missed for sender, show a safe local fallback.
    // If websocket gift already starts showing within 650ms, fallback will not run.
    Timer(const Duration(milliseconds: 650), () {
      final alreadyShowing = websocketController.isGiftAnimationShowing.value;
      final hasRecentSameGift = websocketController.giftMessagesList.any((item) {
        if (item is! Map) return false;
        final senderId = item['sender'] is Map
            ? item['sender']['id']?.toString()
            : item['sender_id']?.toString();
        final gift = item['gift'];
        final gid = gift is Map ? gift['id']?.toString() : item['gift_id']?.toString();
        return senderId == (me?.id?.toString() ?? '') && gid == giftId.toString();
      });

      if (!alreadyShowing && !hasRecentSameGift) {
        websocketController.showGiftAnimation(optimisticEvent);
      }
    });

    // ✅ API call background e cholbe. Button/sheet loading hobe na.
    () async {
      final result = await livestreamController.tryToSendGift(
        receiverId: receivers.first,
        giftId: giftId,
        giftPrice: giftPrice,
      );

      if (result == null) {
        // Backend fail hole user ke janabo, but UI block korbo na.
        return;
      }
    }();
  }

  Map<String, dynamic> _buildOptimisticGiftEvent({
    required Map<String, dynamic> gift,
    required int receiverId,
  }) {
    final me = authController.userProfile.value.user;

    final receiver = _receiverList().firstWhere(
          (item) => item['id']?.toString() == receiverId.toString(),
      orElse: () => <String, dynamic>{'id': receiverId, 'name': 'User'},
    );

    return {
      'type': 'gift',
      'is_optimistic': true,
      'event_id':
      'local_${DateTime.now().microsecondsSinceEpoch}_${me?.id}_${gift['id']}_$receiverId',
      'livestream_id': livestreamController.streamId.value,
      'stream_id': livestreamController.streamId.value,
      'sender': {
        'id': me?.id,
        'name': me?.name ?? 'Me',
        'profile_image': me?.profileImage,
        'level': me?.level,
      },
      'receiver': receiver,
      'gift': gift,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void _syncDefaultReceiver() {
    final receivers = _receiverList();
    final ids = _allReceiverIds(receivers);

    selectedLocalReceiverIds.removeWhere((id) => !ids.contains(id));

    if (selectedLocalReceiverIds.isEmpty && ids.isNotEmpty) {
      selectedLocalReceiverIds.add(ids.first);
    }

    livestreamController.selectedReceiverIds
      ..clear()
      ..addAll(selectedLocalReceiverIds);
  }

  Widget _avatar(Map<String, dynamic> user) {
    final id = int.tryParse('${user['id'] ?? 0}') ?? 0;
    final image = _safeImage(user['profile_image']);
    final seatNo = user['seat_no'];

    return Obx(() {
      final selected = selectedLocalReceiverIds.contains(id);

      return GestureDetector(
        onTap: () {
          if (id == 0) return;

          if (selected) {
            selectedLocalReceiverIds.remove(id);
          } else {
            selectedLocalReceiverIds.add(id);
          }

          livestreamController.selectedReceiverIds
            ..clear()
            ..addAll(selectedLocalReceiverIds);
        },
        child: SizedBox(
          width: avatarBoxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: avatarSize,
                width: avatarSize,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xff22e4c0)
                        : const Color(0xff22e4c0).withValues(alpha: .50),
                    width: selected ? 2.2 : 1.2,
                  ),
                ),
                child: ClipOval(
                  child: image.isEmpty
                      ? Container(
                    color: Colors.white12,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: isSmallScreen ? 17 : 19,
                    ),
                  )
                      : CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: Colors.white12,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: isSmallScreen ? 17 : 19,
                      ),
                    ),
                  ),
                ),
              ),

              if (selected)
                Positioned(
                  top: 2,
                  right: 3,
                  child: Container(
                    height: 15,
                    width: 15,
                    decoration: const BoxDecoration(
                      color: Color(0xff22e4c0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),

              if (seatNo != null)
                Positioned(
                  bottom: 0,
                  child: Container(
                    height: 18,
                    width: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xff28eec7),
                          Color(0xff10bfa5),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$seatNo',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _allReceiverButton(List<Map<String, dynamic>> receivers) {
    final ids = _allReceiverIds(receivers);

    return Obx(() {
      final selectedCount = selectedLocalReceiverIds.length;

      final allSelected = ids.isNotEmpty &&
          selectedCount == ids.length &&
          ids.every((id) => selectedLocalReceiverIds.contains(id));

      return GestureDetector(
        onTap: () {
          if (ids.isEmpty) return;

          if (allSelected) {
            selectedLocalReceiverIds.clear();
          } else {
            selectedLocalReceiverIds
              ..clear()
              ..addAll(ids);
          }

          livestreamController.selectedReceiverIds
            ..clear()
            ..addAll(selectedLocalReceiverIds);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: isSmallScreen ? 38 : 42,
          width: isSmallScreen ? 45 : 50,
          margin: EdgeInsets.only(
            left: isSmallScreen ? 4 : 6,
            right: isSmallScreen ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: allSelected
                ? const Color(0xff22e4c0)
                : Colors.white.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xff22e4c0).withValues(alpha: .55),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'All',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isSmallScreen ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _categoryTabs() {
    return Obx(() {
      final categories = _giftCategories();
      final selectedIndex = livestreamController.selectedGiftCategoryIndex.value;

      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: isSmallScreen ? 36 : 39,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final selected = selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      livestreamController.selectedGiftCategoryIndex.value =
                          index;
                      selectedGift.value = null;
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: isSmallScreen ? 13 : 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            categories[index],
                            style: GoogleFonts.poppins(
                              color: selected ? Colors.white : Colors.white60,
                              fontSize: tabFontSize,
                              fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 3,
                            width: selected ? 14 : 0,
                            decoration: BoxDecoration(
                              color: const Color(0xff22e4c0),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              livestreamController.selectedGiftCategoryIndex.value = -1;
              selectedGift.value = null;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: isSmallScreen ? 38 : 42,
              width: isSmallScreen ? 38 : 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectedIndex == -1
                    ? const Color(0xff22e4c0)
                    : Colors.white.withValues(alpha: .10),
                border: Border.all(
                  color: const Color(0xff22e4c0).withValues(alpha: .45),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'All',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 11.5 : 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _smallBadge({
    required IconData icon,
    required Color color,
    required double top,
    required double right,
  }) {
    return Positioned(
      top: top,
      right: right,
      child: Container(
        height: isSmallScreen ? 12 : 13,
        width: isSmallScreen ? 12 : 13,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .30),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isSmallScreen ? 7.5 : 8.5,
        ),
      ),
    );
  }

  Widget _giftCard(Map<String, dynamic> gift) {
    final giftId = int.tryParse('${gift['id'] ?? 0}') ?? 0;
    final image = _giftImage(gift);
    final name = (gift['name'] ?? 'Gift').toString();
    final coin = _formatCoins(gift['coin'] ?? gift['price'] ?? 0);

    final isLucky = _prettyCategory(_categoryName(gift))
        .toLowerCase()
        .contains('lucky') ||
        (gift['back_coin'] != null && gift['back_coin'].toString() != 'null');

    return Obx(() {
      final selectedId = int.tryParse('${selectedGift.value?['id'] ?? 0}') ?? 0;
      final selected = selectedId == giftId;

      return GestureDetector(
        onTap: () {
          selectedGift.value = gift;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: .04) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? const Color(0xff22e4c0) : Colors.transparent,
              width: selected ? 1.1 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 2 : 3,
                  isSmallScreen ? 4 : 5,
                  isSmallScreen ? 2 : 3,
                  isSmallScreen ? 3 : 4,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          height: giftImageSize,
                          width: giftImageSize,
                          child: image.isEmpty
                              ? Icon(
                            Icons.card_giftcard_rounded,
                            color: Colors.white,
                            size: giftImageSize,
                          )
                              : _isSvga(image)
                              ? SVGAEasyPlayer(
                            resUrl: image,
                            fit: BoxFit.contain,
                          )
                              : CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.contain,
                            errorWidget: (_, _, _) => Icon(
                              Icons.card_giftcard_rounded,
                              color: Colors.white,
                              size: giftImageSize,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: .72),
                        fontSize: giftNameFontSize,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/diamond-removebg-preview.png',
                          height: isSmallScreen ? 10 : 12,
                          width: isSmallScreen ? 10 : 12,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.monetization_on,
                            color: const Color(0xffffd447),
                            size: isSmallScreen ? 10 : 12,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            coin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: coinFontSize,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (isLucky)
                _smallBadge(
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xff8d55ff),
                  top: 4,
                  right: 3,
                ),

              if (gift['back_coin'] != null &&
                  gift['back_coin'].toString() != 'null')
                _smallBadge(
                  icon: Icons.local_offer_rounded,
                  color: const Color(0xff19d3af),
                  top: isSmallScreen ? 18 : 21,
                  right: 3,
                ),

            ],
          ),
        ),
      );
    });
  }

  Widget _bottomBar() {
    return Container(
      height: isSmallScreen ? 49 : 53,
      padding: EdgeInsets.only(
        left: isSmallScreen ? 8 : 10,
        right: isSmallScreen ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff0f1b19).withValues(alpha: .96),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: .06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/images/diamond-removebg-preview.png',
                  height: isSmallScreen ? 21 : 24,
                  width: isSmallScreen ? 21 : 24,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.monetization_on,
                    color: const Color(0xffffd447),
                    size: isSmallScreen ? 21 : 24,
                  ),
                ),

                const SizedBox(width: 5),

                Flexible(
                  child: Obx(() {
                    final coins =
                        authController.userProfile.value.user?.coins ?? 0;

                    return Text(
                      _formatCoins(coins),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 13.5 : 15,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  }),
                ),

                const SizedBox(width: 6),

                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      // Recharge page route থাকলে এখানে দিন
                      // Get.to(() => RechargeView());
                    },
                    child: Text(
                      'Recharge>',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xff22e4c0),
                        fontSize: isSmallScreen ? 12.5 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Obx(() {
            final gift = selectedGift.value;
            final giftId = int.tryParse('${gift?['id'] ?? 0}') ?? 0;

            return GestureDetector(
              onTap: _sendSelectedGift,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: isSmallScreen ? 38 : 42,
                width: isSmallScreen ? 88 : 104,
                decoration: BoxDecoration(
                  color: giftId == 0
                      ? const Color(0xff22d6b8).withValues(alpha: .65)
                      : const Color(0xff22d6b8),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    'Send',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openSheet() {
    _syncDefaultReceiver();

    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          height: sheetHeight,
          width: Get.width,
          decoration: BoxDecoration(
            color: const Color(0xff071816).withValues(alpha: .96),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(17),
            ),
          ),
          child: Obx(() {
            final gifts = _giftListBySelectedCategory();
            final receivers = _receiverList();

            if (livestreamController.giftList.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xff22e4c0),
                ),
              );
            }

            return Column(
              children: [
                SizedBox(height: isSmallScreen ? 7 : 9),

                SizedBox(
                  height: isSmallScreen ? 47 : 52,
                  child: Row(
                    children: [
                      Expanded(
                        child: receivers.isEmpty
                            ? Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No receiver',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                            : ListView.separated(
                          padding: EdgeInsets.only(
                            left: isSmallScreen ? 8 : 10,
                          ),
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: receivers.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(width: isSmallScreen ? 3 : 4),
                          itemBuilder: (_, index) =>
                              _avatar(receivers[index]),
                        ),
                      ),

                      _allReceiverButton(receivers),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                    left: isSmallScreen ? 9 : 10,
                    right: isSmallScreen ? 10 : 14,
                    top: isSmallScreen ? 0 : 1,
                  ),
                  child: _categoryTabs(),
                ),

                Expanded(
                  child: gifts.isEmpty
                      ? Center(
                    child: Text(
                      'No gift found',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      : GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 7 : 9,
                      isSmallScreen ? 4 : 6,
                      isSmallScreen ? 7 : 9,
                      isSmallScreen ? 5 : 7,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: gifts.length,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTinyScreen ? 4 : 5,
                      mainAxisSpacing: isSmallScreen ? 4 : 5,
                      crossAxisSpacing: isSmallScreen ? 4 : 5,
                      childAspectRatio: isSmallScreen ? .72 : .74,
                    ),
                    itemBuilder: (_, index) => _giftCard(gifts[index]),
                  ),
                ),

                _bottomBar(),
              ],
            );
          }),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return message_bottom(
      onPress: () async {
        if (livestreamController.giftList.isEmpty) {
          await livestreamController.fetchGiftList();
        }

        selectedGift.value = null;
        _syncDefaultReceiver();
        _openSheet();
      },
      color2: const Color(0xffff9c58),
      color: const Color(0xffff5d2e),
      image: 'assets/audio_live/gift.png',
    );
  }
}