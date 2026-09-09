import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:life_rank/core/models/gacha_reward_model.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/core/services/ai_quest_service.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';

class GachaProvider extends ChangeNotifier {
  int _tickets = 5; // Starting with 5 tickets for testing
  int _lastStreakAwarded = 0;
  DateTime? _lastClosedNotif;

  int get tickets => _tickets;

  bool get shouldShowNotif {
    if (_tickets <= 0) return false;
    if (_lastClosedNotif == null) return true;
    return DateTime.now().difference(_lastClosedNotif!).inHours >= 8;
  }

  void closeNotif() {
    _lastClosedNotif = DateTime.now();
    notifyListeners();
  }

  final List<GachaReward> _pool = const [
    GachaReward(id: '1', rewardName: 'Bronze Pouch', dropRate: 60, xpReward: 50, rarity: 'Common'),
    GachaReward(id: '5', rewardName: 'Mini Self Reward', dropRate: 15, xpReward: 100, rarity: 'Uncommon'),
    GachaReward(id: '2', rewardName: 'Silver Chest', dropRate: 30, xpReward: 200, rarity: 'Rare'),
    GachaReward(id: '3', rewardName: 'Golden Vault', dropRate: 9, xpReward: 500, rarity: 'Epic'),
    GachaReward(id: '4', rewardName: 'Mythic Crystal', dropRate: 1, xpReward: 1500, rarity: 'Legendary'),
  ];

  List<GachaReward> get pool => _pool;

  void checkStreakAndAwardTicket(int currentStreak) {
    // Award 1 ticket for every 3 days of streak
    int eligibleTickets = currentStreak ~/ 3;
    if (eligibleTickets > _lastStreakAwarded) {
      int newTickets = eligibleTickets - _lastStreakAwarded;
      _tickets += newTickets;
      _lastStreakAwarded = eligibleTickets;
      // In a real app, save _tickets and _lastStreakAwarded to SharedPreferences/DB
      notifyListeners();
    }
  }

  Future<GachaReward?> rollGacha(AuthProvider auth) async {
    if (_tickets <= 0) return null;

    _tickets--;
    notifyListeners();

    // Weighted Random Probability
    int totalWeight = _pool.fold(0, (sum, item) => sum + item.dropRate);
    int randomWeight = Random().nextInt(totalWeight);
    int currentWeight = 0;

    GachaReward? baseReward;
    for (final item in _pool) {
      currentWeight += item.dropRate;
      if (randomWeight < currentWeight) {
        baseReward = item;
        break;
      }
    }
    
    baseReward ??= _pool.last;
    
    GachaReward wonReward = baseReward;
    final user = auth.supabaseUser;
    
    if (user != null) {
      try {
        final totalXp = auth.stats?.totalXp ?? 0;
        final customReward = await AiQuestService.generateCustomGachaReward(
          user.id, 
          baseReward.rarity, 
          totalXp, 
          baseReward.dropRate
        );
        wonReward = customReward;
      } catch (e) {
        debugPrint('Failed to generate custom Gacha Reward: $e');
        // fallback to baseReward
      }

      await UserStatsService.updateCategoryXp(user.id, 'financial', wonReward.xpReward);
      await auth.refreshStats();
    }

    return wonReward;
  }
}
