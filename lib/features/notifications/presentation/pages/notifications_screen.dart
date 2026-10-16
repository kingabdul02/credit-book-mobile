import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notification_cubit.dart';
import '../bloc/notification_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final hasUnread = state.unreadCount > 0;
              final hasItems = state.notifications.isNotEmpty;

              return Row(
                children: [
                  if (hasUnread)
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded, size: 22),
                      tooltip: 'Mark all as read',
                      color: AppTheme.primaryColor,
                      onPressed: () {
                        context.read<NotificationCubit>().markAllAsRead();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('All marked as read'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  if (hasItems)
                    IconButton(
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        size: 22,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      ),
                      tooltip: 'Clear all',
                      onPressed: () => _confirmClearAll(context),
                    ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final notifications = state.filteredNotifications;

          return Column(
            children: [
              // ── Filter Bar ─────────────────────────────────────────
              _buildFilterBar(context, state, isDark),

              // ── Notifications List ─────────────────────────────────
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState(context, isDark, state.activeFilter)
                    : RefreshIndicator(
                        onRefresh: () => context.read<NotificationCubit>().loadNotifications(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: notifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return _buildNotificationCard(context, notification, isDark);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, NotificationState state, bool isDark) {
    final filters = [
      {'label': 'All', 'count': state.notifications.length},
      {'label': 'Unread', 'count': state.unreadCount},
      {'label': 'Reminders', 'count': null},
      {'label': 'Activity', 'count': null},
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final label = filter['label'] as String;
          final count = filter['count'] as int?;
          final isSelected = state.activeFilter == label;

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(
              count != null && count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
              ),
            ),
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            selectedColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
              ),
            ),
            onSelected: (_) {
              context.read<NotificationCubit>().setFilter(label);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
    bool isDark,
  ) {
    final categoryConfig = _getCategoryConfig(notification.category);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        context.read<NotificationCubit>().deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationCubit>().markAsRead(notification.id);
            }
            if (notification.actionRoute != null && notification.actionRoute!.isNotEmpty) {
              context.push(notification.actionRoute!);
            } else {
              context.push('/notification-detail', extra: notification);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? (notification.isRead ? AppTheme.darkSurface : const Color(0xFF1E293B))
                  : (notification.isRead ? Colors.white : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !notification.isRead
                    ? AppTheme.primaryColor.withValues(alpha: 0.35)
                    : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                width: !notification.isRead ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category Icon ─────────────────────────────────────
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: categoryConfig.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      categoryConfig.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Content ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            (notification.actionRoute != null && notification.actionRoute!.isNotEmpty)
                                ? 'Tap to view details'
                                : 'Tap to read full notice',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: (notification.actionRoute != null && notification.actionRoute!.isNotEmpty)
                                  ? AppTheme.primaryColor
                                  : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: (notification.actionRoute != null && notification.actionRoute!.isNotEmpty)
                                ? AppTheme.primaryColor
                                : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              filter == 'Unread' ? 'No Unread Notifications' : 'All Caught Up! 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'Unread'
                  ? 'You have read all your notifications.'
                  : 'You have no new alerts. Debt due dates, payments, and legacy nominations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('Are you sure you want to remove all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotificationCubit>().clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  _CategoryConfig _getCategoryConfig(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.overdue:
        return _CategoryConfig(
          icon: Icons.warning_amber_rounded,
          gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        );
      case NotificationCategory.dueSoon:
        return _CategoryConfig(
          icon: Icons.timer_outlined,
          gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        );
      case NotificationCategory.payment:
        return _CategoryConfig(
          icon: Icons.account_balance_wallet_rounded,
          gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
        );
      case NotificationCategory.debt:
        return _CategoryConfig(
          icon: Icons.receipt_long_rounded,
          gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        );
      case NotificationCategory.legacy:
        return _CategoryConfig(
          icon: Icons.shield_outlined,
          gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        );
      case NotificationCategory.system:
        return _CategoryConfig(
          icon: Icons.info_outline_rounded,
          gradient: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
        );
    }
  }
}

class _CategoryConfig {
  final IconData icon;
  final List<Color> gradient;

  const _CategoryConfig({required this.icon, required this.gradient});
}
