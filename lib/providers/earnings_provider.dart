import '../models/shift.dart';
import '../models/earnings.dart';
import '../providers/shift_provider.dart';
import '../providers/config_provider.dart';

class EarningsProvider {
  final ShiftProvider shiftProvider;
  final ConfigProvider configProvider;

  EarningsProvider({
    required this.shiftProvider,
    required this.configProvider,
  });

  Earnings? getMonthlyEarnings(int year, int month) {
    if (configProvider.config.effectiveHourlyRate <= 0) {
      return null;
    }

    final shifts = shiftProvider.getShiftsByMonth(year, month);

    return EarningsCalculator.calculateMonthEarnings(
      shifts,
      configProvider.config,
      year,
      month,
    );
  }

  double? calculateShiftEarnings(Shift shift) {
    if (configProvider.config.effectiveHourlyRate <= 0) {
      return null;
    }

    return EarningsCalculator.calculateShiftEarnings(
      shift,
      configProvider.config,
    );
  }

  Map<String, double> getWeeklyStats(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final shifts = shiftProvider.getShiftsByDateRange(weekStart, weekEnd);

    double totalMinutes = 0;
    double normalMinutes = 0;
    double extraMinutes = 0;
    double nightMinutes = 0;

    for (final shift in shifts) {
      totalMinutes += shift.duration.inMinutes;
      normalMinutes += shift.normalHours.inMinutes;
      extraMinutes += shift.extraHours.inMinutes;
      nightMinutes += shift.nightHours.inMinutes;
    }

    return {
      'totalHours': totalMinutes / 60,
      'normalHours': normalMinutes / 60,
      'extraHours': extraMinutes / 60,
      'nightHours': nightMinutes / 60,
      'daysWorked': shifts.length.toDouble(),
    };
  }
}
