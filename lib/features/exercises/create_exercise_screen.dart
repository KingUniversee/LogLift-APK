import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/exercise.dart';
import '../../providers/app_providers.dart';

class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({this.existingExercise, super.key});

  final Exercise? existingExercise;

  @override
  ConsumerState<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _notesController;

  late MuscleGroup _selectedMuscle;
  late ExerciseType _selectedType;
  late String _selectedEquipment;

  final _equipmentList = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Kettlebell',
    'Bodyweight',
    'None',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingExercise?.name ?? '');
    _instructionsController = TextEditingController(text: widget.existingExercise?.instructions ?? '');
    _notesController = TextEditingController(text: widget.existingExercise?.notes ?? '');

    _selectedMuscle = widget.existingExercise?.muscleGroup ?? MuscleGroup.chest;
    _selectedType = widget.existingExercise?.exerciseType ?? ExerciseType.strength;
    _selectedEquipment = widget.existingExercise?.equipment ?? 'Barbell';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }

    final exercise = Exercise(
      id: widget.existingExercise?.id ?? const Uuid().v4(),
      name: name,
      muscleGroup: _selectedMuscle,
      equipment: _selectedEquipment,
      exerciseType: _selectedType,
      instructions: _instructionsController.text.trim(),
      notes: _notesController.text.trim(),
      isCustom: true,
      createdAt: widget.existingExercise?.createdAt ?? DateTime.now(),
    );

    await ref.read(exercisesProvider.notifier).addExercise(exercise);

    if (mounted) {
      Navigator.of(context).pop(exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExercise != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Exercise' : 'Create Exercise'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saveExercise,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.liquidBackgroundGradient,
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                GlassTextField(
                  controller: _nameController,
                  label: 'Exercise Name',
                  hint: 'e.g. Incline Bench Press',
                  autofocus: !isEditing,
                ),
                const SizedBox(height: 18),

                // Muscle Group Dropdown
                _buildDropdown<MuscleGroup>(
                  label: 'Muscle Group',
                  value: _selectedMuscle,
                  items: MuscleGroup.values.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m.displayName));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMuscle = val);
                  },
                ),
                const SizedBox(height: 18),

                // Equipment Dropdown
                _buildDropdown<String>(
                  label: 'Equipment',
                  value: _selectedEquipment,
                  items: _equipmentList.map((eq) {
                    return DropdownMenuItem(value: eq, child: Text(eq));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedEquipment = val);
                  },
                ),
                const SizedBox(height: 18),

                // Exercise Type Dropdown
                _buildDropdown<ExerciseType>(
                  label: 'Exercise Type',
                  value: _selectedType,
                  items: ExerciseType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.displayName));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 18),

                GlassTextField(
                  controller: _instructionsController,
                  label: 'Instructions (Optional)',
                  hint: 'Keep back flat, grip slightly wider than shoulder width...',
                  maxLines: 3,
                ),
                const SizedBox(height: 18),

                GlassTextField(
                  controller: _notesController,
                  label: 'Notes / Tips (Optional)',
                  hint: 'Focus on slow eccentric tempo...',
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                GlassButton(
                  label: isEditing ? 'Update Exercise' : 'Create Exercise',
                  icon: Icons.check_rounded,
                  onPressed: _saveExercise,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
