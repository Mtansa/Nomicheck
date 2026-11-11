import 'package:intl/intl.dart';

class AppFormatters {
  static final currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );

  static final currencyFormatDecimals = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final timeFormat = DateFormat('HH:mm');
  static final dateFormat = DateFormat('dd/MM/yyyy');
  static final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final monthYearFormat = DateFormat('MMMM yyyy', 'es');
  static final monthNameFormat = DateFormat('MMMM', 'es');
  static final shortDateFormat = DateFormat('dd MMM', 'es');

  static String formatCurrency(double value) {
    return currencyFormat.format(value);
  }

  static String formatCurrencyDecimals(double value) {
    return currencyFormatDecimals.format(value);
  }

  static String formatTime(DateTime time) {
    return timeFormat.format(time);
  }

  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormat.format(dateTime);
  }

  static String formatMonthYear(DateTime date) {
    final formatted = monthYearFormat.format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  static String formatMonthName(int month) {
    final formatted = monthNameFormat.format(DateTime(2000, month));
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  static String formatShortDate(DateTime date) {
    return shortDateFormat.format(date);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();

    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  static String formatGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
