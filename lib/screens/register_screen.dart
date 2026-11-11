import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/shift_provider.dart';
import '../providers/config_provider.dart';
import '../models/shift.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/gps_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  bool _locationValid = false;
  bool _manualTimeEnabled = false;
  double? _distance;
  final _notesController = TextEditingController();
  ShiftType _selectedType = ShiftType.normal;
  DateTime _manualEntryTime = DateTime.now();
  DateTime _manualExitTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    final config = context.read<ConfigProvider>().config;
    if (!config.hasWorkLocation) return;

    final result = await LocationService.validateLocation(
      workLat: config.workLatitude,
      workLon: config.workLongitude,
      radius: config.gpsRadius,
    );

    if (mounted) {
      setState(() {
        _locationValid = result['valid'] ?? false;
        _distance = result['distance'];
      });
    }
  }

  Future<void> _selectManualEntryTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _manualEntryTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_manualEntryTime),
      );

      if (time != null) {
        setState(() {
          _manualEntryTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectManualExitTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _manualExitTime,
      firstDate: _manualEntryTime,
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_manualExitTime),
      );

      if (time != null) {
        setState(() {
          _manualExitTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _registerEntry() async {
    setState(() => _isLoading = true);

    try {
      final config = context.read<ConfigProvider>().config;
      double? lat, lon;

      if (config.hasWorkLocation && !_manualTimeEnabled) {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          lat = position.latitude;
          lon = position.longitude;
        }
      }

      final entryTime = _manualTimeEnabled ? _manualEntryTime : DateTime.now();

      await context.read<ShiftProvider>().registerEntry(
        type: _selectedType,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        latitude: lat,
        longitude: lon,
        manualEntryTime: entryTime,
      );

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entrada registrada a las ${AppFormatters.formatTime(entryTime)}',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Salida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Deseas registrar tu salida ahora?'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final exitTime = _manualTimeEnabled ? _manualExitTime : DateTime.now();

      await context.read<ShiftProvider>().registerExit(
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        manualExitTime: exitTime,
      );

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Salida registrada a las ${AppFormatters.formatTime(exitTime)}',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Turno'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<ShiftProvider>(
        builder: (context, shiftProvider, child) {
          final hasOpenShift = shiftProvider.hasOpenShift;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Hora manual'),
                          subtitle: const Text('Ingresar hora manualmente'),
                          value: _manualTimeEnabled,
                          onChanged: (value) {
                            setState(() => _manualTimeEnabled = value);
                          },
                          activeColor: AppColors.primary,
                        ),
                        if (_manualTimeEnabled && !hasOpenShift) ...[
                          const SizedBox(height: AppSpacing.sm),
                          ListTile(
                            title: const Text('Hora de entrada'),
                            subtitle: Text(AppFormatters.formatDateTime(_manualEntryTime)),
                            trailing: const Icon(Icons.edit),
                            onTap: _selectManualEntryTime,
                          ),
                        ],
                        if (_manualTimeEnabled && hasOpenShift) ...[
                          const SizedBox(height: AppSpacing.sm),
                          ListTile(
                            title: const Text('Hora de salida'),
                            subtitle: Text(AppFormatters.formatDateTime(_manualExitTime)),
                            trailing: const Icon(Icons.edit),
                            onTap: _selectManualExitTime,
                          ),
                        ],
                        if (hasOpenShift) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.timer,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Turno en curso: ${AppFormatters.formatDuration(shiftProvider.openShift!.duration)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (context.read<ConfigProvider>().config.hasWorkLocation)
                  GpsIndicator(
                    isValid: _locationValid,
                    distance: _distance,
                    maxDistance: context.read<ConfigProvider>().config.gpsRadius,
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (!hasOpenShift) ...[
                  const Text(
                    'Tipo de Turno',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: ShiftType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedType = type);
                          }
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      hintText: 'Agrega una nota sobre este turno',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (hasOpenShift ? _registerExit : _registerEntry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasOpenShift ? AppColors.error : AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasOpenShift ? Icons.stop : Icons.play_arrow,
                                size: 32,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                hasOpenShift ? 'REGISTRAR SALIDA' : 'REGISTRAR ENTRADA',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
