import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shift_provider.dart';
import '../models/shift.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/shift_card.dart';
import 'shift_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial de Turnos'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<ShiftProvider>(
        builder: (context, shiftProvider, child) {
          List<Shift> shifts = shiftProvider.shifts;

          if (_selectedRange != null) {
            shifts = shifts.where((s) =>
              s.entryTime.isAfter(_selectedRange!.start) &&
              s.entryTime.isBefore(_selectedRange!.end.add(const Duration(days: 1)))
            ).toList();
          }

          if (shifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
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
                ],
              ),
            );
          }

          final groupedShifts = _groupShiftsByMonth(shifts);

          return ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 100),
            itemCount: groupedShifts.length,
            itemBuilder: (context, index) {
              final month = groupedShifts.keys.elementAt(index);
              final monthShifts = groupedShifts[month]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      month,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  ...monthShifts.map((shift) => ShiftCard(
                    shift: shift,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShiftDetailScreen(shift: shift),
                        ),
                      );
                    },
                  )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<Shift>> _groupShiftsByMonth(List<Shift> shifts) {
    final Map<String, List<Shift>> grouped = {};

    for (final shift in shifts) {
      final key =
          '${AppFormatters.formatMonthName(shift.entryTime.month)} ${shift.entryTime.year}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(shift);
    }

    return grouped;
  }

  Future<void> _showFilterDialog() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );

    if (result != null) {
      setState(() => _selectedRange = result);
    }
  }
}
