import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/red_packet.dart';
import '../app/modules/auth/controllers/auth_controller.dart';
import 'api_endpoints.dart';

class RedPacketService {
  static final Dio _dio = Dio();
  static final AuthController _authController = Get.find<AuthController>();

  static Options get _defaultOptions => Options(
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer ${_authController.userProfile.value.token}",
    },
  );

  /// Send a red packet
  static Future<RedPacketResponse> sendRedPacket({
    required String amount,
    required String message,
    required int livestreamId,
    required int quantity,
    int? durationMinutes,
    bool? isGlobal,
  }) async {
    try {
      final request = RedPacketSendRequest(
        amount: amount,
        message: message,
        livestreamId: livestreamId,
        quantity: quantity,
        durationMinutes: durationMinutes,
        isGlobal: isGlobal,
      );

      final response = await _dio.post(
        kSendRedPacketUrl,
        data: request.toJson(),
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Red packet sent successfully: ${response.data}");
        return RedPacketResponse.fromJson(response.data);
      } else {
        print("⚠️ Failed to send red packet: ${response.statusCode} - ${response.data}");
        return RedPacketResponse(
          success: false,
          message: "Failed to send red packet",
          error: "HTTP ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      print("❌ DioException in sendRedPacket: ${e.message}");
      String errorMessage = "Network error occurred";
      
      if (e.response != null) {
        errorMessage = e.response!.data['message'] ?? "Server error occurred";
        print("❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
      
      return RedPacketResponse(
        success: false,
        message: errorMessage,
        error: e.message,
      );
    } catch (e) {
      print("❌ Unexpected Error in sendRedPacket: $e");
      return RedPacketResponse(
        success: false,
        message: "An unexpected error occurred",
        error: e.toString(),
      );
    }
  }

  /// Collect a red packet
  static Future<RedPacketResponse> collectRedPacket({
    required int redPacketId,
  }) async {
    try {
      final response = await _dio.post(
        kCollectRedPacketUrl(redPacketId),
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Red packet collected successfully: ${response.data}");
        return RedPacketResponse.fromJson(response.data);
      } else {
        print("⚠️ Failed to collect red packet: ${response.statusCode} - ${response.data}");
        return RedPacketResponse(
          success: false,
          message: "Failed to collect red packet",
          error: "HTTP ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      print("❌ DioException in collectRedPacket: ${e.message}");
      String errorMessage = "Network error occurred";
      
      if (e.response != null) {
        errorMessage = e.response!.data['message'] ?? "Server error occurred";
        print("❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
      
      return RedPacketResponse(
        success: false,
        message: errorMessage,
        error: e.message,
      );
    } catch (e) {
      print("❌ Unexpected Error in collectRedPacket: $e");
      return RedPacketResponse(
        success: false,
        message: "An unexpected error occurred",
        error: e.toString(),
      );
    }
  }

  /// Refund an expired red packet
  static Future<RedPacketResponse> refundRedPacket({
    required int redPacketId,
  }) async {
    try {
      final response = await _dio.post(
        kRefundRedPacketUrl(redPacketId),
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Red packet refunded successfully: ${response.data}");
        return RedPacketResponse.fromJson(response.data);
      } else {
        print("⚠️ Failed to refund red packet: ${response.statusCode} - ${response.data}");
        return RedPacketResponse(
          success: false,
          message: "Failed to refund red packet",
          error: "HTTP ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      print("❌ DioException in refundRedPacket: ${e.message}");
      String errorMessage = "Network error occurred";
      
      if (e.response != null) {
        errorMessage = e.response!.data['message'] ?? "Server error occurred";
        print("❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
      
      return RedPacketResponse(
        success: false,
        message: errorMessage,
        error: e.message,
      );
    } catch (e) {
      print("❌ Unexpected Error in refundRedPacket: $e");
      return RedPacketResponse(
        success: false,
        message: "An unexpected error occurred",
        error: e.toString(),
      );
    }
  }

  /// Get red packets for a specific livestream
  static Future<List<RedPacket>> getRedPacketsForLivestream({
    required int livestreamId,
  }) async {
    try {
      final response = await _dio.get(
        kGetRedPacketsForLivestreamUrl(livestreamId),
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        print("✅ Red packets fetched successfully: ${response.data}");
        
        List<RedPacket> redPackets = [];
        if (response.data['data'] != null) {
          for (var item in response.data['data']) {
            redPackets.add(RedPacket.fromJson(item));
          }
        }
        
        return redPackets;
      } else {
        print("⚠️ Failed to fetch red packets: ${response.statusCode} - ${response.data}");
        return [];
      }
    } on DioException catch (e) {
      print("❌ DioException in getRedPacketsForLivestream: ${e.message}");
      if (e.response != null) {
        print("❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
      return [];
    } catch (e) {
      print("❌ Unexpected Error in getRedPacketsForLivestream: $e");
      return [];
    }
  }

  /// Get user's red packet history
  static Future<List<RedPacket>> getUserRedPacketHistory() async {
    try {
      final response = await _dio.get(
        kGetUserRedPacketHistoryUrl,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        print("✅ User red packet history fetched successfully: ${response.data}");
        
        List<RedPacket> redPackets = [];
        if (response.data['data'] != null) {
          for (var item in response.data['data']) {
            redPackets.add(RedPacket.fromJson(item));
          }
        }
        
        return redPackets;
      } else {
        print("⚠️ Failed to fetch user red packet history: ${response.statusCode} - ${response.data}");
        return [];
      }
    } on DioException catch (e) {
      print("❌ DioException in getUserRedPacketHistory: ${e.message}");
      if (e.response != null) {
        print("❌ Server Error: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        print("❌ Network Error: ${e.message}");
      }
      return [];
    } catch (e) {
      print("❌ Unexpected Error in getUserRedPacketHistory: $e");
      return [];
    }
  }
}
