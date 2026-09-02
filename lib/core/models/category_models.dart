class QuestModel {
  final String id;
  final String userId;
  final String category;
  final String title;
  final int xpReward;
  final bool completed;
  final DateTime date;

  const QuestModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.xpReward,
    this.completed = false,
    required this.date,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      xpReward: json['xp_reward'] as int,
      completed: json['completed'] as bool? ?? false,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'title': title,
      'xp_reward': xpReward,
      'completed': completed,
      'date': date.toIso8601String().split('T')[0],
    };
  }

  QuestModel copyWith({bool? completed}) {
    return QuestModel(
      id: id,
      userId: userId,
      category: category,
      title: title,
      xpReward: xpReward,
      completed: completed ?? this.completed,
      date: date,
    );
  }
}

class AchievementModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final int xpReward;
  final DateTime unlockedAt;

  const AchievementModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.xpReward,
    required this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      xpReward: json['xp_reward'] as int? ?? 0,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }
}

class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'income', 'expense', 'saving', 'investment'
  final double amount;
  final String? category;
  final DateTime date;
  /// For income transactions: 'fixed' (gaji tetap) or 'side' (pendapatan sampingan)
  final String? incomeType;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.category,
    required this.date,
    this.incomeType,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String?,
      date: DateTime.parse(json['date'] as String),
      incomeType: json['income_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'amount': amount.round(), // BIGINT in DB — must be integer
      'category': category,
      'date': date.toIso8601String().split('T')[0],
      if (incomeType != null) 'income_type': incomeType,
    };
  }

  /// Used for UPDATE (excludes user_id, includes all editable fields)
  Map<String, dynamic> toUpdateJson() {
    return {
      'type': type,
      'amount': amount.round(), // BIGINT in DB — must be integer
      'category': category,
      'date': date.toIso8601String().split('T')[0],
      'income_type': incomeType, // always send, null is valid
    };
  }
}

class CareerEntry {
  final String id;
  final String userId;
  final String type; // 'skill', 'project', 'experience', 'network'
  final String title;
  final int xpEarned;
  final DateTime addedAt;

  const CareerEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.xpEarned,
    required this.addedAt,
  });

  factory CareerEntry.fromJson(Map<String, dynamic> json) {
    return CareerEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      xpEarned: json['xp_earned'] as int,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'xp_earned': xpEarned,
    };
  }
}

class KnowledgeEntry {
  final String id;
  final String userId;
  final String type; // 'book', 'course', 'certificate', 'research'
  final String title;
  final int xpEarned;
  final DateTime addedAt;

  const KnowledgeEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.xpEarned,
    required this.addedAt,
  });

  factory KnowledgeEntry.fromJson(Map<String, dynamic> json) {
    return KnowledgeEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      xpEarned: json['xp_earned'] as int,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'xp_earned': xpEarned,
    };
  }
}

class HealthEntry {
  final String id;
  final String userId;
  final String type; // 'workout', 'weight', 'streak'
  final String? note;
  final double? value; // weight value
  final int xpEarned;
  final DateTime date;

  const HealthEntry({
    required this.id,
    required this.userId,
    required this.type,
    this.note,
    this.value,
    required this.xpEarned,
    required this.date,
  });

  factory HealthEntry.fromJson(Map<String, dynamic> json) {
    return HealthEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      note: json['note'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      xpEarned: json['xp_earned'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'note': note,
      'value': value,
      'xp_earned': xpEarned,
      'date': date.toIso8601String().split('T')[0],
    };
  }
}

class NetWorthEntry {
  final String id;
  final String userId;
  final double amountIdr;
  final String? label;
  final String source; // 'manual' or 'auto'
  final String wealthRank;
  final DateTime recordedAt;

  const NetWorthEntry({
    required this.id,
    required this.userId,
    required this.amountIdr,
    this.label,
    this.source = 'manual',
    required this.wealthRank,
    required this.recordedAt,
  });

  factory NetWorthEntry.fromJson(Map<String, dynamic> json) {
    return NetWorthEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amountIdr: (json['amount_idr'] as num).toDouble(),
      label: json['label'] as String?,
      source: json['source'] as String? ?? 'manual',
      wealthRank: json['wealth_rank'] as String? ?? 'Beginner',
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  /// Used for INSERT — excludes 'id' so Supabase uses gen_random_uuid()
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount_idr': amountIdr.round(),
      'label': label,
      'source': source,
      'wealth_rank': wealthRank,
    };
  }
}

class FinancialTodo {
  final String id;
  final String userId;
  final String title;
  final String desc;
  final String icon;
  final int points;
  bool completed;
  final bool isCustom;
  final String? presetId;
  final DateTime? todoDate;

  FinancialTodo({
    required this.id,
    required this.userId,
    required this.title,
    required this.desc,
    required this.icon,
    required this.points,
    this.completed = false,
    this.isCustom = false,
    this.presetId,
    this.todoDate,
  });

  factory FinancialTodo.fromJson(Map<String, dynamic> json) {
    final type = json['todo_type'] as String? ?? 'custom';
    return FinancialTodo(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      desc: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎯',
      points: json['points'] as int? ?? 50,
      completed: json['completed'] as bool? ?? false,
      isCustom: type == 'custom',
      presetId: json['preset_id'] as String?,
      todoDate: json['todo_date'] != null ? DateTime.parse(json['todo_date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': desc,
      'icon': icon,
      'points': points,
      'completed': completed,
      'todo_type': isCustom ? 'custom' : 'preset',
      'preset_id': presetId,
      'todo_date': todoDate?.toIso8601String().split('T')[0],
    };
  }
}
