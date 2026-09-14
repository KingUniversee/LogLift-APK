import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_empty_state.dart';
import '../../providers/app_providers.dart';
import '../../services/report_service.dart';
import 'share_report_modal.dart';

class ReportsTabView extends ConsumerStatefulWidget {
  const ReportsTabView({super.key});

  @override
  ConsumerState<ReportsTabView> createState() => _ReportsTabViewState();
}

class _ReportsTabViewState extends ConsumerState<ReportsTabView> {
  ReportPeriod _period = ReportPeriod.daily;
  DateTime _currentDate = DateTime.now();

  void _navigateDate(int delta) {
    setState(() {
      switch (_period) {
        case ReportPeriod.daily:
          _currentDate = _currentDate.add(Duration(days: delta));
          break;
        case ReportPeriod.weekly:
          _currentDate = _currentDate.add(Duration(days: delta * 7));
          break;
        case ReportPeriod.monthly:
          _currentDate = DateTime(_currentDate.year, _currentDate.month + delta, 1);
          break;
        case ReportPeriod.yearly:
          _currentDate = DateTime(_currentDate.year + delta, 1, 1);
          break;
      }
    });
  }

  void _openShareModal(ReportData report) {
    showGlassBottomSheet(
      context: context,
      builder: (_) => ShareReportModal(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(completedSessionsProvider);
    final prsAsync = ref.watch(allPrsProvider);
    final exercisesAsync = ref.watch(exercisesProvider);
    final reportService = ref.watch(reportServiceProvider);

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
                  'Reports',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Period Selector Tabs: Daily, Weekly, Monthly, Yearly
                Row(
                  children: [
                    _periodTab(ReportPeriod.daily, 'Daily'),
                    const SizedBox(width: 8),
                    _periodTab(ReportPeriod.weekly, 'Weekly'),
                    const SizedBox(width: 8),
                    _periodTab(ReportPeriod.monthly, 'Monthly'),
                    const SizedBox(width: 8),
                    _periodTab(ReportPeriod.yearly, 'Yearly'),
                  ],
                ),
                const SizedBox(height: 16),

                sessionsAsync.when(
                  data: (sessions) {
                    final report = reportService.generateReport(
                      period: _period,
                      targetDate: _currentDate,
                      allSessions: sessions,
                      allPrs: prsAsync.value ?? [],
                      allExercises: exercisesAsync.value ?? [],
                    );

                    return Column(
                      children: [
                        // Date Navigation Bar (< Date >)
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                                onPressed: () => _navigateDate(-1),
                              ),
                              Text(
                                report.dateRangeLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                                onPressed: () => _navigateDate(1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Empty State if no workouts in this period
                        if (report.workoutCount == 0)
                          GlassEmptyState(
                            title: 'No report available',
                            message: 'No workouts were recorded for ${report.dateRangeLabel}. Complete a workout to generate analytics.',
                            icon: Icons.assessment_outlined,
                            compact: true,
                          )
                        else ...[
                          // Period Specific Layout
                          if (_period == ReportPeriod.daily)
                            _buildDailyView(report)
                          else if (_period == ReportPeriod.weekly)
                            _buildWeeklyView(report)
                          else if (_period == ReportPeriod.monthly)
                            _buildMonthlyView(report)
                          else
                            _buildYearlyView(report),

                          const SizedBox(height: 24),

                          // Export PDF & Share Actions
                          Row(
                            children: [
                              Expanded(
                                child: GlassButton(
                                  label: 'Export PDF',
                                  icon: Icons.picture_as_pdf_rounded,
                                  variant: GlassButtonVariant.secondary,
                                  onPressed: () => _openShareModal(report),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GlassButton(
                                  label: 'Share',
                                  icon: Icons.ios_share_rounded,
                                  onPressed: () => _openShareModal(report),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildDailyView(ReportData report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Workouts', '${report.workoutCount}', Icons.fitness_center_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Duration', '${report.durationMinutes} min', Icons.timer_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Exercises', '${report.exercisesCount}', Icons.format_list_numbered_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Sets', '${report.sets}', Icons.layers_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Reps', '${report.reps}', Icons.repeat_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Volume', '${report.volume.toStringAsFixed(0)} kg', Icons.stacked_line_chart_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyView(ReportData report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Workouts', '${report.workoutCount}', Icons.fitness_center_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Total Time', '${report.durationMinutes} min', Icons.timer_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Total Sets', '${report.sets}', Icons.layers_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Total Reps', '${report.reps}', Icons.repeat_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        _buildMuscleListCard(report.muscleDistribution),
      ],
    );
  }

  Widget _buildMonthlyView(ReportData report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Workouts', '${report.workoutCount}', Icons.fitness_center_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Total Volume', '${report.volume.toStringAsFixed(0)} kg', Icons.fitness_center_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Total Duration', '${report.durationMinutes} min', Icons.timer_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('PRs', '${report.prs.length}', Icons.emoji_events_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        _buildMuscleListCard(report.muscleDistribution),
      ],
    );
  }

  Widget _buildYearlyView(ReportData report) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final maxV = report.monthlyBreakdown.fold<double>(0.0, (m, v) => v > m ? v : m);
    final safeMax = maxV == 0 ? 100.0 : maxV;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Total Workouts', '${report.workoutCount}', Icons.fitness_center_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Total Duration', '${report.durationMinutes} min', Icons.timer_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Total Sets', '${report.sets}', Icons.layers_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Total Reps', '${report.reps}', Icons.repeat_rounded)),
          ],
        ),
        const SizedBox(height: 16),

        // Monthly Breakdown Chart
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: safeMax * 1.2,
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= months.length) return const SizedBox();
                            return Text(months[idx].substring(0, 1), style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(12, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: report.monthlyBreakdown[i],
                            color: AppColors.primary,
                            width: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMuscleListCard(Map<dynamic, double> distribution) {
    if (distribution.isEmpty) return const SizedBox();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Muscle Groups', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 16),
          ...distribution.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.displayName, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      Text('${e.value.round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / 100,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _periodTab(ReportPeriod period, String label) {
    final isSelected = _period == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = period),
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
                fontSize: 12,
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
