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
        'avatarUrl': avatarUrl,
        'fitness_goal': fitnessGoal,
        'fitnessGoal': fitnessGoal,
        'created_at': createdAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final rawDate = map['createdAt'] ?? map['created_at'];
    DateTime parsedDate;
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    return UserProfile(
      id: (map['id'] ?? map['_id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      avatarUrl: (map['avatarUrl'] ?? map['avatar_url'] ?? '') as String,
      fitnessGoal:
          (map['fitnessGoal'] ?? map['fitness_goal'] ?? 'Build Strength & Muscle')
              as String,
      createdAt: parsedDate,
    );
  }
}
