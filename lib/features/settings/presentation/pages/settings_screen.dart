import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/services/transaction_pin_service.dart';
import '../../../../core/services/face_auth_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/sync_status_model.dart';
import '../widgets/set_transaction_pin_modal.dart';
import '../widgets/reset_transaction_pin_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentIndex = 3;
  bool _hasFaceSet = false;
  bool _hasPinSet = false;
  SyncStatusModel _syncStatus = SyncStatusModel.empty;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
    _loadSyncStatus();
    _loadFaceStatus();
  }

  Future<void> _loadFaceStatus() async {
    final has = await FaceAuthService.isFaceRegistered();
    if (mounted) setState(() => _hasFaceSet = has);
  }

  Future<void> _loadPinStatus() async {
    final has = await TransactionPinService.hasPin();
    if (mounted) setState(() => _hasPinSet = has);
  }

  Future<void> _loadSyncStatus() async {
    final status = await SyncService.getStatus();
    if (mounted) setState(() => _syncStatus = status);
  }

  Future<void> _handleSyncTap() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final status = await SyncService.triggerSync();
    if (mounted) setState(() {
      _syncStatus = status;
      _isSyncing = false;
    });
  }

  Future<void> _handleTransactionPinTap() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _hasPinSet ? const ResetTransactionPinModal() : const SetTransactionPinModal(),
      ),
    );
    if (result == true) _loadPinStatus();
  }

  Future<void> _handleBiometricTap() async {
    final result = await context.push<bool>('/settings/face-setup');
    if (result == true) _loadFaceStatus();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppTheme.textDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of CreditBook?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(LogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthSuccess ? authState.user : null;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          context.go('/auth');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ACCOUNT'),
            _buildSectionContainer(
              children: [
                _buildListTile(
                  leadingWidget: UserAvatar(
                    avatarUrl: user?.avatarUrl,
                    radius: 18,
                  ),
                  icon: Icons.person_outline,
                  title: 'Personal Profile',
                  subtitle: user?.name.isNotEmpty == true ? user!.name : 'Set up your profile',
                  onTap: () => context.push('/profile'),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.cloud_queue,
                  title: 'Cloud Sync',
                  onTap: _handleSyncTap,
                  subtitleWidget: _isSyncing
                      ? Row(
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 6),
                            const Text('Syncing…', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _syncStatus.hasConflicts
                                    ? AppTheme.errorColor
                                    : _syncStatus.isStale
                                        ? Colors.orange
                                        : AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _syncStatus.hasConflicts
                                  ? '${_syncStatus.conflictCount} conflict(s) — tap to resolve'
                                  : 'Active • ${_syncStatus.formattedLastSync}',
                              style: TextStyle(
                                color: _syncStatus.hasConflicts ? AppTheme.errorColor : AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('SECURITY'),
            _buildSectionContainer(
              children: [
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: 'Transaction PIN',
                  subtitle: _hasPinSet ? 'PIN configured ✓' : 'Tap to set a 4-digit PIN',
                  subtitleColor: _hasPinSet ? AppTheme.primaryColor : null,
                  onTap: _handleTransactionPinTap,
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Login',
                  subtitle: _hasFaceSet ? 'Face ID registered ✓' : 'Tap to register your face',
                  subtitleColor: _hasFaceSet ? AppTheme.primaryColor : null,
                  onTap: _handleBiometricTap,
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.shield_outlined,
                  title: 'Two-Factor Authentication',
                  subtitleWidget: const Text(
                    'Currently Disabled',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.family_restroom_rounded,
                  title: 'Next of Kin',
                  subtitle: 'Manage your nominees & legacy access',
                  onTap: () => context.push('/next-of-kin'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Legacy',
                      style: TextStyle(color: AppTheme.primaryVariant, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.assignment_ind_outlined,
                  title: 'I am a Nominee',
                  subtitle: 'Submit a legacy access request',
                  onTap: () => context.push('/submit-access-request'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('PREFERENCES'),
            _buildSectionContainer(
              children: [
                _buildListTile(
                  icon: Icons.payments_outlined,
                  title: 'Primary Currency',
                  subtitle: 'NGN - Nigerian Naira (₦)',
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme Mode',
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryVariant.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Text('Light', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Dark', style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.5), fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 32),
            // _buildSectionTitle('DATA MANAGEMENT'),
            // _buildSectionContainer(
            //   children: [
            //     _buildListTile(
            //       icon: Icons.download_outlined,
            //       title: 'Export Data',
            //       subtitle: 'CSV, PDF, or JSON format',
            //     ),
            //     _buildDivider(),
            //     _buildListTile(
            //       icon: Icons.upload_outlined,
            //       title: 'Import Backup',
            //       subtitle: 'Restore from local or cloud file',
            //     ),
            //   ],
            // ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: authState is AuthLoading ? null : _handleLogout,
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.2)),
                  ),
                ),
                child: authState is AuthLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.errorColor),
                        ),
                      )
                    : const Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'CreditBook v2.4.1 (Build 108)',
                style: TextStyle(
                  color: AppTheme.textDark.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.textDark.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.textMuted.withValues(alpha: 0.1),
      indent: 64, // Aligned with the text
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? leadingWidget,
    Widget? trailing,
    Color? subtitleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            leadingWidget ??
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.primaryVariant, size: 20),
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null || subtitleWidget != null) ...[
                    const SizedBox(height: 4),
                    subtitleWidget ??
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: subtitleColor ?? AppTheme.textDark.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing else const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
