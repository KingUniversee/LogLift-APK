import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_empty_state.dart';
import '../../core/widgets/glass_stat_card.dart';
import '../../data/models/workout_plan.dart';
import '../../data/models/workout_session.dart';
import '../../providers/active_workout_provider.dart';
import '../../providers/app_providers.dart';
import '../active_workout/active_workout_screen.dart';
import '../active_workout/start_workout_screen.dart';
import '../personal_records/personal_records_screen.dart';
import '../settings/settings_screen.dart';
import '../workout_plans/create_workout_plan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({required this.onNavigateToTab, super.key});

  final ValueChanged<int> onNavigateToTab;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayPlanAsync = ref.watch(todayPlanProvider);
    final statsAsync = ref.watch(overallStatsProvider);
    final sessionsAsync = ref.watch(completedSessionsProvider);
    final prsAsync = ref.watch(allPrsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.liquidBackgroundGradient,
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                // Top App Bar / Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profileAsync.value?.name.isNotEmpty == true
                              ? 'Welcome back, ${profileAsync.value!.name}'
                              : "Let's build a stronger you.",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                          tooltip: 'Settings',
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.accentGlowGradient,
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.person, size: 20, color: Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Active Workout Resume Banner (if workout in progress)
                if (activeWorkout.hasActiveWorkout) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentAmber.withValues(alpha: 0.25),
                        AppColors.primary.withValues(alpha: 0.15),
                      ],
                    ),
                    borderColor: AppColors.accentAmber.withValues(alpha: 0.5),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_circle_fill_rounded, color: AppColors.accentAmber, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Workout In Progress',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${activeWorkout.session!.planName} · ${(activeWorkout.elapsedSeconds / 60).floor()} min',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Resume',
                          style: TextStyle(
                            color: AppColors.accentAmber,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.accentAmber, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Today's Planned Workout Section
                todayPlanAsync.when(
                  data: (plan) => _buildTodayPlanHero(context, ref, plan),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _buildTodayPlanHero(context, ref, null),
                ),
                const SizedBox(height: 24),

                // This Week & Current Streak (2-column stat cards)
                statsAsync.when(
                  data: (stats) {
                    final completedThisWeek = sessionsAsync.value
                            ?.where((s) => s.status == WorkoutStatus.completed && s.startedAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
                            .length ??
                        0;

                    return Row(
                      children: [
                        Expanded(
                          child: GlassStatCard(
                            label: 'This Week',
                            value: '$completedThisWeek',
                            icon: Icons.calendar_today_rounded,
                            iconColor: AppColors.primaryLight,
                            subtitle: completedThisWeek > 0 ? '$completedThisWeek workouts logged' : 'No workouts yet',
                            onTap: () => onNavigateToTab(2), // History tab
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GlassStatCard(
                            label: 'Current Streak',
                            value: '${stats.currentStreak} ${stats.currentStreak == 1 ? 'day' : 'days'}',
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppColors.accentAmber,
                            subtitle: stats.longestStreak > 0 ? 'Best: ${stats.longestStreak} days' : 'Keep showing up',
                            onTap: () => onNavigateToTab(3), // Progress tab
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 110),
                  error: (err, stack) => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // Recent Progress Bar Chart
                _buildRecentProgressCard(context, sessionsAsync.value ?? []),
                const SizedBox(height: 24),

                // Personal Records Card Preview
                prsAsync.when(
                  data: (prs) => _buildPersonalRecordsCard(context, prs),
                  loading: () => const SizedBox(),
                  error: (err, stack) => const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPlanHero(BuildContext context, WidgetRef ref, WorkoutPlan? plan) {
    if (plan == null) {
      return GlassEmptyState(
        title: "No workout scheduled for today",
        message: "Create your first workout plan or start an open session to track sets and volume.",
        icon: Icons.calendar_month_outlined,
        actionLabel: "Create Workout Plan",
        compact: true,
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateWorkoutPlanScreen()),
          );
        },
      );
    }

    final totalSets = plan.exercises.fold<int>(0, (sum, e) => sum + e.targetSets);

    return GlassCard(
      padding: const EdgeInsets.all(22),
      gradient: AppColors.heroCardGradient,
      borderColor: AppColors.borderGlassHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fitness_center_rounded, size: 14, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "TODAY'S WORKOUT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 20),

          // 3 Metrics Pill Row
          Row(
            children: [
              _metricPill(context, Icons.format_list_numbered_rounded, '${plan.exercises.length}', 'Exercises'),
              const SizedBox(width: 10),
              _metricPill(context, Icons.layers_outlined, '$totalSets', 'Sets'),
              const SizedBox(width: 10),
              _metricPill(context, Icons.timer_outlined, '${plan.estimatedDurationMinutes}m', 'Duration'),
            ],
          ),
          const SizedBox(height: 22),

          GlassButton(
            label: 'Start Workout',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StartWorkoutScreen(plan: plan)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metricPill(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGlass),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: AppColors.primaryLight),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProgressCard(BuildContext context, List<WorkoutSession> sessions) {
    final completed = sessions.where((s) => s.status == WorkoutStatus.completed).toList();

    if (completed.isEmpty) {
      return const GlassEmptyState(
        title: 'Recent Progress',
        message: 'Complete your first workout to generate real volume and set trends.',
        icon: Icons.insights_rounded,
        compact: true,
      );
    }

    // 7-day daily volume calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final volumes = <double>[];

    for (final day in days) {
      final daySessions = completed.where((s) {
        final sDate = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
        return sDate.isAtSameMomentAs(day);
      });
      final vol = daySessions.fold<double>(0.0, (sum, s) => sum + s.totalVolume);
      volumes.add(vol);
    }

    final maxVolume = volumes.fold<double>(0.0, (m, v) => v > m ? v : m);
    final safeMax = maxVolume == 0 ? 100.0 : maxVolume;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Last 7 Days',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: safeMax * 1.15,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)} kg',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('E').format(days[index]).substring(0, 1),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: volumes[i],
                        color: i == 6 ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.4),
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRecordsCard(BuildContext context, List<dynamic> prs) {
    return GlassCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PersonalRecordsScreen()),
        );
      },
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentAmber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: AppColors.accentAmber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Records',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  prs.isEmpty ? 'No personal records yet' : '${prs.length} career PRs unlocked',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
        ],
      ),
    );
  }
}
