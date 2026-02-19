import '../models/notification.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  /// Get all notifications for the current user
  Future<List<AppNotification>> getAll() async {
    final response = await _api.get(ApiConstants.notifications);
    return (response as List)
        .map((e) => AppNotification.fromJson(e))
        .toList();
  }

  /// Get unread notifications for the current user
  Future<List<AppNotification>> getUnread() async {
    final response = await _api.get('${ApiConstants.notifications}/unread');
    return (response as List)
        .map((e) => AppNotification.fromJson(e))
        .toList();
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    final response = await _api.get('${ApiConstants.notifications}/unread/count');
    return response as int;
  }

  /// Mark a single notification as read
  Future<void> markAsRead(int notificationId) async {
    await _api.patch('${ApiConstants.notifications}/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _api.patch('${ApiConstants.notifications}/read-all');
  }
}
