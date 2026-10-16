import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notification_cubit.dart';

class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getCategoryConfig(notification.category);
    final hasActionRoute = notification.actionRoute != null && notification.actionRoute!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Notification Details',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              notification.isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
              size: 22,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
            ),
            tooltip: notification.isRead ? 'Mark as unread' : 'Mark as read',
            onPressed: () {
              // Toggling read status
              if (!notification.isRead) {
                context.read<NotificationCubit>().markAsRead(notification.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Marked as read'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: Color(0xFFEF4444),
            ),
            tooltip: 'Delete notification',
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Category Banner Card ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: config.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: config.gradient.first.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(config.icon, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              config.label.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notification.timeAgo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    notification.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(notification.timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),

            const SizedBox(height: 20),

            // ── Content Card ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.subject_rounded,
                        size: 20,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                        ),
                        tooltip: 'Copy text',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '${notification.title}\n\n${notification.message}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Notification copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SelectableText(
                    notification.message,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0),

            // ── Metadata / Action Data (if present) ───────────────────
            if (notification.actionData != null && notification.actionData!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...notification.actionData!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatKey(entry.key),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              entry.value?.toString() ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),
            ],

            const SizedBox(height: 28),

            // ── Action / Primary Button ──────────────────────────────
            if (hasActionRoute) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                onPressed: () {
                  if (!notification.isRead) {
                    context.read<NotificationCubit>().markAsRead(notification.id);
                  }
                  context.push(notification.actionRoute!);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getActionLabel(notification.category, notification.actionRoute!),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ] else ...[
              // Informational badge card when no target screen exists
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is an informational notice. No additional action is required.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notification?'),
        content: const Text('Are you sure you want to remove this notification?'),
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
              context.read<NotificationCubit>().deleteNotification(notification.id);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notification deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} at $hour:$minute';
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  String _getActionLabel(NotificationCategory category, String route) {
    if (route.contains('/ledger')) return 'View Ledger & Transactions';
    if (route.contains('/all-debts')) return 'Review Overdue Debts';
    if (route.contains('/next-of-kin')) return 'Manage Nominees';
    if (route.contains('/settings')) return 'Go to Settings';
    if (route.contains('/home')) return 'Open Dashboard';
    return 'View Related Record';
  }

  _CategoryConfig _getCategoryConfig(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.overdue:
        return _CategoryConfig(
          label: 'Overdue Alert',
          icon: Icons.warning_amber_rounded,
          gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        );
      case NotificationCategory.dueSoon:
        return _CategoryConfig(
          label: 'Upcoming Due Date',
          icon: Icons.timer_outlined,
          gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        );
      case NotificationCategory.payment:
        return _CategoryConfig(
          label: 'Payment Notice',
          icon: Icons.account_balance_wallet_rounded,
          gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
        );
      case NotificationCategory.debt:
        return _CategoryConfig(
          label: 'Debt Activity',
          icon: Icons.receipt_long_rounded,
          gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        );
      case NotificationCategory.legacy:
        return _CategoryConfig(
          label: 'Estate & Nominees',
          icon: Icons.shield_outlined,
          gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        );
      case NotificationCategory.system:
        return _CategoryConfig(
          label: 'System Notice',
          icon: Icons.info_outline_rounded,
          gradient: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
        );
    }
  }
}

class _CategoryConfig {
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _CategoryConfig({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}
