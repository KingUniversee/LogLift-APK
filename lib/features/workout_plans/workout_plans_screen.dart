import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_empty_state.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/workout_plan.dart';
import '../../providers/app_providers.dart';
import '../active_workout/start_workout_screen.dart';
import 'create_workout_plan_screen.dart';

class WorkoutPlansScreen extends ConsumerStatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  ConsumerState<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends ConsumerState<WorkoutPlansScreen> {
  final _searchController = TextEditingController();
  int _selectedTab = 0; // 0: My Plans, 1: Templates

  final _cardColors = const [
    Color(0xFF3B82F6),
    Color(0xFF8DE2C5),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPlanOptions(BuildContext context, WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.borderGlassHighlight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              plan.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: AppColors.primaryLight),
              title: const Text('Start Workout', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => StartWorkoutScreen(plan: plan)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white70),
              title: const Text('Edit Plan', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreateWorkoutPlanScreen(existingPlan: plan)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white70),
              title: const Text('Duplicate Plan', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(workoutPlansProvider.notifier).duplicatePlan(plan.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
              title: const Text('Delete Plan', style: TextStyle(color: AppColors.accentRose)),
              onTap: () async {
                Navigator.pop(context);
                _confirmDelete(plan);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${plan.name}"?'),
        content: const Text(
          'This will delete the workout plan. Completed workout sessions associated with this plan will be preserved in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(workoutPlansProvider.notifier).deletePlan(plan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(workoutPlansProvider);

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateWorkoutPlanScreen()),
            );
          },
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Workouts',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                        tooltip: 'Create Workout Plan',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateWorkoutPlanScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pill Tabs: My Plans / Templates
                  Row(
                    children: [
                      _tabPill(0, 'My Plans'),
                      const SizedBox(width: 10),
                      _tabPill(1, 'Templates'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  GlassTextField(
                    controller: _searchController,
                    hint: 'Search workout plans...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (q) => ref.read(workoutPlansProvider.notifier).search(q),
                  ),
                  const SizedBox(height: 16),

                  // Content list
                  Expanded(
                    child: plansAsync.when(
                      data: (plans) {
                        if (_selectedTab == 1) {
                          return const GlassEmptyState(
                            title: 'Templates',
                            message: 'Pre-made workout routines will be available here, or create your own custom routine.',
                            icon: Icons.view_agenda_outlined,
                            compact: true,
                          );
                        }

                        if (plans.isEmpty) {
                          return GlassEmptyState(
                            title: 'No workout plans yet',
                            message: 'Create your first workout plan to organize your exercises, target sets, and training days.',
                            icon: Icons.fitness_center_rounded,
                            actionLabel: 'Create Workout Plan',
                            onAction: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CreateWorkoutPlanScreen()),
                              );
                            },
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: plans.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            final color = _cardColors[plan.colorIndex % _cardColors.length];

                            return GlassCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => StartWorkoutScreen(plan: plan)),
                                );
                              },
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.fitness_center_rounded, color: color, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${plan.daysFormatted} · ${plan.exercises.length} exercises · ${plan.estimatedDurationMinutes}m',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
                                    onPressed: () => _showPlanOptions(context, plan),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.accentRose),
                              const SizedBox(height: 12),
                              Text(
                                err.toString().replaceAll('Exception: ', ''),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => ref.invalidate(workoutPlansProvider),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _tabPill(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderGlass,
              width: 1,
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
