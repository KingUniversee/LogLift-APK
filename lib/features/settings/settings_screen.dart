import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_config.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/server_settings_dialog.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../auth/login_screen.dart';
import '../personal_records/personal_records_screen.dart';
import '../statistics/statistics_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final json = await ref.read(settingsRepoProvider).exportAllDataAsJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database backup copied to clipboard!')),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderGlassHighlight),
        ),
        title: const Text(
          'Log Out of LiftLog?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to log out? Your workouts, plans, and history will remain safely stored on your account.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(userProfileProvider.notifier).logout();
      ref.invalidate(exercisesProvider);
      ref.invalidate(workoutPlansProvider);
      ref.invalidate(completedSessionsProvider);
      ref.invalidate(allPrsProvider);
      ref.invalidate(overallStatsProvider);
      ref.invalidate(todayPlanProvider);

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                // User Profile Header Card
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.accentGlowGradient,
                        ),
                        child: const Icon(Icons.person, color: Colors.black, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileAsync.value?.name.isNotEmpty == true ? profileAsync.value!.name : 'Fitness Enthusiast',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profileAsync.value?.email.isNotEmpty == true ? profileAsync.value!.email : 'Signed in via Cloud Account',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (profileAsync.value != null)
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.accentRose),
                          tooltip: 'Sign Out',
                          onPressed: () => _handleLogout(context, ref),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Analytics & Records', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.stacked_bar_chart_rounded, color: AppColors.primaryLight),
                        title: const Text('Statistics Overview', style: TextStyle(color: Colors.white, fontSize: 15)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      ListTile(
                        leading: const Icon(Icons.emoji_events_rounded, color: AppColors.accentAmber),
                        title: const Text('Personal Records', style: TextStyle(color: Colors.white, fontSize: 15)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PersonalRecordsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Preferences & Units
                const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),

                settingsAsync.when(
                  data: (settings) {
                    return GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          // Weight Unit
                          ListTile(
                            leading: const Icon(Icons.fitness_center_rounded, color: Colors.white70),
                            title: const Text('Weight Unit', style: TextStyle(color: Colors.white, fontSize: 15)),
                            trailing: SegmentedButton<WeightUnit>(
                              segments: const [
                                ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                                ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                              ],
                              selected: {settings.weightUnit},
                              onSelectionChanged: (set) {
                                ref.read(settingsProvider.notifier).updateSettings(
                                      settings.copyWith(weightUnit: set.first),
                                    );
                              },
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white10),

                          // Distance Unit
                          ListTile(
                            leading: const Icon(Icons.directions_run_rounded, color: Colors.white70),
                            title: const Text('Distance Unit', style: TextStyle(color: Colors.white, fontSize: 15)),
                            trailing: SegmentedButton<DistanceUnit>(
                              segments: const [
                                ButtonSegment(value: DistanceUnit.km, label: Text('km')),
                                ButtonSegment(value: DistanceUnit.miles, label: Text('mi')),
                              ],
                              selected: {settings.distanceUnit},
                              onSelectionChanged: (set) {
                                ref.read(settingsProvider.notifier).updateSettings(
                                      settings.copyWith(distanceUnit: set.first),
                                    );
                              },
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white10),

                          // Default Rest Timer
                          ListTile(
                            leading: const Icon(Icons.timer_outlined, color: Colors.white70),
                            title: const Text('Default Rest Timer', style: TextStyle(color: Colors.white, fontSize: 15)),
                            trailing: DropdownButton<int>(
                              value: settings.defaultRestSeconds,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 30, child: Text('30 sec')),
                                DropdownMenuItem(value: 60, child: Text('60 sec')),
                                DropdownMenuItem(value: 90, child: Text('90 sec')),
                                DropdownMenuItem(value: 120, child: Text('120 sec')),
                              ],
                              onChanged: (sec) {
                                if (sec != null) {
                                  ref.read(settingsProvider.notifier).updateSettings(
                                        settings.copyWith(defaultRestSeconds: sec),
                                      );
                                }
                              },
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white10),

                          // Workout Reminders
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications_active_outlined, color: Colors.white70),
                            title: const Text('Workout Reminders', style: TextStyle(color: Colors.white, fontSize: 15)),
                            value: settings.remindersEnabled,
                            activeThumbColor: AppColors.primaryLight,
                            onChanged: (val) {
                              ref.read(settingsProvider.notifier).updateSettings(
                                    settings.copyWith(remindersEnabled: val),
                                  );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (err, stack) => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // Account & Data Management
                const Text('Account & Data', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dns_outlined, color: AppColors.accentCyan),
                        title: const Text('Server Connection', style: TextStyle(color: Colors.white, fontSize: 15)),
                        subtitle: Text(ApiConfig.baseUrl, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () => showServerSettingsDialog(context),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      ListTile(
                        leading: const Icon(Icons.file_download_outlined, color: AppColors.primaryLight),
                        title: const Text('Export Backup (JSON)', style: TextStyle(color: Colors.white, fontSize: 15)),
                        subtitle: const Text('Copy database JSON to clipboard', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        onTap: () => _handleExport(context, ref),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.accentRose),
                        title: const Text('Log Out', style: TextStyle(color: AppColors.accentRose, fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Securely sign out without erasing workout records', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        onTap: () => _handleLogout(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
