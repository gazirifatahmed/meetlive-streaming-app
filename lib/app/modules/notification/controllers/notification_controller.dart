import 'package:dio/dio.dart';
import 'package:get/get.dart';


import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';

class NotificationController extends GetxController {
  final dio = Dio();
  final notificationListData = [].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    showNotificationData();
  }

  Future<void> showNotificationData() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final response = await dio.get(
        kNotificationList,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data['status'] == true) {
          notificationListData.value = response.data['giftsr_data'] ?? [];
          print('Notifications loaded: ${notificationListData.length}');
        } else {
          hasError.value = true;
          errorMessage.value = 'Failed to load notifications';
        }
      } else {
        hasError.value = true;
        errorMessage.value = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network error: $e';
      print('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshNotifications() async {
    await showNotificationData();
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await dio.post(
        '$kMarkNotificationRead/$notificationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authController.userProfile.value.token}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Update local data
        final index = notificationListData.indexWhere(
            (n) => int.tryParse(n['id'].toString()) == notificationId);
        if (index != -1) {
          notificationListData[index]['is_read'] = true;
          notificationListData.refresh();
        }
        Get.snackbar('Success', 'Notification marked as read');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      Get.snackbar('Error', 'Failed to mark notification as read');
    }
  }

  void deleteNotification(int notificationId) {
    // TODO: Implement delete notification functionality
    // This would require a backend API endpoint
  }
}
