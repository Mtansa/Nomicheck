import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GpsIndicator extends StatelessWidget {
  final bool isValid;
  final double? distance;
  final double maxDistance;
  final VoidCallback? onConfigure;

  const GpsIndicator({
    super.key,
    required this.isValid,
    this.distance,
    this.maxDistance = 100,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.secondary.withOpacity(0.1)
            : AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.location_on : Icons.location_off,
            color: isValid ? AppColors.secondary : AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            distance != null
                ? '${distance!.toStringAsFixed(0)}m'
                : (isValid ? 'En área' : 'Fuera de área'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isValid ? AppColors.secondary : AppColors.accent,
            ),
          ),
          if (onConfigure != null) ...[
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onConfigure,
              child: const Icon(
                Icons.settings,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
