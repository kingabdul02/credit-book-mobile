import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/notification_cubit.dart';
import '../bloc/notification_state.dart';

class NotificationBellButton extends StatelessWidget {
  final Color? iconColor;

  const NotificationBellButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = iconColor ?? (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark);

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final unreadCount = state.unreadCount;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                unreadCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                color: defaultColor,
                size: 24,
              ),
              tooltip: 'Notifications',
              onPressed: () {
                context.read<NotificationCubit>().loadNotifications();
                context.push('/notifications');
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
              ),
          ],
        );
      },
    );
  }
}
