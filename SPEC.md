# NomiCheck - App de Control de Turnos y Nómina

## 1. Proyecto y Visión

**NomiCheck** es una aplicación móvil para trabajadores por turnos que registra horas trabajadas, calcula recargos y horas extra, y proporciona una estimación de nómina mensual precisa. La experiencia debe sentirse profesional pero accesible, como un asistente financiero personal que ayuda al trabajador a tener control sobre sus ingresos.

## 2. Lenguaje de Diseño

### Dirección Estética
Diseño basado en Material Design 3 con un toque moderno y profesional. Inspirado en apps bancarias modernas - limpio, confiable, con jerarquía visual clara.

### Paleta de Colores
- **Primario**: `#1E88E5` (Azul profesional)
- **Secundario**: `#43A047` (Verde éxito/positivo)
- **Acento**: `#FF9800` (Naranja para alertas/recargos)
- **Error**: `#E53935` (Rojo)
- **Fondo**: `#FAFAFA` (Gris muy claro)
- **Superficie**: `#FFFFFF` (Blanco)
- **Texto primario**: `#212121`
- **Texto secundario**: `#757575`

### Tipografía
- **Títulos**: Roboto Bold, 24-28sp
- **Subtítulos**: Roboto Medium, 18-20sp
- **Cuerpo**: Roboto Regular, 14-16sp
- **Captions**: Roboto Light, 12sp

### Sistema Espacial
- Margen base: 16dp
- Padding cards: 16dp
- Espaciado entre elementos: 8-16dp
- Border radius: 12dp para cards, 8dp para botones

### Filosofía de Movimiento
- Transiciones suaves de 300ms para navegación
- Animaciones de feedback en botones: scale 0.95 → 1.0
- Cards con elevación sutil al tocar
- Progress indicators animados para carga

## 3. Layout y Estructura

### Navegación Principal
Bottom Navigation Bar con 4 tabs:
1. **Inicio** - Dashboard con resumen del día/mes
2. **Registrar** - Marcar entrada/salida
3. **Historial** - Lista de turnos registrados
4. **Configuración** - Perfil, salario, ubicación

### Estructura de Pantallas

#### Pantalla de Inicio (Dashboard)
- Header con saludo personalizado y fecha actual
- Card de resumen rápido: horas trabajadas hoy
- Card de estimación de pago mensual
- Listado de últimos 3 turnos
- Botón flotante para marcar entrada/salida rápida

#### Pantalla de Registro
- Reloj digital grande mostrando hora actual
- Botones prominentes: ENTRADA / SALIDA
- Selector de tipo de turno (si aplica)
- Campo opcional para notas
- Indicador de ubicación GPS
- Botón de registrar con confirmación

#### Pantalla de Historial
- Filtros: día, semana, mes, rango de fechas
- Lista de turnos con fecha, hora entrada/salida, duración
- Indicadores visuales para horas extra/nocturnas/dominicales
- Tap en turno para ver detalle
- Totales acumulados visibles

#### Pantalla de Detalle de Turno
- Fecha y hora completa (entrada y salida)
- Duración total
- Desglose: horas normales, extra, nocturnas, dominicales
- Monto calculado para ese turno
- Notas agregadas
- Opción de editar/eliminar

#### Pantalla de Configuración
- **Perfil**: Nombre, puesto, empresa
- **Salario**: Valor hora o salario mensual fijo
- **Recargos**: Configurar % nocturnos, dominicales, festivos
- **Ubicación**: Coordenadas GPS del trabajo (radio de validación)
- **Notificaciones**: Activar/desactivar recordatorios
- **Horarios**: Configurar inicio de turno, duración estándar

#### Pantalla de Resumen Mensual
- Mes y año seleccionado
- Tabla con: días trabajados, horas totales, horas extra, recargos
- Monto bruto estimado
- Comparativa visual mes anterior
- Exportar/resumen imprimible

## 4. Features e Interacciones

### 4.1 Registro de Entrada/Salida
- **Trigger**: Tap en botón ENTRADA o SALIDA
- **Validación GPS**: Verifica que esté dentro del radio configurado (100m default)
- **Confirmación**: Modal con hora registrada y opción de agregar nota
- **Error GPS**: Alerta si está fuera del área, pero permite registrar con advertencia
- **Feedback**: Vibración y sonido de confirmación
- **Estado visual**: Botón cambia de verde (entrada) a rojo (salida)

### 4.2 Configuración de Salario
- **Input**: Valor numérico con formato de moneda local
- **Modo**: Seleccionar entre valor/hora o salario mensual fijo
- **Cálculo automático**: Aplica recargos según configuración
- **Validación**: No permite valores 0 o negativos

### 4.3 Tipos de Horas y Recargos
- **Horas normales**: 8 horas diarias (configurable)
- **Horas extra diurnas**: 125% del valor hora (configurable)
- **Horas extra nocturnas**: 150% del valor hora (configurable)
- **Recargo nocturno**: 35% adicional (9pm - 6am)
- **Recargo dominical/festivo**: 75% adicional
- **Combinación**: Dominical + nocturno = máxima tarifa

