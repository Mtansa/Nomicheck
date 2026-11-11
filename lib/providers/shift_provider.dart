import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/shift.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/pending_deletions.dart';

class ShiftProvider with ChangeNotifier {
  List<Shift> _shifts = [];
  Shift? _openShift;
  bool _isLoading = false;

  /// Se invoca tras cada cambio local para propagarlo al servidor.
  Future<void> Function()? onLocalChange;

  List<Shift> get shifts => _shifts;
  Shift? get openShift => _openShift;
  bool get isLoading => _isLoading;
  bool get hasOpenShift => _openShift != null;

  Future<void> loadShifts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await AuthService.getUserId();
      _shifts = await DatabaseService.getAllShifts(userId: userId);
      _openShift = await DatabaseService.getOpenShift(userId: userId);
    } catch (e) {
      debugPrint('Error loading shifts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkOpenShift() async {
    final userId = await AuthService.getUserId();
    _openShift = await DatabaseService.getOpenShift(userId: userId);
    notifyListeners();
  }

  Future<void> registerEntry({
    ShiftType type = ShiftType.normal,
    String? notes,
    double? latitude,
    double? longitude,
    DateTime? manualEntryTime,
  }) async {
    final shift = Shift(
      id: const Uuid().v4(),
      entryTime: manualEntryTime ?? DateTime.now(),
      type: type,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
    );

    final userId = await AuthService.getUserId();
    await DatabaseService.insertShift(shift, userId: userId);
    _openShift = shift;
    _shifts.insert(0, shift);
    notifyListeners();
    await onLocalChange?.call();
  }

  Future<void> registerExit({
    String? notes,
    DateTime? manualExitTime,
  }) async {
    if (_openShift == null) return;

    final updatedShift = _openShift!.copyWith(
      exitTime: manualExitTime ?? DateTime.now(),
      notes: notes ?? _openShift!.notes,
    );

    final userId = await AuthService.getUserId();
    await DatabaseService.updateShift(updatedShift, userId: userId);

    final index = _shifts.indexWhere((s) => s.id == _openShift!.id);
    if (index != -1) {
      _shifts[index] = updatedShift;
    }

    _openShift = null;
    notifyListeners();
    await onLocalChange?.call();
  }

  Future<void> updateShift(Shift shift) async {
    final userId = await AuthService.getUserId();
    await DatabaseService.updateShift(shift, userId: userId);

    final index = _shifts.indexWhere((s) => s.id == shift.id);
    if (index != -1) {
      _shifts[index] = shift;
    }

    if (_openShift?.id == shift.id) {
      _openShift = shift.exitTime != null ? null : shift;
    }

    notifyListeners();
    await onLocalChange?.call();
  }

  Future<void> deleteShift(String id) async {
    final userId = await AuthService.getUserId();
    await DatabaseService.deleteShift(id);

    // El servidor no puede inferir un borrado a partir de la ausencia del
    // turno, asi que la lapida se registra para propagarla en el proximo sync.
    if (userId != null && userId.isNotEmpty) {
      await PendingDeletions.add(userId, id);
    }

    _shifts.removeWhere((s) => s.id == id);

    if (_openShift?.id == id) {
      _openShift = null;
    }

    notifyListeners();
    await onLocalChange?.call();
  }

  List<Shift> getShiftsByMonth(int year, int month) {
    return _shifts.where((s) =>
      s.entryTime.year == year && s.entryTime.month == month
    ).toList();
  }

  List<Shift> getShiftsByDateRange(DateTime start, DateTime end) {
    return _shifts.where((s) =>
      s.entryTime.isAfter(start) && s.entryTime.isBefore(end)
    ).toList();
  }

  double getTodayHours() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    double totalMinutes = 0;
    for (final shift in _shifts) {
      if (shift.entryTime.isAfter(startOfDay) &&
          shift.entryTime.isBefore(endOfDay)) {
        totalMinutes += shift.duration.inMinutes;
      }
    }

    return totalMinutes / 60;
  }
}
