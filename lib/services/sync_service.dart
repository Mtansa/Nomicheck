import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'pending_deletions.dart';

enum SyncState { idle, syncing, success, error }

class SyncResult {
  final SyncState state;
  final String? error;
  final int shiftsSynced;

  const SyncResult(this.state, {this.error, this.shiftsSynced = 0});
}

class SyncService {
  static const String _keyLastSync = 'last_sync_at';

  final ApiClient _api = ApiClient();

  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastSync);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Empuja los turnos locales al servidor y adopta el estado autoritativo.
  /// Si el servidor no responde, los datos locales se conservan intactos.
  Future<SyncResult> sync() async {
    final session = await AuthService.getSession();
    if (session == null) {
      return const SyncResult(SyncState.error, error: 'No hay sesión activa');
    }

    try {
      _api.setToken(session.token);

      final localShifts = await DatabaseService.getAllShifts(userId: session.userId);
      final pendingDeletions = await PendingDeletions.get(session.userId);

      final data = await _api.post('/sync', body: {
        'shifts': localShifts.map((s) => s.toMap()).toList(),
        'deletedShiftIds': pendingDeletions,
      });

      final remoteShifts = (data['shifts'] as List<dynamic>? ?? [])
          .map((e) => Shift.fromMap(e as Map<String, dynamic>))
          .toList();

      await _replaceLocalShifts(remoteShifts, session.userId);

      // Solo se descartan las lapidas que el servidor dejo de devolver: si
      // siguen apareciendo, el borrado no llego y hay que reintentarlo.
      final remoteIds = remoteShifts.map((s) => s.id).toSet();
      final confirmed = pendingDeletions.where((id) => !remoteIds.contains(id)).toList();
      await PendingDeletions.remove(session.userId, confirmed);

      final remoteConfig = data['config'];
      if (remoteConfig is Map<String, dynamic>) {
        await _saveRemoteConfig(remoteConfig);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());

      return SyncResult(SyncState.success, shiftsSynced: remoteShifts.length);
    } on ApiException catch (e) {
      return SyncResult(SyncState.error, error: e.message);
    } catch (e) {
      debugPrint('Error de sincronización: $e');
      return const SyncResult(SyncState.error, error: 'Error inesperado al sincronizar');
    }
  }

  Future<void> _replaceLocalShifts(List<Shift> remote, String userId) async {
    final local = await DatabaseService.getAllShifts(userId: userId);
    final localIds = local.map((s) => s.id).toSet();
    final remoteIds = remote.map((s) => s.id).toSet();

    for (final shift in local) {
      if (!remoteIds.contains(shift.id)) {
        await DatabaseService.deleteShift(shift.id);
      }
    }

    for (final shift in remote) {
      if (localIds.contains(shift.id)) {
        await DatabaseService.updateShift(shift, userId: userId);
      } else {
        await DatabaseService.insertShift(shift, userId: userId);
      }
    }
  }

  Future<void> _saveRemoteConfig(Map<String, dynamic> remote) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('hourlyRate', (remote['hourlyRate'] as num?)?.toDouble() ?? 0);
    await prefs.setDouble('monthlySalary', (remote['monthlySalary'] as num?)?.toDouble() ?? 0);
    await prefs.setInt('salaryType', remote['salaryType'] as int? ?? 0);
    await prefs.setDouble(
        'nightSurchargePercent', (remote['nightSurchargePercent'] as num?)?.toDouble() ?? 35);
    await prefs.setDouble(
        'sundaySurchargePercent', (remote['sundaySurchargePercent'] as num?)?.toDouble() ?? 75);
    await prefs.setDouble(
        'extraDaySurchargePercent', (remote['extraDaySurchargePercent'] as num?)?.toDouble() ?? 25);
    await prefs.setDouble(
        'extraNightSurchargePercent', (remote['extraNightSurchargePercent'] as num?)?.toDouble() ?? 50);
    if (remote['workLatitude'] != null) {
      await prefs.setDouble('workLatitude', (remote['workLatitude'] as num).toDouble());
    }
    if (remote['workLongitude'] != null) {
      await prefs.setDouble('workLongitude', (remote['workLongitude'] as num).toDouble());
    }
    await prefs.setDouble('gpsRadius', (remote['gpsRadius'] as num?)?.toDouble() ?? 100);
    await prefs.setBool('notificationsEnabled', remote['notificationsEnabled'] as bool? ?? true);
    await prefs.setInt('reminderMinutesBefore', remote['reminderMinutesBefore'] as int? ?? 30);
    await prefs.setInt('standardHoursPerDay', remote['standardHoursPerDay'] as int? ?? 8);
    await prefs.setString(
        'workDays', (remote['workDays'] as List<dynamic>? ?? [1, 2, 3, 4, 5]).join(','));
  }
}
