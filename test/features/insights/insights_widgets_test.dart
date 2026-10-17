import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creditbook/features/insights/domain/entities/insights_entity.dart';
import 'package:creditbook/features/insights/presentation/widgets/debt_distribution_chart.dart';
import 'package:creditbook/features/insights/presentation/widgets/cash_flow_chart.dart';

void main() {
  group('DebtDistributionChart', () {
    testWidgets('displays empty state when items is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebtDistributionChart(items: []),
          ),
        ),
      );

      expect(find.text('Debt Distribution'), findsOneWidget);
      expect(find.text('No category data available yet.'), findsOneWidget);
    });

    testWidgets('renders categories and percentages when items are provided', (tester) async {
      final items = [
        const DebtDistributionItem(category: 'Business', percentage: 70.0),
        const DebtDistributionItem(category: 'General', percentage: 30.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DebtDistributionChart(items: items),
            ),
          ),
        ),
      );

      expect(find.text('Debt Distribution'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('70%'), findsNWidgets(2)); // center "Top 70%" and list item "70%"
      expect(find.text('30%'), findsOneWidget);
    });
  });

  group('CashFlowChart', () {
    testWidgets('renders empty state when data is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CashFlowChart(data: []),
          ),
        ),
      );

      expect(find.text('No trend data available yet.'), findsOneWidget);
    });

    testWidgets('renders chart and legend when trend data is provided', (tester) async {
      final data = [
        const MonthlyTrendPoint(month: 'Mon', lent: 5000.0, borrowed: 0.0),
        const MonthlyTrendPoint(month: 'Tue', lent: 0.0, borrowed: 3000.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CashFlowChart(data: data),
          ),
        ),
      );

      expect(find.text('Cash Flow Trend'), findsOneWidget);
      expect(find.text('Lent'), findsOneWidget);
      expect(find.text('Borrowed'), findsOneWidget);
    });
  });
}
