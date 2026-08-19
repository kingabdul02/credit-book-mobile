import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/insights_entity.dart';

/// Generates a financial health tip derived from the insights data
/// since the API does not return a dedicated health_tip field.
class FinancialHealthTipCard extends StatelessWidget {
  final InsightsDataEntity data;

  const FinancialHealthTipCard({super.key, required this.data});

  String _buildTip() {
    if (data.topDebtors.isNotEmpty) {
      final name = data.topDebtors.first.contact.displayName;
      return '$name has an outstanding balance. Sending a gentle reminder could help improve your cash flow.';
    }
    if (data.summary.totalBorrowed > data.summary.totalLent) {
      return 'You currently owe more than you have lent. Consider settling your debts to maintain a healthy financial balance.';
    }
    if (data.repaymentRate.ratePercentage < 50) {
      return 'Your repayment rate is below 50%. Follow up with contacts to collect pending balances.';
    }
    return 'Great job! Keep tracking your transactions to stay on top of your finances.';
  }

  String _buildActionLabel() {
    if (data.topDebtors.isNotEmpty) return 'Send Reminders';
    return 'View Transactions';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
          const Text(
            'Financial Health Tip',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _buildTip(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                _buildActionLabel(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
