class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.fitnessGoal = 'Build Strength & Muscle',
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String fitnessGoal;
  final DateTime createdAt;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? fitnessGoal,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'fitness_goal': fitnessGoal,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        avatarUrl: map['avatar_url'] as String? ?? '',
        fitnessGoal: map['fitness_goal'] as String? ?? 'Build Strength & Muscle',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
