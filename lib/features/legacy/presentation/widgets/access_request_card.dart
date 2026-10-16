import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/legacy_access_request_entity.dart';

class AccessRequestCard extends StatelessWidget {
  final LegacyAccessRequestEntity request;
  final bool isActionLoading;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;
  final VoidCallback? onViewReport;

  const AccessRequestCard({
    super.key,
    required this.request,
    this.isActionLoading = false,
    this.onApprove,
    this.onDeny,
    this.onViewReport,
  });

  Color get _statusColor {
    if (request.isPending) return const Color(0xFFF59E0B);
    if (request.isApproved) return AppTheme.primaryColor;
    if (request.isDenied) return AppTheme.errorColor;
    return AppTheme.textMuted;
  }

  IconData get _statusIcon {
    if (request.isPending) return Icons.hourglass_top_rounded;
    if (request.isApproved) return Icons.check_circle_rounded;
    if (request.isDenied) return Icons.cancel_rounded;
    return Icons.help_outline_rounded;
  }

  String get _statusLabel {
    if (request.isAutoApproved) return 'Auto-Approved';
    return request.statusLabel ?? request.status;
  }

  String get _timeInfo {
    if (request.isPending && request.expiresAt != null) {
      final expiry = DateTime.tryParse(request.expiresAt!);
      if (expiry != null) {
        final remaining = expiry.difference(DateTime.now());
        if (remaining.isNegative) return 'Expired — awaiting auto-approval';
        if (remaining.inDays > 0) return '${remaining.inDays} days remaining';
        if (remaining.inHours > 0) return '${remaining.inHours} hours remaining';
        return '${remaining.inMinutes} minutes remaining';
      }
    }
    if (request.isApproved && request.approvedAt != null) {
      final date = DateTime.tryParse(request.approvedAt!);
      if (date != null) {
        return 'Approved ${_formatDate(date)}';
      }
    }
    if (request.isDenied && request.deniedAt != null) {
      final date = DateTime.tryParse(request.deniedAt!);
      if (date != null) {
        return 'Denied ${_formatDate(date)}';
      }
    }
    return '';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactName = request.legacyContact?.fullName ?? 'Unknown Contact';
    final contactRelation = request.legacyContact?.relationship ?? '';
    final initials = request.legacyContact?.initials ?? '?';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: request.isPending
                          ? [const Color(0xFFF59E0B).withValues(alpha: 0.8), const Color(0xFFD97706)]
                          : request.isApproved
                              ? [AppTheme.primaryColor.withValues(alpha: 0.8), AppTheme.primaryVariant]
                              : [AppTheme.errorColor.withValues(alpha: 0.8), const Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + Relationship
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contactName,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (contactRelation.isNotEmpty)
                        Text(
                          contactRelation,
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, color: _statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Reason + Time ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reason: ${request.reasonLabel}',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (request.recoveryCodeProvided) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.key_rounded, size: 10, color: AppTheme.primaryColor),
                              SizedBox(width: 3),
                              Text(
                                'Code verified',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Time remaining / status date
                if (_timeInfo.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        request.isPending ? Icons.timer_outlined : Icons.calendar_today_outlined,
                        size: 13,
                        color: request.isPending ? const Color(0xFFF59E0B) : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _timeInfo,
                        style: TextStyle(
                          color: request.isPending ? const Color(0xFFF59E0B) : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Actions ──────────────────────────────────────────
          Divider(
            height: 1,
            color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                if (request.isPending) ...[
                  Expanded(
                    child: TextButton.icon(
                      onPressed: isActionLoading ? null : onDeny,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isActionLoading ? AppTheme.textMuted.withValues(alpha: 0.4) : AppTheme.errorColor,
                      ),
                      label: Text(
                        'Deny',
                        style: TextStyle(
                          color: isActionLoading ? AppTheme.textMuted.withValues(alpha: 0.4) : AppTheme.errorColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: isActionLoading ? null : onApprove,
                      icon: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: isActionLoading ? AppTheme.textMuted.withValues(alpha: 0.4) : AppTheme.primaryColor,
                      ),
                      label: Text(
                        'Approve',
                        style: TextStyle(
                          color: isActionLoading ? AppTheme.textMuted.withValues(alpha: 0.4) : AppTheme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                if (request.isApproved)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onViewReport,
                      icon: const Icon(Icons.assessment_outlined, size: 16, color: AppTheme.primaryVariant),
                      label: const Text(
                        'View Estate Report',
                        style: TextStyle(
                          color: AppTheme.primaryVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (request.isDenied)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'This request has been denied',
                          style: TextStyle(
                            color: AppTheme.textMuted.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
