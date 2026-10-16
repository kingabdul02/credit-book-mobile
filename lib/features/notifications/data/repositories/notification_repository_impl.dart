import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../../../home/domain/entities/dashboard_entities.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SharedPreferences sharedPreferences;
  final NotificationRemoteDataSource? remoteDataSource;
  static const _storageKey = 'app_notifications_list';

  NotificationRepositoryImpl({
    required this.sharedPreferences,
    this.remoteDataSource,
  });

  @override
  Future<List<AppNotification>> getNotifications() async {
    if (remoteDataSource != null) {
      try {
        final serverList = await remoteDataSource!.getNotifications();
        if (serverList.isNotEmpty) {
          serverList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          await saveNotifications(serverList);
          return serverList;
        }
      } catch (_) {
        // Server fetch failed, gracefully fallback to local cache
      }
    }

    return getCachedNotifications();
  }

  Future<List<AppNotification>> getCachedNotifications() async {
    final raw = sharedPreferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      final initial = _getInitialNotifications();
      await saveNotifications(initial);
      return initial;
    }

    try {
      final decoded = json.decode(raw) as List;
      final list = decoded
          .map((item) => AppNotification.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (_) {
      final fallback = _getInitialNotifications();
      await saveNotifications(fallback);
      return fallback;
    }
  }

  @override
  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final list = notifications.map((n) => n.toMap()).toList();
    await sharedPreferences.setString(_storageKey, json.encode(list));
  }

  @override
  Future<void> markAsRead(String id) async {
    final list = await getCachedNotifications();
    final updated = list.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    await saveNotifications(updated);

    if (remoteDataSource != null) {
      try {
        await remoteDataSource!.markAsRead(id);
      } catch (_) {}
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final list = await getCachedNotifications();
    final updated = list.map((n) => n.copyWith(isRead: true)).toList();
    await saveNotifications(updated);

    if (remoteDataSource != null) {
      try {
        await remoteDataSource!.markAllAsRead();
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    final list = await getCachedNotifications();
    list.removeWhere((n) => n.id == id);
    await saveNotifications(list);

    if (remoteDataSource != null) {
      try {
        await remoteDataSource!.deleteNotification(id);
      } catch (_) {}
    }
  }

  @override
  Future<void> clearAll() async {
    await sharedPreferences.remove(_storageKey);

    if (remoteDataSource != null) {
      try {
        await remoteDataSource!.clearAll();
      } catch (_) {}
    }
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    final list = await getCachedNotifications();
    list.insert(0, notification);
    await saveNotifications(list);
  }

  @override
  Future<List<AppNotification>> syncFromDashboard(DashboardData dashboard) async {
    // If we have remoteDataSource, fetching notifications from the server handles real backend alerts.
    // We also reconcile local notifications for quick offline visibility.
    final existing = await getCachedNotifications();
    final existingIds = existing.map((n) => n.id).toSet();
    final List<AppNotification> newItems = [];

    // 1. Process Overdue debts from Metrics
    if (dashboard.metrics.overdueCount > 0) {
      final overdueId = 'metric_overdue_${dashboard.metrics.overdueCount}';
      if (!existingIds.contains(overdueId)) {
        newItems.add(
          AppNotification(
            id: overdueId,
            title: 'Attention: ${dashboard.metrics.overdueCount} Overdue Payment${dashboard.metrics.overdueCount > 1 ? 's' : ''}',
            message: 'You have ${dashboard.metrics.overdueCount} debt records past their due date. Review them to send payment reminders.',
            category: NotificationCategory.overdue,
            timestamp: DateTime.now(),
            actionRoute: '/all-debts',
          ),
        );
      }
    }

    // 2. Process Reminders
    for (final reminder in dashboard.upcomingReminders) {
      final remId = 'rem_${reminder.id}';
      if (!existingIds.contains(remId) && reminder.debt?.contact != null) {
        final contactName = reminder.debt!.contact!.fullName;
        newItems.add(
          AppNotification(
            id: remId,
            title: 'Reminder: $contactName',
            message: 'Scheduled reminder for debt with $contactName (${reminder.typeLabel}).',
            category: NotificationCategory.dueSoon,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            actionRoute: '/ledger/${reminder.debt!.contact!.id}',
          ),
        );
      }
    }

    // 3. Process Recent Transactions
    for (final tx in dashboard.recentTransactions) {
      final txId = 'tx_${tx.id}';
      if (!existingIds.contains(txId)) {
        final contactName = tx.debt?.contact?.fullName ?? 'Contact';
        final isPayment = tx.type == 'PAYMENT';
        newItems.add(
          AppNotification(
            id: txId,
            title: isPayment ? 'Payment Recorded' : 'Debt Updated',
            message: '$contactName: ${isPayment ? 'Recorded payment of' : 'Added'} ${tx.amount}.',
            category: isPayment ? NotificationCategory.payment : NotificationCategory.debt,
            timestamp: DateTime.tryParse(tx.createdAt) ?? DateTime.now(),
            actionRoute: tx.debt?.contact != null ? '/ledger/${tx.debt!.contact!.id}' : '/all-debts',
          ),
        );
      }
    }

    if (newItems.isNotEmpty) {
      final combined = [...newItems, ...existing];
      combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await saveNotifications(combined);
      return combined;
    }

    return existing;
  }

  List<AppNotification> _getInitialNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'welcome_1',
        title: 'Welcome to CreditBook! 🎉',
        message: 'Track who owes you and who you owe with instant offline sync, biometrics, and secure ledger management.',
        category: NotificationCategory.system,
        timestamp: now.subtract(const Duration(minutes: 10)),
        actionRoute: '/home',
      ),
      AppNotification(
        id: 'legacy_setup_tip',
        title: 'Protect Your Financial Estate 🛡️',
        message: 'Nominate a trusted Next of Kin so your financial ledger is safely accessible in case of an emergency.',
        category: NotificationCategory.legacy,
        timestamp: now.subtract(const Duration(hours: 2)),
        actionRoute: '/next-of-kin',
      ),
      AppNotification(
        id: 'biometric_security_tip',
        title: 'Security Recommendation',
        message: 'Secure your transaction approvals with biometric face authentication and transaction PIN.',
        category: NotificationCategory.system,
        timestamp: now.subtract(const Duration(hours: 5)),
        actionRoute: '/settings',
      ),
    ];
  }
}
