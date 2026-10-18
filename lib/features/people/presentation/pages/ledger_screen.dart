import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../bloc/ledger_bloc.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/ledger_transaction_entity.dart';
import '../../data/models/debt_model.dart';

class LedgerScreen extends StatefulWidget {
  final String contactId;

  const LedgerScreen({super.key, required this.contactId});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    context.read<LedgerBloc>().add(LoadLedger(widget.contactId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<LedgerBloc, LedgerState>(
      listener: (context, state) {
        if (state is PaymentRecorded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully! ✓'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        } else if (state is PaymentFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorHandler.getFriendlyMessage(state.message)),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8F9FA),
        appBar: const CustomAppBar(
          title: 'Ledger',
        ),
        body: BlocBuilder<LedgerBloc, LedgerState>(
          builder: (context, state) {
            if (state is LedgerLoading || state is LedgerInitial || state is PaymentRecording || state is PaymentRecorded) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LedgerError) {
              return AppErrorView(
                error: state.message,
                onRetry: () => context.read<LedgerBloc>().add(LoadLedger(widget.contactId)),
              );
            }

            if (state is LedgerLoaded) {
              // Group transactions by date
              final Map<String, List<LedgerTransactionEntity>> groupedHistory = {};
              for (var txn in state.history) {
                if (!groupedHistory.containsKey(txn.date)) {
                  groupedHistory[txn.date] = [];
                }
                groupedHistory[txn.date]!.add(txn);
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(context, state),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ledger History',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                    ),
                              ),
                              TextButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.filter_list, size: 18, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                                label: Text('Filter', style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildHistoryList(context, groupedHistory),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildSummaryCard('You Owe Them', state.totalUserOwes, AppTheme.primaryVariant.withValues(alpha: 0.15), AppTheme.primaryColor, Icons.trending_down)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildSummaryCard('They Owe You', state.totalOwedToUser, AppTheme.errorColor.withValues(alpha: 0.05), AppTheme.errorColor, Icons.trending_up)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildStickyBottomBar(context, state),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _timeAgo(String dateTimeStr) {
    try {
      if (dateTimeStr.isEmpty) return 'Unknown';
      final date = DateTime.parse(dateTimeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildHeaderCard(BuildContext context, LedgerLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: state.contact.profilePicture != null
                      ? DecorationImage(image: NetworkImage(state.contact.profilePicture!), fit: BoxFit.cover)
                      : null,
                ),
                child: state.contact.profilePicture == null
                    ? Center(
                        child: Text(
                          state.contact.initials,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.contact.fullName,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last activity: ${_timeAgo(state.contact.updatedAt)}',
                      style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.info_outline, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'REMAINING BALANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formatCurrency.format(state.netBalance.abs()),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: state.netBalance < 0
                      ? AppTheme.errorColor
                      : (state.netBalance > 0 ? AppTheme.primaryColor : (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark)),
                ),
              ),
              if (state.netBalance != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.netBalance > 0 ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.netBalance > 0 ? 'Pending Payment' : 'You Owe',
                    style: TextStyle(
                      color: state.netBalance > 0 ? AppTheme.errorColor : AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Repayment Progress',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
              ),
              Text(
                '${state.repaymentProgress.toStringAsFixed(1)}% Paid',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.repaymentProgress / 100,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('You Owe: ${formatCurrency.format(state.totalUserOwes)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.8))),
              Text('They Owe: ${formatCurrency.format(state.totalOwedToUser)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, Map<String, List<LedgerTransactionEntity>> groupedHistory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedHistory.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : AppTheme.secondaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              ...entry.value.map((txn) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: txn.isPositive ? (isDark ? const Color(0xFF334155) : AppTheme.textDark) : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          txn.isPositive ? Icons.add : Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.title,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              txn.subtitle,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency.format(txn.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: txn.transactionType == 'THEY_OWE_ME' ? AppTheme.primaryColor : AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                txn.transactionType == 'THEY_OWE_ME' ? 'They Owe' : 'You Owe',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                txn.time,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency.format(amount),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, LedgerLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showAdjustBalanceSheet(context, state),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.textDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Adjust Balance', style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await context.push('/add-transaction?contactId=${widget.contactId}');
                if (result == true && context.mounted) {
                  context.read<LedgerBloc>().add(LoadLedger(widget.contactId, forceRefresh: true));
                }
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Add Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.primaryColor : AppTheme.textDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the Adjust Balance bottom sheet — lets the user pick which debt direction
  /// they are settling and enter an amount + optional note.
  void _showAdjustBalanceSheet(BuildContext context, LedgerLoaded state) {
    // Extract open debts from contact
    final debts = (state.contact.debts ?? [])
        .cast<DebtEntity>()
        .where((d) => 
            d.status.toLowerCase() != 'paid' && 
            d.status.toLowerCase() != 'settled' && 
            d.outstandingAmount > 0)
        .toList();

    if (debts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No outstanding debts to adjust.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<LedgerBloc>(),
        child: _AdjustBalanceSheet(
          debts: debts,
          contactId: widget.contactId,
          contactName: state.contact.fullName,
        ),
      ),
    );
  }
}

// ─── Adjust Balance Bottom Sheet ──────────────────────────────

class _AdjustBalanceSheet extends StatefulWidget {
  final List<DebtEntity> debts;
  final String contactId;
  final String contactName;

  const _AdjustBalanceSheet({
    required this.debts,
    required this.contactId,
    required this.contactName,
  });

  @override
  State<_AdjustBalanceSheet> createState() => _AdjustBalanceSheetState();
}

class _AdjustBalanceSheetState extends State<_AdjustBalanceSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

  late DebtEntity _selectedDebt;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDebt = widget.debts.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isIGave => _selectedDebt.transactionType.toUpperCase() == 'I_OWE_THEM';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<LedgerBloc, LedgerState>(
      listener: (context, state) {
        if (state is PaymentRecorded) {
          Navigator.of(context).pop();
        } else if (state is PaymentFailed) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.errorColor),
          );
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.92,
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
                      color: isDark ? Colors.white24 : AppTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 22, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                              const SizedBox(width: 10),
                              Text(
                                'Adjust Balance',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Record a payment with ${widget.contactName}',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Debt selector (if multiple open debts)
                          if (widget.debts.length > 1) ...[
                            Text(
                              'Select Debt',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...widget.debts.map((debt) => _buildDebtOption(debt, isDark)),
                            const SizedBox(height: 20),
                          ],

                          // Direction indicator
                          _buildDirectionCard(isDark),
                          const SizedBox(height: 20),

                          // Amount field
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                            ),
                            decoration: InputDecoration(
                              prefixText: '₦ ',
                              prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary.withValues(alpha: 0.5) : AppTheme.textMuted.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w400,
                              ),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter an amount';
                              final amount = double.tryParse(v);
                              if (amount == null || amount <= 0) return 'Enter a valid amount';
                              if (amount > _selectedDebt.outstandingAmount) {
                                return 'Amount cannot exceed outstanding balance (${formatCurrency.format(_selectedDebt.outstandingAmount)})';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          // Outstanding hint
                          Text(
                            'Outstanding: ${formatCurrency.format(_selectedDebt.outstandingAmount)}',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Note field
                          Text(
                            'Note (optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _noteController,
                            maxLines: 2,
                            style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                            decoration: InputDecoration(
                              hintText: 'e.g. Partial repayment via transfer',
                              hintStyle: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary.withValues(alpha: 0.5) : AppTheme.textMuted.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w400,
                              ),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isIGave ? AppTheme.primaryColor : (isDark ? Colors.white : AppTheme.textDark),
                                foregroundColor: _isIGave ? Colors.white : (isDark ? Colors.black : Colors.white),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _isIGave ? 'Record My Payment (I Paid)' : 'Record Received Payment',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
      ),
    );
  }

  Widget _buildDebtOption(DebtEntity debt, bool isDark) {
    final isSelected = _selectedDebt.id == debt.id;
    final isIGave = debt.transactionType.toUpperCase() == 'I_OWE_THEM';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedDebt = debt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isIGave ? AppTheme.primaryColor.withValues(alpha: 0.12) : AppTheme.errorColor.withValues(alpha: 0.1))
              : (isDark ? AppTheme.darkBackground : AppTheme.onBackground),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isIGave ? AppTheme.primaryColor : AppTheme.errorColor)
                : (isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? (isIGave ? AppTheme.primaryColor : AppTheme.errorColor) : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIGave ? 'I Gave (I Owe Them)' : 'I Got (They Owe Me)',
                    style: TextStyle(fontWeight: FontWeight.w700, color: isIGave ? AppTheme.primaryColor : AppTheme.errorColor, fontSize: 13),
                  ),
                  Text(
                    'Outstanding: ${formatCurrency.format(debt.outstandingAmount)}',
                    style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionCard(bool isDark) {
    final color = _isIGave ? AppTheme.primaryColor : AppTheme.errorColor;
    final icon = _isIGave ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final label = _isIGave ? 'I Gave — Paying My Debt' : 'I Got — Receiving Payment';
    final sublabel = _isIGave
        ? 'Recording a payment you made to ${widget.contactName}'
        : 'Recording money you received from ${widget.contactName}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();
    setState(() => _isSubmitting = true);
    context.read<LedgerBloc>().add(
      RecordPayment(
        debtId: _selectedDebt.id,
        amount: amount,
        note: note.isEmpty ? null : note,
        contactId: widget.contactId,
      ),
    );
  }
}

