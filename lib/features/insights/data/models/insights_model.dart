import '../../domain/entities/insights_entity.dart';

// ─────────────────────────────────────────────────────────────
// Models extend Domain Entities — fromJson factories map from
// the real API response shape under the "insights" key.
// ─────────────────────────────────────────────────────────────

class InsightSummaryModel extends InsightSummaryEntity {
  const InsightSummaryModel({
    required super.totalLent,
    required super.totalBorrowed,
    required super.totalCollected,
    required super.totalRepaid,
  });

  factory InsightSummaryModel.fromJson(Map<String, dynamic> json) {
    return InsightSummaryModel(
      totalLent: double.tryParse(json['total_lent']?.toString() ?? '0') ?? 0.0,
      totalBorrowed: double.tryParse(json['total_borrowed']?.toString() ?? '0') ?? 0.0,
      totalCollected: double.tryParse(json['total_collected']?.toString() ?? '0') ?? 0.0,
      totalRepaid: double.tryParse(json['total_repaid']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class MonthlyTrendPointModel extends MonthlyTrendPoint {
  const MonthlyTrendPointModel({
    required super.month,
    required super.lent,
    required super.borrowed,
  });

  factory MonthlyTrendPointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPointModel(
      month: json['month']?.toString() ?? '',
      lent: double.tryParse(json['lent']?.toString() ?? '0') ?? 0.0,
      borrowed: double.tryParse(json['borrowed']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DebtDistributionItemModel extends DebtDistributionItem {
  const DebtDistributionItemModel({
    required super.category,
    required super.percentage,
  });

  factory DebtDistributionItemModel.fromJson(Map<String, dynamic> json) {
    return DebtDistributionItemModel(
      category: json['category']?.toString() ?? '',
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ContactSummaryModel extends ContactSummaryEntity {
  const ContactSummaryModel({
    required super.id,
    required super.fullName,
    super.nickname,
    super.profilePicture,
  });

  factory ContactSummaryModel.fromJson(Map<String, dynamic> json) {
    return ContactSummaryModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}

class TopContactModel extends TopContactEntity {
  const TopContactModel({
    required super.contact,
    required super.outstanding,
  });

  factory TopContactModel.fromJson(Map<String, dynamic> json) {
    return TopContactModel(
      contact: ContactSummaryModel.fromJson(
        json['contact'] as Map<String, dynamic>? ?? {},
      ),
      outstanding: double.tryParse(json['outstanding']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class RepaymentRateModel extends RepaymentRateEntity {
  const RepaymentRateModel({
    required super.totalDebts,
    required super.paidDebts,
    required super.ratePercentage,
  });

  factory RepaymentRateModel.fromJson(Map<String, dynamic> json) {
    return RepaymentRateModel(
      totalDebts: (json['total_debts'] as num?)?.toInt() ?? 0,
      paidDebts: (json['paid_debts'] as num?)?.toInt() ?? 0,
      ratePercentage: (json['rate_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InsightsDataModel extends InsightsDataEntity {
  const InsightsDataModel({
    required super.summary,
    required super.monthlyTrends,
    required super.topDebtors,
    required super.topCreditors,
    required super.repaymentRate,
    required super.categoryBreakdown,
  });

  factory InsightsDataModel.fromJson(Map<String, dynamic> json) {
    // Response is wrapped under the "insights" key
    final root = json['insights'] as Map<String, dynamic>? ?? json;

    final summaryJson = root['summary'] as Map<String, dynamic>? ?? {};
    final trendsList = root['monthly_trends'] as List? ?? [];
    final topDebtorsList = root['top_debtors'] as List? ?? [];
    final topCreditorsList = root['top_creditors'] as List? ?? [];
    final repaymentJson = root['repayment_rate'] as Map<String, dynamic>? ?? {};
    final categoryList = root['category_breakdown'] as List? ?? [];

    var categoryItems = categoryList
        .map((e) => DebtDistributionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Fallback: If backend provided total_amount but percentage is 0.0 on all items
    final totalSum = categoryList.fold<double>(
      0.0,
      (sum, e) => sum + (double.tryParse((e as Map<String, dynamic>)['total_amount']?.toString() ?? '0') ?? 0.0),
    );
    if (totalSum > 0 && categoryItems.isNotEmpty && categoryItems.every((item) => item.percentage == 0.0)) {
      categoryItems = categoryList.map((e) {
        final map = e as Map<String, dynamic>;
        final amt = double.tryParse(map['total_amount']?.toString() ?? '0') ?? 0.0;
        final pct = double.parse(((amt / totalSum) * 100).toStringAsFixed(1));
        return DebtDistributionItemModel(
          category: map['category']?.toString() ?? '',
          percentage: pct,
        );
      }).toList();
    }

    return InsightsDataModel(
      summary: InsightSummaryModel.fromJson(summaryJson),
      monthlyTrends: trendsList
          .map((e) => MonthlyTrendPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topDebtors: topDebtorsList
          .map((e) => TopContactModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCreditors: topCreditorsList
          .map((e) => TopContactModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      repaymentRate: RepaymentRateModel.fromJson(repaymentJson),
      categoryBreakdown: categoryItems,
    );
  }
}
