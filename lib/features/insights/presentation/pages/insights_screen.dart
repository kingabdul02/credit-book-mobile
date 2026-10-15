import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../bloc/insights_bloc.dart';
import '../bloc/insights_event.dart';
import '../bloc/insights_state.dart';
import '../widgets/summary_cards.dart';
import '../widgets/cash_flow_chart.dart';
import '../widgets/debt_distribution_chart.dart';
import '../widgets/top_debtor_card.dart';
import '../widgets/repayment_rate_card.dart';
import '../widgets/financial_health_tip_card.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InsightsBloc>().add(const FetchInsightsData(timeframe: 'monthly'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.onBackground,
      appBar: CustomAppBar(
        title: 'Insights',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppTheme.textDark),
            onPressed: () {
              context.read<InsightsBloc>().add(const FetchInsightsData(timeframe: 'monthly'));
            },
          ),
        ],
      ),
      body: BlocBuilder<InsightsBloc, InsightsState>(
        builder: (context, state) {
          if (state is InsightsLoading || state is InsightsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InsightsError) {
            return AppErrorView(
              error: state.message,
              onRetry: () => context.read<InsightsBloc>().add(
                FetchInsightsData(timeframe: state.currentTimeframe),
              ),
            );
          }

          if (state is InsightsLoaded) {
            final data = state.data;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<InsightsBloc>().add(
                  FetchInsightsData(timeframe: state.currentTimeframe),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSegmentControl(context, state.currentTimeframe),
                    const SizedBox(height: 24),
                    SummaryCards(summary: data.summary),
                    const SizedBox(height: 24),
                    CashFlowChart(data: data.monthlyTrends),
                    const SizedBox(height: 24),
                    DebtDistributionChart(items: data.categoryBreakdown),
                    const SizedBox(height: 24),
                    TopContactsCard(
                      topDebtors: data.topDebtors,
                      topCreditors: data.topCreditors,
                    ),
                    const SizedBox(height: 24),
                    RepaymentRateCard(entity: data.repaymentRate),
                    const SizedBox(height: 24),
                    FinancialHealthTipCard(data: data),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildSegmentControl(BuildContext context, String currentVal) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSegmentButton(context, 'weekly', currentVal)),
          Expanded(child: _buildSegmentButton(context, 'monthly', currentVal)),
          Expanded(child: _buildSegmentButton(context, 'yearly', currentVal)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(BuildContext context, String value, String currentVal) {
    final isSelected = value == currentVal;
    final label = '${value[0].toUpperCase()}${value.substring(1)}'; // "weekly" → "Weekly"
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.read<InsightsBloc>().add(FetchInsightsData(timeframe: value));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.textDark : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
