import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/services/transaction_pin_service.dart';
import '../../../../core/services/face_auth_service.dart';
import '../bloc/add_transaction_bloc.dart';
import '../../domain/entities/contact_entity.dart';
import '../widgets/confirm_transaction_pin_modal.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? preSelectedContactId;

  const AddTransactionScreen({super.key, this.preSelectedContactId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _directorySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AddTransactionBloc>().add(LoadContacts());
    _noteController.addListener(() {
      context.read<AddTransactionBloc>().add(NoteChanged(_noteController.text));
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _directorySearchController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(BuildContext context, AddTransactionState state) async {
    final amount = double.tryParse(state.amountString) ?? 0.0;
    final contactName = state.selectedContact?.fullName ?? 'Unknown';

    // Face Liveness Check for Large Transactions
    if (amount >= FaceAuthService.largeTransactionThreshold) {
      final hasFaceSet = await FaceAuthService.isFaceRegistered();
      
      if (!hasFaceSet) {
        if (!context.mounted) return;
        final usePinFallback = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Action Required'),
            content: const Text('Transactions of this size require biometric verification. Please set up your Face ID in Settings.'),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => ctx.pop(true),
                child: const Text('Use PIN instead', style: TextStyle(color: AppTheme.primaryColor)),
              ),
            ],
          ),
        );
        if (usePinFallback != true) return;
        // Fallback to PIN
      } else {
        if (!context.mounted) return;
        final verified = await context.push<bool>('/face-verify', extra: {
          'amount': amount,
          'contactName': contactName,
        });

        if (verified != true) {
          // Face verification is mandatory; abort if cancelled or failed
          return;
        }
      }
    }

    // Standard PIN Flow
    final hasPinSet = await TransactionPinService.hasPin();

    if (!hasPinSet) {
      // No PIN set — save directly
      if (context.mounted) context.read<AddTransactionBloc>().add(SubmitTransaction());
      return;
    }

    // PIN is set — show confirmation modal
    if (!context.mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmTransactionPinModal(
        contactName: contactName,
        amount: amount,
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AddTransactionBloc>().add(SubmitTransaction());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddTransactionBloc, AddTransactionState>(
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction saved successfully!'), backgroundColor: AppTheme.primaryColor),
          );
          // Pop and possibly signal refresh
          context.pop(true);
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: AppTheme.errorColor),
          );
        }
        
        // If contacts are loaded and a preSelectedContactId is provided, select it once
        if (state.contacts.isNotEmpty && state.selectedContact == null && widget.preSelectedContactId != null) {
          try {
            final contact = state.contacts.firstWhere((c) => c.id == widget.preSelectedContactId);
            context.read<AddTransactionBloc>().add(ContactSelected(contact));
          } catch (_) {}
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Create a sorted list so the selected contact is always first
        final displayContacts = List<ContactEntity>.from(state.contacts);
        if (state.selectedContact != null) {
          displayContacts.removeWhere((c) => c.id == state.selectedContact!.id);
          displayContacts.insert(0, state.selectedContact!);
        }

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
          appBar: const CustomAppBar(title: '', showBackButton: true),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Toggle Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              context: context,
                              title: 'THEY OWE ME',
                              icon: Icons.arrow_downward,
                              isSelected: state.transactionType == 'THEY_OWE_ME',
                              onTap: () => context.read<AddTransactionBloc>().add(TypeToggled('THEY_OWE_ME')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildToggleButton(
                              context: context,
                              title: 'I OWE THEM',
                              icon: Icons.arrow_upward,
                              isSelected: state.transactionType == 'I_OWE_THEM',
                              onTap: () => context.read<AddTransactionBloc>().add(TypeToggled('I_OWE_THEM')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Select Contact Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SELECT CONTACT',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textDark.withOpacity(0.6),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showDirectoryBottomSheet(context, state);
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.search, size: 16, color: AppTheme.primaryVariant),
                                SizedBox(width: 4),
                                Text('Directory', style: TextStyle(color: AppTheme.primaryVariant, fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayContacts.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(width: 20),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildNewContactButton(context);
                            }
                            final contact = displayContacts[index - 1];
                            return _buildContactAvatar(contact, state.selectedContact?.id == contact.id, context);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Amount Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, right: 4.0),
                            child: Text(
                              '\₦',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textMuted.withOpacity(0.8),
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _formatAmount(state.amountString),
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                              fontSize: 55,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Note Input
                      TextField(
                        controller: _noteController,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a note (Lunch, Rent...)',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextSecondary.withOpacity(0.6)
                                : AppTheme.textMuted.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Custom Numpad
                      _buildNumpad(context),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (state.isLoading || state.selectedContact == null || double.parse(state.amountString) <= 0) 
                              ? null 
                              : () => _handleSave(context, state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.primaryColor : AppTheme.textDark,
                            disabledBackgroundColor: isDark
                                ? AppTheme.primaryColor.withOpacity(0.3)
                                : AppTheme.textDark.withOpacity(0.3),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white.withOpacity(0.7),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: isDark
                                ? Colors.transparent
                                : AppTheme.textDark.withOpacity(0.3),
                          ),
                          child: state.isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Save Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: Icon(
                                        Icons.check,
                                        color: isDark ? AppTheme.primaryColor : AppTheme.textDark,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0';
    if (amount.contains('.')) return amount; // Don't format with commas while typing decimals
    try {
      final formatter = NumberFormat('#,###');
      return formatter.format(int.parse(amount));
    } catch (_) {
      return amount;
    }
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkSurface : Colors.white)
              : (isDark
                  ? AppTheme.darkSurface.withOpacity(0.5)
                  : AppTheme.secondaryColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.primaryColor : AppTheme.textDark)
                : (isDark ? AppTheme.darkBorder : Colors.transparent),
            width: 2,
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewContactButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () async {
        final result = await context.push('/add-person');
        if (result == true && context.mounted) {
          context.read<AddTransactionBloc>().add(LoadContacts());
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.primaryColor : AppTheme.textDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'New',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAvatar(ContactEntity contact, bool isSelected, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.read<AddTransactionBloc>().add(ContactSelected(contact)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: isDark
                  ? AppTheme.darkSurface
                  : AppTheme.secondaryColor.withOpacity(0.15),
              child: contact.profilePicture != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(contact.profilePicture!, width: 56, height: 56, fit: BoxFit.cover),
                    )
                  : Text(
                      contact.initials,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contact.fullName.split(' ').first,
            style: TextStyle(
              color: isSelected
                  ? (isDark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildNumpadButton(context, '1')),
            const SizedBox(width: 12),
            Expanded(child: _buildNumpadButton(context, '2')),
            const SizedBox(width: 12),
            Expanded(child: _buildNumpadButton(context, '3')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildNumpadButton(context, '4')),
            const SizedBox(width: 12),
            Expanded(child: _buildNumpadButton(context, '5')),
            const SizedBox(width: 12),
            Expanded(child: _buildNumpadButton(context, '6')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildNumpadButton(context, '7')),
            const SizedBox(width: 12),
            Expanded(child: _buildNumpadButton(context, '8')),
            const SizedBox(width: 12),
            Expanded(child: _buildNumpadButton(context, '9')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildNumpadButton(context, '.')),
            const SizedBox(width: 12),
            Expanded(child: _buildNumpadButton(context, '0')),
            const SizedBox(width: 12),
            Expanded(child: _buildNumpadButton(context, 'DEL', icon: Icons.backspace_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadButton(BuildContext context, String text, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (text == 'DEL') {
          context.read<AddTransactionBloc>().add(BackspacePressed());
        } else if (text == '.') {
          context.read<AddTransactionBloc>().add(DecimalPressed());
        } else {
          context.read<AddTransactionBloc>().add(NumberPressed(text));
        }
      },
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
        ),
        child: icon != null
            ? Icon(
                icon,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                size: 24,
              )
            : Text(
                text,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  void _showDirectoryBottomSheet(BuildContext context, AddTransactionState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _directorySearchController.text.toLowerCase();
            final filteredContacts = state.contacts.where((c) {
              return c.fullName.toLowerCase().contains(query);
            }).toList();

            return DraggableScrollableSheet(
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
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Contact Directory',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkBackground
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: isDark
                                ? Border.all(color: AppTheme.darkBorder)
                                : null,
                          ),
                          child: TextField(
                            controller: _directorySearchController,
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                            ),
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search contacts...',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextSecondary.withOpacity(0.6)
                                    : AppTheme.textMuted.withOpacity(0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredContacts.isEmpty
                            ? Center(
                                child: Text(
                                  'No contacts found',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                itemCount: filteredContacts.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final contact = filteredContacts[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: isDark
                                          ? AppTheme.darkBackground
                                          : AppTheme.secondaryColor.withOpacity(0.15),
                                      child: contact.profilePicture != null
                                          ? ClipOval(child: Image.network(contact.profilePicture!, width: 40, height: 40, fit: BoxFit.cover))
                                          : Text(
                                              contact.initials,
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppTheme.darkTextPrimary
                                                    : AppTheme.textDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                    title: Text(
                                      contact.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.textDark,
                                      ),
                                    ),
                                    onTap: () {
                                      this.context.read<AddTransactionBloc>().add(ContactSelected(contact));
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _directorySearchController.clear();
    });
  }
}
