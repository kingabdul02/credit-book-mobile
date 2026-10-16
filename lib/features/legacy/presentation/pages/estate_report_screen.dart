import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/legacy_access_request_entity.dart';
import '../bloc/legacy_bloc.dart';

class EstateReportScreen extends StatefulWidget {
  final String requestId;

  const EstateReportScreen({super.key, required this.requestId});

  @override
  State<EstateReportScreen> createState() => _EstateReportScreenState();
}

class _EstateReportScreenState extends State<EstateReportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LegacyBloc>().add(LoadEstateReport(widget.requestId));
  }

  String _formatCurrency(double amount, String currency) {
    final symbol = currency == 'NGN' ? '₦' : currency == 'USD' ? '\$' : currency;
    final formatted = amount.abs().toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$symbol$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
      appBar: const CustomAppBar(title: 'Estate Report'),
      body: BlocBuilder<LegacyBloc, LegacyState>(
        builder: (context, state) {
          if (state is EstateReportLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 20),
                  Text(
                    'Loading estate report...',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is EstateReportError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Unable to Load Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<LegacyBloc>().add(LoadEstateReport(widget.requestId)),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryVariant,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is EstateReportLoaded) {
            final report = state.report;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Account Owner Header ──────────────────────
                  _AccountOwnerCard(
                    name: report.accountOwner.name,
                    email: report.accountOwner.email,
                    generatedAt: report.generatedAt,
                  ),
                  const SizedBox(height: 20),

                  // ── Net Position Card ─────────────────────────
                  _NetPositionCard(
                    totalReceivables: report.totalReceivables,
                    totalPayables: report.totalPayables,
                    netPosition: report.netPosition,
                    currency: report.currency,
                    formatCurrency: _formatCurrency,
                  ),
                  const SizedBox(height: 24),

                  // ── Read-Only Notice ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.secondaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.secondaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, color: AppTheme.secondaryColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Read-only access. You cannot modify any records.',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextPrimary.withValues(alpha: 0.9) : AppTheme.textDark.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Receivables Section ───────────────────────
                  _SectionHeader(
                    title: 'People Owe Them',
                    subtitle: 'Money owed to the account owner',
                    icon: Icons.arrow_downward_rounded,
                    color: AppTheme.primaryColor,
                    total: _formatCurrency(report.totalReceivables, report.currency),
                    count: report.receivableItems.length,
                  ),
                  const SizedBox(height: 12),
                  if (report.receivableItems.isEmpty)
                    _EmptyDebtSection(
                      message: 'No outstanding receivables',
                      icon: Icons.check_circle_outline_rounded,
                    )
                  else
                    ...report.receivableItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DebtItemCard(
                            item: item,
                            currency: report.currency,
                            formatCurrency: _formatCurrency,
                            isReceivable: true,
                          ),
                        )),
                  const SizedBox(height: 24),

                  // ── Payables Section ──────────────────────────
                  _SectionHeader(
                    title: 'They Owe Others',
                    subtitle: 'Money owed by the account owner',
                    icon: Icons.arrow_upward_rounded,
                    color: AppTheme.errorColor,
                    total: _formatCurrency(report.totalPayables, report.currency),
                    count: report.payableItems.length,
                  ),
                  const SizedBox(height: 12),
                  if (report.payableItems.isEmpty)
                    _EmptyDebtSection(
                      message: 'No outstanding payables',
                      icon: Icons.check_circle_outline_rounded,
                    )
                  else
                    ...report.payableItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DebtItemCard(
                            item: item,
                            currency: report.currency,
                            formatCurrency: _formatCurrency,
                            isReceivable: false,
                          ),
                        )),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _AccountOwnerCard extends StatelessWidget {
  final String name;
  final String email;
  final String generatedAt;

  const _AccountOwnerCard({
    required this.name,
    required this.email,
    required this.generatedAt,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = '';
    final date = DateTime.tryParse(generatedAt);
    if (date != null) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      formattedDate = '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF1a3a2e)],
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.white.withValues(alpha: 0.6), size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Generated $formattedDate',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NetPositionCard extends StatelessWidget {
  final double totalReceivables;
  final double totalPayables;
  final double netPosition;
  final String currency;
  final String Function(double, String) formatCurrency;

  const _NetPositionCard({
    required this.totalReceivables,
    required this.totalPayables,
    required this.netPosition,
    required this.currency,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = netPosition >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Net Position
          Text(
            'Net Position',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${isPositive ? '+' : '-'}${formatCurrency(netPosition.abs(), currency)}',
            style: TextStyle(
              color: isPositive ? AppTheme.primaryColor : AppTheme.errorColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? AppTheme.primaryColor : AppTheme.errorColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPositive ? 'Net Positive' : 'Net Negative',
              style: TextStyle(
                color: isPositive ? AppTheme.primaryColor : AppTheme.errorColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Breakdown row
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Receivables',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totalReceivables, currency),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.errorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Payables',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totalPayables, currency),
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String total;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.total,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              total,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '$count ${count == 1 ? 'entry' : 'entries'}',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DebtItemCard extends StatelessWidget {
  final EstateDebtItemEntity item;
  final String currency;
  final String Function(double, String) formatCurrency;
  final bool isReceivable;

  const _DebtItemCard({
    required this.item,
    required this.currency,
    required this.formatCurrency,
    required this.isReceivable,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isReceivable ? AppTheme.primaryColor : AppTheme.errorColor;
    final initials = _getInitials(item.contactName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.7), color],
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
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + Note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.contactName,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (item.note != null && item.note!.isNotEmpty)
                  Text(
                    item.note!,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(item.amount, item.currency),
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                isReceivable ? 'owes them' : 'they owe',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _EmptyDebtSection extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyDebtSection({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
