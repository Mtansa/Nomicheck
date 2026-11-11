import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shift_provider.dart';
import '../providers/config_provider.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';
import '../providers/auth_provider.dart';
import '../models/earnings.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/clock_display.dart';
import '../widgets/summary_card.dart';
import '../widgets/shift_card.dart';
import 'shift_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _sync(BuildContext context) async {
    final syncProvider = context.read<SyncProvider>();
    final shiftProvider = context.read<ShiftProvider>();
    final configProvider = context.read<ConfigProvider>();

    final messenger = ScaffoldMessenger.of(context);
    final ok = await syncProvider.sync();
    if (!context.mounted) return;

    if (ok) {
      await shiftProvider.loadShifts();
      await configProvider.loadConfig();
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Datos sincronizados con el servidor'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(syncProvider.error ?? 'No se pudo sincronizar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer3<ShiftProvider, ConfigProvider, SyncProvider>(
          builder: (context, shiftProvider, configProvider, syncProvider, child) {
            final config = configProvider.config;
            final authName = context.read<AuthProvider>().userName;
            final userName =
                authName.isNotEmpty ? authName : (config.userName.isNotEmpty ? config.userName : 'Usuario');

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppFormatters.formatGreeting(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Sincronizar con el servidor',
                                  onPressed:
                                      syncProvider.isSyncing ? null : () => _sync(context),
                                  icon: syncProvider.isSyncing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.sync),
                                ),
                                const ClockDisplay(),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          AppFormatters.formatDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildTodaySummary(context, shiftProvider, config),
                ),
                SliverToBoxAdapter(
                  child: _buildSyncStatus(context, syncProvider),
                ),
                SliverToBoxAdapter(
                  child: _buildMonthlyEstimate(context, shiftProvider, config),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Turnos Recientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (shiftProvider.shifts.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              // Navigate to history
                            },
                            child: const Text('Ver todos'),
                          ),
                      ],
                    ),
                  ),
                ),
                if (shiftProvider.shifts.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'No hay turnos registrados',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Toca el botón + para registrar tu entrada',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final shift = shiftProvider.shifts[index];
                        return ShiftCard(
                          shift: shift,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ShiftDetailScreen(shift: shift),
                              ),
                            );
                          },
                        );
                      },
                      childCount: shiftProvider.shifts.length > 5
                          ? 5
                          : shiftProvider.shifts.length,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context, SyncProvider syncProvider) {
    final lastSync = syncProvider.lastSync;
    final isError = syncProvider.state == SyncState.error;

    final subtitle = isError
        ? (syncProvider.error ?? 'Sin conexión con el servidor')
        : lastSync != null
            ? 'Última sincronización: ${AppFormatters.formatTime(lastSync)}'
            : 'Toca para sincronizar con el servidor';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListTile(
        leading: Icon(
          isError ? Icons.cloud_off : Icons.cloud_done,
          color: isError ? AppColors.error : AppColors.secondary,
        ),
        title: const Text(
          'Servidor MySQL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: syncProvider.isSyncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: syncProvider.isSyncing ? null : () => _sync(context),
      ),
    );
  }

  Widget _buildTodaySummary(
    BuildContext context,
    ShiftProvider shiftProvider,
    config,
  ) {
    final todayHours = shiftProvider.getTodayHours();
    final openShift = shiftProvider.openShift;

    if (openShift != null) {
      final currentDuration = openShift.duration;
      return SummaryCard(
        title: 'Turno en curso',
        value: AppFormatters.formatDuration(currentDuration),
        icon: Icons.timer,
        color: AppColors.secondary,
        subtitle: 'Entrada: ${AppFormatters.formatTime(openShift.entryTime)}',
      );
    }

    return SummaryCard(
      title: 'Horas hoy',
      value: AppFormatters.formatHours(todayHours),
      icon: Icons.access_time,
      color: AppColors.primary,
      subtitle: todayHours >= 8
          ? 'Meta alcanzada'
          : '${(8 - todayHours).toStringAsFixed(1)}h restantes',
    );
  }

  Widget _buildMonthlyEstimate(
    BuildContext context,
    ShiftProvider shiftProvider,
    config,
  ) {
    if (config.effectiveHourlyRate <= 0) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Configura tu salario en ajustes para ver la estimación',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final earnings = EarningsCalculator.calculateMonthEarnings(
      shiftProvider.getShiftsByMonth(now.year, now.month),
      config,
      now.year,
      now.month,
    );

    return SummaryCard(
      title: 'Estimación ${AppFormatters.formatMonthYear(now)}',
      value: AppFormatters.formatCurrency(earnings.grossEarnings),
      icon: Icons.payments,
      color: AppColors.secondary,
      subtitle: '${AppFormatters.formatHours(earnings.totalHours)} trabajadas',
    );
  }
}
