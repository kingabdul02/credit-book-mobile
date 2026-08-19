import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/insights_entity.dart';

/// Shows the top debtor and top creditor side-by-side (or stacked)
/// based on the real API's top_debtors and top_creditors lists.
class TopContactsCard extends StatelessWidget {
  final List<TopContactEntity> topDebtors;
  final List<TopContactEntity> topCreditors;

  const TopContactsCard({
    super.key,
    required this.topDebtors,
    required this.topCreditors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (topDebtors.isNotEmpty) ...[
          _buildCard(
            tag: 'TOP DEBTOR',
            tagColor: Colors.orange.shade700,
            entity: topDebtors.first,
            labelColor: AppTheme.primaryColor,
            valueLabel: 'Owes You',
          ),
          if (topCreditors.isNotEmpty) const SizedBox(height: 12),
        ],
        if (topCreditors.isNotEmpty)
          _buildCard(
            tag: 'TOP CREDITOR',
            tagColor: Colors.red.shade700,
            entity: topCreditors.first,
            labelColor: Colors.red.shade700,
            valueLabel: 'You Owe',
          ),
        if (topDebtors.isEmpty && topCreditors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
            ),
            child: const Center(
              child: Text('No top contacts found.', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ),
      ],
    );
  }

  Widget _buildCard({
    required String tag,
    required Color tagColor,
    required TopContactEntity entity,
    required Color labelColor,
    required String valueLabel,
  }) {
    final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: labelColor.withValues(alpha: 0.1),
            child: entity.contact.profilePicture != null && entity.contact.profilePicture!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      entity.contact.profilePicture!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        entity.contact.initials,
                        style: TextStyle(color: labelColor, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  )
                : Text(
                    entity.contact.initials,
                    style: TextStyle(color: labelColor, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entity.contact.displayName,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entity.contact.nickname != null &&
                    entity.contact.nickname != entity.contact.fullName)
                  Text(
                    entity.contact.fullName,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency.format(entity.outstanding),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valueLabel,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
