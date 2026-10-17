import 'package:flutter_test/flutter_test.dart';
import 'package:creditbook/features/insights/data/models/insights_model.dart';

void main() {
  group('InsightsDataModel', () {
    test('correctly parses insights JSON with percentages', () {
      final json = {
        'insights': {
          'summary': {
            'total_lent': '15000.00',
            'total_borrowed': '5000.00',
            'total_collected': '2000.00',
            'total_repaid': '1000.00',
          },
          'monthly_trends': [
            {'month': 'Mon', 'lent': '5000.00', 'borrowed': '0.00'},
            {'month': 'Tue', 'lent': '10000.00', 'borrowed': '5000.00'},
          ],
          'top_debtors': [],
          'top_creditors': [],
          'repayment_rate': {
            'total_debts': 3,
            'paid_debts': 1,
            'rate_percentage': 33.3,
          },
          'category_breakdown': [
            {'category': 'Business', 'count': 1, 'total_amount': '10000.00', 'percentage': 66.7},
            {'category': 'General', 'count': 1, 'total_amount': '5000.00', 'percentage': 33.3},
          ],
        }
      };

      final model = InsightsDataModel.fromJson(json);

      expect(model.summary.totalLent, 15000.0);
      expect(model.summary.totalBorrowed, 5000.0);
      expect(model.monthlyTrends.length, 2);
      expect(model.monthlyTrends[0].shortLabel, 'Mon');
      expect(model.categoryBreakdown.length, 2);
      expect(model.categoryBreakdown[0].category, 'Business');
      expect(model.categoryBreakdown[0].percentage, 66.7);
      expect(model.categoryBreakdown[1].category, 'General');
      expect(model.categoryBreakdown[1].percentage, 33.3);
    });

    test('calculates fallback percentage if percentage is missing from category_breakdown', () {
      final json = {
        'insights': {
          'summary': {
            'total_lent': '10000.00',
            'total_borrowed': '0.00',
            'total_collected': '0.00',
            'total_repaid': '0.00',
          },
          'monthly_trends': [],
          'top_debtors': [],
          'top_creditors': [],
          'repayment_rate': {
            'total_debts': 2,
            'paid_debts': 0,
            'rate_percentage': 0.0,
          },
          'category_breakdown': [
            {'category': 'Personal', 'count': 1, 'total_amount': '7500.00'},
            {'category': 'General', 'count': 1, 'total_amount': '2500.00'},
          ],
        }
      };

      final model = InsightsDataModel.fromJson(json);

      expect(model.categoryBreakdown.length, 2);
      expect(model.categoryBreakdown[0].category, 'Personal');
      expect(model.categoryBreakdown[0].percentage, 75.0);
      expect(model.categoryBreakdown[1].category, 'General');
      expect(model.categoryBreakdown[1].percentage, 25.0);
    });
  });
}
