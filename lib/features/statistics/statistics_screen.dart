import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_empty_state.dart';
import '../../core/widgets/glass_stat_card.dart';
import '../../data/models/workout_session.dart';
import '../../providers/app_providers.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _selectedTab = 0; // 0: Overview, 1: Volume, 2: Strength, 3: Cardio
  final _tabs = ['Overview', 'Volume', 'Strength', 'Cardio'];

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(overallStatsProvider);
    final sessionsAsync = ref.watch(completedSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // Top Segmented Tabs
                Row(
                  children: List.generate(_tabs.length, (i) {
                    final isSelected = _selectedTab == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: Container(
                          margin: EdgeInsets.only(right: i == _tabs.length - 1 ? 0 : 6),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surfaceGlass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : AppColors.borderGlass,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _tabs[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                statsAsync.when(
                  data: (stats) {
                    if (stats.totalWorkouts == 0) {
                      return const GlassEmptyState(
                        title: 'No statistics yet',
                        message: 'Complete workouts to calculate your average duration, volume metrics, and PRs.',
                        icon: Icons.stacked_bar_chart_rounded,
                      );
                    }

                    return Column(
                      children: [
                        // 4 Primary Metric Cards Grid
                        Row(
                          children: [
                            Expanded(
                              child: GlassStatCard(
                                label: 'Avg. Duration',
                                value: '${stats.averageDurationMinutes} min',
                                icon: Icons.timer_outlined,
                                iconColor: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassStatCard(
                                label: 'Avg. Volume',
                                value: '${stats.averageVolume.toStringAsFixed(0)} kg',
                                icon: Icons.fitness_center_rounded,
                                iconColor: AppColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GlassStatCard(
                                label: 'Workout Streak',
                                value: '${stats.currentStreak} ${stats.currentStreak == 1 ? 'day' : 'days'}',
                                icon: Icons.local_fire_department_rounded,
                                iconColor: AppColors.accentAmber,
                                subtitle: 'Best: ${stats.longestStreak} days',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassStatCard(
                                label: 'Personal Records',
                                value: '${stats.prCount}',
                                icon: Icons.emoji_events_rounded,
                                iconColor: AppColors.accentPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Progress Trend Line Chart
                        _buildLineTrendCard(sessionsAsync.value ?? []),
                      ],
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

  Widget _buildLineTrendCard(List<WorkoutSession> sessions) {
    final completed = sessions.where((s) => s.status == WorkoutStatus.completed).toList();
    if (completed.isEmpty) return const SizedBox();

    // Last 10 workouts trend points
    final count = completed.length < 10 ? completed.length : 10;
    final slice = completed.reversed.toList().sublist(completed.length - count);

    final spots = <FlSpot>[];
    for (var i = 0; i < slice.length; i++) {
      spots.add(FlSpot(i.toDouble(), slice[i].totalVolume));
    }

    final maxVolume = slice.fold<double>(0.0, (m, s) => s.totalVolume > m ? s.totalVolume : m);
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
                'Progress Trend',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Volume (kg)', style: TextStyle(fontSize: 11, color: AppColors.primaryLight)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: safeMax * 1.2,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)} kg',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primaryLight,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryLight.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
