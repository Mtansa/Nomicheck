import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shift.dart';
import '../models/earnings.dart';
import '../providers/shift_provider.dart';
import '../providers/config_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'edit_shift_screen.dart';

class ShiftDetailScreen extends StatelessWidget {
  final Shift shift;

  const ShiftDetailScreen({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>().config;
    final earnings = config.effectiveHourlyRate > 0
        ? EarningsCalculator.calculateShiftEarnings(shift, config)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del Turno'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateCard(),
            const SizedBox(height: AppSpacing.md),
            _buildTimeCard(),
            const SizedBox(height: AppSpacing.md),
            _buildDurationCard(),
            const SizedBox(height: AppSpacing.md),
            _buildBreakdownCard(),
            if (earnings != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildEarningsCard(earnings),
            ],
            if (shift.notes != null && shift.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildNotesCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: const Icon(Icons.calendar_today, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fecha',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  AppFormatters.formatDate(shift.entryTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildTypeBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _buildTimeRow(
              icon: Icons.login,
              label: 'Entrada',
              time: shift.entryTime,
              color: AppColors.secondary,
            ),
            const Divider(height: AppSpacing.lg),
            _buildTimeRow(
              icon: Icons.logout,
              label: 'Salida',
              time: shift.exitTime,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required DateTime? time,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              time != null
                  ? AppFormatters.formatDateTime(time)
                  : 'En curso',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: time != null ? AppColors.textPrimary : AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: const Icon(Icons.timer, color: AppColors.accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Duración Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  AppFormatters.formatDuration(shift.duration),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desglose de Horas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBreakdownRow(
              'Horas Normales',
              AppFormatters.formatDuration(shift.normalHours),
              AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBreakdownRow(
              'Horas Extra',
              AppFormatters.formatDuration(shift.extraHours),
              AppColors.extraSurcharge,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBreakdownRow(
              'Horas Nocturnas',
              AppFormatters.formatDuration(shift.nightHours),
              AppColors.nightSurcharge,
            ),
            if (shift.isSundayOrHoliday) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildBreakdownRow(
                'Dominical/Festivo',
                AppFormatters.formatDuration(shift.duration),
                AppColors.sundaySurcharge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(double earnings) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: const Icon(Icons.payments, color: AppColors.secondary, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimación del Turno',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(earnings),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Notas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              shift.notes!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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

  void _handleMenuAction(BuildContext context, String action) async {
    if (action == 'edit') {
      final edited = await Navigator.push<Shift>(
        context,
        MaterialPageRoute(
          builder: (context) => EditShiftScreen(shift: shift),
        ),
      );

      if (edited == null || !context.mounted) return;

      await context.read<ShiftProvider>().updateShift(edited);
      if (!context.mounted) return;

      // La pantalla de detalle muestra el turno recibido por constructor, asi
      // que se reconstruye para reflejar los cambios guardados.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ShiftDetailScreen(shift: edited),
        ),
      );
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar Turno'),
          content: const Text('¿Estás seguro de que deseas eliminar este turno?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await context.read<ShiftProvider>().deleteShift(shift.id);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turno eliminado'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    }
  }
}
