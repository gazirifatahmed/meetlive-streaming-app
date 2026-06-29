import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:record/record.dart';

import 'package:video_player/video_player.dart';

import '../../../../constants/constants.dart';

import '../../../../constants/image_helper.dart';
import '../../../../constants/layout_constant.dart';
import '../controllers/messanger_controller.dart';
import 'chat_controller.dart';
import 'chat_model.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverImage;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final ChatController _chatController = Get.put(ChatController());
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late String _chatId;

  List<Message> _cachedMessages = [];
  bool _isFirstLoad = true;
  Message? _replyingToMessage;

  // Voice
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;
  Duration _playPosition = Duration.zero;

  // ✅ Emoji picker
  bool _showEmojiPicker = false;
  int _emojiTabIndex = 0;

  final List<String> _reactionEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

  // ✅ Emoji categories
  final List<Map<String, dynamic>> _emojiCategories = [
    {
      'icon': '😀',
      'label': 'Smileys',
      'emojis': [
        '😀',
        '😁',
        '😂',
        '🤣',
        '😃',
        '😄',
        '😅',
        '😆',
        '😉',
        '😊',
        '😋',
        '😎',
        '😍',
        '🥰',
        '😘',
        '😗',
        '😙',
        '😚',
        '🙂',
        '🤗',
        '🤩',
        '🤔',
        '🤨',
        '😐',
        '😑',
        '😶',
        '🙄',
        '😏',
        '😣',
        '😥',
        '😮',
        '🤐',
        '😯',
        '😪',
        '😫',
        '🥱',
        '😴',
        '😌',
        '😛',
        '😜',
        '😝',
        '🤤',
        '😒',
        '😓',
        '😔',
        '😕',
        '🙃',
        '🤑',
        '😲',
        '☹️',
        '🙁',
        '😖',
        '😞',
        '😟',
        '😤',
        '😢',
        '😭',
        '😦',
        '😧',
        '😨',
        '😩',
        '🤯',
        '😬',
        '😰',
        '😱',
        '🥵',
        '🥶',
        '😳',
        '🤪',
        '😵',
        '🥴',
        '😠',
        '😡',
        '🤬',
        '😷',
        '🤒',
        '🤕',
        '🤢',
        '🤮',
        '🤧',
        '😇',
        '🥳',
        '🥸',
        '🤠',
        '🥺',
        '🤡',
        '👹',
        '👺',
        '💀',
        '☠️',
        '👻',
        '👽',
        '👾',
        '🤖',
        '😺',
        '😸',
      ],
    },
    {
      'icon': '👋',
      'label': 'Gestures',
      'emojis': [
        '👋',
        '🤚',
        '🖐',
        '✋',
        '🖖',
        '👌',
        '🤌',
        '🤏',
        '✌️',
        '🤞',
        '🤟',
        '🤘',
        '🤙',
        '👈',
        '👉',
        '👆',
        '🖕',
        '👇',
        '☝️',
        '👍',
        '👎',
        '✊',
        '👊',
        '🤛',
        '🤜',
        '👏',
        '🙌',
        '👐',
        '🤲',
        '🤝',
        '🙏',
        '✍️',
        '💅',
        '🤳',
        '💪',
        '🦾',
        '🦿',
        '🦵',
        '🦶',
        '👂',
        '🦻',
        '👃',
        '🫀',
        '🫁',
        '🧠',
        '🦷',
        '🦴',
        '👀',
        '👁',
        '👅',
        '👄',
        '💋',
        '🩸',
        '👣',
        '👤',
        '👥',
        '🫂',
        '👫',
        '👬',
        '👭',
      ],
    },
    {
      'icon': '❤️',
      'label': 'Hearts',
      'emojis': [
        '❤️',
        '🧡',
        '💛',
        '💚',
        '💙',
        '💜',
        '🖤',
        '🤍',
        '🤎',
        '💔',
        '❣️',
        '💕',
        '💞',
        '💓',
        '💗',
        '💖',
        '💘',
        '💝',
        '💟',
        '♥️',
        '💌',
        '💒',
        '💍',
        '💎',
        '👑',
        '🏆',
        '🥇',
        '🎖',
        '🏅',
        '🎗',
        '🎀',
        '🎁',
        '🎊',
        '🎉',
        '🎈',
        '🎆',
        '🎇',
        '✨',
        '⭐',
        '🌟',
        '💫',
        '⚡',
        '🔥',
        '🌈',
        '☀️',
        '🌙',
        '⛅',
        '🌊',
      ],
    },
    {
      'icon': '🐶',
      'label': 'Animals',
      'emojis': [
        '🐶',
        '🐱',
        '🐭',
        '🐹',
        '🐰',
        '🦊',
        '🐻',
        '🐼',
        '🐨',
        '🐯',
        '🦁',
        '🐮',
        '🐷',
        '🐸',
        '🐵',
        '🐔',
        '🐧',
        '🐦',
        '🐤',
        '🦆',
        '🦅',
        '🦉',
        '🦇',
        '🐺',
        '🐗',
        '🐴',
        '🦄',
        '🐝',
        '🐛',
        '🦋',
        '🐌',
        '🐞',
        '🐜',
        '🦟',
        '🦗',
        '🕷',
        '🦂',
        '🐢',
        '🐍',
        '🦎',
        '🦖',
        '🦕',
        '🐙',
        '🦑',
        '🦐',
        '🦞',
        '🦀',
        '🐡',
        '🐠',
        '🐟',
        '🐬',
        '🐳',
        '🐋',
        '🦈',
        '🐊',
        '🐅',
        '🐆',
        '🦓',
        '🦍',
        '🦧',
      ],
    },
    {
      'icon': '🍎',
      'label': 'Food',
      'emojis': [
        '🍎',
        '🍐',
        '🍊',
        '🍋',
        '🍌',
        '🍉',
        '🍇',
        '🍓',
        '🫐',
        '🍈',
        '🍒',
        '🍑',
        '🥭',
        '🍍',
        '🥥',
        '🥝',
        '🍅',
        '🍆',
        '🥑',
        '🥦',
        '🥬',
        '🥒',
        '🌶',
        '🫑',
        '🌽',
        '🥕',
        '🧄',
        '🧅',
        '🥔',
        '🍠',
        '🥐',
        '🥯',
        '🍞',
        '🥖',
        '🥨',
        '🧀',
        '🥚',
        '🍳',
        '🧈',
        '🥞',
        '🧇',
        '🥓',
        '🥩',
        '🍗',
        '🍖',
        '🦴',
        '🌮',
        '🌯',
        '🫔',
        '🥙',
        '🧆',
        '🥚',
        '🍜',
        '🍝',
        '🍛',
        '🍲',
        '🫕',
        '🥘',
        '🍣',
        '🍱',
        '🍤',
        '🍙',
        '🍚',
        '🍘',
        '🍥',
        '🥮',
        '🍡',
        '🧁',
        '🍰',
        '🎂',
        '🍮',
        '🍭',
        '🍬',
        '🍫',
        '🍿',
        '🍩',
        '🍪',
        '🌰',
        '🥜',
        '🍯',
        '🧃',
        '🥤',
        '🧋',
        '☕',
        '🍵',
        '🧉',
        '🍶',
        '🍺',
        '🍻',
        '🥂',
        '🍷',
        '🥃',
        '🍸',
        '🍹',
        '🍾',
        '🎊',
      ],
    },
    {
      'icon': '⚽',
      'label': 'Activities',
      'emojis': [
        '⚽',
        '🏀',
        '🏈',
        '⚾',
        '🥎',
        '🎾',
        '🏐',
        '🏉',
        '🥏',
        '🎱',
        '🏓',
        '🏸',
        '🏒',
        '🏑',
        '🥍',
        '🏏',
        '🪃',
        '🥅',
        '⛳',
        '🪁',
        '🛝',
        '🏹',
        '🎣',
        '🤿',
        '🥊',
        '🥋',
        '🎽',
        '🛹',
        '🛼',
        '🛷',
        '⛸',
        '🥌',
        '🎿',
        '⛷',
        '🏂',
        '🪂',
        '🏋️',
        '🤼',
        '🤸',
        '🤺',
        '🏇',
        '⛹️',
        '🤾',
        '🏊',
        '🏄',
        '🚣',
        '🧘',
        '🚴',
        '🏆',
        '🥇',
        '🥈',
        '🥉',
        '🎖',
        '🎗',
        '🎫',
        '🎟',
        '🎪',
        '🎭',
        '🎨',
        '🎬',
        '🎤',
        '🎧',
        '🎼',
        '🎹',
        '🪘',
        '🥁',
        '🎷',
        '🎺',
        '🎸',
        '🪕',
        '🎻',
        '🎲',
      ],
    },
    {
      'icon': '🚗',
      'label': 'Travel',
      'emojis': [
        '🚗',
        '🚕',
        '🚙',
        '🚌',
        '🚎',
        '🚐',
        '🚑',
        '🚒',
        '🚓',
        '🚔',
        '🚖',
        '🚘',
        '🚍',
        '🚋',
        '🚂',
        '🚆',
        '🚇',
        '🚈',
        '🚊',
        '🚞',
        '🚝',
        '🚄',
        '🚅',
        '🚃',
        '🛻',
        '🚚',
        '🚛',
        '🚜',
        '🏎',
        '🏍',
        '🛵',
        '🦽',
        '🦼',
        '🛺',
        '🚲',
        '🛴',
        '🛹',
        '🛼',
        '🚏',
        '🛣',
        '🛤',
        '⛽',
        '🚨',
        '🚥',
        '🚦',
        '🛑',
        '🚧',
        '⚓',
        '🛟',
        '⛵',
        '🚤',
        '🛥',
        '🛳',
        '⛴',
        '🚢',
        '✈️',
        '🛩',
        '🛫',
        '🛬',
        '🪂',
        '💺',
        '🚁',
        '🚟',
        '🚠',
        '🚡',
        '🛰',
        '🚀',
        '🛸',
        '🪐',
        '🌍',
        '🌎',
        '🌏',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatId = _chatController.generateChatId(widget.receiverId);
    _chatController.markMessagesAsRead(_chatId);

    _chatController.getMessages(_chatId).listen((messages) {
      _chatController.markMessagesAsRead(_chatId);
      if (mounted) {
        final isNew = messages.length > _cachedMessages.length;
        setState(() => _cachedMessages = messages);
        if (_isFirstLoad || isNew) {
          _scrollToBottom();
          _isFirstLoad = false;
        }
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _playPosition = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
          _playPosition = Duration.zero;
        });
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✅ Emoji picker toggle
  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _showEmojiPicker = true);
        _scrollToBottom();
      });
    }
  }

  void _onEmojiSelected(String emoji) {
    final text = _messageController.text;
    final sel = _messageController.selection;
    final newText = text.replaceRange(
      sel.start < 0 ? text.length : sel.start,
      sel.end < 0 ? text.length : sel.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: (sel.start < 0 ? text.length : sel.start) + emoji.length),
    );
  }

  void _cancelReply() => setState(() => _replyingToMessage = null);

  // ─── Voice ────────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      if (!status.isGranted) {
        Get.snackbar('🎤 Permission', 'Microphone permission দিন',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(
            encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: _recordingPath!,
      );
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _isRecording) {
          setState(() => _recordingDuration += const Duration(seconds: 1));
        }
      });
    } catch (e) {
      debugPrint('❌ $e');
    }
  }

  Future<void> _stopAndSendVoice() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    final dur = _recordingDuration.inSeconds;
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
    if (path != null && File(path).existsSync() && dur >= 1) {
      await _chatController.sendVoiceMessage(
        chatId: _chatId,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        receiverImage: widget.receiverImage,
        voiceFile: File(path),
        voiceDuration: dur,
      );
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
    if (_recordingPath != null && File(_recordingPath!).existsSync()) {
      await File(_recordingPath!).delete();
    }
  }

  Future<void> _toggleVoicePlayback(String url) async {
    if (_currentlyPlayingUrl == url && _isPlaying) {
      await _audioPlayer.pause();
    } else if (_currentlyPlayingUrl == url && !_isPlaying) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingUrl = url;
        _playPosition = Duration.zero;
      });
      await _audioPlayer.play(UrlSource(url));
    }
  }

  String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtTime(DateTime t) => DateFormat('h:mm a').format(t);

  // ─── Long Press Options ───────────────────────────────────────────────────
  void _showMessageOptions(Message message) {
    final isMe = message.senderId == _chatController.currentUserId;
    HapticFeedback.mediumImpact();

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),

          // ✅ Reaction row
          if (!message.deletedForEveryone)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _reactionEmojis.map((emoji) {
                  final myReaction =
                      message.reactions[_chatController.currentUserId];
                  final isSelected = myReaction == emoji;
                  return GestureDetector(
                    onTap: () {
                      Get.back();
                      if (isSelected) {
                        _chatController.removeReaction(
                            chatId: _chatId, messageId: message.id);
                      } else {
                        _chatController.reactToMessage(
                            chatId: _chatId,
                            messageId: message.id,
                            emoji: emoji);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xff7c3df6).withValues(alpha: 0.12)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xff7c3df6), width: 2)
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 1, color: Color(0xfff0f0f0)),

          // Options
          if (!message.deletedForEveryone)
            _tile(Icons.reply_rounded, 'Reply', const Color(0xffade8f0), () {
              Get.back();
              setState(() => _replyingToMessage = message);
            }),

          if (!message.deletedForEveryone && message.message.isNotEmpty)
            _tile(Icons.copy_rounded, 'Copy', Colors.blueGrey, () {
              Get.back();
              Clipboard.setData(ClipboardData(text: message.message));
              Get.snackbar('✅', 'Copied!',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.black87,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(12),
                  borderRadius: 12);
            }),

          _tile(Icons.delete_outline_rounded, 'Delete for me', Colors.orange,
              () {
            Get.back();
            _confirmDelete(message, forEveryone: false);
          }),

          if (isMe && !message.deletedForEveryone)
            _tile(
                Icons.delete_forever_rounded, 'Delete for everyone', Colors.red,
                () {
              Get.back();
              _confirmDelete(message, forEveryone: true);
            }),

          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ]),
      ),
    );
  }

  void _confirmDelete(Message message, {required bool forEveryone}) {
    Get.dialog(AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(forEveryone ? 'Delete for everyone?' : 'Delete for me?',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
      content: Text(
        forEveryone
            ? 'This message will be deleted for everyone.'
            : 'This message will only be deleted for you.',
        style: TextStyle(color: Colors.grey[600]),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
        TextButton(
          onPressed: () {
            Get.back();
            forEveryone
                ? _chatController.deleteMessageForEveryone(
                    chatId: _chatId, messageId: message.id)
                : _chatController.deleteMessageForMe(
                    chatId: _chatId, messageId: message.id);
          },
          child: Text('Delete',
              style: TextStyle(
                  color: forEveryone ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    Get.put(MessangerController());
    return Scaffold(
      backgroundColor: const Color(0xfff8f6ff),
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ Color(0xffade8f0),
                Color(0xffcdaafc),],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(children: [
                InkWell(
                    onTap: () => Get.back(),
                    child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.arrow_back,
                            color: Colors.black, size: 25))),
                SizedBox(width: Get.width * 0.02),
                InkWell(
                  onTap: () {

                  },

                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(50)),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.receiverImage.isNotEmpty
                          ? NetworkImage(
                              ImageHelper.getImageUrl(widget.receiverImage))
                          : null,
                      child: widget.receiverImage.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: Get.width * 0.03),
                Text(widget.receiverName,
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: Get.height * 0.02)),
                const Spacer(),
                IconButton(
                  icon: Image.asset('assets/new/facetime-button.png',
                      height: Get.height * 0.03, color: Colors.white),
                  onPressed: () {
                    final data = {
                      'id': int.parse(widget.receiverId),
                      'peeredUserName': widget.receiverName,
                      'peeredUserImage': widget.receiverImage,
                    };
                    livestreamController.tryToMakeCall(
                      streamType: 'video',
                      userId:
                      authController.userProfile.value.user!.id!.toInt(),
                      receiverData: data,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.white, size: 30),
                  onPressed: () {
                    final data = {'id': int.parse(widget.receiverId)};
                    livestreamController.tryToMakeCall(
                      streamType: 'audio',
                      userId:
                      authController.userProfile.value.user!.id!.toInt(),
                      receiverData: data,
                    );
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
      body: Column(children: [
        // Upload progress
        Obx(() {
          final c = Get.find<MessangerController>();
          final p = c.uploadProgress.value;
          if (p > 0 && p < 100) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xff7c3df6).withValues(alpha: 0.07),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            c.isVoice.value
                                ? '🎤 Sending...'
                                : c.isVideo.value
                                    ? '🎥 Uploading...'
                                    : '📷 Uploading...',
                            style: const TextStyle(
                                color: Color(0xff7c3df6),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text('${p.toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Color(0xff7c3df6),
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                        value: p / 100,
                        minHeight: 5,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xff7c3df6))),
                  ),
                ]),
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // Messages
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _chatController.getMessages(_chatId),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? _cachedMessages;
              if (snapshot.connectionState == ConnectionState.waiting &&
                  messages.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xff7c3df6))));
              }
              if (messages.isEmpty) {
                return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text('No messages yet\nSay Hi! 👋',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 16)),
                    ]));
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                itemCount: messages.length,
                itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
              );
            },
          ),
        ),

        // ✅ Premium bottom area
        _buildBottomArea(),
      ]),
    );
  }

  // ─── Message Bubble ───────────────────────────────────────────────────────
  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId == _chatController.currentUserId;
    if (message.isDeletedFor(_chatController.currentUserId) &&
        !message.deletedForEveryone) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key(message.id),
      direction: message.deletedForEveryone
          ? DismissDirection.none
          : (isMe ? DismissDirection.endToStart : DismissDirection.startToEnd),
      confirmDismiss: (_) async {
        if (!message.deletedForEveryone) {
          setState(() => _replyingToMessage = message);
        }
        return false;
      },
      background: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xffade8f0).withValues(alpha: 0.15),
              shape: BoxShape.circle),
          child: const Icon(Icons.reply, color: Color(0xffade8f0), size: 22),
        ),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showMessageOptions(message),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Message bubble
                Container(
                  decoration: BoxDecoration(
                    gradient: isMe && !message.deletedForEveryone
                        ? const LinearGradient(
                            colors: [Color(0xffade8f0), Color(0xffcdaafc)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                        : null,
                    color: message.deletedForEveryone
                        ? Colors.grey[100]
                        : (isMe ? null : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildBubbleContent(message, isMe),
                ),

                // ✅ Reaction নিচে থাকবে
                if (message.hasReactions)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: _buildReactionDisplay(message, isMe),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Reaction নিচে - bubble এর বাইরে
  Widget _buildReactionDisplay(Message message, bool isMe) {
    final Map<String, int> counts = {};
    message.reactions.forEach((_, emoji) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ...counts.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                e.value > 1 ? '${e.key} ${e.value}' : e.key,
                style: const TextStyle(fontSize: 13,color: Colors.black),
              ),
            )),
      ]),
    );
  }

  Widget _buildBubbleContent(Message message, bool isMe) {
    if (message.deletedForEveryone) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.block, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Text(isMe ? 'You deleted this message' : 'This message was deleted',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontStyle: FontStyle.italic)),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (message.hasReply) _buildReplyPreview(message, isMe),
      if (message.hasImage) _buildImageMsg(message),
      if (message.hasVideo) _buildVideoMsg(message),
      if (message.hasVoice) _buildVoiceMsg(message, isMe),
      if (message.message.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message.message,
                style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isMe ? Colors.black : Colors.black87)),
            const SizedBox(height: 4),
            _buildTimeStatus(message, isMe),
          ]),
        ),
      if (message.message.isEmpty && message.hasMedia)
        Padding(
            padding: const EdgeInsets.all(8),
            child: _buildTimeStatus(message, isMe)),
    ]);
  }

  Widget _buildVoiceMsg(Message message, bool isMe) {
    final isPlaying = _currentlyPlayingUrl == message.voiceUrl;
    final dur = message.voiceDuration != null
        ? Duration(seconds: message.voiceDuration!)
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () => _toggleVoicePlayback(message.voiceUrl!),
          child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xff7c3df6),
                  shape: BoxShape.circle),
              child: Icon(
                  isPlaying && _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 22)),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
              children: List.generate(15, (i) {
            final heights = [
              10.0,
              16.0,
              8.0,
              20.0,
              12.0,
              18.0,
              8.0,
              14.0,
              20.0,
              10.0,
              16.0,
              8.0,
              18.0,
              12.0,
              20.0
            ];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              width: 3,
              height: heights[i],
              decoration: BoxDecoration(
                  color: isPlaying
                      ? (isMe ? Colors.white : const Color(0xff7c3df6))
                      : (isMe ? Colors.white54 : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(10)),
            );
          })),
          const SizedBox(height: 4),
          Row(children: [
            Text(isPlaying ? _fmtDur(_playPosition) : _fmtDur(dur),
                style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : Colors.grey[500])),
            const SizedBox(width: 8),
            _buildTimeStatus(message, isMe),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildReplyPreview(Message message, bool isMe) {
    final isMine = message.replyToSenderId == _chatController.currentUserId;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xfff0ebff),
        borderRadius: BorderRadius.circular(10),
        border: Border(
            left: BorderSide(
                color: isMe ? Colors.white : const Color(0xff7c3df6),
                width: 3)),
      ),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isMine ? 'You' : widget.receiverName,
              style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xff7c3df6),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 2),
          if (message.replyToImageUrl != null)
            _replyLabel(Icons.photo, 'Photo', isMe)
          else if (message.replyToVideoUrl != null)
            _replyLabel(Icons.videocam, 'Video', isMe)
          else if (message.replyToVoiceUrl != null)
            _replyLabel(Icons.mic, 'Voice', isMe)
          else
            Text(message.replyToMessage ?? '',
                style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ])),
        if (message.replyToImageUrl != null)
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(message.replyToImageUrl!,
                  width: 40, height: 40, fit: BoxFit.cover)),
      ]),
    );
  }

  Widget _replyLabel(IconData icon, String label, bool isMe) => Row(children: [
        Icon(icon, size: 12, color: isMe ? Colors.white70 : Colors.grey[500]),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[500], fontSize: 12)),
      ]);

  Widget _buildImageMsg(Message message) => GestureDetector(
        onTap: () => _openImageViewer(message.imageUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(children: [
            Image.network(message.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) {
                  if (p == null) return child;
                  return _shimmer(p.expectedTotalBytes != null
                      ? p.cumulativeBytesLoaded / p.expectedTotalBytes!
                      : null);
                },
                errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 50, color: Colors.grey)))),
            Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.zoom_out_map,
                        color: Colors.white, size: 16))),
          ]),
        ),
      );

  Widget _buildVideoMsg(Message message) => GestureDetector(
        onTap: () => _openVideoPlayer(message.videoUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(alignment: Alignment.center, children: [
            Container(
                height: 220,
                width: double.infinity,
                color: Colors.black87,
                child: Center(
                    child: Icon(Icons.play_circle_fill,
                        size: 70, color: Colors.white.withValues(alpha: 0.9)))),
            Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.videocam, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Video',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                )),
          ]),
        ),
      );

  Widget _buildTimeStatus(Message message, bool isMe) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_fmtTime(message.timestamp),
            style: TextStyle(
                fontSize: 11, color: isMe ? Colors.black54 : Colors.grey[500])),
        if (isMe) ...[
          const SizedBox(width: 3),
          Icon(message.read ? Icons.done_all : Icons.done,
              size: 15,
              color: message.read ? Colors.blue[200] : Colors.white60),
        ],
      ]);

  Widget _shimmer(double? progress) => Container(
        height: 220,
        width: double.infinity,
        color: Colors.grey[100],
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation(Color(0xff7c3df6))),
          if (progress != null) ...[
            const SizedBox(height: 8),
            Text('${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Color(0xff7c3df6), fontWeight: FontWeight.bold)),
          ],
        ]),
      );

  void _openImageViewer(String url) => Get.dialog(
        Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Stack(children: [
              PhotoView(
                  imageProvider: NetworkImage(url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.black)),
              Positioned(
                  top: 40,
                  right: 16,
                  child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 24)))),
            ])),
        barrierColor: Colors.black87,
      );

  void _openVideoPlayer(String url) =>
      Get.dialog(VideoPlayerDialog(videoUrl: url),
          barrierColor: Colors.black87);

  // ─── ✅ PREMIUM BOTTOM AREA ────────────────────────────────────────────────
  Widget _buildBottomArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Reply bar
        if (_replyingToMessage != null) _buildReplyBar(),

        // Recording bar
        if (_isRecording) _buildRecordingBar(),

        // ✅ Premium input
        if (!_isRecording)
          Padding(
            padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Emoji button
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopAndSendVoice(),
                    child: Image.asset(
                      'assets/audio_live/unMute.png',
                      height: kHeight * 0.04,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: kWeight * 0.02),
                  // ✅ Text field
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(maxHeight: kHeight * 0.05),
                      decoration: BoxDecoration(
                        color: const Color(0xfff7f5ff),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: const Color(0xffe8e0ff), width: 1.5),
                      ),
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _messageController,
                        style: GoogleFonts.lato(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                        cursorColor: const Color(0xff7c3df6),
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                          Future.delayed(const Duration(milliseconds: 300),
                              _scrollToBottom);
                        },
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: GoogleFonts.lato(
                              color: Colors.grey[400], fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: kWeight * 0.04,
                              vertical: kHeight * 0.0123),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: kWeight * 0.02),

                  // ✅ Right side actions
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    // Plus
                    GestureDetector(
                      onTap: _toggleEmojiPicker,
                      child: Image.asset('assets/new/happy (1).png',
                          height: kHeight * 0.03),
                    ),
                    SizedBox(width: kWeight * 0.02),

                    GestureDetector(
                      onTap: _showPlusOptions,
                      child: Image.asset(
                        'assets/new/image-gallery (1).png',
                        height: kHeight * 0.034,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: kWeight * 0.02),
                    // // Gift
                    // GestureDetector(
                    //   onTap: _showGiftSheet,
                    //   child: Container(
                    //     width: 40,
                    //     height: 40,
                    //     decoration: BoxDecoration(
                    //         color: const Color(0xfffff0f5),
                    //         borderRadius: BorderRadius.circular(12)),
                    //     child: Center(
                    //         child: Image.asset('assets/audio_live/gift-box.png',
                    //             height: 22)),
                    //   ),
                    // ),
                    // const SizedBox(width: 6),

                    // Mic

                    // Send
                    Obx(() {
                      final sending = _chatController.isSending.value;

                      return GestureDetector(
                        onTap: sending ? null : _sendMessage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: sending ? 44 : 44,
                          height: kHeight * 0.05,
                          decoration: BoxDecoration(
                            color: sending ? Colors.deepPurple : null,
                            gradient: sending
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xffade8f0),
                                      Color(0xffcdaafc),
                                      ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(
                              sending ? 22 : 14, // 👈 গোল হবে
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xff7c3df6).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: sending
                                  ? SizedBox(
                                      key: ValueKey('loader'),
                                      width: 22,
                                      height: 22,
                                      child: SpinKitFadingCircle(
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      key: ValueKey('send'),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      );
                    })
                  ]),
                ]),
          ),

        // ✅ Premium Emoji Picker
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child:
              _showEmojiPicker ? _buildEmojiPicker() : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _buildReplyBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xfff7f5ff),
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Row(children: [
          Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xff7c3df6),
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  _replyingToMessage!.senderId == _chatController.currentUserId
                      ? 'You'
                      : widget.receiverName,
                  style: const TextStyle(
                      color: Color(0xff7c3df6),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingToMessage!.hasImage
                      ? '📷 Photo'
                      : _replyingToMessage!.hasVideo
                          ? '🎥 Video'
                          : _replyingToMessage!.hasVoice
                              ? '🎤 Voice'
                              : _replyingToMessage!.message,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ])),
          if (_replyingToMessage!.hasImage)
            ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(_replyingToMessage!.imageUrl!,
                    width: 36, height: 36, fit: BoxFit.cover)),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: _cancelReply,
              child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.grey[200], shape: BoxShape.circle),
                  child:
                      const Icon(Icons.close, size: 16, color: Colors.grey))),
        ]),
      );

  Widget _buildRecordingBar() => SafeArea(
    child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[100]!, width: 1)),
          ),
          child: Row(children: [
            GestureDetector(
                onTap: _cancelRecording,
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.red[50], shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 22))),
            const SizedBox(width: 12),
            Expanded(
                child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(_fmtDur(_recordingDuration),
                  style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(12, (i) {
                  final h = (i % 3 == 0)
                      ? 20.0
                      : (i % 3 == 1)
                          ? 12.0
                          : 16.0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 3,
                    height: _isRecording ? h : 4,
                    decoration: BoxDecoration(
                        color: const Color(0xff7c3df6),
                        borderRadius: BorderRadius.circular(10)),
                  );
                }),
              )),
            ])),
            const SizedBox(width: 12),
            GestureDetector(
                onTap: _stopAndSendVoice,
                child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xff7c3df6), Color(0xff9b5ff8)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xff7c3df6).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20))),
          ]),
        ),
  );

  // ✅ Premium Emoji Picker
  Widget _buildEmojiPicker() {
    final category = _emojiCategories[_emojiTabIndex];
    final emojis = category['emojis'] as List<String>;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Column(children: [
        // Category tabs
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _emojiCategories.length,
            itemBuilder: (_, i) {
              final isSelected = _emojiTabIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _emojiTabIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xffd6c3fa).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: const Color(0xff7c3df6), width: 1.5)
                        : null,
                  ),
                  child: Text(
                    _emojiCategories[i]['icon'] as String,
                    style: TextStyle(fontSize: isSelected ? 22 : 20),
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1, color: Color(0xfff0f0f0)),

        // Emoji grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: emojis.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _onEmojiSelected(emojis[i]),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent),
                child: Center(
                  child: Text(emojis[i], style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _sendMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;
    _messageController.clear();
    final reply = _replyingToMessage;
    setState(() => _replyingToMessage = null);
    await _chatController.sendMessage(
      chatId: _chatId,
      receiverId: widget.receiverId,
      receiverName: widget.receiverName,
      receiverImage: widget.receiverImage,
      message: msg,
      replyToMessageId: reply?.id,
      replyToMessage: reply?.message,
      replyToSenderId: reply?.senderId,
      replyToImageUrl: reply?.imageUrl,
      replyToVideoUrl: reply?.videoUrl,
    );
    _scrollToBottom();
  }



  void _showPlusOptions() {
    final controller = Get.put(MessangerController());
    controller.setChatData(
        chatId: _chatId,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        receiverImage: widget.receiverImage);
    Get.bottomSheet(SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _mediaItem(
                Icons.camera_alt_rounded, 'Camera', const Color(0xff7c3df6), () {
              Get.back();
              controller.openCamera();
            }),
            _mediaItem(Icons.photo_rounded, 'Gallery', const Color(0xff4a9af5),
                () {
              Get.back();
              controller.pickImage();
            }),
            _mediaItem(Icons.videocam_rounded, 'Video', const Color(0xffff6b6b),
                () {
              Get.back();
              controller.pickVideo();
            }),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    ));
  }

  Widget _mediaItem(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87)),
        ]),
      );

  Widget _giftItem(String asset, String label) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(14),
            decoration:
                BoxDecoration(color: Colors.purple[50], shape: BoxShape.circle),
            child: Image.asset(asset, height: 36, width: 36)),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ]);
}

