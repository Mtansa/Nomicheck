import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class EarningsIndicator extends StatelessWidget {
  final double amount;
  final String label;
  final bool isHighlighted;

  const EarningsIndicator({
    super.key,
    required this.amount,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.secondary.withOpacity(0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: isHighlighted
            ? Border.all(color: AppColors.secondary.withOpacity(0.3))
            : null,
        boxShadow: isHighlighted
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: isHighlighted ? 28 : 22,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? AppColors.secondary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
