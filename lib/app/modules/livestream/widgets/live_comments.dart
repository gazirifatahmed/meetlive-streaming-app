import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../controllers/websocket_controller.dart';
import 'entrySecound.dart';

class LiveCommentsSection extends StatefulWidget {
  final RxMap broadcasterData;
  final String? streamType;

  const LiveCommentsSection({
    super.key,
    required this.broadcasterData,
    this.streamType,
  });

  @override
  State<LiveCommentsSection> createState() => _LiveCommentsSectionState();
}

class _LiveCommentsSectionState extends State<LiveCommentsSection> {
  final WebsocketController websocketController = Get.find();
  final ScrollController _scrollController = ScrollController();

  /// 0 = All, 1 = Message, 2 = Gift
  final RxInt selectedTab = 0.obs;
  final List<Worker> _workers = <Worker>[];

  final String welcomeText =
      'Welcome to TaDo Live.. pornographic, minor, vulgar, violent and other illegal content is strictly prohibited in live broadcast room. We maintain 24 hour supervision and if any violation occurs the account will be banned immediately';

  int get _currentStreamId {
    final value = websocketController.streamID.value;
    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _ensureWelcomeForCurrentStream();

    _workers.add(ever(websocketController.commentsList, (_) => _scrollToBottom()));
    _workers.add(ever(websocketController.giftMessagesList, (_) => _scrollToBottom()));
    _workers.add(ever(websocketController.streamID, (_) {
      _ensureWelcomeForCurrentStream();
      _scrollToBottom();
    }));
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureWelcomeForCurrentStream() {
    final sid = _currentStreamId;
    if (sid == 0) return;

    final key = 'welcome_$sid';
    final hasWelcome = websocketController.commentsList.any((item) {
      if (item is! Map) return false;
      return item['comment_key'] == key ||
          (item['comment'] == welcomeText &&
              item['livestream_id']?.toString() == sid.toString());
    });

    if (!hasWelcome) {
      websocketController.commentsList.add({
        'type': 'system',
        'system_type': 'welcome',
        'comment_key': key,
        'livestream_id': sid,
        'user': {
          'id': 0,
          'name': 'System',
          'level': 0,
          'profile_image': null,
          'is_online': true,
        },
        'comment': welcomeText,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 160), () {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _safeText(dynamic value) => value?.toString().trim() ?? '';

  bool get _isPkRunningForComments {
    try {
      final int currentPkId = _toInt(livestreamController.currentPkId.value);
      final int pkSenderStreamId =
      _toInt(livestreamController.pkSenderLivestreamId.value);
      final int pkReceiverStreamId =
      _toInt(livestreamController.pkReceiverLivestreamId.value);

      return livestreamController.pkModeActive.value == true ||
          currentPkId > 0 ||
          pkSenderStreamId > 0 ||
          pkReceiverStreamId > 0;
    } catch (_) {
      return false;
    }
  }

  int get _currentPkIdForComments {
    try {
      return _toInt(livestreamController.currentPkId.value);
    } catch (_) {
      return 0;
    }
  }

  Set<int> get _pkStreamIdsForComments {
    final ids = <int>{};

    try {
      final int current = _toInt(livestreamController.streamId.value);
      final int sender = _toInt(livestreamController.pkSenderLivestreamId.value);
      final int receiver =
      _toInt(livestreamController.pkReceiverLivestreamId.value);

      if (current > 0) ids.add(current);
      if (sender > 0) ids.add(sender);
      if (receiver > 0) ids.add(receiver);
    } catch (_) {}

    final int wsStream = _currentStreamId;
    if (wsStream > 0) ids.add(wsStream);

    return ids;
  }

  Set<int> _itemStreamIds(Map item) {
    final ids = <int>{};

    for (final key in [
      'livestream_id',
      'stream_id',
      'live_stream_id',
      'room_id',
      'sender_livestream_id',
      'receiver_livestream_id',
      'opponent_livestream_id',
    ]) {
      final id = _toInt(item[key]);
      if (id > 0) ids.add(id);
    }

    return ids;
  }

  bool _isForCurrentStream(Map item) {
    if (item['comment'] == welcomeText && item['comment_key'] == null) {
      /// Old welcome message from previous version had livestream_id 100.
      /// Do not show it in new rooms, otherwise old audio comments mix in video.
      return false;
    }

    final sid = _currentStreamId;
    final itemStreamId = item['livestream_id'] ??
        item['stream_id'] ??
        item['live_stream_id'] ??
        item['room_id'];

    /// Only current welcome can pass without stream id.
    if (itemStreamId == null) {
      return item['comment_key'] == 'welcome_$sid';
    }

    final int eventStreamId = _toInt(itemStreamId);

    /// Normal live: only current stream will show.
    if (sid > 0 && eventStreamId == sid) {
      return true;
    }

    /// PK live: both livestream rooms must show in the same comment box.
    final bool pkRunning = _isPkRunningForComments;
    if (!pkRunning) {
      return sid == 0;
    }

    final pkStreams = _pkStreamIdsForComments;
    final itemStreams = _itemStreamIds(item);

    if (itemStreams.any(pkStreams.contains)) {
      return true;
    }

    /// If backend sends pk_id but not both stream ids, still allow the current PK.
    final int itemPkId = _toInt(item['pk_id']);
    final int currentPkId = _currentPkIdForComments;
    if (itemPkId > 0 && currentPkId > 0 && itemPkId == currentPkId) {
      return true;
    }

    return false;
  }

  bool _isJoinLeft(Map item) {
    final comment = _safeText(item['comment']);
    final systemType = _safeText(item['system_type']).toLowerCase();
    return comment == 'has joined the stream' ||
        comment == 'left the room' ||
        systemType == 'viewer_join' ||
        systemType == 'viewer_left';
  }

  bool _isValidUser(dynamic user) {
    if (user is! Map) return false;
    final name = _safeText(user['name']);
    return name.isNotEmpty && name.toLowerCase() != 'null';
  }

  bool _isGift(Map item) {
    return item['type'] == 'gift' || item['gift'] != null;
  }

  bool _isRealMessage(Map item) {
    if (_isGift(item)) return false;
    if (_isJoinLeft(item)) return false;
    if (item['comment'] == welcomeText) return false;
    final comment = _safeText(item['comment']);
    return comment.isNotEmpty;
  }

  DateTime _timeOf(Map item) {
    return DateTime.tryParse(item['timestamp']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _dedupeKey(Map<String, dynamic> item) {
    final type = _safeText(item['type']);
    final systemType = _safeText(item['system_type']);
    final user = _asMap(item['user'] ?? item['sender']);
    final gift = _asMap(item['gift']);
    final receiver = _asMap(item['receiver']);
    final userId = _safeText(user['id'] ?? user['user_id']);
    final comment = _safeText(item['comment']);
    final eventId = _safeText(item['event_id'] ?? item['id'] ?? item['comment_key']);
    final stream = _safeText(item['livestream_id'] ?? item['stream_id']);

    if (eventId.isNotEmpty) return '$stream|$type|$systemType|$eventId';

    if (_isGift(item)) {
      return '$stream|gift|$userId|${receiver['id']}|${gift['id']}|${item['timestamp']}';
    }

    if (_isJoinLeft(item)) {
      /// Same user can join -> leave -> join again.
      /// Timestamp keeps the second join visible instead of treating it as duplicate.
      final ts = _safeText(item['timestamp']);
      return '$stream|join_left|$systemType|$comment|$userId|$ts';
    }

    return '$stream|msg|$userId|$comment|${item['timestamp']}';
  }

  List<Map<String, dynamic>> _dedupe(List<Map<String, dynamic>> input) {
    final seen = <String>{};
    final output = <Map<String, dynamic>>[];

    for (final item in input) {
      final key = _dedupeKey(item);
      if (seen.contains(key)) continue;
      seen.add(key);
      output.add(item);
    }

    return output;
  }

  List<Map<String, dynamic>> _itemsForTab() {
    final currentUserId = authController.userProfile.value.user?.id?.toString();

    final comments = websocketController.commentsList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where(_isForCurrentStream)
        .where((item) {
      final user = item['user'];
      final itemUserId = user is Map ? user['id']?.toString() : null;

      /// Nijer join/left nijer comment section-e show korbe na.
      if (_isJoinLeft(item) && itemUserId != null && itemUserId == currentUserId) {
        return false;
      }

      if (_isJoinLeft(item) && !_isValidUser(item['user'])) return false;
      return true;
    }).toList();

    final gifts = websocketController.giftMessagesList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where(_isForCurrentStream)
        .toList();

    if (selectedTab.value == 1) {
      return _dedupe(comments.where(_isRealMessage).toList());
    }

    if (selectedTab.value == 2) {
      return _dedupe(gifts)..sort((a, b) => _timeOf(a).compareTo(_timeOf(b)));
    }

    final all = _dedupe(<Map<String, dynamic>>[
      ...comments,
      ...gifts,
    ]);

    all.sort((a, b) => _timeOf(a).compareTo(_timeOf(b)));
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          livestreamController.isBroadcaster.value
              ? SizedBox(height: kHeight * 0.137)
              : SizedBox(height: kHeight * 0.1),
          _tabHeader(),
          SizedBox(height: kHeight * 0.006),
          Expanded(
            child: Obx(() {
              /// Watch stream id + PK state reactively so room/PK change filters immediately.
              websocketController.streamID.value;
              livestreamController.currentPkId.value;
              livestreamController.pkSenderLivestreamId.value;
              livestreamController.pkReceiverLivestreamId.value;
              livestreamController.pkModeActive.value;
              final items = _itemsForTab();

              if (items.isEmpty) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: kWeight * .02, top: 8),
                    child: Text(
                      selectedTab.value == 2
                          ? 'No gifts yet'
                          : selectedTab.value == 1
                          ? 'No messages yet'
                          : 'No activity yet',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: kHeight * .012,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.zero,
                controller: _scrollController,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  if (_isGift(item)) {
                    return _giftItem(item);
                  }

                  if (_isJoinLeft(item)) {
                    return _joinLeftItem(item);
                  }

                  if (item['comment'] == welcomeText) {
                    return _welcomeItem(item);
                  }

                  return _messageItem(item);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _tabHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Obx(
            () => Padding(
          padding: EdgeInsets.only(left: kWeight * 0.02),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tabButton('All', 0),
              SizedBox(width: kWeight * .035),
              _tabButton('Message', 1),
              SizedBox(width: kWeight * .035),
              _tabButton('Gift', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final active = selectedTab.value == index;

    return GestureDetector(
      onTap: () {
        selectedTab.value = index;
        _scrollToBottom();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              color: active ? Colors.white : Colors.white70,
              fontSize: kHeight * .015,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            width: active ? kWeight * .045 : 0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _joinLeftItem(Map<String, dynamic> item) {
    final user = _asMap(item['user']);
    if (!_isValidUser(user)) return const SizedBox.shrink();

    final comment = _safeText(item['comment']);
    final systemType = _safeText(item['system_type']).toLowerCase();
    final isLeft = comment == 'left the room' || systemType == 'viewer_left';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: UserJoinAnimation(
        imageUrl: ImageHelper.getImageUrl(user['profile_image'] ?? ''),
        userName: '${user['name']} ${isLeft ? 'left the room' : 'has joined'}',
        userLv: '${user['level'] ?? 0}',
        imageFrame: user['asset_purchase_history'],
        userLvFrame: user['level_image'] ?? 'assets/svga/Level/level_0_to_9_bg.svga',
      ),
    );
  }

  Widget _welcomeItem(Map<String, dynamic> item) {
    if (widget.broadcasterData['user']?['id'] ==
        authController.userProfile.value.user!.id) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: FadeIn(
        duration: const Duration(milliseconds: 350),
        child: Container(
          constraints: BoxConstraints(maxWidth: kWeight * .62),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: kAppColor, width: 1.4),
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withValues(alpha: .35),
          ),
          child: Text(
            item['comment'] ?? '',
            style: GoogleFonts.roboto(
              fontSize: kHeight * .011,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageItem(Map<String, dynamic> item) {
    final user = _asMap(item['user']);

    if (!_isValidUser(user)) return const SizedBox.shrink();

    final comment = _safeText(item['comment']);
    if (comment.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: kWeight * .68,
          minWidth: kWeight * .42,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7, right: 6),
          child: FadeIn(
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .55),
                  width: .75,
                ),
                color: Colors.black.withValues(alpha: .18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(user, size: kHeight * .038),
                  SizedBox(width: kWeight * .018),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _nameLevelRow(user),
                        const SizedBox(height: 4),
                        Text(
                          comment,
                          style: GoogleFonts.roboto(
                            fontSize: kHeight * .0114,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
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

  Widget _giftItem(Map<String, dynamic> item) {
    final sender = item['sender'] is Map
        ? _asMap(item['sender'])
        : item['user'] is Map
        ? _asMap(item['user'])
        : <String, dynamic>{};

    final receiver = _asMap(item['receiver']);
    final gift = _asMap(item['gift']);

    if (!_isValidUser(sender)) return const SizedBox.shrink();

    final giftName = (gift['name'] ?? 'Gift').toString();
    final receiverName = (receiver['name'] ?? 'User').toString();

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: kWeight * .68,
          minWidth: kWeight * .42,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7, right: 6),
          child: FadeIn(
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: .85),
                  width: .85,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: .22),
                    Colors.deepPurple.withValues(alpha: .22),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(sender, size: kHeight * .038),
                  SizedBox(width: kWeight * .018),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _nameLevelRow(sender),
                        const SizedBox(height: 4),
                        Text(
                          'sent $giftName to $receiverName',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: kHeight * .0114,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: kWeight * .01),
                  _giftIcon(gift),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(Map<String, dynamic> user, {required double size}) {
    final img = user['profile_image'];

    return ClipOval(
      child: img == null || img.toString().isEmpty || img.toString() == 'null'
          ? Image.asset(
        'assets/images/support_user.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      )
          : CachedNetworkImage(
        imageUrl: ImageHelper.getImageUrl(img.toString()),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => Image.asset(
          'assets/images/support_user.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _nameLevelRow(Map<String, dynamic> user) {
    final name = (user['name'] ?? 'User').toString();
    final level = (user['level'] ?? 0).toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: kHeight * .0125,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: kWeight * .012),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xff4C3CFF).withValues(alpha: .75),
          ),
          child: Text(
            'Lv $level',
            style: GoogleFonts.roboto(
              fontSize: kHeight * .0095,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _giftIcon(Map<String, dynamic> gift) {
    final raw = gift['show_image'] ??
        gift['image'] ??
        gift['gift_image'] ??
        gift['icon'] ??
        gift['svga'] ??
        gift['gift_svga'];

    if (raw == null || raw.toString().isEmpty || raw.toString() == 'null') {
      return Icon(
        Icons.card_giftcard,
        color: Colors.amber,
        size: kHeight * .028,
      );
    }

    final url = ImageHelper.getImageUrl(raw.toString());

    return CachedNetworkImage(
      imageUrl: url,
      height: kHeight * .032,
      width: kHeight * .032,
      fit: BoxFit.contain,
      errorWidget: (_, _, _) => Icon(
        Icons.card_giftcard,
        color: Colors.amber,
        size: kHeight * .028,
      ),
    );
  }
}
