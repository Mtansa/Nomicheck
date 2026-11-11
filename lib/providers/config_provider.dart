import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ConfigProvider with ChangeNotifier {
  AppConfig _config = AppConfig();
  bool _isLoading = false;

  AppConfig get config => _config;
  bool get isLoading => _isLoading;

  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      _config = AppConfig(
        userName: prefs.getString('userName') ?? '',
        position: prefs.getString('position'),
        company: prefs.getString('company'),
        hourlyRate: prefs.getDouble('hourlyRate') ?? 0,
        monthlySalary: prefs.getDouble('monthlySalary') ?? 0,
        salaryType: SalaryType.values[prefs.getInt('salaryType') ?? 0],
        nightSurchargePercent: prefs.getDouble('nightSurchargePercent') ?? 35,
        sundaySurchargePercent: prefs.getDouble('sundaySurchargePercent') ?? 75,
        extraDaySurchargePercent: prefs.getDouble('extraDaySurchargePercent') ?? 25,
        extraNightSurchargePercent: prefs.getDouble('extraNightSurchargePercent') ?? 50,
        workLatitude: prefs.getDouble('workLatitude'),
        workLongitude: prefs.getDouble('workLongitude'),
        gpsRadius: prefs.getDouble('gpsRadius') ?? 100,
        notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
        reminderMinutesBefore: prefs.getInt('reminderMinutesBefore') ?? 30,
        standardHoursPerDay: prefs.getInt('standardHoursPerDay') ?? 8,
        workDays: prefs.getString('workDays')?.split(',').map((e) => int.parse(e)).toList() ?? [1, 2, 3, 4, 5],
      );
    } catch (e) {
      debugPrint('Error loading config: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userName', config.userName);
    if (config.position != null) await prefs.setString('position', config.position!);
    if (config.company != null) await prefs.setString('company', config.company!);
    await prefs.setDouble('hourlyRate', config.hourlyRate);
    await prefs.setDouble('monthlySalary', config.monthlySalary);
    await prefs.setInt('salaryType', config.salaryType.index);
    await prefs.setDouble('nightSurchargePercent', config.nightSurchargePercent);
    await prefs.setDouble('sundaySurchargePercent', config.sundaySurchargePercent);
    await prefs.setDouble('extraDaySurchargePercent', config.extraDaySurchargePercent);
    await prefs.setDouble('extraNightSurchargePercent', config.extraNightSurchargePercent);
    if (config.workLatitude != null) await prefs.setDouble('workLatitude', config.workLatitude!);
    if (config.workLongitude != null) await prefs.setDouble('workLongitude', config.workLongitude!);
    await prefs.setDouble('gpsRadius', config.gpsRadius);
    await prefs.setBool('notificationsEnabled', config.notificationsEnabled);
    await prefs.setInt('reminderMinutesBefore', config.reminderMinutesBefore);
    await prefs.setInt('standardHoursPerDay', config.standardHoursPerDay);
    await prefs.setString('workDays', config.workDays.join(','));

    _config = config;
    notifyListeners();

    await _pushToServer(config);
  }

  /// Sube la configuración a MySQL. Un fallo de red no interrumpe el uso local.
  Future<void> _pushToServer(AppConfig config) async {
    final session = await AuthService.getSession();
    if (session == null) return;

    try {
      final api = ApiClient()..setToken(session.token);
      await api.put('/config', body: {
        'hourlyRate': config.hourlyRate,
        'monthlySalary': config.monthlySalary,
        'salaryType': config.salaryType.index,
        'nightSurchargePercent': config.nightSurchargePercent,
        'sundaySurchargePercent': config.sundaySurchargePercent,
        'extraDaySurchargePercent': config.extraDaySurchargePercent,
        'extraNightSurchargePercent': config.extraNightSurchargePercent,
        'workLatitude': config.workLatitude,
        'workLongitude': config.workLongitude,
        'gpsRadius': config.gpsRadius,
        'notificationsEnabled': config.notificationsEnabled,
        'reminderMinutesBefore': config.reminderMinutesBefore,
        'standardHoursPerDay': config.standardHoursPerDay,
        'workDays': config.workDays,
      });
    } catch (e) {
      debugPrint('No se pudo subir la configuración al servidor: $e');
    }
  }

  Future<void> updateUserName(String name) async {
    _config = _config.copyWith(userName: name);
    await saveConfig(_config);
  }

  Future<void> updateSalary({
    required double hourlyRate,
    required double monthlySalary,
    required SalaryType salaryType,
  }) async {
    _config = _config.copyWith(
      hourlyRate: hourlyRate,
      monthlySalary: monthlySalary,
      salaryType: salaryType,
    );
    await saveConfig(_config);
  }

  Future<void> updateWorkLocation(double latitude, double longitude) async {
    _config = _config.copyWith(
      workLatitude: latitude,
      workLongitude: longitude,
    );
    await saveConfig(_config);
  }

  Future<void> updateNotifications({
    required bool enabled,
    int? minutesBefore,
  }) async {
    _config = _config.copyWith(
      notificationsEnabled: enabled,
      reminderMinutesBefore: minutesBefore ?? _config.reminderMinutesBefore,
    );
    await saveConfig(_config);
  }
}
