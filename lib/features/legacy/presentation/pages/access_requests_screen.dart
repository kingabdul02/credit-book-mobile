import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/legacy_access_request_entity.dart';
import '../bloc/legacy_bloc.dart';
import '../widgets/access_request_card.dart';

class AccessRequestsScreen extends StatefulWidget {
  const AccessRequestsScreen({super.key});

  @override
  State<AccessRequestsScreen> createState() => _AccessRequestsScreenState();
}

class _AccessRequestsScreenState extends State<AccessRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<LegacyBloc>().add(LoadAccessRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleApprove(BuildContext context, LegacyAccessRequestEntity request) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Approve Access?',
        description:
            '${request.legacyContact?.fullName ?? 'This contact'} will gain read-only access to your debt records.\n\nThey can view people who owe you and people you owe.',
        confirmLabel: 'Approve Access',
        confirmColor: AppTheme.primaryVariant,
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppTheme.primaryColor,
        onConfirm: () {
          Navigator.pop(context);
          context.read<LegacyBloc>().add(ApproveAccessRequest(request.id));
        },
      ),
    );
  }

  void _handleDeny(BuildContext context, LegacyAccessRequestEntity request) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Deny Access?',
        description:
            '${request.legacyContact?.fullName ?? 'This contact'} will not be able to view your records. They can submit another request later.',
        confirmLabel: 'Deny Request',
        confirmColor: AppTheme.errorColor,
        icon: Icons.block_rounded,
        iconColor: AppTheme.errorColor,
        onConfirm: () {
          Navigator.pop(context);
          context.read<LegacyBloc>().add(DenyAccessRequest(request.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LegacyBloc, LegacyState>(
      listener: (context, state) {
        if (state is AccessRequestApproved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Access granted to ${state.request.legacyContact?.fullName ?? 'contact'}',
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
        } else if (state is AccessRequestDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Access request denied.', style: TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.textDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else if (state is AccessRequestError) {
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
      },
      builder: (context, state) {
        final isLoading = state is AccessRequestsLoading;
        final isActionLoading = state is AccessRequestActionLoading;

        List<LegacyAccessRequestEntity> allRequests = [];
        if (state is AccessRequestsLoaded) {
          allRequests = state.requests;
        } else if (state is AccessRequestActionLoading) {
          allRequests = state.requests;
        } else if (state is AccessRequestApproved) {
          allRequests = state.requests;
        } else if (state is AccessRequestDenied) {
          allRequests = state.requests;
        } else if (state is AccessRequestError) {
          allRequests = state.requests;
        }

        final pending = allRequests.where((r) => r.isPending).toList();
        final approved = allRequests.where((r) => r.isApproved).toList();
        final denied = allRequests.where((r) => r.isDenied).toList();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
          appBar: const CustomAppBar(title: 'Access Requests'),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : Column(
                  children: [
                    // ── Tab Bar ──────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: isDark ? AppTheme.darkBackground : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.all(3),
                        labelColor: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                        unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Pending'),
                                if (pending.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${pending.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Approved'),
                                if (approved.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${approved.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Tab(text: 'Denied'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Tab Body ─────────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _RequestsList(
                            requests: pending,
                            emptyIcon: Icons.inbox_rounded,
                            emptyTitle: 'No Pending Requests',
                            emptySubtitle: 'When someone requests access to your records, it will appear here.',
                            isActionLoading: isActionLoading,
                            onApprove: (r) => _handleApprove(context, r),
                            onDeny: (r) => _handleDeny(context, r),
                          ),
                          _RequestsList(
                            requests: approved,
                            emptyIcon: Icons.check_circle_outline_rounded,
                            emptyTitle: 'No Approved Requests',
                            emptySubtitle: 'Approved requests with active access will appear here.',
                            isActionLoading: isActionLoading,
                          ),
                          _RequestsList(
                            requests: denied,
                            emptyIcon: Icons.block_rounded,
                            emptyTitle: 'No Denied Requests',
                            emptySubtitle: 'Requests you have denied will appear here.',
                            isActionLoading: isActionLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─── Requests List ────────────────────────────────────────────────────────────

class _RequestsList extends StatelessWidget {
  final List<LegacyAccessRequestEntity> requests;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool isActionLoading;
  final void Function(LegacyAccessRequestEntity)? onApprove;
  final void Function(LegacyAccessRequestEntity)? onDeny;
  final void Function(LegacyAccessRequestEntity)? onViewReport;

  const _RequestsList({
    required this.requests,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.isActionLoading = false,
    this.onApprove,
    this.onDeny,
    this.onViewReport,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 20),
              Text(
                emptyTitle,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AccessRequestCard(
            request: request,
            isActionLoading: isActionLoading,
            onApprove: onApprove != null ? () => onApprove!(request) : null,
            onDeny: onDeny != null ? () => onDeny!(request) : null,
            onViewReport: onViewReport != null ? () => onViewReport!(request) : null,
          ),
        );
      },
    );
  }
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String description;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
    required this.iconColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.3)),
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
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: confirmColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
