class Shift {
  final String id;
  final DateTime entryTime;
  final DateTime? exitTime;
  final ShiftType type;
  final String? notes;
  final double? latitude;
  final double? longitude;

  Shift({
    required this.id,
    required this.entryTime,
    this.exitTime,
    this.type = ShiftType.normal,
    this.notes,
    this.latitude,
    this.longitude,
  });

  bool get isOpen => exitTime == null;

  Duration get duration {
    if (exitTime == null) {
      return DateTime.now().difference(entryTime);
    }
    return exitTime!.difference(entryTime);
  }

  Duration get normalHours {
    const normalHoursPerDay = 8;
    final totalMinutes = duration.inMinutes;
    final normalMinutes = normalHoursPerDay * 60;
    return Duration(minutes: totalMinutes > normalMinutes ? normalMinutes : totalMinutes);
  }

  Duration get extraHours {
    const normalHoursPerDay = 8;
    final totalMinutes = duration.inMinutes;
    final normalMinutes = normalHoursPerDay * 60;
    return Duration(minutes: totalMinutes > normalMinutes ? totalMinutes - normalMinutes : 0);
  }

  Duration get nightHours {
    if (exitTime == null) return Duration.zero;

    int nightMinutes = 0;
    DateTime current = entryTime;

    while (current.isBefore(exitTime!)) {
      final hour = current.hour;
      if (hour >= 21 || hour < 6) {
        nightMinutes += 60;
      }
      current = current.add(const Duration(hours: 1));
    }

    return Duration(minutes: nightMinutes);
  }

  bool get isSundayOrHoliday {
    return entryTime.weekday == DateTime.sunday;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryTime': entryTime.toIso8601String(),
      'exitTime': exitTime?.toIso8601String(),
      'type': type.index,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      entryTime: DateTime.parse(map['entryTime']),
      exitTime: map['exitTime'] != null ? DateTime.parse(map['exitTime']) : null,
      type: ShiftType.values[map['type'] ?? 0],
      notes: map['notes'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }

  Shift copyWith({
    String? id,
    DateTime? entryTime,
    DateTime? exitTime,
    ShiftType? type,
    String? notes,
    double? latitude,
    double? longitude,
  }) {
    return Shift(
      id: id ?? this.id,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

enum ShiftType {
  normal,
  extra,
  night,
  sunday,
  holiday,
}

extension ShiftTypeExtension on ShiftType {
  String get label {
    switch (this) {
      case ShiftType.normal:
        return 'Normal';
      case ShiftType.extra:
        return 'Extra';
      case ShiftType.night:
        return 'Nocturno';
      case ShiftType.sunday:
        return 'Dominical';
      case ShiftType.holiday:
        return 'Festivo';
    }
  }
}
