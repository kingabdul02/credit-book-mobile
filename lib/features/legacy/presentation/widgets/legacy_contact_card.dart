import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/legacy_contact_entity.dart';

class LegacyContactCard extends StatelessWidget {
  final LegacyContactEntity contact;
  final bool isPrimary;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onResend;
  final VoidCallback onRevoke;

  const LegacyContactCard({
    super.key,
    required this.contact,
    required this.isPrimary,
    required this.isActionLoading,
    required this.onEdit,
    required this.onDelete,
    required this.onResend,
    required this.onRevoke,
  });

  Color get _statusColor {
    switch (contact.verificationStatus) {
      case 'VERIFIED':
        return AppTheme.primaryColor;
      case 'REVOKED':
        return AppTheme.errorColor;
      default:
        return const Color(0xFFF59E0B); // amber
    }
  }

  IconData get _statusIcon {
    switch (contact.verificationStatus) {
      case 'VERIFIED':
        return Icons.verified_rounded;
      case 'REVOKED':
        return Icons.block_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String get _statusLabel {
    switch (contact.verificationStatus) {
      case 'VERIFIED':
        return 'Verified';
      case 'REVOKED':
        return 'Revoked';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPrimary
                          ? [AppTheme.primaryColor.withValues(alpha: 0.8), AppTheme.primaryVariant]
                          : [AppTheme.secondaryColor.withValues(alpha: 0.8), const Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      contact.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
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
                        contact.fullName,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.relationship,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                          fontSize: 13,
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
                      Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Contact Details ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _InfoRow(icon: Icons.email_outlined, label: contact.email),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.phone_outlined, label: contact.phone),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Divider + Actions ────────────────────────────────
          Divider(
            height: 1,
            color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (contact.isPending)
                  _ActionButton(
                    icon: Icons.send_outlined,
                    label: 'Resend Email',
                    color: AppTheme.secondaryColor,
                    onTap: isActionLoading ? null : onResend,
                  ),
                if (contact.isVerified)
                  _ActionButton(
                    icon: Icons.block_outlined,
                    label: 'Revoke',
                    color: AppTheme.errorColor,
                    onTap: isActionLoading ? null : onRevoke,
                  ),
                const Spacer(),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                  onTap: isActionLoading ? null : onEdit,
                ),
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove',
                  color: AppTheme.errorColor,
                  onTap: isActionLoading ? null : onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: onTap == null ? AppTheme.textMuted.withValues(alpha: 0.4) : color),
      label: Text(
        label,
        style: TextStyle(
          color: onTap == null ? AppTheme.textMuted.withValues(alpha: 0.4) : color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
