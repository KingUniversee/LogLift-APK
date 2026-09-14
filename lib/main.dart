import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glass.dart';
import 'models.dart';
import 'stats.dart';
import 'storage.dart';

void main() => runApp(const MyApp());

class AppController extends ChangeNotifier {
  AppController() { exercises = List.of(defaultExercises); plans = List.of(defaultPlans); }
  late List<Exercise> exercises;
  late List<WorkoutPlan> plans;
  List<WorkoutSession> sessions = [];
  WorkoutStorage? _storage;
  bool ready = false;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _storage = WorkoutStorage(preferences);
    exercises = _storage!.loadExercises();
    plans = _storage!.loadPlans();
    sessions = _storage!.loadSessions();
    ready = true;
    notifyListeners();
  }

  Exercise exercise(String id) => exercises.firstWhere((item) => item.id == id);
  WorkoutStats get stats => calculateStats(sessions);

  Future<void> saveSession(WorkoutSession session) async {
    if (sessions.any((item) => item.id == session.id)) return;
    sessions = [session, ...sessions];
    await _persist();
    notifyListeners();
  }

  Future<void> addPlan(String name, String subtitle) async {
    plans = [...plans, WorkoutPlan(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, subtitle: subtitle, exerciseIds: ['bench'])];
    await _persist();
    notifyListeners();
  }

  Future<void> deletePlan(WorkoutPlan plan) async {
    plans = plans.where((item) => item.id != plan.id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => _storage?.save(exercises: exercises, plans: plans, sessions: sessions) ?? Future.value();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = AppController();
  @override
  void initState() { super.initState(); controller.load(); }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => MaterialApp(
          title: 'Workout Log', debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.dark), home: HomeShell(controller: controller),
        ),
      );
}

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xff8de2c5), brightness: brightness, surface: dark ? const Color(0xff12171b) : const Color(0xfff2f6f5));
  return ThemeData(
    brightness: brightness, colorScheme: scheme, scaffoldBackgroundColor: dark ? const Color(0xff091012) : const Color(0xffedf4f2), useMaterial3: true, fontFamily: 'Avenir Next',
    navigationBarTheme: NavigationBarThemeData(backgroundColor: Colors.transparent, indicatorColor: scheme.primary.withValues(alpha: 0.18), labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, color: scheme.onSurface))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white.withValues(alpha: 0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({required this.controller, super.key});
  final AppController controller;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;
  final titles = const ['Good morning', 'Workout plans', 'History', 'Progress', 'Reports'];
  @override
  Widget build(BuildContext context) {
    final pages = [HomePage(controller: widget.controller, onStart: _startWorkout), PlansPage(controller: widget.controller, onStart: _startWorkout), HistoryPage(controller: widget.controller), ProgressPage(controller: widget.controller), ReportsPage(controller: widget.controller)];
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(titles[selectedIndex], style: const TextStyle(fontWeight: FontWeight.w700)), backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, actions: [IconButton(onPressed: () {}, tooltip: 'Settings', icon: const Icon(Icons.tune_rounded))]),
      body: IndexedStack(index: selectedIndex, children: pages),
      floatingActionButton: selectedIndex < 2 ? FloatingActionButton.extended(onPressed: _startWorkout, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start workout')) : null,
      bottomNavigationBar: NavigationBar(selectedIndex: selectedIndex, onDestinationSelected: (index) => setState(() => selectedIndex = index), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'), NavigationDestination(icon: Icon(Icons.view_agenda_outlined), selectedIcon: Icon(Icons.view_agenda_rounded), label: 'Workouts'), NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'History'), NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Progress'), NavigationDestination(icon: Icon(Icons.assessment_outlined), selectedIcon: Icon(Icons.assessment_rounded), label: 'Reports')]),
    );
  }
  void _startWorkout() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActiveWorkoutPage(controller: widget.controller, plan: widget.controller.plans.first)));
}

