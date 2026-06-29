import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/modules/home/controllers/home_controller.dart';
import 'app/modules/home/views/home_view.dart';
import 'app/modules/livestream/controllers/agoraTokenController.dart';
import 'app/modules/livestream/controllers/livestream_controller.dart';
import 'app/modules/livestream/controllers/websocket_controller.dart';
import 'app/modules/messanger/views/audio_call_view.dart';
import 'app/modules/messanger/views/video_call_view.dart';
import 'app/modules/moments/controllers/moments_controller.dart';
import 'app/modules/myprofile/controllers/myprofile_controller.dart';
import 'app/modules/registersteps/controllers/registersteps_controller.dart';
import 'app/routes/app_pages.dart';
import 'background_service/background_main.dart';
import 'notifications/fcm_notifications.dart';

// Connectivity Controller-এর সঠিক ইমপোর্ট নিশ্চিত করার জন্য (যদি আলাদা ফাইল থাকে)
// যদি GetX-এর নিজস্ব থাকে তবে নিচের ক্লাসটি ব্যবহৃত হবে, নয়তো আপনার কাস্টম কন্ট্রোলারটি ইমপোর্ট হবে।

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  // ১. ফ্ল্যাটার ইঞ্জিন বাইন্ডিং এবং নেটওয়ার্ক ওভাররাইড নিশ্চিত করা
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  try {
    // ২. ফায়ারবেস সেফ ইনিশিয়ালাইজেশন
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // ৩. কোর নোটিফিকেশন সেটআপ (যা রান অ্যাপের আগে দরকার)
    await _requestPermissions();
    await notificationInitialization();
    FirebaseMessaging.onBackgroundMessage(messageHandler);

  } catch (e) {
    print("⚠️ Initialization Warning: $e");
  }

  // ৪. GetX কন্ট্রোলার ডিপেন্ডেন্সি ইনজেকশন
  Get.put(AuthController());
  Get.put(RegisterstepsController());
  Get.put(AgoraTokenController());
  Get.put(WebsocketController());
  Get.put(LivestreamController());
  
  // জেনেরিক কানেক্টিভিটি চেকার সেফ ইনজেকশন
  if (!Get.isRegistered<ConnectivityController>()) {
    Get.put(ConnectivityController());
  }
  
  Get.put(HomeController());
  Get.put(MyprofileController());
  Get.put(MomentsController());
  
  // ৫. UI এবং সিস্টেম বার কনফিগারেশন
  _configureForAndroidDevice();

  // ৬. নন-ব্লকিং ব্যাকগ্রাউন্ড লিসেনার্স (অ্যাপ লোড হওয়ার ঠিক পর মুহূর্তে ব্যাকগ্রাউন্ডে এক্সিকিউট হবে)
  Future.delayed(Duration.zero, () {
    getDeviceToken();
    firebaseMessagingListener();
    notificationCallInitialization();
  });

  runApp(const MyApp());
}

void _configureForAndroidDevice() {
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}

void getDeviceToken() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    print("✅ FCM Device Token: $token");
  } catch (e) {
    print("❌ Error fetching FCM Token: $e");
  }
}

Future<void> _requestPermissions() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    print('📋 Permission status: ${settings.authorizationStatus}');
  } catch (e) {
    print("❌ Error requesting permissions: $e");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static bool _isHandlingCall = false;

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    if (action.buttonKeyPressed == "Answer") {
      if (_isHandlingCall) {
        print('⚠️ Duplicate call ignored');
        return;
      }
      _isHandlingCall = true;

      // ব্যাকগ্রাউন্ড সার্ভিস এলার্ট স্টপ (সেফ কল)
      try {
        service.invoke('stopCallRing');
      } catch (_) {}
      
      await AwesomeNotifications().dismiss(action.id!);

      final data = Map<String, dynamic>.from(notificationData);
      final callerIdStr = data['caller_id'] ?? '0';
      final callType = data['type'] ?? 'audio';
      final callerUserId = int.tryParse(callerIdStr.toString()) ?? 0;

      print('📞 Answer pressed - callerId: $callerUserId, type: $callType');

      if (callerUserId == 0) {
        print('❌ Invalid caller ID');
        _isHandlingCall = false;
        return;
      }

      try {
        final authController = Get.find<AuthController>();
        final myUserId = authController.userProfile.value.user?.id?.toInt() ?? 0;
        final agoraTokenController = Get.find<AgoraTokenController>();

        await agoraTokenController.tryToGenerateBroadcasterToken(
          isBroadcaster: true,
          userId: myUserId,
          channelName: '$callerUserId',
          streamId: '$callerUserId',
        );

        final token = agoraTokenController.agoraToken['token'];
        if (token == null || token.toString().isEmpty) {
          print('❌ Token empty');
          _isHandlingCall = false;
          return;
        }

        if (callType == 'video') {
          Get.to(
            () => VideoCallView(
              channelName: '$callerUserId',
              isBroadcaster: false,
              token: token,
              profile: null,
            ),
            arguments: data,
          );
        } else {
          Get.to(
            () => AudioCallView(
              channelName: '$callerUserId',
              isBroadcaster: false,
              token: token,
              profile: null,
            ),
            arguments: data,
          );
        }
      } catch (e) {
        print('❌ Error in action receiver: $e');
      } finally {
        Future.delayed(const Duration(seconds: 3), () {
          _isHandlingCall = false;
        });
      }
    } else if (action.buttonKeyPressed == "Cancel") {
      try {
        service.invoke('stopCallRing');
      } catch (_) {}
      await AwesomeNotifications().dismiss(action.id!);
      print('📵 Cancelled');
    }
  }
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<ReceivedAction>? _actionStreamSubscription;
  bool subscribedActionStream = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!subscribedActionStream) {
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: MyApp.onActionReceivedMethod,
      );
      subscribedActionStream = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _actionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Meet Live",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF9e28b4),
        ),
        primaryColor: const Color(0xFF9e28b4),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
    );
  }
}