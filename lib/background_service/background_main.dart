import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';

final service = FlutterBackgroundService();

Future<void> initializeBackgroundService() async {
  // ✅ Background service disabled — FCM diye call handle hocche
  return;
}

bool onIosBackground(ServiceInstance service) {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // ✅ Disabled
}