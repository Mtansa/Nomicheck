import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shift_provider.dart';
import '../providers/config_provider.dart';
import '../models/earnings.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resumen Mensual'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer2<ShiftProvider, ConfigProvider>(
        builder: (context, shiftProvider, configProvider, child) {
          final config = configProvider.config;

          if (config.effectiveHourlyRate <= 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 64,
                    color: AppColors.accent.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Configura tu salario para ver el resumen',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final earnings = EarningsCalculator.calculateMonthEarnings(
            shiftProvider.getShiftsByMonth(_selectedYear, _selectedMonth),
            config,
            _selectedYear,
            _selectedMonth,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector(),
                const SizedBox(height: AppSpacing.lg),
                _buildOverviewCard(earnings),
                const SizedBox(height: AppSpacing.md),
                _buildHoursBreakdown(earnings),
                const SizedBox(height: AppSpacing.md),
                _buildEarningsBreakdown(earnings),
                const SizedBox(height: AppSpacing.md),
                _buildComparisonCard(earnings, shiftProvider, config),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            Text(
              '${AppFormatters.formatMonthName(_selectedMonth)} $_selectedYear',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _canGoNext() ? _nextMonth : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(Earnings earnings) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary.withOpacity(0.15),
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Text(
              'Estimación Total',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppFormatters.formatCurrency(earnings.grossEarnings),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOverviewStat(
                  'Días',
                  earnings.daysWorked.toStringAsFixed(0),
                  Icons.calendar_today,
                ),
                _buildOverviewStat(
                  'Horas',
                  AppFormatters.formatHours(earnings.totalHours),
                  Icons.access_time,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHoursBreakdown(Earnings earnings) {
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
            _buildHoursRow('Normales', earnings.normalHours, AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            _buildHoursRow('Extra', earnings.extraHours, AppColors.extraSurcharge),
            const SizedBox(height: AppSpacing.sm),
            _buildHoursRow('Nocturnas', earnings.nightHours, AppColors.nightSurcharge),
            const SizedBox(height: AppSpacing.sm),
            _buildHoursRow('Dominicales', earnings.sundayHours, AppColors.sundaySurcharge),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppFormatters.formatHours(earnings.totalHours),
                  style: const TextStyle(
                    fontSize: 18,
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

  Widget _buildHoursRow(String label, double hours, Color color) {
    return Row(
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
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(
          AppFormatters.formatHours(hours),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsBreakdown(Earnings earnings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desglose de Ganancias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildEarningsRow('Horas Normales', earnings.normalEarnings, AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            _buildEarningsRow('Horas Extra', earnings.extraEarnings, AppColors.extraSurcharge),
            const SizedBox(height: AppSpacing.sm),
            _buildEarningsRow('Recargo Nocturno', earnings.nightEarnings, AppColors.nightSurcharge),
            const SizedBox(height: AppSpacing.sm),
            _buildEarningsRow('Recargo Dominical', earnings.sundayEarnings, AppColors.sundaySurcharge),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(earnings.grossEarnings),
                  style: const TextStyle(
                    fontSize: 18,
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

  Widget _buildEarningsRow(String label, double amount, Color color) {
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
          AppFormatters.formatCurrency(amount),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(
    Earnings currentEarnings,
    ShiftProvider shiftProvider,
    config,
  ) {
    int prevMonth = _selectedMonth - 1;
    int prevYear = _selectedYear;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }

    final previousEarnings = EarningsCalculator.calculateMonthEarnings(
      shiftProvider.getShiftsByMonth(prevYear, prevMonth),
      config,
      prevYear,
      prevMonth,
    );

    final difference = currentEarnings.grossEarnings - previousEarnings.grossEarnings;
    final isPositive = difference >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparación con Mes Anterior',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppFormatters.formatMonthName(prevMonth)} $prevYear',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(previousEarnings.grossEarnings),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? AppColors.secondary : AppColors.error,
                  size: 32,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppFormatters.formatMonthName(_selectedMonth)} $_selectedYear',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(currentEarnings.grossEarnings),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.secondary : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${AppFormatters.formatCurrency(difference)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppColors.secondary : AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth--;
      if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedYear < now.year ||
        (_selectedYear == now.year && _selectedMonth < now.month)) {
      setState(() {
        _selectedMonth++;
        if (_selectedMonth > 12) {
          _selectedMonth = 1;
          _selectedYear++;
        }
      });
    }
  }

  bool _canGoNext() {
    final now = DateTime.now();
    return _selectedYear < now.year ||
        (_selectedYear == now.year && _selectedMonth < now.month);
  }
}
