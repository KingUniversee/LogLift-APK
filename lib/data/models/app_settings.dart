enum AppAppearance { system, light, dark }
enum WeightUnit { kg, lb }
enum DistanceUnit { km, miles }

class AppSettings {
  const AppSettings({
    this.appearance = AppAppearance.dark,
    this.weightUnit = WeightUnit.kg,
    this.distanceUnit = DistanceUnit.km,
    this.defaultRestSeconds = 60,
    this.notificationsEnabled = true,
    this.remindersEnabled = true,
    this.hapticsEnabled = true,
  });

  final AppAppearance appearance;
  final WeightUnit weightUnit;
  final DistanceUnit distanceUnit;
  final int defaultRestSeconds;
  final bool notificationsEnabled;
  final bool remindersEnabled;
  final bool hapticsEnabled;

  AppSettings copyWith({
    AppAppearance? appearance,
    WeightUnit? weightUnit,
    DistanceUnit? distanceUnit,
    int? defaultRestSeconds,
    bool? notificationsEnabled,
    bool? remindersEnabled,
    bool? hapticsEnabled,
  }) {
    return AppSettings(
      appearance: appearance ?? this.appearance,
      weightUnit: weightUnit ?? this.weightUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': 'settings_default',
        'appearance': appearance.name,
        'weight_unit': weightUnit.name,
        'distance_unit': distanceUnit.name,
        'default_rest_seconds': defaultRestSeconds,
        'notifications_enabled': notificationsEnabled ? 1 : 0,
        'reminders_enabled': remindersEnabled ? 1 : 0,
        'haptics_enabled': hapticsEnabled ? 1 : 0,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        appearance: AppAppearance.values.firstWhere(
          (e) => e.name == map['appearance'],
          orElse: () => AppAppearance.dark,
        ),
        weightUnit: WeightUnit.values.firstWhere(
          (e) => e.name == map['weight_unit'],
          orElse: () => WeightUnit.kg,
        ),
        distanceUnit: DistanceUnit.values.firstWhere(
          (e) => e.name == map['distance_unit'],
          orElse: () => DistanceUnit.km,
        ),
        defaultRestSeconds: map['default_rest_seconds'] as int? ?? 60,
        notificationsEnabled: (map['notifications_enabled'] as int? ?? 1) == 1,
        remindersEnabled: (map['reminders_enabled'] as int? ?? 1) == 1,
        hapticsEnabled: (map['haptics_enabled'] as int? ?? 1) == 1,
      );
}