class PageBody extends StatelessWidget {
  const PageBody({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 120), children: children));
}

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, required this.onStart, super.key});
  final AppController controller;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    final recent = controller.sessions.isEmpty ? null : controller.sessions.first;
    return PageBody(children: [
      const Text('Monday, September 14', style: TextStyle(color: Colors.white60)), const SizedBox(height: 20),
      GlassCard(padding: EdgeInsets.zero, child: InkWell(onTap: onStart, borderRadius: BorderRadius.circular(24), child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("TODAY'S PLAN", style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4, color: Theme.of(context).colorScheme.primary)), Icon(Icons.arrow_forward_rounded, color: Theme.of(context).colorScheme.primary)]), const SizedBox(height: 12), Text('Push Day', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('Chest, shoulders & triceps · 45 min', style: TextStyle(color: Colors.white60)), const SizedBox(height: 22), Row(children: [_miniMetric(context, Icons.fitness_center_rounded, '5 exercises'), const SizedBox(width: 20), _miniMetric(context, Icons.timer_outlined, '45 min')])])))),
      const SizedBox(height: 28), const SectionTitle('Your week'), const SizedBox(height: 12), SizedBox(height: 110, child: Row(children: [Expanded(child: GlassStat(label: 'Workouts', value: '${stats.workouts}', icon: Icons.check_circle_outline_rounded)), const SizedBox(width: 10), Expanded(child: GlassStat(label: 'Sets', value: '${stats.sets}', icon: Icons.layers_outlined)), const SizedBox(width: 10), Expanded(child: GlassStat(label: 'Streak', value: '${stats.streak}d', icon: Icons.local_fire_department_outlined))])),
      const SizedBox(height: 28), const SectionTitle('Recent progress'), const SizedBox(height: 12), GlassCard(child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .14), shape: BoxShape.circle), child: Icon(Icons.trending_up_rounded, color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(recent == null ? 'Ready when you are' : 'Nice work last time', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(recent == null ? 'Start your first workout to see progress here.' : '${recent.planName} · ${recent.totalVolume.toStringAsFixed(0)} kg volume', style: const TextStyle(color: Colors.white60))])), if (recent != null) const Text('+8.3%', style: TextStyle(color: Color(0xff8de2c5), fontWeight: FontWeight.w700))])),
      const SizedBox(height: 28), const SectionTitle('Personal records'), const SizedBox(height: 12), GlassCard(child: Row(children: [Icon(Icons.workspace_premium_outlined, color: Theme.of(context).colorScheme.secondary), const SizedBox(width: 12), const Expanded(child: Text('Your best lifts will appear here as you train.', style: TextStyle(color: Colors.white70))), const Icon(Icons.chevron_right_rounded, color: Colors.white38)])),
    ]);
  }
  Widget _miniMetric(BuildContext context, IconData icon, String text) => Row(children: [Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white70))]);
}

