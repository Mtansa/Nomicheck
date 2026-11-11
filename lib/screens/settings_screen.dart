import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';
import '../models/config.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'monthly_summary_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _companyController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _monthlySalaryController;
  SalaryType _salaryType = SalaryType.hourly;
  bool _notificationsEnabled = true;
  int _reminderMinutes = 30;
  double _gpsRadius = 100;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    final config = context.read<ConfigProvider>().config;
    _nameController = TextEditingController(text: config.userName);
    _positionController = TextEditingController(text: config.position ?? '');
    _companyController = TextEditingController(text: config.company ?? '');
    _hourlyRateController = TextEditingController(
      text: config.hourlyRate > 0 ? config.hourlyRate.toString() : '',
    );
    _monthlySalaryController = TextEditingController(
      text: config.monthlySalary > 0 ? config.monthlySalary.toString() : '',
    );
    _salaryType = config.salaryType;
    _notificationsEnabled = config.notificationsEnabled;
    _reminderMinutes = config.reminderMinutesBefore;
    _gpsRadius = config.gpsRadius;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _companyController.dispose();
    _hourlyRateController.dispose();
    _monthlySalaryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final config = context.read<ConfigProvider>().config.copyWith(
      userName: _nameController.text,
      position: _positionController.text.isNotEmpty ? _positionController.text : null,
      company: _companyController.text.isNotEmpty ? _companyController.text : null,
    );
    await context.read<ConfigProvider>().saveConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  Future<void> _saveSalary() async {
    final hourlyRate = double.tryParse(_hourlyRateController.text) ?? 0;
    final monthlySalary = double.tryParse(_monthlySalaryController.text) ?? 0;

    final config = context.read<ConfigProvider>().config.copyWith(
      hourlyRate: hourlyRate,
      monthlySalary: monthlySalary,
      salaryType: _salaryType,
    );
    await context.read<ConfigProvider>().saveConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salario guardado'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  Future<void> _saveWorkLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener la ubicación'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await context.read<ConfigProvider>().updateWorkLocation(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación de trabajo guardada'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<ConfigProvider>(
        builder: (context, configProvider, child) {
          final config = configProvider.config;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Perfil'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _positionController,
                            decoration: const InputDecoration(
                              labelText: 'Puesto (opcional)',
                              prefixIcon: Icon(Icons.work),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Empresa (opcional)',
                              prefixIcon: Icon(Icons.business),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              child: const Text('Guardar Perfil'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('Salario'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de Salario',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SegmentedButton<SalaryType>(
                            segments: const [
                              ButtonSegment(
                                value: SalaryType.hourly,
                                label: Text('Por Hora'),
                                icon: Icon(Icons.access_time),
                              ),
                              ButtonSegment(
                                value: SalaryType.monthly,
                                label: Text('Mensual'),
                                icon: Icon(Icons.calendar_month),
                              ),
                            ],
                            selected: {_salaryType},
                            onSelectionChanged: (selected) {
                              setState(() => _salaryType = selected.first);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_salaryType == SalaryType.hourly)
                            TextFormField(
                              controller: _hourlyRateController,
                              decoration: const InputDecoration(
                                labelText: 'Valor por Hora',
                                prefixIcon: Icon(Icons.attach_money),
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                            )
                          else
                            TextFormField(
                              controller: _monthlySalaryController,
                              decoration: const InputDecoration(
                                labelText: 'Salario Mensual',
                                prefixIcon: Icon(Icons.attach_money),
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          if (config.effectiveHourlyRate > 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Valor hora calculado: ${AppFormatters.formatCurrency(config.effectiveHourlyRate)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveSalary,
                              child: const Text('Guardar Salario'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('Ubicación de Trabajo'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (config.hasWorkLocation) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ubicación configurada',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        Text(
                                          'Lat: ${config.workLatitude!.toStringAsFixed(6)}, Lon: ${config.workLongitude!.toStringAsFixed(6)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          Text(
                            'Radio de validación GPS: ${_gpsRadius.toInt()}m',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          Slider(
                            value: _gpsRadius,
                            min: 50,
                            max: 500,
                            divisions: 9,
                            label: '${_gpsRadius.toInt()}m',
                            onChanged: (value) {
                              setState(() => _gpsRadius = value);
                            },
                            onChangeEnd: (value) async {
                              final newConfig = config.copyWith(gpsRadius: value);
                              await context.read<ConfigProvider>().saveConfig(newConfig);
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _saveWorkLocation,
                              icon: const Icon(Icons.my_location),
                              label: Text(config.hasWorkLocation
                                  ? 'Actualizar Ubicación'
                                  : 'Guardar Ubicación Actual'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('Notificaciones'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Activar recordatorios'),
                            subtitle: const Text('Notificar antes de turno'),
                            value: _notificationsEnabled,
                            onChanged: (value) async {
                              setState(() => _notificationsEnabled = value);
                              await context.read<ConfigProvider>().updateNotifications(
                                enabled: value,
                              );
                            },
                          ),
                          if (_notificationsEnabled) ...[
                            const Divider(),
                            ListTile(
                              title: const Text('Minutos antes del turno'),
                              trailing: DropdownButton<int>(
                                value: _reminderMinutes,
                                items: [15, 30, 45, 60].map((m) {
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text('$m min'),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  if (value != null) {
                                    setState(() => _reminderMinutes = value);
                                    await context.read<ConfigProvider>().updateNotifications(
                                      enabled: true,
                                      minutesBefore: value,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('Cuenta'),
                  Card(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person, color: AppColors.primary),
                              title: const Text('Usuario'),
                              subtitle: Text(
                                authProvider.userEmail.isNotEmpty
                                    ? authProvider.userEmail
                                    : 'No iniciado sesión',
                              ),
                            ),
                            const Divider(),
                            Consumer<SyncProvider>(
                              builder: (context, syncProvider, child) {
                                final lastSync = syncProvider.lastSync;
                                return ListTile(
                                  leading: Icon(
                                    syncProvider.state == SyncState.error
                                        ? Icons.cloud_off
                                        : Icons.cloud_done,
                                    color: syncProvider.state == SyncState.error
                                        ? AppColors.error
                                        : AppColors.secondary,
                                  ),
                                  title: const Text('Sincronización'),
                                  subtitle: Text(
                                    syncProvider.state == SyncState.error
                                        ? (syncProvider.error ?? 'Error al sincronizar')
                                        : lastSync != null
                                            ? 'Sincronizado a las ${AppFormatters.formatTime(lastSync)}'
                                            : 'Pendiente de sincronización',
                                  ),
                                  trailing: syncProvider.isSyncing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.sync),
                                  onTap: syncProvider.isSyncing
                                      ? null
                                      : () => _handleSync(context),
                                );
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.logout, color: AppColors.error),
                              title: const Text(
                                'Cerrar Sesión',
                                style: TextStyle(color: AppColors.error),
                              ),
                              onTap: () => _handleLogout(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('Resumen'),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.summarize, color: AppColors.primary),
                      title: const Text('Ver Resumen Mensual'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MonthlySummaryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Future<void> _handleSync(BuildContext context) async {
    final syncProvider = context.read<SyncProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await syncProvider.sync();
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Datos sincronizados con el servidor'
            : (syncProvider.error ?? 'No se pudo sincronizar')),
        backgroundColor: ok ? AppColors.secondary : AppColors.error,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
