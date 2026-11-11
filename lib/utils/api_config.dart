import 'dart:io';

import 'package:flutter/foundation.dart';

/// URL base del API de NomiCheck.
///
/// Se puede fijar en tiempo de compilación con:
///   flutter run --dart-define=API_BASE_URL=https://tu-api.com/api
///
/// Sin `--dart-define`, el emulador de Android usa la IP del host en la red local
/// y el resto de plataformas usan localhost.
///
/// 10.0.2.2 sólo existe en el emulador de Android Studio corriendo en la misma
/// máquina. Un emulador remoto (o un contenedor) llega al host por su IP real.
class ApiConfig {
  static const String _definedUrl = String.fromEnvironment('API_BASE_URL');

  /// IP del host en la red local, alcanzable desde el emulador remoto.
  static const String _androidEmulatorHost = '192.168.246.2';

  static String get baseUrl {
    if (_definedUrl.isNotEmpty) return _definedUrl;
    if (_isTest) return 'http://localhost:3000/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_androidEmulatorHost:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  /// Bajo `flutter test` el emulador de Android no existe, así que el host
  /// real es el localhost de la máquina.
  static bool get _isTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
}