class PlansPage extends StatelessWidget {
  const PlansPage({required this.controller, required this.onStart, super.key});
  final AppController controller;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => PageBody(children: [Text('${controller.plans.length} plans', style: const TextStyle(color: Colors.white60)), const SizedBox(height: 16), ...controller.plans.map((plan) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _planCard(context, plan))), const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => _newPlan(context), icon: const Icon(Icons.add_rounded), label: const Text('Create a plan'))]);
  Widget _planCard(BuildContext context, WorkoutPlan plan) => GlassCard(onTap: onStart, child: Row(children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: [const Color(0xff8de2c5), const Color(0xffffc98b), const Color(0xffb8a4ff)][plan.color % 3].withValues(alpha: .16), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.fitness_center_rounded, color: [const Color(0xff8de2c5), const Color(0xffffc98b), const Color(0xffb8a4ff)][plan.color % 3])), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), const SizedBox(height: 4), Text('${plan.subtitle} · ${plan.exerciseIds.length} exercises', style: const TextStyle(color: Colors.white60))])), IconButton(onPressed: () => _confirmDelete(context, plan), icon: const Icon(Icons.more_horiz_rounded), tooltip: 'Plan actions')]));
  Future<void> _newPlan(BuildContext context) async { final name = TextEditingController(); final subtitle = TextEditingController(text: 'Custom workout'); final created = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('New workout plan'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Plan name')), TextField(controller: subtitle, decoration: const InputDecoration(labelText: 'Description'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (name.text.trim().isNotEmpty) Navigator.pop(context, true); }, child: const Text('Create'))])); if (created == true && context.mounted) await controller.addPlan(name.text.trim(), subtitle.text.trim()); }
  Future<void> _confirmDelete(BuildContext context, WorkoutPlan plan) async { final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text('Delete ${plan.name}?'), content: const Text('This removes the plan but keeps completed workouts.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])); if (confirmed == true) await controller.deletePlan(plan); }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.controller, super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) => PageBody(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${controller.sessions.length} completed', style: const TextStyle(color: Colors.white60)), IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list_rounded), tooltip: 'Filter history')]), if (controller.sessions.isEmpty) GlassCard(child: Column(children: [const Icon(Icons.calendar_today_rounded, size: 34, color: Colors.white38), const SizedBox(height: 14), const Text('Your history is waiting', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), const Text('Complete a workout and it will show up here.', style: TextStyle(color: Colors.white60))])) else ...controller.sessions.map((session) => Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .14), shape: BoxShape.circle), child: Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(session.planName, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${_date(session.startedAt)} · ${session.durationMinutes} min · ${session.completedSets} sets', style: const TextStyle(color: Colors.white60))])), Text('${session.totalVolume.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.w700))]))))]);
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({required this.controller, super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    final bars = [0.35, 0.58, 0.44, 0.8, 0.62, 0.92, 0.7];
    return PageBody(children: [
      const Text('Last 7 days', style: TextStyle(color: Colors.white60)),
      const SizedBox(height: 16),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Training rhythm', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        SizedBox(height: 130, child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(7, (index) => Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          AnimatedContainer(duration: const Duration(milliseconds: 500), width: 24, height: 100 * bars[index], decoration: BoxDecoration(color: index == 5 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withValues(alpha: .25), borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 8), Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][index], style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ])))),
      ])),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: GlassStat(label: 'Total volume', value: '${stats.volume.toStringAsFixed(0)} kg', icon: Icons.stacked_line_chart_rounded)), const SizedBox(width: 12), Expanded(child: GlassStat(label: 'Avg. duration', value: '${stats.averageDuration.toStringAsFixed(0)} min', icon: Icons.timer_outlined))]),
      const SizedBox(height: 16),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Muscle balance', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 18), _bar(context, 'Chest', .72), _bar(context, 'Back', .54), _bar(context, 'Legs', .38)])),
    ]);
  }
  Widget _bar(BuildContext context, String label, double value) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text('${(value * 100).round()}%', style: const TextStyle(color: Colors.white54))]), const SizedBox(height: 7), LinearProgressIndicator(value: value, minHeight: 7, borderRadius: BorderRadius.circular(8))]));
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({required this.controller, super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) { final stats = controller.stats; return PageBody(children: [const Text('A clear view of your consistency.', style: TextStyle(color: Colors.white60)), const SizedBox(height: 18), SegmentedButton<String>(segments: const [ButtonSegment(value: 'Week', label: Text('Week')), ButtonSegment(value: 'Month', label: Text('Month')), ButtonSegment(value: 'Year', label: Text('Year'))], selected: const {'Week'}, onSelectionChanged: (_) {}), const SizedBox(height: 18), GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Weekly report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(_date(DateTime.now()), style: const TextStyle(color: Colors.white54)), const SizedBox(height: 22), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_reportValue('${stats.workouts}', 'workouts'), _reportValue('${stats.sets}', 'sets'), _reportValue('${stats.reps}', 'reps')]), const SizedBox(height: 22), const Divider(color: Colors.white12), const SizedBox(height: 14), Row(children: [Icon(Icons.trending_up_rounded, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), const Text('Keep showing up. Your trend is building.', style: TextStyle(color: Colors.white70))])])), const SizedBox(height: 16), OutlinedButton.icon(onPressed: () => _share(context), icon: const Icon(Icons.ios_share_rounded), label: const Text('Export report'))]); }
  Widget _reportValue(String value, String label) => Column(children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white54))]);
  void _share(BuildContext context) { Clipboard.setData(const ClipboardData(text: 'Workout Log report')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report summary copied to clipboard'))); }
}

class ActiveWorkoutPage extends StatefulWidget {
  const ActiveWorkoutPage({required this.controller, required this.plan, super.key});
  final AppController controller;
  final WorkoutPlan plan;
  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  late final DateTime startedAt;
  late final Map<String, List<SetLog>> sets;
  @override
  void initState() { super.initState(); startedAt = DateTime.now(); sets = {for (final id in widget.plan.exerciseIds) id: [const SetLog(reps: 8, weight: 60)]}; }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.plan.name), backgroundColor: Colors.transparent, actions: [TextButton(onPressed: _finish, child: const Text('Finish'))]),
        body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 30), children: [
          Row(children: [Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text('${DateTime.now().difference(startedAt).inMinutes} min', style: const TextStyle(color: Colors.white70)), const Spacer(), Text('${sets.values.fold(0, (sum, item) => sum + item.length)} sets', style: const TextStyle(color: Colors.white70))]),
          const SizedBox(height: 20),
          ...widget.plan.exerciseIds.map((id) => _exerciseCard(widget.controller.exercise(id))),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded), label: const Text('Add exercise')),
        ])),
      );
  Widget _exerciseCard(Exercise exercise) {
    final exerciseSets = sets[exercise.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), const SizedBox(height: 4), Text('${exercise.muscle} · ${exercise.type.name}', style: const TextStyle(color: Colors.white54))])),
          IconButton(onPressed: () => setState(() => exerciseSets.add(const SetLog(reps: 8, weight: 60))), icon: const Icon(Icons.add_circle_outline_rounded), tooltip: 'Add set'),
        ]),
        const SizedBox(height: 12),
        Row(children: [const SizedBox(width: 28), Expanded(child: Text(exercise.type == ExerciseType.cardio ? 'MIN' : 'KG', style: const TextStyle(color: Colors.white38, fontSize: 11))), Expanded(child: Text(exercise.type == ExerciseType.cardio ? 'KM' : 'REPS', style: const TextStyle(color: Colors.white38, fontSize: 11))), const SizedBox(width: 38)]),
        ...exerciseSets.asMap().entries.map((entry) => _setRow(exercise, entry.key, entry.value)),
      ])),
    );
  }
  Widget _setRow(Exercise exercise, int index, SetLog set) => Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [SizedBox(width: 28, child: Text('${index + 1}', style: const TextStyle(color: Colors.white54))), Expanded(child: _numberField(set.weight.toStringAsFixed(0), (value) => _updateSet(exercise.id, index, weight: double.tryParse(value) ?? set.weight))), Expanded(child: _numberField('${set.reps}', (value) => _updateSet(exercise.id, index, reps: int.tryParse(value) ?? set.reps))), IconButton(onPressed: () => setState(() => sets[exercise.id]![index] = SetLog(reps: set.reps, weight: set.weight, completed: !set.completed)), icon: Icon(set.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: set.completed ? Theme.of(context).colorScheme.primary : Colors.white38), tooltip: 'Complete set')]));
  Widget _numberField(String value, ValueChanged<String> onChanged) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: TextFormField(initialValue: value, keyboardType: TextInputType.number, onChanged: onChanged, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4))));
  void _updateSet(String exerciseId, int index, {int? reps, double? weight}) { final current = sets[exerciseId]![index]; sets[exerciseId]![index] = SetLog(reps: reps ?? current.reps, weight: weight ?? current.weight, completed: current.completed); }
  Future<void> _finish() async { HapticFeedback.mediumImpact(); final session = WorkoutSession(id: startedAt.microsecondsSinceEpoch.toString(), planName: widget.plan.name, startedAt: startedAt, durationMinutes: DateTime.now().difference(startedAt).inMinutes.clamp(1, 999), logs: sets.entries.map((entry) => ExerciseLog(exerciseId: entry.key, sets: entry.value)).toList()); await widget.controller.saveSession(session); if (mounted) Navigator.pop(context); }
}

String _date(DateTime date) => '${date.month}/${date.day}/${date.year}';
