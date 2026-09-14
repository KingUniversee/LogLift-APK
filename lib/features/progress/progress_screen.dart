import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_empty_state.dart';
import '../../core/widgets/glass_stat_card.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_session.dart';
import '../../providers/app_providers.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedFilterIndex = 1; // 0: 7D, 1: 30D, 2: 3M, 3: 6M, 4: 1Y, 5: All
  final _filters = ['7D', '30D', '3M', '6M', '1Y', 'All'];

  int _getFilterDays() {
    switch (_selectedFilterIndex) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 90;
      case 3:
        return 180;
      case 4:
        return 365;
      default:
        return 3650;
    }
  }

  final _muscleColors = const [
    Color(0xFF3B82F6), // Blue - Chest
    Color(0xFF8DE2C5), // Mint - Back
    Color(0xFFA78BFA), // Violet - Legs
    Color(0xFFFBBF24), // Gold - Shoulders
    Color(0xFFF43F5E), // Rose - Arms
    Color(0xFF10B981), // Green - Core
    Color(0xFF60A5FA), // Light blue - Cardio
    Color(0xFF94A3B8), // Slate - Full Body
  ];

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(completedSessionsProvider);
    final statsAsync = ref.watch(overallStatsProvider);

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
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Time filter pills
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedFilterIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilterIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceGlass,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : AppColors.borderGlass,
                            ),
                          ),
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                sessionsAsync.when(
                  data: (allSessions) {
                    final completed = allSessions.where((s) => s.status == WorkoutStatus.completed).toList();

                    if (completed.isEmpty) {
                      return const GlassEmptyState(
                        title: 'Not enough data yet',
                        message: 'Complete workouts to start seeing your volume trends, sets, and muscle distribution analytics.',
                        icon: Icons.insights_rounded,
                      );
                    }

                    // Filter sessions for selected range
                    final cutoff = DateTime.now().subtract(Duration(days: _getFilterDays()));
                    final filtered = completed.where((s) => !s.startedAt.isBefore(cutoff)).toList();

                    final totalVolume = filtered.fold<double>(0.0, (sum, s) => sum + s.totalVolume);
                    final totalSets = filtered.fold<int>(0, (sum, s) => sum + s.completedSets);

                    return Column(
                      children: [
                        // Total Workouts Chart Card
                        _buildTotalWorkoutsCard(filtered),
                        const SizedBox(height: 16),

                        // 2 Stat cards: Total Volume & Total Sets
                        Row(
                          children: [
                            Expanded(
                              child: GlassStatCard(
                                label: 'Total Volume',
                                value: '${totalVolume.toStringAsFixed(0)} kg',
                                icon: Icons.fitness_center_rounded,
                                iconColor: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: GlassStatCard(
                                label: 'Total Sets',
                                value: '$totalSets',
                                icon: Icons.layers_outlined,
                                iconColor: AppColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Muscle Group Distribution Donut Chart
                        statsAsync.when(
                          data: (stats) => _buildMuscleDistributionCard(stats.muscleDistribution),
                          loading: () => const SizedBox(),
                          error: (err, stack) => const SizedBox(),
                        ),
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

  Widget _buildTotalWorkoutsCard(List<WorkoutSession> sessions) {
    // Generate weekly or daily intervals for chart
    final pointsCount = 7;
    final volumes = List.generate(pointsCount, (i) {
      final start = DateTime.now().subtract(Duration(days: (pointsCount - i) * 4));
      final end = start.add(const Duration(days: 4));
      final match = sessions.where((s) => s.startedAt.isAfter(start) && s.startedAt.isBefore(end));
      return match.fold<double>(0.0, (sum, s) => sum + s.totalVolume);
    });

    final maxV = volumes.fold<double>(0.0, (m, v) => v > m ? v : m);
    final safeMax = maxV == 0 ? 100.0 : maxV;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Workouts', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${sessions.length}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active Training',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: safeMax * 1.2,
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
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(pointsCount, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: volumes[i],
                        color: i == pointsCount - 1 ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.35),
                        width: 22,
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

  Widget _buildMuscleDistributionCard(Map<MuscleGroup, double> distribution) {
    if (distribution.isEmpty) {
      return const SizedBox();
    }

    final entries = distribution.entries.toList();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muscle Group Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: entries.asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      final color = _muscleColors[idx % _muscleColors.length];
                      return PieChartSectionData(
                        color: color,
                        value: entry.value,
                        title: '',
                        radius: 22,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  children: entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final entry = e.value;
                    final color = _muscleColors[idx % _muscleColors.length];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.key.displayName,
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                          Text(
                            '${entry.value.round()}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
