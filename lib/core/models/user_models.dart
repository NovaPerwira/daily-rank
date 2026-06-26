class UserProfile {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}

class UserStats {
  final String id;
  final String userId;
  final int financialXp;
  final int careerXp;
  final int habitXp;
  final int knowledgeXp;
  final int healthXp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserStats({
    required this.id,
    required this.userId,
    this.financialXp = 0,
    this.careerXp = 0,
    this.habitXp = 0,
    this.knowledgeXp = 0,
    this.healthXp = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalXp =>
      financialXp + careerXp + habitXp + knowledgeXp + healthXp;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      financialXp: (json['financial_xp'] as int?) ?? 0,
      careerXp: (json['career_xp'] as int?) ?? 0,
      habitXp: (json['habit_xp'] as int?) ?? 0,
      knowledgeXp: (json['knowledge_xp'] as int?) ?? 0,
      healthXp: (json['health_xp'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'financial_xp': financialXp,
      'career_xp': careerXp,
      'habit_xp': habitXp,
      'knowledge_xp': knowledgeXp,
      'health_xp': healthXp,
    };
  }

  UserStats copyWith({
    int? financialXp,
    int? careerXp,
    int? habitXp,
    int? knowledgeXp,
    int? healthXp,
  }) {
    return UserStats(
      id: id,
      userId: userId,
      financialXp: financialXp ?? this.financialXp,
      careerXp: careerXp ?? this.careerXp,
      habitXp: habitXp ?? this.habitXp,
      knowledgeXp: knowledgeXp ?? this.knowledgeXp,
      healthXp: healthXp ?? this.healthXp,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
