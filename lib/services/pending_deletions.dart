import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Turnos borrados en el dispositivo que todavia no se han borrado en el
/// servidor.
///
/// El borrado solo se puede propagar si el servidor recibe el id del turno:
/// `POST /sync` hace upsert de lo que le llega, asi que un turno ausente de
/// la lista no significa "borrado" sino "desconocido". Estas lapidas viajan
/// en la propia llamada de sincronizacion y sobreviven a los reinicios y a
/// los fallos de red.
class PendingDeletions {
  static const String _key = 'pending_shift_deletions';

  static Future<List<String>> get(String userId) async {
    final map = await _readMap();
    return (map[userId] as List<dynamic>? ?? const []).cast<String>();
  }

  static Future<void> add(String userId, String shiftId) async {
    final map = await _readMap();
    final ids = (map[userId] as List<dynamic>? ?? const []).cast<String>().toSet();
    ids.add(shiftId);
    map[userId] = ids.toList();
    await _writeMap(map);
  }

  /// Descarta las lapidas ya confirmadas por el servidor.
  static Future<void> remove(String userId, List<String> shiftIds) async {
    if (shiftIds.isEmpty) return;
    final map = await _readMap();
    final ids = (map[userId] as List<dynamic>? ?? const []).cast<String>().toSet();
    ids.removeAll(shiftIds);
    if (ids.isEmpty) {
      map.remove(userId);
    } else {
      map[userId] = ids.toList();
    }
    await _writeMap(map);
  }

  static Future<Map<String, dynamic>> _readMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeMap(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }
}
