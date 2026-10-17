import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/legacy_contact_entity.dart';
import '../bloc/legacy_bloc.dart';
import '../widgets/legacy_contact_card.dart';

class NextOfKinScreen extends StatefulWidget {
  const NextOfKinScreen({super.key});

  @override
  State<NextOfKinScreen> createState() => _NextOfKinScreenState();
}

class _NextOfKinScreenState extends State<NextOfKinScreen> {
  LegacySettingsEntity? _cachedSettings;
  List<LegacyContactEntity> _cachedContacts = [];

  @override
  void initState() {
    super.initState();
    context.read<LegacyBloc>().add(LoadLegacyData());
  }

  Future<void> _navigateAndRefresh(String path, {Map<String, dynamic>? extra}) async {
    await context.push(path, extra: extra);
    if (mounted) {
      context.read<LegacyBloc>().add(LoadLegacyData());
    }
  }

  void _handleStateChange(BuildContext context, LegacyState state) {
    if (state is LegacyLoaded) {
      _cachedSettings = state.settings;
      _cachedContacts = state.contacts;
    } else if (state is LegacyActionLoading) {
      _cachedSettings = state.settings;
      _cachedContacts = state.contacts;
    } else if (state is LegacyEnabled) {
      _cachedSettings = state.settings;
      _cachedContacts = state.contacts;
      if (state.recoveryCode != null) {
        _showRecoveryCodeDialog(context, state.recoveryCode!);
      }
    } else if (state is LegacyContactAdded) {
      _cachedSettings = state.settings;
      _cachedContacts = state.contacts;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nominee added! Verification email sent to ${state.contact.email}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else if (state is LegacyContactDeleted) {
      _cachedSettings = state.settings;
      _cachedContacts = state.contacts;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nominee removed.', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.textDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else if (state is LegacyVerificationSent) {
      _cachedSettings = state.settings;
      _cachedContacts = state.contacts;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification email resent!', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.primaryVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else if (state is LegacyError) {
      if (state.settings != null) {
        _cachedSettings = state.settings;
        _cachedContacts = state.contacts;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showRecoveryCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.key_rounded, color: AppTheme.primaryVariant, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Recovery Code',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save this code somewhere safe. It will NEVER be shown again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.textDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, color: AppTheme.textMuted, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryVariant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("I've Saved It", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToggleConfirm(BuildContext context, bool currentlyEnabled) {
    final bloc = context.read<LegacyBloc>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _LegacyToggleDialog(currentlyEnabled: currentlyEnabled),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LegacyBloc, LegacyState>(
      listener: _handleStateChange,
      builder: (context, state) {
        if (state is LegacyLoaded) {
          _cachedSettings = state.settings;
          _cachedContacts = state.contacts;
        } else if (state is LegacyActionLoading) {
          _cachedSettings = state.settings;
          _cachedContacts = state.contacts;
        } else if (state is LegacyEnabled) {
          _cachedSettings = state.settings;
          _cachedContacts = state.contacts;
        } else if (state is LegacyContactAdded) {
          _cachedSettings = state.settings;
          _cachedContacts = state.contacts;
        } else if (state is LegacyContactDeleted) {
          _cachedSettings = state.settings;
          _cachedContacts = state.contacts;
        } else if (state is LegacyVerificationSent) {
          _cachedSettings = state.settings;
          _cachedContacts = state.contacts;
        } else if (state is LegacyError && state.settings != null) {
          _cachedSettings = state.settings;
          _cachedContacts = state.contacts;
        }

        final settings = _cachedSettings;
        final contacts = _cachedContacts;
        final isActionLoading = state is LegacyActionLoading;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (settings == null) {
          if (state is LegacyError) {
            return Scaffold(
              backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
              appBar: const CustomAppBar(title: 'Next of Kin'),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.read<LegacyBloc>().add(LoadLegacyData()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
            appBar: const CustomAppBar(title: 'Next of Kin'),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }

        final primaryContact = contacts.where((c) => c.isPrimary).isNotEmpty
            ? contacts.firstWhere((c) => c.isPrimary)
            : null;
        final secondaryContacts = contacts.where((c) => !c.isPrimary).toList();

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
          appBar: const CustomAppBar(title: 'Next of Kin'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Banner ──────────────────────────────────────
                _HeroBanner(settings: settings, isActionLoading: isActionLoading, onToggle: () {
                  _showToggleConfirm(context, settings.legacyAccessEnabled);
                }),
                const SizedBox(height: 24),

                // ── Security Notice ──────────────────────────────────
                _SecurityNotice(settings: settings),
                const SizedBox(height: 16),

                // ── Access Requests Card ──────────────────────────────
                if (settings.legacyAccessEnabled)
                  GestureDetector(
                    onTap: () => _navigateAndRefresh('/access-requests'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    color: AppTheme.secondaryColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Access Requests',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Review and manage nominee access requests',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (settings?.legacyAccessEnabled == true) const SizedBox(height: 24),

                      // ── Primary Nominee ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PRIMARY NOMINEE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (primaryContact == null)
                            _AddButton(onTap: () => _navigateAndRefresh('/next-of-kin/add', extra: {'isPrimary': true, 'bloc': context.read<LegacyBloc>()})),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (primaryContact != null)
                        LegacyContactCard(
                          contact: primaryContact,
                          isPrimary: true,
                          isActionLoading: isActionLoading,
                          onEdit: () => _navigateAndRefresh('/next-of-kin/add', extra: {'contact': primaryContact, 'isPrimary': true, 'bloc': context.read<LegacyBloc>()}),
                          onDelete: () => _confirmDelete(context, primaryContact),
                          onResend: () => context.read<LegacyBloc>().add(ResendVerification(primaryContact.id)),
                          onRevoke: () => context.read<LegacyBloc>().add(RevokeLegacyContact(primaryContact.id)),
                        )
                      else
                        _EmptySlot(
                          label: 'No primary nominee added',
                          enabled: true,
                          onAdd: () => _navigateAndRefresh('/next-of-kin/add', extra: {'isPrimary': true, 'bloc': context.read<LegacyBloc>()}),
                        ),

                      const SizedBox(height: 28),

                      // ── Secondary Nominees ───────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SECONDARY NOMINEES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (secondaryContacts.length < 3)
                            _AddButton(onTap: () => _navigateAndRefresh('/next-of-kin/add', extra: {'isPrimary': false, 'bloc': context.read<LegacyBloc>()})),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (secondaryContacts.isEmpty)
                        _EmptySlot(
                          label: 'Add a secondary nominee (optional)',
                          enabled: true,
                          onAdd: () => _navigateAndRefresh('/next-of-kin/add', extra: {'isPrimary': false, 'bloc': context.read<LegacyBloc>()}),
                        )
                      else
                        ...secondaryContacts.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LegacyContactCard(
                                contact: c,
                                isPrimary: false,
                                isActionLoading: isActionLoading,
                                onEdit: () => _navigateAndRefresh('/next-of-kin/add', extra: {'contact': c, 'isPrimary': false, 'bloc': context.read<LegacyBloc>()}),
                                onDelete: () => _confirmDelete(context, c),
                                onResend: () => context.read<LegacyBloc>().add(ResendVerification(c.id)),
                                onRevoke: () => context.read<LegacyBloc>().add(RevokeLegacyContact(c.id)),
                              ),
                            )),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, LegacyContactEntity contact) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove ${contact.fullName}?',
          style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This person will no longer be a nominee on your account.',
          style: TextStyle(color: AppTheme.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LegacyBloc>().add(DeleteLegacyContact(contact.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final LegacySettingsEntity? settings;
  final bool isActionLoading;
  final VoidCallback onToggle;

  const _HeroBanner({required this.settings, required this.isActionLoading, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final enabled = settings?.legacyAccessEnabled ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF1a3a2e)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: enabled ? AppTheme.primaryColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: enabled ? AppTheme.primaryColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      enabled ? Icons.shield_rounded : Icons.shield_outlined,
                      color: enabled ? AppTheme.primaryColor : AppTheme.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      enabled ? 'Legacy Active' : 'Legacy Inactive',
                      style: TextStyle(
                        color: enabled ? AppTheme.primaryColor : AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isActionLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                )
              else
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 50,
                    height: 28,
                    decoration: BoxDecoration(
                      color: enabled ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Protect your\nfamily\'s legacy.',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Your nominees can securely access your CreditBook in case of an emergency.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.5),
          ),
          if (settings != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(label: '${settings!.contactsCount} Nominees', icon: Icons.people_outline_rounded),
                const SizedBox(width: 10),
                _StatChip(label: '${settings!.verifiedContactsCount} Verified', icon: Icons.verified_outlined),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  final LegacySettingsEntity? settings;
  const _SecurityNotice({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'End-to-End Protected',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  settings?.legacyAccessEnabled == true
                      ? 'Nominees can request access after ${settings!.legacyWaitingPeriodDays} days of account inactivity. They will be notified first.'
                      : 'Enable legacy access to allow trusted nominees to access your account in an emergency.',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onAdd;

  const _EmptySlot({required this.label, required this.enabled, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onAdd : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? (isDark
                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                    : AppTheme.primaryColor.withValues(alpha: 0.35))
                : (isDark
                    ? AppTheme.darkBorder
                    : AppTheme.textMuted.withValues(alpha: 0.2)),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_add_alt_1_outlined,
              color: enabled
                  ? AppTheme.primaryColor.withValues(alpha: 0.6)
                  : (isDark
                      ? AppTheme.darkTextSecondary.withValues(alpha: 0.4)
                      : AppTheme.textMuted.withValues(alpha: 0.4)),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              enabled ? label : 'Enable legacy access to add nominees',
              style: TextStyle(
                color: enabled
                    ? (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    : (isDark
                        ? AppTheme.darkTextSecondary.withValues(alpha: 0.5)
                        : AppTheme.textMuted.withValues(alpha: 0.5)),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyToggleDialog extends StatelessWidget {
  final bool currentlyEnabled;
  const _LegacyToggleDialog({required this.currentlyEnabled});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header gradient
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentlyEnabled
                      ? [AppTheme.errorColor.withValues(alpha: 0.8), AppTheme.errorColor]
                      : [AppTheme.primaryColor.withValues(alpha: 0.8), AppTheme.primaryVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentlyEnabled ? Icons.shield_outlined : Icons.shield_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentlyEnabled ? 'Disable Legacy Access?' : 'Enable Legacy Access?',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentlyEnabled
                        ? 'If you disable this feature, your nominees will lose the ability to request access to your account.'
                        : 'Secure your financial legacy by allowing trusted nominees to access your account if you are inactive.',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  if (!currentlyEnabled) ...[
                    const _FeatureRow(icon: Icons.timer_outlined, text: 'Access is only granted after a waiting period of inactivity.'),
                    const SizedBox(height: 12),
                    const _FeatureRow(icon: Icons.notifications_active_outlined, text: 'You will be notified immediately when a request is made.'),
                    const SizedBox(height: 12),
                    const _FeatureRow(icon: Icons.block_outlined, text: 'You can cancel any pending request before the waiting period ends.'),
                    const SizedBox(height: 24),
                  ] else ...[
                    const _FeatureRow(icon: Icons.warning_amber_rounded, text: 'Existing nominees will remain on your list but their access will be revoked.', isWarning: true),
                    const SizedBox(height: 24),
                  ],
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.textMuted.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (currentlyEnabled) {
                              context.read<LegacyBloc>().add(DisableLegacyAccess());
                            } else {
                              context.read<LegacyBloc>().add(EnableLegacyAccess());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: currentlyEnabled ? AppTheme.errorColor : AppTheme.primaryVariant,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            currentlyEnabled ? 'Disable' : 'Enable',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isWarning;

  const _FeatureRow({required this.icon, required this.text, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isWarning ? AppTheme.errorColor : AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: isWarning ? AppTheme.textDark : AppTheme.textMuted, fontSize: 13, height: 1.4, fontWeight: isWarning ? FontWeight.w500 : FontWeight.normal),
          ),
        ),
      ],
    );
  }
}
