# NomiCheck

Aplicación de control de turnos y nómina para trabajadores por turnos.

## Características

- **Registro de entrada/salida**: Marcar horas de trabajo con validación GPS
- **Cálculo de recargos**: Horas extra, nocturnas, dominicales y festivas
- **Estimación de nómina**: Cálculo automático del pago basado en configuración salarial
- **Historial completo**: Registro detallado de todos los turnos
- **Validación GPS**: Asegura que los registros se hacen cerca del lugar de trabajo
- **Notificaciones**: Recordatorios antes de iniciar turnos
- **Resumen mensual**: Vista detallada de horas trabajadas y ganancias estimadas
- **Cuentas y sincronización en la nube**: Usuarios, turnos y configuración en MySQL

## Arquitectura de datos

La app es **híbrida**: MySQL es la fuente de verdad, SQLite queda como caché local.

```
┌──────────────┐   HTTPS + JWT    ┌──────────────┐      mysql2      ┌─────────┐
│  Flutter app │ ───────────────► │  API REST    │ ───────────────► │  MySQL  │
│              │ ◄─────────────── │  (Express)   │ ◄─────────────── │         │
│  SQLite ─────┼── caché offline  └──────────────┘                  └─────────┘
└──────────────┘
```

- **Al iniciar sesión** el token JWT se guarda en el dispositivo y la app descarga
  turnos y configuración desde el servidor.
- **Cada registro de turno** se escribe primero en SQLite (respuesta inmediata) y
  se propaga al servidor en segundo plano.
- **Sin internet** la app sigue funcionando con los datos locales; la sincronización
  se reintenta cuando vuelve la conexión.
- Los turnos van identificados por el UUID que genera el dispositivo, lo que hace
  el push idempotente: reenviar el mismo turno no lo duplica.

### Endpoints del API

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/auth/register` | Crear cuenta |
| POST | `/api/auth/login` | Iniciar sesión |
| GET/PUT | `/api/auth/me` | Perfil |
| GET/POST/PUT/DELETE | `/api/shifts` | Turnos |
| GET/PUT | `/api/config` | Configuración |
| POST | `/api/sync` | Sincronización completa |

Detalle completo en [`server/README.md`](server/README.md).

## Puesta en marcha

### 1. Servidor

```bash
cd server
npm install
cp .env.example .env    # ajusta credenciales y JWT_SECRET
npm run migrate         # crea la base de datos y las tablas
npm run seed            # opcional: usuario demo@nomicheck.app / demo1234
npm start               # http://localhost:3000/api
```

### 2. App

```bash
flutter pub get
flutter run
```

La URL del API se fija en tiempo de compilación. Por defecto apunta a
`http://10.0.2.2:3000/api` (host del emulador de Android desde el dispositivo
virtual). Para un dispositivo físico o iOS:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000/api
```

Para un APK de release:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://tu-api.com/api
```

> En el emulador de Android usa `10.0.2.2`; `localhost` dentro del emulador
> apunta al propio emulador, no a tu máquina.

### 3. Pruebas

```bash
flutter test
```

Los tests de modelo corren siempre. Los de integración
(`test/api_integration_test.dart`) necesitan el API levantado; si no está
disponible se saltan solos.

```bash
cd server && npm start        # en otra terminal
flutter test
```

## Configuración

### Salario
- Valor por hora
- Salario mensual (cálculo automático del valor hora)

### Recargos (configurables)
- Recargo nocturno (9pm - 6am): 35%
- Recargo dominical/festivo: 75%
- Hora extra diurna: 25%
- Hora extra nocturna: 50%

### Ubicación
- Guardar coordenadas del lugar de trabajo
- Radio de validación GPS configurable (50-500m)

## Compilación

```bash
flutter build apk --release --dart-define=API_BASE_URL=<url-del-api>
```

El APK se genera en: `build/app/outputs/flutter-apk/app-release.apk`

> Para ejecutarla en un Android físico paso a paso (MySQL + API + compilación +
> instalación + verificación), consulta **[MANUAL_ANDROID.md](MANUAL_ANDROID.md)**.

## Permisos Requeridos

- Ubicación (fine/coarse)
- Notificaciones
- Vibración
- Alarma exacta

## Stack Tecnológico

- Flutter 3.47 / Dart 3.13
- Provider (state management)
- SQLite (caché local) + MySQL 8 (fuente de verdad)
- Node.js + Express (API REST), JWT + bcrypt
- Geolocator (GPS)
- flutter_local_notifications

## Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada
├── app.dart               # Configuración de la app
├── models/                # Modelos de datos
│   ├── shift.dart         # Turno
│   ├── config.dart       # Configuración
│   └── earnings.dart     # Ganancias
├── providers/             # Estado de la aplicación
│   ├── shift_provider.dart
│   ├── config_provider.dart
│   ├── auth_provider.dart
│   ├── sync_provider.dart
│   └── earnings_provider.dart
├── screens/               # Pantallas
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── register_screen.dart
│   ├── history_screen.dart
│   ├── shift_detail_screen.dart
│   ├── settings_screen.dart
│   └── monthly_summary_screen.dart
├── widgets/               # Componentes reutilizables
│   ├── clock_display.dart
│   ├── shift_card.dart
│   ├── summary_card.dart
│   ├── gps_indicator.dart
│   └── earnings_indicator.dart
├── services/              # Servicios externos
│   ├── api_client.dart    # Cliente HTTP con JWT
│   ├── auth_service.dart  # Sesión y token
│   ├── sync_service.dart  # Push/pull con el servidor
│   ├── database_service.dart
│   ├── notification_service.dart
│   └── location_service.dart
└── utils/                 # Utilidades
    ├── constants.dart
    └── formatters.dart

server/
├── src/
│   ├── index.js           # App Express
│   ├── db/
│   │   ├── pool.js        # Pool de conexiones mysql2
│   │   ├── schema.sql     # Definición de tablas
│   │   ├── migrate.js     # Aplica el esquema
│   │   └── seed.js        # Usuario de prueba
│   ├── middleware/
│   │   └── auth.js        # Verificación de JWT
│   └── routes/
│       ├── auth.js
│       ├── shifts.js
│       ├── config.js
│       └── sync.js
└── package.json
```