// ─── Video Player ─────────────────────────────────────────────────────────
class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerDialog({super.key, required this.videoUrl});
  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _c;
  bool _ready = false, _muted = false, _controls = true;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _c.initialize().then((_) {
      setState(() => _ready = true);
      _c.play();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
      '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => setState(() => _controls = !_controls),
          child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Stack(alignment: Alignment.center, children: [
                _ready
                    ? AspectRatio(
                        aspectRatio: _c.value.aspectRatio,
                        child: VideoPlayer(_c))
                    : const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xff7c3df6))),
                if (_controls && _ready)
                  Container(
                      color: Colors.black38,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SafeArea(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _btn(Icons.close, () => Get.back()),
                                          _btn(
                                              _muted
                                                  ? Icons.volume_off
                                                  : Icons.volume_up,
                                              () => setState(() {
                                                    _muted = !_muted;
                                                    _c.setVolume(
                                                        _muted ? 0 : 1);
                                                  })),
                                        ]))),
                            _btn(
                                _c.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                () => setState(() => _c.value.isPlaying
                                    ? _c.pause()
                                    : _c.play()),
                                size: 40,
                                pad: 16),
                            Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(children: [
                                  VideoProgressIndicator(_c,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                          playedColor: Color(0xff7c3df6),
                                          bufferedColor: Colors.white30,
                                          backgroundColor: Colors.white12)),
                                  const SizedBox(height: 8),
                                  ValueListenableBuilder(
                                      valueListenable: _c,
                                      builder: (_, VideoPlayerValue v, _) =>
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(_fmt(v.position),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12)),
                                                Text(_fmt(v.duration),
                                                    style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12)),
                                              ])),
                                ])),
                          ])),
              ])),
        ),
      );

  Widget _btn(IconData icon, VoidCallback onTap,
          {double size = 24, double pad = 8}) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: EdgeInsets.all(pad),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: size)));
}
