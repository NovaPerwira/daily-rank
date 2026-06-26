import 'package:flutter/material.dart';
import 'app_colors.dart';

class RankInfo {
  final String name;
  final String shortName;
  final int minXp;
  final int maxXp;
  final Color color;
  final Color glowColor;
  final String emoji;

  const RankInfo({
    required this.name,
    required this.shortName,
    required this.minXp,
    required this.maxXp,
    required this.color,
    required this.glowColor,
    required this.emoji,
  });
}

class RankConfig {
  static const List<RankInfo> ranks = [
    RankInfo(
      name: 'Warrior',
      shortName: 'WR',
      minXp: 0,
      maxXp: 999,
      color: AppColors.rankWarrior,
      glowColor: Color(0x408B8B8B),
      emoji: '⚔️',
    ),
    RankInfo(
      name: 'Elite',
      shortName: 'EL',
      minXp: 1000,
      maxXp: 1999,
      color: AppColors.rankElite,
      glowColor: Color(0x404CAF50),
      emoji: '🛡️',
    ),
    RankInfo(
      name: 'Master',
      shortName: 'MS',
      minXp: 2000,
      maxXp: 2999,
      color: AppColors.rankMaster,
      glowColor: Color(0x402196F3),
      emoji: '🔵',
    ),
    RankInfo(
      name: 'Grandmaster',
      shortName: 'GM',
      minXp: 3000,
      maxXp: 4499,
      color: AppColors.rankGrandmaster,
      glowColor: Color(0x409C27B0),
      emoji: '💜',
    ),
    RankInfo(
      name: 'Epic',
      shortName: 'EP',
      minXp: 4500,
      maxXp: 5999,
      color: AppColors.rankEpic,
      glowColor: Color(0x40FF9800),
      emoji: '🔥',
    ),
    RankInfo(
      name: 'Legend',
      shortName: 'LG',
      minXp: 6000,
      maxXp: 7999,
      color: AppColors.rankLegend,
      glowColor: Color(0x40F44336),
      emoji: '⭐',
    ),
    RankInfo(
      name: 'Mythic',
      shortName: 'MY',
      minXp: 8000,
      maxXp: 9999,
      color: AppColors.rankMythic,
      glowColor: Color(0x40E91E63),
      emoji: '💎',
    ),
    RankInfo(
      name: 'Mythical Glory',
      shortName: 'MG',
      minXp: 10000,
      maxXp: 999999,
      color: AppColors.rankMythicalGlory,
      glowColor: Color(0x40FFD700),
      emoji: '👑',
    ),
  ];

  static RankInfo getRankInfo(int xp) {
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (xp >= ranks[i].minXp) return ranks[i];
    }
    return ranks[0];
  }

  static RankInfo? getNextRank(int xp) {
    final current = getRankInfo(xp);
    final idx = ranks.indexOf(current);
    if (idx < ranks.length - 1) return ranks[idx + 1];
    return null;
  }

  static double getProgressToNextRank(int xp) {
    final current = getRankInfo(xp);
    final next = getNextRank(xp);
    if (next == null) return 1.0;
    final range = current.maxXp - current.minXp + 1;
    final progress = xp - current.minXp;
    return (progress / range).clamp(0.0, 1.0);
  }

  static int getXpToNextRank(int xp) {
    final next = getNextRank(xp);
    if (next == null) return 0;
    return next.minXp - xp;
  }

  static int calculateLevel(int totalXp) {
    return (totalXp / 100).floor() + 1;
  }

  // Financial XP Calculation
  static int calculateSavingXp(double savingAmount) {
    if (savingAmount >= 500000000) return 3000;
    if (savingAmount >= 150000000) return 2200;
    if (savingAmount >= 50000000) return 1500;
    if (savingAmount >= 20000000) return 1000;
    if (savingAmount >= 5000000) return 600;
    if (savingAmount >= 1000000) return 300;
    if (savingAmount > 0) return 100;
    return 0;
  }

  static int calculateSavingRateXp(double savingRate) {
    if (savingRate >= 50) return 500;
    if (savingRate >= 30) return 300;
    if (savingRate >= 20) return 200;
    if (savingRate >= 10) return 100;
    return 0;
  }

  static int calculateDebtManagementXp(bool hasDebt, double debtRatio) {
    if (!hasDebt) return 300;
    if (debtRatio < 0.1) return 200;
    if (debtRatio < 0.3) return 100;
    return 0;
  }

  // Career XP
  static const Map<String, int> skillXp = {
    'HTML/CSS': 100,
    'JavaScript': 200,
    'React': 300,
    'Vue.js': 300,
    'Laravel': 300,
    'Node.js': 300,
    'Flutter': 400,
    'Swift': 400,
    'Kotlin': 400,
    'Python': 300,
    'AI/Machine Learning': 500,
    'Blockchain': 500,
    'DevOps': 400,
    'Cloud (AWS/GCP)': 400,
  };

  static const Map<String, int> projectXp = {
    'Personal Project': 200,
    'Portfolio Website': 500,
    'First Client Project': 1000,
    'Production Application': 2000,
    'SaaS Product': 5000,
    'Open Source Contribution': 300,
    'Hackathon Winner': 800,
  };

  // Knowledge XP
  static const Map<String, int> knowledgeXp = {
    'Book': 100,
    'Online Course': 300,
    'Certificate': 500,
    'Research Paper': 1000,
  };

  // Health XP
  static const int workoutXp = 20;
  static const int weightTrackingXp = 50;
  static const int healthyStreakXp = 500;

  // Habit XP
  static const Map<String, int> habitXp = {
    'Wake Up Early': 10,
    'Workout': 20,
    'Reading': 20,
    'Coding': 30,
    'Meditation': 15,
    'Healthy Eating': 15,
    'No Social Media': 10,
    'Journal Writing': 10,
  };

  static const Map<int, int> streakBonusXp = {
    7: 100,
    30: 500,
    100: 2000,
  };
}
