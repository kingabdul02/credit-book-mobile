import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/insights_entity.dart';

class SummaryCards extends StatelessWidget {
  final InsightSummaryEntity summary;

  const SummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            context: context,
            title: 'Total Lent',
            amount: summary.totalLent,
            iconColor: Colors.green,
            iconData: Icons.arrow_upward_rounded,
            amountColor: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            context: context,
            title: 'Total Borrowed',
            amount: summary.totalBorrowed,
            iconColor: Colors.red,
            iconData: Icons.arrow_downward_rounded,
            amountColor: Colors.red.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required double amount,
    required Color iconColor,
    required IconData iconData,
    required Color amountColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.1)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency.format(amount),
            style: TextStyle(
              color: amountColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
