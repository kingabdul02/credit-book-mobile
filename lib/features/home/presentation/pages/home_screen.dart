import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/services/sync_service.dart';
import 'package:creditbook/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:creditbook/features/notifications/presentation/bloc/notification_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Search & Filter State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  late final _syncSub = SyncService.onSyncComplete.listen((_) {
    if (mounted) {
      context.read<HomeBloc>().add(LoadDashboardRequested());
      context.read<NotificationCubit>().loadNotifications();
    }
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationCubit>().loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _syncSub.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    return transactions.where((tx) {
      // Apply Search
      final query = _searchController.text.toLowerCase();
      final name = (tx.debt?.contact?.fullName ?? '').toLowerCase();
      if (query.isNotEmpty && !name.contains(query)) {
        return false;
      }

      // Apply Filter
      if (_selectedFilter != 'All') {
        final status = tx.debt?.statusLabel?.toUpperCase() ?? 'UNPAID';
        if (_selectedFilter == 'Received/Settled' &&
            !(status == 'RECEIVED' ||
                status == 'SETTLED' ||
                status == 'PAID')) {
          return false;
        }
        if (_selectedFilter == 'Unpaid' && status != 'UNPAID') {
          return false;
        }
        if (_selectedFilter == 'Pending' && status != 'PENDING') {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildFilterButton(String title) {
              final isSelected = _selectedFilter == title;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      setState(() => _selectedFilter = title);
                      setModalState(() {});
                      // Optional: Add a slight delay before closing for better UX
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) Navigator.pop(context);
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Row(
                        children: [
                          buildFilterButton('All'),
                          const SizedBox(width: 12),
                          buildFilterButton('Received/Settled'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          buildFilterButton('Unpaid'),
                          const SizedBox(width: 12),
                          buildFilterButton('Pending'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthSuccess ? authState.user : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        title: Row(
          children: [
            UserAvatar(
              avatarUrl: user?.avatarUrl,
              radius: 16,
              onTap: () => context.push('/profile'),
            ),
            const SizedBox(width: 12),
            Text(
              'CreditBook',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: const [
          NotificationBellButton(),
          SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeLoaded) {
            context.read<NotificationCubit>().loadNotifications();
          }
        },
        builder: (context, state) {
          if (state is HomeInitial || state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeError) {
            return AppErrorView(
              error: state.message,
              onRetry: () =>
                  context.read<HomeBloc>().add(LoadDashboardRequested()),
            );
          } else if (state is HomeLoaded) {
            final filteredTransactions = _getFilteredTransactions(
              state.dashboardData.recentTransactions,
            );

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(LoadDashboardRequested(forceRefresh: true));
                await context.read<NotificationCubit>().loadNotifications();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNetBalanceCard(state.dashboardData.metrics),
                    const SizedBox(height: 16),

                    // Quick Action: View All Debts
                    _buildQuickActionCard(
                      context,
                    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildReceivableCard(
                            state.dashboardData.metrics,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPayableCard(state.dashboardData.metrics),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (state.dashboardData.upcomingReminders.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upcoming Reminders',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'View All',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              state.dashboardData.upcomingReminders.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            return _buildReminderCard(
                                  state.dashboardData.upcomingReminders[index],
                                )
                                .animate()
                                .fadeIn(
                                  delay: Duration(milliseconds: 100 * index),
                                )
                                .slideX(begin: 0.1, end: 0);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isSearching)
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search by name...',
                                        hintStyle: TextStyle(
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        icon: Icon(
                                          Icons.search,
                                          size: 18,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                        ),
                                        suffixIcon:
                                            _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() {
                                                    _searchController.clear();
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = false;
                                      _searchController.clear();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideX(begin: 0.1, end: 0)
                        else
                          Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        if (!_isSearching)
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.filter_list_rounded,
                                  color: _selectedFilter != 'All'
                                      ? AppTheme.primaryColor
                                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                                  size: 20,
                                ),
                                onPressed: _showFilterBottomSheet,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = true;
                                  });
                                },
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),

                    if (filteredTransactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppTheme.textMuted.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found.',
                                style: TextStyle(
                                  color: AppTheme.textMuted.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTransactions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildTransactionCard(
                            filteredTransactions[index],
                          ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                        },
                      ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Download PDF Report coming soon!'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: AppTheme.textDark.withValues(alpha: 0.8),
                          ),
                        ),
                        child: const Text(
                          'Download PDF Report',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 80), // Padding for FAB
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton:
          FloatingActionButton(
            onPressed: () => context.push('/add-transaction'),
            backgroundColor: AppTheme.textDark,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ).animate().scale(
            delay: 600.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildNetBalanceCard(DashboardMetrics metrics) {
    final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final balance = double.tryParse(metrics.netBalance) ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            'Net Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance > 0 ? '+' : ''}${formatCurrency.format(balance)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: balance < 0
                  ? AppTheme.errorColor
                  : (balance > 0 ? AppTheme.primaryColor : (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark)),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: AppTheme.primaryVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Safe to Spend',
                  style: TextStyle(
                    color: AppTheme.primaryVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(curve: Curves.easeOutBack);
  }

  Widget _buildQuickActionCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/all-debts'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_list_bulleted_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'View All Debts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and settle pending debts quickly',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceivableCard(DashboardMetrics metrics) {
    final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final amount = double.tryParse(metrics.totalOwedToMe) ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/all-debts?filter=pending&type=receivable'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2)),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.south_west_rounded,
                      size: 20,
                      color: AppTheme.primaryVariant,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Receivable',
                        style: TextStyle(
                          color: AppTheme.primaryVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppTheme.primaryVariant.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'People Owe Me',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency.format(amount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPayableCard(DashboardMetrics metrics) {
    final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final amount = double.tryParse(metrics.totalIOwe) ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/all-debts?filter=pending&type=payable'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2)),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.north_east_rounded,
                      size: 20,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Payable',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppTheme.errorColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'I Owe People',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency.format(amount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildReminderCard(Reminder reminder) {
    final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final name = reminder.debt?.contact?.fullName ?? 'Unknown';
    final initials = name.isNotEmpty ? name.substring(0, 2).toUpperCase() : '?';
    // Dummy amount for now as it's not directly in reminder
    final amount = reminder.debt?.statusLabel == 'Unpaid' ? 15000.0 : 0.0;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.secondaryColor.withValues(
                  alpha: 0.15,
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Due Tomorrow', // Mocked due date for ui demo
                      style: TextStyle(
                        color: AppTheme.textDark.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency.format(amount),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Remind', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final amount = double.tryParse(transaction.amount) ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine status badge based on transaction properties
    String status = transaction.debt?.statusLabel?.toUpperCase() ?? 'UNPAID';
    Color statusColor = AppTheme.errorColor;
    Color statusBgColor = AppTheme.errorColor.withValues(alpha: 0.15);

    if (status == 'RECEIVED' || status == 'SETTLED' || status == 'PAID') {
      statusColor = AppTheme.primaryColor;
      statusBgColor = AppTheme.primaryColor.withValues(alpha: 0.2);
    } else if (status == 'PENDING') {
      statusColor = AppTheme.secondaryColor;
      statusBgColor = AppTheme.secondaryColor.withValues(alpha: 0.15);
    }

    // Determine icon
    IconData icon = Icons.person_outline;
    Color iconColor = AppTheme.secondaryColor;
    if (transaction.type == 'PAYMENT') {
      icon = Icons.payments_outlined;
      iconColor = AppTheme.primaryColor;
    } else if (status == 'SETTLED') {
      icon = Icons.check_circle_outline;
      iconColor = AppTheme.primaryVariant;
    }

    return GestureDetector(
      onTap: () {
        if (transaction.debt?.contact?.id != null) {
          context.push('/ledger/${transaction.debt!.contact!.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.debt?.contact?.fullName ??
                        'Unknown Transaction',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.createdAt.isNotEmpty
                        ? DateFormat('MMM dd, yyyy').format(
                            DateTime.tryParse(transaction.createdAt) ??
                                DateTime.now(),
                          )
                        : 'Unknown Date',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency.format(amount),
                  style: TextStyle(
                    color: transaction.debt?.transactionType == 'THEY_OWE_ME'
                        ? AppTheme.primaryColor
                        : AppTheme.errorColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.debt?.transactionType == 'THEY_OWE_ME'
                          ? 'They Owe'
                          : 'You Owe',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