### 4.4 Estadísticas y Resumen
- **Por día**: Horas trabajadas, inicio/fin, duración
- **Por semana**: Total horas, extra, días trabajados
- **Por mes**: Totales, estimado de pago, сравнение con mes anterior
- **Visualización**: Gráficos de barras para distribución de horas

### 4.5 Recordatorios y Notificaciones
- **Antes de turno**: Notificación 30 min antes (configurable)
- **Inicio turno**: Recordatorio si no ha marcado entrada
- **Fin turno**: Alerta de hora de salida según horario
- **Implementación**: flutter_local_notifications

### 4.6 Validación GPS
- **Configuración**: Guardar coordenadas del lugar de trabajo
- **Radio**: 100-500 metros (configurable)
- **Validación**: Calcula distancia al registrar
- **Indicador**: Muestra distancia actual vs permitida
- **Fallback**: Permitir registro manual si GPS falla

### 4.7 Persistencia de Datos
- **Local**: SQLite (sqflite) para turnos y configuración
- **Modelo Turno**: id, fecha, horaEntrada, horaSalida, tipoTurno, notas, latitud, longitud
- **Modelo Config**: salario, tipoSalario, recargos, ubicacion, horarios

### 4.8 Historial y Edición
- **Lista**: chronological order, más reciente primero
- **Filtros**: por fecha, rango, tipo de turno
- **Edición**: permite cambiar hora entrada/salida, notas
- **Eliminación**: confirmación antes de borrar

## 5. Inventario de Componentes

### Botón Principal (Registro)
- Estados: default, pressed (scale 0.95), disabled, loading
- Tamaño: 80dp height, full width con padding
- Colores: Verde (#43A047) para entrada, Rojo (#E53935) para salida
- Icono: play_arrow / stop
- Texto: bold, 18sp

### Card de Turno
- Elevation: 2dp
- Padding: 16dp
- Contenido: fecha, horas, duración, badges de tipo
- Tap: navegación a detalle
- Badge colores: azul (normal), naranja (extra), rojo (nocturno), púrpura (dominical)

### Card de Resumen
- Fondo con gradiente sutil
- Icono grande a la izquierda
- Valores numéricos destacados
- Texto descriptivo pequeño

### Input de Número
- Formato automático de moneda
- Validación en tiempo real
- Sufijo "$" o "COP"
- Error state con mensaje

### Bottom Navigation
- 4 items con icono y label
- Indicator de item activo
- Badge en "Registrar" si hay turno abierto

### Modal de Confirmación
- Título centrado
- Detalles del registro
- Botones: Cancelar (outline), Confirmar (filled)
- Animación de entrada: slide up + fade

### Snackbar
- Aparece desde abajo
- Auto-dismiss en 3s
- Colores según tipo: success (verde), error (rojo), info (azul)

## 6. Enfoque Técnico

### Stack
- **Framework**: Flutter 3.47
- **Lenguaje**: Dart 3.13
- **Estado**: Provider (simple, escalable)
- **Persistencia**: sqflite + shared_preferences
- **Notificaciones**: flutter_local_notifications
- **GPS**: geolocator + geocoding
- **UI**: Material Design 3

### Arquitectura
```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── shift.dart
│   ├── config.dart
│   └── earnings.dart
├── providers/
│   ├── shift_provider.dart
│   ├── config_provider.dart
│   └── earnings_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── register_screen.dart
│   ├── history_screen.dart
│   ├── shift_detail_screen.dart
│   ├── settings_screen.dart
│   └── monthly_summary_screen.dart
├── widgets/
│   ├── shift_card.dart
│   ├── summary_card.dart
│   ├── clock_display.dart
│   ├── earnings_indicator.dart
│   └── gps_indicator.dart
├── services/
│   ├── database_service.dart
│   ├── notification_service.dart
│   └── location_service.dart
└── utils/
    ├── constants.dart
    ├── formatters.dart
    └── calculations.dart
```

### Dependencias Clave
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  sqflite: ^2.3.3
  shared_preferences: ^2.2.3
  flutter_local_notifications: ^17.2.3
  geolocator: ^12.0.0
  intl: ^0.19.0
  uuid: ^4.4.2
```

### Cálculos de Nómina
```
Valor Hora = Salario Mensual / (30 días × 8 horas)

Horas Extra Diurnas = horas × 1.25
Horas Extra Nocturnas = horas × 1.50
Recargo Nocturno (9pm-6am) = horas × 0.35
Recargo Dominical/Festivo = horas × 0.75
```

### Persistencia
- **Turnos**: Tabla SQLite con todos los registros
- **Config**: SharedPreferences para settings del usuario
- **Backup**: Exportar a JSON (próxima feature)
