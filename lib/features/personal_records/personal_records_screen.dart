import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_empty_state.dart';
import '../../data/models/personal_record.dart';
import '../../providers/app_providers.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  IconData _iconForPR(PRType type) {
    switch (type) {
      case PRType.highestWeight:
        return Icons.fitness_center_rounded;
      case PRType.mostReps:
        return Icons.repeat_rounded;
      case PRType.highestVolume:
        return Icons.stacked_line_chart_rounded;
      case PRType.longestDuration:
        return Icons.timer_outlined;
      case PRType.longestDistance:
        return Icons.directions_run_rounded;
    }
  }

  Color _colorForPR(PRType type) {
    switch (type) {
      case PRType.highestWeight:
        return AppColors.accentAmber;
      case PRType.mostReps:
        return AppColors.primaryLight;
      case PRType.highestVolume:
        return AppColors.accentCyan;
      case PRType.longestDuration:
        return AppColors.accentPurple;
      case PRType.longestDistance:
        return AppColors.accentGreen;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(allPrsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Records'),
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
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentAmber.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 40,
                      color: AppColors.accentAmber,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Career Highlights',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Automatically tracked and updated upon every completed session.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 28),

                prsAsync.when(
                  data: (prs) {
                    if (prs.isEmpty) {
                      return const GlassEmptyState(
                        title: 'No personal records yet',
                        message: 'Complete your workouts to set and track personal records across weight, volume, and reps.',
                        icon: Icons.emoji_events_outlined,
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final pr = prs[index];
                        final color = _colorForPR(pr.recordType);
                        final icon = _iconForPR(pr.recordType);
                        final dateFormatted = DateFormat('MMM d, y').format(pr.achievedAt);

                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: color.withValues(alpha: 0.3),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pr.recordType.displayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pr.exerciseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormatted,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${pr.value.toStringAsFixed(pr.value.truncateToDouble() == pr.value ? 0 : 1)} ${pr.recordType.defaultUnit}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
