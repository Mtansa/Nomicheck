import 'shift.dart';
import 'config.dart';

class Earnings {
  final int year;
  final int month;
  final double totalHours;
  final double normalHours;
  final double extraHours;
  final double nightHours;
  final double sundayHours;
  final double grossEarnings;
  final double normalEarnings;
  final double extraEarnings;
  final double nightEarnings;
  final double sundayEarnings;
  final List<Shift> shifts;

  Earnings({
    required this.year,
    required this.month,
    required this.totalHours,
    required this.normalHours,
    required this.extraHours,
    required this.nightHours,
    required this.sundayHours,
    required this.grossEarnings,
    required this.normalEarnings,
    required this.extraEarnings,
    required this.nightEarnings,
    required this.sundayEarnings,
    required this.shifts,
  });

  double get daysWorked => shifts.length.toDouble();

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'totalHours': totalHours,
      'normalHours': normalHours,
      'extraHours': extraHours,
      'nightHours': nightHours,
      'sundayHours': sundayHours,
      'grossEarnings': grossEarnings,
      'normalEarnings': normalEarnings,
      'extraEarnings': extraEarnings,
      'nightEarnings': nightEarnings,
      'sundayEarnings': sundayEarnings,
    };
  }
}

class EarningsCalculator {
  static Earnings calculateMonthEarnings(
    List<Shift> shifts,
    AppConfig config,
    int year,
    int month,
  ) {
    final monthShifts = shifts.where((s) =>
      s.entryTime.year == year && s.entryTime.month == month
    ).toList();

    double totalMinutes = 0;
    double normalMinutes = 0;
    double extraMinutes = 0;
    double nightMinutes = 0;
    double sundayMinutes = 0;

    for (final shift in monthShifts) {
      totalMinutes += shift.duration.inMinutes;
      normalMinutes += shift.normalHours.inMinutes;
      extraMinutes += shift.extraHours.inMinutes;
      nightMinutes += shift.nightHours.inMinutes;

      if (shift.isSundayOrHoliday) {
        sundayMinutes += shift.duration.inMinutes;
      }
    }

    final totalHours = totalMinutes / 60;
    final normalHours = normalMinutes / 60;
    final extraHours = extraMinutes / 60;
    final nightHours = nightMinutes / 60;
    final sundayHours = sundayMinutes / 60;

    final hourlyRate = config.effectiveHourlyRate;

    final normalEarnings = normalHours * hourlyRate;
    final extraDayRate = hourlyRate * (1 + config.extraDaySurchargePercent / 100);
    final nightRate = hourlyRate * (1 + config.nightSurchargePercent / 100);
    final sundayRate = hourlyRate * (1 + config.sundaySurchargePercent / 100);

    final extraEarnings = extraHours * extraDayRate;
    final nightEarnings = nightHours * nightRate;
    final sundayEarnings = sundayHours * sundayRate;

    final grossEarnings = normalEarnings + extraEarnings + nightEarnings + sundayEarnings;

    return Earnings(
      year: year,
      month: month,
      totalHours: totalHours,
      normalHours: normalHours,
      extraHours: extraHours,
      nightHours: nightHours,
      sundayHours: sundayHours,
      grossEarnings: grossEarnings,
      normalEarnings: normalEarnings,
      extraEarnings: extraEarnings,
      nightEarnings: nightEarnings,
      sundayEarnings: sundayEarnings,
      shifts: monthShifts,
    );
  }

  static double calculateShiftEarnings(Shift shift, AppConfig config) {
    final hours = shift.duration.inMinutes / 60;
    final hourlyRate = config.effectiveHourlyRate;

    double earnings = 0;

    // Normal hours (up to standard)
    final normalHours = shift.normalHours.inMinutes / 60;
    earnings += normalHours * hourlyRate;

    // Extra hours
    final extraHours = shift.extraHours.inMinutes / 60;
    final extraRate = hourlyRate * (1 + config.extraDaySurchargePercent / 100);
    earnings += extraHours * extraRate;

    // Night surcharge
    final nightHours = shift.nightHours.inMinutes / 60;
    final nightSurcharge = hourlyRate * (config.nightSurchargePercent / 100);
    earnings += nightHours * nightSurcharge;

    // Sunday/holiday surcharge
    if (shift.isSundayOrHoliday) {
      final sundaySurcharge = hourlyRate * (config.sundaySurchargePercent / 100);
      earnings += hours * sundaySurcharge;
    }

    return earnings;
  }
}
