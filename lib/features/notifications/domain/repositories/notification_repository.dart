import '../entities/app_notification.dart';
import '../../../home/domain/entities/dashboard_entities.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> saveNotifications(List<AppNotification> notifications);
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> clearAll();
  Future<void> addNotification(AppNotification notification);
  Future<List<AppNotification>> syncFromDashboard(DashboardData dashboard);
}
