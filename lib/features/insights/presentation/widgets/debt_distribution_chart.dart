import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/insights_entity.dart';

class DebtDistributionChart extends StatelessWidget {
  final List<DebtDistributionItem> items;

  const DebtDistributionChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debt Distribution',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No category data available yet.',
                  style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final colors = [
      isDark ? const Color(0xFF818CF8) : AppTheme.textDark,
      AppTheme.primaryColor,
      isDark ? const Color(0xFF64748B) : Colors.grey.shade300,
      Colors.orange,
      Colors.purple,
    ];

    return Container(
      padding: const EdgeInsets.all(24),
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
          Text(
            'Debt Distribution',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 45,
                        sections: items.asMap().entries.map((e) {
                          return PieChartSectionData(
                            color: colors[e.key % colors.length],
                            value: e.value.percentage,
                            title: '',
                            radius: 12,
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Top',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${items[0].percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: items.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[e.key % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value.category,
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${e.value.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
