import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../../apis/api_endpoints.dart';

class AgoraTokenController extends GetxController {
  final Dio dio = Dio();

  final RxMap<String, dynamic> agoraToken = <String, dynamic>{}.obs;
  final RxBool tokenIsLoading = false.obs;

  Future<void> tryToGenerateBroadcasterToken({
    required bool isBroadcaster,
    required int userId,
    required String channelName,
    required String streamId,
    int? pkId,
  }) async {
    final Map<String, dynamic> data = {
      "channel_name": channelName,
      "uid": userId,
      "livestream_id": streamId,
      if (pkId != null && pkId > 0) "pk_id": pkId,
    };

    try {
      tokenIsLoading.value = true;

      print("=============== AGORA TOKEN REQUEST ===============");
      print("📤 URL => ${isBroadcaster ? kAgoraTokenGenerateBroadcaster : kAgoraTokenGenerateAudience}");
      print("📤 BODY => $data");
      print("📤 ROLE => ${isBroadcaster ? 'broadcaster' : 'audience'}");

      final response = await dio.post(
        isBroadcaster
            ? kAgoraTokenGenerateBroadcaster
            : kAgoraTokenGenerateAudience,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print("📥 STATUS => ${response.statusCode}");
      print("📥 RESPONSE => ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map) {
          agoraToken.value = Map<String, dynamic>.from(response.data);
        } else {
          agoraToken.clear();
        }

        print("✅ Agora token generated successfully");
        print("✅ token app_id => ${agoraToken['app_id']}");
        print("✅ token channel => ${agoraToken['channel_name']}");
        print("✅ token uid => ${agoraToken['uid']}");
        print("✅ token pk_id => ${agoraToken['pk_id']}");
        print("✅ token source => ${agoraToken['source']}");
      } else {
        agoraToken.clear();
        print("⚠️ Failed to generate agora token: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      agoraToken.clear();
      print("❌ Agora token Dio error => ${e.response?.data ?? e.message}");
    } catch (e) {
      agoraToken.clear();
      print("❌ Agora token unexpected error => $e");
    } finally {
      tokenIsLoading.value = false;
      print("=============== AGORA TOKEN END ===================");
    }
  }

  String getTokenString() {
    final dynamic token = agoraToken['token'] ??
        agoraToken['rtc_token'] ??
        agoraToken['agora_token'] ??
        agoraToken['data']?['token'] ??
        agoraToken['data']?['rtc_token'] ??
        '';
    return token?.toString() ?? '';
  }

  String getAppIdString() {
    final dynamic appId = agoraToken['app_id'] ?? agoraToken['data']?['app_id'] ?? '';
    return appId?.toString() ?? '';
  }

  String getChannelNameString() {
    final dynamic channel =
        agoraToken['channel_name'] ?? agoraToken['data']?['channel_name'] ?? '';
    return channel?.toString() ?? '';
  }
}