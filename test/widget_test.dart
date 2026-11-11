import 'package:flutter_test/flutter_test.dart';

import 'package:nomicheck/models/shift.dart';

void main() {
  group('Shift', () {
    test('un turno abierto tiene duración en curso', () {
      final shift = Shift(
        id: 'test-1',
        entryTime: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(shift.isOpen, isTrue);
      expect(shift.duration.inHours, 2);
    });

    test('un turno cerrado calcula la duración exacta', () {
      final entry = DateTime(2026, 3, 10, 8, 0);
      final shift = Shift(
        id: 'test-2',
        entryTime: entry,
        exitTime: entry.add(const Duration(hours: 6)),
      );

      expect(shift.isOpen, isFalse);
      expect(shift.duration.inMinutes, 360);
    });

    test('las horas extra son el exceso sobre las 8 horas diarias', () {
      final entry = DateTime(2026, 3, 10, 6, 0);
      final shift = Shift(
        id: 'test-3',
        entryTime: entry,
        exitTime: entry.add(const Duration(hours: 10)),
      );

      expect(shift.normalHours.inHours, 8);
      expect(shift.extraHours.inHours, 2);
    });

    test('las horas nocturnas cubren el tramo de 21:00 a 06:00', () {
      final entry = DateTime(2026, 3, 10, 22, 0);
      final shift = Shift(
        id: 'test-4',
        entryTime: entry,
        exitTime: entry.add(const Duration(hours: 4)),
      );

      expect(shift.nightHours.inHours, 4);
    });

    test('toMap y fromMap conservan los datos del turno', () {
      final entry = DateTime(2026, 3, 10, 8, 0);
      final original = Shift(
        id: 'test-5',
        entryTime: entry,
        exitTime: entry.add(const Duration(hours: 8)),
        type: ShiftType.night,
        notes: 'Turno de prueba',
        latitude: 1.5,
        longitude: -2.5,
      );

      final restored = Shift.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.entryTime, original.entryTime);
      expect(restored.exitTime, original.exitTime);
      expect(restored.type, original.type);
      expect(restored.notes, original.notes);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });
  });
}
