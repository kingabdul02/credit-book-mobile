import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/services/sync_service.dart';
import '../bloc/people_bloc.dart';
import '../../domain/entities/contact_entity.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 1;
  late final _syncSub = SyncService.onSyncComplete.listen((_) {
    if (mounted) context.read<PeopleBloc>().add(LoadPeopleDataRequested());
  });

  @override
  void dispose() {
    _syncSub.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
      appBar: const CustomAppBar(
        title: 'People',
        showBackButton: false,
      ),
      body: BlocBuilder<PeopleBloc, PeopleState>(
        builder: (context, state) {
          if (state is PeopleInitial || state is PeopleLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PeopleError) {
            return AppErrorView(
              error: state.message,
              onRetry: () => context.read<PeopleBloc>().add(LoadPeopleDataRequested()),
            );
          } else if (state is PeopleLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<PeopleBloc>().add(LoadPeopleDataRequested(forceRefresh: true));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.3)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.search, size: 20, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                                    decoration: InputDecoration(
                                      hintText: 'Find a person or group...',
                                      hintStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            final result = await context.push('/add-person');
                            if (result == true && context.mounted) {
                              context.read<PeopleBloc>().add(LoadPeopleDataRequested(forceRefresh: true));
                            }
                          },
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : AppTheme.textDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                    const SizedBox(height: 32),

                    if (state.peopleData.favorites.isNotEmpty) ...[
                      Text(
                        'FAVORITES',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.peopleData.favorites.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 24),
                          itemBuilder: (context, index) {
                            return _buildFavoriteItem(state.peopleData.favorites[index])
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: 50 * index))
                                .slideX(begin: 0.1, end: 0);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (state.peopleData.frequentlyContacted.isNotEmpty) ...[
                      Text(
                        'FREQUENTLY CONTACTED',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.peopleData.frequentlyContacted.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildFrequentCard(state.peopleData.frequentlyContacted[index])
                                .animate()
                                .fadeIn()
                                .slideY(begin: 0.1, end: 0);
                        },
                      ),
                      const SizedBox(height: 32),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ALL CONTACTS',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.sort_rounded, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark),
                            const SizedBox(width: 4),
                            Text(
                              'Sorted by Activity',
                              style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn().slideX(),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.peopleData.allContacts.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.15),
                        ),
                        itemBuilder: (context, index) {
                          return _buildAllContactTile(state.peopleData.allContacts[index])
                              .animate()
                              .fadeIn()
                              .slideY(begin: 0.05, end: 0);
                        },
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 80), // Padding for FAB
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/add-person');
          if (result == true && context.mounted) {
            context.read<PeopleBloc>().add(LoadPeopleDataRequested(forceRefresh: true));
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
      ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
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

  Widget _buildFavoriteItem(ContactEntity contact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Show green dot randomly or based on logic (totalOwed > 0)
    final isActive = contact.totalOwedToUser > 0 || contact.totalUserOwes > 0;

    return GestureDetector(
      onTap: () async {
        await context.push('/ledger/${contact.id}');
        if (context.mounted) {
          context.read<PeopleBloc>().add(LoadPeopleDataRequested(forceRefresh: false));
        }
      },
      child: Column(
        children: [
          Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
                child: contact.profilePicture != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(contact.profilePicture!, width: 56, height: 56, fit: BoxFit.cover),
                      )
                    : Text(
                        contact.initials,
                        style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 20),
                      ),
              ),
            ),
            if (isActive)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppTheme.darkSurface : Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          contact.fullName,
          style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        ],
      ),
    );
  }

  Widget _buildFrequentCard(ContactEntity contact) {
    final formatCurrency = NumberFormat.currency(symbol: '\₦', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    double amount = 0;
    String status = 'Settled';
    Color statusColor = AppTheme.textMuted;
    
    if (contact.totalOwedToUser > 0) {
      amount = contact.totalOwedToUser;
      status = 'Owes you';
      statusColor = AppTheme.primaryVariant;
    } else if (contact.totalUserOwes > 0) {
      amount = contact.totalUserOwes;
      status = 'You owe';
      statusColor = AppTheme.errorColor;
    }

    String lastActivity = 'Last activity ${_timeAgo(contact.updatedAt)}';

    return GestureDetector(
      onTap: () async {
        await context.push('/ledger/${contact.id}');
        if (context.mounted) {
          context.read<PeopleBloc>().add(LoadPeopleDataRequested(forceRefresh: false));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
            child: contact.profilePicture != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(contact.profilePicture!, width: 48, height: 48, fit: BoxFit.cover),
                  )
                : Text(
                    contact.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.fullName,
                  style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency.format(amount),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                lastActivity,
                style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          )
        ],
      ),
      ),
    );
  }

  Widget _buildAllContactTile(ContactEntity contact) {
    final formatCurrency = NumberFormat.currency(symbol: '\₦', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    double amount = 0;
    String status = 'Settled';
    Color statusColor = AppTheme.textMuted;
    
    if (contact.totalOwedToUser > 0) {
      amount = contact.totalOwedToUser;
      status = 'Owes you';
      statusColor = AppTheme.primaryVariant;
    } else if (contact.totalUserOwes > 0) {
      amount = contact.totalUserOwes;
      status = 'You owe';
      statusColor = AppTheme.errorColor;
    }

    return GestureDetector(
      onTap: () async {
        await context.push('/ledger/${contact.id}');
        if (context.mounted) {
          context.read<PeopleBloc>().add(LoadPeopleDataRequested(forceRefresh: false));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.2),
            child: contact.profilePicture != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(contact.profilePicture!, width: 40, height: 40, fit: BoxFit.cover),
                  )
                : Text(
                    contact.initials,
                    style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.fullName,
                  style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency.format(amount),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Icon(Icons.chevron_right, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted.withValues(alpha: 0.6)),
            ],
          )
        ],
      ),
      ),
    );
  }
}
