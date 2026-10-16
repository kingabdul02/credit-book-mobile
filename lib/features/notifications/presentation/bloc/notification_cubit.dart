import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../home/domain/entities/dashboard_entities.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository repository;

  NotificationCubit({required this.repository}) : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await repository.getNotifications();
      emit(state.copyWith(notifications: items, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void setFilter(String filter) {
    emit(state.copyWith(activeFilter: filter));
  }

  Future<void> markAsRead(String id) async {
    await repository.markAsRead(id);
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> markAllAsRead() async {
    await repository.markAllAsRead();
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> deleteNotification(String id) async {
    await repository.deleteNotification(id);
    final updated = state.notifications.where((n) => n.id != id).toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> clearAll() async {
    await repository.clearAll();
    emit(state.copyWith(notifications: []));
  }

  Future<void> addNotification(AppNotification notification) async {
    await repository.addNotification(notification);
    final updated = [notification, ...state.notifications];
    emit(state.copyWith(notifications: updated));
  }

  Future<void> syncDashboard(DashboardData dashboard) async {
    try {
      final items = await repository.syncFromDashboard(dashboard);
      emit(state.copyWith(notifications: items));
    } catch (_) {}
  }
}
