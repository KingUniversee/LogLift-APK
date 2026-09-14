import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/workout_session.dart';

class LogSetModal extends StatefulWidget {
  const LogSetModal({
    required this.exerciseName,
    required this.setLog,
    required this.onSave,
    super.key,
  });

  final String exerciseName;
  final SetLog setLog;
  final void Function(double weight, int reps, int restSeconds, String notes) onSave;

  @override
  State<LogSetModal> createState() => _LogSetModalState();
}

class _LogSetModalState extends State<LogSetModal> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _restController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.setLog.weightKg > 0 ? widget.setLog.weightKg.toStringAsFixed(widget.setLog.weightKg.truncateToDouble() == widget.setLog.weightKg ? 0 : 1) : '',
    );
    _repsController = TextEditingController(
      text: widget.setLog.reps > 0 ? '${widget.setLog.reps}' : '',
    );
    _restController = TextEditingController(text: '60');
    _notesController = TextEditingController(text: widget.setLog.notes);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;
    final rest = int.tryParse(_restController.text.trim()) ?? 60;
    final notes = _notesController.text.trim();

    widget.onSave(weight, reps, rest, notes);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Set',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.exerciseName} · Set ${widget.setLog.setNumber}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GlassTextField(
                  controller: _repsController,
                  label: 'Reps',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GlassTextField(
            controller: _restController,
            label: 'Rest Time (seconds)',
            hint: '60',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          GlassTextField(
            controller: _notesController,
            label: 'Notes (optional)',
            hint: 'Felt light, good form...',
          ),
          const SizedBox(height: 26),

          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Cancel',
                  variant: GlassButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassButton(
                  label: 'Save',
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
