import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/all_debts_bloc.dart';
import '../../domain/entities/debt_with_contact_entity.dart';

class AllDebtsScreen extends StatefulWidget {
  final String initialFilter; // 'all', 'pending', 'settled'
  final String initialTypeFilter; // 'all', 'receivable', 'payable'

  const AllDebtsScreen({
    super.key,
    this.initialFilter = 'all',
    this.initialTypeFilter = 'all',
  });

  @override
  State<AllDebtsScreen> createState() => _AllDebtsScreenState();
}

class _AllDebtsScreenState extends State<AllDebtsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialFilter == 'pending') {
      initialIndex = 1;
    } else if (widget.initialFilter == 'settled') {
      initialIndex = 2;
    }
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
    context.read<AllDebtsBloc>().add(
      LoadAllDebts(
        statusFilter: widget.initialFilter,
        typeFilter: widget.initialTypeFilter,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final filters = ['all', 'pending', 'settled'];
      context.read<AllDebtsBloc>().add(
        FilterDebts(filters[_tabController.index]),
      );
    }
  }

  String _getTitle(AllDebtsState state) {
    if (state is AllDebtsLoaded) {
      if (state.typeFilter == 'receivable') {
        if (state.currentFilter == 'pending') return 'Pending Receivables';
        if (state.currentFilter == 'settled') return 'Settled Receivables';
        return 'Receivables';
      }
      if (state.typeFilter == 'payable') {
        if (state.currentFilter == 'pending') return 'Pending Payables';
        if (state.currentFilter == 'settled') return 'Settled Payables';
        return 'Payables';
      }
      if (state.currentFilter == 'pending') return 'Pending Debts';
      if (state.currentFilter == 'settled') return 'Settled Debts';
    } else {
      if (widget.initialTypeFilter == 'receivable') return 'Pending Receivables';
      if (widget.initialTypeFilter == 'payable') return 'Pending Payables';
      if (widget.initialFilter == 'pending') return 'Pending Debts';
      if (widget.initialFilter == 'settled') return 'Settled Debts';
    }
    return 'All Debts';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AllDebtsBloc, AllDebtsState>(
      listener: (context, state) {
        if (state is PaymentRecorded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully! ✓'),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is PaymentFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorHandler.getFriendlyMessage(state.message)),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<AllDebtsBloc, AllDebtsState>(
        builder: (context, state) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDark
                ? AppTheme.darkBackground
                : const Color(0xFFF8F9FA),
            appBar: CustomAppBar(
              title: _getTitle(state),
            ),
            body: Column(
              children: [
                // Search Bar
                Container(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      context.read<AllDebtsBloc>().add(SearchDebts(query));
                    },
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, note, or category...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextSecondary.withValues(alpha: 0.6)
                            : AppTheme.textMuted.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<AllDebtsBloc>().add(SearchDebts(''));
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isDark
                            ? const BorderSide(color: AppTheme.darkBorder)
                            : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isDark
                            ? const BorderSide(color: AppTheme.darkBorder)
                            : BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // Tab Bar
                Container(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  child: state is AllDebtsLoaded
                      ? TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          dividerHeight: 0,
                          indicatorColor: AppTheme.primaryColor,
                          indicatorWeight: 3,
                          labelColor: AppTheme.primaryColor,
                          unselectedLabelColor: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textMuted,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: [
                            Tab(text: 'All (${state.filteredTotalCount})'),
                            Tab(text: 'Pending (${state.filteredPendingCount})'),
                            Tab(text: 'Settled (${state.filteredSettledCount})'),
                          ],
                        )
                      : TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          dividerHeight: 0,
                          indicatorColor: AppTheme.primaryColor,
                          labelColor: AppTheme.primaryColor,
                          unselectedLabelColor: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textMuted,
                          tabs: const [
                            Tab(text: 'All'),
                            Tab(text: 'Pending'),
                            Tab(text: 'Settled'),
                          ],
                        ),
                ),

                // Content
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is AllDebtsInitial ||
                          state is AllDebtsLoading ||
                          state is PaymentRecording ||
                          state is PaymentRecorded) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is AllDebtsError) {
                        return AppErrorView(
                          error: state.message,
                          onRetry: () {
                            context.read<AllDebtsBloc>().add(
                              LoadAllDebts(
                                statusFilter: widget.initialFilter,
                                typeFilter: widget.initialTypeFilter,
                              ),
                            );
                          },
                        );
                      }

                      if (state is AllDebtsLoaded) {
                        return Column(
                          children: [
                            // Summary Cards & Quick Type Toggles (only show on Pending and Settled tabs)
                            if (_tabController.index != 0)
                              _buildSummarySection(state),

                            // Type Filter Pills
                            _buildTypeFilterPills(state),

                            // Debt List
                            Expanded(
                              child: RefreshIndicator(
                                color: AppTheme.primaryColor,
                                onRefresh: () async {
                                  context.read<AllDebtsBloc>().add(
                                    LoadAllDebts(
                                      statusFilter: state.currentFilter,
                                      typeFilter: state.typeFilter,
                                      forceRefresh: true,
                                    ),
                                  );
                                },
                                child: state.filteredDebts.isEmpty
                                    ? ListView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          _buildEmptyState(
                                            state.searchQuery,
                                            state.typeFilter,
                                          ),
                                        ],
                                      )
                                    : ListView.separated(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(16),
                                        itemCount: state.filteredDebts.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          return _buildDebtCard(
                                                context,
                                                state.filteredDebts[index],
                                              )
                                              .animate()
                                              .fadeIn(
                                                delay: Duration(
                                                  milliseconds: 50 * index,
                                                ),
                                              )
                                              .slideY(begin: 0.1, end: 0);
                                        },
                                      ),
                              ),
                            ),
                          ],
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeFilterPills(AllDebtsLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget buildPill(String title, String type, int count, Color color) {
      final isSelected = state.typeFilter == type;
      return GestureDetector(
        onTap: () {
          context.read<AllDebtsBloc>().add(FilterDebtsByType(type));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : (isDark ? AppTheme.darkBackground : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark
                      ? AppTheme.darkBorder
                      : AppTheme.textMuted.withValues(alpha: 0.25)),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? AppTheme.darkSurface : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPending = state.currentFilter == 'pending';
    final isSettled = state.currentFilter == 'settled';

    final totalCount = isPending
        ? state.pendingCount
        : (isSettled ? state.settledCount : state.allDebts.length);

    final receivableCount = isPending
        ? state.allDebts.where((d) => d.isTheyOweMe && d.isPending).length
        : (isSettled
            ? state.allDebts.where((d) => d.isTheyOweMe && d.isSettled).length
            : state.allDebts.where((d) => d.isTheyOweMe).length);

    final payableCount = isPending
        ? state.allDebts.where((d) => d.isIOweThem && d.isPending).length
        : (isSettled
            ? state.allDebts.where((d) => d.isIOweThem && d.isSettled).length
            : state.allDebts.where((d) => d.isIOweThem).length);

    return Container(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            buildPill(
              'All Debts',
              'all',
              totalCount,
              isDark ? AppTheme.primaryColor : AppTheme.textDark,
            ),
            const SizedBox(width: 8),
            buildPill(
              'Receivables (Owed Me)',
              'receivable',
              receivableCount,
              AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            buildPill(
              'Payables (I Owe)',
              'payable',
              payableCount,
              AppTheme.errorColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(AllDebtsLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPayableSelected = state.typeFilter == 'payable';
    final isReceivableSelected = state.typeFilter == 'receivable';

    return Container(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              state.currentFilter == 'all' ? 'Total Pending' : 'I Owe',
              state.currentFilter == 'all'
                  ? state.totalPending
                  : state.currentFilterIOwe,
              AppTheme.errorColor,
              Icons.arrow_upward_rounded,
              isSelected: isPayableSelected,
              onTap: () {
                final next = isPayableSelected ? 'all' : 'payable';
                context.read<AllDebtsBloc>().add(FilterDebtsByType(next));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              state.currentFilter == 'all' ? 'Total Settled' : 'They Owe Me',
              state.currentFilter == 'all'
                  ? state.totalSettled
                  : state.currentFilterTheyOweMe,
              AppTheme.primaryColor,
              Icons.arrow_downward_rounded,
              isSelected: isReceivableSelected,
              onTap: () {
                final next = isReceivableSelected ? 'all' : 'receivable';
                context.read<AllDebtsBloc>().add(FilterDebtsByType(next));
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.check_circle, color: color, size: 13),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCurrency.format(amount),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery, [String typeFilter = 'all']) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message = 'No debts found';
    String submessage = 'Start by adding a transaction';

    if (searchQuery.isNotEmpty) {
      message = 'No matching debts';
      submessage = 'Try adjusting your search';
    } else if (typeFilter == 'receivable') {
      message = 'No pending receivables found';
      submessage = 'You do not have any pending receivables in this tab';
    } else if (typeFilter == 'payable') {
      message = 'No pending payables found';
      submessage = 'You do not have any pending payables in this tab';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isEmpty
                  ? Icons.inbox_outlined
                  : Icons.search_off_rounded,
              size: 64,
              color: isDark
                  ? AppTheme.darkTextSecondary.withValues(alpha: 0.4)
                  : AppTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              submessage,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary.withValues(alpha: 0.8)
                    : AppTheme.textMuted.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildDebtCard(BuildContext context, DebtWithContactEntity debt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOweThem = debt.isIOweThem;
    final contactName = debt.contact?.fullName ?? 'Unknown';
    final initials = debt.contact?.initials ?? '?';

    // Determine colors and icons
    Color primaryColor = isIOweThem
        ? AppTheme.errorColor
        : AppTheme.primaryColor;
    Color bgColor = primaryColor.withValues(alpha: 0.1);
    IconData debtIcon = isIOweThem
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;

    // Status badge
    Color statusColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;
    String statusText = debt.statusLabel;
    if (debt.isSettled) {
      statusColor = AppTheme.primaryVariant;
    } else if (debt.isOverdue) {
      statusColor = AppTheme.errorColor;
    }

    // Parse dates for display
    String? formattedDate;
    String? formattedTime;
    if (debt.updatedAt.isNotEmpty) {
      try {
        final date = DateTime.parse(debt.updatedAt).toLocal();
        formattedDate = DateFormat('MMM dd, yyyy').format(date);
        formattedTime = DateFormat('hh:mm a').format(date);
      } catch (e) {
        // Handle parse error gracefully
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder
              : AppTheme.textMuted.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: debt.isPending
              ? () => _showSettleBottomSheet(context, debt)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        image: debt.contact?.profilePicture != null
                            ? DecorationImage(
                                image: NetworkImage(
                                  debt.contact!.profilePicture!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: debt.contact?.profilePicture == null
                          ? Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Contact Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contactName,
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(debtIcon, size: 12, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                isIOweThem ? 'I Owe' : 'Owes Me',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Amount Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.isSettled ? 'Total Amount' : 'Outstanding',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextSecondary.withValues(alpha: 0.8)
                                : AppTheme.textMuted.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          debt.isSettled
                              ? formatCurrency.format(debt.originalAmount)
                              : formatCurrency.format(debt.outstandingAmount),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    if (debt.isPending) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary.withValues(alpha: 0.8)
                                  : AppTheme.textMuted.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${debt.progressPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (debt.isSettled && formattedDate != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Settled on',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary.withValues(alpha: 0.8)
                                  : AppTheme.textMuted.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (formattedTime != null)
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextSecondary.withValues(
                                        alpha: 0.7,
                                      )
                                    : AppTheme.textMuted.withValues(
                                        alpha: 0.7,
                                      ),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),

                // Progress Bar (for pending debts)
                if (debt.isPending) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: debt.progressPercentage / 100,
                      backgroundColor: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.textMuted.withValues(
                              alpha: 0.1,
                            ),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],

                // Note/Category
                if (debt.note != null || debt.category != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    debt.note ?? debt.category ?? '',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary.withValues(alpha: 0.7)
                          : AppTheme.textMuted.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Action Button (for pending debts)
                if (debt.isPending) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showSettleBottomSheet(context, debt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isIOweThem
                                ? 'Record My Payment'
                                : 'Record Received',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettleBottomSheet(
    BuildContext context,
    DebtWithContactEntity debt,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          20,
                          24,
                          MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Row(
                                children: [
                                  Icon(
                                    Icons.payment_rounded,
                                    size: 24,
                                    color: debt.isIOweThem
                                        ? AppTheme.errorColor
                                        : AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Record Payment',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Settle debt with ${debt.contact?.fullName ?? "Unknown"}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Outstanding amount display
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.darkBackground
                                      : AppTheme.onBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isDark
                                      ? Border.all(color: AppTheme.darkBorder)
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Outstanding Amount',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      formatCurrency.format(
                                        debt.outstandingAmount,
                                      ),
                                      style: TextStyle(
                                        color: debt.isIOweThem
                                            ? AppTheme.errorColor
                                            : AppTheme.primaryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Amount field
                              Text(
                                'Payment Amount',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textDark,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '₦ ',
                                  prefixStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: debt.isIOweThem
                                        ? AppTheme.errorColor
                                        : AppTheme.primaryColor,
                                  ),
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary.withValues(
                                            alpha: 0.5,
                                          )
                                        : AppTheme.textMuted.withValues(
                                            alpha: 0.5,
                                          ),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? AppTheme.darkBackground
                                      : AppTheme.onBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: isDark
                                        ? const BorderSide(color: AppTheme.darkBorder)
                                        : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: isDark
                                        ? const BorderSide(color: AppTheme.darkBorder)
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: debt.isIOweThem
                                          ? AppTheme.errorColor
                                          : AppTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  final amount = double.tryParse(v);
                                  if (amount == null || amount <= 0) {
                                    return 'Enter a valid amount';
                                  }
                                  if (amount > debt.outstandingAmount) {
                                    return 'Amount cannot exceed ${formatCurrency.format(debt.outstandingAmount)}';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Note field
                              Text(
                                'Note (optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: noteController,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Partial payment via transfer',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary.withValues(
                                            alpha: 0.5,
                                          )
                                        : AppTheme.textMuted.withValues(
                                            alpha: 0.5,
                                          ),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? AppTheme.darkBackground
                                      : AppTheme.onBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: isDark
                                        ? const BorderSide(color: AppTheme.darkBorder)
                                        : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: isDark
                                        ? const BorderSide(color: AppTheme.darkBorder)
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: debt.isIOweThem
                                          ? AppTheme.errorColor
                                          : AppTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!.validate())
                                            return;

                                          setModalState(
                                            () => isSubmitting = true,
                                          );

                                          final amount = double.parse(
                                            amountController.text,
                                          );
                                          final note =
                                              noteController.text.isEmpty
                                              ? null
                                              : noteController.text;

                                          context.read<AllDebtsBloc>().add(
                                            RecordDebtPayment(
                                              debtId: debt.id,
                                              amount: amount,
                                              note: note,
                                            ),
                                          );

                                          Navigator.of(sheetContext).pop();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: debt.isIOweThem
                                        ? AppTheme.errorColor
                                        : AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      56,
                                    ),
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          debt.isIOweThem
                                              ? 'Record My Payment'
                                              : 'Record Received Payment',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
