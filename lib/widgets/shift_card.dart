import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class ShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback? onTap;
  final double? earnings;

  const ShiftCard({
    super.key,
    required this.shift,
    this.onTap,
    this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppFormatters.formatDate(shift.entryTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _buildTypeBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.login, size: 18, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    AppFormatters.formatTime(shift.entryTime),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (shift.exitTime != null) ...[
                    const Icon(Icons.logout, size: 18, color: AppColors.error),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppFormatters.formatTime(shift.exitTime!),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ] else ...[
                    const Icon(Icons.schedule, size: 18, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'En curso',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    AppFormatters.formatDuration(shift.duration),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (shift.notes != null && shift.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  shift.notes!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    Color color;
    String label;

    switch (shift.type) {
      case ShiftType.normal:
        color = AppColors.primary;
        label = 'Normal';
        break;
      case ShiftType.extra:
        color = AppColors.extraSurcharge;
        label = 'Extra';
        break;
      case ShiftType.night:
        color = AppColors.nightSurcharge;
        label = 'Nocturno';
        break;
      case ShiftType.sunday:
        color = AppColors.sundaySurcharge;
        label = 'Dominical';
        break;
      case ShiftType.holiday:
        color = AppColors.error;
        label = 'Festivo';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
