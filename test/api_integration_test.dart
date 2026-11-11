import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nomicheck/services/api_client.dart';
import 'package:nomicheck/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Pruebas de integración contra un servidor NomiCheck real.
///
/// Requiere el API levantado en la URL de API_BASE_URL (por defecto
/// http://localhost:3000/api). Se saltan si el servidor no responde.
void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  late ApiClient api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient();
  });

  Future<bool> serverAvailable() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  test('el servidor responde en /api/health', () async {
    if (!await serverAvailable()) {
      markTestSkipped('Servidor no disponible en $baseUrl');
      return;
    }

    final res = await http.get(Uri.parse('$baseUrl/health'));
    expect(res.statusCode, 200);
    expect(res.body, contains('ok'));
  });

  test('registro, login y sincronizacion de un turno', () async {
    if (!await serverAvailable()) {
      markTestSkipped('Servidor no disponible en $baseUrl');
      return;
    }

    final email = 'test_${DateTime.now().millisecondsSinceEpoch}@ejemplo.com';

    final registro = await AuthService.register(
      name: 'Usuario de Prueba',
      email: email,
      password: 'secreto123',
    );
    expect(registro.token, isNotEmpty);
    expect(registro.email, email);
    expect(registro.userId, isNotEmpty);

    api.setToken(registro.token);

    final turnoId = const Uuid().v4();
    final entryTime = DateTime.utc(2026, 3, 10, 8);
    final exitTime = DateTime.utc(2026, 3, 10, 16);

    final sync = await api.post('/sync', body: {
      'shifts': [
        {
          'id': turnoId,
          'entryTime': entryTime.toIso8601String(),
          'exitTime': exitTime.toIso8601String(),
          'type': 0,
          'notes': 'Turno de integracion',
          'latitude': 4.71,
          'longitude': -74.07,
        }
      ],
    });

    final turnos = sync['shifts'] as List<dynamic>;
    expect(turnos.length, 1);

    final turno = turnos.first as Map<String, dynamic>;
    expect(turno['id'], turnoId);
    expect(turno['notes'], 'Turno de integracion');
    expect(DateTime.parse(turno['entryTime'] as String), entryTime);
    expect(DateTime.parse(turno['exitTime'] as String), exitTime);

    // Reenviar el mismo turno no debe duplicarlo
    final resync = await api.post('/sync', body: {
      'shifts': [
        {
          'id': turnoId,
          'entryTime': entryTime.toIso8601String(),
          'exitTime': exitTime.toIso8601String(),
          'type': 0,
        }
      ],
    });
    expect((resync['shifts'] as List<dynamic>).length, 1);

    // La configuracion se guarda y se relee
    await api.put('/config', body: {'hourlyRate': 30.0, 'gpsRadius': 200});
    final config = await api.get('/config');
    final cfg = config['config'] as Map<String, dynamic>;
    expect(cfg['hourlyRate'], 30.0);
    expect(cfg['gpsRadius'], 200);

    // El turno creado es visible para su propio usuario
    final propios = await api.get('/shifts');
    final idsPropios = (propios['shifts'] as List<dynamic>)
        .map((t) => (t as Map<String, dynamic>)['id'])
        .toList();
    expect(idsPropios, contains(turnoId));

    // Los turnos de otro usuario no son accesibles con este token
    final otro = await AuthService.register(
      name: 'Otro Usuario',
      email: 'otro_${DateTime.now().millisecondsSinceEpoch}@ejemplo.com',
      password: 'secreto123',
    );
    api.setToken(otro.token);
    final ajenos = await api.get('/shifts');
    for (final t in ajenos['shifts'] as List<dynamic>) {
      expect((t as Map<String, dynamic>)['id'], isNot(turnoId));
    }

    api.setToken(registro.token);

    // Eliminar el turno
    await api.delete('/shifts/$turnoId');
    final despues = await api.get('/shifts');
    for (final t in despues['shifts'] as List<dynamic>) {
      expect((t as Map<String, dynamic>)['id'], isNot(turnoId));
    }
  });

  test('un turno borrado no reaparece tras sincronizar', () async {
    if (!await serverAvailable()) {
      markTestSkipped('Servidor no disponible en $baseUrl');
      return;
    }

    final email = 'delete_${DateTime.now().millisecondsSinceEpoch}@ejemplo.com';
    final registro = await AuthService.register(
      name: 'Usuario Borra',
      email: email,
      password: 'secreto123',
    );
    api.setToken(registro.token);

    final turnoId = const Uuid().v4();
    final entryTime = DateTime.utc(2026, 3, 20, 8);
    final exitTime = DateTime.utc(2026, 3, 20, 16);

    await api.post('/sync', body: {
      'shifts': [
        {
          'id': turnoId,
          'entryTime': entryTime.toIso8601String(),
          'exitTime': exitTime.toIso8601String(),
          'type': 0,
          'notes': 'para borrar',
        }
      ],
    });

    var turnos = (await api.get('/shifts'))['shifts'] as List<dynamic>;
    expect(turnos.length, 1);

    // El dispositivo borra el turno localmente y propaga la lapida.
    final sync = await api.post('/sync', body: {
      'shifts': <dynamic>[],
      'deletedShiftIds': [turnoId],
    });

    final resultantes = sync['shifts'] as List<dynamic>;
    expect(resultantes.where((t) => (t as Map<String, dynamic>)['id'] == turnoId), isEmpty,
        reason: 'El servidor no debe devolver un turno borrado');

    turnos = (await api.get('/shifts'))['shifts'] as List<dynamic>;
    expect(turnos.where((t) => (t as Map<String, dynamic>)['id'] == turnoId), isEmpty,
        reason: 'El turno debe estar borrado en la tabla del servidor');

    // Volver a iniciar sesion no debe resucitar el turno.
    final login = await AuthService.login(email: email, password: 'secreto123');
    api.setToken(login.token);
    final trasLogin = await api.post('/sync', body: {'shifts': <dynamic>[]});
    expect(
      (trasLogin['shifts'] as List<dynamic>)
          .where((t) => (t as Map<String, dynamic>)['id'] == turnoId),
      isEmpty,
    );
  });

  test('un token invalido es rechazado', () async {
    if (!await serverAvailable()) {
      markTestSkipped('Servidor no disponible en $baseUrl');
      return;
    }

    api.setToken('token_invalido');
    try {
      await api.get('/shifts');
      fail('Se esperaba un error 401');
    } on ApiException catch (e) {
      expect(e.statusCode, 401);
      expect(e.isUnauthorized, isTrue);
    }
  });
}
