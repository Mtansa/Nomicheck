import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Formulario para corregir las horas, el tipo y las notas de un turno.
///
/// Devuelve el turno editado con `Navigator.pop(context, shift)`.
class EditShiftScreen extends StatefulWidget {
  final Shift shift;

  const EditShiftScreen({super.key, required this.shift});

  @override
  State<EditShiftScreen> createState() => _EditShiftScreenState();
}

class _EditShiftScreenState extends State<EditShiftScreen> {
  late DateTime _entryTime = widget.shift.entryTime;
  late DateTime _exitTime = widget.shift.exitTime ?? widget.shift.entryTime;
  late ShiftType _type = widget.shift.type;
  late final TextEditingController _notesController =
      TextEditingController(text: widget.shift.notes ?? '');
  late bool _hasExit = widget.shift.exitTime != null;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isEntry}) async {
    final current = isEntry ? _entryTime : _exitTime;

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 1),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    setState(() {
      final picked = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isEntry) {
        _entryTime = picked;
      } else {
        _exitTime = picked;
      }
      _error = null;
    });
  }

  void _save() {
    if (_hasExit && !_exitTime.isAfter(_entryTime)) {
      setState(() => _error = 'La salida debe ser posterior a la entrada');
      return;
    }

    final notes = _notesController.text.trim();
    final edited = Shift(
      id: widget.shift.id,
      entryTime: _entryTime,
      exitTime: _hasExit ? _exitTime : null,
      type: _type,
      notes: notes.isEmpty ? null : notes,
      latitude: widget.shift.latitude,
      longitude: widget.shift.longitude,
    );

    Navigator.pop(context, edited);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Turno'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Hora de entrada'),
                    subtitle: Text(AppFormatters.formatDateTime(_entryTime)),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _pickDateTime(isEntry: true),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Turno cerrado'),
                    subtitle: const Text('Desactívalo si el turno sigue en curso'),
                    value: _hasExit,
                    onChanged: (value) {
                      setState(() {
                        _hasExit = value;
                        _error = null;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  if (_hasExit) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Hora de salida'),
                      subtitle: Text(AppFormatters.formatDateTime(_exitTime)),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _pickDateTime(isEntry: false),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Turno',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: ShiftType.values.map((type) {
                        final isSelected = _type == type;
                        return ChoiceChip(
                          label: Text(type.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _type = type);
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
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
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  ),
                ),
                child: const Text(
                  'GUARDAR CAMBIOS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
