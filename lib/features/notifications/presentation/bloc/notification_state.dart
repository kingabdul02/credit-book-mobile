import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

class NotificationState extends Equatable {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String activeFilter; // 'All', 'Unread', 'Reminders', 'Activity'

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.activeFilter = 'All',
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<AppNotification> get filteredNotifications {
    switch (activeFilter) {
      case 'Unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'Reminders':
        return notifications
            .where((n) =>
                n.category == NotificationCategory.overdue ||
                n.category == NotificationCategory.dueSoon)
            .toList();
      case 'Activity':
        return notifications
            .where((n) =>
                n.category == NotificationCategory.payment ||
                n.category == NotificationCategory.debt ||
                n.category == NotificationCategory.legacy)
            .toList();
      case 'All':
      default:
        return notifications;
    }
  }

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? activeFilter,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [notifications, isLoading, activeFilter];
}
