import 'package:flutter/material.dart';
import '../error/error_handler.dart';
import '../theme/app_theme.dart';
import '../services/session_manager.dart';

/// A polished, user-friendly error view widget that gracefully displays
/// error messages (especially network/connectivity failures) with an icon,
/// clear heading, explanation, and a styled retry button.
class AppErrorView extends StatelessWidget {
  final dynamic error;
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String retryText;
  final bool isCompact;
  final EdgeInsetsGeometry? padding;

  const AppErrorView({
    super.key,
    this.error,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryText = 'Try Again',
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = ErrorHandler.isNetworkError(error);
    final isSession = ErrorHandler.isSessionExpired(error);
    final displayTitle = title ?? ErrorHandler.getTitle(error);
    final displayMessage = message ?? ErrorHandler.getFriendlyMessage(error);
    final displayIcon = icon ??
        (isNetwork
            ? Icons.wifi_off_rounded
            : isSession
                ? Icons.lock_outline_rounded
                : Icons.error_outline_rounded);

    final iconColor = isNetwork ? AppTheme.primaryColor : AppTheme.errorColor;
    final iconBgColor = iconColor.withValues(alpha: 0.1);

    final buttonLabel = (retryText == 'Try Again' && isSession) ? 'Sign In Again' : retryText;
    final buttonIcon = isSession ? Icons.login_rounded : Icons.refresh_rounded;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isCompact ? 16 : 32,
            ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft rounded icon badge
            Container(
              width: isCompact ? 56 : 72,
              height: isCompact ? 56 : 72,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                displayIcon,
                size: isCompact ? 28 : 36,
                color: iconColor,
              ),
            ),
            SizedBox(height: isCompact ? 14 : 20),
            // Error Title
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            // Friendly Error Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ),
            // Action button
            if (onRetry != null || isSession) ...[
              SizedBox(height: isCompact ? 18 : 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (isSession) {
                    SessionManager.instance.notifySessionExpired();
                  }
                  onRetry?.call();
                },
                icon: Icon(buttonIcon, size: 18),
                label: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 22 : 28,
                    vertical: isCompact ? 10 : 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
