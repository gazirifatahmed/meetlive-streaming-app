import 'dart:async';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';


import '../app/modules/auth/controllers/auth_controller.dart';
import '../app/modules/livestream/controllers/livestream_controller.dart';
import '../app/modules/messanger/views/audio_call_view.dart';
import '../app/modules/messanger/views/video_call_view.dart';
import '../constants/name_constants.dart';

// ✅ Global notification data store
Map<String, dynamic> notificationData = {};

// ─────────────────────────────────────────────
// INITIALIZATION
// ─────────────────────────────────────────────

Future<void> notificationInitialization() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void notificationCallInitialization() {
  AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelGroupKey: 'Call notifications $kAppName',
      channelKey: 'CallingTaDoLive',
      channelName: 'Call notifications $kAppName',
      channelDescription: 'Notification channel for calling',
      channelShowBadge: true,
      importance: NotificationImportance.High,
      enableVibration: true,
    ),
  ]);

  // ✅ Action listener set করো — Answer/Cancel button এর জন্য
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );
}

// ─────────────────────────────────────────────
// ✅ ANSWER / CANCEL HANDLER — এটাই মূল fix
// ─────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final data = notificationData; // FCM থেকে আসা data

  if (action.buttonKeyPressed == 'Answer') {
// ✅ Ring বন্ধ করো
    FlutterBackgroundService().invoke('stopCallRing');

// ✅ Caller এর info বের করো
    final callerIdStr = data['caller_id'] ?? '0';
    final callType = data['type'] ?? 'audio'; // 'audio' বা 'video'
    final callerUserId = int.tryParse(callerIdStr.toString()) ?? 0;

    print('📞 Call Answered - callerUserId: $callerUserId, type: $callType');

// ✅ App foreground এ আনো এবং call view এ যাও
// GetX দিয়ে navigate করতে হলে app context লাগবে
// তাই SchedulerBinding দিয়ে করো
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
// ✅ LivestreamController খোঁজো
        final livestreamController = Get.find<LivestreamController>();
        final authController = Get.find<AuthController>();

        final myUserId =
            authController.userProfile.value.user?.id?.toInt() ?? 0;

// ✅ Receiver এর জন্য token generate করো
// Channel name = caller এর userId (গুরুত্বপূর্ণ!)
        await livestreamController.tryToGenerateToken(
          roleId: 2, // 2 = subscriber/audience (receiver)
          userId: myUserId,
          channelName: '$callerUserId', // caller এর channel এ join
        );

        final token = livestreamController.getTokens['token'];

        if (token == null || token.isEmpty) {
          print('❌ Token generate failed for receiver');
          return;
        }

        print('✅ Receiver token generated: $token');

// ✅ Call type অনুযায়ী View এ যাও
        if (callType == 'video') {
          Get.to(
            () => VideoCallView(
              channelName: '$callerUserId', // ⚠️ caller এর channel
              isBroadcaster: false, // ⚠️ receiver = false
              token: token,
              profile: null,
            ),
            arguments: data,
          );
        } else {
          Get.to(
            () => AudioCallView(
              channelName: '$callerUserId', // ⚠️ caller এর channel
              isBroadcaster: false, // ⚠️ receiver = false
              token: token,
              profile: null,
            ),
            arguments: data,
          );
        }
      } catch (e) {
        print('❌ Error navigating to call view: $e');
      }
    });
  } else if (action.buttonKeyPressed == 'Cancel') {
// ✅ Ring বন্ধ করো
    FlutterBackgroundService().invoke('stopCallRing');

// ✅ Notification dismiss করো
    await AwesomeNotifications().dismiss(action.id!);

    print('📵 Call Cancelled/Rejected');

// Optional: Backend কে reject জানাও
// final callerId = data['caller_id'];
// await dio.get(rejectCallUrl(callerId));
  }
}

// ─────────────────────────────────────────────
// FCM HANDLERS
// ─────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> messageHandler(RemoteMessage message) async {
  notificationData = Map<String, dynamic>.from(message.data);

  if (notificationData['notice_type'] == 'call_notice') {
    await sendCallNotification(notificationMessage: notificationData);
  } else {
    await messageNotification(message: notificationData);
  }
}

void firebaseMessagingListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    notificationData = Map<String, dynamic>.from(message.data);

    if (notificationData['notice_type'] == 'call_notice') {
      sendCallNotification(notificationMessage: notificationData);
    } else {
      messageNotification(message: notificationData);
    }
  });
}

// ─────────────────────────────────────────────
// NOTIFICATION DISPLAY
// ─────────────────────────────────────────────

Future<void> messageNotification({required Map message}) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    "message notification",
    "Messages Notifications",
    channelDescription: "show message to user",
    channelShowBadge: false,
    importance: Importance.max,
    priority: Priority.high,
    onlyAlertOnce: true,
    showProgress: true,
    autoCancel: false,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    Random().nextInt(1000000000),
    message['title'],
    message['message'],
    platformChannelSpecifics,
  );

  FlutterBackgroundService().invoke('stopCallRing');
}

Future<void> sendCallNotification({required Map notificationMessage}) async {
  final content = NotificationContent(
    id: 1265478,
    channelKey: 'CallingTaDoLive',
    title: 'TaDo Live Calling',
    body:
        "${notificationMessage['type'] == 'video' ? "Video" : "Audio"} call from ${notificationMessage['caller_name'] ?? 'Unknown caller'}",
    autoDismissible: true,
    wakeUpScreen: true,
    locked: true,
    displayOnBackground: true,
    displayOnForeground: true,
    fullScreenIntent: true,
    showWhen: true,
    largeIcon: notificationMessage['caller_image']?.isNotEmpty == true
        ? notificationMessage['caller_image']
        : null,
  );

  final actionButtons = [
    NotificationActionButton(
      key: "Answer",
      label: "Answer",
      color: Colors.green,
      actionType: ActionType.Default, // ✅ App foreground এ আনবে
    ),
    NotificationActionButton(
      key: "Cancel",
      label: "Cancel",
      color: Colors.red,
      actionType: ActionType.DismissAction, // ✅ Notification dismiss করবে
      isDangerousOption: true,
    ),
  ];

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  await AwesomeNotifications().createNotification(
    content: content,
    actionButtons: actionButtons,
  );
}
