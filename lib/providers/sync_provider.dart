import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();

  SyncState _state = SyncState.idle;
  String? _error;
  DateTime? _lastSync;
  bool _syncing = false;

  SyncState get state => _state;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  bool get isSyncing => _syncing;

  Future<void> loadLastSync() async {
    _lastSync = await _syncService.getLastSync();
    notifyListeners();
  }

  Future<bool> sync() async {
    if (_syncing) return false;

    _syncing = true;
    _state = SyncState.syncing;
    _error = null;
    notifyListeners();

    final result = await _syncService.sync();

    _syncing = false;
    _state = result.state;
    _error = result.error;
    if (result.state == SyncState.success) {
      _lastSync = DateTime.now();
    }
    notifyListeners();

    return result.state == SyncState.success;
  }
}
