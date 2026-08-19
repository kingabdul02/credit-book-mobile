// ─────────────────────────────────────────────────────────────
// Actual API response shape (GET /api/v1/analytics/insights):
// {
//   "insights": {
//     "summary": {
//       "total_lent": "20000.00",
//       "total_borrowed": "234000.00",
//       "total_collected": "0.00",
//       "total_repaid": "0.00"
//     },
//     "monthly_trends": [
//       { "month": "2026-06", "lent": "20000.00", "borrowed": "234000.00" }
//     ],
//     "top_debtors": [
//       { "contact": { "id": "...", "full_name": "...", "nickname": "...", "profile_picture": null }, "outstanding": "20000.00" }
//     ],
//     "top_creditors": [...same shape as top_debtors...],
//     "repayment_rate": { "total_debts": 4, "paid_debts": 0, "rate_percentage": 0 },
//     "category_breakdown": []
//   }
// }
// ─────────────────────────────────────────────────────────────

class InsightSummaryEntity {
  final double totalLent;
  final double totalBorrowed;
  final double totalCollected;
  final double totalRepaid;

  const InsightSummaryEntity({
    required this.totalLent,
    required this.totalBorrowed,
    required this.totalCollected,
    required this.totalRepaid,
  });
}

class MonthlyTrendPoint {
  final String month; // e.g. "2026-06"
  final double lent;
  final double borrowed;

  const MonthlyTrendPoint({
    required this.month,
    required this.lent,
    required this.borrowed,
  });

  /// Returns a short display label, e.g. "Jun"
  String get shortLabel {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthIdx = int.parse(parts[1]) - 1;
        return months[monthIdx];
      }
    } catch (_) {}
    return month;
  }
}

class DebtDistributionItem {
  final String category;
  final double percentage;

  const DebtDistributionItem({
    required this.category,
    required this.percentage,
  });
}

class ContactSummaryEntity {
  final String id;
  final String fullName;
  final String? nickname;
  final String? profilePicture;

  const ContactSummaryEntity({
    required this.id,
    required this.fullName,
    this.nickname,
    this.profilePicture,
  });

  String get displayName => nickname ?? fullName;

  String get initials {
    final name = fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class TopContactEntity {
  final ContactSummaryEntity contact;
  final double outstanding;

  const TopContactEntity({
    required this.contact,
    required this.outstanding,
  });
}

class RepaymentRateEntity {
  final int totalDebts;
  final int paidDebts;
  final double ratePercentage;

  const RepaymentRateEntity({
    required this.totalDebts,
    required this.paidDebts,
    required this.ratePercentage,
  });

  String get scoreLabel {
    if (ratePercentage >= 80) return 'High reliability score';
    if (ratePercentage >= 50) return 'Moderate reliability score';
    return 'Low reliability score';
  }
}

class InsightsDataEntity {
  final InsightSummaryEntity summary;
  final List<MonthlyTrendPoint> monthlyTrends;
  final List<TopContactEntity> topDebtors;
  final List<TopContactEntity> topCreditors;
  final RepaymentRateEntity repaymentRate;
  final List<DebtDistributionItem> categoryBreakdown;

  const InsightsDataEntity({
    required this.summary,
    required this.monthlyTrends,
    required this.topDebtors,
    required this.topCreditors,
    required this.repaymentRate,
    required this.categoryBreakdown,
  });
}
