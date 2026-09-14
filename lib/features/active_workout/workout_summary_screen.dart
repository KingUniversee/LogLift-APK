import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/personal_record.dart';
import '../../data/models/workout_session.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({
    required this.session,
    this.newPrs = const [],
    super.key,
  });

  final WorkoutSession session;
  final List<PersonalRecord> newPrs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.liquidBackgroundGradient,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.accentGlowGradient,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.black, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Workout Complete!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.planName,
                          style: const TextStyle(fontSize: 15, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Metrics Summary Grid
                  Row(
                    children: [
                      Expanded(child: _metricTile('Duration', '${session.durationMinutes} min', Icons.timer_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _metricTile('Volume', '${session.totalVolume.toStringAsFixed(0)} kg', Icons.fitness_center_rounded)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _metricTile('Sets', '${session.completedSets}', Icons.layers_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _metricTile('Reps', '${session.totalReps}', Icons.repeat_rounded)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // PRs Earned Section
                  if (newPrs.isNotEmpty) ...[
                    const Text(
                      'New Personal Records!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accentAmber),
                    ),
                    const SizedBox(height: 10),
                    ...newPrs.map((pr) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          borderColor: AppColors.accentAmber.withValues(alpha: 0.4),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: AppColors.accentAmber, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${pr.exerciseName}: ${pr.recordType.displayName}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                              Text(
                                '${pr.value.toStringAsFixed(1)} ${pr.recordType.defaultUnit}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentAmber),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const Spacer(),
                  GlassButton(
                    label: 'Done',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
