class AppConfig {
  final String userName;
  final String? position;
  final String? company;
  final double hourlyRate;
  final double monthlySalary;
  final SalaryType salaryType;
  final double nightSurchargePercent;
  final double sundaySurchargePercent;
  final double extraDaySurchargePercent;
  final double extraNightSurchargePercent;
  final double? workLatitude;
  final double? workLongitude;
  final double gpsRadius;
  final bool notificationsEnabled;
  final int reminderMinutesBefore;
  final int standardHoursPerDay;
  final List<int> workDays;

  AppConfig({
    this.userName = '',
    this.position,
    this.company,
    this.hourlyRate = 0,
    this.monthlySalary = 0,
    this.salaryType = SalaryType.hourly,
    this.nightSurchargePercent = 35,
    this.sundaySurchargePercent = 75,
    this.extraDaySurchargePercent = 25,
    this.extraNightSurchargePercent = 50,
    this.workLatitude,
    this.workLongitude,
    this.gpsRadius = 100,
    this.notificationsEnabled = true,
    this.reminderMinutesBefore = 30,
    this.standardHoursPerDay = 8,
    this.workDays = const [1, 2, 3, 4, 5],
  });

  bool get hasWorkLocation => workLatitude != null && workLongitude != null;

  double get effectiveHourlyRate {
    if (salaryType == SalaryType.monthly && monthlySalary > 0) {
      return monthlySalary / (30 * standardHoursPerDay);
    }
    return hourlyRate;
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'position': position,
      'company': company,
      'hourlyRate': hourlyRate,
      'monthlySalary': monthlySalary,
      'salaryType': salaryType.index,
      'nightSurchargePercent': nightSurchargePercent,
      'sundaySurchargePercent': sundaySurchargePercent,
      'extraDaySurchargePercent': extraDaySurchargePercent,
      'extraNightSurchargePercent': extraNightSurchargePercent,
      'workLatitude': workLatitude,
      'workLongitude': workLongitude,
      'gpsRadius': gpsRadius,
      'notificationsEnabled': notificationsEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'standardHoursPerDay': standardHoursPerDay,
      'workDays': workDays.join(','),
    };
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      userName: map['userName'] ?? '',
      position: map['position'],
      company: map['company'],
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      monthlySalary: (map['monthlySalary'] ?? 0).toDouble(),
      salaryType: SalaryType.values[map['salaryType'] ?? 0],
      nightSurchargePercent: (map['nightSurchargePercent'] ?? 35).toDouble(),
      sundaySurchargePercent: (map['sundaySurchargePercent'] ?? 75).toDouble(),
      extraDaySurchargePercent: (map['extraDaySurchargePercent'] ?? 25).toDouble(),
      extraNightSurchargePercent: (map['extraNightSurchargePercent'] ?? 50).toDouble(),
      workLatitude: map['workLatitude']?.toDouble(),
      workLongitude: map['workLongitude']?.toDouble(),
      gpsRadius: (map['gpsRadius'] ?? 100).toDouble(),
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      reminderMinutesBefore: map['reminderMinutesBefore'] ?? 30,
      standardHoursPerDay: map['standardHoursPerDay'] ?? 8,
      workDays: (map['workDays'] as String?)?.split(',').map((e) => int.parse(e)).toList() ?? [1, 2, 3, 4, 5],
    );
  }

  AppConfig copyWith({
    String? userName,
    String? position,
    String? company,
    double? hourlyRate,
    double? monthlySalary,
    SalaryType? salaryType,
    double? nightSurchargePercent,
    double? sundaySurchargePercent,
    double? extraDaySurchargePercent,
    double? extraNightSurchargePercent,
    double? workLatitude,
    double? workLongitude,
    double? gpsRadius,
    bool? notificationsEnabled,
    int? reminderMinutesBefore,
    int? standardHoursPerDay,
    List<int>? workDays,
  }) {
    return AppConfig(
      userName: userName ?? this.userName,
      position: position ?? this.position,
      company: company ?? this.company,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      salaryType: salaryType ?? this.salaryType,
      nightSurchargePercent: nightSurchargePercent ?? this.nightSurchargePercent,
      sundaySurchargePercent: sundaySurchargePercent ?? this.sundaySurchargePercent,
      extraDaySurchargePercent: extraDaySurchargePercent ?? this.extraDaySurchargePercent,
      extraNightSurchargePercent: extraNightSurchargePercent ?? this.extraNightSurchargePercent,
      workLatitude: workLatitude ?? this.workLatitude,
      workLongitude: workLongitude ?? this.workLongitude,
      gpsRadius: gpsRadius ?? this.gpsRadius,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      standardHoursPerDay: standardHoursPerDay ?? this.standardHoursPerDay,
      workDays: workDays ?? this.workDays,
    );
  }
}

enum SalaryType {
  hourly,
  monthly,
}

extension SalaryTypeExtension on SalaryType {
  String get label {
    switch (this) {
      case SalaryType.hourly:
        return 'Por Hora';
      case SalaryType.monthly:
        return 'Salario Mensual';
    }
  }
}
