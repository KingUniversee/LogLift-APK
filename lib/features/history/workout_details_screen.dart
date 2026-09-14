import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/workout_session.dart';

class WorkoutDetailsScreen extends StatelessWidget {
  const WorkoutDetailsScreen({required this.session, super.key});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d, y · h:mm a').format(session.startedAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.planName),
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
                Text(
                  session.planName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Metrics Grid
                Row(
                  children: [
                    Expanded(child: _metric('Duration', '${session.durationMinutes} min', Icons.timer_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _metric('Volume', '${session.totalVolume.toStringAsFixed(0)} kg', Icons.fitness_center_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _metric('Sets', '${session.completedSets}', Icons.layers_outlined)),
                  ],
                ),
                const SizedBox(height: 24),

                // Exercises & Sets
                const Text(
                  'Exercises & Sets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                ...session.logs.map((log) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log.exerciseName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${log.totalVolume.toStringAsFixed(0)} kg',
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),

                          // Sets table
                          ...log.sets.map((set) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      'Set ${set.setNumber}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      '${set.weightKg.toStringAsFixed(set.weightKg.truncateToDouble() == set.weightKg ? 0 : 1)} kg × ${set.reps} reps',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                  if (set.notes.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        set.notes,
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  Icon(
                                    set.completed ? Icons.check_circle_rounded : Icons.cancel_outlined,
                                    color: set.completed ? AppColors.accentGreen : AppColors.textMuted,
                                    size: 18,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
