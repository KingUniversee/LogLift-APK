import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/active_workout_provider.dart';
import '../history/workout_history_screen.dart';
import '../home/home_screen.dart';
import '../progress/progress_screen.dart';
import '../reports/reports_tab_view.dart';
import '../workout_plans/workout_plans_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Check for any active session to resume
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeWorkoutProvider.notifier).checkResumeInterruptedWorkout();
    });
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigateToTab: _onTabSelected),
      const WorkoutPlansScreen(),
      const WorkoutHistoryScreen(),
      const ProgressScreen(),
      const ReportsTabView(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF090E1A).withValues(alpha: 0.82),
              border: const Border(
                top: BorderSide(color: AppColors.borderGlass, width: 1),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTabSelected,
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primary.withValues(alpha: 0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.view_agenda_outlined),
                  selectedIcon: Icon(Icons.view_agenda_rounded),
                  label: 'Workouts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: 'Progress',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assessment_outlined),
                  selectedIcon: Icon(Icons.assessment_rounded),
                  label: 'Reports',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
