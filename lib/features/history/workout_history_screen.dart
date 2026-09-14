import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_empty_state.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/workout_session.dart';
import '../../providers/app_providers.dart';
import 'workout_details_screen.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: All, 1: Workouts, 2: Plans

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteSession(WorkoutSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: Text('Are you sure you want to delete the workout from ${DateFormat('MMM d, y').format(session.startedAt)}? This will remove its sets and recalculate statistics.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () {
              Navigator.pop(context);
              ref.read(completedSessionsProvider.notifier).deleteSession(session.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(completedSessionsProvider);

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Segmented Tabs: All, Workouts, Plans
                  Row(
                    children: [
                      _filterTab(0, 'All'),
                      const SizedBox(width: 8),
                      _filterTab(1, 'Workouts'),
                      const SizedBox(width: 8),
                      _filterTab(2, 'Plans'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search input
                  GlassTextField(
                    controller: _searchController,
                    hint: 'Search workout history...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (q) => ref.read(completedSessionsProvider.notifier).filter(query: q),
                  ),
                  const SizedBox(height: 16),

                  // History list
                  Expanded(
                    child: sessionsAsync.when(
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return const GlassEmptyState(
                            title: 'No workouts yet',
                            message: 'Complete your first workout and it will appear here with detailed logs, volumes, and records.',
                            icon: Icons.calendar_month_rounded,
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: sessions.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            final dateFormatted = DateFormat('MMM d, y · h:mm a').format(session.startedAt);

                            return GlassCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WorkoutDetailsScreen(session: session),
                                  ),
                                );
                              },
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center_rounded,
                                      color: AppColors.primaryLight,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session.planName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$dateFormatted · ${session.durationMinutes} min',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${session.logs.length} exercises · ${session.completedSets} sets · ${session.totalVolume.toStringAsFixed(0)} kg',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                                    onPressed: () => _confirmDeleteSession(session),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : AppColors.borderGlass,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
